using Campofinale.Game.Factory.Components;
using Campofinale.Game.Inventory;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using Campofinale.Resource.Table;
using Newtonsoft.Json;
using StardustUtils;
using System.Xml.Linq;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Factory
{
    public class FactoryChapter
    {
        public string chapterId;
        public ulong ownerId;
        public List<FactoryNode> nodes = new();
        public uint v = 1;
        public uint compV = 0;
        public int bandwidth = 200;
        public FactoryBlackboard blackboard = new();
        public class FactoryBlackboard
        {
            public uint inventoryNodeId=1;
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
                        IsStopByPower=power.isStopByPower,
                        PowerCost=power.powerCost,
                        PowerGen=power.powerGen,
                        PowerSaveCurrent=power.powerSaveCurrent,
                        PowerSaveMax=power.powerSaveMax,    
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
        public ScFactorySyncChapter ToProto()
        {
            blackboard = new();
            
            ScFactorySyncChapter chapter = new()
            {
                ChapterId = chapterId,
                Tms = DateTime.UtcNow.ToUnixTimestampMilliseconds(),
                Blackboard = new(),
                Statistic = new()
                {
                    LastDay = new()
                    {
                        
                    },
                    Other = new()
                    {
                        InPowerBuilding = nodes.FindAll(n=>n.lastPowered==true).Count,
                        
                    }
                },
                PinBoard = new()
                {
                    Cards =
                    {

                    },

                },
                PendingPlace = new()
                {
                    
                },
                
            };
            blackboard.power.powerSaveCurrent = bandwidth;
            domainDataTable[chapterId].levelGroup.ForEach(levelGroup =>
            {
                try
                {
                    int grade = 1;
                    /* LevelGradeInfo sceneGrade = ResourceManager.levelGradeTable[levelGroup].grades.Find(g => g.grade == grade);
                     if (sceneGrade != null)
                     {*/
                    blackboard.power.powerGen += 1;
                    blackboard.power.powerSaveMax += 1;

                    var scene = new ScdFactorySyncScene()
                    {
                        SceneId = GetSceneNumIdFromLevelData(levelGroup),

                        Bandwidth = new()
                        {
                            Current = 0,
                            Max = 1,
                            TravelPoleMax = 111,

                            BattleCurrent = 0,
                            BattleMax = 11,
                        },
                        Settlements =
                        {

                        },

                        Panels =
                        {

                        }
                    };
                    int index = 0;
                    LevelScene scen = GetLevelData(GetSceneNumIdFromLevelData(levelGroup));
                    /*foreach (var reg in scen.levelData.factoryRegions)
                    {
                        foreach (var area in reg.areas)
                        {
                            var lvData = area.levelData.Find(l => l.level == grade);
                            if (lvData == null)
                            {
                                lvData = area.levelData.Last();
                            }
                            if (lvData.levelBounds.Count > 0)
                            {
                                var bounds = lvData.levelBounds[0];
                                scene.Panels.Add(new ScdFactorySyncScenePanel()
                                {
                                    Index = index,
                                    Level = lvData.level,
                                    MainMesh =
                                    {
                                        new ScdRectInt()
                                        {
                                            X=(int)bounds.start.x,
                                            Z=(int)bounds.start.z,
                                            Y=(int)bounds.start.y,
                                            W=(int)bounds.size.x,
                                            H=(int)bounds.size.y,
                                            L=(int)bounds.size.z,
                                        }
                                    }
                                });
                                index++;
                            }

                        }
                    }*/
                    chapter.Scenes.Add(scene);
                }
                catch (Exception ex)
                {

                }
                
                /* }
             */

            });
            try
            {
                nodes.ForEach(node =>
                {
                    chapter.Nodes.Add(node.ToProto());
                });
            }
            catch(Exception e)
            {

            }
            chapter.Blackboard = blackboard.ToProto();
            chapter.Maps.AddRange(GetMaps());
            return chapter;
        }
        public List<ScdFactorySyncMap> GetMaps()
        {
            List<ScdFactorySyncMap> maps = new();
            string levelId = domainDataTable[chapterId].levelGroup[0];
            string mapId = GetLevelData(GetSceneNumIdFromLevelData(levelId)).mapIdStr;
            maps.Add(new ScdFactorySyncMap()
            {
                MapId = ResourceManager.strIdNumTable.chapter_map_id.dic[mapId],
                
                Wires =
                {
                    GetWires()
                },
                
            });
            return maps;
        }

        public List<ScdFactorySyncMapWire> GetWires()
        {
            List<ScdFactorySyncMapWire> wires = new();
            HashSet<(ulong, ulong)> addedConnections = new();
            ulong i = 0;

            foreach (FactoryNode node in nodes)
            {
                foreach (var conn in node.connectedComps)
                {
                    ulong compA = conn.Key;
                    ulong compB = conn.Value;

                    var key = (compA, compB);

                    if (!addedConnections.Contains(key))
                    {
                        wires.Add(new ScdFactorySyncMapWire()
                        {
                            Index = i,
                            FromComId = compA,
                            ToComId = compB,
                            
                        });

                        addedConnections.Add(key);
                        i++;
                    }
                }
            }

            return wires;
        }


        public void Update()
        {
            try
            {
                UpdatePowerGrid(nodes);
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
            catch (Exception e)
            {

            }

        }
        public List<FactoryNode> GetNodesInRange(Vector3f pos, float range)
        {
            return nodes.FindAll(n => n.position.Distance(pos) <= range);
        }

        public void ExecOp(CsFactoryOp op, ulong seq)
        {

            switch (op.OpType)
            {
                case FactoryOpType.Place:
                    CreateNode(op, seq);
                    break;
                case FactoryOpType.MoveNode:
                    MoveNode(op, seq);
                    break;
                case FactoryOpType.Dismantle:
                    DismantleNode(op, seq);
                    break;
                case FactoryOpType.AddConnection:
                    AddConnection(op, seq);
                    break;
                case FactoryOpType.MoveItemBagToCache:
                    MoveItemBagToCache(op, seq);
                    break;
                case FactoryOpType.MoveItemCacheToBag:
                    MoveItemCacheToBag(op, seq);
                    break;
                case FactoryOpType.ChangeProducerMode:
                    ChangeProducerMode(op, seq);
                    break;
                case FactoryOpType.EnableNode:
                    EnableNode(op, seq);
                    break;
                case FactoryOpType.PlaceConveyor:
                    PlaceConveyor(op, seq);
                    break;
                case FactoryOpType.DismantleBoxConveyor:
                    DismantleBoxConveyor(op, seq);
                    break;
                case FactoryOpType.UseHealTowerPoint:
                    //TODO
                    break;
                case FactoryOpType.SetTravelPoleDefaultNext:
                    FactoryNode travelNode = GetNodeByCompId(op.SetTravelPoleDefaultNext.ComponentId);
                    travelNode.GetComponent<FComponentTravelPole>().defaultNext = op.SetTravelPoleDefaultNext.DefaultNext;
                    GetOwner().Send(new PacketScFactoryModifyChapterNodes(GetOwner(), chapterId, travelNode));
                    GetOwner().Send(new PacketScFactoryOpRet(GetOwner(), 0, op), seq);
                    break;
                default:
                    break;
            }

        }
        public void DismantleBoxConveyor(CsFactoryOp op, ulong seq)
        {
            var dismantle = op.DismantleBoxConveyor;

            FactoryNode nodeRem = nodes.Find(n => n.nodeId == dismantle.NodeId);
            if (nodeRem != null)
            {
                RemoveConnectionsToNode(nodeRem, nodes);
                nodes.Remove(nodeRem);
                GetOwner().Send(new PacketScFactoryModifyChapterNodes(GetOwner(), chapterId, nodeRem.nodeId));
                GetOwner().Send(new PacketScFactoryOpRet(GetOwner(), nodeRem.nodeId, op), seq);
            }
            else
            {
                ScFactoryOpRet ret = new()
                {
                    RetCode = FactoryOpRetCode.Fail,
                    
                };
                GetOwner().Send(ScMsgId.ScFactoryOpRet, ret, seq);
            }
        }
        public void EnableNode(CsFactoryOp op, ulong seq)
        {
            var enableNode = op.EnableNode;
            FactoryNode node = nodes.Find(n => n.nodeId == enableNode.NodeId);
            if(node!= null)
            {
                node.deactive = !enableNode.Enable;
                GetOwner().Send(new PacketScFactoryModifyChapterNodes(GetOwner(), chapterId, node));
            }
            GetOwner().Send(new PacketScFactoryOpRet(GetOwner(), 0, op), seq);
        }
        public void ChangeProducerMode(CsFactoryOp op, ulong seq)
        {
            var changeMode = op.ChangeProducerMode;
            FactoryNode node = nodes.Find(n=>n.nodeId == changeMode.NodeId);
            if(node != null)
            {
                FComponentFormulaMan formula = node.GetComponent<FComponentFormulaMan>();
                if (formula != null)
                {
                    formula.currentMode = changeMode.ToMode; //test, not sure
                }
                
            }
            GetOwner().Send(new PacketScFactoryOpRet(GetOwner(), 0, op), seq);
            
        }
        public void MoveItemCacheToBag(CsFactoryOp op, ulong seq)
        {
            var move = op.MoveItemCacheToBag;
            FComponentCache cacheComp = GetCompById<FComponentCache>(move.ComponentId);
            if (cacheComp != null)
            {
                ItemCount cacheItem = cacheComp.items[move.CacheGridIndex];
                Item gridItem = null;
                GetOwner().inventoryManager.items.bag.TryGetValue(move.GridIndex, out gridItem);
                if (gridItem == null)
                {
                    GetOwner().inventoryManager.items.bag.Add(move.GridIndex, new Item(ownerId,cacheItem.id,cacheItem.count));
                    cacheItem.id = "";
                    cacheItem.count = 0;
                    
                }
                else
                {
                    if(gridItem.id == cacheItem.id)
                    {
                        int availableSpace = 50 - gridItem.amount;
                        if(cacheItem.count > availableSpace)
                        {
                            gridItem.amount += availableSpace;
                            cacheItem.count-= availableSpace;
                        }
                        else
                        {
                            gridItem.amount += cacheItem.count;
                            cacheItem.id = "";
                            cacheItem.count = 0;
                        }
                    }
                    else
                    {
                        //TODO Swap
                    }
                    
                }
            }
            GetOwner().inventoryManager.items.UpdateBagInventoryPacket();
            GetOwner().Send(new PacketScFactoryOpRet(GetOwner(), 0, op), seq);
        }
        public void MoveItemBagToCache(CsFactoryOp op, ulong seq)
        {
            var move = op.MoveItemBagToCache;
            FComponentCache cacheComp = GetCompById<FComponentCache>(move.ComponentId);
            if (cacheComp != null)
            {
                Item gridItem = null;
                GetOwner().inventoryManager.items.bag.TryGetValue(move.GridIndex, out gridItem);
                if (gridItem != null)
                {
                    if(cacheComp.items[move.CacheGridIndex].id == "" || cacheComp.items[move.CacheGridIndex].id == gridItem.id)
                    {
                        int canAdd = 50 - cacheComp.items[move.CacheGridIndex].count;

                        if (canAdd >= gridItem.amount)
                        {
                            cacheComp.items[move.CacheGridIndex].id = gridItem.id;
                            cacheComp.items[move.CacheGridIndex].count += gridItem.amount;
                            GetOwner().inventoryManager.items.bag.Remove(move.GridIndex);
                            GetOwner().inventoryManager.items.UpdateBagInventoryPacket();
                        }
                        else
                        {
                            cacheComp.items[move.CacheGridIndex].id = gridItem.id;
                            cacheComp.items[move.CacheGridIndex].count += canAdd;
                            gridItem.amount-=canAdd;
                            GetOwner().inventoryManager.items.UpdateBagInventoryPacket();
                        }
                    }
                }
                
            }
            GetOwner().Send(new PacketScFactoryOpRet(GetOwner(), 0, op), seq);
        }

        public void MoveNode(CsFactoryOp op, ulong seq)
        {
            var move = op.MoveNode;
            FactoryNode node = nodes.Find(n => n.nodeId == move.NodeId);
            if (node != null)
            {
                node.direction = new Vector3f(move.Direction);
                node.position = new Vector3f(move.Position);
                node.worldPosition = new Vector3f(move.InteractiveParam.Position);
                GetOwner().Send(new PacketScFactoryModifyChapterNodes(GetOwner(), chapterId, node));
                GetOwner().Send(new PacketScFactoryOpRet(GetOwner(), node.nodeId, op), seq);
                node.SendEntity(GetOwner(), chapterId);
            }
            else
            {
                ScFactoryOpRet ret = new()
                {
                    RetCode = FactoryOpRetCode.Fail,
                };
                GetOwner().Send(ScMsgId.ScFactoryOpRet, ret, seq);
            }
        }
        public void DismantleNode(CsFactoryOp op, ulong seq)
        {
            var dismantle = op.Dismantle;

            FactoryNode nodeRem = nodes.Find(n => n.nodeId == dismantle.NodeId);
            if (nodeRem != null)
            {
                RemoveConnectionsToNode(nodeRem, nodes);
                nodes.Remove(nodeRem);
                GetOwner().Send(ScMsgId.ScFactoryModifyChapterMap, new ScFactoryModifyChapterMap()
                {
                    ChapterId = chapterId,
                    MapId = nodeRem.mapId,
                    Tms = DateTime.UtcNow.ToUnixTimestampMilliseconds(),
                    Wires =
                    {
                        GetWires()
                    }
                });
                GetOwner().Send(new PacketScFactoryModifyChapterNodes(GetOwner(), chapterId, nodeRem.nodeId));
                GetOwner().Send(new PacketScFactoryOpRet(GetOwner(), nodeRem.nodeId, op), seq);
            }
            else
            {
                ScFactoryOpRet ret = new()
                {
                    RetCode = FactoryOpRetCode.Fail,

                };
                GetOwner().Send(ScMsgId.ScFactoryOpRet, ret, seq);
            }
        }
        public void RemoveConnectionsToNode(FactoryNode nodeRem, List<FactoryNode> allNodes)
        {
            // Ottieni tutti i compId del nodo da rimuovere
            HashSet<ulong> remCompIds = nodeRem.components.Select(c => (ulong)c.compId).ToHashSet();

            foreach (var node in allNodes)
            {
                node.connectedComps.RemoveAll(conn =>
                    remCompIds.Contains(conn.Key) || remCompIds.Contains(conn.Value));
            }
        }


        public uint nextCompV()
        {
            compV++;
            return compV;
        }
        public FComponent GetCompById(ulong compId)
        {
            foreach (FactoryNode node in nodes)
            {
                if (node.components.Find(c => c.compId == compId) != null)
                {
                    return node.components.Find(c => c.compId == compId);
                }
            }
            return null;
        }
        public FComponent GetCompById<FComponent>(ulong compId) where FComponent : class
        {
            foreach (FactoryNode node in nodes)
            {
                if (node.components.Find(c => c.compId == compId) != null)
                {
                    return node.components.Find(c => c.compId == compId && c is FComponent) as FComponent;
                }
            }
            return null;
        }
        public FactoryNode GetNodeByCompId(ulong compId)
        {
            foreach (FactoryNode node in nodes)
            {
                if (node.components.Find(c => c.compId == compId) != null)
                {
                    return node;
                }
            }
            return null;
        }
        private void AddConnection(CsFactoryOp op, ulong seq)
        {
            FComponent nodeFrom = GetCompById(op.AddConnection.FromComId);
            FComponent nodeTo = GetCompById(op.AddConnection.ToComId);

            if (nodeFrom != null && nodeTo != null)
            {
                GetNodeByCompId(nodeFrom.compId).connectedComps.Add(new(nodeFrom.compId, nodeTo.compId));
                GetNodeByCompId(nodeTo.compId).connectedComps.Add(new(nodeTo.compId, nodeFrom.compId));
                GetOwner().Send(ScMsgId.ScFactoryModifyChapterMap, new ScFactoryModifyChapterMap()
                {
                    ChapterId = chapterId,
                    MapId = GetNodeByCompId(nodeFrom.compId).mapId,
                    Tms = DateTime.UtcNow.ToUnixTimestampMilliseconds(),
                    Wires =
                    {
                        GetWires()
                    }
                });
                var wire = GetWires().Find(w =>
    (w.FromComId == op.AddConnection.FromComId && w.ToComId == op.AddConnection.ToComId) ||
    (w.FromComId == op.AddConnection.ToComId && w.ToComId == op.AddConnection.FromComId));

                if (wire != null)
                {
                    GetOwner().Send(new PacketScFactoryOpRet(GetOwner(), (uint)wire.Index, op), seq);
                }
                else
                {
                    // Facoltativo: log di errore
                    Console.WriteLine($"[WARN] Connessione non trovata tra {op.AddConnection.FromComId} e {op.AddConnection.ToComId}");
                }

            }

        }
        void ResetAllPower(List<FactoryNode> allNodes)
        {
            foreach (var node in allNodes)
                node.powered = false;
        }
        void UpdatePowerGrid(List<FactoryNode> allNodes)
        {
            ResetAllPower(allNodes);

            HashSet<uint> visited = new();

            foreach (var node in allNodes)
            {
                if (node.templateId.Contains("hub") || node.templateId == "power_diffuser_1")
                {
                    //if(node.forcePowerOn)
                    if (node.templateId == "power_diffuser_1")
                    {
                        //Check inside factory region

                    }
                    else
                    {
                        PropagatePowerFrom(node, visited);
                    }

                }
            }
        }
        void PropagatePowerFrom(FactoryNode node, HashSet<uint> visited)
        {
            if (visited.Contains(node.nodeId))
                return;

            visited.Add(node.nodeId);
            node.powered = true;
            if (node.templateId == "power_diffuser_1")
            {
                //get builds in area test
                List<FactoryNode> nodes = GetNodesInRange(node.position, 15);
                foreach (FactoryNode propagateNode in nodes)
                {
                    if (propagateNode.GetComponent<FComponentPowerPole>() == null)
                    {
                        propagateNode.powered = true;
                    }
                }
            }
            if (node.GetComponent<FComponentPowerPole>() != null)
                foreach (var connectedCompId in node.connectedComps)
                {
                    FactoryNode connectedNode = GetNodeByCompId(connectedCompId.Value);
                    if (connectedNode != null)
                    {
                        PropagatePowerFrom(connectedNode, visited);
                    }
                }
        }
        public void PlaceConveyor(CsFactoryOp op, ulong seq)
        {
            var placeConveyor = op.PlaceConveyor;
            v++;
            uint nodeId = v;
            List<Vector3f> points = new();
            foreach(var point in placeConveyor.Points)
            {
                points.Add(new Vector3f(point));
            }
            FactoryNode node = new()
            {
                nodeId = nodeId,
                templateId = placeConveyor.TemplateId,
                mapId = placeConveyor.MapId,
                sceneNumId = GetOwner().sceneManager.GetCurScene().sceneNumId,
                nodeType = FCNodeType.BoxConveyor,
                position = new Vector3f(placeConveyor.Points[0]),
                direction = new(),
                directionIn = new Vector3f(placeConveyor.DirectionIn),
                directionOut = new Vector3f(placeConveyor.DirectionOut),
                worldPosition = null,
                points = points,
                guid = GetOwner().random.NextRand(),
            };
            
            node.InitComponents(this);
            GetOwner().Send(new PacketScFactoryModifyChapterNodes(GetOwner(), chapterId, node));
            nodes.Add(node);
            
            GetOwner().Send(new PacketScFactoryOpRet(GetOwner(), nodeId, op), seq);
        }
        private void CreateNode(CsFactoryOp op, ulong seq)
        {
            v++;
            uint nodeId = v;
            CsdFactoryOpPlace place = op.Place;
            FactoryBuildingTable table = ResourceManager.factoryBuildingTable[place.TemplateId];
            FactoryNode node = new()
            {
                nodeId = nodeId,
                templateId = place.TemplateId,
                mapId = place.MapId,
                sceneNumId = GetOwner().sceneManager.GetCurScene().sceneNumId,
                nodeType = table.GetNodeType(),
                position = new Vector3f(place.Position),
                direction = new Vector3f(place.Direction),
                worldPosition = new Vector3f(place.InteractiveParam.Position),
                guid = GetOwner().random.NextRand(),

            };

            node.InitComponents(this);
            GetOwner().Send(new PacketScFactoryModifyChapterNodes(GetOwner(), chapterId, node));
            nodes.Add(node);
            node.SendEntity(GetOwner(), chapterId);

            GetOwner().Send(new PacketScFactoryOpRet(GetOwner(), node.nodeId, op), seq);

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
        }
        public Player GetOwner()
        {
            return Server.clients.Find(c => c.roleId == ownerId);
        }
    }
}
