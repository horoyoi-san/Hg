using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using Campofinale.Packets.Sc;
using StardustUtils;

namespace Campofinale.Packets.Cs
{
	public class HandleCsGameMechanicsReqStart
	{
		[Server.Handler(CsMsgId.CsGameMechanicsReqStart)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsGameMechanicsReqStart req = packet.DecodeBody<CsGameMechanicsReqStart>();

			// Validate game_id exists in gameMechanicTable
			if (!ResourceManager.gameMechanicTable.ContainsKey(req.GameId))
			{
				Logger.PrintWarn($"Player {session.roleId} attempted to start unknown game mechanics: {req.GameId}");
				return;
			}

			session.Send(new PacketScGameMechanicsSyncEnterGameInst(req.GameId));
		}
	}
}
