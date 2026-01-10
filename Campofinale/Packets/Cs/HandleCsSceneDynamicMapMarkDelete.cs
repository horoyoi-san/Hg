using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
	/// <summary>
	/// Handles CsSceneDynamicMapMarkDelete which is sent when the player deletes dynamic map marks.
	/// </summary>
	public class HandleCsSceneDynamicMapMarkDelete
	{
		[Server.Handler(CsMsgId.CsSceneDynamicMapMarkDelete)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsSceneDynamicMapMarkDelete req = packet.DecodeBody<CsSceneDynamicMapMarkDelete>();
			if (session == null || req == null || req.Id.Count == 0)
			{
				return;
			}

			// Remove marks from manager
			session.mapMarkManager.RemoveDynamicMapMarks(req.SceneNumId, req.Id.ToList());

			// Send modify response
			ScSceneDynamicMapMarkModify rsp = new ScSceneDynamicMapMarkModify
			{
				DeletedMarks = { req.Id }
			};
			session.Send(ScMsgId.ScSceneDynamicMapMarkModify, rsp);

			// Save to database
			session.mapMarkManager.Save();
		}
	}
}

