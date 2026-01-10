using Campofinale.Network;
using Campofinale.Protocol;
using Google.Protobuf;
using System.Net.Sockets;
using Campofinale.Packets.Sc;
using Campofinale.Game.Char;
using Campofinale.Resource;
using Campofinale.Game.Inventory;
using static Campofinale.Resource.ResourceManager;
using Campofinale.Database;
using Campofinale.Game;
using Campofinale.Game.Gacha;
using Campofinale.Game.Spaceship;
using Campofinale.Game.Dungeons;
using Campofinale.Game.Factory;
using Campofinale.Game.MissionSys;
using System.Drawing;
using Campofinale.Game.Adventure;
using static Campofinale.Player;
using StardustUtils;
using Campofinale.Game.BP;
using Campofinale.Game.MapMarks;
using Campofinale.Game.Domain;
using Campofinale.Resource.Table;
namespace Campofinale
{
    public class GuidRandomizer
    {
        public ulong v = 1;
        public List<ulong> usedGuids = new();
        public Random random = new();
        public Player player;
        public GuidRandomizer(Player p)
        {
            this.player = p;
        }
        public ulong Next()
        {
            if (v + 1 >= IdConst.LogicIdSegment)
            {
                v = IdConst.MaxLogicIdBound + 1;
            }
            v++;
            return (ulong)v;
        }

        public ulong NextRand()
        {
            var maxGuid = IdConst.MaxLogicIdBound + 1;

            ulong val = (ulong)random.NextInt64((long)maxGuid, (long)IdConst.MaxRuntimeClientId);

            if (val <= v)
            {
                return NextRand();
            }
            if (player.sceneManager.GetCurScene() != null)
                if (player.sceneManager.GetCurScene().entities.Find(e => e.guid == val) != null)
                {
                    return NextRand();
                }
            if (usedGuids.Contains(val))
            {
                return NextRand();
            }
            else
            {
                usedGuids.Add(val);
                return val;
            }
        }
    }
    public class PlayerSafeZoneInfo
    {
        public int sceneNumId;
        public Vector3f position;
        public Vector3f rotation;
    }

    public class PlayerPersonalData
    {
        public string signature = "Campofinale!!";
        public int userAvatarId = 3;
        public int userAvatarFrameId = 8;
        public int businessCardTopicId = 9;
        public bool businessCardExpandFlag = false;
        public List<ulong> charList = [0];
    }

    public class Player
    {
        public List<string> temporanyChatMessages = new(); //for cbt2 only as no chat exist
        public GuidRandomizer random;
        public Thread receivorThread;
        public Socket socket;
        //Data
        public string accountId = "";
        public string nickname = "Endministrator";
        public ulong roleId = 1;
        public Gender gender = Gender.GenFemale;
        public uint level = 20;
        public uint xp = 0;
        public uint worldLevel = 7;
        public uint unlockWorldLevel = 7;
        public long lastSetWorldLevelTs = 0;
        public Vector3f position;
        public Vector3f rotation;
        public Vector3f safeZonePoint; //Don't need to be saved
        public int curSceneNumId;
        public List<Character> chars = new List<Character>();
        public InventoryManager inventoryManager;
        public SpaceshipManager spaceshipManager;
        public SceneManager sceneManager;
        public GachaManager gachaManager;
        public BitsetManager bitsetManager;
        public FactoryManager factoryManager;
        public MissionSystem missionSystem;
        public AdventureBookManager adventureBookManager;
        public BattlePassManager battlePassManager;
        public MapMarkManager mapMarkManager;
        public DomainDepotManager domainDepotManager;
        public int teamIndex = 0;
        public List<Team> teams = new List<Team>();
        public List<Mail> mails = new List<Mail>();
        public List<int> unlockedSystems = new();
        public List<ulong> noSpawnAnymore = new();
        public long maxDashEnergy = 250;
        public uint curStamina = 10;
        public long nextRecoverTime = 0;
        public long nextDailyReset = 0;
        public Dungeon currentDungeon;
        public PlayerSafeZoneInfo savedSaveZone;
        public PlayerPersonalData personalData = new();
        public byte[] clientSetting = new byte[0];
        public uint maxStamina
        {
            get
            {
                return (uint)200;
            }
        }
        public bool Initialized = false;

