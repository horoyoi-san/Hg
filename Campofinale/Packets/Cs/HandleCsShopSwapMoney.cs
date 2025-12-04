using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsShopSwapMoney
    {
        
        [Server.Handler(CsMsgId.CsShopSwapMoney)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsShopSwapMoney req = packet.DecodeBody<CsShopSwapMoney>();
            //TODO
            ScShopSwapMoney rsp = new()
            {

            };
        }
       
    }
}
