using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScSyncWallet : Packet
    {

        public PacketScSyncWallet(Player client) {

            ScSyncWallet proto = new ScSyncWallet()
            {
                MoneyList =
                {
                    new MoneyInfo()
                    {
                        Id="item_diamond",
                        Amount=(ulong)client.inventoryManager.item_diamond_amt,
                    },
                    new MoneyInfo()
                    {
                        Id="item_gold",
                        Amount=(ulong)client.inventoryManager.item_gold_amt,
                    }
                }
                
            };

            SetData(ScMsgId.ScSyncWallet, proto);
        }

    }
}
