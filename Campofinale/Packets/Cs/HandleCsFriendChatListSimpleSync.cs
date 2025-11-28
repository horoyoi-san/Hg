using Campofinale.Game;
using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsFriendChatListSimpleSync
    {

        [Server.Handler(CsMsgId.CsFriendChatListSimpleSync)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFriendChatListSimpleSync req = packet.DecodeBody<CsFriendChatListSimpleSync>();
            session.Send(ScMsgId.ScFriendChatListSimpleSync, new ScFriendChatListSimpleSync()
            {
                DataList =
                {
                    new ScdFriendChatListData()
                    {
                        RoleId=(ulong)GameConstants.SERVER_UID.Item1,
                        DataType=FriendChatListSimpleSyncType.ChatListSimpleSyncDefault
                    }
                }
            });
        }
       
    }
}
