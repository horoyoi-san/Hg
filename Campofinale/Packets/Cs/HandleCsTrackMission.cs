using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    internal class HandleCsTrackMission
    {
        [Server.Handler(CsMsgId.CsTrackMission)]
        public static void Handle(Player session, CsMsgId msgId, Packet packet)
        {
            CsTrackMission req = packet.DecodeBody<CsTrackMission>();
            session.missionSystem.curMission = req.MissionId;
            
            ScTrackMissionChange rsp = new()
            {
                MissionId = req.MissionId
            };
            session.Send(ScMsgId.ScTrackMissionChange, rsp,packet.csHead.UpSeqid);
        }
    }
}
