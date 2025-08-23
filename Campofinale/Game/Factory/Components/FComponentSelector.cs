using Campofinale.Resource;
using static Campofinale.Game.Factory.FactoryNode;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentSelector : FComponent
    {
        public string selectedItemId = "";
        public FComponentSelector(uint id) : base(id, FCComponentType.Selector)
        {
        }

        public override void SetComponentInfo(ScdFacCom proto)
        {
            proto.Selector = new()
            {
                SelectedItemId= selectedItemId
            };
        }
    }
}
