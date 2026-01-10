using Campofinale.Game.Inventory;
using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using StardustUtils;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Sc
{
    public class PacketScItemBagScopeSync : Packet
    {
        public PacketScItemBagScopeSync(Player client, ItemValuableDepotType type)
        {
            ScItemBagScopeSync proto = new ScItemBagScopeSync()
            {
                Bag = new()
                {
                    GridLimit = client.inventoryManager.items.maxBagSize,
                    Grids = { }
                },
                FactoryDepot =
                {
                    {"domain_1", new ScdItemDepot() },
                    {"domain_2", new ScdItemDepot() }
                },
                ScopeName = 1,
                Depot = { },
            };

            // Clear factory depot and bag for non-Weapon depot types
            int i = (int)type;
            if (i > 1)
            {
                proto.FactoryDepot.Clear();
                proto.Bag = null;
            }
            proto.Depot.Add(i, new ScdItemDepot());

            // Populate bag items
            if (proto.Bag != null)
            {
                foreach (var item in client.inventoryManager.items.bag)
                {
                    try
                    {
                        ScdItemGrid itemGrid = item.Value.ToProto();
                        itemGrid.GridIndex = item.Key; // Set grid index
                        proto.Bag.Grids.Add(itemGrid);
                    }
                    catch (Exception ex)
                    {
                        Logger.PrintError($"[PacketScItemBagScopeSync] Error converting bag item {item.Value.id} to proto: {ex.Message}");
                    }
                }
            }

            // Populate depot items for the requested type
            List<Item> items = client.inventoryManager.items.items.FindAll(item => item.ItemType == (ItemValuableDepotType)i);
            foreach (var item in items)
            {
                try
                {
                    if (item.InstanceType())
                    {
                        // Instance type items go to InstList
                        ScdItemGrid itemGrid = item.ToProto();
                        proto.Depot[i].InstList.Add(itemGrid);
                    }
                    else
                    {
                        // Stackable items go to StackableItems map
                        if (proto.Depot[i].StackableItems.ContainsKey(item.id))
                        {
                            proto.Depot[i].StackableItems[item.id] += item.amount;
                        }
                        else
                        {
                            proto.Depot[i].StackableItems.Add(item.id, item.amount);
                        }
                    }
                }
                catch (Exception ex)
                {
                    Logger.PrintError($"[PacketScItemBagScopeSync] Error converting depot item {item.id} to proto: {ex.Message}");
                }
            }

            // Populate FactoryDepot (only when syncing Weapon depot)
            // FactoryDepot stores Factory-type items that are NOT in the bag (bag has 30 slot limit)
            if (proto.FactoryDepot.Count > 0)
            {
                List<Item> factoryItems = client.inventoryManager.items.items.FindAll(item =>
                {
                    ItemTable itemConfig = ResourceManager.GetItemTable(item.id);

                    // Must be Factory type in the original table (valuableTabType == Factory)
                    bool isFactoryType = itemConfig.valuableTabType == ItemValuableDepotType.Factory;

                    // Must not be in the bag
                    bool notInBag = !client.inventoryManager.items.bag.ContainsValue(item);

                    // Must NOT be a valuable item (equipment with domainId)
                    // Valuable items should go to ValuableDepot, not FactoryDepot
                    bool isNotValuable = true;
                    if (ResourceManager.equipTable.TryGetValue(item.id, out var equipEntry))
                    {
                        // If item has a domainId in EquipTable, it's a valuable item
                        isNotValuable = string.IsNullOrEmpty(equipEntry.domainId);
                    }

                    return isFactoryType && notInBag && isNotValuable;
                });

                foreach (Item factoryItem in factoryItems)
                {
                    try
                    {
                        // All factory items go to domain_1 (not domain_2 which is for valuables)
                        string targetDomain = "domain_1";

                        if (factoryItem.InstanceType())
                        {
                            ScdItemGrid itemGrid = factoryItem.ToProto();
                            proto.FactoryDepot[targetDomain].InstList.Add(itemGrid);
                        }
                        else
                        {
                            if (proto.FactoryDepot[targetDomain].StackableItems.ContainsKey(factoryItem.id))
                            {
                                proto.FactoryDepot[targetDomain].StackableItems[factoryItem.id] += factoryItem.amount;
                            }
                            else
                            {
                                proto.FactoryDepot[targetDomain].StackableItems.Add(factoryItem.id, factoryItem.amount);
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        Logger.PrintError($"[PacketScItemBagScopeSync] Error converting factory item {factoryItem.id} to proto: {ex.Message}");
                    }
                }
            }

            SetData(ScMsgId.ScItemBagScopeSync, proto);
        }
    }
}