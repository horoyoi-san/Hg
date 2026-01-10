using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Packets.Sc;
using Campofinale.Game.Inventory;
using Campofinale.Database;
using Campofinale.Resource;
using StardustUtils;

namespace Campofinale.Packets.Cs
{
    /// <summary>
    /// Handler for CsItemBagBagToFactoryDepot message.
    /// Client requests to move items from bag to FactoryDepot (region depot).
    /// Items are removed from bag but remain in items collection, allowing unlimited storage beyond 30-slot bag limit.
    /// </summary>
    public class HandleCsItemBagBagToFactoryDepot
    {
        [Server.Handler(CsMsgId.CsItemBagBagToFactoryDepot)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsItemBagBagToFactoryDepot req = packet.DecodeBody<CsItemBagBagToFactoryDepot>();

            Logger.Print($"[HandleCsItemBagBagToFactoryDepot] gridList count={req.GridList.Count}, scopeName={req.ScopeName}, chapterId={req.ChapterId}");

            var inventoryManager = session.inventoryManager;
            var bag = inventoryManager.items.bag;
            bool notAllSuccess = false;

            // Process each grid index in the request
            foreach (int gridIndex in req.GridList)
            {
                if (!bag.ContainsKey(gridIndex))
                {
                    Logger.PrintWarn($"[HandleCsItemBagBagToFactoryDepot] Grid {gridIndex} not found in bag");
                    notAllSuccess = true;
                    continue;
                }

                Item bagItem = bag[gridIndex];
                if (bagItem == null)
                {
                    Logger.PrintWarn($"[HandleCsItemBagBagToFactoryDepot] Item at grid {gridIndex} is null");
                    notAllSuccess = true;
                    continue;
                }

                // Check if item is BagAndFactoryDepot type (can be moved to FactoryDepot)
                Item tempItem = new Item()
                {
                    id = bagItem.id,
                    owner = session.roleId
                };

                if (tempItem.StorageSpace() != ItemStorageSpace.BagAndFactoryDepot)
                {
                    Logger.PrintWarn($"[HandleCsItemBagBagToFactoryDepot] Item {bagItem.id} at grid {gridIndex} is not BagAndFactoryDepot type, cannot move to FactoryDepot");
                    notAllSuccess = true;
                    continue;
                }

                // Remove item from bag (but keep in items collection)
                bag.Remove(gridIndex);

                // Item remains in items collection, which is used for FactoryDepot storage
                // No need to modify the item itself, just remove from bag mapping

                // Send modify packet to notify client of the change
                session.Send(new PacketScItemBagScopeModify(session, bagItem));
            }

            // Send response
            ScItemBagBagToFactoryDepot rsp = new ScItemBagBagToFactoryDepot()
            {
                NotAllSuccess = notAllSuccess,
                ScopeName = req.ScopeName
            };
            session.Send(ScMsgId.ScItemBagBagToFactoryDepot, rsp);

            // Send all bag syncs to update client's bag display completely
            session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.Weapon));
            session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.WeaponGem));
            session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.Equip));
            session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.CommercialItem));
            session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.Factory));
            session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.SpecialItem));
        }
    }
}

