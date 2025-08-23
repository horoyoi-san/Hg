using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Cs
{
    
    public class HandleCsCharBagSetCurrTeamIndex
    {
        [Server.Handler(CsMsgId.CsCharBagSetCurrTeamIndex)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCharBagSetCurrTeamIndex req = packet.DecodeBody<CsCharBagSetCurrTeamIndex>();
            session.teamIndex = req.TeamIndex;
            session.teams[session.teamIndex].leader = req.LeaderId;
            
            session.Send(new PacketScCharBagSetCurrTeamIndex(session));
            session.Send(new PacketScSelfSceneInfo(session,SelfInfoReasonType.SlrChangeTeam));
        }
    }
}
