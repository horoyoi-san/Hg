using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using Campofinale.Resource.Table;

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
                ShopGroupConditions =
                {
                    
                },
                FrequencyLimits =
                {
                    
                },
                Shops =
                {
                   /* new ScdShop()
                    {
                        ShopId="shop_pay_originium_recharge"
                    }*/
                }
            };
            foreach(ShopTable table in ResourceManager.shopTable.Values)
            {
                proto.Shops.Add(new ScdShop()
                {
                    ShopId=table.shopId,
                });
            }
            SetData(ScMsgId.ScShopSync, proto);
        }

    }
}
