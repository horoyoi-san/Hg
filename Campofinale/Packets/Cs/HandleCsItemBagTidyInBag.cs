using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
	public class HandleCsItemBagTidyInBag
	{
		[Server.Handler(CsMsgId.CsItemBagTidyInBag)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsItemBagTidyInBag req = packet.DecodeBody<CsItemBagTidyInBag>();

			// Tidy up the specified scope of the bag
			// scope_name indicates which inventory section to tidy (e.g., main inventory, factory depot, etc.)
			session.inventoryManager.TidyBag(req.ScopeName);

			session.Send(ScMsgId.ScItemBagCommonSync, new ScItemBagCommonSync());
		}
	}
}
