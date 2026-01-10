using Campofinale.Game.Char;
using Campofinale.Game.Inventory;
using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsWeaponBreakthrough
    {
        [Server.Handler(CsMsgId.CsWeaponBreakthrough)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsWeaponBreakthrough req = packet.DecodeBody<CsWeaponBreakthrough>();
            Character? character = session.chars.Find(c => c.weaponGuid == req.Weaponid);
            if (character != null)
            {
                Item? item = session.inventoryManager.items.Find(c => c.guid == req.Weaponid);
                if (item != null)
                {
                    item.breakthroughLv++;
                    ScWeaponBreakthrough res = new()
                    {
                        Weaponid = req.Weaponid,
                        BreakthroughLv = item.breakthroughLv
                    };
                    session.Send(ScMsgId.ScWeaponBreakthrough, res);
                    session.Send(new PacketScSyncWallet(session));
                    session.Send(new PacketScItemBagScopeModify(session, item));
                    session.Send(new PacketScSyncCharBagInfo(session));
                }
            }
        }
    }
}