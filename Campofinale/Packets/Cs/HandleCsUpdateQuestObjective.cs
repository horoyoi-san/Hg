using Campofinale.Network;
using Campofinale.Protocol;
using Google.Protobuf;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

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
