using Campofinale.Resource;


namespace Campofinale.Game.Factory.Components
{
    public class FComponentFormulaMan : FComponent
    {
        public string currentGroup = "group_grinder_normal";
        public string currentMode = "normal";
        public List<string> formulaIds = new();
        public FComponentFormulaMan(uint id) : base(id, FCComponentType.FormulaMan)
        {
        }
        public List<string> GetFormulaIds()
        {
            List<string> ids = ResourceManager.factoryMachineCraftTable.Where(i => i.Value.formulaGroupId == currentGroup).Select(i => i.Value.id).ToList();
            return ids;
        }
        public override void SetComponentInfo(ScdFacCom proto)
        {
            formulaIds = GetFormulaIds();
            proto.FormulaMan = new()
            {
                CurrentGroup = currentGroup,
                CurrentMode = currentMode,
                FormulaIds = {
                    formulaIds
                }
            };
        }
    }
}
