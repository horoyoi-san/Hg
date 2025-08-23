using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsUpdateQuestObjective
    {
        
        [Server.Handler(CsMsgId.CsUpdateQuestObjective)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsUpdateQuestObjective req = packet.DecodeBody<CsUpdateQuestObjective>();
            ScQuestObjectivesUpdate u = new()
            {
                QuestId = req.QuestId,
                QuestObjectives =
                {
                    
                }
            };
            session.Send(ScMsgId.ScQuestObjectivesUpdate, u);
        }
       
    }
}
