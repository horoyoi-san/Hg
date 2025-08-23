namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/LevelGradeTable.json", LoadPriority.LOW)]
    public class LevelGradeTable : TableCfgResource
    {
        public string name;
        public List<LevelGradeInfo> grades;
    }
    public class LevelGradeInfo
    {
        public int bandwidth;
        public int battleBuildingLimit;
        public int grade;
        public int monsterBaseLevel;
        public int prosperity;
        public int travelPoleLimit;
    }
}
