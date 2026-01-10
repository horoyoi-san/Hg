namespace Campofinale.Resource.Table
{
	/// <summary>
	/// Factory Grid related tables.
	/// </summary>
	[TableCfgType("TableCfg/FactoryGridBeltTable.json", LoadPriority.LOW)]
	public class FactoryGridBeltTable
	{
		public BeltData beltData;
		public string id;

		public class BeltData
		{
			public string buildCamState;
			public string iconOnPanel;
			public string itemId;
			public int msPerRound;
			public FactoryTableCommonTypes.NameData name;
		}

		public FCNodeType GetNodeType()
		{
			// Factory grid belts are conveyor belts for item transport
			// Map to BoxConveyor type as they are basic conveyor components
			return FCNodeType.BoxConveyor;
		}
	}

	[TableCfgType("TableCfg/FactoryGridRouterTable.json", LoadPriority.LOW)]
	public class FactoryGridRouterTable
	{
		public FactoryTableCommonTypes.GridUnitData gridUnitData;
		public string id;
		public FactoryTableCommonTypes.PortData[] inputPorts;
		public FactoryTableCommonTypes.PortData[] outputPorts;
		public FactoryTableCommonTypes.RangeData range;

		public FCNodeType GetNodeType()
		{
			// Factory grid routers are logistics splitters/mergers
			// Map to BoxRouterM1 type as they function as routing nodes in the logistics grid
			return FCNodeType.BoxRouterM1;
		}
	}

	[TableCfgType("TableCfg/FactoryGridConnecterTable.json", LoadPriority.LOW)]
	public class FactoryGridConnecterTable
	{
		public FactoryTableCommonTypes.GridUnitData gridUnitData;
		public string id;
		public FactoryTableCommonTypes.PortData[] inputPorts;
		public FactoryTableCommonTypes.PortData[] outputPorts;
		public FactoryTableCommonTypes.RangeData range;

		public FCNodeType GetNodeType()
		{
			// Factory grid connectors are logistics routers with multiple input/output ports
			// Map to BoxRouterM1 type as they function as routing nodes in the logistics grid
			return FCNodeType.BoxRouterM1;
		}
	}
}
