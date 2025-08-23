using Campofinale.Game.Entities;
using Campofinale.Game.Factory.Components;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource.Table;
using Campofinale.Resource;
using MongoDB.Bson.Serialization.Attributes;
using static Campofinale.Resource.ResourceManager;
using Campofinale.Game.Factory.BuildingsBehaviour;
using static Campofinale.Resource.ResourceManager.FactoryBuildingTable;
using Newtonsoft.Json;
using System.Drawing;
using Campofinale.Game.Inventory;
using System.Numerics;

namespace Campofinale.Game.Factory
{
    public class FactoryNode
    {
        public uint nodeId;
        public FCNodeType nodeType;
        public string templateId;
        public Vector3f position = new();
        public Vector3f direction = new();
        public Vector3f worldPosition = new();

        public Vector3f directionIn;
        public Vector3f directionOut;
        public string instKey = "";
        public bool deactive = false;
        public int mapId;
        public int sceneNumId;
        public bool forcePowerOn = false;
        public List<FComponent> components = new();
        //Conveyor only
        public List<Vector3f> points;
        public bool powered = false;
        public bool lastPowered = false;
        public List<ConnectedComp> connectedComps = new();
        public ulong guid;
        public NodeBuildingBehaviour nodeBehaviour;
        public class ConnectedComp
        {
            public ulong Key;
            public ulong Value;
            public ConnectedComp(ulong key, ulong value)
            {
                this.Key = key;
                this.Value = value;
            }
        }
        public void Update(FactoryChapter chapter)
        {
            LevelScene scen = GetLevelData(sceneNumId);
            if (lastPowered != powered)
            {
                lastPowered = powered;
                chapter.GetOwner().Send(new PacketScFactoryModifyChapterNodes(chapter.GetOwner(), chapter.chapterId, this));
            }
            if (nodeBehaviour != null && !deactive)
            {
                nodeBehaviour.Update(chapter,this);
            }
            foreach (var comp in components.FindAll(c => c is FComponentPortManager))
            {
                var portmanager = (FComponentPortManager)comp;
                if (portmanager.customPos != FCComponentPos.PortOutManager)
                {
                    UpdatePortManager(chapter, portmanager);
                }
            }
            foreach (var comp in components.FindAll(c => c is FComponentPortManager))
            {
                var portmanager = (FComponentPortManager)comp;
                if (portmanager.customPos == FCComponentPos.PortOutManager)
                {
                    UpdatePortManager(chapter, portmanager);
                }
            }
            
        }
        public FactoryBuildingTable GetBuildingTable()
        {
            ResourceManager.factoryBuildingTable.TryGetValue(templateId, out FactoryBuildingTable table);
            if (table == null)
            {
                table = new FactoryBuildingTable();
            }
            return table;
        }
        public void UpdatePortManager(FactoryChapter chapter,FComponentPortManager manager)
        {
            if (ResourceManager.factoryBuildingTable.TryGetValue(templateId, out FactoryBuildingTable table))
            {
                List<FacPort> ports = new();
                if (manager.customPos == FCComponentPos.PortOutManager)
                {
                    ports = GetTransformedPorts(table.outputPorts);
                    List<FactoryNode> conveyors = chapter.nodes.FindAll(n => n.points != null);
                    foreach (var port in ports)
                    {
                        Vector3f front = port.GetFront();
                        FactoryNode node = conveyors.Find(c =>
                            c.nodeType == FCNodeType.BoxConveyor &&
                            c.points.Any(p => p.x == front.x && p.y == front.y && p.z == front.z));
                        var compPort = manager.ports.Find(p => p.index == port.index);
                        if (compPort != null)
                        {
                            if (node != null)
                            {
                                compPort.touchComId = node.GetComponent<FComponentBoxConveyor>().compId;
                            }
                            else
                            {
                                compPort.touchComId = 0;
                            }
                        }

                    }
                    //Output items
                    foreach (var port in manager.ports)
                    {
                        FComponentBoxConveyor output = chapter.GetCompById<FComponentBoxConveyor>(port.touchComId);
                        FComponentCache outputCache = chapter.GetCompById<FComponentCache>(port.ownerComId);
                        FactoryNode conveyorNode = chapter.GetNodeByCompId(port.touchComId);
                        if (outputCache != null && output != null && conveyorNode != null)
                        {
                            bool did = false;
                            outputCache.items.ForEach(i =>
                            {
                                if (!did && i.count > 0)
                                {
                                    ItemCount add = new ItemCount()
                                    {
                                        id = i.id,
                                        count = 1
                                    };

                                    if (conveyorNode.AddConveyorItem(chapter,add))
                                    {
                                        did = true;
                                        outputCache.ConsumeItems(new List<ItemCount>() { add });
                                    }

                                }
                            });
                        }
                    }

                }
                else
                {
                    ports = GetTransformedPorts(table.inputPorts);
                    List<FactoryNode> conveyors = chapter.nodes.FindAll(n => n.points != null);
                    foreach (var port in ports)
                    {
                        Vector3f back = port.GetBack();
                        FactoryNode node = conveyors.Find(c =>
                            c.nodeType == FCNodeType.BoxConveyor &&
                            c.points.Any(p => p.x == back.x && p.y == back.y && p.z == back.z));
                        var compPort = manager.ports.Find(p => p.index == port.index);

                        if (compPort != null)
                        {
                            if (node != null)
                            {
                                compPort.touchComId = node.GetComponent<FComponentBoxConveyor>().compId;
                            }
                            else
                            {
                                compPort.touchComId = 0;
                            }
                        }

                    }

                    //Input items
                    foreach (var port in manager.ports)
                    {
                        FComponentBoxConveyor input = chapter.GetCompById<FComponentBoxConveyor>(port.touchComId);
                        FComponentCache inputCache = chapter.GetCompById<FComponentCache>(port.ownerComId);
                        FactoryNode conveyorNode = chapter.GetNodeByCompId(port.touchComId);
                        if (inputCache != null && input != null && conveyorNode != null)
                        {
                            bool did = false;
                            ItemCount toRemove = null;
                            foreach (var item in input.items)
                            {
                                if (!did && item.count > 0 && item.IsItemAtConveyorEnd(BlockCalculator.CalculateTotalBlocks(conveyorNode.points)))
                                {

                                    if (!inputCache.IsFull())
                                    {
                                        did = true;
                                        toRemove = item;
                                        inputCache.AddItem(item.id, item.count);
                                        break;
                                    }

                                }
                            }
                            if(toRemove!=null)
                                conveyorNode.RemoveConveyorItem(chapter,toRemove);

                        }
                    }
                }
            }
           
        }

