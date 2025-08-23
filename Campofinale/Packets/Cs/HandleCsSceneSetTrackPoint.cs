using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneSetTrackPoint
    {

        [Server.Handler(CsMsgId.CsSceneSetTrackPoint)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneSetTrackPoint req = packet.DecodeBody<CsSceneSetTrackPoint>();

            session.Send(new PacketScSceneSetTrackPoint(req.TrackPoint));
        }
    }
}
