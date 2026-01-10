using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
	public class PacketScGameMechanicsSyncEnterGameInst : Packet
	{
		public PacketScGameMechanicsSyncEnterGameInst(string gameId)
		{
			ScGameMechanicsSyncEnterGameInst enterGameInst = new()
			{
				GameId = gameId
			};

			SetData(ScMsgId.ScGameMechanicsSyncEnterGameInst, enterGameInst);
		}
	}
}
