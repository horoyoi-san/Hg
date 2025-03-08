using Campofinale.Resource;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
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
