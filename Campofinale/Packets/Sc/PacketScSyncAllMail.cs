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
    public class PacketScSyncAllMail : Packet
    {

        public PacketScSyncAllMail(Player client) {

            ScSyncAllMail proto = new ScSyncAllMail()
            {
                
                
            };
            foreach (var mail in client.mails)
            {
                proto.MailIdList.Add(mail.guid);
            }
            SetData(ScMsgId.ScSyncAllMail, proto);
        }

    }
}
