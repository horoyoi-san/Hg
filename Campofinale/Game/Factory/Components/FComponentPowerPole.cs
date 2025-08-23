using Campofinale.Resource;
using static Campofinale.Game.Factory.FactoryNode;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentPowerPole : FComponent
    {
        public FComponentPowerPole(uint id) : base(id, FCComponentType.PowerPole)
        {
        }

        public override void SetComponentInfo(ScdFacCom proto)
        {
            proto.PowerPole = new();
        }
    }
}
