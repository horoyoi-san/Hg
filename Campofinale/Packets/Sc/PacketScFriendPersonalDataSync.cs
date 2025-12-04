using Campofinale.Network;
using Campofinale.Protocol;
using Google.Protobuf.Collections;

namespace Campofinale.Packets.Sc
{
    public class PacketScFriendPersonalDataSync : Packet
    {

        public PacketScFriendPersonalDataSync(Player client)
        {
            PlayerPersonalData personalData = client.personalData;

            FriendPersonalData friendPersonalData = new()
            {
                Signature = personalData.signature,
                UserAvatarFrameId = personalData.userAvatarFrameId,
                UserAvatarId = personalData.userAvatarId,
                BusinessCardTopicId = personalData.businessCardTopicId,
                BusinessCardExpandFlag = personalData.businessCardExpandFlag,
                CharList = { },
            };

            foreach (var charId in personalData.charList)
            {
                friendPersonalData.CharList.Add(charId);
            }

            ScFriendPersonalDataSync proto = new ScFriendPersonalDataSync()
            {
                Data = friendPersonalData
            };

            SetData(ScMsgId.ScFriendPersonalDataSync, proto);
        }

    }
}
