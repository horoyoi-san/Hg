using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
	/// <summary>
	/// Handles CsSceneDynamicMapMarkUpdate which is sent when the player updates a dynamic map mark's note or type.
	/// </summary>
	public class HandleCsSceneDynamicMapMarkUpdate
	{
		[Server.Handler(CsMsgId.CsSceneDynamicMapMarkUpdate)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsSceneDynamicMapMarkUpdate req = packet.DecodeBody<CsSceneDynamicMapMarkUpdate>();
			if (session == null || req == null)
			{
				return;
			}

			// Update mark in manager
			session.mapMarkManager.UpdateDynamicMapMark(req.SceneNumId, req.Id, req.Note ?? "", req.Typ);

			// Find the updated mark to send back
			var updatedMark = session.mapMarkManager.sceneDynamicMapMarkList
				.FirstOrDefault(m => m.SceneNumId == req.SceneNumId && m.Id == req.Id);

			if (updatedMark != null)
			{
				// Send modify response
				ScSceneDynamicMapMarkModify rsp = new ScSceneDynamicMapMarkModify
				{
					ModifiedMarks = { updatedMark }
				};
				session.Send(ScMsgId.ScSceneDynamicMapMarkModify, rsp);

				// Save to database
				session.mapMarkManager.Save();
			}
		}
	}
}

