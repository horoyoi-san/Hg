using Campofinale.Resource;
using static Campofinale.Game.Factory.FactoryNode;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentCache : FComponent
    {

        public List<ItemCount> items = new();
        public FComponentCache(uint id,FCComponentPos pos) : base(id, FCComponentType.Cache,pos)
        {
        }
        public int GetItemCount(string id)
        {
            int count = 0;
            ItemCount item = items.Find(i=>i.id == id);
            if (item != null)
            {
                count += item.count;
            }
            return count;
        }
        public override void SetComponentInfo(ScdFacCom proto)
        {
            if(items.Count < 1)
            {
                //Add 1 empty item as default
                items.Add(new ItemCount());
            }
            proto.Cache = new()
            {
                Items =
                {
                },
                Size=items.Count,
                
            };
            items.ForEach(item =>
            {
                proto.Cache.Items.Add(item.ToFactoryItemProto());
            });
        }

        public void ConsumeItems(List<ItemCount> toConsume)
        {
            foreach (var consume in toConsume)
            {
                ItemCount item = items.Find(i => i.id == consume.id);
                if (item != null)
                {
                    item.count-=consume.count;
                    if(item.count < 1)
                    {
                        item.count = 0;
                        item.id = "";
                    }
                }
            }
        }

        public bool IsFull()
        {
            int maxItems = items.Count * 50;
            int count = 0;
            foreach (var item in items)
            {
                count += item.count;
            };
            return count>=maxItems;
        }

        public void AddItem(string id, int count)
        {
            int remaining = count;
            foreach (var item in items)
            {
                int space = 50-item.count;
                if (item.id==id)
                {
                    if (space >= remaining)
                    {
                        item.count +=remaining;
                        remaining = 0;
                    }
                    else
                    {
                        item.count += space;
                        remaining -= space;
                    }
                }
                else if(item.id.Length < 1)
                {
                    item.id = id;
                    item.count = remaining;
                }
            }
        }
    }
}
