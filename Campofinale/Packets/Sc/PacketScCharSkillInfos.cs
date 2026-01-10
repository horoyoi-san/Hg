using Campofinale.Game.Char;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    /// <summary>
    /// Packet for sending character skill information to client.
    /// This message is used to sync skill level information for a character.
    /// </summary>
    public class PacketScCharSkillInfos : Packet
    {
        public PacketScCharSkillInfos(Character character)
        {
            var skillInfo = character.GetSkillInfo();

            ScCharSkillInfos proto = new()
            {
                CharObjId = character.guid,
            };

            // Copy LevelInfo from SkillInfo to ScCharSkillInfos
            foreach (var levelInfo in skillInfo.LevelInfo)
            {
                proto.LevelInfos.Add(new SkillLevelInfo()
                {
                    SkillId = levelInfo.SkillId,
                    SkillLevel = levelInfo.SkillLevel,
                    SkillMaxLevel = levelInfo.SkillMaxLevel,
                    SkillEnhancedLevel = levelInfo.SkillEnhancedLevel,
                });
            }

            SetData(ScMsgId.ScCharSkillInfos, proto);
        }
    }
}

