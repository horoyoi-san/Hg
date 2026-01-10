using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using Campofinale.Resource.Table;

namespace Campofinale.Packets.Sc
{
    public class PacketScFactorySyncScope : Packet
    {

        public PacketScFactorySyncScope(Player client)
        {
            // Build PanelStore goods from all chapters
            var panelStoreGoods = new List<ScdFactoryPanelStoreGood>();

            foreach (var chapter in client.factoryManager.chapters)
            {
                panelStoreGoods.AddRange(chapter.BuildPanelStoreGoodsProto());
            }

            // TODO: Remove hardcoded values
            SetData(ScMsgId.ScFactorySyncScope, new ScFactorySyncScope()
            {
                ScopeName = 1,
                CurrentChapterId = client.GetCurrentChapter(),
                ActiveChapterIds =
                {
                    client.factoryManager.chapters.Select(f=>f.chapterId)
                },
                PanelStore = new ScdFactorySyncPanelStore
                {
                    Goods = { panelStoreGoods }
                },
                SharedMgr = new(),
                SignMgr = new(),
                TransportRoute = new()
                {
                    UpdateTs = DateTime.UtcNow.AddMinutes(1).ToUnixTimestampMilliseconds() / 1000,
                    Routes =
                    {
                        new ScdFactoryHubTransportRoute
                        {
                            ChapterId = "domain_1",
                            Index = 1,

                        },
                        new ScdFactoryHubTransportRoute
                        {
                            ChapterId = "domain_2",
                            Index = 2,

                        }
                    }
                },
                BookMark = new()
                {

                },

            });
        }

    }
}
