using Campofinale.Game.Char;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScCharBagAddChar : Packet
    {

        public PacketScCharBagAddChar(Player client,Character chara) {

            ScCharBagAddChar proto = new ScCharBagAddChar()
            {
                Char = chara.ToProto(),
                ScopeName=1,
            };

            SetData(ScMsgId.ScCharBagAddChar, proto);
        }

    }
}
