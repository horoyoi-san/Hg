using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource.Table;
using Campofinale.Utils;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Cs
{
    public class HandleCsPayQueryPlatformData
    {

        [Server.Handler(CsMsgId.CsPayQueryPlatformData)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsPayQueryPlatformData req = packet.DecodeBody<CsPayQueryPlatformData>();
            ScPayQueryPlatformData rsp = new ScPayQueryPlatformData()
            {
                
            };
            foreach (CashShopGoodsTable good in cashShopGoodsTable.Values)
            {
                rsp.PlatformGoodsData.Add(new ScdPlatformGoodsData()
                {
                    GoodsId=good.cashGoodsId,
                    LimitCount=1,
                    LimitType = good.GetLimitType(),
                    PurchaseCount=0,
                    
                });
            }
            session.Send(ScMsgId.ScPayQueryPlatformData, rsp, packet.csHead.UpSeqid);

        }
       
    }
}
