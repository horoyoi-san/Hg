using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneMonsterSpawnerBeginWave
    {

        [Server.Handler(CsMsgId.CsSceneMonsterSpawnerBeginWave)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneMonsterSpawnerBeginWave req = packet.DecodeBody<CsSceneMonsterSpawnerBeginWave>();
            session.sceneManager.GetCurScene().SpawnWaveEnemy(req.SpawnerId, req.WaveId);
            session.Send(ScMsgId.ScSceneMonsterSpawnerBeginWave, new ScSceneMonsterSpawnerBeginWave()
            {
                SceneNumId=req.SceneNumId,
                SpawnerId=req.SpawnerId,
                WaveId=req.WaveId,
            });
            
        }
       
    }
}
