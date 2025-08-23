using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/StrIdNumTable.json", LoadPriority.LOW)]
    public class StrIdNumTable : TableCfgResource
    {
        public StrIdDic skill_group_id;
        public StrIdDic item_id;
        public Dictionary<string, int> dialogStrToNum;
        public StrIdDic chapter_map_id;
        public StrIdDic char_voice_id;
        public StrIdDic char_doc_id;
        public StrIdDic area_id;
        public StrIdDic map_mark_temp_id;
        public StrIdDic wiki_id;
        public StrIdDic client_game_var_string_id;
    }
}
