using Campofinale.Network;
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
    public class HandleCsEnterDungeon
    {
        
        [Server.Handler(CsMsgId.CsEnterDungeon)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsEnterDungeon req = packet.DecodeBody<CsEnterDungeon>();
            session.EnterDungeon(req.DungeonId, req.RacingParam);

        }
       
    }
}
