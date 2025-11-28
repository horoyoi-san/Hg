using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScFriendPersonalDataSync  : Packet
    {

        public PacketScFriendPersonalDataSync(Player client) {

            ScFriendPersonalDataSync proto = new ScFriendPersonalDataSync()
            {
                Data = new()
                {
                    Signature="Campofinale!!",
                    UserAvatarFrameId=3,
                    UserAvatarId=8,
                    BusinessCardTopicId= 9,
                    CharList ={ 0},
                    
                }

            };
            SetData(ScMsgId.ScFriendPersonalDataSync, proto);
        }

    }
}