        public Player(Socket socket)
        {
            this.random = new(this);
            this.socket = socket;
            roleId = (ulong)new Random().Next();
            bitsetManager = new(this);
            inventoryManager = new(this);
            sceneManager = new(this);
            gachaManager = new(this);
            spaceshipManager = new(this);
            factoryManager = new(this);
            missionSystem = new(this);
            adventureBookManager = new(this);
            battlePassManager = new(this);
            mapMarkManager = new(this);
            domainDepotManager = new(this);
            receivorThread = new Thread(new ThreadStart(Receive));

        }
        public List<Character> GetCurTeam()
        {
            return chars.FindAll(c => teams[teamIndex].members.Contains(c.guid));
        }
        public bool Load(string accountId)
        {
            this.accountId = accountId;
            PlayerData data = DatabaseManager.db.GetPlayerById(this.accountId);

            if (data != null)
            {
                nickname = data.nickname;
                position = data.position;
                rotation = data.rotation;
                curSceneNumId = data.curSceneNumId;
                teams = data.teams;
                roleId = data.roleId;
                random.v = data.totalGuidCount;
                teamIndex = data.teamIndex;
                if (data.unlockedSystems != null)
                    unlockedSystems = data.unlockedSystems;
                if (data.noSpawnAnymore != null)
                    noSpawnAnymore = data.noSpawnAnymore;
                maxDashEnergy = data.maxDashEnergy;
                curStamina = data.curStamina;
                nextRecoverTime = data.nextRecoverTime;
                if (data.clientSetting != null)
                {
                    clientSetting = data.clientSetting;
                }
                if (data.gender > 0) gender = data.gender;
                level = data.level;
                xp = data.xp;
                worldLevel = data.worldLevel;
                unlockWorldLevel = data.unlockWorldLevel;
                lastSetWorldLevelTs = data.lastSetWorldLevelTs;

                LoadCharacters();
                mails = DatabaseManager.db.LoadMails(roleId);
                inventoryManager.Load();
                // Load bag and ensure bag items reference the same Item objects from items.items
                // This prevents data inconsistency where bag items and items.items have different object instances
                if (data.bag != null)
                {
                    inventoryManager.items.bag = new Dictionary<int, Item>();
                    foreach (var bagEntry in data.bag)
                    {
                        int gridIndex = bagEntry.Key;
                        Item bagItem = bagEntry.Value;

                        // Find the corresponding item in items.items by guid
                        // This ensures bag items reference the same Item objects from items.items
                        Item? existingItem = inventoryManager.items.items.Find(i => i.guid == bagItem.guid);
                        if (existingItem != null)
                        {
                            // Use the item from items.items to ensure consistency
                            inventoryManager.items.bag[gridIndex] = existingItem;
                        }
                        else
                        {
                            // Item not found in items.items, add it
                            // This handles edge cases where bag has items not in items collection
                            Logger.PrintWarn($"[Player.Load] Bag item {bagItem.id} (guid={bagItem.guid}) not found in items.items, adding it");
                            inventoryManager.items.items.Add(bagItem);
                            DatabaseManager.db.UpsertItem(bagItem);
                            inventoryManager.items.bag[gridIndex] = bagItem;
                        }
                    }
                }
                spaceshipManager.Load();
                if (data.scenes != null)
                {
                    sceneManager.scenes = data.scenes;
                }
                nextDailyReset = data.nextDailyReset;
                bitsetManager.Load(data.bitsets);
                savedSaveZone = data.savedSafeZone;
                personalData = data.personalData;
                if (personalData == null)
                {
                    personalData = new();
                }
                if (Server.config.serverOptions.missionsEnabled) missionSystem.Load();
            }
            else
            {
                Initialize(); //only if no account found
            }
            adventureBookManager.Load();
            sceneManager.Load();
            factoryManager.Load();
            battlePassManager.Load();
            mapMarkManager.Load();
            return (data != null);
        }
        public void LoadCharacters()
        {
            chars = DatabaseManager.db.LoadCharacters(roleId);
        }
        /// <summary>
        /// Get the character using the guid *Added in 1.0.7*
        /// </summary>
        /// <param name="guid"></param>
        /// <returns></returns>
        public Character GetCharacter(ulong guid)
        {
            return chars.Find(c => c.guid == guid);
        }
        /// <summary>
        /// Get the character using the template id
        /// </summary>
        /// <param name="templateId"></param>
        /// <returns>Character</returns>
        public Character GetCharacter(string templateId)
        {
            return chars.Find(c => c.id == templateId);
        }
        /// <summary>
        /// Add a character with template id if not present in the chars list *Added in 1.1.6*
        /// </summary>
        /// <param name="id"></param>
        public Character AddCharacter(string id, bool notify = false)
        {
            Character chara = GetCharacter(id);
            if (chara == null)
            {
                chara = new Character(roleId, id, 1);
                chars.Add(chara);
                // Save character to database immediately
                DatabaseManager.db.UpsertCharacter(chara);
                if (notify)
                {
                    Send(new PacketScCharBagAddChar(this, chara));
                }
            }
            return chara;
        }
        /// <summary>
        /// Add a character with template id and level if not present in the chars list *Added in 1.1.6*
        /// </summary>
        /// <param name="id"></param>
        public Character AddCharacter(string id, int level, bool notify = false)
        {
            Character chara = GetCharacter(id);
            if (chara == null)
            {
                chara = new Character(roleId, id, level);
                chars.Add(chara);
                // Save character to database immediately
                DatabaseManager.db.UpsertCharacter(chara);
                if (notify)
                {
                    Send(new PacketScCharBagAddChar(this, chara));
                    Item weapon = inventoryManager.items.Find(i => i.guid == chara.weaponGuid);
                    if (weapon != null) Send(new PacketScItemBagScopeModify(this, weapon));
                }
            }
            return chara;
        }
        /// <summary>
        /// Remove a character using template id *Added in 1.1.6*
        /// </summary>
        /// <param name="id"></param>
        public void RemoveCharacter(string id)
        {
            Character chara = GetCharacter(id);
            if (chara == null)
            {
                return;
            }
            chars.Remove(chara);
            // Delete character from database immediately
            DatabaseManager.db.DeleteCharacter(chara);
            Send(new PacketScCharBagDelChar(this, chara));
        }
        public void ReplaceCharacter(string id, string newId)
        {
            Character chara = GetCharacter(id);
            if (chara == null)
            {
                return;
            }
            chara.id = newId;
            Send(new PacketScSyncCharBagInfo(this));
        }
        public void Initialize()
        {
            if (Server.config.serverOptions.missionsEnabled)
            {
                chars.Add(new Character(roleId, "chr_0002_endminm", 1));
                missionSystem.AddMission("e0m0", MissionState.Processing);
                // missionSystem.GetQuestById("e0m0_q#6").state = QuestState.Processing;
            }
            else
            {
                foreach (var item in ResourceManager.characterTable)
                {
                    chars.Add(new Character(roleId, item.Key, 1));
                }
                UnlockImportantSystems();
            }
            /* if (Server.config.serverOptions.giveAllItems)
             {
                 foreach (var item in itemTable)
                 {
                     if (item.Value.GetStorage() != ItemStorageSpace.BagAndFactoryDepot)
                     {
                         if (item.Value.maxStackCount == -1)
                         {
                             inventoryManager.items.Add(new Item(roleId, item.Value.id, 100000));
                         }
                         else
                         {
                             inventoryManager.items.Add(new Item(roleId, item.Value.id, item.Value.maxStackCount));
                         }
                     }
                 }
             }*/

            teams.Add(new Team()
            {
                leader = chars[0].guid,
                members = { chars[0].guid }
            });
            teams.Add(new Team());
            teams.Add(new Team());
            teams.Add(new Team());
            teams.Add(new Team());
            bitsetManager.Load(new Dictionary<int, List<int>>());
            mails.Add(new Mail()
            {
                expireTime = DateTime.UtcNow.AddDays(30).ToUnixTimestampMilliseconds() / 1000,
                guid = random.NextRand(),
                mailSubType = MailSubType.Default,
                mailType = MailType.Mail,
                owner = roleId,
                sendTime = DateTime.UtcNow.ToUnixTimestampMilliseconds() / 1000,

                content = new()
                {
                    content = "Campofinale PS",
                    senderName = "Team Stardust",
                    title = "Campofinale PS"
                }
            });
            spaceshipManager.Load();
            // Save newly created characters to database
            foreach (Character c in chars)
            {
                DatabaseManager.db.UpsertCharacter(c);
            }
        }
        public void UnlockImportantSystems()
        {
            foreach (UnlockSystemType type in Enum.GetValues(typeof(UnlockSystemType)))
            {
                unlockedSystems.Add((int)type);
            }
        }
        public void EnterScene()
        {
            if (curSceneNumId == 0)
            {
                EnterScene(Server.config.serverOptions.defaultSceneNumId); //or 101                
            }
            else
            {
                sceneLoadState = SceneLoadState.Loading;
                Send(new PacketScEnterSceneNotify(this, curSceneNumId));
            }
            if (savedSaveZone == null || savedSaveZone.sceneNumId == 0)
            {
                savedSaveZone = new PlayerSafeZoneInfo()
                {
                    sceneNumId = curSceneNumId,
                    position = this.position,
                    rotation = this.rotation
                };
            }
        }
        public enum SceneLoadState
        {
            OK = 0,
            Loading = 1,

        }
        public SceneLoadState sceneLoadState = 0;


