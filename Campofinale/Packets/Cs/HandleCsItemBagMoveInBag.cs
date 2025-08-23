using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsItemBagMoveInBag
    {
        
        [Server.Handler(CsMsgId.CsItemBagMoveInBag)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsItemBagMoveInBag req = packet.DecodeBody<CsItemBagMoveInBag>();
            session.inventoryManager.items.MoveBagItem(req.FromGrid, req.ToGrid);
        }
       
    }
}
