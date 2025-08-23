using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScSyncCharBagInfo : Packet
    {

        public PacketScSyncCharBagInfo(Player client) {

            ScSyncCharBagInfo proto = new()
            {
                
                ScopeName=1,
                
                CharInfo =
                {

                },
                CurrTeamIndex=client.teamIndex,
                MaxCharTeamMemberCount=4,
                
                TeamInfo =
                {

                },
               
            };
            client.chars.ForEach(c =>
            {
                proto.CharInfo.Add(c.ToProto());
            });
            client.teams.ForEach(c =>
            {
                proto.TeamInfo.Add(new CharTeamInfo()
                {
                    CharTeam = { c.members },
                    Leaderid=c.leader,
                    TeamName=c.name,
                });
            });
            SetData(ScMsgId.ScSyncCharBagInfo, proto);
        }

    }
}
