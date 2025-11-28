using Campofinale.Game;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScFriendListQuery : Packet
    {

        public PacketScFriendListQuery(Player client) {

            ScFriendListQuery proto = new ScFriendListQuery()
            {
                FriendList =
                {
                    new FriendFriendInfo()
                    {
                        FriendUserInfo = new()
                        {
                            Name="Campofinale",
                            RoleId=(ulong)GameConstants.SERVER_UID.Item1,
                            Uid=""+GameConstants.SERVER_UID.Item1,
                            ShortId="2"
                        },
                        
                    },
                    new FriendFriendInfo()
                    {
                        FriendUserInfo = new()
                        {
                            Name=client.nickname,
                            RoleId=client.roleId,
                            Uid=""+client.roleId,
                        },


                    }
                }
                
            };
           
            SetData(ScMsgId.ScFriendListQuery, proto);
        }

    }
}
