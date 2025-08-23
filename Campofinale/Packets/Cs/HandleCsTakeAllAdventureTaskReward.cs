using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Cs
{
    public class HandleCsTakeAllAdventureTaskReward
    {
        
        [Server.Handler(CsMsgId.CsTakeAllAdventureTaskReward)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsTakeAllAdventureTaskReward req = packet.DecodeBody<CsTakeAllAdventureTaskReward>();
            session.adventureBookManager.ClaimTasks((AdventureTaskType)req.TaskType);
            session.Send(new PacketScAdventureBookSync(session), packet.csHead.UpSeqid);
        }
       
    }
}
