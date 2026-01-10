using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Bson;
using static Campofinale.Resource.ResourceManager;
using Campofinale.Resource;
using MongoDB.Bson.Serialization.IdGenerators;

namespace Campofinale.Game.Spaceship
{
    public class SpaceshipRoom
    {
        [BsonId(IdGenerator = typeof(ObjectIdGenerator))]
        public ObjectId _id { get; set; }
        public string id = "";
        public int level = 1;
        public List<string> stationedCharList = new();
        public ulong owner;
        public SpaceshipRoom()
        {

        }
        public SpaceshipRoom(ulong owner, string id)
        {
            this.owner = owner;
            this.id = id;
        }
        public bool HasCharWorking()
        {
            Player? owner = GetOwner();
            if (owner == null) return false;

            foreach (string chara in stationedCharList)
            {
                SpaceshipChar? ch = owner.spaceshipManager.GetChar(chara);
                if (ch != null)
                {
                    if (ch.isWorking)
                    {
                        return true;
                    }
                }
            }
            return false;
        }
        public int GetRoomType()
        {
            if (ResourceManager.spaceshipRoomInsTable.TryGetValue(id, out var roomInfo))
            {
                return roomInfo.roomType;
            }
            // Default to ControlCenter
            return 0;
        }
        public Player? GetOwner()
        {
            return Server.clients.Find(c => c.roleId == owner);
        }

        public ScdSpaceshipRoom ToRoomProto()
        {
            // Get room info from resource table
            int roomType = 0;
            int serialNum = 0;

            if (ResourceManager.spaceshipRoomInsTable.TryGetValue(id, out var roomInfo))
            {
                roomType = roomInfo.roomType;
                // Use sortId as serialNum if available, otherwise use 0
                serialNum = roomInfo.sortId;
            }
            else
            {
                roomType = GetRoomType();
            }

            ScdSpaceshipRoom room = new()
            {
                Id = id,
                Level = level,
                Type = roomType,
                SerialNum = serialNum,
                HasCharWorking = HasCharWorking(),
                StationedCharList =
                {
                    stationedCharList
                },
                LevelUpConditionFlags =
                {
                    { id+"_level_"+(level+1),true}
                },
                LevelUpConditonValues =
                {
                    { id+"_level_"+(level+1),4}
                },
                AttrsMap =
                        {
                            {0, new ScdSpaceshipRoomAttr()
                            {
                                Value=24.8f,
                                TheoreticalValue=24.8f,
                                BaseAttrs =
                                {
                                    new ScdSpaceshipRoomAttrUnit()
                                    {
                                        Value=20,

                                        Source = new()
                                        {
                                            SourceType=1,
                                        }
                                    }
                                },
                                PercentAttrs =
                                {
                                    new ScdSpaceshipRoomAttrUnit()
                                    {
                                        Value=0.24f,
                                        Source = new()
                                        {
                                            CharId="chr_0004_pelica",
                                            SkillId="spaceship_skill_acc_all_ps_recovery1_2"
                                        }
                                    }
                                }
                            } },
                            {1, new ScdSpaceshipRoomAttr()
                            {
                                Value=12,
                                TheoreticalValue=12,
                                BaseAttrs =
                                {
                                    new ScdSpaceshipRoomAttrUnit()
                                    {
                                        Type=1,
                                        Value=12,
                                        Source = new()
                                        {
                                            SourceType=1
                                        }
                                    }
                                }
                            }
                            }
                        },
            };

            // Set room_data based on room type
            switch (roomType)
            {
                case 0: // ControlCenter
                    room.ControlCenter = new ScdSpaceshipControlCenter
                    {
                    };
                    break;
                case 1: // ManufacturingStation
                    room.ManufacturingStation = new ScdSpaceshipManufacturingStation
                    {
                    };
                    break;
                case 2: // GrowCabin
                    room.GrowCabin = new ScdSpaceshipGrowCabin
                    {
                    };
                    break;
            }
            return room;
        }
    }
}
