using Campofinale.Network;
using Campofinale.Protocol;
using System.Collections.Generic;
using System.Linq;

namespace Campofinale.Packets.Cs
{
	public class HandleCsSceneStaticMapMarkUpdate
	{
		[Server.Handler(CsMsgId.CsSceneStaticMapMarkUpdate)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsSceneStaticMapMarkUpdate req = packet.DecodeBody<CsSceneStaticMapMarkUpdate>();
			if (session == null)
			{
				return;
			}

			// Static map marks: only store indices, actual data loaded from config table
			var indices = session.mapMarkManager.discoveredStaticMarkIndices;
			List<SceneStaticMapMark> added = new();
			List<int> deleted = new();

			foreach (var op in req.Ops)
			{
				if (op.Mark == null)
				{
					continue;
				}

				int index = op.Mark.Index;
				if (op.IsAdd)
				{
					// Add index if not already present
					if (!indices.Contains(index))
					{
						indices.Add(index);
						added.Add(new SceneStaticMapMark { Index = index });
					}
				}
				else
				{
					// Remove index
					if (indices.Remove(index))
					{
						deleted.Add(index);
					}
				}
			}

			if (added.Count > 0 || deleted.Count > 0)
			{
				ScSceneStaticMapMarkModify rsp = new()
				{
					AddedList = { added },
					DeletedList = { deleted }
				};
				session.Send(ScMsgId.ScSceneStaticMapMarkModify, rsp);

				session.mapMarkManager.Save();
			}
		}
	}
}

