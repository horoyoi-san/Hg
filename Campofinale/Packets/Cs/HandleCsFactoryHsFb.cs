using Campofinale.Game.Factory;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsFactoryHsFb
    {

        [Server.Handler(CsMsgId.CsFactoryHsFb)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFactoryHsFb req = packet.DecodeBody<CsFactoryHsFb>();
            
            List<ScdFacCom> comps = new();

            foreach (var id in req.NodeIdList)
            {
                FactoryNode node=session.factoryManager.GetChapter(req.ChapterId).nodes.Find(n=>n.nodeId == id);
                if (node != null)
                {
                    node.components.ForEach(c =>
                    {
                        comps.Add(c.ToProto());
                    });
                }
            }
            
            long curtimestamp = DateTime.UtcNow.ToUnixTimestampMilliseconds();
            ScFactoryHsSync hs = new()
            {
                Tms = curtimestamp,
                CcList =
                {
                    comps,
                },
                Blackboard = session.factoryManager.GetChapter(req.ChapterId).ToProto().Blackboard,
                ChapterId=req.ChapterId,
            };
            session.Send(ScMsgId.ScFactoryHsSync, hs,packet.csHead.UpSeqid);
            
        }
       
    }
}
