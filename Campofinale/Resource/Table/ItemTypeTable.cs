namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/ItemTypeTable.json", LoadPriority.LOW)]
    public class ItemTypeTable
    {
        public int itemType;
        public ItemStorageSpace storageSpace;
    }
}
