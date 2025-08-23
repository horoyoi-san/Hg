using Campofinale.Database;
using Campofinale.Protocol;
using Campofinale.Resource;
using Campofinale.Resource.Table;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace Campofinale.Game.MissionSys
{
    public class MissionSystem
    {
        public Player owner;
        public List<GameMission> missions=new();
        public List<GameQuest> quests=new();
        public string curMission = "e0m0";

        public MissionSystem(Player o)
        {
            owner = o;
        }
        public ScSyncAllMission ToProto()
        {
            if (!Server.config.serverOptions.missionsEnabled)
            {
                string json1 = File.ReadAllText("44_ScSyncAllMission.json");
                ScSyncAllMission m = Newtonsoft.Json.JsonConvert.DeserializeObject<ScSyncAllMission>(json1);
                m.TrackMissionId = "";
                return m;
            }
            ScSyncAllMission sync = new ScSyncAllMission();
            sync.TrackMissionId = curMission;
            missions.ForEach(m =>
            {
                if(!sync.Missions.ContainsKey(m.missionId))
                sync.Missions.Add(m.missionId, new Mission()
                {
                    MissionId = m.missionId,
                    MissionState = (int)m.state,
                    
                });
            });
            
            quests.ForEach(q =>
            {
                Quest quest=new Quest()
                {
                    QuestId = q.questId,
                    QuestState = (int)q.state,

                };
                var data = GetQuestData(q.questId);
                data.objectiveList.ForEach(o =>
                {
                    quest.QuestObjectives.Add(new QuestObjective()
                    {
                        ConditionId = o.condition.uniqueId,
                        Values =
                        {
                            {o.condition.uniqueId,0 }
                        }
                    });
                });
                sync.CurQuests.Add(q.questId, quest);
                
            });
            return sync;
        }
        public MissionDataTable.QuestInfo GetQuestData(string id)
        {
            MissionDataTable.QuestInfo quest = null;
            foreach(MissionDataTable m in ResourceManager.missionDataTable)
            {
                if(m.questDic.TryGetValue(id, out quest))
                {
                    return quest;
                }
            };

            return quest;
        }
        public void Save()
        {
            DatabaseManager.db.UpsertMissionData(new MissionData()
            {
                roleId=owner.roleId,
                curMission=curMission,
                missions=missions,
                quests=quests,
            });
        }
        public void Load()
        {
            MissionData data= DatabaseManager.db.LoadMissionData(owner.roleId);
            if (data != null)
            {
                curMission = data.curMission;
                missions = data.missions;
                quests = data.quests;
            }
        }
        public void AddMission(string id,MissionState state = MissionState.Available, bool notify=false)
        {
            MissionDataTable data = ResourceManager.missionDataTable.Find(m=>m.missionId == id);
            if (data != null)
            {
                missions.Add(new GameMission(id, state));
                if (notify)
                {
                    
                    ScMissionStateUpdate s = new()
                    {
                        MissionId = data.missionId,
                        MissionState = (int)state,
                        SucceedId=-1,

                    };
                }
                
                int i = 0;
                foreach (var q in data.questDic.Values)
                {
                    AddQuest(q, false);
                }
            }
        }
        public GameQuest GetQuestById(string id)
        {
            return quests.Find(q => q.questId == id);
        }
        public void AddQuest(MissionDataTable.QuestInfo data,bool notify=false)
        {
            GameQuest quest = GetQuestById(data.questId);
            if (quest == null)
            {
                quest = new GameQuest(data.questId);
                quest.state = QuestState.Available;
                if (notify)
                {
                    ScQuestObjectivesUpdate upd = new()
                    {
                        QuestId = data.questId,
                        
                    };
                    data.objectiveList.ForEach(o =>
                    {
                        upd.QuestObjectives.Add(new QuestObjective()
                        {
                            ConditionId=o.condition.uniqueId,
                            Values =
                            {
                                {o.condition.uniqueId,0 }
                            }
                        });
                    });
                    ScQuestStateUpdate update = new()
                    {
                        QuestId = quest.questId,
                        QuestState = (int)quest.state,
                        RoleBaseInfo = owner.GetRoleBaseInfo()
                    };
                    owner.Send(ScMsgId.ScQuestStateUpdate, update);
                    owner.Send(ScMsgId.ScQuestObjectivesUpdate, upd);
                }
               
                quests.Add(quest);
            }
        }
        public void ProcessQuest(string id)
        {
            GameQuest quest = GetQuestById(id);
            if (quest != null)
            {
               
                quest.state = QuestState.Processing;
                var data = GetQuestData(id);
                ScQuestStateUpdate update = new()
                {
                    QuestId = quest.questId,
                    QuestState = (int)quest.state,
                    RoleBaseInfo = owner.GetRoleBaseInfo()
                };
                ScQuestObjectivesUpdate upd = new()
                {
                    QuestId = data.questId,

                };
                data.objectiveList.ForEach(o =>
                {
                    upd.QuestObjectives.Add(new QuestObjective()
                    {
                        ConditionId = o.condition.uniqueId,
                        Values =
                        {
                            {o.condition.uniqueId,0 }
                        }
                    });
                });
                owner.Send(ScMsgId.ScQuestObjectivesUpdate, upd);
                owner.Send(ScMsgId.ScQuestStateUpdate, update);
                
            }
        }
        public void CompleteQuest(string id)
        {
            GameQuest quest = GetQuestById(id);
            if (quest != null)
            {
                quest.state = QuestState.Completed;
                var data = GetQuestData(id);
                ScQuestStateUpdate update = new()
                {
                    QuestId = quest.questId,
                    QuestState=(int)quest.state,
                };
                ScQuestObjectivesUpdate upd = new()
                {
                    QuestId = data.questId,

                };
                data.objectiveList.ForEach(o =>
                {
                    upd.QuestObjectives.Add(new QuestObjective()
                    {
                        ConditionId = o.condition.uniqueId,
                        IsComplete=true,
                        Values =
                        {
                            {o.condition.uniqueId,1 }
                        }
                    });
                });
                owner.Send(ScMsgId.ScQuestObjectivesUpdate, upd);
                owner.Send(ScMsgId.ScQuestStateUpdate, update);
                quests.Remove(quest);
            }
        }

        public void TrackMission(string v)
        {
            curMission = v;
            owner.Send(ScMsgId.ScTrackMissionChange, new ScTrackMissionChange()
            {
                MissionId = curMission,
            });
        }

        public void CompleteMission(string v)
        {
            if(curMission == v)
            {
                TrackMission("");
            }
            GameMission mission = missions.Find(m => m.missionId == v);
            MissionDataTable data = ResourceManager.missionDataTable.Find(m => m.missionId == v);
            if (mission != null && data != null)
            {
                mission.state=MissionState.Completed;
                ScMissionStateUpdate s = new()
                {
                    MissionId = mission.missionId,
                    MissionState = (int)mission.state,
                    SucceedId = -1,

                };
                owner.Send(ScMsgId.ScMissionStateUpdate, s);
                //TODO rewards
            }
        }
    }
    
    
}
