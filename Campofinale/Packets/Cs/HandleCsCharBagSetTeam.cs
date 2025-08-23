using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsCharBagSetTeam
    {

        [Server.Handler(CsMsgId.CsCharBagSetTeam)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCharBagSetTeam req = packet.DecodeBody<CsCharBagSetTeam>();

            session.teams[req.TeamIndex].leader=req.LeaderId;
            session.teams[req.TeamIndex].members= req.CharTeam.ToList();
            session.Send(new PacketScCharBagSetTeam(session,session.teams[req.TeamIndex], req.TeamIndex));
            session.Send(new PacketScSelfSceneInfo(session, Resource.SelfInfoReasonType.SlrChangeTeam));
        }
       
    }
}
