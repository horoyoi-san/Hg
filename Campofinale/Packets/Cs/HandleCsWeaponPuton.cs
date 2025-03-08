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
    public class HandleCsWeaponPuton
    {

        [Server.Handler(CsMsgId.CsWeaponPuton)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsWeaponPuton req = packet.DecodeBody<CsWeaponPuton>();
            Character toEquip = session.chars.Find(c => c.guid == req.Charid);
            Character toRemove = session.chars.Find(c => c.weaponGuid == req.Weaponid);
            if (toEquip != null)
            {
                ScWeaponPuton put = new()
                {
                    Charid = req.Charid,
                    Weaponid = req.Weaponid,
                    Offweaponid = toEquip.guid,

                };
                if (toRemove != null)
                {
                    toRemove.weaponGuid = toEquip.weaponGuid;
                    put.PutOffCharid = toRemove.guid;
                }
                toEquip.weaponGuid = req.Weaponid;
                //TODO Improve all this maybe with an internal method in Character
                session.Send(ScMsgId.ScWeaponPuton, put);
            }

        }
       
    }
}
