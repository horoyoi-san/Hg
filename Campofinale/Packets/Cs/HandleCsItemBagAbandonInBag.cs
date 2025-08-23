using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsItemBagAbandonInBag
    {

        [Server.Handler(CsMsgId.CsItemBagAbandonInBag)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsItemBagAbandonInBag req = packet.DecodeBody<CsItemBagAbandonInBag>();
            session.inventoryManager.DropItemsBag(req);
        }
       
    }
}
