namespace Campofinale.Resource.Json
{
    //Beyond.Gameplay.MissionRuntimeAsset
    public class MissionRuntimeAsset
    {
        public string missionId;
        public string rewardId;
        public MissionType missionType;
        public string charId;
        public string levelId;
        public Dictionary<string, QuestInfo> questDic;
        public int onMissionAcceptId;
        public int onMissionCompletedId;
        public int onMissionFailedId;

        public class QuestInfo
        {
            public string questId;
            public bool optional;
            public bool autoSucceed;
            public bool autoRestartWhenFailed;
            public int objectiveConditionNum;
            public string rewardId;
            public List<QuestObjective> objectiveList;

            public class QuestObjective
            {
                public ObjectiveCond condition;

                public class ObjectiveCond
                {
                    public string uniqueId;
                }
            }
        }
        public enum MissionType
        {
            Main = 0,
            Char = 1,
            Factory = 2,
            Bloc = 3,
            Hide = 4,
            Misc = 5,
            Dungeon = 6,
            World = 7,
            WeekRaid = 8,
            FakeMain = 9,
            Side = 10,
            Activity = 11,
        }
    }
}
