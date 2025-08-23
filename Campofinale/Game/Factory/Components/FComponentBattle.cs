using Campofinale.Resource;
using static Campofinale.Game.Factory.FactoryNode;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentBattle : FComponent
    {
        public int EnergyCurrent=100;
        public FComponentBattle(uint id) : base(id, FCComponentType.Battle, FCComponentPos.Battle1)
        {
        }

        public override void SetComponentInfo(ScdFacCom proto)
        {
            proto.Battle = new()
            {
                EnergyCurrent=100,
                EnergyMax=100,
                InOverloading=false
            };
        }
    }
}
