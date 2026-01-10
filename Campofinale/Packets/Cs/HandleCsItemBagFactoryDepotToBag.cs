using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Packets.Sc;
using Campofinale.Resource;
using Campofinale.Resource.Table;
using Campofinale.Database;
using Campofinale.Game.Inventory;
using Google.Protobuf.Collections;
using StardustUtils;
using System;

namespace Campofinale.Packets.Cs
{
	public class HandleCsItemBagFactoryDepotToBag
	{
		[Server.Handler(CsMsgId.CsItemBagFactoryDepotToBag)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsItemBagFactoryDepotToBag req = packet.DecodeBody<CsItemBagFactoryDepotToBag>();

			var inventoryManager = session.inventoryManager;
			bool notAllSuccess = false;

			string itemId = req.ItemId;
			int gridIndex = req.GridIndex;
			int requestedCount = req.Count;

			if (string.IsNullOrEmpty(itemId))
			{
				Logger.PrintWarn($"[HandleCsItemBagFactoryDepotToBag] Invalid itemId");
				notAllSuccess = true;
			}
			else
			{
				// Validate grid index
				if (gridIndex < 0 || gridIndex >= inventoryManager.items.maxBagSize)
				{
					Logger.PrintWarn($"[HandleCsItemBagFactoryDepotToBag] Invalid gridIndex: {gridIndex}, maxBagSize: {inventoryManager.items.maxBagSize}");
					notAllSuccess = true;
				}
				else if (inventoryManager.items.bag.ContainsKey(gridIndex))
				{
					// Check if target grid is already occupied
					Logger.PrintWarn($"[HandleCsItemBagFactoryDepotToBag] Grid {gridIndex} is already occupied");
					notAllSuccess = true;
				}
				else
				{
					// Find item in factory depot
					Item? factoryDepotItem = null;

					var factoryItems = inventoryManager.items.items
						.Where(item => item.id == itemId && item.ItemType == ItemValuableDepotType.Factory)
						.ToList();

					// Check if any of these items are not in bag
					foreach (var item in factoryItems)
					{
						bool inBag = inventoryManager.items.bag.ContainsValue(item);
						if (!inBag)
						{
							factoryDepotItem = item;
							break;
						}
					}

					// If not found, try to find any item with matching itemId (fallback)
					if (factoryDepotItem == null)
					{
						factoryDepotItem = inventoryManager.items.items
							.FirstOrDefault(item => item.id == itemId && !inventoryManager.items.bag.ContainsValue(item));
					}

					if (factoryDepotItem == null)
					{
						Logger.PrintWarn($"[HandleCsItemBagFactoryDepotToBag] Item {itemId} not found in factory depot");
						notAllSuccess = true;
					}
					else
					{
						// Determine move count
						int moveCount = requestedCount;
						if (moveCount < 0 || moveCount > factoryDepotItem.amount)
						{
							moveCount = factoryDepotItem.amount; // Move all if count is -1 or exceeds available
						}

						if (moveCount <= 0)
						{
							Logger.PrintWarn($"[HandleCsItemBagFactoryDepotToBag] Invalid move count: {moveCount} for item {itemId}");
							notAllSuccess = true;
						}
						else
						{
							// Get item config for stack limits
							var itemConfig = ResourceManager.GetItemTable(itemId);
							int maxStack = itemConfig.maxBackpackStackCount;
							int amountToMove = Math.Min(moveCount, maxStack);

							// Create new item in bag at specified grid index
							Item newItem = new Item(session.roleId, itemId, amountToMove)
							{
								guid = session.random.NextRand()
							};

							inventoryManager.items.bag[gridIndex] = newItem;
							inventoryManager.items.items.Add(newItem);
							DatabaseManager.db.UpsertItem(newItem);

							Logger.Print($"[HandleCsItemBagFactoryDepotToBag] Added {amountToMove} of {itemId} to grid {gridIndex}");

							// Update factory depot item
							if (amountToMove >= factoryDepotItem.amount)
							{
								// Moved all, remove from depot
								inventoryManager.items.items.Remove(factoryDepotItem);
								DatabaseManager.db.DeleteItem(factoryDepotItem);
							}
							else
							{
								// Reduce amount in depot
								factoryDepotItem.amount -= amountToMove;
								DatabaseManager.db.UpsertItem(factoryDepotItem);
							}

							Logger.Print($"[HandleCsItemBagFactoryDepotToBag] Successfully moved {amountToMove} of {itemId} from factory depot to bag at grid {gridIndex}");
						}
					}
				}
			}

			ScItemBagBagToFactoryDepot rsp = new ScItemBagBagToFactoryDepot()
			{
				NotAllSuccess = notAllSuccess,
				ScopeName = req.ScopeName
			};
			session.Send(ScMsgId.ScItemBagBagToFactoryDepot, rsp);

			// Sync all bag-related scopes to ensure client UI is fully updated after item movement
			session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.Weapon));
			session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.WeaponGem));
			session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.Equip));
			session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.CommercialItem));
			session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.Factory));
			session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.SpecialItem));
		}
	}
}
