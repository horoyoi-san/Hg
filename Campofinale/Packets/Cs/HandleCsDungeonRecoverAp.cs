using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Cs
{
	public class HandleCsDungeonRecoverAp
	{
		[Server.Handler(CsMsgId.CsDungeonRecoverAp)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsDungeonRecoverAp req = packet.DecodeBody<CsDungeonRecoverAp>();
			if (session == null)
			{
				return;
			}

			uint totalRecoverAmount = 0;

			if (req.Items != null && req.Items.Count > 0)
			{
				foreach (var item in req.Items)
				{
					if (recoverApItemTable.TryGetValue(item.Id, out var recoverApItem))
					{
						totalRecoverAmount += (uint)(recoverApItem.apRecoverValue * item.Count);
					}
				}
			}

			if (req.UseMoney && dungeonConstTable != null)
			{
				totalRecoverAmount += (uint)dungeonConstTable.apRecoverValueByMoney;
			}

			if (totalRecoverAmount > 0)
			{
				session.AddStamina(totalRecoverAmount);
			}
		}
	}
}

