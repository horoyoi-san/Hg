using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/CharacterTable.json", LoadPriority.LOW)]
    public class CharacterTable : TableCfgResource
    {
        public List<Attributes> attributes;
        public string charId;
        public int weaponType;
        public string engName;
        public int rarity;

    }
}