        public void EnterScene(int sceneNumId, Vector3f pos, Vector3f rot, PassThroughData passThroughData = null)
        {
            // if (!LoadFinish) return;
            if (GetLevelData(sceneNumId) != null)
            {
                LevelScene curLvData = GetLevelData(curSceneNumId);
                if (curLvData != null)
                {
                    string sceneConfigPathCur = curLvData.defaultState.exportedSceneConfigPath;
                    string sceneConfigPathNew = curLvData.defaultState.exportedSceneConfigPath;
                    if (sceneConfigPathCur != sceneConfigPathNew)
                    {
                        sceneManager.UnloadAllByConfigPath(sceneConfigPathCur);
                    }
                }
                curSceneNumId = sceneNumId;
                position = pos;
                rotation = rot;
                sceneLoadState = SceneLoadState.Loading;
                Send(new PacketScEnterSceneNotify(this, sceneNumId, pos, passThroughData));
                //sceneManager.LoadCurrent();
            }
            else
            {
                Logger.PrintError($"Scene {sceneNumId} not found");
            }
        }
        /// <summary>
        /// Seamless Crossing scene is not working, self scene info is not modifying the current scene num id in the client...
        /// </summary>
        /// <param name="sceneNumId"></param>
        public void SeamlessEnterScene(int sceneNumId)
        {
            if (curSceneNumId != sceneNumId && sceneLoadState == SceneLoadState.OK)
            {
                sceneLoadState = SceneLoadState.Loading;
                curSceneNumId = sceneNumId;
                Send(new PacketScSelfSceneInfo(this, SelfInfoReasonType.SlrSeamlesslyEnterScene));
                ScFactoryModifyChapterScene modify = new()
                {
                    ChapterId = GetCurrentChapter(),
                    SceneId = sceneNumId,
                    Tms = DateTime.UtcNow.ToUnixTimestampMilliseconds()
                };
                Send(ScMsgId.ScFactoryModifyChapterScene, modify);
                ScSceneCrossSceneStatus cross = new()
                {
                    ObjId = teams[teamIndex].leader,
                    SceneNumId = curSceneNumId
                };
                Send(ScMsgId.ScSceneCrossSceneStatus, cross);


                sceneManager.LoadCurrentTeamEntities();
                sceneManager.LoadCurrent();
                sceneLoadState = SceneLoadState.OK;
            }
        }
        public void EnterScene(int sceneNumId)
        {
            if (GetLevelData(sceneNumId) != null)
            {
                //sceneManager.UnloadCurrent(true);
                LevelScene curLvData = GetLevelData(curSceneNumId);
                if (curLvData != null)
                {
                    string sceneConfigPathCur = curLvData.defaultState.exportedSceneConfigPath;
                    string sceneConfigPathNew = curLvData.defaultState.exportedSceneConfigPath;
                    if (sceneConfigPathCur != sceneConfigPathNew)
                    {
                        sceneManager.UnloadAllByConfigPath(sceneConfigPathCur);
                    }
                }

                curSceneNumId = sceneNumId;
                position = GetLevelData(sceneNumId).playerInitPos;
                rotation = GetLevelData(sceneNumId).playerInitRot;
                // sceneManager.LoadCurrent();
                sceneLoadState = SceneLoadState.Loading;
                Send(new PacketScEnterSceneNotify(this, sceneNumId));

            }
            else
            {
                Logger.PrintError($"Scene {sceneNumId} not found");
            }

        }

