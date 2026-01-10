using Campofinale.Resource;
using Campofinale.Resource.Table;
using Campofinale.Game.Inventory;
using System.Collections.Generic;
using System.Linq;
using StardustUtils;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Shop
{
	/// <summary>
	/// Manages shop-related operations and queries.
	/// Provides functionality to query shop goods by shop ID and process purchases.
	/// </summary>
	public static class ShopManager
	{
		/// <summary>
		/// Get all goods for a specific shop by shop ID.
		/// </summary>
		/// <param name="shopId">The shop ID to query</param>
		/// <returns>List of ShopGoodsTable entries for the shop, ordered by sortId</returns>
		public static List<ShopGoodsTable> GetShopGoods(string shopId)
		{
			if (string.IsNullOrEmpty(shopId))
			{
				return new List<ShopGoodsTable>();
			}

			return ResourceManager.shopGoodsTable.Values
				.Where(goods => goods.shopId == shopId)
				.OrderBy(goods => goods.sortId)
				.ToList();
		}

		/// <summary>
		/// Get a specific goods entry by goods ID.
		/// </summary>
		/// <param name="goodsId">The goods ID to query</param>
		/// <returns>ShopGoodsTable entry if found, null otherwise</returns>
		public static ShopGoodsTable GetGoodsById(string goodsId)
		{
			if (string.IsNullOrEmpty(goodsId))
			{
				return null;
			}

			ResourceManager.shopGoodsTable.TryGetValue(goodsId, out var goods);
			return goods;
		}

		/// <summary>
		/// Get shop information by shop ID.
		/// </summary>
		/// <param name="shopId">The shop ID to query</param>
		/// <returns>ShopTable entry if found, null otherwise</returns>
		public static ShopTable GetShopById(string shopId)
		{
			if (string.IsNullOrEmpty(shopId))
			{
				return null;
			}

			ResourceManager.shopTable.TryGetValue(shopId, out var shop);
			return shop;
		}

		/// <summary>
		/// Get all goods IDs for a specific shop by shop ID.
		/// This method uses the shopGoodsIds list from ShopTable if available,
		/// otherwise queries from ShopGoodsTable.
		/// </summary>
		/// <param name="shopId">The shop ID to query</param>
		/// <returns>List of goods IDs for the shop</returns>
		public static List<string> GetShopGoodsIds(string shopId)
		{
			if (string.IsNullOrEmpty(shopId))
			{
				return new List<string>();
			}

			// First try to get from ShopTable.shopGoodsIds
			var shop = GetShopById(shopId);
			if (shop != null && shop.shopGoodsIds != null && shop.shopGoodsIds.Count > 0)
			{
				return shop.shopGoodsIds;
			}

			// Fallback to query from ShopGoodsTable
			return GetShopGoods(shopId)
				.Select(goods => goods.goodsId)
				.ToList();
		}

		/// <summary>
		/// Check if a goods belongs to a specific shop.
		/// </summary>
		/// <param name="goodsId">The goods ID to check</param>
		/// <param name="shopId">The shop ID to verify</param>
		/// <returns>True if the goods belongs to the shop, false otherwise</returns>
		public static bool IsGoodsInShop(string goodsId, string shopId)
		{
			var goods = GetGoodsById(goodsId);
			return goods != null && goods.shopId == shopId;
		}

		/// <summary>
		/// Get all shops in a shop group.
		/// </summary>
		/// <param name="shopGroupId">The shop group ID to query</param>
		/// <returns>List of ShopTable entries for the shop group, ordered by shopGroupNumber</returns>
		public static List<ShopTable> GetShopsByGroupId(string shopGroupId)
		{
			if (string.IsNullOrEmpty(shopGroupId))
			{
				return new List<ShopTable>();
			}

			return ResourceManager.shopTable.Values
				.Where(shop => shop.shopGroupId == shopGroupId)
				.OrderBy(shop => shop.shopGroupNumber)
				.ToList();
		}

		/// <summary>
		/// Process a purchase: validate, deduct currency, and grant rewards.
		/// </summary>
		/// <param name="shopId">The shop ID</param>
		/// <param name="goodsId">The goods ID</param>
		/// <param name="count">The purchase count</param>
		/// <param name="inventoryManager">The player's inventory manager</param>
		/// <returns>True if purchase succeeded, false otherwise</returns>
		public static bool ProcessPurchase(
			string shopId, string goodsId, int count, InventoryManager inventoryManager)
		{
			// Validate shop exists
			var shop = GetShopById(shopId);
			if (shop == null)
			{
				return false;
			}

			// Validate goods exists
			var goods = GetGoodsById(goodsId);
			if (goods == null)
			{
				return false;
			}

			// Validate goods belongs to the shop
			if (!IsGoodsInShop(goodsId, shopId))
			{
				return false;
			}

			// Validate purchase count
			if (count <= 0)
			{
				return false;
			}

			// Calculate total price (considering discount)
			int totalPrice = (int)(goods.price * goods.cnDiscount * count);

			// Check if player has enough currency
			int playerCurrencyAmount = inventoryManager.items.GetItemAmount(goods.moneyId);
			if (playerCurrencyAmount < totalPrice)
			{
				return false;
			}

			// Deduct currency
			if (!inventoryManager.ConsumeItem(goods.moneyId, totalPrice))
			{
				return false;
			}

			// Give rewards using rewardId - directly add to inventory
			if (!string.IsNullOrEmpty(goods.rewardId))
			{
				if (rewardTable.ContainsKey(goods.rewardId))
				{
					var reward = rewardTable[goods.rewardId];
					if (reward.itemBundles != null)
					{
						foreach (var bundle in reward.itemBundles)
						{
							// Add items directly to inventory, multiply by purchase count
							inventoryManager.AddItem(bundle.id, bundle.count * count, true);
						}
					}
				}
			}

			return true;
		}

		/// <summary>
		/// Calculate total price for a purchase.
		/// </summary>
		/// <param name="goods">The goods to purchase</param>
		/// <param name="count">The purchase count</param>
		/// <returns>Total price considering discount</returns>
		public static int CalculateTotalPrice(ShopGoodsTable goods, int count)
		{
			if (goods == null || count <= 0)
			{
				return 0;
			}
			return (int)(goods.price * goods.cnDiscount * count);
		}
	}
}

