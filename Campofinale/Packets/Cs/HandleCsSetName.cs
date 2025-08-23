using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Cs
{
    
    public class HandleCsSetName
    {
        [Server.Handler(CsMsgId.CsSetName)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSetName req = packet.DecodeBody<CsSetName>();
            session.nickname = req.Name;
            session.Send(ScMsgId.ScSetName, new ScSetName()
            {
                Name = req.Name,
               
            },packet.csHead.UpSeqid);
        }
    }
}
