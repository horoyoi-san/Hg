using Campofinale.Resource;
using static Campofinale.Game.Factory.FactoryNode;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentStablePower : FComponent
    {
        public FComponentStablePower(uint id) : base(id, FCComponentType.StablePower)
        {
        }

        public override void SetComponentInfo(ScdFacCom proto)
        {
            proto.StablePower = new()
            {
                PowerGenPerSec=150
            };
        }
    }
}
