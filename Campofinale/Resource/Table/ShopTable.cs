namespace Campofinale.Resource.Table
{
    public class IdTextPair
    {
        public long id;
        public string text;
    }

    public class ShopUnlockCondition
    {
        public string conditionId;
        public IdTextPair desc;
    }

    [TableCfgType("TableCfg/ShopTable.json", LoadPriority.LOW)]
    public class ShopTable : TableCfgResource
    {
        public string shopGroupId;
        public string shopId;
        public List<string> shopGoodsIds;
        public string iconId;
        public bool isShowWhenLock;
        public IdTextPair lockDesc;
        public IdTextPair shopName;
        public IdTextPair shopEnName;
        public int shopGroupNumber;
        public int shopRefreshCycleType;
        public int shopRefreshType;
        public List<ShopUnlockCondition> unlockConditions;
    }

    [TableCfgType("TableCfg/ShopGoodsTable.json", LoadPriority.LOW)]
    public class ShopGoodsTable : TableCfgResource
    {
        public string goodsId;
        public string shopId;
        public int sortId;
        public float cnDiscount;
        public string goodsTagId;
        public bool isShowWhenLock;
        public int limitCount;
        public int limitCountRefreshType;
        public IdTextPair lockDesc;
        public string moneyId;
        public int price;
        public int randomGoodsStandardPrice;
        public string relatedWeaponGachPoolId;
        public string rewardId;
        public string weaponGachaPoolId;
        public List<ShopUnlockCondition> unlockConditions;
    }
}