        public bool SocketConnected(Socket s)
        {
            try
            {
                return !((s.Poll(1000, SelectMode.SelectRead) && (s.Available == 0)) || !s.Connected);
            }
            catch (Exception e)
            {
                return false;
            }

        }
        public void Send(Packet packet, ulong seq = 0, uint totalPackCount = 1, uint currentPackIndex = 0)
        {
            Send(Packet.EncodePacket(packet, seq, totalPackCount, currentPackIndex));
        }
        public void Send(ScMsgId id, IMessage mes, ulong seq = 0, uint totalPackCount = 1, uint currentPackIndex = 0)
        {
            Send(Packet.EncodePacket((int)id, mes, seq, totalPackCount, currentPackIndex));
        }
        public async void Send(Packet packet)
        {
            byte[] datas = packet.set_body.ToByteArray();
            int maxChunkSize = 65535;
            if (datas.Length < maxChunkSize)
            {
                Send(Packet.EncodePacket(packet));
                return;
            }
            int totalChunks = Math.Max((int)Math.Ceiling((double)datas.Length / maxChunkSize), 1);
            List<byte[]> chunks = new List<byte[]>();
            for (int i = 0; i < totalChunks; i++)
            {
                int offset = i * maxChunkSize;
                int chunkSize = Math.Min(maxChunkSize, datas.Length - offset);
                byte[] chunk = new byte[chunkSize];
                Array.Copy(datas, offset, chunk, 0, chunkSize);
                chunks.Add(chunk);
            }
            ulong seqNext = Packet.seqNext;
            for (int i = 0; i < chunks.Count; i++)
            {
                byte[] data = chunks[i];

                Send(Packet.EncodePacket(packet.cmdId, data, seqNext, (uint)chunks.Count, (uint)i));
            }
        }
        public async void Send(byte[] data)
        {
            try
            {
                await socket.SendAsync(data);
            }
            catch (Exception e)
            {
                Disconnect();
            }

        }
        public static byte[] ConcatenateByteArrays(byte[] array1, byte[] array2)
        {
            return array1.Concat(array2).ToArray();
        }

