using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Packets.Sc;

namespace Campofinale.Packets.Cs
{
    public class HandleCsBpBuyOriginiumTrack
    {
        [Server.Handler(CsMsgId.CsBpBuyOriginiumTrack)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsBpBuyOriginiumTrack req = packet.DecodeBody<CsBpBuyOriginiumTrack>();

            bool success = session.battlePassManager.PurchaseOriginiumTrack();
            if (success)
            {
                var trackUpdate = new ScBpTrackMgrModify
                {
                    BpTrackMgr = session.battlePassManager.GetTrackMgrData()
                };
                session.Send(new PacketScBpTrackMgrModify(session, trackUpdate));
            }
        }
    }
}

