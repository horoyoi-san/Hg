namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/SNSChatTable.json", LoadPriority.LOW)]
    public class SNSChatTable
    {
        public string chatId;
        public int chatType;
        public int tagType;
    }
}
