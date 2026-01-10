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

namespace Campofinale.Game.BP
{
    public class BattlePassManager
    {
        public Player player;
        public static string currentSeasonId = "bp_01";
        public BattlePassPlayerData data = new();
        public BattlePassManager(Player player)
        {
            this.player = player;
        }
        public void Load()
        {
            BattlePassPlayerData toLoad = DatabaseManager.db.LoadBPPlayerData(player.roleId, currentSeasonId);
            if (toLoad != null)
            {
                data = toLoad;
                // Ensure claimedRewards is initialized if null (for backward compatibility)
                if (data.claimedRewards == null)
                {
                    data.claimedRewards = new Dictionary<string, HashSet<int>>();
                }
            }
            else
            {
                data.roleId = player.roleId;
                data.seasonId = currentSeasonId;
                data.level = 1;
                data.claimedRewards = new Dictionary<string, HashSet<int>>();
            }
        }

        public void DailyReset()
        {

        }
        public void Save()
        {
            DatabaseManager.db.UpsertBPPlayerData(data);
        }

        public bool PurchaseOriginiumTrack()
        {
            if (data.ownOriginiumTier)
            {
                Logger.PrintWarn($"[BattlePassManager] Player {player.accountId} already has originium track");
                return false;
            }

            // TODO: Check and deduct currency when economy system is implemented
            // For now, just grant it for free

            data.ownOriginiumTier = true;
            Save();
            Logger.Print($"[BattlePassManager] Player {player.accountId} purchased originium track");
            return true;
        }

        public bool PurchaseLevels(int targetLevel)
        {
            if (targetLevel <= data.level)
            {
                Logger.PrintWarn($"[BattlePassManager] Player {player.accountId} target level {targetLevel} is not greater than current level {data.level}");
                return false;
            }

            int levelsToBuy = targetLevel - data.level;

            // TODO: Calculate cost and check/deduct currency when economy system is implemented
            // For now, just grant it for free

            data.level = targetLevel;
            data.exp = 0; // Reset exp when buying levels
            Save();

            Logger.Print($"[BattlePassManager] Player {player.accountId} purchased {levelsToBuy} levels, new level: {data.level}");
            return true;
        }

        public ScdBpLevelData GetLevelData()
        {
            return new ScdBpLevelData
            {
                CurLevel = data.level,
                CurExp = data.exp
            };
        }

        /// <summary>
        /// Convert a set of claimed levels to rewardState bitmap format.
        /// Each uint64 represents 64 levels using bit flags.
        /// </summary>
        private List<ulong> BuildRewardState(HashSet<int> claimedLevels)
        {
            if (claimedLevels == null || claimedLevels.Count == 0)
                return new List<ulong>();

            const int BITS_PER_UINT64 = 64;
            int maxLevel = claimedLevels.Count > 0 ? claimedLevels.Max() : 0;
            int arraySize = (maxLevel / BITS_PER_UINT64) + 1;
            List<ulong> rewardState = new List<ulong>(new ulong[arraySize]);

            foreach (int level in claimedLevels)
            {
                int arrayIndex = level / BITS_PER_UINT64;
                int bitIndex = level % BITS_PER_UINT64;
                rewardState[arrayIndex] |= (1UL << bitIndex);
            }

            return rewardState;
        }

        /// <summary>
        /// Check if a reward level has been claimed for a track.
        /// </summary>
        public bool IsRewardClaimed(string trackId, int level)
        {
            if (data.claimedRewards == null)
                return false;

            if (!data.claimedRewards.TryGetValue(trackId, out var claimedLevels))
                return false;

            return claimedLevels.Contains(level);
        }

        /// <summary>
        /// Mark a reward level as claimed for a track.
        /// </summary>
        public void MarkRewardClaimed(string trackId, int level)
        {
            if (data.claimedRewards == null)
                data.claimedRewards = new Dictionary<string, HashSet<int>>();

            if (!data.claimedRewards.TryGetValue(trackId, out var claimedLevels))
            {
                claimedLevels = new HashSet<int>();
                data.claimedRewards[trackId] = claimedLevels;
            }

            claimedLevels.Add(level);
        }