        public void Receive()
        {
            try
            {
                while (SocketConnected(socket))
                {
                    byte[] buffer = new byte[3];
                    int length = socket.Receive(buffer);
                    if (length == 3)
                    {
                        Packet packet = null;
                        byte headLength = Packet.GetByte(buffer, 0);
                        ushort bodyLength = Packet.GetUInt16(buffer, 1);
                        byte[] moreData = new byte[bodyLength + headLength];
                        while (socket.Available < moreData.Length)
                        {

                        }
                        int mLength = socket.Receive(moreData);
                        if (mLength == moreData.Length)
                        {
                            buffer = ConcatenateByteArrays(buffer, moreData);
                            packet = Packet.Read(this, buffer);

                            if (Server.config.logOptions.packets && !Server.csMessageToHide.Contains((CsMsgId)packet.csHead.Msgid))
                            {
                                Logger.Print("Received Packet: " + ((CsMsgId)packet.csHead.Msgid).ToString().Pastel(Color.LightCyan) + $" Id: {packet.csHead.Msgid} with {packet.finishedBody.Length} Bytes");
                                if (Server.config.logOptions.packetBodies)
                                {
                                    // Try to parse and print as JSON, fallback to hex if parsing fails
                                    string bodyStr = PacketBodyParser.TryParsePacketBody((CsMsgId)packet.csHead.Msgid, packet.finishedBody);
                                    Logger.Print(bodyStr);
                                }
                                // Logger.Print(BitConverter.ToString(packet.finishedBody).Replace("-", string.Empty).ToLower());
                            }

                            try
                            {
                                NotifyManager.Notify(this, (CsMsgId)packet.cmdId, packet);
                            }
                            catch (Exception e)
                            {

                                Logger.PrintError("Error while notify packet: " + e.Message + ": " + e.StackTrace);
                            }

                        }
                    }
                }
            }
            catch (Exception e)
            {

            }
            Disconnect();
        }
        public void Kick(CODE code, string optionalMsg = "")
        {
            Send(ScMsgId.ScNtfErrorCode, new ScNtfErrorCode()
            {
                Details = optionalMsg,
                ErrorCode = (int)code
            });
            Disconnect();
        }
        public void Disconnect()
        {
            Server.clients.Remove(this);
            if (Initialized)
            {
                if (currentDungeon != null)
                {
                    curSceneNumId = currentDungeon.prevPlayerSceneNumId;
                    position = currentDungeon.prevPlayerPos;
                    rotation = currentDungeon.prevPlayerRot;
                    currentDungeon = null;
                }
                Initialized = false;
                Save();
                Logger.Print($"{nickname} Disconnected");
                socket.Disconnect(false);
            }
        }
        public void Save()
        {
            //Save playerdata

            DatabaseManager.db.SavePlayerData(this);
            inventoryManager.Save();
            spaceshipManager.Save();
            adventureBookManager.Save();
            factoryManager.Save();
            if (Server.config.serverOptions.missionsEnabled) missionSystem.Save();
            mapMarkManager.Save();
            SaveCharacters();
            SaveMails();

        }
        public void AddStamina(uint stamina)
        {
            curStamina += stamina;
            if (curStamina > 999)
            {
                curStamina = 999;
            }
            if (Initialized) Send(new PacketScSyncStamina(this));
        }
        public void Update()
        {
            //Check recover time
            long curtimestamp = DateTime.UtcNow.ToUnixTimestampMilliseconds();
            if (curtimestamp >= nextRecoverTime)
            {
                nextRecoverTime = DateTime.UtcNow.AddMinutes(7).ToUnixTimestampMilliseconds();
                if (curStamina < maxStamina)
                {
                    AddStamina(1);
                }
            }
            if (curtimestamp >= nextDailyReset && adventureBookManager.data != null)
            {
                nextDailyReset = DateTime.UtcNow.GetNextDailyReset().ToUnixTimestampMilliseconds();
                adventureBookManager.DailyReset();
                if (Initialized)
                    this.Send(new PacketScAdventureBookSync(this));
            }
            if (sceneLoadState == 0)
                sceneManager.Update();
            factoryManager.Update();
        }
        public void SaveMails()
        {
            foreach (Mail mail in mails)
            {
                DatabaseManager.db.UpsertMail(mail);
            }
        }
        public void SaveCharacters()
        {
            foreach (Character c in chars)
            {
                DatabaseManager.db.UpsertCharacter(c);
            }
        }

