using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScFactoryModifyChapterMap : Packet
    {
        public PacketScFactoryModifyChapterMap(Player client, string chapterId, int mapId, List<ScdFactorySyncMapWire> wires)
        {
            ScFactoryModifyChapterMap modify = new()
            {
                ChapterId = chapterId,
                MapId = mapId,
                Tms = DateTime.UtcNow.ToUnixTimestampMilliseconds(),
                Wires =
                {
                    wires
                }
            };
            SetData(ScMsgId.ScFactoryModifyChapterMap, modify);
        }

        public PacketScFactoryModifyChapterMap(Player client, string chapterId, int mapId, List<ulong> removeWires)
        {
            ScFactoryModifyChapterMap modify = new()
            {
                ChapterId = chapterId,
                MapId = mapId,
                Tms = DateTime.UtcNow.ToUnixTimestampMilliseconds(),
                RemoveWires =
                {
                    removeWires
                }
            };
            SetData(ScMsgId.ScFactoryModifyChapterMap, modify);
        }
    }
}

