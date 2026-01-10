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
using StardustUtils;

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
            AdventureBookData toLoad = DatabaseManager.db.LoadAdventureBookData(player.roleId);
            if (toLoad != null)
            {
                data = toLoad;
            }
            else
            {
                data.roleId = player.roleId;
                data.claimedStageRewards = new HashSet<int>();
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
        public void TaskUpdate(ConditionType condType, object obj = null)
        {
            List<GameAdventureTask> toUpdate = new();
            data.tasks.FindAll(t => t.GetTaskTable().conditionType == condType).ForEach(task =>
            {
                if (task.TaskUpdate(this.player, obj))
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
        public void InitNextStage(bool notify = false)
        {
            data.adventureBookStage++;
            data.tasks.RemoveAll(t => t.GetTaskTable().taskType == AdventureTaskType.AdventureBook);
            ResourceManager.adventureTaskTable.Values.ToList().ForEach(task =>
            {
                if (task.adventureBookStage == data.adventureBookStage)
                {
                    data.tasks.Add(new GameAdventureTask()
                    {
                        adventureTaskId = task.adventureTaskId,
                        claimed = false
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
                if (t.GetTaskTable().taskType == taskType && t.GetState() == AdventureTaskState.Completed)
                {
                    t.ClaimRewards(player);
                }
            });
        }

        public void ClaimStageReward(int stage)
        {
            // Check if the stage reward has already been claimed or is not valid
            if (data.claimedStageRewards.Contains(stage) || stage > data.adventureBookStage)
            {
                return;
            }

            if (!ResourceManager.adventureBookStageRewardTable.ContainsKey(stage))
            {
                Logger.PrintWarn($"No stage reward config for stage {stage}");
                return;
            }

            var stageRewardConfig = ResourceManager.adventureBookStageRewardTable[stage];

            // Verify all tasks in this stage are completed
            foreach (var taskId in stageRewardConfig.taskIds)
            {
                var task = data.tasks.Find(t => t.adventureTaskId == taskId);
                if (task == null || !task.claimed)
                {
                    return;
                }
            }

            if (!string.IsNullOrEmpty(stageRewardConfig.rewardId))
            {
                var rewardConfig = rewardTable[stageRewardConfig.rewardId];
                foreach (var itemBundle in rewardConfig.itemBundles)
                {
                    // Add each item in the reward bundle directly to inventory
                    player.inventoryManager.AddItem(itemBundle.id, itemBundle.count);
                }
            }

            data.claimedStageRewards.Add(stage);
        }

        public bool CanCheckinToday()
        {
            // Check if already checked in today
            var today = DateTime.UtcNow.Date;
            var lastCheckin = DateTimeOffset.FromUnixTimeMilliseconds(data.lastCheckinTime).Date;
            return today > lastCheckin; // Can only check in once per day
        }

        public void DoCheckin(string activityId)
        {
            if (!CanCheckinToday())
            {
                Logger.PrintWarn($"Player {player.roleId} already checked in today");
                // todo: fix this. 
                // return;
            }

            // Get checkin reward configuration from CheckInRewardTable
            int currentDay = data.dailyCheckinDay + 1;

            string rewardId = null;
            if (checkInRewardTable.ContainsKey(activityId))
            {
                var checkInConfig = checkInRewardTable[activityId];
                var stage = checkInConfig.stageList.Find(s => s.day == currentDay);
                if (stage != null)
                {
                    rewardId = stage.rewardId;
                }
            }

            if (string.IsNullOrEmpty(rewardId))
            {
                // No reward configured for this day, skip reward granting
                Logger.PrintWarn($"No reward configured for checkin day {currentDay} in activity {activityId}");
            }

            // Update checkin data
            data.dailyCheckinDay = currentDay;
            data.lastCheckinTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

            // Grant rewards - add items directly to inventory instead of dropping them on ground
            if (!string.IsNullOrEmpty(rewardId) && rewardTable.ContainsKey(rewardId))
            {
                var rewardConfig = rewardTable[rewardId];
                foreach (var itemBundle in rewardConfig.itemBundles)
                {
                    // Add each item in the reward bundle directly to inventory
                    player.inventoryManager.AddItem(itemBundle.id, itemBundle.count);
                }
                Logger.Print($"Player {player.roleId} checked in day {currentDay} for activity {activityId}, received reward {rewardId}");
            }
            else if (!string.IsNullOrEmpty(rewardId))
            {
                Logger.PrintWarn($"Reward {rewardId} not found for checkin day {currentDay}");
            }

            Save();
        }

        public class GameAdventureTask
        {
            public string adventureTaskId;
            public int progress;
            public bool claimed;

            public void ClaimRewards(Player player)
            {
                var taskTable = GetTaskTable();
                if (!string.IsNullOrEmpty(taskTable.rewardId) && rewardTable.ContainsKey(taskTable.rewardId))
                {
                    var rewardConfig = rewardTable[taskTable.rewardId];
                    foreach (var itemBundle in rewardConfig.itemBundles)
                    {
                        // Add each item in the reward bundle directly to inventory
                        player.inventoryManager.AddItem(itemBundle.id, itemBundle.count);
                    }
                }
                claimed = true;
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
                if (progress < GetTaskTable().progressToCompare)
                {
                    return AdventureTaskState.Processing;
                }
                else if (!claimed)
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
                if (conditions.TryGetValue(GetTaskTable().conditionId, out cond))
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
                                if (c.level >= cond.ToInt(0))
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
                return adventureTaskTable.Values.ToList().Find(a => a.adventureTaskId == adventureTaskId);
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
            public int dailyCheckinDay = 0;
            public long lastCheckinTime = 0;
            public HashSet<int> claimedStageRewards = new();
        }
    }

}
