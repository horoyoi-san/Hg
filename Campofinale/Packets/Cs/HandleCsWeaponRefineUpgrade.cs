using Campofinale.Game.Inventory;
using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
	/// <summary>
	/// Handler for weapon refinement upgrade requests.
	/// Consumes cost weapons and upgrades the refinement level of the target weapon.
	/// </summary>
	public class HandleCsWeaponRefineUpgrade
	{
		[Server.Handler(CsMsgId.CsWeaponRefineUpgrade)]
		public static void Handle(Player session, CsMsgId cmdId, Packet packet)
		{
			CsWeaponRefineUpgrade req = packet.DecodeBody<CsWeaponRefineUpgrade>();

			// Find the target weapon
			Item? targetWeapon = session.inventoryManager.items.Find(c => c.guid == req.Weaponid);
			if (targetWeapon == null)
			{
				// Weapon not found, silently fail (similar to other handlers)
				return;
			}

			// Verify all cost weapons exist and collect them for consumption
			List<Item> costWeaponsToRemove = new List<Item>();
			foreach (ulong costWeaponGuid in req.CostWeaponIds)
			{
				// Don't allow consuming the target weapon itself
				if (costWeaponGuid == req.Weaponid)
				{
					return;
				}

				Item? costWeapon = session.inventoryManager.items.Find(c => c.guid == costWeaponGuid);
				if (costWeapon == null)
				{
					// Cost weapon not found, silently fail
					return;
				}

				costWeaponsToRemove.Add(costWeapon);
			}

			// Consume all cost weapons
			foreach (Item costWeapon in costWeaponsToRemove)
			{
				session.inventoryManager.items.Remove(costWeapon);
			}

			// Update refinement level
			targetWeapon.refineLv = req.UpgradeRefineLv;

			// Save weapon to database
			Database.DatabaseManager.db.UpsertItem(targetWeapon);

			// Send response
			ScWeaponRefineUpgrade res = new()
			{
				Weaponid = req.Weaponid,
				RefineLv = targetWeapon.refineLv
			};
			session.Send(ScMsgId.ScWeaponRefineUpgrade, res, packet.csHead.UpSeqid);

			// Send inventory sync packets
			session.Send(new PacketScItemBagScopeModify(session, targetWeapon));
			session.Send(new PacketScSyncCharBagInfo(session));
		}
	}
}
