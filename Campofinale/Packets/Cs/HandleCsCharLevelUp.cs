using Campofinale.Game.Char;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsCharLevelUp
    {

        [Server.Handler(CsMsgId.CsCharLevelUp)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCharLevelUp req = packet.DecodeBody<CsCharLevelUp>();

            Character character = session.chars.Find(c=>c.guid==req.CharObjID);
            if(character!=null)
            character.LevelUp(req.Items);

        }
       
    }
}
