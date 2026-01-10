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

            if (req?.TrackPoint != null)
            {
                session.mapMarkManager.SetTrackPoint(req.TrackPoint);
                session.Send(new PacketScSceneSetTrackPoint(req.TrackPoint));
                session.mapMarkManager.Save();
            }
        }
    }
}
