using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Packets.Cs
{
    internal class HandleCsFriendBusinessCardTopicModify
    {
        [Server.Handler(CsMsgId.CsFriendBusinessCardTopicModify)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFriendBusinessCardTopicModify req = packet.DecodeBody<CsFriendBusinessCardTopicModify>();

            session.personalData.businessCardTopicId = (int)req.Id;
            session.Save();
            session.Send(new PacketScFriendBusinessCardTopicModify(req));
        }
    }
}
