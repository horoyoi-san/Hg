using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Game.Spaceship;
using Campofinale.Database;

namespace Campofinale.Packets.Cs
{
	public class HandleCsSpaceshipBuildRoom
	{
		[Server.Handler(CsMsgId.CsSpaceshipBuildRoom)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsSpaceshipBuildRoom req = packet.DecodeBody<CsSpaceshipBuildRoom>();

			SpaceshipRoom? existingRoom = session.spaceshipManager.rooms.Find(r => r.id == req.RoomId);
			if (existingRoom != null)
			{
				ScSpaceshipModifyRoom response = new ScSpaceshipModifyRoom
				{
					Rooms = { existingRoom.ToRoomProto() }
				};
				session.Send(ScMsgId.ScSpaceshipModifyRoom, response);
				return;
			}

			// Create new room
			SpaceshipRoom newRoom = new SpaceshipRoom(session.roleId, req.RoomId);
			session.spaceshipManager.rooms.Add(newRoom);

			DatabaseManager.db.UpsertSpaceshipRoom(newRoom);

			ScSpaceshipModifyRoom modifyResponse = new ScSpaceshipModifyRoom
			{
				Rooms = { newRoom.ToRoomProto() }
			};
			session.Send(ScMsgId.ScSpaceshipModifyRoom, modifyResponse);
		}
	}
}