        private void RemoveConveyorItem(FactoryChapter chapter,ItemCount toRemove)
        {
            FComponentBoxConveyor conveyorComp = GetComponent<FComponentBoxConveyor>();
            conveyorComp.items.Remove(toRemove);
            chapter.GetOwner().Send(new PacketScFactoryHsSync(chapter.GetOwner(), chapter, new List<FactoryNode>() { this}));
        }

        private bool AddConveyorItem(FactoryChapter chapter,ItemCount i)
        {
            float length=BlockCalculator.CalculateTotalBlocks(points);
            FComponentBoxConveyor conveyorComp = GetComponent<FComponentBoxConveyor>();
            if (conveyorComp != null)
            {
                if(conveyorComp.items.Count < (int)length)
                {
                    long timestamp = i.tms - conveyorComp.lastPopTms;
                    if(timestamp >= 2000)
                    {
                        conveyorComp.items.Add(i);
                        i.tms = DateTime.UtcNow.ToUnixTimestampMilliseconds();
                        conveyorComp.lastPopTms = i.tms;
                        chapter.GetOwner().Send(new PacketScFactoryHsSync(chapter.GetOwner(), chapter, new List<FactoryNode>() { this }));
                        return true;
                    }
                    else
                    {
                        return false;
                    }
                   
                        
                }
            }
            return false;
        }

        public bool InPower()
        {
            if (forcePowerOn)
            {
                return true;
            }
            return lastPowered;
        }
        public FComponent GetComponent<FComponent>() where FComponent : class
        {
            return components.Find(c => c is FComponent) as FComponent;
        }
        public FComponent GetComponent<FComponent>(uint compid) where FComponent : class
        {
            return components.Find(c => c is FComponent && c.compId==compid) as FComponent;
        }
        public List<FacPort> GetTransformedPorts(List<FacPort> originalPorts)
        {
            List<FacPort> transformedPorts = new List<FacPort>();

            if (originalPorts == null || originalPorts.Count == 0)
                return transformedPorts;

            FMesh mesh = GetMesh();
            if (mesh.points.Count < 2)
                return transformedPorts;

            Vector3f objectPosition = mesh.points[0];
            float objectRotationY = direction.y % 360f;

            FactoryBuildingTable table;
            if (!ResourceManager.factoryBuildingTable.TryGetValue(templateId, out table))
                return transformedPorts;

            float width = table.range.width - 1;
            float depth = table.range.depth - 1;

            foreach (FacPort originalPort in originalPorts)
            {
                FacPort transformedPort = new FacPort
                {
                    index = originalPort.index,
                    isOutput = originalPort.isOutput,
                    isPipe = originalPort.isPipe,
                    trans = new FacPort.FacPortTrans()
                };

                Vector3f originalPos = originalPort.trans.position;
                Vector3f transformedPos = objectPosition;

                switch ((int)objectRotationY)
                {
                    case 0:
                        transformedPos += originalPos;
                        break;

                    case 90:
                        transformedPos += new Vector3f(originalPos.z, originalPos.y, width - originalPos.x);
                        break;

                    case 180:
                        transformedPos += new Vector3f(width - originalPos.x, originalPos.y, depth - originalPos.z);
                        break;

                    case 270:
                        transformedPos += new Vector3f(depth - originalPos.z, originalPos.y, originalPos.x);
                        break;
                }

                transformedPort.trans.position = transformedPos;

                transformedPort.trans.rotation = new Vector3f(
                    originalPort.trans.rotation.x,
                    (originalPort.trans.rotation.y + objectRotationY) % 360f,
                    originalPort.trans.rotation.z
                );

                transformedPorts.Add(transformedPort);
            }

            return transformedPorts;
        }

