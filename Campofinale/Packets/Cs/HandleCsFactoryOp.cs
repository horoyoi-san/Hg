using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsFactoryOp
    {

        [Server.Handler(CsMsgId.CsFactoryOp)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFactoryOp req = packet.DecodeBody<CsFactoryOp>();
            session.factoryManager.ExecOp(req,packet.csHead.UpSeqid);
        }
       
    }
}
