using Campofinale.Game.Factory.Components;
using Campofinale.Protocol;
using Campofinale.Resource;
using Campofinale.Resource.Table;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Campofinale.Resource;
using static Campofinale.Resource.ResourceManager;
using System.Xml.Linq;

namespace Campofinale.Game.Factory.BuildingsBehaviour
{
    public class NodeBuilding_ProducerFurnace : NodeBuildingBehaviour
    {
        public uint inputCacheId = 0;
        public uint outputCacheId = 0;
        public uint inputCacheIdFluid = 0;
        public uint outputCacheIdFluid = 0;
        public uint producerId = 0;
        public long timestampFinish = 0;
        public override void Init(FactoryChapter chapter, FactoryNode node)
        {
            FComponentCache cache1 = (FComponentCache)new FComponentCache(chapter.nextCompV(), FCComponentPos.CacheIn1).Init();
            FComponentCache cache2 = (FComponentCache)new FComponentCache(chapter.nextCompV(), FCComponentPos.CacheOut1).Init();
            FComponentCache cache3 = (FComponentCache)new FComponentCache(chapter.nextCompV(), FCComponentPos.CacheFluidIn1).Init();
            FComponentCache cache4 = (FComponentCache)new FComponentCache(chapter.nextCompV(), FCComponentPos.CacheFluidOut1).Init();
            FComponentProducer producer = (FComponentProducer)new FComponentProducer(chapter.nextCompV()).Init();
            node.components.Add(producer);
            node.components.Add(new FComponentFormulaMan(chapter.nextCompV()).Init());
            node.components.Add(cache1);
            node.components.Add(cache2);
            node.components.Add(cache3);
            node.components.Add(cache4);
            inputCacheId = cache1.compId;
            outputCacheId = cache2.compId;
            inputCacheIdFluid = cache3.compId;
            outputCacheIdFluid = cache4.compId;
            producerId = producer.compId;
            node.components.Add(new FComponentPortManager(chapter.nextCompV(), 4, cache1).Init());
            node.components.Add(new FComponentPortManager(chapter.nextCompV(), 4, cache2).Init());
        }
        public string GetFormulaGroupId(string templateId)
        {
            FactoryMachineCraftTable table = factoryMachineCraftTable.Values.ToList().Find(r => r.machineId == templateId);
            if (table != null)
            {
                return table.formulaGroupId;
            }
            else
            {
                return "";
            }
        }
        public override void Update(FactoryChapter chapter, FactoryNode node)
        {
           
            if (node.powered)
            {
                FComponentProducer producer = node.GetComponent<FComponentProducer>(producerId);
                FComponentCache inCache = node.GetComponent<FComponentCache>(inputCacheId);
                FComponentCache outCache = node.GetComponent<FComponentCache>(outputCacheId);
                FComponentFormulaMan formulaManager = node.GetComponent<FComponentFormulaMan>();

                if (formulaManager == null) return;
                formulaManager.currentGroup = GetFormulaGroupId(node.templateId);
                FactoryMachineCraftTable craftingRecipe = null;
                string recipe = ResourceManager.FindFactoryMachineCraftIdUsingCacheItems(inCache.items,formulaManager.currentGroup);
                producer.formulaId = recipe;
                ResourceManager.factoryMachineCraftTable.TryGetValue(producer.formulaId, out craftingRecipe);

                if (craftingRecipe != null)
                {
                    producer.inBlock = outCache.IsFull();
                    if (craftingRecipe.CacheHaveItems(inCache) && !outCache.IsFull())
                    {
                        producer.inProduce = true;
                        
                        producer.lastFormulaId = recipe;
                        if (timestampFinish == 0)
                        {
                            timestampFinish = DateTime.UtcNow.ToUnixTimestampMilliseconds() + 1000 * craftingRecipe.progressRound;
                        }
                        producer.progress = (DateTime.UtcNow.ToUnixTimestampMilliseconds() / timestampFinish) * craftingRecipe.totalProgress;
                        if (DateTime.UtcNow.ToUnixTimestampMilliseconds() >= timestampFinish)
                        {
                            timestampFinish = DateTime.UtcNow.ToUnixTimestampMilliseconds() + 1000 * craftingRecipe.progressRound;
                            List<ItemCount> toConsume = craftingRecipe.GetIngredients();
                            inCache.ConsumeItems(toConsume);
                            craftingRecipe.outcomes.ForEach(e =>
                            {
                                e.group.ForEach(i =>
                                {
                                    outCache.AddItem(i.id, i.count);
                                });

                            });
                        }
                    }
                    else
                    {
                        producer.inProduce = false;
                        producer.progress = 0;
                        timestampFinish = 0;
                    }
                }
                else
                {
                    producer.inBlock = false;
                    producer.inProduce = false;
                    producer.progress = 0;
                    timestampFinish = 0;
                }
            }
          
        }
    }
}
