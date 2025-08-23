using Campofinale.Game.Char;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsEquipPutoff
    {

        [Server.Handler(CsMsgId.CsEquipPutoff)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsEquipPutoff req = packet.DecodeBody<CsEquipPutoff>();
            Character toRemove = session.chars.Find(c => c.guid == req.Charid);
            if (toRemove != null)
            {
                ScEquipPutoff put = new()
                {
                    Charid = req.Charid,
                    Slotid = req.Slotid,
                    
                };
                if (toRemove != null)
                {
                    toRemove.equipCol[req.Slotid] = 0;
                    
                }
                //TODO Improve all this maybe with an internal method in Character
                session.Send(ScMsgId.ScEquipPutoff, put);
            }

        }
       
    }
}
