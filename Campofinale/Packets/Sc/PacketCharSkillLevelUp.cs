using Campofinale.Game.Char;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketCharSkillLevelUp : Packet
    {
        public PacketCharSkillLevelUp(Character character, CsCharSkillLevelUp req)
        {
            ScCharSkillLevelUp skillLevelUp = new()
            {
                CharObjId = character.guid,
                LevelInfo = new SkillLevelInfo()
                {
                    SkillId = req.SkillId,
                    SkillLevel = character.GetSkillMaxLevel(),
                    SkillMaxLevel = character.GetSkillMaxLevel(),
                    SkillEnhancedLevel = 3,
                },
            };
            SetData(ScMsgId.ScCharSkillLevelUp, skillLevelUp);
        }
    }
}