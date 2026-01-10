using Campofinale.Game.Inventory;
using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Cs
{
	/// <summary>
	/// Handles CsItemBagUseItem message.
	/// Processes item usage from player's bag (consumables, medicines, bombs, etc.)
	/// </summary>
	public class HandleCsItemBagUseItem
	{
		[Server.Handler(CsMsgId.CsItemBagUseItem)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsItemBagUseItem req = packet.DecodeBody<CsItemBagUseItem>();

			// Validate request
			if (req.GridIndex < 0 || req.Count <= 0)
			{
				// Send error response if needed
				return;
			}

			// Get item from bag at specified grid index
			Item? bagItem = null;
			if (session.inventoryManager.items.bag.TryGetValue(req.GridIndex, out bagItem))
			{
				// Check if item exists and has enough count
				if (bagItem == null || bagItem.amount < req.Count)
				{
					// Send error response
					session.Send(ScMsgId.ScItemBagUseItem, new ScItemBagUseItem()
					{
						Result = EUseItemResult.CondiitonFail,
						ScopeName = req.ScopeName
					});
					return;
				}

				// Consume the item
				int originalAmount = bagItem.amount;
				string itemId = bagItem.id;
				session.inventoryManager.RemoveItem(bagItem, req.Count);

				// Create response with used item info
				ScdItemGrid usedItemGrid = new ScdItemGrid()
				{
					GridIndex = req.GridIndex,
					Id = itemId,
					Count = req.Count
				};

				// Send success response
				ScItemBagUseItem response = new ScItemBagUseItem()
				{
					Result = EUseItemResult.Ok,
					UsedItem = usedItemGrid,
					CharInstIdList = { req.CharInstIdList },
					EquipMedicineCharInstId = req.EquipMedicineCharInstId,
					ScopeName = req.ScopeName
				};

				session.Send(ScMsgId.ScItemBagUseItem, response);
			}
			else
			{
				// Item not found at grid index
				session.Send(ScMsgId.ScItemBagUseItem, new ScItemBagUseItem()
				{
					Result = EUseItemResult.CondiitonFail,
					ScopeName = req.ScopeName
				});
			}
		}
	}
}

