using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    internal class PacketScShopBuyResp : Packet
    {
        public PacketScShopBuyResp(Player client, ScShopBuyResp result)
        {
            ScShopBuyResp proto = new ScShopBuyResp()
            {
                ShopId = result.ShopId,
                GoodsId = result.GoodsId,
                Count = result.Count
            };
            SetData(ScMsgId.ScShopBuyResp, proto);
        }
    }
}