using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Resource.Json
{
    [TableCfgType("Data/Conditions.json", LoadPriority.LOW)]
    public class ConditionData
    {
        public List<string> args = new();


        public string Get(int index)
        {
            return args[index];
        }
        public int ToInt(int index)
        {
            return int.Parse(args[index]);
        }
    }
}
