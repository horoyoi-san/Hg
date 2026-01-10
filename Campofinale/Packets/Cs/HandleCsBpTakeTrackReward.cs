using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Packets.Sc;
using StardustUtils;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Cs
{
    public class HandleCsBpTakeTrackReward
    {
        [Server.Handler(CsMsgId.CsBpTakeTrackReward)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsBpTakeTrackReward req = packet.DecodeBody<CsBpTakeTrackReward>();

            List<CsdBpTrackReward> failedRewards = new List<CsdBpTrackReward>();
            List<ItemBundle> grantedItems = new List<ItemBundle>();

            const string levelGroupId = "bp_lv_group_default";
            if (!battlePassLevelTable.ContainsKey(levelGroupId))
            {
                Logger.PrintWarn($"[HandleCsBpTakeTrackReward] Level group not found: {levelGroupId}");
                session.Send(new PacketScBpTakeTrackReward(session, new ScBpTakeTrackReward()), packet.csHead.UpSeqid);
                return;
            }

            var levelGroup = battlePassLevelTable[levelGroupId];

            foreach (var trackReward in req.TakeTrackReward)
            {
                string bpTrackId = trackReward.BpTrackId;

                if (!battlePassTrackTable.ContainsKey(bpTrackId))
                {
                    Logger.PrintWarn($"[HandleCsBpTakeTrackReward] Invalid track ID: {bpTrackId}");
                    failedRewards.Add(trackReward);
                    continue;
                }

                var trackConfig = battlePassTrackTable[bpTrackId];

                foreach (int level in trackReward.Level)
                {
                    // Check if reward is already claimed
                    if (session.battlePassManager.IsRewardClaimed(bpTrackId, level))
                    {
                        Logger.PrintWarn($"[HandleCsBpTakeTrackReward] Reward already claimed: track={bpTrackId}, level={level}");
                        continue;
                    }

                    // Check if player has reached this level
                    if (level > session.battlePassManager.data.level)
                    {
                        Logger.PrintWarn($"[HandleCsBpTakeTrackReward] Level not reached: track={bpTrackId}, level={level}, current={session.battlePassManager.data.level}");
                        failedRewards.Add(new CsdBpTrackReward { BpTrackId = bpTrackId, Level = { level } });
                        continue;
                    }

                    if (levelGroup.levelInfos == null || !levelGroup.levelInfos.TryGetValue(level.ToString(), out var levelInfo))
                    {
                        Logger.PrintWarn($"[HandleCsBpTakeTrackReward] Level info not found: level={level}");
                        continue;
                    }

                    string? rewardId = trackConfig.trackType switch
                    {
                        0 => levelInfo.freeRewardId,
                        1 => levelInfo.originiumRewardId,
                        2 => levelInfo.payRewardId,
                        _ => null
                    };

                    if (string.IsNullOrEmpty(rewardId) || !rewardTable.TryGetValue(rewardId, out var reward) || reward.itemBundles == null || reward.itemBundles.Count == 0)
                    {
                        Logger.PrintWarn($"[HandleCsBpTakeTrackReward] Invalid reward: track={bpTrackId}, level={level}, rewardId={rewardId}");
                        continue;
                    }

                    bool rewardGranted = false;
                    foreach (var bundle in reward.itemBundles)
                    {
                        if (string.IsNullOrEmpty(bundle.id) || bundle.count <= 0)
                            continue;

                        if (session.inventoryManager.AddItem(bundle.id, bundle.count) != null)
                        {
                            rewardGranted = true;
                            grantedItems.Add(new ItemBundle { Id = bundle.id, Count = bundle.count });
                        }
                    }

                    if (rewardGranted)
                    {
                        // Mark reward as claimed
                        session.battlePassManager.MarkRewardClaimed(bpTrackId, level);
                    }
                    else
                    {
                        failedRewards.Add(new CsdBpTrackReward { BpTrackId = bpTrackId, Level = { level } });
                    }
                }
            }

            // Save claimed rewards to database
            session.battlePassManager.Save();

            var response = new ScBpTakeTrackReward();
            response.FailedReward.AddRange(failedRewards);
            response.Items.AddRange(grantedItems);
            session.Send(new PacketScBpTakeTrackReward(session, response), packet.csHead.UpSeqid);

            // Send track manager update to client so it knows which rewards are claimed
            if (grantedItems.Count > 0)
            {
                var trackUpdate = new ScBpTrackMgrModify
                {
                    BpTrackMgr = session.battlePassManager.GetTrackMgrData()
                };
                session.Send(new PacketScBpTrackMgrModify(session, trackUpdate));
            }
        }
    }
}

