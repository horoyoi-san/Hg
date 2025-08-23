using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsFlushSync
    {
        
        [Server.Handler(CsMsgId.CsFlushSync)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFlushSync req = packet.DecodeBody<CsFlushSync>();
            long curtimestamp = DateTime.UtcNow.ToUnixTimestampMilliseconds();
            ScFlushSync sync = new()
            {
                ClientTs=req.ClientTs,
                ServerTs=(ulong)curtimestamp,
                
            };
            session.Send(ScMsgId.ScFlushSync, sync,packet.csHead.UpSeqid);
           
            //Logger.Print("Server: " + curtimestamp + " client: " + req.ClientTs);
        }
       
    }
}
