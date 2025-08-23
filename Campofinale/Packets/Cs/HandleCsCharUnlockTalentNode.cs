using Campofinale.Game.Char;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsCharUnlockTalentNode
    {
        [Server.Handler(CsMsgId.CsCharUnlockTalentNode)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCharUnlockTalentNode req = packet.DecodeBody<CsCharUnlockTalentNode>();
            
            Character character = session.chars.Find(c=>c.guid==req.CharObjId);
            if (character != null)
            {
                character.UnlockNode(req.NodeId);             
            }
        }
       
    }
}
