using Campofinale.Game.Factory.Components;
using Campofinale.Game.Inventory;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using Campofinale.Resource.Table;
using MongoDB.Bson.Serialization.Attributes;
using Newtonsoft.Json;
using StardustUtils;
using System.Linq;
using System.Xml.Linq;
using static Campofinale.Resource.ResourceManager;
using static Campofinale.Resource.Table.DomainDataTable;

namespace Campofinale.Game.Factory
{
    public class FactoryChapter
    {
        public string chapterId;
        public ulong ownerId;
        public int domainDevelopmentLevel = 12;
        public List<FactoryNode> nodes = new();
        public uint v = 1;
        public uint compV = 0;
        public int bandwidth = 200;
        public FactoryBlackboard blackboard = new();
        public Dictionary<string, int> regionsLevels = [];
        public List<FactoryQuickbar> quickbars = [];
        // set of purchased good IDs (state = Done)
        public HashSet<string> panelStorePurchasedGoods = [];

        public Player GetOwner()
        {
            return Server.clients.Find(c => c.roleId == ownerId);
        }
        public uint nextCompV()
        {
            compV++;
            return compV;
        }

        // Sub-managers for operations (not serialized to database, initialized via InitializeSubManagers())
        [BsonIgnore]
        public FactoryNodeOps nodeOps;
        [BsonIgnore]
        public FactoryWire wire;
        [BsonIgnore]
        public FactoryPower power;
        [BsonIgnore]
        public FactoryItemTransfer itemTransfer;
        public class FactoryQuickbar
        {
            public int Type;
            public List<string> List = [];
        }
        public class FactoryBlackboard
        {
            public uint inventoryNodeId = 1;
            public FacBbPower power = new();

            public class FacBbPower
            {
                public long powerGen;
                public long powerSaveMax;
                public long powerSaveCurrent;
                public long powerCost;
                public bool isStopByPower;
            }
            public ScdFactorySyncBlackboard ToProto()
            {
                return new ScdFactorySyncBlackboard()
                {
                    InventoryNodeId = inventoryNodeId,
                    Power = new()
                    {
                        IsStopByPower = power.isStopByPower,
                        PowerCost = power.powerCost,
                        PowerGen = power.powerGen,
                        PowerSaveCurrent = power.powerSaveCurrent,
                        PowerSaveMax = power.powerSaveMax,
                    }
                };
            }

            public ScdFactoryHsBb ToProtoHsBb()
            {
                return new ScdFactoryHsBb()
                {
                    Power = new()
                    {
                        IsStopByPower = power.isStopByPower,
                        PowerSaveCurrent = power.powerSaveCurrent,
                        PowerSaveMax = power.powerSaveMax,
                    },
                };
            }
        }

        public FactoryChapter(string chapterId, ulong ownerId)
        {
            this.ownerId = ownerId;
            this.chapterId = chapterId;
            FactoryNode node = new()
            {
                nodeId = v,
                templateId = "__inventory__",
                nodeType = FCNodeType.Inventory,
                mapId = 0,
                deactive = true,
                guid = GetOwner().random.NextRand()
            };
            node.InitComponents(this);
            nodes.Add(node);

            // Initialize quickbars
            quickbars = new List<FactoryQuickbar>
            {
                new FactoryQuickbar { Type = 0, List = [] },
                new FactoryQuickbar { Type = 1, List = [] }
            };

            // Initialize empty slots for quickbars
            foreach (var quickbar in quickbars)
            {
                for (int i = 0; i < 8; i++)
                {
                    quickbar.List.Add("");
                }
            }

            // Initialize sub-managers
            InitializeSubManagers();
        }

