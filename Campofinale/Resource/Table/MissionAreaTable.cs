namespace Campofinale.Resource.Table
{
    [TableCfgType("Json/GameplayConfig/MissionAreaTable.json", LoadPriority.LOW)]
    public class MissionAreaTable : TableCfgResource
    {
        public Dictionary<string, Dictionary<string, object>> m_areas;
    }
}
