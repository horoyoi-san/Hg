using Campofinale.Resource;
using static Campofinale.Game.Factory.FactoryNode;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentPowerSave : FComponent
    {
        public FComponentPowerSave(uint id) : base(id, FCComponentType.PowerSave)
        {
        }

        public override void SetComponentInfo(ScdFacCom proto)
        {
            proto.PowerSave = new()
            {
                PowerSave=100000
            };
        }
    }
}