        public void InitializeSubManagers()
        {
            nodeOps = new FactoryNodeOps(this);
            wire = new FactoryWire(this);
            power = new FactoryPower(this);
            itemTransfer = new FactoryItemTransfer(this);
        }
        private ScFactorySyncChapter CreateBaseChapterProto()
        {
            return new ScFactorySyncChapter()
            {
                Tms = DateTime.UtcNow.ToUnixTimestampMilliseconds(),
                ChapterId = chapterId,
                Blackboard = new()
                {
                    Power = new()
                },
                PinBoard = new(),
                Quickbars = { BuildQuickbars() },
                Statistic = new()
                {
                    LastDay = new(),
                    Other = new()
                    {
                        InPowerBuilding = nodes.FindAll(n => n.lastPowered == true).Count
                    },
                },
                PendingPlace = new()
            };
        }

        public ScFactorySyncChapter ToProto()
        {
            // Build chapter proto with all components
            var chapter = CreateBaseChapterProto();
            BuildNodes(chapter);
            BuildScenes(chapter);
            BuildBlackboard(chapter);
            BuildMaps(chapter);
            // TODO: build remaining

            return chapter;
        }

        public List<ScdFactoryPanelStoreGood> BuildPanelStoreGoodsProto()
        {
            var goods = new List<ScdFactoryPanelStoreGood>();

            panelStorePurchasedGoods ??= new HashSet<string>();

            if (ResourceManager.factoryPanelStoreTable == null)
            {
                return goods;
            }

            // Get levelIds for this chapter to filter goods
            var chapterLevelIds = new HashSet<string>();
            if (domainDataTable.TryGetValue(chapterId, out var domainData))
            {
                foreach (var levelId in domainData.levelGroup)
                {
                    chapterLevelIds.Add(levelId);
                }
            }

            foreach (var kvp in ResourceManager.factoryPanelStoreTable)
            {
                if (kvp.Value == null)
                    continue;

                var good = kvp.Value;

                // Only include goods that belong to this chapter (regionId matches levelId in levelGroup)
                if (!chapterLevelIds.Contains(good.regionId))
                    continue;

                int state;

                // Check if purchased (Done = 2)
                if (panelStorePurchasedGoods.Contains(good.id))
                {
                    state = 2; // Done
                }
                else
                {
                    // TODO: Check conditions to determine if Ready (1) or Lock (0)
                    // For now, set to Ready (1) - conditions check should be implemented later
                    state = 1; // Ready
                }

                goods.Add(new ScdFactoryPanelStoreGood
                {
                    Id = good.id,
                    State = state
                });
            }

            return goods;
        }

        public List<ScdFactorySyncQuickbar> BuildQuickbars()
        {
            var protoQuickbars = new List<ScdFactorySyncQuickbar>();
            for (int type = 0; type < 2; type++)
            {
                var protoQuickbar = new ScdFactorySyncQuickbar { Type = type };

                var existingQuickbar = quickbars?.FirstOrDefault(q => q.Type == type);
                var items = existingQuickbar?.List ?? new List<string>();

                for (int i = 0; i < 8; i++)
                {
                    protoQuickbar.List.Add(i < items.Count ? (items[i] ?? "") : "");
                }

                protoQuickbars.Add(protoQuickbar);
            }

            return protoQuickbars;
        }

        private void BuildBlackboard(ScFactorySyncChapter chapter)
        {
            blackboard = new();
            blackboard.power.powerSaveCurrent = bandwidth;

            chapter.Blackboard = blackboard.ToProto();
        }

        private void BuildMaps(ScFactorySyncChapter chapter)
        {
            chapter.Maps.AddRange(GetMaps());
        }

        private void BuildScenes(ScFactorySyncChapter chapter)
        {
            DomainDataTable? domainData = domainDataTable[chapterId];
            if (domainData?.levelGroup == null)
            {
                return;
            }

            foreach (var levelGroup in domainData.levelGroup)
            {
                var scene = BuildSceneForLevelGroup(levelGroup, domainData);
                if (scene != null)
                {
                    chapter.Scenes.Add(scene);
                }
            }
        }

