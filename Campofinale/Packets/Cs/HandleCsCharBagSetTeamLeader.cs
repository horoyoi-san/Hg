using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsCharBagSetTeamLeader
    {

        [Server.Handler(CsMsgId.CsCharBagSetTeamLeader)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCharBagSetTeamLeader req = packet.DecodeBody<CsCharBagSetTeamLeader>();

            session.teams[req.TeamIndex].leader=req.Leaderid;
            ScCharBagSetTeamLeader rsp = new()
            {
                Leaderid = req.Leaderid,
                TeamIndex = req.TeamIndex,
                ScopeName = 1,
                TeamType = req.TeamType,
            };
            session.Send(ScMsgId.ScCharBagSetTeamLeader, rsp);
            
        }
       
    }
}
