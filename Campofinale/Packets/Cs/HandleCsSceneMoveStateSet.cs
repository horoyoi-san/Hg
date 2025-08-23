using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneMoveStateSet
    {
        
        [Server.Handler(CsMsgId.CsSceneMoveStateSet)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneMoveStateSet req = packet.DecodeBody<CsSceneMoveStateSet>();
            //req.
            
        }
       
    }
}
