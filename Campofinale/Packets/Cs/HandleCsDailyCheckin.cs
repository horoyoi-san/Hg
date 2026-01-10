using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using StardustUtils;

namespace Campofinale.Packets.Cs
{
	public class HandleCsDailyCheckin
	{
		[Server.Handler(CsMsgId.CsDailyCheckin)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsDailyCheckin req = packet.DecodeBody<CsDailyCheckin>();

			if (!ResourceManager.activityTable.ContainsKey(req.Id))
			{
				Logger.PrintWarn($"Player {session.roleId} attempted checkin for unknown activity: {req.Id}");
				return;
			}

			var activityConfig = ResourceManager.activityTable[req.Id];
			if (activityConfig.type != ActivityType.Checkin)
			{
				Logger.PrintWarn($"Activity {req.Id} is not a checkin activity");
				return;
			}

			session.adventureBookManager.DoCheckin(req.Id);

			ScDailyCheckin response = new ScDailyCheckin()
			{
				Id = req.Id
			};

			session.Send(ScMsgId.ScDailyCheckin, response);
		}
	}
}