        public ScdBpTrackMgr GetTrackMgrData()
        {
            var trackMgr = new ScdBpTrackMgr();

            // Add free track (always available)
            var freeTrackData = new ScdBpTrackRewardData
            {
                BpTrackId = "bp_track_free"
            };
            if (data.claimedRewards != null && data.claimedRewards.TryGetValue("bp_track_free", out var freeClaimedLevels))
            {
                freeTrackData.RewardState.AddRange(BuildRewardState(freeClaimedLevels));
            }
            trackMgr.TrackData.Add(freeTrackData);

            // Add originium track if owned
            if (data.ownOriginiumTier)
            {
                var originiumTrackData = new ScdBpTrackRewardData
                {
                    BpTrackId = "bp_track_originium"
                };
                if (data.claimedRewards != null && data.claimedRewards.TryGetValue("bp_track_originium", out var originiumClaimedLevels))
                {
                    originiumTrackData.RewardState.AddRange(BuildRewardState(originiumClaimedLevels));
                }
                trackMgr.TrackData.Add(originiumTrackData);
            }

            // Add premium track if owned
            if (data.ownPremiumTier)
            {
                var payTrackData = new ScdBpTrackRewardData
                {
                    BpTrackId = "bp_track_pay"
                };
                if (data.claimedRewards != null && data.claimedRewards.TryGetValue("bp_track_pay", out var payClaimedLevels))
                {
                    payTrackData.RewardState.AddRange(BuildRewardState(payClaimedLevels));
                }
                trackMgr.TrackData.Add(payTrackData);
            }

            return trackMgr;
        }

        public ScBpSyncAll ToProto()
        {
            ScBpSyncAll proto = new ScBpSyncAll()
            {
                LevelData = new()
                {
                    CurExp = data.exp,
                    CurLevel = data.level,

                },
                BpTaskMgr = new(),
                BpTrackMgr = new()
                {
                    TrackData =
                    {
                        new ScdBpTrackRewardData()
                        {
                            BpTrackId="bp_track_free",
                        }
                    },
                },
                SeasonData = new()
                {
                    SeasonId = currentSeasonId,
                    CloseTime = DateTime.UtcNow.AddDays(10).ToUnixTimestampMilliseconds(),
                    CloseStatus = new()
                    {

                    },

                }
            };
            // Update free track with reward state
            if (proto.BpTrackMgr.TrackData.Count > 0)
            {
                var freeTrack = proto.BpTrackMgr.TrackData[0];
                if (data.claimedRewards != null && data.claimedRewards.TryGetValue("bp_track_free", out var freeClaimedLevels))
                {
                    freeTrack.RewardState.AddRange(BuildRewardState(freeClaimedLevels));
                }
            }

            if (data.ownOriginiumTier)
            {
                var originiumTrack = new ScdBpTrackRewardData()
                {
                    BpTrackId = "bp_track_originium",
                };
                if (data.claimedRewards != null && data.claimedRewards.TryGetValue("bp_track_originium", out var originiumClaimedLevels))
                {
                    originiumTrack.RewardState.AddRange(BuildRewardState(originiumClaimedLevels));
                }
                proto.BpTrackMgr.TrackData.Add(originiumTrack);
            }
            if (data.ownPremiumTier)
            {
                var payTrack = new ScdBpTrackRewardData()
                {
                    BpTrackId = "bp_track_pay",
                };
                if (data.claimedRewards != null && data.claimedRewards.TryGetValue("bp_track_pay", out var payClaimedLevels))
                {
                    payTrack.RewardState.AddRange(BuildRewardState(payClaimedLevels));
                }
                proto.BpTrackMgr.TrackData.Add(payTrack);
            }
            return proto;
        }
        public class BattlePassPlayerData
        {
            [BsonId(IdGenerator = typeof(ObjectIdGenerator))]
            public ObjectId _id { get; set; }
            public ulong roleId;
            public int level = 1;
            public int exp = 0;
            public string seasonId;
            public bool ownOriginiumTier;
            public bool ownPremiumTier;
            // Track claimed rewards: key is trackId, value is set of claimed levels
            public Dictionary<string, HashSet<int>> claimedRewards = new Dictionary<string, HashSet<int>>();
        }
    }

}
