using Campofinale.Game;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScFriendListQuery : Packet
    {

        public PacketScFriendListQuery(Player client, CsFriendListQuery req) {

            ScFriendListQuery proto = new ScFriendListQuery()
            {
                FriendList =
                {
                    new FriendFriendInfo()
                    {
                        FriendUserInfo = new()
                        {
                            Name="Campofinale",
                            RoleId=GameConstants.SERVER_UID.Item1,
                            ShortId="2",
                        }
                        
                    }
                }
                
            };
           
            SetData(ScMsgId.ScFriendListQuery, proto);
        }

    }
}
