using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using System.Linq;

namespace Campofinale.Packets.Cs
{
	public class HandleCsFactoryQuickbarMoveOne
	{

		[Server.Handler(CsMsgId.CsFactoryQuickbarMoveOne)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsFactoryQuickbarMoveOne req = packet.DecodeBody<CsFactoryQuickbarMoveOne>();

			// Use chapter_id from request, or fallback to current chapter
			string chapterId = !string.IsNullOrEmpty(req.ChapterId) ? req.ChapterId : session.GetCurrentChapter();
			var chapter = session.factoryManager.GetChapter(chapterId);
			if (chapter != null)
			{
				chapter.MoveQuickbarOne(req.ScopeName, req.Type, req.FromIndex, req.ToIndex);
				session.factoryManager.Save();
				var quickbarList = chapter.BuildQuickbars();
				session.Send(new PacketScFactoryModifyQuickbar(session, req.ScopeName, quickbarList, chapterId), packet.csHead.UpSeqid);
			}
		}
	}
}
