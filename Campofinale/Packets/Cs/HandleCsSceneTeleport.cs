using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Utils;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneTeleport
    {

        [Server.Handler(CsMsgId.CsSceneTeleport)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneTeleport req = packet.DecodeBody<CsSceneTeleport>();
            
            if (session.curSceneNumId != req.SceneNumId)
            {
                session.EnterScene(req.SceneNumId, new Resource.ResourceManager.Vector3f(req.Position), new Resource.ResourceManager.Vector3f(req.Rotation));
                ScSceneTeleport t = new()
                {
                    TeleportReason = req.TeleportReason,
                    PassThroughData = req.PassThroughData,
                    Position = req.Position,
                    Rotation = req.Rotation,
                    SceneNumId = req.SceneNumId,
                };
                session.Send(ScMsgId.ScSceneTeleport, t);
            }
            else
            {
                uint unixTimestamp = (uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                var generator = new SnowflakeIdGenerator(machineId: 1);
                long id = generator.GenerateId();
                ScSceneTeleport t = new()
                {
                    TeleportReason = req.TeleportReason,
                    PassThroughData = req.PassThroughData,
                    Position = req.Position,
                    Rotation = req.Rotation,
                    SceneNumId = req.SceneNumId,
                    ServerTime = unixTimestamp,
                    TpUuid= (ulong)id
                };
                session.curSceneNumId = t.SceneNumId;
                session.position = new Vector3f(req.Position);
                session.rotation = new Vector3f(req.Rotation);
                session.sceneLoadState = Player.SceneLoadState.Loading;
                session.Send(ScMsgId.ScSceneTeleport, t);
            }
            
            

        }
       
    }
}
