using Campofinale.Database;
using Campofinale.Packets.Sc;
using Google.Protobuf.Collections;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Inventory
{
    public class InventoryManager
    {
        public Player owner;
        public InventoryList items;

        public int item_diamond_amt
        {
            get
            {
                if (items.Find(i => i.id == "item_diamond") == null) return 0;
                return items.Find(i => i.id == "item_diamond")!.amount;
            }
        }
        public int item_gold_amt
        {
            get
            {
                if (items.Find(i => i.id == "item_gold") == null) return 0;
                return items.Find(i => i.id == "item_gold")!.amount;
            }
        }

        public Item GetItemById(string id)
        {
            return items.FindInAll(i => i.id == id);
        }
        public InventoryManager(Player o) {

            owner = o;
            items=new(o);
        }
        public void AddRewards(string rewardTemplateId, Vector3f pos, int sourceType=1)
        {
            try
            {
                ScRewardToastBegin begin = new ScRewardToastBegin()
                {
                    RewardSourceType = sourceType,
                    RewardToastInstId = owner.random.NextRand(),

                };
                ScRewardToSceneBegin begin2 = new ScRewardToSceneBegin()
                {
                    RewardSourceType = sourceType,
                    SourceTemplateId = rewardTemplateId,
                };
                ScRewardToastEnd end = new()
                {
                    RewardToastInstId = begin.RewardToastInstId,

                };
                List<RewardTable.ItemBundle> bundles = rewardTable[rewardTemplateId].itemBundles;
                foreach(RewardTable.ItemBundle bundle in bundles)
                {
                    Item item = new Item()
                    {
                        id=bundle.id
                    };
                    if(bundle.id == "item_daily_activation")
                    {
                        owner.adventureBookManager.data.dailyActivation += bundle.count;
                        continue;
                    }
                    if (!item.InstanceType() || sourceType == 0)
                    {
                        item = AddItem(bundle.id, bundle.count);
                        end.RewardVirtualList.Add(new RewardItem()
                        {
                            Count = bundle.count,
                            Id = bundle.id,
                            Inst=item.ToProto().Inst,
                        });

                    }
                    else
                    {
                        owner.sceneManager.CreateDrop(pos, bundle);
                        //TODO drops
                    }
                }
                owner.Send(Protocol.ScMsgId.ScRewardToastBegin, begin);
                owner.Send(Protocol.ScMsgId.ScRewardToSceneBegin, begin2);
                

                owner.Send(Protocol.ScMsgId.ScRewardToastEnd, end);
                owner.Send(Protocol.ScMsgId.ScRewardToSceneEnd, new ScRewardToSceneEnd());
                owner.Send(new PacketScSyncWallet(owner));
            }
            catch (Exception e)
            {
                Logger.PrintError(e.Message);
            }
            
        }
        public Item AddWeapon(string id, ulong level)
        {
            Item item = new Item(owner.roleId, id, level);
            items.Add(item);
            return item;
        }
        public void Save()
        {
            foreach (Item item in items.items)
            {
                DatabaseManager.db.UpsertItem(item);
            }
        }
        public void Load()
        {
           items.items = DatabaseManager.db.LoadInventoryItems(owner.roleId);
        }
        public Item AddItem(string id, int amt, bool notify=false)
        {
            Item item = new Item(owner.roleId, id, amt);
           
            Item itemNew = items.Add(item);
            if (notify && itemNew != null)
            {
                this.owner.Send(new PacketScItemBagScopeModify(this.owner, itemNew));
            }
            return item;
        }
        public void RemoveItem(Item item,int amt)
        {
            item.amount -= amt;
            if(item.amount <= 0)
            {
                items.Remove(item);
            }
            else
            {
                this.owner.Send(new PacketScItemBagScopeModify(this.owner, item));
                items.UpdateBagInventoryPacket();
            }
        }
        
        public bool ConsumeItem(string id, int amt)
        {
            Item item=items.FindInAll(i=>i.id== id);
            if (item != null)
            {
                if(item.amount >= amt)
                {
                    item.amount -= amt;
                    
                    if(item.amount < 1)
                    {
                        items.Remove(item);
                    }
                    else
                    {
                        this.owner.Send(new PacketScItemBagScopeModify(this.owner, item));
                        items.UpdateBagInventoryPacket();
                    }
                    return true;
                }
                else
                {
                    int toConsume = amt - item.amount;
                    item.amount = 0;
                    items.Remove(item);
                    return ConsumeItem(id, toConsume);
                }
            }
            else
            {
                return false;
            }
        }
        public bool ConsumeItems(MapField<string, ulong> costItemId2Count)
        {
            RepeatedField<ItemInfo> items = new RepeatedField<ItemInfo>();
            foreach (var item in costItemId2Count)
            {
                items.Add(new ItemInfo()
                {
                    ResCount=(int)item.Value,
                    ResId=item.Key,
                });
            }
            return ConsumeItems(items);
        }
        public bool ConsumeItems(RepeatedField<ItemInfo> items)
        {
            bool found = true;
            foreach (ItemInfo item in items)
            {
                int amount = this.items.GetItemAmount(item.ResId);
                if(amount < item.ResCount)
                {
                    found = false;
                    break;
                }
            }
            foreach (ItemInfo item in items)
            {
                ConsumeItem(item.ResId, item.ResCount);
            }
            return found;
        }

        public Dictionary<uint, int> GetInventoryChapter(string chapterId)
        {
            Dictionary<uint, int> dir= new Dictionary<uint, int>();
            /*List<Item> citems = items.FindAll(i=>!i.InstanceType());
            foreach (Item item in citems)
            {
                dir.Add((uint)ResourceManager.strIdNumTable.item_id.dic[item.id], item.amount);
            }*/

            return dir;
        }

        public void DropItemsBag(CsItemBagAbandonInBag req)
        {
           if(req.TargetObjectId == 0)
           {
                foreach (var i in req.GridCut)
                {
                    Item item = items.bag[i.Key];
                    item.amount -= i.Value;
                    if(item.amount <= 0)
                    {
                        items.bag.Remove(i.Key);
                    }
                    owner.sceneManager.CreateDrop(owner.position, new RewardTable.ItemBundle()
                    {
                        count=i.Value,
                        id=item.id,
                    });
                    
                }
                
           }
            items.UpdateBagInventoryPacket();
        }
    }
}