        public void EnterDungeon(string dungeonId, CsEnterDungeon req)
        {
            Dungeon dungeon = new()
            {
                player = this,
                prevPlayerPos = position,
                prevPlayerRot = rotation,
                prevPlayerSceneNumId = curSceneNumId,
                table = ResourceManager.dungeonTable[dungeonId],
                req = req
            };
            this.currentDungeon = dungeon;
            dungeon.Enter();
        }

        public void LeaveDungeon(CsLeaveDungeon req)
        {
            if (currentDungeon != null)
                currentDungeon.Leave();
        }

        public string GetCurrentChapter()
        {
            try
            {
                DomainDataTable table = domainDataTable.Values.ToList().Find(c => c.levelGroup.Contains(GetLevelData(curSceneNumId).id));
                if (table != null)
                {
                    return table.domainId;
                }
                else
                {
                    return "";
                }
            }
            catch (Exception e)
            {
                return "";
            }
        }

        public RoleBaseInfo GetRoleBaseInfo()
        {
            long curtimestamp = DateTime.UtcNow.ToUnixTimestampMilliseconds();
            try
            {
                return new RoleBaseInfo()
                {
                    LeaderCharId = teams[teamIndex].leader,
                    LeaderPosition = position.ToProto(),
                    LeaderRotation = rotation.ToProto(),
                    ServerTs = (ulong)curtimestamp,
                    SceneName = ResourceManager.levelDatas.Find(l => l.idNum == curSceneNumId).mapIdStr
                };
            }
            catch (Exception e)
            {

                return new RoleBaseInfo()
                {
                    LeaderCharId = teams[teamIndex].leader,
                    LeaderPosition = position.ToProto(),
                    LeaderRotation = rotation.ToProto(),
                    ServerTs = (ulong)curtimestamp
                };
            }

        }
        /// <summary>
        /// Unlock a system
        /// </summary>
        /// <param name="none"></param>
        public void UnlockSystem(UnlockSystemType t)
        {
            unlockedSystems.Add((int)t);
            Send(ScMsgId.ScUnlockSystem, new ScUnlockSystem()
            {
                UnlockSystemType = (int)t
            });
        }

        public void AddToTeam(int index, ulong guid)
        {
            if (teams[index].members.Count < 4)
            {
                teams[index].members.Add(guid);
                Send(new PacketScCharBagSetTeam(this, teams[index], index));
                if (index == this.teamIndex)
                    Send(new PacketScSelfSceneInfo(this, Resource.SelfInfoReasonType.SlrChangeTeam));
            }

        }

        public void RestTeam()
        {
            GetCurTeam().ForEach(chara =>
            {
                chara.curHp = chara.CalcAttributes()[AttributeType.MaxHp].val;
                ScCharSyncStatus state = new ScCharSyncStatus()
                {
                    Objid = chara.guid,
                    IsDead = chara.curHp < 1,
                    BattleInfo = new()
                    {
                        Hp = chara.curHp,
                        Ultimatesp = chara.ultimateSp
                    }
                };
                Send(ScMsgId.ScCharSyncStatus, state);
            });
        }
    }
}
