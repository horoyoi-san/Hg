using Campofinale.Network;
using Campofinale.Protocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Packets.Sc
{
    public class PacketScGetMail : Packet
    {

        public PacketScGetMail(Player client) {

            ScGetMail proto = new ScGetMail()
            {
                MailList =
                {
                }
                
            };
            foreach (var mail in client.mails)
            {
                proto.MailList.Add(mail.ToProto());
            }
            SetData(ScMsgId.ScGetMail, proto);
        }

    }
}
