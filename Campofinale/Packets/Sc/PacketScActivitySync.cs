using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using Campofinale.Resource.Table;
using System.Reflection.Metadata;

namespace Campofinale.Packets.Sc
{
    public class PacketScActivitySync : Packet
    {

        public PacketScActivitySync(Player client) {

            ScActivitySync proto = new ScActivitySync()
            {
                Info =
                {
                }
            };
            
            foreach (ActivityTable activity in ResourceManager.activityTable.Values)
            {
                ActivityInfo info = new ActivityInfo()
                {
                    IsEnable = true,
                    Id = activity.id,
                    StartTime = DateTime.UtcNow.ToUnixTimestampMilliseconds() / 1000,
                    EndTime = DateTime.UtcNow.AddDays(20).ToUnixTimestampMilliseconds() / 1000,
                    IsUnlocked = true,
                    Status = 2,
                    Typ = (int)activity.type,
                    Conditions = new(),
                    Data = new()
                    {

                    }
                };
                switch (activity.type)
                {
                    case ActivityType.Checkin:
                        info.Data.Checkin = new()
                        {
                            LoginDays = 1,

                        };
                        break;
                    case ActivityType.PhotoTaking:
                        info.Data.ConditionalMultiStage = new()
                        {
                            

                        };
                        break;
                    case ActivityType.NormalChallenge:
                        info.Data.GameEntrance = new()
                        {
                            

                        };
                        break;
                    case ActivityType.HighDifficultyChallenge:
                        info.Data.GameEntrance = new()
                        {


                        };
                        break;
                    default:
                        break;
                }
                proto.Info.Add(info);
            }
            SetData(ScMsgId.ScActivitySync, proto);
        }

    }
}
