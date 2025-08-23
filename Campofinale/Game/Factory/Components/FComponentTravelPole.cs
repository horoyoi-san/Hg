using Campofinale.Resource;
using static Campofinale.Game.Factory.FactoryNode;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentTravelPole : FComponent
    {
        public uint defaultNext;
        public FComponentTravelPole(uint id) : base(id, FCComponentType.TravelPole)
        {
        }

        public override void SetComponentInfo(ScdFacCom proto)
        {
            proto.TravelPole = new()
            {
                DefaultNext = defaultNext
            };
        }
    }
}
