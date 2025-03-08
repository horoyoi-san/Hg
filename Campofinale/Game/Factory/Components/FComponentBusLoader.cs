using Campofinale.Resource;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static Campofinale.Game.Factory.FactoryNode;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentBusLoader : FComponent
    {
        public string lastPutinItemId = "";
        public FComponentBusLoader(uint id) : base(id, FCComponentType.BusLoader)
        {
        }

        public override void SetComponentInfo(ScdFacCom proto)
        {
            proto.BusLoader = new()
            {
                LastPutinItemId= lastPutinItemId
            };
        }
    }
}
