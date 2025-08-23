using Campofinale.Network;
using Campofinale.Protocol;

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
