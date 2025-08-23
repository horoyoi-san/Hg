using Campofinale.Database;
using Campofinale.Game.Factory;
using Campofinale.Game.Spaceship;
using Campofinale.Resource;
using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Bson;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using static Campofinale.Resource.ResourceManager;
using MongoDB.Bson.Serialization.IdGenerators;
using Campofinale.Game.Char;
using Campofinale.Resource.Json;
using Campofinale.Protocol;

namespace Campofinale.Game.Adventure
{
    public class AdventureBookManager
    {
        public Player player;
        public AdventureBookData data = new();

        public AdventureBookManager(Player player)
        {
            this.player = player;
        }
        public void Load()
        {
            AdventureBookData toLoad= DatabaseManager.db.LoadAdventureBookData(player.roleId);
            if (toLoad != null)
            {
                data = toLoad;
            }
            else
            {
                data.roleId = player.roleId;
            }
            if (data.adventureBookStage == 0)
            {
                InitNextStage();
            }
        }
        
        public void DailyReset()
        {
            data.tasks.RemoveAll(t => t.GetTaskTable().taskType == AdventureTaskType.Daily);
            data.dailyActivation = 0;
            data.dailyCharLevelUp = 0;
            data.dailyLogin = 0;
            ResourceManager.adventureTaskTable.Values.ToList().ForEach(task =>
            {
                if (task.taskType == AdventureTaskType.Daily)
                {
                    data.tasks.Add(new GameAdventureTask()
                    {
                        adventureTaskId = task.adventureTaskId,
                        claimed = false
                    });
                }
            });
        }
        public void Save()
        {
            DatabaseManager.db.UpsertAdventureBookData(data);
        }
        public void TaskUpdate(ConditionType condType, object obj=null)
        {
            List<GameAdventureTask> toUpdate = new();
            data.tasks.FindAll(t=>t.GetTaskTable().conditionType==condType).ForEach(task =>
            {
                if(task.TaskUpdate(this.player, obj))
                {
                    toUpdate.Add(task);
                }
            });
            if (toUpdate.Count > 0)
            {
                ScAdventureTaskModify modify = new ScAdventureTaskModify()
                {
                    
                };
                toUpdate.ForEach(t =>
                {
                    modify.Tasks.Add(t.ToProto());
                });
                player.Send(ScMsgId.ScAdventureTaskModify, modify);
            }
        }
        public void InitNextStage(bool notify=false)
        {
            data.adventureBookStage++;
            data.tasks.RemoveAll(t => t.GetTaskTable().taskType == AdventureTaskType.AdventureBook);
            ResourceManager.adventureTaskTable.Values.ToList().ForEach(task =>
            {
                if(task.adventureBookStage == data.adventureBookStage)
                {
                    data.tasks.Add(new GameAdventureTask()
                    {
                        adventureTaskId = task.adventureTaskId,
                        claimed=false
                    });
                }
            });
            //TODO Update everything
        }

        public void ClaimTask(string taskId)
        {
            data.tasks.ForEach(t =>
            {
                if (t.adventureTaskId == taskId && t.GetState() == AdventureTaskState.Completed)
                {
                    t.ClaimRewards(player);
                }
            });
        }

        public void ClaimTasks(AdventureTaskType taskType)
        {
            data.tasks.ForEach(t =>
            {
                if (t.GetTaskTable().taskType==taskType && t.GetState() == AdventureTaskState.Completed)
                {
                    t.ClaimRewards(player);
                }
            });
        }

        public class GameAdventureTask
        {
            public string adventureTaskId;
            public int progress;
            public bool claimed;

            public void ClaimRewards(Player player)
            {
                player.inventoryManager.AddRewards(GetTaskTable().rewardId, player.position, 0);
                claimed= true;
                ScAdventureTaskModify modify = new()
                {
                    Tasks =
                    {
                        ToProto()
                    }
                };
                player.Send(ScMsgId.ScAdventureTaskModify, modify);
            }
            public AdventureTaskState GetState()
            {
                if(progress < GetTaskTable().progressToCompare)
                {
                    return AdventureTaskState.Processing;
                }else if (!claimed)
                {
                    return AdventureTaskState.Completed;
                }
                else
                {
                    return AdventureTaskState.Rewarded;
                }
            }
            public bool TaskUpdate(Player owner, object obj)
            {
                ConditionType condType = GetTaskTable().conditionType;
                ConditionData cond;
                if(ResourceManager.conditions.TryGetValue(GetTaskTable().conditionId, out cond))
                {
                    int count = 0;
                    switch (condType)
                    {
                        case ConditionType.CheckStatisticVal:
                            switch (Enum.Parse(typeof(StatType), cond.Get(0)))
                            {
                                case StatType.DailyCharLevelUp:
                                    count = owner.adventureBookManager.data.dailyCharLevelUp;
                                    break;
                                case StatType.DailyLogin:
                                    count = owner.adventureBookManager.data.dailyLogin;
                                    break;
                                default:
                                    break;
                            }
                            if (count > progress)
                            {
                                progress = count;
                                return true;
                            }
                            else
                            {
                                return false;
                            }
                        case ConditionType.CheckGreaterCharLevelNum:
                            count = 0;
                            owner.chars.ForEach(c =>
                            {
                                if(c.level >= cond.ToInt(0))
                                {
                                    count++;
                                }
                            });
                            if (count > progress)
                            {
                                progress = count;
                                return true;
                            }
                            else
                            {
                                return false;
                            }
                        default:
                            return false;
                    }
                }
                else
                {
                    return false;
                }
                
            }
            public AdventureTaskTable GetTaskTable()
            {
                return ResourceManager.adventureTaskTable.Values.ToList().Find(a => a.adventureTaskId == adventureTaskId);
            }

            public AdventureTask ToProto()
            {
                return new AdventureTask()
                {
                    Progress = progress,
                    State = (int)GetState(),
                    TaskId = adventureTaskId,
                };
            }
        }
        public class AdventureBookData
        {
            [BsonId(IdGenerator = typeof(ObjectIdGenerator))]
            public ObjectId _id { get; set; }
            public ulong roleId;
            public int adventureBookStage = 0;
            public int dailyActivation = 0;
            public List<GameAdventureTask> tasks = new();
            public int dailyCharLevelUp = 0;
            public int dailyLogin = 0;

        }
    }

}
