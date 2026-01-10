using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using System.Linq;

namespace Campofinale.Packets.Cs
{
	public class HandleCsFactoryQuickbarSetOne
	{

		[Server.Handler(CsMsgId.CsFactoryQuickbarSetOne)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsFactoryQuickbarSetOne req = packet.DecodeBody<CsFactoryQuickbarSetOne>();

			string chapterId = !string.IsNullOrEmpty(req.ChapterId) ? req.ChapterId : session.GetCurrentChapter();
			var chapter = session.factoryManager.GetChapter(chapterId);
			if (chapter != null)
			{
				chapter.SetQuickbarOne(req.ScopeName, req.Type, req.Index, req.ItemId);
				session.factoryManager.Save();
				var quickbarList = chapter.BuildQuickbars();
				session.Send(new PacketScFactoryModifyQuickbar(session, req.ScopeName, quickbarList, chapterId), packet.csHead.UpSeqid);
			}
		}
	}
}
