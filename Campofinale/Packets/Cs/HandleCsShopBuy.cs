using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Game.Shop;
using Campofinale.Packets.Sc;
using StardustUtils;

namespace Campofinale.Packets.Cs
{
    public class HandleCsShopBuy
    {
        [Server.Handler(CsMsgId.CsShopBuy)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsShopBuy req = packet.DecodeBody<CsShopBuy>();

            // Process purchase through ShopManager
            bool success = ShopManager.ProcessPurchase(
                req.ShopId,
                req.GoodsId,
                req.Count,
                session.inventoryManager
            );

            if (!success)
            {
                Logger.PrintWarn($"[HandleCsShopBuy] Purchase failed: shop={req.ShopId}, goods={req.GoodsId}, count={req.Count}");
            }

            session.Send(new PacketScShopBuyResp(session, new ScShopBuyResp()
            {
                ShopId = req.ShopId,
                GoodsId = req.GoodsId,
                Count = req.Count,
            }));
        }
    }
}