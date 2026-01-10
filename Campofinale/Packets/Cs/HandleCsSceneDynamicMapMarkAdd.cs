using Campofinale.Network;
using Campofinale.Protocol;
using System.Linq;

namespace Campofinale.Packets.Cs
{
	/// <summary>
	/// Handles CsSceneDynamicMapMarkAdd which is sent when the player adds a dynamic map mark.
	/// Dynamic map marks are player-created custom marks on the map with position, note, and type.
	/// </summary>
	public class HandleCsSceneDynamicMapMarkAdd
	{
		[Server.Handler(CsMsgId.CsSceneDynamicMapMarkAdd)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsSceneDynamicMapMarkAdd req = packet.DecodeBody<CsSceneDynamicMapMarkAdd>();
			if (session == null || req == null)
			{
				return;
			}

			// Generate a unique ID for the new mark
			// Find the max ID for this scene and increment
			uint newId = 1;
			var existingMarks = session.mapMarkManager.sceneDynamicMapMarkList
				.Where(m => m.SceneNumId == req.SceneNumId)
				.ToList();
			if (existingMarks.Count > 0)
			{
				newId = existingMarks.Max(m => m.Id) + 1;
			}

			// Create the dynamic map mark
			SceneDynamicMapMark mark = new SceneDynamicMapMark
			{
				Id = newId,
				SceneNumId = req.SceneNumId,
				Pos = req.Position,
				Note = req.Note ?? "",
				Typ = req.Typ,
				TierIndex = req.TierIndex,
				TierId = req.TierId
			};

			// Add to manager
			session.mapMarkManager.AddDynamicMapMark(mark);

			// Send modify response
			ScSceneDynamicMapMarkModify rsp = new ScSceneDynamicMapMarkModify
			{
				ModifiedMarks = { mark }
			};
			session.Send(ScMsgId.ScSceneDynamicMapMarkModify, rsp);

			// Save to database
			session.mapMarkManager.Save();
		}
	}
}
