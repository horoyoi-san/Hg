using Campofinale.Network;
using Campofinale.Packets.Sc;
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
    public class HandleCsCharBagSetTeamLeader
    {

        [Server.Handler(CsMsgId.CsCharBagSetTeamLeader)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCharBagSetTeamLeader req = packet.DecodeBody<CsCharBagSetTeamLeader>();

            session.teams[req.TeamIndex].leader=req.Leaderid;
            ScCharBagSetTeamLeader rsp = new()
            {
                Leaderid = req.Leaderid,
                TeamIndex = req.TeamIndex,
                ScopeName = 1,
                TeamType = req.TeamType,
            };
            session.Send(ScMsgId.ScCharBagSetTeamLeader, rsp);
            
        }
       
    }
}
