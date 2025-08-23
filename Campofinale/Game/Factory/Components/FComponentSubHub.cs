using Campofinale.Resource;
using static Campofinale.Game.Factory.FactoryNode;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentSubHub : FComponent
    {
        public int level = 1;
        public FComponentSubHub(uint id) : base(id, FCComponentType.SubHub)
        {
        }

        public override void SetComponentInfo(ScdFacCom proto)
        {
            proto.SubHub = new()
            {
                Level = level,
            };
        }
    }
}
