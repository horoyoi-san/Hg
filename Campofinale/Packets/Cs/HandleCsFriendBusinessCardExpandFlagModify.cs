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
    internal class HandleCsFriendBusinessCardExpandFlagModify
    {
        [Server.Handler(CsMsgId.CsFriendBusinessCardExpandFlagModify)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFriendBusinessCardExpandFlagModify req = packet.DecodeBody<CsFriendBusinessCardExpandFlagModify>();

            session.personalData.businessCardExpandFlag = req.Flag;
            session.Save();
            session.Send(new PacketScFriendBusinessCardExpandFlagModify(req));
        }
    }
}
