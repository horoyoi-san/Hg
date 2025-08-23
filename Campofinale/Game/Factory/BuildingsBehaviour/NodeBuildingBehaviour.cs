using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Game.Factory.BuildingsBehaviour
{
    public class NodeBuildingBehaviour
    {
        public virtual void Update(FactoryChapter chapter, FactoryNode node)
        {

        }
        //Executed the first time when created a node that use the specific behaviour
        public virtual void Init(FactoryChapter chapter, FactoryNode node)
        {

        }
    }
}
