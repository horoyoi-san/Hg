using Campofinale.Game.Char;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScCharBagDelChar : Packet
    {
        public PacketScCharBagDelChar(Player player, Character character)
        {
            ScCharBagDelChar proto = new ScCharBagDelChar()
            {
                CharInstId = character.guid,
                ScopeName = 1,
            };

            SetData(ScMsgId.ScCharBagDelChar, proto);
        }
    }
}
