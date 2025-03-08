using Campofinale.Game.Character;
using Campofinale.Game.Inventory;
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
    public class HandleCsWeaponAddExp
    {

        [Server.Handler(CsMsgId.CsWeaponAddExp)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsWeaponAddExp req = packet.DecodeBody<CsWeaponAddExp>();
            
            Item item = session.inventoryManager.items.Find(c=>c.guid==req.Weaponid);
            if(item != null)
            item.LevelUp(req.CostItemId2Count,req.CostWeaponIds);

        }
       
    }
}
