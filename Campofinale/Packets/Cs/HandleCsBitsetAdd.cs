using Campofinale.Game.Character;
using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
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
    public class HandleCsBitsetAdd
    {

        [Server.Handler(CsMsgId.CsBitsetAdd)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsBitsetAdd req = packet.DecodeBody<CsBitsetAdd>();
            foreach (var item in req.Value)
            {
                session.bitsetManager.AddValue((BitsetType)req.Type, (int)item);
            }
            session.Send(new PacketScBitsetAdd(session,req.Type,req.Value.ToList()));    

        }
       
    }
}
