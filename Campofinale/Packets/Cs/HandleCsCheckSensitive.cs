using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Cs
{
    
    public class HandleCsCheckSensitive
    {
        [Server.Handler(CsMsgId.CsCheckSensitive)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCheckSensitive req = packet.DecodeBody<CsCheckSensitive>();
            
            session.Send(ScMsgId.ScCheckSensitive, new ScCheckSensitive()
            {
                
            });
        }
    }
}
