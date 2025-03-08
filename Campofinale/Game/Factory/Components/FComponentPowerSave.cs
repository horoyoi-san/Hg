using Campofinale.Resource;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
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
