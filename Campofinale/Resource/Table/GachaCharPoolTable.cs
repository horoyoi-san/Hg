namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/GachaCharPoolTable.json", LoadPriority.LOW)]
    public class GachaCharPoolTable
    {
        public string id;
        public List<string> upCharIds;
        public int type;
    }
}
