using Campofinale.Game;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScCharBagSetTeam : Packet
    {

        public PacketScCharBagSetTeam(Player client, Team team, int index) {

            ScCharBagSetTeam proto = new ScCharBagSetTeam()
            {
                CharTeam = {team.members },
                LeaderId = team.leader,
                ScopeName = 1,
                TeamIndex = index,
                TeamType = CharBagTeamType.Main,
            };
            SetData(ScMsgId.ScCharBagSetTeam, proto);
        }

    }
}
