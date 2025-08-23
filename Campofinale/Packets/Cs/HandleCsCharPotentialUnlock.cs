using Campofinale.Game.Char;
using Campofinale.Network;
using Campofinale.Protocol;

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
