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
                    },
                    new MoneyInfo()
                    {
                        Id="item_originium_recharge",
                        Amount=(ulong)client.inventoryManager.item_originium_recharge_amt,
                    },
                    new MoneyInfo()
                    {
                        Id="item_domain_tundra_coupon",
                        Amount=(ulong)client.inventoryManager.item_domain_tundra_coupon_amt,
                    },
                    new MoneyInfo()
                    {
                        Id="item_domain_jinlong_coupon",
                        Amount=(ulong)client.inventoryManager.item_domain_jinlong_coupon_amt,
                    }
                }
                
            };

            SetData(ScMsgId.ScSyncWallet, proto);
        }

    }
}
