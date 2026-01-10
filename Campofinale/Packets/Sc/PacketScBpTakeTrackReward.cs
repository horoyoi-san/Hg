using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
	internal class PacketScBpTakeTrackReward : Packet
	{
		public PacketScBpTakeTrackReward(Player client, ScBpTakeTrackReward result)
		{
			SetData(ScMsgId.ScBpTakeTrackReward, result);
		}
	}
}

