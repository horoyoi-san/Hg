using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneLoadFinish
    {
        [Server.Handler(CsMsgId.CsSceneLoadFinish)]
        public static void HandleSceneFinish(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneLoadFinish req = packet.DecodeBody<CsSceneLoadFinish>();

            session.curSceneNumId=req.SceneNumId;
            session.Send(new PacketScSelfSceneInfo(session, SelfInfoReasonType.SlrEnterScene));
            session.sceneManager.LoadCurrentTeamEntities();
            session.sceneManager.LoadCurrent();
            
            if (session.curSceneNumId == 98)
            {
                session.Send(new PacketScSyncGameMode(session, "spaceship"));
            }
            else
            {
                
                if (session.currentDungeon != null && session.curSceneNumId==GetSceneNumIdFromLevelData(session.currentDungeon.table.sceneId))
                {
                    session.Send(new PacketScSyncGameMode(session, "dungeon_race"));
                }
                else
                {
                    session.currentDungeon = null;
                    session.Send(new PacketScSyncGameMode(session, ""));
                }
                    
            }
            session.sceneLoadState = Player.SceneLoadState.OK;
        }
    }
}
