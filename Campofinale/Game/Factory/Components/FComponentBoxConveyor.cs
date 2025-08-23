using Campofinale.Resource;
using static Campofinale.Game.Factory.FactoryNode;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentBoxConveyor : FComponent
    {
        public long lastPopTms = 0;
        public List<ItemCount> items = new();
        public FComponentBoxConveyor(uint id) : base(id, FCComponentType.BoxConveyor,FCComponentPos.BoxConveyor)
        {
            lastPopTms=DateTime.UtcNow.ToUnixTimestampMilliseconds();
        }

        public override void SetComponentInfo(ScdFacCom proto)
        {
            if (items == null)
            {
                items = new List<ItemCount>();
            }

            proto.BoxConveyor = new()
            {
                LastPopTms = lastPopTms,
                
            };

            items.ForEach(item =>
            {
                if(item!=null)    
                proto.BoxConveyor.Items.Add(item.ToFactoryItemProto());
            });

        }
    }
}
