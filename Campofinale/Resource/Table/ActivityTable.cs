using Campofinale.Resource.Json;

namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/ActivityTable.json", LoadPriority.LOW)]
    public class ActivityTable : TableCfgResource
    {
        public string id;
        public ActivityType type;
        public List<ActivityCondition> conditions=new();

        public class ActivityCondition
        {
            public string conditionId;
            public ConditionType conditionType;
            public int compareOperator;
            public int progressToCompare;
        }
    }
}
