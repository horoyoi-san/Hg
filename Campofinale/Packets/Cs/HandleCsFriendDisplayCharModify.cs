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
    internal class HandleCsFriendDisplayCharModify
    {
        [Server.Handler(CsMsgId.CsFriendDisplayCharModify)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFriendDisplayCharModify req = packet.DecodeBody<CsFriendDisplayCharModify>();

            session.personalData.charList = [.. req.ObjIdList];
            session.Save();
            session.Send(new PacketScFriendDisplayCharModify(req));
        }
    }
}
