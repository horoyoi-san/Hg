namespace Campofinale.Resource.Table
{
	/// <summary>
	/// Factory Liquid and Fluid related tables.
	/// </summary>
	[TableCfgType("TableCfg/FactoryLiquidRouterTable.json", LoadPriority.LOW)]
	public class FactoryLiquidRouterTable
	{
		public string id;
		public FactoryTableCommonTypes.PortData[] inputPorts;
		public FactoryTableCommonTypes.LiquidUnitData liquidUnitData;
		public FactoryTableCommonTypes.PortData[] outputPorts;
		public FactoryTableCommonTypes.RangeData range;

		public FCNodeType GetNodeType()
		{
			// Factory liquid routers are fluid splitters/mergers
			// Map to FluidRouterM1 type as they function as routing nodes in the liquid logistics grid
			return FCNodeType.FluidRouterM1;
		}
	}

	[TableCfgType("TableCfg/FactoryLiquidPipeTable.json", LoadPriority.LOW)]
	public class FactoryLiquidPipeTable
	{
		public string id;
		public PipeData pipeData;

		public class PipeData
		{
			public string buildCamState;
			public string iconOnPanel;
			public string itemId;
			public int msPerRound;
			public FactoryTableCommonTypes.NameData name;
			public int volume;
		}

		public FCNodeType GetNodeType()
		{
			// Factory liquid pipes are basic fluid transport components
			// Map to FluidConveyor type as they are fundamental liquid transport elements
			return FCNodeType.FluidConveyor;
		}
	}

	[TableCfgType("TableCfg/FactoryLiquidConnectorTable.json", LoadPriority.LOW)]
	public class FactoryLiquidConnectorTable
	{
		public string id;
		public FactoryTableCommonTypes.PortData[] inputPorts;
		public FactoryTableCommonTypes.LiquidUnitData liquidUnitData;
		public FactoryTableCommonTypes.PortData[] outputPorts;
		public FactoryTableCommonTypes.RangeData range;

		public FCNodeType GetNodeType()
		{
			// Factory liquid connectors are liquid logistics connectors
			// Map to FluidConveyor type as they are basic liquid transport components
			return FCNodeType.FluidConveyor;
		}
	}

	[TableCfgType("TableCfg/FactoryLiquidRepeaterTable.json", LoadPriority.LOW)]
	public class FactoryLiquidRepeaterTable
	{
		public string id;
		public FactoryTableCommonTypes.PortData[] inputPorts;
		public FactoryTableCommonTypes.LiquidUnitData liquidUnitData;
		public FactoryTableCommonTypes.PortData[] outputPorts;
		public FactoryTableCommonTypes.RangeData range;

		public FCNodeType GetNodeType()
		{
			// Factory liquid repeaters are liquid signal repeaters
			// Map to FluidRepeater type as they extend liquid transport range
			return FCNodeType.FluidRepeater;
		}
	}
}
