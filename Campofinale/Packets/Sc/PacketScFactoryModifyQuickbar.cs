using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
	public class PacketScFactoryModifyQuickbar : Packet
	{

		public PacketScFactoryModifyQuickbar(Player client, int scopeName, List<ScdFactorySyncQuickbar> quickbars, string chapterId)
		{
			ScFactoryModifyQuickbar proto = new ScFactoryModifyQuickbar();
			proto.ScopeName = scopeName;
			proto.Quickbars.AddRange(quickbars);
			proto.ChapterId = chapterId;

			SetData(ScMsgId.ScFactoryModifyQuickbar, proto);
		}
	}
}
