using Campofinale.Protocol;
using Campofinale.Network;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneSetLastRecordCampid
    {
        [Server.Handler(CsMsgId.CsSceneSetLastRecordCampid)]
        public static void Handler(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneSetLastRecordCampid req = packet.DecodeBody<CsSceneSetLastRecordCampid>();
            if (session == null)
            {
                return;
            }

            if (session?.savedSaveZone == null)
            {
                session.savedSaveZone = new PlayerSafeZoneInfo();
            }

            // Update the saved safe zone with the camp information
            // This will be used by repatriate logic to teleport the player back
            session.savedSaveZone.sceneNumId = req.SceneNumId;
            session.savedSaveZone.position = new Vector3f(req.Position);
            session.savedSaveZone.rotation = new Vector3f(req.Rotation);

            ScSceneSetLastRecordCampid rsp = new ScSceneSetLastRecordCampid()
            {
                LastCampId = req.LastCampId,
                SceneNumId = req.SceneNumId,
            };

            session.Send(ScMsgId.ScSceneSetLastRecordCampid, rsp);
        }
    }
}