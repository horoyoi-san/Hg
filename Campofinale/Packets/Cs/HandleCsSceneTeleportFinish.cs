using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Utils;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneTeleportFinish
    {

        [Server.Handler(CsMsgId.CsSceneTeleportFinish)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneTeleportFinish req = packet.DecodeBody<CsSceneTeleportFinish>();
            session.sceneLoadState=Player.SceneLoadState.OK;
        }
       
    }
}
