using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Cs
{
    public class HandleCsAdventureTakeRewardAll
    {
        
        [Server.Handler(CsMsgId.CsAdventureTakeRewardAll)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsAdventureTakeRewardAll req = packet.DecodeBody<CsAdventureTakeRewardAll>();
            //TODO
            
        }
       
    }
}
