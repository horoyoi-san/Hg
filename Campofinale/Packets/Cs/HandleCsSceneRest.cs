using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneRest
    {
        
        [Server.Handler(CsMsgId.CsSceneRest)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneRest req = packet.DecodeBody<CsSceneRest>();
            if (session.sceneLoadState == Player.SceneLoadState.Loading) return;
            ScSceneRevival revival = new()
            {
                
            };
            session.RestTeam();
            session.sceneManager.LoadCurrentTeamEntities();
            session.Send(ScMsgId.ScSceneRevival, revival, packet.csHead.UpSeqid);
            session.Send(new PacketScSelfSceneInfo(session, SelfInfoReasonType.SlrReviveRest));
            
        }
       
    }
}
