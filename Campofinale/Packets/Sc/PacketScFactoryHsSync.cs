using Campofinale.Game.Factory;
using Campofinale.Network;
using Campofinale.Protocol;
using System.Numerics;

namespace Campofinale.Packets.Sc
{
    public class PacketScFactoryHsSync : Packet
    {

        public PacketScFactoryHsSync(Player client, FactoryChapter chapter, List<FactoryNode> nodes) {

            long curtimestamp = DateTime.UtcNow.ToUnixTimestampMilliseconds();
            ScFactoryHsSync hs = new()
            {
                Tms = curtimestamp,
                Blackboard = chapter.blackboard.ToProto(),
                ChapterId = chapter.chapterId,
            };
            nodes.ForEach(node =>
            {
                node.components.ForEach(c =>
                {
                    hs.CcList.Add(c.ToProto());
                });
            });
            SetData(ScMsgId.ScFactoryHsSync, hs);
        }
       
    }
}
