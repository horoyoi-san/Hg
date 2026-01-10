using Campofinale.Network;
using Campofinale.Protocol;
using StardustUtils;

namespace Campofinale.Packets.Cs
{
	public class HandleCsItemBagSetBatchMoveFlag
	{
		[Server.Handler(CsMsgId.CsItemBagSetBatchMoveFlag)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			// do nothing here.
			Logger.Print($"[HandleCsItemBagSetBatchMoveFlag] Player {session.accountId} received batch move flag packet (Id: {(int)cmdId})");
		}
	}
}
