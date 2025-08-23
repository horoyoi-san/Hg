using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsFactoryStatisticRequire
    {
        
        [Server.Handler(CsMsgId.CsFactoryStatisticRequire)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFactoryStatisticRequire req = packet.DecodeBody<CsFactoryStatisticRequire>();
            ScFactoryStatisticRequire rsp = new()
            {

            };
            
            session.Send(ScMsgId.ScFactoryStatisticRequire, rsp);
           
            //Logger.Print("Server: " + curtimestamp + " client: " + req.ClientTs);
        }
       
    }
}
