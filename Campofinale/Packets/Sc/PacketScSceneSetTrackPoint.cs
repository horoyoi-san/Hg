using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScSceneSetTrackPoint : Packet
    {

        public PacketScSceneSetTrackPoint(SceneTrackPoint trackPoint)
        {
            ScSceneSetTrackPoint proto = new()
            {
                TrackPoint = trackPoint
            };
            SetData(ScMsgId.ScSceneSetTrackPoint, proto);
        }
    }
}
