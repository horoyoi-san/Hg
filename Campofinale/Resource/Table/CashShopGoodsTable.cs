
namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/CashShopGoodsTable.json", LoadPriority.LOW)]
    public class CashShopGoodsTable : TableCfgResource
    {
        public string cashGoodsId;
        public string cashShopId;
        public CashGoodsType goodsType;
        public long priceCNY;
        public double priceUSD;

        public PlatformGoodsLimitType GetLimitType()
        {
            switch (goodsType)
            {
                case CashGoodsType.GiftPack:
                    return PlatformGoodsLimitType.PgltGiftPack;
                case CashGoodsType.MonthlyCard:
                    return PlatformGoodsLimitType.PgltCommon;
                case CashGoodsType.BattlePass:
                    return PlatformGoodsLimitType.PgltCommon;
                case CashGoodsType.Recharge:
                    return PlatformGoodsLimitType.PgltOnceBonus;
                default:
                    return PlatformGoodsLimitType.PgltCommon;
            }
        }
    }
    public enum CashGoodsType // TypeDefIndex: 37819
    {
        GiftPack = 0,
        MonthlyCard = 1,
        BattlePass = 2,
        Recharge = 3,
    }
}
