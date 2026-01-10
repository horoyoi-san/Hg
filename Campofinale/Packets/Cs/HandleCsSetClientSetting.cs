using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSetClientSetting
    {
        
        [Server.Handler(CsMsgId.CsSetClientSetting)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSetClientSetting req = packet.DecodeBody<CsSetClientSetting>();
            session.clientSetting = req.ClientSettingModify.ToArray();
            session.Send(ScMsgId.ScSetClientSetting, new ScSetClientSetting());

        }
       
    }
}
