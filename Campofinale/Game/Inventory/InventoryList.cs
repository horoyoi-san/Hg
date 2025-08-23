using Campofinale.Database;
using Campofinale.Packets.Sc;

namespace Campofinale.Game.Inventory
{
    public class InventoryList
    {
        public List<Item> items = new();
        public Dictionary<int, Item> bag = new();
        public int maxBagSize = 30;

        public Player player;
        public InventoryList(Player player)
        {
            this.player = player;
        }
        public enum FindType
        {
            Items,
            FactoryDepots,
            Bag
        }
        public void UpdateInventoryPacket()
        {

        }
        public void UpdateBagInventoryPacket()
        {
            player.Send(new PacketScItemBagScopeSync(this.player,Resource.ItemValuableDepotType.Invalid));
            
        }
        private void AddToBagAvailableSlot(Item item)
        {
            for (int i = 0; i < maxBagSize; i++)
            {
                if (!bag.ContainsKey(i))
                {
                    bag.Add(i, item);
                    return;
                }
            }
        }
        ///
        ///<summary>Add a item directly to the bag if there is enough space or increment current stack value</summary>
        ///
        public bool AddToBag(Item item)
        {
            Item existOne = Find(i=>i.id == item.id && i.amount < item.GetItemTable().maxStackCount,FindType.Bag);
            if (existOne != null)
            {
                
                if(existOne.amount+item.amount > item.GetItemTable().maxStackCount)
                {
                    int max = existOne.GetItemTable().maxStackCount;
                    int toAddInNewSlotAmount = existOne.amount + item.amount - max;
                    item.amount = toAddInNewSlotAmount;
                    if (SlotAvailableInBag())
                    {
                        existOne.amount = max;
                        AddToBagAvailableSlot(item);
                        UpdateBagInventoryPacket();
                        return true;
                    }
                    else
                    {
                        return false;
                    }
                }
                else
                {
                    existOne.amount += item.amount;
                    UpdateBagInventoryPacket();
                    return true;
                }
            }
            else
            {
                if(bag.Count < maxBagSize)
                {
                    AddToBagAvailableSlot(item);
                    UpdateBagInventoryPacket();
                    return true;
                }
                else
                {
                    return false;
                }
            }
        }
        public bool SlotAvailableInBag()
        {
            bool availableSlot = false;
            for (int i = 0; i < maxBagSize; i++)
            {
                if (!bag.ContainsKey(i))
                {
                    return true;
                }
            }
            return availableSlot;
        }
        public Item FindInAll(Predicate<Item> match)
        {
            var item = items.Find(match);
            if (item != null)
            {
                return item;
            }
            var itemB = bag.Values.ToList().Find(match);
            if (itemB != null)
            {
                return itemB;
            }
            return null;
        }
        public Item Find(Predicate<Item> match,FindType findType = FindType.Items)
        {
            switch (findType)
            {
                case FindType.Items:
                    var item = items.Find(match);
                    if (item != null)
                    {
                        return item;
                    }
                    break;
                case FindType.FactoryDepots:
                    //TODO
                    break;
                case FindType.Bag:
                    var itemB = bag.Values.ToList().Find(match);
                    if (itemB != null)
                    {
                        return itemB;
                    }
                    break;
            }
            
            return null;
        }
        public List<Item> FindAll(Predicate<Item> match, FindType findType = FindType.Items)
        {
            switch (findType)
            {
                case FindType.Items:
                    return items.FindAll(match);
                    break;
                case FindType.FactoryDepots:
                    //TODO
                    break;
                case FindType.Bag:
                    var itemB = bag.Values.ToList().FindAll(match);
                    if (itemB != null)
                    {
                        return itemB;
                    }
                    break;
            }

            return null;
        }
        ///<summary>
        ///Add an item to the inventory (or increment it's amount if it's not an instance type, else add a new one or add to bag if it's a Factory item
        ///</summary>
        public Item Add(Item item)
        {
            if (item.StorageSpace() == Resource.ItemStorageSpace.BagAndFactoryDepot)
            {
                AddToBag(item);
                return null;
            }
            if (item.InstanceType())
            {
                items.Add(item);
                DatabaseManager.db.UpsertItem(item);
                return item;
            }
            else
            {
                Item exist=Find(i=>i.id==item.id);
                if (exist != null)
                {
                    exist.amount += item.amount;
                    DatabaseManager.db.UpsertItem(exist);
                    return exist;
                }
                else
                {
                    items.Add(item);
                    DatabaseManager.db.UpsertItem(item);
                    return item;
                }
            }

        }
        /// <summary>
        /// Get the item amount from all depots
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public int GetItemAmount(string id)
        {
            int amt = 0;
            Item item=Find(i=>i.id==id);
            if (item != null)
            {
                amt += item.amount;
            }
            List<Item> bagItems = FindAll(i=>i.id==id,FindType.Bag);
            foreach (Item bagItem in bagItems)
            {
                amt += bagItem.amount;
            }
            
            return amt;
        }
        public void Remove(Item item)
        {
            if (items.Remove(item))
            {
                this.player.Send(new PacketScItemBagScopeModify(this.player, item));
                DatabaseManager.db.DeleteItem(item);
            }
            else if (RemoveFromBag(item))
            {
                UpdateBagInventoryPacket();
            }
        }

        private bool RemoveFromBag(Item item)
        {
            for (int i = 0; i < maxBagSize; i++)
            {
                Item bagItem = null;
                if (bag.ContainsKey(i))
                {
                    bagItem = bag[i];
                    if (bagItem.guid == item.guid)
                    {
                        bag.Remove(i);
                        return true;
                    }
                }
            }
            return false;
        }
        /// <summary>
        /// Move item from bag grid to another position
        /// </summary>
        /// <param name="fromGrid"></param>
        /// <param name="toGrid"></param>
        public void MoveBagItem(int fromGrid, int toGrid)
        {
            Item item1 = bag[fromGrid];
            Item item2 = null;
            if (bag.ContainsKey(toGrid))
            {
                item2 = bag[toGrid];
            }
            bag[toGrid] = item1;
            if (item2 != null)
            {
                bag[fromGrid] = item2;
            }
            else
            {
                bag.Remove(fromGrid);
            }
            UpdateBagInventoryPacket();
        }
    }
}
