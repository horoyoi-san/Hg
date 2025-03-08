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
    public class HandleCsSpaceshipStationCharChangeWorkState
    {

        [Server.Handler(CsMsgId.CsSpaceshipStationCharChangeWorkState)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSpaceshipStationCharChangeWorkState req = packet.DecodeBody<CsSpaceshipStationCharChangeWorkState>();
            session.spaceshipManager.GetChar(req.CharId).isWorking = req.GoToWork;
            foreach (var room in session.spaceshipManager.rooms)
            {
                session.Send(new PacketScSpaceshipSyncRoomStation(session,room));
            }
        }
       
    }
}
