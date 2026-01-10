namespace Campofinale.Resource.Table
{
    /// <summary>
    /// Battle Pass track table.
    /// Represents different reward tracks in the battle pass system (free, originium, pay).
    /// </summary>
    [TableCfgType("TableCfg/BattlePassTrackTable.json", LoadPriority.LOW)]
    public class BattlePassTrackTable : TableCfgResource
    {
        public string? trackId;
        public int trackType; // 0=free, 1=originium, 2=pay
        public int bpExpUpRatio;
    }

    /// <summary>
    /// Battle Pass level group table.
    /// Contains level information for a battle pass season/group.
    /// </summary>
    [TableCfgType("TableCfg/BattlePassLevelTable.json", LoadPriority.LOW)]
    public class BattlePassLevelGroupTable : TableCfgResource
    {
        public string? levelGroupId;
        public Dictionary<string, BattlePassLevelInfo>? levelInfos;
    }

    /// <summary>
    /// Battle Pass level information.
    /// Represents reward configuration for a specific battle pass level.
    /// </summary>
    public class BattlePassLevelInfo
    {
        public int level;
        public int levelExp;
        public string? freeRewardId;
        public string? originiumRewardId;
        public string? payRewardId;
        public bool isMilestone;
        public bool isRecurring;
        public int buyHintType;
    }
}

