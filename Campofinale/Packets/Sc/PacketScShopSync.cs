using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScShopSync : Packet
    {

        public PacketScShopSync(Player client) {

            ScShopSync proto = new ScShopSync()
            {
                ShopGroupData = new()
                {
                    
                },
                FrequencyLimitMgr = new()
                {
                    
                },
                
            };

            SetData(ScMsgId.ScShopSync, proto);
        }

    }
}
