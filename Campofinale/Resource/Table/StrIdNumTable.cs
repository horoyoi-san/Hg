using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/StrIdNumTable.json", LoadPriority.LOW)]
    public class StrIdNumTable : TableCfgResource
    {
        public StrIdDic skill_group_id = new();
        public StrIdDic item_id = new();
        public Dictionary<string, int> dialogStrToNum = new();
        public StrIdDic chapter_map_id = new();
        public StrIdDic char_voice_id = new();
        public StrIdDic char_doc_id = new();
        public StrIdDic area_id = new();
        public StrIdDic map_mark_temp_id = new();
        public StrIdDic wiki_id = new();
        public StrIdDic client_game_var_string_id = new();
        public StrIdDic user_avatar_id = new();
        public StrIdDic business_card_topic_id = new();
        public StrIdDic user_avatar_frame_id = new();
    }
}
