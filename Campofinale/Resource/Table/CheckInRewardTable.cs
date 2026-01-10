using Campofinale.Resource.Json;

namespace Campofinale.Resource.Table
{
	[TableCfgType("TableCfg/CheckInRewardTable.json", LoadPriority.LOW)]
	public class CheckInRewardTable : TableCfgResource
	{
		public List<CheckInStage> stageList = new();

		public class CheckInStage
		{
			public string activityId;
			public string charId;
			public int day;
			public bool isKeyReward;
			public bool isPopup;
			public string rewardId;
			public string rewardImg;
			public RewardName rewardName;
			public string weaponId;

			public class RewardName
			{
				public long id;
				public string text;
			}
		}
	}
}
