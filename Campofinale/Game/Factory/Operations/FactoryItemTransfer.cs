using Campofinale.Game.Factory.Components;
using Campofinale.Game.Inventory;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Factory
{
    /// <summary>
    /// Handles item transfer between bag and cache
    /// </summary>
    public class FactoryItemTransfer
    {
        private readonly FactoryChapter chapter;

        public FactoryItemTransfer(FactoryChapter chapter)
        {
            this.chapter = chapter;
        }

        /// <summary>
        /// Move item from cache to bag
        /// </summary>
        public void MoveItemCacheToBag(CsFactoryOp op, ulong seq)
        {
            var move = op.MoveItemCacheToBag;
            FComponentCache cacheComp = chapter.GetCompById<FComponentCache>(move.ComponentId);
            if (cacheComp != null)
            {
                ItemCount cacheItem = cacheComp.items[move.CacheGridIndex];
                Item gridItem = null;
                chapter.GetOwner().inventoryManager.items.bag.TryGetValue(move.GridIndex, out gridItem);
                if (gridItem == null)
                {
                    chapter.GetOwner().inventoryManager.items.bag.Add(move.GridIndex, new Item(chapter.ownerId, cacheItem.id, cacheItem.count));
                    cacheItem.id = "";
                    cacheItem.count = 0;

                }
                else
                {
                    if (gridItem.id == cacheItem.id)
                    {
                        int availableSpace = 50 - gridItem.amount;
                        if (cacheItem.count > availableSpace)
                        {
                            gridItem.amount += availableSpace;
                            cacheItem.count -= availableSpace;
                        }
                        else
                        {
                            gridItem.amount += cacheItem.count;
                            cacheItem.id = "";
                            cacheItem.count = 0;
                        }
                    }
                    else
                    {
                        //TODO Swap
                    }

                }
            }
            chapter.GetOwner().inventoryManager.items.UpdateBagInventoryPacket();
            chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), 0, op), seq);
        }

        /// <summary>
        /// Move item from bag to cache
        /// </summary>
        public void MoveItemBagToCache(CsFactoryOp op, ulong seq)
        {
            var move = op.MoveItemBagToCache;
            FComponentCache cacheComp = chapter.GetCompById<FComponentCache>(move.ComponentId);
            if (cacheComp != null)
            {
                Item gridItem = null;
                chapter.GetOwner().inventoryManager.items.bag.TryGetValue(move.GridIndex, out gridItem);
                if (gridItem != null)
                {
                    if (cacheComp.items[move.CacheGridIndex].id == "" || cacheComp.items[move.CacheGridIndex].id == gridItem.id)
                    {
                        int canAdd = 50 - cacheComp.items[move.CacheGridIndex].count;

                        if (canAdd >= gridItem.amount)
                        {
                            cacheComp.items[move.CacheGridIndex].id = gridItem.id;
                            cacheComp.items[move.CacheGridIndex].count += gridItem.amount;
                            chapter.GetOwner().inventoryManager.items.bag.Remove(move.GridIndex);
                            chapter.GetOwner().inventoryManager.items.UpdateBagInventoryPacket();
                        }
                        else
                        {
                            cacheComp.items[move.CacheGridIndex].id = gridItem.id;
                            cacheComp.items[move.CacheGridIndex].count += canAdd;
                            gridItem.amount -= canAdd;
                            chapter.GetOwner().inventoryManager.items.UpdateBagInventoryPacket();
                        }
                    }
                }

            }
            chapter.GetOwner().Send(new PacketScFactoryOpRet(chapter.GetOwner(), 0, op), seq);
        }
    }
}

