using Campofinale.Game.Factory.Components;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using StardustUtils;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Factory
{
    /// <summary>
    /// Handles all node-related operations for FactoryChapter
    /// </summary>
    public class FactoryNodeOps
    {
        private readonly FactoryChapter chapter;

        public FactoryNodeOps(FactoryChapter chapter)
        {
            this.chapter = chapter;
        }

        /// <summary>
        /// Create a new factory node
        /// </summary>
        public void CreateNode(CsFactoryOp op, ulong seq)
        {
            chapter.v++;
            uint nodeId = chapter.v;
            CsdFactoryOpPlace place = op.Place;

            // Determine node type and get table data from appropriate source
            var tableResult = FactoryManager.ResolveFactoryTable(place.TemplateId);
            if (tableResult == null)
            {
                Logger.Print($"Error: Unknown factory templateId '{place.TemplateId}' not found in any table");
                return;
            }

            var (table, nodeType) = tableResult.Value;
            FactoryNode node = new()
            {
                nodeId = nodeId,
                templateId = place.TemplateId,
                mapId = place.MapId,
                sceneNumId = chapter.GetOwner().sceneManager.GetCurScene().sceneNumId,
                nodeType = nodeType,
                position = new Vector3f(place.Position),
                direction = new Vector3f(place.Direction),
                worldPosition = new Vector3f(place.InteractiveParam.Position),
                guid = chapter.GetOwner().random.NextRand(),

            };

            node.InitComponents(chapter);
            chapter.GetOwner().Send(new PacketScFactoryModifyChapterNodes(chapter.GetOwner(), chapter.chapterId, node));
            chapter.nodes.Add(node);
            node.SendEntity(chapter.GetOwner(), chapter.chapterId);

            chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), node.nodeId, op), seq);
        }

        /// <summary>
        /// Place a conveyor belt node
        /// </summary>
        public void PlaceConveyor(CsFactoryOp op, ulong seq)
        {
            var placeConveyor = op.PlaceConveyor;
            chapter.v++;
            uint nodeId = chapter.v;
            List<Vector3f> points = new();
            foreach (var point in placeConveyor.Points)
            {
                points.Add(new Vector3f(point));
            }
            FactoryNode node = new()
            {
                nodeId = nodeId,
                templateId = placeConveyor.TemplateId,
                mapId = placeConveyor.MapId,
                sceneNumId = chapter.GetOwner().sceneManager.GetCurScene().sceneNumId,
                nodeType = FCNodeType.BoxConveyor,
                position = new Vector3f(placeConveyor.Points[0]),
                direction = new(),
                directionIn = new Vector3f(placeConveyor.DirectionIn),
                directionOut = new Vector3f(placeConveyor.DirectionOut),
                worldPosition = null,
                points = points,
                guid = chapter.GetOwner().random.NextRand(),
            };

            node.InitComponents(chapter);
            chapter.GetOwner().Send(new PacketScFactoryModifyChapterNodes(chapter.GetOwner(), chapter.chapterId, node));
            chapter.nodes.Add(node);

            chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), nodeId, op), seq);
        }

        /// <summary>
        /// Move an existing node
        /// </summary>
        public void MoveNode(CsFactoryOp op, ulong seq)
        {
            var move = op.MoveNode;
            FactoryNode? node = chapter.nodes.Find(n => n.nodeId == move.NodeId);
            if (node != null)
            {
                node.direction = new Vector3f(move.Direction);
                node.position = new Vector3f(move.Position);
                node.worldPosition = new Vector3f(move.InteractiveParam.Position);
                chapter.GetOwner().Send(new PacketScFactoryModifyChapterNodes(chapter.GetOwner(), chapter.chapterId, node));
                chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), node.nodeId, op), seq);
                node.SendEntity(chapter.GetOwner(), chapter.chapterId);
            }
            else
            {
                chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), op, seq));
            }
        }

        /// <summary>
        /// Dismantle a factory node
        /// </summary>
        public void DismantleNode(CsFactoryOp op, ulong seq)
        {
            var dismantle = op.Dismantle;

            FactoryNode? nodeRem = chapter.nodes.Find(n => n.nodeId == dismantle.NodeId);
            if (nodeRem != null)
            {
                chapter.wire.RemoveConnectionsToNode(nodeRem, chapter.nodes);
                chapter.nodes.Remove(nodeRem);
                chapter.GetOwner().Send(new PacketScFactoryModifyChapterMap(chapter.GetOwner(), chapter.chapterId, nodeRem.mapId, chapter.wire.GetWires()));
                chapter.GetOwner().Send(new PacketScFactoryModifyChapterNodes(chapter.GetOwner(), chapter.chapterId, nodeRem.nodeId));
                chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), nodeRem.nodeId, op), seq);
            }
            else
            {
                chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), op, seq));
            }
        }

        /// <summary>
        /// Dismantle a box conveyor node
        /// </summary>
        public void DismantleBoxConveyor(CsFactoryOp op, ulong seq)
        {
            var dismantle = op.DismantleBoxConveyor;

            FactoryNode? nodeRem = chapter.nodes.Find(n => n.nodeId == dismantle.NodeId);
            if (nodeRem != null)
            {
                chapter.wire.RemoveConnectionsToNode(nodeRem, chapter.nodes);
                chapter.nodes.Remove(nodeRem);
                chapter.GetOwner().Send(new PacketScFactoryModifyChapterNodes(chapter.GetOwner(), chapter.chapterId, nodeRem.nodeId));
                chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), nodeRem.nodeId, op), seq);
            }
            else
            {
                chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), op, seq));
            }
        }

        /// <summary>
        /// Enable or disable a node
        /// </summary>
        public void EnableNode(CsFactoryOp op, ulong seq)
        {
            var enableNode = op.EnableNode;
            FactoryNode? node = chapter.nodes.Find(n => n.nodeId == enableNode.NodeId);
            if (node != null)
            {
                node.deactive = !enableNode.Enable;
                chapter.GetOwner().Send(new PacketScFactoryModifyChapterNodes(chapter.GetOwner(), chapter.chapterId, node));
            }
            chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), 0, op), seq);
        }

        /// <summary>
        /// Change producer mode for a node
        /// </summary>
        public void ChangeProducerMode(CsFactoryOp op, ulong seq)
        {
            var changeMode = op.ChangeProducerMode;
            FactoryNode? node = chapter.nodes.Find(n => n.nodeId == changeMode.NodeId);
            if (node != null)
            {
                FComponentFormulaMan formula = node.GetComponent<FComponentFormulaMan>();
                if (formula != null)
                {
                    formula.currentMode = changeMode.ToMode; //test, not sure
                }

            }
            chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), 0, op), seq);
        }

        /// <summary>
        /// Set travel pole default next component
        /// </summary>
        public void SetTravelPoleDefaultNext(CsFactoryOp op, ulong seq)
        {
            FactoryNode travelNode = chapter.GetNodeByCompId(op.SetTravelPoleDefaultNext.ComponentId);
            travelNode.GetComponent<FComponentTravelPole>().defaultNext = op.SetTravelPoleDefaultNext.DefaultNext;
            chapter.GetOwner().Send(new PacketScFactoryModifyChapterNodes(chapter.GetOwner(), chapter.chapterId, travelNode));
            chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), 0, op), seq);
        }
    }
}

