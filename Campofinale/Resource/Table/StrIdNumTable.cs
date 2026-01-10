using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/StrIdNumTable.json", LoadPriority.LOW)]
    public class StrIdNumTable : TableCfgResource
    {
        public StrIdDic skill_group_id = new();
        public StrIdDic char_id = new();
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
        public StrIdDic domain_depot_id = new();
        public StrIdDic wiki_tutorial_id = new();
        public StrIdDic prts_first_lv_id = new();
        public StrIdDic prts_investigate_id = new();
        public StrIdDic prts_collect_id = new();
        public StrIdDic prts_terminal_content_id = new();
        public StrIdDic prts_investigate_note_id = new();
        public StrIdDic npc_proxy_id = new();
        public int GetNpcProxyId(string proxyId)
        {
            if (npc_proxy_id?.dic != null && npc_proxy_id.dic.TryGetValue(proxyId, out int numericId))
            {
                return numericId;
            }
            return 0;
        }
        public bool TryGetNpcProxyId(string proxyId, out int numericId)
        {
            if (npc_proxy_id?.dic != null && npc_proxy_id.dic.TryGetValue(proxyId, out numericId))
            {
                return true;
            }
            numericId = 0;
            return false;
        }
    }
}
