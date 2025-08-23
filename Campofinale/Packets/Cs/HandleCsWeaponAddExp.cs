using Campofinale.Game.Inventory;
using Campofinale.Network;
using Campofinale.Protocol;

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