        private ScdFactorySyncScene? BuildSceneForLevelGroup(string levelGroup, DomainDataTable domainData)
        {
            // Find matching domain development level, or use the highest available level that is <= target level
            DomainDevelopmentLevel? devLvl = domainData.domainDevelopmentLevel.Find(D => D.domainDevelopmentLevel == domainDevelopmentLevel);
            if (devLvl == null)
            {
                // If exact match not found, find the highest available level that is <= target level
                devLvl = domainData.domainDevelopmentLevel
                    .Where(D => D.domainDevelopmentLevel <= domainDevelopmentLevel)
                    .OrderByDescending(D => D.domainDevelopmentLevel)
                    .FirstOrDefault();

                if (devLvl == null)
                {
                    // If no level found, try to use the highest available level regardless
                    devLvl = domainData.domainDevelopmentLevel
                        .OrderByDescending(D => D.domainDevelopmentLevel)
                        .FirstOrDefault();
                }

                if (devLvl == null)
                {
                    return null;
                }
            }

            DomainDevelopmentLevelEffect? devEff = devLvl.domainDevelopmentLevelEffect.Values.ToList().Find(V => V.levelId == levelGroup);
            if (devEff == null)
            {
                return null;
            }

            blackboard.power.powerGen += devEff.bandwidth;
            blackboard.power.powerSaveMax += devEff.bandwidth;
            blackboard.power.powerSaveCurrent = blackboard.power.powerSaveMax;

            var scene = new ScdFactorySyncScene()
            {
                SceneId = GetSceneNumIdFromLevelData(levelGroup),
                Bandwidth = new()
                {
                    Current = 0,
                    Max = devEff.bandwidth,
                    TravelPoleMax = devEff.travelPoleLimit,
                    TravelPoleCurrent = 0,
                    BattleCurrent = 0,
                    BattleMax = devEff.battleBuildingLimit,
                },
                Settlements =
                {

                },
                Panels =
                {

                }
            };

            BuildScenePanels(scene, levelGroup);
            BuildSettlements(scene, levelGroup);

            return scene;
        }

        private void BuildSettlements(ScdFactorySyncScene scene, string levelGroup)
        {
            LevelScene levelScene = GetLevelData(GetSceneNumIdFromLevelData(levelGroup));

            foreach (var reg in levelScene.levelData.factoryRegions)
            {
                // Check if region has settlementAreas
                if (reg.settlementAreas == null || reg.settlementAreas.Count == 0)
                {
                    continue;
                }

                foreach (var settlementArea in reg.settlementAreas)
                {
                    string settlementId = settlementArea.areaId;
                    if (string.IsNullOrEmpty(settlementId))
                    {
                        continue;
                    }

                    // Get settlement level from player data (default to 1 if not found)
                    int settlementLevel = GetSettlementLevel(settlementId);

                    // Get settlement level data from settlementBasicDataTable
                    if (ResourceManager.settlementBasicDataTable.TryGetValue(settlementId, out var settlementBasic))
                    {
                        // Get level-specific data from settlementLevelMap
                        int bandwidth = 0;
                        int travelPoleLimit = 0;
                        int battleBuildingLimit = 0;

                        if (settlementBasic.settlementLevelMap != null &&
                            settlementBasic.settlementLevelMap.TryGetValue(settlementLevel.ToString(), out var levelData))
                        {
                            bandwidth = levelData.bandwidth;
                            travelPoleLimit = levelData.travelPoleLimit;
                            battleBuildingLimit = levelData.battleBuildingLimit;
                        }
                        else
                        {
                            // If level not found, try to get the first available level as fallback
                            if (settlementBasic.settlementLevelMap != null && settlementBasic.settlementLevelMap.Count > 0)
                            {
                                var firstLevel = settlementBasic.settlementLevelMap.Values.First();
                                bandwidth = firstLevel.bandwidth;
                                travelPoleLimit = firstLevel.travelPoleLimit;
                                battleBuildingLimit = firstLevel.battleBuildingLimit;
                            }
                        }

                        var bandwidthData = new ScdFactorySyncSceneBandwidth()
                        {
                            Current = 0,
                            Max = bandwidth,
                            TravelPoleCurrent = 0,
                            TravelPoleMax = travelPoleLimit,
                            BattleCurrent = 0,
                            BattleMax = battleBuildingLimit,
                            SpCurrent = 0,
                            SpMax = 0
                        };

                        scene.Settlements[settlementId] = bandwidthData;
                    }
                }
            }
        }

