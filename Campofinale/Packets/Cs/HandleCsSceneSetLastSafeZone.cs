using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneSetLastSafeZone
    {

        [Server.Handler(CsMsgId.CsSceneSetLastSafeZone)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneSetLastSafeZone req = packet.DecodeBody<CsSceneSetLastSafeZone>();
            /*if (req.SceneNumId != session.curSceneNumId)
            {
                session.SeamlessEnterScene(req.SceneNumId);
            }*/
        }
       
    }
}
