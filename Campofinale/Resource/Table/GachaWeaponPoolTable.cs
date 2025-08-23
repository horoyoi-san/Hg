namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/GachaWeaponPoolTable.json", LoadPriority.LOW)]
    public class GachaWeaponPoolTable
    {
        public string id;
        public int type;
        public List<string> upWeaponIds;
        public List<string> closeTimes;
    }
}
