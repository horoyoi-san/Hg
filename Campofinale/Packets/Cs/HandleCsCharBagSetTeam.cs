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
    public class HandleCsCharBagSetTeam
    {

        [Server.Handler(CsMsgId.CsCharBagSetTeam)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCharBagSetTeam req = packet.DecodeBody<CsCharBagSetTeam>();

            session.teams[req.TeamIndex].leader=req.LeaderId;
            session.teams[req.TeamIndex].members= req.CharTeam.ToList();
            ScCharBagSetTeam team = new()
            {
                CharTeam = { req.CharTeam },
                LeaderId = req.LeaderId,
                ScopeName = 1,
                TeamIndex = req.TeamIndex,
                TeamType = CharBagTeamType.Main,
            };
            
            session.Send(ScMsgId.ScCharBagSetTeam,team);
            session.Send(new PacketScSelfSceneInfo(session, Resource.SelfInfoReasonType.SlrChangeTeam));
        }
       
    }
}