        public FMesh GetMesh()
        {
            FMesh mesh = new FMesh();
            if(points != null)
            {
                points.ForEach(p =>
                {
                    mesh.points.Add(p);
                });
                mesh.type = FCMeshType.Line;
                return mesh;
            }
            if (ResourceManager.factoryBuildingTable.TryGetValue(templateId, out FactoryBuildingTable table))
            {
                float width = table.range.width - 1;
                float height = table.range.height - 1;
                float depth = table.range.depth - 1;

                Vector3f p1_final = new Vector3f();
                Vector3f p2_final = new Vector3f();

                switch (direction.y)
                {
                    case 0f:
                    case 360f:
                    default:
                        p1_final = position + new Vector3f(table.range.x, table.range.y, table.range.z);
                        p2_final = p1_final + new Vector3f(width, height, depth);
                        break;

                    case 90f:
                        p1_final = position + new Vector3f(table.range.x, table.range.y, table.range.z - width);
                        p2_final = p1_final + new Vector3f(depth, height, width);
                        break;

                    case 180f:
                        p1_final = position + new Vector3f(table.range.x - width, table.range.y, table.range.z - depth);
                        p2_final = p1_final + new Vector3f(width, height, depth);
                        break;

                    case 270f:
                        p1_final = position + new Vector3f(table.range.x - depth, table.range.y, table.range.z);
                        p2_final = p1_final + new Vector3f(depth, height, width);
                        break;
                }

                mesh.points.Add(p1_final);
                mesh.points.Add(p2_final);
            }

            return mesh;
        }


