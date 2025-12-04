using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Packets.Sc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Packets.Cs
{
    internal class HandleCsFriendSignatureModify
    {

        [Server.Handler(CsMsgId.CsFriendSignatureModify)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFriendSignatureModify req = packet.DecodeBody<CsFriendSignatureModify>();

            session.personalData.signature = req.Signature;
            session.Save();
            session.Send(new PacketScFriendSignatureModify(req));
        }
    }
}