        private int GetSettlementLevel(string settlementId)
        {
            // TODO: Implement proper settlement level retrieval from player settlement data
            // For now, return default level 1
            return 1;
        }

        private void BuildScenePanels(ScdFactorySyncScene scene, string levelGroup)
        {
            int index = 0;
            LevelScene levelScene = GetLevelData(GetSceneNumIdFromLevelData(levelGroup));

            foreach (var reg in levelScene.levelData.factoryRegions)
            {
                // Get current region level
                int currentLevel = 3; // GetFactoryRegionLevel(reg.regionId);

                foreach (var area in reg.areas)
                {
                    var lvData = area.levelData.Find(l => l.level == currentLevel);
                    lvData ??= area.levelData.Last();

                    if (lvData.levelBounds.Count > 0)
                    {
                        var bounds = lvData.levelBounds[0];
                        scene.Panels.Add(new ScdFactorySyncScenePanel()
                        {
                            Index = index,
                            Level = currentLevel,
                            MainMesh =
                            {
                                new ScdRectInt()
                                {
                                    X = (int)bounds.start.x,
                                    Z = (int)bounds.start.z,
                                    Y = (int)bounds.start.y,
                                    W = (int)bounds.size.x,
                                    H = (int)bounds.size.y,
                                    L = (int)bounds.size.z,
                                }
                            }
                        });
                        index++;
                    }
                }
            }
        }

        private void BuildNodes(ScFactorySyncChapter chapter)
        {
            foreach (var node in nodes)
            {
                chapter.Nodes.Add(node.ToProto());
            }
        }

        public int GetFactoryRegionLevel(string regionId)
        {
            regionsLevels ??= new();
            if (regionsLevels.TryGetValue(regionId, out var r))
            {
                return r;
            }

            // use max level for region. NOTICE: some region may have cropPanel levelBounds. no idea what it is.
            regionsLevels.Add(regionId, 3);
            return 3;
        }

        public List<ScdFactorySyncMap> GetMaps()
        {

            List<ScdFactorySyncMap> maps = [];
            if (!domainDataTable.TryGetValue(chapterId, out var domainData) || domainData?.levelGroup == null || domainData.levelGroup.Count == 0)
            {
                return maps;
            }

            string levelId = domainData.levelGroup[0];
            LevelScene levelScene = GetLevelData(GetSceneNumIdFromLevelData(levelId));
            if (levelScene == null || string.IsNullOrEmpty(levelScene.mapIdStr) || strIdNumTable?.chapter_map_id?.dic == null || !strIdNumTable.chapter_map_id.dic.TryGetValue(levelScene.mapIdStr, out int mapIdNum))
            {
                return maps;
            }

            // Use AddRange instead of collection initializer syntax for RepeatedField
            var map = new ScdFactorySyncMap()
            {
                MapId = mapIdNum
            };
            map.Wires.AddRange(wire.GetWires());
            maps.Add(map);
            return maps;
        }

        public void Update()
        {
            power.UpdatePowerGrid(nodes);
            foreach (FactoryNode node in nodes)
            {
                try
                {
                    node.Update(this);
                }
                catch (Exception e)
                {
                    Logger.PrintError($"Error occured while updating nodeId {node.nodeId}: {e.Message}");
                }

            }
        }

