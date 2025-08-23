using Campofinale.Game.Factory.Components;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Resource.Table
{
    [TableCfgType("TableCfg/FactoryMachineCraftTable.json", LoadPriority.LOW)]
    public class FactoryMachineCraftTable
    {
        public string id;
        public string machineId;
        public int progressRound;
        public long totalProgress;
        public int signal;
        public string formulaGroupId;
        public List<FactoryMachineCraftIngredient> ingredients = new();
        public List<FactoryMachineCraftIngredient> outcomes = new();

        public bool CacheHaveItems(FComponentCache inCache)
        {
            bool enough = true;
            ingredients.ForEach(i =>
            {
                i.group.ForEach(item =>
                {
                    if(inCache.GetItemCount(item.id) < item.count)
                    {
                        enough = false;
                        
                    }
                });
            });
            return enough;
        }

        internal List<ItemCount> GetIngredients()
        {
            List<ItemCount> items = new();
            ingredients.ForEach(i =>
            {
                i.group.ForEach(item =>
                {
                    items.Add(item);
                });
            });
            return items;
        }

        public class FactoryMachineCraftIngredient
        {
            public List<ItemCount> group = new();
        }
    }
}
