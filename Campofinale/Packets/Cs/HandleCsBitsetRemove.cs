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
    public class HandleCsBitsetRemove
    {

        [Server.Handler(CsMsgId.CsBitsetRemove)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsBitsetRemove req = packet.DecodeBody<CsBitsetRemove>();
            foreach (var item in req.Value)
            {
                session.bitsetManager.RemoveValue((BitsetType)req.Type, (int)item);
            }
            session.Send(new PacketScBitsetRemove(session,req.Type,req.Value.ToList()));    

        }
       
    }
}