        public List<FactoryNode> GetNodesInRange(Vector3f pos, float range)
        {
            return nodes.FindAll(n => n.position.Distance(pos) <= range);
        }

        public void SetQuickbarOne(int scopeName, int type, int index, string itemId)
        {
            if (type < 0 || type >= 2) return; // Only 2 quickbar types (0 and 1)
            if (index < 0 || index >= 8) return; // Quickbar always has 8 slots

            if (quickbars == null)
            {
                quickbars = new List<FactoryQuickbar>();
            }

            // Find or create quickbar for this type
            var quickbar = quickbars.FirstOrDefault(q => q.Type == type);
            if (quickbar == null)
            {
                quickbar = new FactoryQuickbar { Type = type, List = new List<string>() };
                quickbars.Add(quickbar);
            }

            quickbar.List[index] = itemId ?? "";
        }

        public void MoveQuickbarOne(int scopeName, int type, int fromIndex, int toIndex)
        {
            if (fromIndex < 0 || fromIndex >= 8) return;
            if (toIndex < 0 || toIndex >= 8) return;
            if (fromIndex == toIndex) return;

            var quickbar = quickbars.FirstOrDefault(q => q.Type == type);
            if (quickbar == null)
            {
                quickbar = new FactoryQuickbar { Type = type, List = new List<string>() };
                quickbars.Add(quickbar);
            }

            var item = quickbar.List[fromIndex];
            quickbar.List[fromIndex] = "";
            quickbar.List[toIndex] = item ?? "";
        }

        public void ExecOp(CsFactoryOp op, ulong seq)
        {
            switch (op.OpType)
            {
                case FactoryOpType.Place:
                    nodeOps.CreateNode(op, seq);
                    break;
                case FactoryOpType.MoveNode:
                    nodeOps.MoveNode(op, seq);
                    break;
                case FactoryOpType.Dismantle:
                    nodeOps.DismantleNode(op, seq);
                    break;
                case FactoryOpType.AddConnection:
                    wire.AddConnection(op, seq);
                    break;
                case FactoryOpType.MoveItemBagToCache:
                    itemTransfer.MoveItemBagToCache(op, seq);
                    break;
                case FactoryOpType.MoveItemCacheToBag:
                    itemTransfer.MoveItemCacheToBag(op, seq);
                    break;
                case FactoryOpType.ChangeProducerMode:
                    nodeOps.ChangeProducerMode(op, seq);
                    break;
                case FactoryOpType.EnableNode:
                    nodeOps.EnableNode(op, seq);
                    break;
                case FactoryOpType.PlaceConveyor:
                    nodeOps.PlaceConveyor(op, seq);
                    break;
                case FactoryOpType.DismantleBoxConveyor:
                    nodeOps.DismantleBoxConveyor(op, seq);
                    break;
                case FactoryOpType.UseHealTowerPoint:
                    //TODO
                    break;
                case FactoryOpType.SetTravelPoleDefaultNext:
                    nodeOps.SetTravelPoleDefaultNext(op, seq);
                    break;
                default:
                    break;
            }

        }

        public FComponent GetCompById(ulong compId)
        {
            foreach (FactoryNode node in nodes)
            {
                var comp = node.components.Find(c => c.compId == compId);
                if (comp != null)
                {
                    return comp;
                }
            }
            return null;
        }
        public FComponent GetCompById<FComponent>(ulong compId) where FComponent : class
        {
            foreach (FactoryNode node in nodes)
            {
                var comp = node.components.Find(c => c.compId == compId && c is FComponent);
                if (comp != null)
                {
                    return comp as FComponent;
                }
            }
            return null;
        }
        public FactoryNode GetNodeByCompId(ulong compId)
        {
            foreach (FactoryNode node in nodes)
            {
                if (node.components.Any(c => c.compId == compId))
                {
                    return node;
                }
            }
            return null;
        }
    }
}
