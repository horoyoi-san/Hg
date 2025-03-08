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
    public class HandleCsFactoryOp
    {

        [Server.Handler(CsMsgId.CsFactoryOp)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFactoryOp req = packet.DecodeBody<CsFactoryOp>();
            session.factoryManager.ExecOp(req,packet.csHead.UpSeqid);
        }
       
    }
}
