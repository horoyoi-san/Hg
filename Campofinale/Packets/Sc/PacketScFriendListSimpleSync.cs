using Campofinale.Game;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScFriendListSimpleSync : Packet
    {

        public PacketScFriendListSimpleSync(Player client) {

           
            ScFriendListSimpleSync proto = new ScFriendListSimpleSync()
            {
                
                FriendList =
                {
                    new ScdFriendFriendSimpleInfo()
                    {
                        AdventureLevel=3,
                        Name="Campofinale",
                        Online=true,
                        RoleId=GameConstants.SERVER_UID.Item1,
                        Signature="Campofinale console friend!",
                        RemarkName="",
                        UserAvatarFrameId=3,
                        UserAvatarId=8,
                        BusinessCardTopicId= 9,
                        ShortId="2",
                        ThirdAccountData = new()
                        {
                            ThirdAccountDataType=HgThirdAccountType.AccountTypeDefault
                        },
                        LastLoginType=HgThirdAccountType.AccountTypeDefault
                    }
                },
                
                
            };
           
            SetData(ScMsgId.ScFriendListSimpleSync, proto);
        }

    }
}
