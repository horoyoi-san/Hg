using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Sc
{
    public class PacketScSnsGetChatList : Packet
    {
        public PacketScSnsGetChatList(Player player) {
            ScSnsGetChatList proto = new ScSnsGetChatList() {
               
            };
            foreach (var chat in ResourceManager.snsChatTable)
            {
                var chatInfo = new SnsChatInfo()
                {
                    ChatId = chat.Value.chatId,
                    ChatType = chat.Value.chatType,
                    Timestamp = DateTime.UtcNow.ToUnixTimestampMilliseconds(),

                };
                proto.ChatList.Add(chatInfo);
            }
            SetData(ScMsgId.ScSnsGetChatList, proto);
        }
    }
}
