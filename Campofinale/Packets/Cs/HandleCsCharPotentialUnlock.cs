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
    public class HandleCsCharPotentialUnlock
    {

        [Server.Handler(CsMsgId.CsCharPotentialUnlock)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCharPotentialUnlock req = packet.DecodeBody<CsCharPotentialUnlock>();
            
            Character character = session.chars.Find(c => c.guid == req.CharObjId);
            if (character != null)
            {
                character.potential=req.Level;
                //TODO consume Item ID

                ScCharPotentialUnlock unlock = new()
                {
                    CharObjId = req.CharObjId,
                    Level = req.Level,
                };
                session.Send(ScMsgId.ScCharPotentialUnlock, unlock);
            }
           
        }
       
    }
}
