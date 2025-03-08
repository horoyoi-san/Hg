using Campofinale.Game.Character;
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
    public class HandleCsEquipPuton
    {

        [Server.Handler(CsMsgId.CsEquipPuton)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsEquipPuton req = packet.DecodeBody<CsEquipPuton>();
            Character toEquip = session.chars.Find(c => c.guid == req.Charid);
            Character toRemove = session.chars.Find(c => c.IsEquipped(req.Equipid));
            if (toEquip != null)
            {
                ScEquipPuton put = new()
                {
                    Charid = req.Charid,
                    Equipid = req.Equipid,
                    Slotid = req.Slotid,
                    
                };
                if (toRemove != null)
                {
                    toRemove.equipCol[req.Slotid] = toEquip.equipCol[req.Slotid];
                    put.PutOffCharid = toRemove.guid;
                }
                toEquip.equipCol[req.Slotid] = req.Equipid;
                //TODO Improve all this maybe with an internal method in Character
                session.Send(ScMsgId.ScEquipPuton, put);
            }

        }
       
    }
}
