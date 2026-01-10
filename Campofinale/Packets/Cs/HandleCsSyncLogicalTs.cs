using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
	public class HandleCsSyncLogicalTs
	{
		[Server.Handler(CsMsgId.CsSyncLogicalTs)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			// nothing here.
		}
	}
}

