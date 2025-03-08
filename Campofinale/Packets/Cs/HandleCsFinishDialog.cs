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
    public class HandleCsFinishDialog
    {
        
        [Server.Handler(CsMsgId.CsFinishDialog)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFinishDialog req = packet.DecodeBody<CsFinishDialog>();
            session.Send(ScMsgId.ScFinishDialog, new ScFinishDialog()
            {
                DialogId=req.DialogId,
                FinishNums = { req.FinishNums },
                OptionIds = { req.OptionIds },
            });
        }
       
    }
}
