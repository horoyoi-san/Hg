using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsCharBagSetTeamName
    {

        [Server.Handler(CsMsgId.CsCharBagSetTeamName)]

        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCharBagSetTeamName req = packet.DecodeBody<CsCharBagSetTeamName>();

            session.teams[req.TeamIndex].name=req.TeamName;

            ScCharBagSetTeamName rsp = new()
            {
                TeamIndex = req.TeamIndex,
                TeamName = req.TeamName,
                ScopeName = 1,
            };
            session.Send(ScMsgId.ScCharBagSetTeamName, rsp);
        }
    }
}
