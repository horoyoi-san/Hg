using Campofinale.Database;
using Campofinale.Resource;
using Campofinale.Resource.Table;

namespace Campofinale.Game.Spaceship
{
    public class SpaceshipManager
    {
        public Player owner;
        public List<SpaceshipChar> chars=new();
        public List<SpaceshipRoom> rooms = new();
        public SpaceshipManager(Player o)
        {
            owner = o;
        }
        public SpaceshipChar GetChar(string id)
        {
            return chars.Find(c => c.id == id);
        }
        public void AddNewCharacter(string id)
        {
            if (id.Contains("endmin")) return;
            SpaceshipChar chara = new(owner.roleId, id);
            chars.Add(chara);
        }
        public void Load()
        {
            chars = DatabaseManager.db.LoadSpaceshipChars(owner.roleId);
            rooms = DatabaseManager.db.LoadSpaceshipRooms(owner.roleId);
            foreach (var chara in owner.chars)
            {
                SpaceshipChar c = GetChar(chara.id);
                if (c == null && !chara.id.Contains("endmin"))
                {
                    AddNewCharacter(chara.id);
                }
            }
            if(rooms.Count < 1)
            {
                rooms.Add(new SpaceshipRoom(owner.roleId,"control_center"));
            }
        }

        public void Save()
        {
            foreach(SpaceshipChar spaceshipChar in chars)
            {
                DatabaseManager.db.UpsertSpaceshipChar(spaceshipChar);
            }
            foreach(SpaceshipRoom room in rooms)
            {
                DatabaseManager.db.UpsertSpaceshipRoom(room);
            }
        }

        public void UpdateStationedChars()
        {
            Dictionary<string, string> charAndRoom = new();
            foreach(SpaceshipRoom room in rooms)
            {
                foreach (var c in room.stationedCharList)
                {
                    charAndRoom.Add(c, room.id);
                }
            }
            foreach(SpaceshipChar chara in chars)
            {
                if (charAndRoom.ContainsKey(chara.id))
                {
                    chara.stationedRoomId = charAndRoom[chara.id];
                }
                else
                {
                    chara.stationedRoomId = "";
                }
            }
        }

        public void GiftToChar(CsSpaceshipPresentGiftToChar req)
        {
            SpaceshipChar chara = GetChar(req.CharId);
            if (chara != null)
            {
                foreach (var item in req.Gifts)
                {
                    GiftItemTable giftItem = ResourceManager.giftItemTable[item.Id];
                    chara.favorability += giftItem.favorablePoint * item.Count;
                    //TODO item consume
                }
                ScSpaceshipPresentGiftToChar confirm = new()
                {
                    CurFav = chara.favorability,
                    CharId = chara.id,
                    RecvGiftCnt = req.Gifts.Count,
                };
                //TODO packet class
                /*ScSpaceshipCharFavorabilityChange change = new()
                {
                    ChangeInfos =
                    {
                        new SpaceshipCharFavorabilityChangeInfo()
                        {
                            CharId = chara.id,
                            CurFav=chara.favorability,
                        }
                    }
                };*/
                owner.Send(Protocol.ScMsgId.ScSpaceshipPresentGiftToChar, confirm);
            }
        }
    }
    
    
}
