using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
	internal class PacketScBpTrackMgrModify : Packet
	{
		public PacketScBpTrackMgrModify(Player client, ScBpTrackMgrModify result)
		{
			SetData(ScMsgId.ScBpTrackMgrModify, result);
		}
	}
}

