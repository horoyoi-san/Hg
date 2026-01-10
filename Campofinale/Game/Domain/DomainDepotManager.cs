using Campofinale.Resource;
using Campofinale.Resource.Table;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Domain
{
    /// <summary>
    /// Manager for Domain Depot operations
    /// Handles unlocking and managing domain depots
    /// </summary>
    public class DomainDepotManager
    {
        public Player player;

        public DomainDepotManager(Player player)
        {
            this.player = player;
        }

        /// <summary>
        /// Convert domain depot string ID to numeric ID using strIdNumTable
        /// Returns 0 if conversion fails
        /// </summary>
        public int GetDomainDepotNumId(string domainDepotId)
        {
            if (strIdNumTable?.domain_depot_id?.dic != null &&
                strIdNumTable.domain_depot_id.dic.TryGetValue(domainDepotId, out int numId))
            {
                return numId;
            }

            // If mapping doesn't exist, log warning and return 0
            StardustUtils.Logger.PrintWarn($"[DomainDepotManager] Domain depot ID mapping not found for: {domainDepotId}");
            return 0;
        }

        /// <summary>
        /// Unlock a domain depot by string ID
        /// Converts string ID to numeric ID and adds to bitset
        /// </summary>
        public bool UnlockDomainDepot(string domainDepotId)
        {
            int numId = GetDomainDepotNumId(domainDepotId);
            if (numId == 0)
            {
                return false;
            }

            // Add to bitset
            player.bitsetManager.AddValue(BitsetType.UnlockDomainDepot, numId);
            return true;
        }
    }
}

