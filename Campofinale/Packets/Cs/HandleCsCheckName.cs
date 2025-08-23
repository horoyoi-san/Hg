using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Cs
{
    
    public class HandleCsCheckName
    {
        [Server.Handler(CsMsgId.CsCheckName)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsCheckName req = packet.DecodeBody<CsCheckName>();
            session.Send(ScMsgId.ScCheckName, new ScCheckName()
            {
                Name = req.Name,
                Pass=true
            },packet.csHead.UpSeqid);
        }
    }
}
