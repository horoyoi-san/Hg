using Campofinale.Game.Char;
using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsCharSkillLevelUp
    {
        [Server.Handler(CsMsgId.CsCharSkillLevelUp)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCharSkillLevelUp req = packet.DecodeBody<CsCharSkillLevelUp>();
            Character? character = session.chars.Find(c => c.guid == req.CharObjId);
            if (character != null)
            {
                // TODO: no db operation now, just respond with max level.
                session.Send(new PacketCharSkillLevelUp(character, req));
            }
        }
    }
}