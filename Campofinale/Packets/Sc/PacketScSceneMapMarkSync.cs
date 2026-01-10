using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
	public class PacketScSceneMapMarkSync : Packet
	{
		public PacketScSceneMapMarkSync(Player client)
		{
			ScSceneMapMarkSync proto = client.mapMarkManager.ToProto();
			SetData(ScMsgId.ScSceneMapMarkSync, proto);
		}
	}
}

