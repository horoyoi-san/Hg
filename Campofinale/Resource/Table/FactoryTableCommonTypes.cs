namespace Campofinale.Resource.Table
{
	/// <summary>
	/// Shared data structures for factory grid and liquid tables.
	/// </summary>
	public static class FactoryTableCommonTypes
	{
		/// <summary>
		/// Port data with position and rotation.
		/// </summary>
		public class PortData
		{
			public Vector3Data position;
			public Vector3Data rotation;
		}

		/// <summary>
		/// 3D vector data (position or rotation).
		/// </summary>
		public class Vector3Data
		{
			public float x;
			public float y;
			public float z;
		}

		/// <summary>
		/// Range data for factory nodes.
		/// </summary>
		public class RangeData
		{
			public int x;
			public int y;
			public int z;
		}

		/// <summary>
		/// Name data with ID and text.
		/// </summary>
		public class NameData
		{
			public string id;
			public string text;
		}

		/// <summary>
		/// Grid unit data for grid-based factory nodes.
		/// </summary>
		public class GridUnitData
		{
			public string buildCamState;
			public string iconOnPanel;
			public string itemId;
			public int msPerRound;
			public NameData name;
		}

		/// <summary>
		/// Liquid unit data for liquid-based factory nodes.
		/// </summary>
		public class LiquidUnitData
		{
			public string buildCamState;
			public string iconOnPanel;
			public string itemId;
			public int msPerRound;
			public NameData name;
			public int volume;
		}
	}
}
