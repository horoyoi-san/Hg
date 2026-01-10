namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/DomainDataTable.json", LoadPriority.LOW)]
    public class DomainDataTable : TableCfgResource
    {
        public string domainId;
        public int sortId;
        public List<string> levelGroup = [];
        public List<string> settlementGroup = [];
        public List<DomainDevelopmentLevel> domainDevelopmentLevel = [];

        public class DomainDevelopmentLevel
        {
            public int domainDevelopmentLevel;
            public string versionStart;
            public int levelUpExp;
            public bool isFinalMaxLevel;
            public string rewardId;
            public Dictionary<string, DomainDevelopmentLevelEffect> domainDevelopmentLevelEffect = new();
           
        }
        public class DomainDevelopmentLevelEffect
        {
            public int bandwidth;
            public int battleBuildingLimit;
            public int travelPoleLimit;
            public string levelId;
        }
    }
}
