using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScCharBagSetTeamName : Packet
    {

        public PacketScCharBagSetTeamName(Player client)
        {
            ScCharBagSetTeamName proto = new()
            {
                TeamIndex = client.teamIndex,
                TeamName = client.teams[client.teamIndex].name,
                ScopeName = 1,
            };
            SetData(ScMsgId.ScCharBagSetTeamName, proto);
        }
    }
}
