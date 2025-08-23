using Campofinale.Game.Char;
using Campofinale.Game.Inventory;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsItemBagSetItemLock
    {
        [Server.Handler(CsMsgId.CsItemBagSetItemLock)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsItemBagSetItemLock req = packet.DecodeBody<CsItemBagSetItemLock>();

            foreach (var info in req.LockInfoList)
            {
                Item item = session.inventoryManager.items.items.Find(i=>i.guid==info.InstId);
                if (item != null)
                {
                    item.locked = info.IsLock;
                }
            }
            ScItemBagSetItemLock rsp = new()
            {
                LockInfoList =
                {
                    req.LockInfoList,
                }
            };
            session.Send(ScMsgId.ScItemBagSetItemLock, rsp);
        }
       
    }
}
