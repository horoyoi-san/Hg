using Campofinale.Game.Gacha;
using Campofinale.Network;
using Campofinale.Protocol;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Sc
{
    public class PacketScGachaSync : Packet
    {

        public PacketScGachaSync(Player client) {

            ScGachaSync proto = new ScGachaSync()
            {
                CharGachaPool = new()
                {
                    GachaPoolInfos =
                    {

                    },
                    GachaPoolRoleDatas =
                    {

                    },
                    GachaPoolCategoryRoleDatas =
                    {
                        
                    }
                },
                WeaponGachaPool = new()
                {
                    
                },
                
            };
            foreach(var item in gachaWeaponPoolTable)
            {
                (int fiveStarPity, int sixStarPity, GachaTransaction? lastSixStar, bool isFiftyFiftyLost)
                PityInfo = client.gachaManager.GetCurrentPity(item.Value.type);
                ScdGachaPoolInfo wPool = new ScdGachaPoolInfo()
                {
                    GachaPoolId = item.Value.id,
                    IsClosed = false,
                    CloseTime = DateTime.UtcNow.AddDays(20).ToUnixTimestampMilliseconds() / 1000,
                    OpenTime = DateTime.UtcNow.ToUnixTimestampMilliseconds() / 1000,
                    PublicCloseReason = 0,


                };
                
                proto.WeaponGachaPool.GachaPoolInfos.Add(wPool);
                proto.WeaponGachaPool.GachaPoolRoleDatas.Add(new ScdGachaPoolRoleData()
                {
                    GachaPoolId = item.Value.id,
                    IsClosed = false,
                    PersonalCloseReason = 0,
                    SoftGuaranteeProgress = PityInfo.sixStarPity,
                    TotalPullCount = PityInfo.sixStarPity,
                    Star5SoftGuaranteeProgress = PityInfo.fiveStarPity,
                    HardGuaranteeProgress = PityInfo.sixStarPity,

                });
                proto.WeaponGachaPool.GachaPoolCategoryRoleDatas.Add(new ScdGachaPoolCategoryRoleData()
                {
                    GachaPoolType = item.Value.type,
                    TotalPullCount = PityInfo.sixStarPity,
                    Star5SoftGuaranteeProgress = PityInfo.fiveStarPity,
                    SoftGuaranteeProgress = PityInfo.sixStarPity,

                });

            }
            //TODO: Implement banner config for opentime etc
            foreach (var item in gachaCharPoolTable)
            {
                (int fiveStarPity, int sixStarPity, GachaTransaction? lastSixStar, bool isFiftyFiftyLost)
                PityInfo = client.gachaManager.GetCurrentPity(item.Value.type);
                proto.CharGachaPool.GachaPoolInfos.Add(new ScdGachaPoolInfo()
                {
                    GachaPoolId = item.Value.id,
                    IsClosed=false,
                    CloseTime= DateTime.UtcNow.AddDays(20).ToUnixTimestampMilliseconds()/1000,
                    OpenTime= DateTime.UtcNow.ToUnixTimestampMilliseconds() / 1000,
                    PublicCloseReason=0,
                    
                    
                });
                proto.CharGachaPool.GachaPoolRoleDatas.Add(new ScdGachaPoolRoleData()
                {
                    GachaPoolId=item.Value.id,
                    IsClosed=false,
                    PersonalCloseReason=0,
                    SoftGuaranteeProgress=PityInfo.sixStarPity,
                    TotalPullCount = PityInfo.sixStarPity,
                    Star5SoftGuaranteeProgress = PityInfo.fiveStarPity,
                    HardGuaranteeProgress = PityInfo.sixStarPity,
                    
                });
                proto.CharGachaPool.GachaPoolCategoryRoleDatas.Add(new ScdGachaPoolCategoryRoleData()
                {
                    GachaPoolType=item.Value.type,
                    TotalPullCount = PityInfo.sixStarPity,
                    Star5SoftGuaranteeProgress = PityInfo.fiveStarPity,
                    SoftGuaranteeProgress = PityInfo.sixStarPity,
                    
                });
            }

            SetData(ScMsgId.ScGachaSync, proto);
        }

    }
}
