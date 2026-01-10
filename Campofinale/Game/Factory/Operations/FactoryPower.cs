using Campofinale.Game.Factory.Components;

namespace Campofinale.Game.Factory
{
    /// <summary>
    /// Manages power grid system for factory chapter
    /// </summary>
    public class FactoryPower
    {
        private readonly FactoryChapter chapter;

        public FactoryPower(FactoryChapter chapter)
        {
            this.chapter = chapter;
        }

        /// <summary>
        /// Reset all nodes' power state
        /// </summary>
        public void ResetAllPower(List<FactoryNode> allNodes)
        {
            foreach (var node in allNodes)
            {
                node.powered = false;
            }
        }

        /// <summary>
        /// Update power grid by propagating power from power sources
        /// </summary>
        public void UpdatePowerGrid(List<FactoryNode> allNodes)
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

        /// <summary>
        /// Propagate power from a node to connected nodes
        /// </summary>
        private void PropagatePowerFrom(FactoryNode node, HashSet<uint> visited)
        {
            if (visited.Contains(node.nodeId))
                return;

            visited.Add(node.nodeId);
            node.powered = true;
            if (node.templateId == "power_diffuser_1")
            {
                //get builds in area test
                List<FactoryNode> nodes = chapter.GetNodesInRange(node.position, 15);
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
                    FactoryNode connectedNode = chapter.GetNodeByCompId(connectedCompId.Value);
                    if (connectedNode != null)
                    {
                        PropagatePowerFrom(connectedNode, visited);
                    }
                }
        }
    }
}

