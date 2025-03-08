using Campofinale.Game.Character;
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
    public class HandleCsCharUnlockTalentNode
    {
        [Server.Handler(CsMsgId.CsCharUnlockTalentNode)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCharUnlockTalentNode req = packet.DecodeBody<CsCharUnlockTalentNode>();
            
            Character character = session.chars.Find(c=>c.guid==req.CharObjId);
            if (character != null)
            {
                character.UnlockNode(req.NodeId);             
            }
        }
       
    }
}
