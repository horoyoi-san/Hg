using Campofinale.Game.Char;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsEquipPuton
    {

        [Server.Handler(CsMsgId.CsEquipPuton)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsEquipPuton req = packet.DecodeBody<CsEquipPuton>();
            Character? toEquip = session.chars.Find(c => c.guid == req.Charid);
            Character? toRemove = session.chars.Find(c => c.IsEquipped(req.Equipid));
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
                    // Save character data to database after equipment change
                    Database.DatabaseManager.db.UpsertCharacter(toRemove);
                }
                toEquip.equipCol[req.Slotid] = req.Equipid;
                // Save character data to database after equipment change
                Database.DatabaseManager.db.UpsertCharacter(toEquip);
                //TODO Improve all this maybe with an internal method in Character
                session.Send(ScMsgId.ScEquipPuton, put);
            }

        }

    }
}
