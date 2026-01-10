using Campofinale.Database;
using Campofinale.Game.Entities;
using Campofinale.Game.Factory.Components;
using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Factory
{
    public class FactoryManager
    {
        public Player player;
        public List<FactoryChapter> chapters = new();
        public ObjectId _id;

        public class FactoryData
        {
            public ulong roleId;
            public ObjectId _id;
            public List<FactoryChapter> chapters = new();
        }
        public FactoryManager(Player player)
        {
            this.player = player;
        }
        public void Load()
        {
            FactoryData data = DatabaseManager.db.LoadFactoryData(player.roleId);
            if (data != null)
            {
                _id = data._id;
                chapters = data.chapters;
            }

            // Ensure default chapters exist
            if (!ChapterExist("domain_1")) chapters.Add(new FactoryChapter("domain_1", player.roleId));
            if (!ChapterExist("domain_2")) chapters.Add(new FactoryChapter("domain_2", player.roleId));

            // Unified initialization for all chapters (handles both new and deserialized chapters)
            foreach (var chapter in chapters)
            {
                // Initialize sub-managers (required for deserialized chapters since constructor wasn't called)
                chapter.InitializeSubManagers();

                // Auto-upgrade domain development level to maximum (12) for existing data
                if (chapter.domainDevelopmentLevel < 12)
                {
                    chapter.domainDevelopmentLevel = 12;
                }
            }
        }

        /// <summary>
        /// Resolves factory node table and type from templateId
        /// Maps templateId to appropriate table data source and FCNodeType
        /// </summary>
        /// <param name="templateId">Factory node template identifier</param>
        /// <returns>Tuple of (table, nodeType) or null if not found</returns>
        public static (object table, FCNodeType nodeType)? ResolveFactoryTable(string templateId)
        {
            // Define table resolvers with metadata for better maintainability
            var tableResolvers = new (string Description, Func<(object, FCNodeType)?> Resolver)[]
            {
                // 1. Standard factory buildings - production machines, storages, power systems
                ("FactoryBuildingTable: production/storages/power nodes", () =>
                    ResourceManager.factoryBuildingTable.TryGetValue(templateId, out var table) ? (table, table.GetNodeType()) : null),

                // 2. Grid connectors - logistics connection nodes with multiple ports (log_connector)
                ("FactoryGridConnecterTable: grid connectors (4in+4out)", () =>
                    ResourceManager.factoryGridConnecterTable.TryGetValue(templateId, out var table) ? (table, table.GetNodeType()) : null),

                // 3. Grid routers - logistics splitters/mergers (log_splitter, log_converger)
                ("FactoryGridRouterTable: grid routers (1→3, 3→1)", () =>
                    ResourceManager.factoryGridRouterTable.TryGetValue(templateId, out var table) ? (table, table.GetNodeType()) : null),

                // 4. Grid belts - conveyor belt systems (grid_belt_01)
                ("FactoryGridBeltTable: conveyor belts", () =>
                    ResourceManager.factoryGridBeltTable.TryGetValue(templateId, out var table) ? (table, table.GetNodeType()) : null),

                // 5. Liquid connectors - fluid connection nodes (log_pipe_connector)
                ("FactoryLiquidConnectorTable: liquid connectors (4in+4out)", () =>
                    ResourceManager.factoryLiquidConnectorTable.TryGetValue(templateId, out var table) ? (table, table.GetNodeType()) : null),

                // 6. Liquid routers - fluid splitters/mergers (log_pipe_splitter, log_pipe_converger)
                ("FactoryLiquidRouterTable: liquid routers (1→3, 3→1)", () =>
                    ResourceManager.factoryLiquidRouterTable.TryGetValue(templateId, out var table) ? (table, table.GetNodeType()) : null),

                // 7. Liquid repeaters - fluid signal extenders (log_pipe_repeater)
                ("FactoryLiquidRepeaterTable: liquid repeaters (4in+4out)", () =>
                    ResourceManager.factoryLiquidRepeaterTable.TryGetValue(templateId, out var table) ? (table, table.GetNodeType()) : null),

                // 8. Liquid pipes - basic fluid transport (log_pipe_01)
                ("FactoryLiquidPipeTable: liquid pipes", () =>
                    ResourceManager.factoryLiquidPipeTable.TryGetValue(templateId, out var table) ? (table, table.GetNodeType()) : null),
            };

            // Try each resolver in order until one succeeds
            foreach (var (_, resolver) in tableResolvers)
            {
                var result = resolver();
                if (result.HasValue)
                {
                    return result.Value;
                }
            }

            return null;
        }


        public bool ChapterExist(string id)
        {
            return chapters.Find(c => c.chapterId == id) != null;
        }
        public void Save()
        {
            DatabaseManager.db.UpsertFactoryData(new FactoryData()
            {
                _id = _id,
                roleId = player.roleId,
                chapters = chapters
            });
        }
        public void ExecOp(CsFactoryOp op, ulong seq)
        {
            FactoryChapter chapter = GetChapter(op.ChapterId);
            if (chapter != null)
            {
                chapter.ExecOp(op, seq);

            }
            else
            {
                player.Send(new PacketScFactoryOpRet(player, op, seq));
            }
        }
        public void SendFactoryHsSync()
        {
            if (!player.Initialized) return;
            if (player.GetCurrentChapter() == "") return;
            List<FactoryNode> nodeUpdateList = new();
            foreach (var node in GetChapter(player.GetCurrentChapter()).nodes)
            {
                if (node != null)
                {
                    if (node.position.DistanceXZ(player.position) < 150 && node.nodeBehaviour != null)
                    {
                        nodeUpdateList.Add(node);
                    }
                }
            }
            player.Send(new PacketScFactoryHsSync(player, GetChapter(player.GetCurrentChapter()), nodeUpdateList));
        }
        public void Update()
        {
            if (!player.Initialized) return;
            foreach (FactoryChapter chapter in chapters)
            {
                chapter.Update();
            }

        }
        public FactoryChapter GetChapter(string id)
        {
            return chapters.Find(c => c.chapterId == id);
        }
    }
}
