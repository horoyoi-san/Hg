using Campofinale.Network;
using Campofinale.Protocol;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Sc
{
    public class PacketScEnterSceneNotify : Packet
    {

        public PacketScEnterSceneNotify(Player client, int sceneNumId = 21, Vector3f pos=null, PassThroughData data=null) {


            ScEnterSceneNotify proto = new ScEnterSceneNotify()
            {
                Position = pos==null ? client.position.ToProto() : pos.ToProto(),
                PassThroughData= data,
                SceneId = client.sceneManager.GetSceneGuid(sceneNumId),
                RoleId = client.roleId,
                SceneNumId = sceneNumId,
                
            };
            
            SetData(ScMsgId.ScEnterSceneNotify, proto);
        }

    }
}
