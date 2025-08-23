using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsGachaTenPullReq
    {
        
        [Server.Handler(CsMsgId.CsGachaSinglePullReq)]
        public static void HandleOnePull(Player session, CsMsgId cmdId, Packet packet)
        {
            CsGachaSinglePullReq req = packet.DecodeBody<CsGachaSinglePullReq>();
            session.gachaManager.upSeqId = packet.csHead.UpSeqid;
            session.gachaManager.DoGacha(req.GachaPoolId, 1);
        }
        [Server.Handler(CsMsgId.CsGachaTenPullReq)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsGachaTenPullReq req = packet.DecodeBody<CsGachaTenPullReq>();
            session.gachaManager.upSeqId = packet.csHead.UpSeqid;
            session.gachaManager.DoGacha(req.GachaPoolId, 10);
        }
       
    }
}
