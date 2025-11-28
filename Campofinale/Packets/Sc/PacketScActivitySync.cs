using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScActivitySync : Packet
    {

        public PacketScActivitySync(Player client) {

            ScActivitySync proto = new ScActivitySync()
            {
                Info =
                {
                    /*new ActivityInfo()
                    {
                        IsEnable = true,
                        Id="activity_checkin_1",
                        StartTime=DateTime.UtcNow.ToUnixTimestampMilliseconds(),
                        EndTime=DateTime.UtcNow.AddDays(20).ToUnixTimestampMilliseconds(),
                        Data = new()
                        {
                            Checkin = new()
                            {
                                LoginDays=1,
                                RewardDays={1,1,2,3,4,5,6,7,8,9,10,11,12,13,14},
                                
                            }
                        }
                    },*/
                    new ActivityInfo()
                    {
                        
                        IsEnable = true,
                        Id="CharacterGuide_wolfgd",
                        StartTime=DateTime.UtcNow.ToUnixTimestampMilliseconds(),
                        EndTime=DateTime.UtcNow.AddDays(20).ToUnixTimestampMilliseconds(),
                        Data = new()
                        {
                            CharTrial = new()
                            {
                                
                            }
                        }
                    }
                }
                
            };

            SetData(ScMsgId.ScActivitySync, proto);
        }

    }
}
