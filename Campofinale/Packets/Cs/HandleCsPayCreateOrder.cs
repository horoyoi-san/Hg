using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Cs
{
    public class HandleCsPayCreateOrder
    {

        [Server.Handler(CsMsgId.CsPayCreateOrder)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsPayCreateOrder req = packet.DecodeBody<CsPayCreateOrder>();
            
            session.Send(ScMsgId.ScPayCreateOrder,new ScPayCreateOrder()
            {
                CashShopId = req.CashShopId,
                Count = req.Count,
                GoodsId = req.GoodsId,
                SignParam="lol"
            }, packet.csHead.UpSeqid);    

        }
       
    }
}
