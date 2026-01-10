using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
	public class HandleCsTakeAdventureBookStageReward
	{

		[Server.Handler(CsMsgId.CsTakeAdventureBookStageReward)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsTakeAdventureBookStageReward req = packet.DecodeBody<CsTakeAdventureBookStageReward>();
			session.adventureBookManager.ClaimStageReward(req.AdventureBookStage);
			session.Send(new PacketScAdventureBookSync(session), packet.csHead.UpSeqid);
		}

	}
}
