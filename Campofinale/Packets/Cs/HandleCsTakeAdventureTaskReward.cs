using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsTakeAdventureTaskReward
    {
        
        [Server.Handler(CsMsgId.CsTakeAdventureTaskReward)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsTakeAdventureTaskReward req = packet.DecodeBody<CsTakeAdventureTaskReward>();
            session.adventureBookManager.ClaimTask(req.TaskId);
            session.Send(new PacketScAdventureBookSync(session), packet.csHead.UpSeqid);
        }
       
    }
}
