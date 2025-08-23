using Campofinale.Resource;
using static Campofinale.Game.Factory.FactoryNode;

namespace Campofinale.Game.Factory.Components
{
    public class FComponentProducer : FComponent
    {
        public string formulaId = "";
        public string lastFormulaId = "";
        public bool inProduce, inBlock;
        public long progress;
        public FComponentProducer(uint id) : base(id, FCComponentType.Producer)
        {
            
        }

        public override void SetComponentInfo(ScdFacCom proto)
        {
            proto.Producer = new()
            {
               FormulaId=formulaId,
               InBlock=inBlock,
               CurrentProgress=progress,
               InProduce=inProduce,
               LastFormulaId=lastFormulaId
            };
        }
    }
}
