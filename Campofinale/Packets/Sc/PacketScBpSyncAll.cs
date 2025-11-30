using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScBpSyncAll : Packet
    {

        public PacketScBpSyncAll(Player client) {

            ScBpSyncAll proto = new ScBpSyncAll()
            {
                LevelData = new()
                {
                    CurExp=0,
                    CurLevel=1
                },
                BpTaskMgr=new(),
                BpTrackMgr = new()
                {
                    TrackData =
                    {
                        new ScdBpTrackRewardData()
                        {
                            BpTrackId="bp_track_free",
                            
                        },
                        /*new ScdBpTrackRewardData()
                        {
                            BpTrackId="bp_track_originium",

                        },
                        new ScdBpTrackRewardData()
                        {
                            BpTrackId="bp_track_pay",
                            
                        }*/
                    }
                },
                SeasonData = new()
                {
                    SeasonId= "bp_01",
                    CloseTime=DateTime.UtcNow.AddDays(10).ToUnixTimestampMilliseconds(),
                    CloseStatus = new()
                    {

                    },
                    
                }
            };

            SetData(ScMsgId.ScBpSyncAll, proto);
        }

    }
}
