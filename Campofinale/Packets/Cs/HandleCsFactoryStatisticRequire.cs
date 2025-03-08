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
