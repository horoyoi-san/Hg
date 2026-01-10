using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using System.Linq;

namespace Campofinale.Game.Factory
{
    /// <summary>
    /// Manages connections (wires) between factory nodes
    /// </summary>
    public class FactoryWire
    {
        private readonly FactoryChapter chapter;

        public FactoryWire(FactoryChapter chapter)
        {
            this.chapter = chapter;
        }

        /// <summary>
        /// Add a connection between two components
        /// </summary>
        public void AddConnection(CsFactoryOp op, ulong seq)
        {
            FComponent nodeFrom = chapter.GetCompById(op.AddConnection.FromComId);
            FComponent nodeTo = chapter.GetCompById(op.AddConnection.ToComId);

            if (nodeFrom != null && nodeTo != null)
            {
                chapter.GetNodeByCompId(nodeFrom.compId).connectedComps.Add(new(nodeFrom.compId, nodeTo.compId));
                chapter.GetNodeByCompId(nodeTo.compId).connectedComps.Add(new(nodeTo.compId, nodeFrom.compId));
                chapter.GetOwner().Send(new PacketScFactoryModifyChapterMap(chapter.GetOwner(), chapter.chapterId, chapter.GetNodeByCompId(nodeFrom.compId).mapId, GetWires()));
                var wire = GetWires().Find(w =>
                    (w.FromComId == op.AddConnection.FromComId && w.ToComId == op.AddConnection.ToComId) ||
                    (w.FromComId == op.AddConnection.ToComId && w.ToComId == op.AddConnection.FromComId));

                if (wire != null)
                {
                    chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), (uint)wire.Index, op), seq);
                }
                else
                {
                    Console.WriteLine($"[WARN] Connessione non trovata tra {op.AddConnection.FromComId} e {op.AddConnection.ToComId}");
                }

            }
        }

        /// <summary>
        /// Remove all connections to a node
        /// </summary>
        public void RemoveConnectionsToNode(FactoryNode nodeRem, List<FactoryNode> allNodes)
        {
            // Get all compIds of the node to be removed
            HashSet<ulong> remCompIds = nodeRem.components.Select(c => (ulong)c.compId).ToHashSet();

            foreach (var node in allNodes)
            {
                node.connectedComps.RemoveAll(conn =>
                    remCompIds.Contains(conn.Key) || remCompIds.Contains(conn.Value));
            }
        }

        /// <summary>
        /// Get all wires (connections) for proto serialization
        /// </summary>
        public List<ScdFactorySyncMapWire> GetWires()
        {
            List<ScdFactorySyncMapWire> wires = [];
            HashSet<(ulong, ulong)> addedConnections = new();
            ulong i = 0;

            // Handle null nodes list (can happen after deserialization)
            if (chapter.nodes == null)
            {
                return wires;
            }

            foreach (FactoryNode node in chapter.nodes)
            {
                // Handle null node or null connectedComps (can happen after deserialization)
                if (node == null || node.connectedComps == null)
                {
                    continue;
                }

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
    }
}

