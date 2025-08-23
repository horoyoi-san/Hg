using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneSetBattle
    {
        
        [Server.Handler(CsMsgId.CsSceneSetBattle)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneSetBattle req = packet.DecodeBody<CsSceneSetBattle>();

            ScSceneSetBattle rsp = new()
            {
                InBattle = req.InBattle,
            };
            session.Send(ScMsgId.ScSceneSetBattle, rsp);
        }
       
    }
}
