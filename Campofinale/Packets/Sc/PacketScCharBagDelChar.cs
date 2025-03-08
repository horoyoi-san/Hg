using Campofinale.Game.Character;
using Campofinale.Network;
using Campofinale.Protocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

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
