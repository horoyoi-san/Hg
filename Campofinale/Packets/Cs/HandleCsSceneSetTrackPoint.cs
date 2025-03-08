using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Google.Protobuf;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneSetTrackPoint
    {

        [Server.Handler(CsMsgId.CsSceneSetTrackPoint)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneSetTrackPoint req = packet.DecodeBody<CsSceneSetTrackPoint>();

            session.Send(new PacketScSceneSetTrackPoint(req.TrackPoint));
        }
    }
}
