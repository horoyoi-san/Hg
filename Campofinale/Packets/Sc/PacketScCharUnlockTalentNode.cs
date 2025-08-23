using Campofinale.Game.Char;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScCharUnlockTalentNode : Packet
    {

        public PacketScCharUnlockTalentNode(Player client, Character character, string nodeId) {

            ScCharUnlockTalentNode proto = new ScCharUnlockTalentNode()
            {
                CharObjId=character.guid,
                NodeId= nodeId,
            };

            SetData(ScMsgId.ScCharUnlockTalentNode, proto);
        }

    }
}
