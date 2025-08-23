using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSpaceshipStationChar
    {

        [Server.Handler(CsMsgId.CsSpaceshipStationChar)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSpaceshipStationChar req = packet.DecodeBody<CsSpaceshipStationChar>();
            session.spaceshipManager.rooms.Find(r=>r.id==req.RoomId).stationedCharList=req.StationedCharList.ToList();
            session.spaceshipManager.UpdateStationedChars();
            session.Send(new PacketScSpaceshipSyncRoomStation(session, session.spaceshipManager.rooms.Find(r => r.id == req.RoomId)));
            //Logger.Print("Server: " + curtimestamp + " client: " + req.ClientTs);
        }
       
    }
}
