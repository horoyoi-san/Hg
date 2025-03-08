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
    public class HandleCsFactoryHsFb
    {

        [Server.Handler(CsMsgId.CsFactoryHsFb)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFactoryHsFb req = packet.DecodeBody<CsFactoryHsFb>();
            long curtimestamp = DateTime.UtcNow.ToUnixTimestampMilliseconds();

            ScFactoryHs hs = new()
            {


            };
            session.Send(ScMsgId.ScFactoryHs, hs);
            
        }
       
    }
}
