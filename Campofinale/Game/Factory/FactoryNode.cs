using Campofinale.Game.Entities;
using Campofinale.Game.Factory.Components;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource.Table;
using Campofinale.Resource;
using MongoDB.Bson.Serialization.Attributes;
using static Campofinale.Resource.ResourceManager;
using Campofinale.Game.Factory.BuildingsBehaviour;
using Newtonsoft.Json;
using System.Drawing;
using Campofinale.Game.Inventory;
using System.Numerics;
using StardustUtils;
using static Campofinale.Resource.ResourceManager.FactoryBuildingTable;

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
                nodeBehaviour.Update(chapter, this);
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
            factoryBuildingTable.TryGetValue(templateId, out FactoryBuildingTable table);
            table ??= new FactoryBuildingTable();
            return table;
        }
        public void UpdatePortManager(FactoryChapter chapter, FComponentPortManager manager)
        {
            if (factoryBuildingTable.TryGetValue(templateId, out FactoryBuildingTable table))
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

                                    if (conveyorNode.AddConveyorItem(chapter, add))
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
                            if (toRemove != null)
                            {
                                conveyorNode.RemoveConveyorItem(chapter, toRemove);
                            }
                        }
                    }
                }
            }

        }

        private void RemoveConveyorItem(FactoryChapter chapter, ItemCount toRemove)
        {
            FComponentBoxConveyor conveyorComp = GetComponent<FComponentBoxConveyor>();
            conveyorComp.items.Remove(toRemove);
            chapter.GetOwner().Send(new PacketScFactoryHsSync(chapter.GetOwner(), chapter, new List<FactoryNode>() { this }));
        }

        private bool AddConveyorItem(FactoryChapter chapter, ItemCount i)
        {
            float length = BlockCalculator.CalculateTotalBlocks(points);
            FComponentBoxConveyor conveyorComp = GetComponent<FComponentBoxConveyor>();
            if (conveyorComp != null)
            {
                if (conveyorComp.items.Count < (int)length)
                {
                    long timestamp = i.tms - conveyorComp.lastPopTms;
                    if (timestamp >= 2000)
                    {
                        conveyorComp.items.Add(i);
                        i.tms = DateTime.UtcNow.ToUnixTimestampMilliseconds();
                        conveyorComp.lastPopTms = i.tms;
                        chapter.GetOwner().Send(new PacketScFactoryHsSync(chapter.GetOwner(), chapter, new List<FactoryNode>() { this }));
                        return true;
                    }

                    return false;
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
            return components.Find(c => c is FComponent && c.compId == compid) as FComponent;
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
            if (!factoryBuildingTable.TryGetValue(templateId, out table))
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
            if (points != null)
            {
                // Add points and remove duplicates
                foreach (var p in points)
                {
                    // Avoid adding duplicate consecutive points
                    if (mesh.points.Count == 0 ||
                        mesh.points[mesh.points.Count - 1].x != p.x ||
                        mesh.points[mesh.points.Count - 1].y != p.y ||
                        mesh.points[mesh.points.Count - 1].z != p.z)
                    {
                        mesh.points.Add(p);
                    }
                }
                mesh.type = FCMeshType.Line;
                return mesh;
            }
            if (factoryBuildingTable.TryGetValue(templateId, out FactoryBuildingTable table))
            {
                // Calculate size offset: range.width/height/depth represents grid count
                // Convert grid count to coordinate offset (grid count - 1)
                float width = table.range.width - 1;
                float height = table.range.height - 1;
                float depth = table.range.depth - 1;

                // Ensure minimum offset of 1 for each dimension
                // This is a mathematical requirement: a valid bounding box must be defined by two distinct vertices
                // Without this, mesh with width/depth/height = 1 would have p1 == p2, causing "duplicated point" client error
                if (width <= 0) width = 1;
                if (height <= 0) height = 1;
                if (depth <= 0) depth = 1;

                Vector3f p1_final = new Vector3f();
                Vector3f p2_final = new Vector3f();

                // All rotation calculations use the same width/height/depth values to ensure consistency
                // This prevents p1 and p2 from being identical after integer truncation in ToProto()
                switch (direction.y)
                {
                    case 0f:
                    case 360f:
                    default:
                        // No rotation: use range.x/y/z as base position, then add width/height/depth offset
                        p1_final = position + new Vector3f(table.range.x, table.range.y, table.range.z);
                        p2_final = p1_final + new Vector3f(width, height, depth);
                        break;

                    case 90f:
                        // Rotated 90 degrees: swap width and depth, adjust p1 position accordingly
                        p1_final = position + new Vector3f(table.range.x, table.range.y, table.range.z - width);
                        p2_final = p1_final + new Vector3f(depth, height, width);
                        break;

                    case 180f:
                        // Rotated 180 degrees: adjust p1 position by width and depth
                        p1_final = position + new Vector3f(table.range.x - width, table.range.y, table.range.z - depth);
                        p2_final = p1_final + new Vector3f(width, height, depth);
                        break;

                    case 270f:
                        // Rotated 270 degrees: swap width and depth, adjust p1 position accordingly
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
                    PowerCost = GetBuildingTable().bandwidth,
                    PowerCostShow = GetBuildingTable().bandwidth,
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
                if (nodeType != FCNodeType.BoxConveyor)
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
                    node.InteractiveObject = null;
                    node.Transform.BcPortIn = new()
                    {
                        Direction = directionIn.ToProtoScd(),
                        Position = points[0].ToProtoScd()
                    };
                    node.Transform.BcPortOut = new()
                    {
                        Direction = directionOut.ToProtoScd(),
                        Position = points[points.Count - 1].ToProtoScd()
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
                    switch (templateId)
                    {
                        case "grinder_1":
                            nodeBehaviour = new NodeBuilding_Producer();
                            break;
                        case "furnance_1":
                            nodeBehaviour = new NodeBuilding_ProducerFurnace();
                            break;
                        default:
                            break;
                    }
                    nodeBehaviour?.Init(chapter, this);
                    break;
                case FCNodeType.BoxConveyor:
                    components.Add(new FComponentBoxConveyor(chapter.nextCompV()).Init());
                    break;
                case FCNodeType.TravelPole:
                    components.Add(new FComponentTravelPole(chapter.nextCompV()).Init());
                    break;
                case FCNodeType.Hub:
                    components.Add(new FComponentHub(chapter.nextCompV()).Init());
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

        /// <summary>
        /// Sends or updates the factory node entity to the player
        /// Handles both existing entity updates and new entity creation
        /// </summary>
        /// <param name="player">The player to send the entity to</param>
        /// <param name="chapterId">The factory chapter ID</param>
        public void SendEntity(Player player, string chapterId)
        {
            var scene = player.sceneManager.GetCurScene();

            // Check if entity already exists
            Entity? existingEntity = scene.entities.Find(e => e.guid == guid);
            if (existingEntity != null)
            {
                UpdateExistingEntity(player, existingEntity);
            }
            else
            {
                CreateNewEntity(player, scene);
            }
        }

        /// <summary>
        /// Updates an existing entity's position and sends movement notification
        /// </summary>
        private void UpdateExistingEntity(Player player, Entity entity)
        {
            entity.Position = worldPosition;
            entity.Rotation = direction;

            var moveInfo = new MoveObjectMoveInfo()
            {
                Objid = guid,
                SceneNumId = sceneNumId,
                MotionInfo = new()
                {
                    Position = entity.Position.ToProto(),
                    Rotation = entity.Rotation.ToProto(),
                    Speed = new Vector(),
                    State = MotionState.MotionNone
                }
            };

            var move = new ScMoveObjectMove()
            {
                ServerNotify = true,
                MoveInfo = { moveInfo }
            };

            player.Send(new PacketScMoveObjectMove(player, move));
        }

        /// <summary>
        /// Creates a new entity based on the factory node type
        /// </summary>
        private void CreateNewEntity(Player player, Scene scene)
        {
            // Determine if this node type needs an interactive entity
            var entityCreationResult = DetermineEntityCreationType();

            switch (entityCreationResult.Type)
            {
                case EntityCreationType.InteractiveEntity:
                    CreateInteractiveEntity(player, scene, entityCreationResult.InteractiveTemplateId!, entityCreationResult.LogMessage);
                    break;

                case EntityCreationType.NoEntity:
                    Logger.Print(entityCreationResult.LogMessage);
                    break;

                case EntityCreationType.Unknown:
                default:
                    Logger.Print($"Warning: {entityCreationResult.LogMessage}");
                    break;
            }
        }

        /// <summary>
        /// Determines what type of entity creation is needed for this factory node
        /// </summary>
        private (EntityCreationType Type, string? InteractiveTemplateId, string LogMessage) DetermineEntityCreationType()
        {
            // 1. Check explicit interactive wrapper mappings (highest priority)
            if (interactiveFacWrapperTable.TryGetValue(templateId, out var wrapper))
            {
                return (EntityCreationType.InteractiveEntity, wrapper.interactiveTemplateId,
                    $"Interactive entity created for '{templateId}' using explicit mapping");
            }

            // 2. Standard factory buildings need auto-generated interactive entities
            if (factoryBuildingTable.ContainsKey(templateId))
            {
                string interactiveTemplateId = $"int_fac_{templateId}";
                return (EntityCreationType.InteractiveEntity, interactiveTemplateId,
                    $"FactoryBuilding node '{templateId}' created with generated interactive entity '{interactiveTemplateId}'");
            }

            // 3. Logistics nodes don't need interactive entities
            if (IsLogisticsNode())
            {
                return (EntityCreationType.NoEntity, null,
                    $"Logistics node '{templateId}' created without interactive entity");
            }

            // 4. Unknown node type
            return (EntityCreationType.Unknown, null,
                $"templateId '{templateId}' not found in any factory table, skipping EntityInteractive creation");
        }

        /// <summary>
        /// Checks if this node is a logistics node that doesn't need interactive entities
        /// </summary>
        private bool IsLogisticsNode()
        {
            return factoryGridConnecterTable.ContainsKey(templateId) ||
                   factoryGridRouterTable.ContainsKey(templateId) ||
                   factoryGridBeltTable.ContainsKey(templateId) ||
                   factoryLiquidConnectorTable.ContainsKey(templateId) ||
                   factoryLiquidRouterTable.ContainsKey(templateId) ||
                   factoryLiquidRepeaterTable.ContainsKey(templateId) ||
                   factoryLiquidPipeTable.ContainsKey(templateId);
        }

        /// <summary>
        /// Creates and registers an interactive entity
        /// </summary>
        private void CreateInteractiveEntity(Player player, Scene scene, string interactiveTemplateId, string logMessage)
        {
            var entity = new EntityInteractive(interactiveTemplateId, player.roleId, worldPosition, direction, sceneNumId, guid);
            entity.InitDefaultProperties();
            entity.SetPropValue(nodeId, "factory_inst_id");

            scene.entities.Add(entity);
            scene.SpawnEntity(entity);

            Logger.Print($"Info: {logMessage}");
        }

        /// <summary>
        /// Entity creation type enumeration
        /// </summary>
        private enum EntityCreationType
        {
            InteractiveEntity,
            NoEntity,
            Unknown
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
