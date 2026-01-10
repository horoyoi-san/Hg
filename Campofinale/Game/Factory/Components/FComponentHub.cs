using Campofinale.Resource;
using static Campofinale.Game.Factory.FactoryNode;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentHub : FComponent
    {
        public FComponentHub(uint id) : base(id, FCComponentType.Hub)
        {
        }

        public override void SetComponentInfo(ScdFacCom proto)
        {
           
        }
    }
}
