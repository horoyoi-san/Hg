namespace Campofinale.Resource.Table
{
    /// <summary>
    /// Factory panel store table for region upgrade and bus placement goods.
    /// </summary>
    public class FactoryPanelStoreTable
    {
        public string id;
        public string regionId;
        public int regionIndex;
        public int goodType; // 1 = RegionLevelUp, 2 = BusPlace
        public int cost;
        public string currencyType;
        public int sortId;
        public NameData name;
        public List<int> actions = new();
        public List<ActionParamsData> actionParamsList = new();
        public List<int> conditions = new();
        public List<ConditionParamsData> conditionParamsList = new();
        public List<int> busFreeShowCounts = new();
        public class ActionParamsData
        {
            public List<string> actionParams = new();
        }
        public class ConditionParamsData
        {
            public List<string> conditionParams = new();
        }
        public class NameData
        {
            public long id;
            public string text;
        }
    }
}