        public ScdFacNode ToProto()
        {
            ScdFacNode node = new ScdFacNode()
            {
                InstKey = instKey,
                NodeId = nodeId,
                TemplateId = templateId,
                StableId = GetStableId(),
                IsDeactive = deactive,

                Power = new()
                {
                    InPower = InPower(),
                    NeedInPower = true,
                    PowerCost= GetBuildingTable().bandwidth,
                    PowerCostShow= GetBuildingTable().bandwidth,
                },

                NodeType = (int)nodeType,
                Transform = new()
                {
                    Position = position.ToProtoScd(),
                    Direction = direction.ToProtoScd(),
                    MapId = mapId,
                    
                }
            };
            
            if (templateId != "__inventory__")
            {
                if(nodeType != FCNodeType.BoxConveyor)
                {
                    node.Transform.Mesh = GetMesh().ToProto();
                    node.Transform.Position = position.ToProtoScd();
                    node.Transform.WorldPosition = worldPosition.ToProto();
                    node.Transform.WorldRotation = direction.ToProto();
                    node.InteractiveObject = new()
                    {
                        ObjectId = guid,
                    };
                    node.Flag = 0;
                    node.InstKey = "";
                }
                else
                {
                    node.Transform.Mesh = GetMesh().ToProto();
                    node.Transform.Position = position.ToProtoScd();
                    node.Transform.WorldPosition = null;
                    node.Transform.WorldRotation = null;
                    node.InteractiveObject =null;
                    node.Transform.BcPortIn = new()
                    {
                        Direction = directionIn.ToProtoScd(),
                        Position = points[0].ToProtoScd()
                    };
                    node.Transform.BcPortOut = new()
                    {
                        Direction = directionOut.ToProtoScd(),
                        Position = points[points.Count-1].ToProtoScd()
                    };
                    node.Flag = 0;
                    node.InstKey = "";
                }
               
            }

            foreach (FComponent comp in components)
            {
                node.Components.Add(comp.ToProto());
                node.ComponentPos.Add((int)comp.GetComPos(), comp.compId);
            }

            return node;
        }
        public uint GetStableId()
        {
            return 10000 + nodeId;
        }
        public FCComponentType GetMainCompType()
        {
            string nodeTypeName = nodeType.ToString();
            if (Enum.TryParse(nodeTypeName, out FCComponentType fromName))
            {
                return fromName;
            }
            return FCComponentType.Invalid;
        }
        public void InitComponents(FactoryChapter chapter)
        {
            switch (nodeType)
            {
                case FCNodeType.PowerPole:
                    components.Add(new FComponentPowerPole(chapter.nextCompV()).Init());
                    break;
                case FCNodeType.PowerDiffuser:
                    components.Add(new FComponentPowerPole(chapter.nextCompV()).Init());
                    break;
                case FCNodeType.Battle:
                    components.Add(new FComponentBattle(chapter.nextCompV()).Init());
                    break;
                case FCNodeType.Producer:
                    if (templateId == "grinder_1")
                    {
                        nodeBehaviour = new NodeBuilding_Producer();
                    }else if (templateId == "furnance_1")
                    {
                        nodeBehaviour = new NodeBuilding_ProducerFurnace();
                    }
                    if(nodeBehaviour!=null)
                    nodeBehaviour.Init(chapter, this);
                    break;
                case FCNodeType.BoxConveyor:
                    components.Add(new FComponentBoxConveyor(chapter.nextCompV()).Init());
                    break;
                case FCNodeType.TravelPole:
                    components.Add(new FComponentTravelPole(chapter.nextCompV()).Init());
                    break;
                case FCNodeType.Hub:
                    components.Add(new FComponentSelector(chapter.nextCompV()).Init());
                    components.Add(new FComponentPowerPole(chapter.nextCompV()).Init());
                    components.Add(new FComponentPowerSave(chapter.nextCompV()).Init());
                    components.Add(new FComponentStablePower(chapter.nextCompV()).Init());
                    components.Add(new FComponentBusLoader(chapter.nextCompV()).Init());
                    components.Add(new FComponentPortManager(chapter.nextCompV(), GetComponent<FComponentBusLoader>().compId).Init());
                    forcePowerOn = true;
                    break;
                case FCNodeType.SubHub:
                    components.Add(new FComponentSubHub(chapter.nextCompV()).Init());
                    components.Add(new FComponentSelector(chapter.nextCompV()).Init());
                    components.Add(new FComponentPowerPole(chapter.nextCompV()).Init());
                    components.Add(new FComponentPowerSave(chapter.nextCompV()).Init());
                    components.Add(new FComponentStablePower(chapter.nextCompV()).Init());
                    components.Add(new FComponentBusLoader(chapter.nextCompV()).Init());
                    components.Add(new FComponentPortManager(chapter.nextCompV(), GetComponent<FComponentBusLoader>().compId).Init());
                    forcePowerOn = true;
                    break;
                default:
                    components.Add(new FComponent(chapter.nextCompV(), GetMainCompType()).Init());
                    break;
            }

        }

        public void SendEntity(Player player, string chapterId)
        {
            Entity exist = player.sceneManager.GetCurScene().entities.Find(e => e.guid == guid);
            if (exist != null)
            {
                exist.Position = worldPosition;
                exist.Rotation = direction;
                ScMoveObjectMove move = new()
                {
                    ServerNotify = true,
                    MoveInfo =
                    {
                        new MoveObjectMoveInfo()
                        {
                            Objid = guid,
                            SceneNumId=sceneNumId,
                            MotionInfo = new()
                            {
                                Position=exist.Position.ToProto(),
                                Rotation=exist.Rotation.ToProto(),
                                Speed=new Vector()
                                {

                                },
                                State=MotionState.MotionNone
                            }
                        }
                    }
                };
                player.Send(ScMsgId.ScMoveObjectMove, move);
            }
            else
            {
                if (interactiveFacWrapperTable.ContainsKey(templateId))
                {
                    EntityInteractive e = new(interactiveFacWrapperTable[templateId].interactiveTemplateId, player.roleId, worldPosition, direction, sceneNumId, guid);
                    e.InitDefaultProperties();
                    e.SetPropValue(nodeId, "factory_inst_id");

                    player.sceneManager.GetCurScene().entities.Add(e);
                    player.sceneManager.GetCurScene().SpawnEntity(e);
                }

            }

        }

        
        public class FMesh
        {
            public FCMeshType type;
            public List<Vector3f> points = new();
            public ScdFacMesh ToProto()
            {
                ScdFacMesh m = new ScdFacMesh()
                {
                    MeshType = (int)type
                };
                foreach (Vector3f p in points)
                {
                    m.Points.Add(new ScdVec3Int()
                    {
                        X = (int)p.x,
                        Y = (int)p.y,
                        Z = (int)p.z
                    });
                }
                return m;
            }
        }
    }
}
