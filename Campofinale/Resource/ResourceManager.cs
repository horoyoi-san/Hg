using Campofinale.Resource.Dynamic;
using Campofinale.Resource.Json;
using Campofinale.Resource.Table;
using Newtonsoft.Json;
using System.Numerics;
using System;
using static Campofinale.Resource.ResourceManager.LevelScene;
using static Campofinale.Resource.ResourceManager.LevelScene.LevelData;
using StardustUtils;
using System.IO;

namespace Campofinale.Resource
{
    public class IdConst
    {
        public static int IdServerSetTypeBit = 62;
        public static int IdClientRuntimeSetTypeBit = 61;
        public static int IdRoleIndexShift = 57;
        public static ulong LogicIdSegment = 10000;
        public static ulong MaxLogicIdBound = 100000000;
        public static int LocalIdSegment = 10000;
        public static int MaxLocalIdBound = 100000000;
        public static int MaxLevelIdBound = 100000;
        public static ulong MaxGlobalId = 10000000000000;
        public static ulong MaxRuntimeClientId = 2305843009213693952;
    }
    //TODO Move all tables to separated class
    public class ResourceManager
    {
        public static Dictionary<string, LevelScriptEvent> levelScriptsEvents = new(); //
        public static Dictionary<string, SceneAreaTable> sceneAreaTable = new();
        public static StrIdNumTable strIdNumTable = new StrIdNumTable();//
        public static Dictionary<string, CharacterTable> characterTable = new(); //
        public static Dictionary<string, SystemJumpTable> systemJumpTable = new(); //
        public static Dictionary<string, SettlementBasicDataTable> settlementBasicDataTable = new();
        public static Dictionary<string, BlocMissionTable> blocMissionTable = new();
        public static MissionAreaTable missionAreaTable = new(); //
        public static Dictionary<string, DialogTextTable> dialogTextTable = new();
        public static Dictionary<string, GameSystemConfigTable> gameSystemConfigTable = new();
        public static Dictionary<string, WikiGroupTable> wikiGroupTable = new();
        public static Dictionary<string, object> blocUnlockTable = new();
        public static Dictionary<string, GameMechanicTable> gameMechanicTable = new();
        public static Dictionary<string, WeaponBasicTable> weaponBasicTable = new();
        public static Dictionary<string, BlocDataTable> blocDataTable = new(); //
        public static Dictionary<string, ItemTable> itemTable = new();
        public static Dictionary<string, DomainDataTable> domainDataTable = new();
        public static Dictionary<string, CollectionTable> collectionTable = new();
        public static Dictionary<string, CharBreakNodeTable> charBreakNodeTable = new();
        public static Dictionary<string, EnemyAttributeTemplateTable> enemyAttributeTemplateTable = new();
        public static Dictionary<string, CharLevelUpTable> charLevelUpTable = new();
        public static Dictionary<string, ExpItemDataMap> expItemDataMap = new();
        public static Dictionary<string, CharGrowthTable> charGrowthTable = new();
        public static Dictionary<string, WeaponUpgradeTemplateTable> weaponUpgradeTemplateTable = new();
        //Gacha
        public static Dictionary<string, GachaCharPoolTable> gachaCharPoolTable = new();
        public static Dictionary<string, GachaCharPoolContentTable> gachaCharPoolContentTable = new();
        public static Dictionary<string, GachaCharPoolTypeTable> gachaCharPoolTypeTable = new();

        public static Dictionary<string, GachaWeaponPoolTable> gachaWeaponPoolTable = new();
        //
        public static Dictionary<string, EnemyTable> enemyTable = new();
        public static Dictionary<string, WikiEnemyDropTable> wikiEnemyDropTable = new();
        public static Dictionary<string, EquipTable> equipTable = new();
        public static Dictionary<string, EquipSuitTable> equipSuitTable = new();
        public static Dictionary<string, SpaceShipCharBehaviourTable> spaceShipCharBehaviourTable = new();
        public static Dictionary<string, SpaceshipRoomInsTable> spaceshipRoomInsTable = new();
        public static Dictionary<string, DungeonTable> dungeonTable = new();
        public static Dictionary<string, LevelGradeTable> levelGradeTable = new(); //
        public static Dictionary<string, RewardTable> rewardTable = new();
        public static Dictionary<string, AdventureTaskTable> adventureTaskTable = new();
        public static DialogIdTable dialogIdTable = new();//
        public static Dictionary<string, LevelShortIdTable> levelShortIdTable = new();
        public static Dictionary<string, FactoryBuildingTable> factoryBuildingTable = new();
        public static Dictionary<string, FactoryMachineCraftTable> factoryMachineCraftTable = new();
        public static Dictionary<string, FacSTTNodeTable> facSTTNodeTable = new();
        public static Dictionary<string, FacSTTLayerTable> facSTTLayerTable = new();
        public static Dictionary<int, ItemTypeTable> itemTypeTable = new(); //
        public static Dictionary<string, SNSChatTable> snsChatTable = new();//
        public static Dictionary<string, GiftItemTable> giftItemTable = new();
        public static Dictionary<string, InteractiveFacWrapperTable> interactiveFacWrapperTable = new();
        public static List<MissionRuntimeAsset> missionDataTable = new();

        public static InteractiveTable interactiveTable = new(); //
        public static List<LevelScene> levelDatas = new();
        public static List<InteractiveData> interactiveData = new();
        public static List<SpawnerConfig> spawnerConfigs = new();
        public static Dictionary<string, ConditionData> conditions = new();
        public static int GetSceneNumIdFromLevelData(string name)
        {
            if (levelDatas.Find(a => a.id == name) == null) return 0;
            return levelDatas.Find(a => a.id == name).idNum;
        }
        public static bool missingResources = false;
        /// <summary>
        /// Utility method for read a json file
        /// </summary>
        /// <param name="path">The file path</param>
        /// <returns>Return the file content if the file exist, else it return an empty string</returns>
        public static string ReadJsonFile(string path)
        {
            try
            {
                return File.ReadAllText(path);
            }
            catch (Exception e)
            {
                Logger.PrintError($"Error occured while loading {path} Err: {e.Message}");
                missingResources = true;
                return "";
            }

        }
        public static void Init()
        {
            Logger.Print("Loading TableCfg resources");
            // TODO: move all tables to the folder
            sceneAreaTable = JsonConvert.DeserializeObject<Dictionary<string, SceneAreaTable>>(ReadJsonFile("TableCfg/SceneAreaTable.json"));
            systemJumpTable = JsonConvert.DeserializeObject<Dictionary<string, SystemJumpTable>>(ReadJsonFile("TableCfg/SystemJumpTable.json"));
            settlementBasicDataTable = JsonConvert.DeserializeObject<Dictionary<string, SettlementBasicDataTable>>(ReadJsonFile("TableCfg/SettlementBasicDataTable.json"));
            blocMissionTable = JsonConvert.DeserializeObject<Dictionary<string, BlocMissionTable>>(ReadJsonFile("TableCfg/BlocMissionTable.json"));
            dialogTextTable = JsonConvert.DeserializeObject<Dictionary<string, DialogTextTable>>(ReadJsonFile("TableCfg/DialogTextTable.json"));
            gameSystemConfigTable = JsonConvert.DeserializeObject<Dictionary<string, GameSystemConfigTable>>(ReadJsonFile("TableCfg/GameSystemConfigTable.json"));
            wikiGroupTable = JsonConvert.DeserializeObject<Dictionary<string, WikiGroupTable>>(ReadJsonFile("TableCfg/WikiGroupTable.json"));
            dialogIdTable = JsonConvert.DeserializeObject<DialogIdTable>(ReadJsonFile("Json/GameplayConfig/DialogIdTable.json"));
            blocUnlockTable = JsonConvert.DeserializeObject<Dictionary<string, object>>(ReadJsonFile("TableCfg/BlocUnlockTable.json"));
            gameMechanicTable = JsonConvert.DeserializeObject<Dictionary<string, GameMechanicTable>>(ReadJsonFile("TableCfg/GameMechanicTable.json"));
            weaponBasicTable = JsonConvert.DeserializeObject<Dictionary<string, WeaponBasicTable>>(ReadJsonFile("TableCfg/WeaponBasicTable.json"));
            missionAreaTable = JsonConvert.DeserializeObject<MissionAreaTable>(ReadJsonFile("Json/GameplayConfig/MissionAreaTable.json"));
            blocDataTable = JsonConvert.DeserializeObject<Dictionary<string, BlocDataTable>>(ReadJsonFile("TableCfg/BlocDataTable.json"));
            itemTable = JsonConvert.DeserializeObject<Dictionary<string, ItemTable>>(ReadJsonFile("TableCfg/ItemTable.json"));
            domainDataTable = JsonConvert.DeserializeObject<Dictionary<string, DomainDataTable>>(ReadJsonFile("TableCfg/DomainDataTable.json"));
            collectionTable = JsonConvert.DeserializeObject<Dictionary<string, CollectionTable>>(ReadJsonFile("TableCfg/CollectionTable.json"));
            charBreakNodeTable = JsonConvert.DeserializeObject<Dictionary<string, CharBreakNodeTable>>(ReadJsonFile("TableCfg/CharBreakNodeTable.json"));
            enemyAttributeTemplateTable = JsonConvert.DeserializeObject<Dictionary<string, EnemyAttributeTemplateTable>>(ReadJsonFile("TableCfg/EnemyAttributeTemplateTable.json"));
            charLevelUpTable = JsonConvert.DeserializeObject<Dictionary<string, CharLevelUpTable>>(ReadJsonFile("TableCfg/CharLevelUpTable.json"));
            expItemDataMap = JsonConvert.DeserializeObject<Dictionary<string, ExpItemDataMap>>(ReadJsonFile("TableCfg/ExpItemDataMap.json"));
            charGrowthTable = JsonConvert.DeserializeObject<Dictionary<string, CharGrowthTable>>(ReadJsonFile("TableCfg/CharGrowthTable.json"));
            weaponUpgradeTemplateTable = JsonConvert.DeserializeObject<Dictionary<string, WeaponUpgradeTemplateTable>>(ReadJsonFile("TableCfg/WeaponUpgradeTemplateTable.json"));
            gachaCharPoolContentTable = JsonConvert.DeserializeObject<Dictionary<string, GachaCharPoolContentTable>>(ReadJsonFile("TableCfg/GachaCharPoolContentTable.json"));
            enemyTable = JsonConvert.DeserializeObject<Dictionary<string, EnemyTable>>(ReadJsonFile("TableCfg/EnemyTable.json"));
            gachaCharPoolTypeTable = JsonConvert.DeserializeObject<Dictionary<string, GachaCharPoolTypeTable>>(ReadJsonFile("TableCfg/GachaCharPoolTypeTable.json"));
            equipTable = JsonConvert.DeserializeObject<Dictionary<string, EquipTable>>(ReadJsonFile("TableCfg/EquipTable.json"));
            spaceShipCharBehaviourTable = JsonConvert.DeserializeObject<Dictionary<string, SpaceShipCharBehaviourTable>>(ReadJsonFile("TableCfg/SpaceShipCharBehaviourTable.json"));
            spaceshipRoomInsTable = JsonConvert.DeserializeObject<Dictionary<string, SpaceshipRoomInsTable>>(ReadJsonFile("TableCfg/SpaceshipRoomInsTable.json"));
            dungeonTable = JsonConvert.DeserializeObject<Dictionary<string, DungeonTable>>(ReadJsonFile("TableCfg/DungeonTable.json"));
            equipSuitTable = JsonConvert.DeserializeObject<Dictionary<string, EquipSuitTable>>(ReadJsonFile("TableCfg/EquipSuitTable.json"));
            levelShortIdTable = JsonConvert.DeserializeObject<Dictionary<string, LevelShortIdTable>>(ReadJsonFile("DynamicAssets/gamedata/gameplayconfig/jsoncfg/LevelShortIdTable.json"));
            rewardTable = JsonConvert.DeserializeObject<Dictionary<string, RewardTable>>(ReadJsonFile("TableCfg/RewardTable.json"));
            adventureTaskTable = JsonConvert.DeserializeObject<Dictionary<string, AdventureTaskTable>>(ReadJsonFile("TableCfg/AdventureTaskTable.json"));
            factoryBuildingTable = JsonConvert.DeserializeObject<Dictionary<string, FactoryBuildingTable>>(ReadJsonFile("TableCfg/FactoryBuildingTable.json"));
            facSTTNodeTable = JsonConvert.DeserializeObject<Dictionary<string, FacSTTNodeTable>>(ReadJsonFile("TableCfg/FacSTTNodeTable.json"));
            facSTTLayerTable = JsonConvert.DeserializeObject<Dictionary<string, FacSTTLayerTable>>(ReadJsonFile("TableCfg/FacSTTLayerTable.json"));
            LoadInteractiveData();
            LoadLevelDatas();
            LoadScriptsEvent();
            LoadSpawners();
            LoadMissionRuntimeAsset();
            ResourceLoader.LoadTableCfg();

            if (missingResources)
            {
                Logger.PrintWarn("Some Resources are Missing. The Game server may not work properly.");
            }
        }

        public static List<int> GetAllShortIds()
        {
            List<int> IDS = new List<int>();
            foreach (LevelShortIdTable table in levelShortIdTable.Values)
            {
                IDS.AddRange(table.ids.Values);
            }
            return IDS;
        }
        public static string GetEquipSuitTableKey(string suitTableId)
        {
            foreach (var item in equipSuitTable)
            {
                if (item.Value.equipList.Contains(suitTableId))
                {
                    return item.Key;
                }
            }
            return "";
        }
        public static CharGrowthTable.CharTalentNode GetTalentNode(string c, string id)
        {
            return charGrowthTable[c].talentNodeMap[id];
        }
        public static ItemTable GetItemTable(string id)
        {
            return itemTable[id];
        }

        public static LevelScene GetLevelData(int sceneNumId)
        {
            return levelDatas.Find(e => e.idNum == sceneNumId);
        }
        public static ulong[] CalculateWaypointIdsBitset()
        {
            return new LongBitSet(GetAllShortIds()).Bits;
        }
        public static ulong[] CalculateDocsIdsBitset()
        {
            return new LongBitSet(strIdNumTable.char_doc_id.dic.Values).Bits;
        }
        public static ulong[] CalculateVoiceIdsBitset()
        {
            return new LongBitSet(strIdNumTable.char_voice_id.dic.Values).Bits;
        }
        public static LevelScene GetLevelData(string sceneId)
        {
            if (levelDatas.Find(e => e.id == sceneId) == null)
            {
                return new LevelScene();
            }
            return levelDatas.Find(e => e.id == sceneId);
        }
        public static string GetDefaultWeapon(int type)
        {
            return weaponBasicTable.Values.ToList().Find(x => x.weaponType == type).weaponId;
        }
        public static void LoadInteractiveData()
        {
            Logger.Print("Loading InteractiveData resources");
            string directoryPath = @"Json/Interactive/InteractiveData";
            try
            {
                string[] jsonFiles = Directory.GetFiles(directoryPath, "*.json", SearchOption.AllDirectories);
                foreach (string json in jsonFiles)
                {
                    InteractiveData data = JsonConvert.DeserializeObject<InteractiveData>(ReadJsonFile(json));

                    if (data != null)
                    {
                        interactiveData.Add(data);
                    }
                }
                Logger.Print($"Loaded {interactiveData.Count} InteractiveData");
            }
            catch (Exception e)
            {
                Logger.PrintError($"Error occured when loading InteractiveData: " + e.Message);
            }

        }
        public static void LoadMissionRuntimeAsset()
        {
            missionDataTable = new();
            Logger.Print("Loading MissionRuntimeAssets");
            string directoryPath = @"Json/MissionRuntimeAsset";
            try
            {
                var jsonFiles = Directory.GetFiles(directoryPath, "*.json", SearchOption.AllDirectories).Where(f => !f.EndsWith("_meta.json"));
                foreach (string json in jsonFiles)
                {
                    MissionRuntimeAsset asset = JsonConvert.DeserializeObject<MissionRuntimeAsset>(ReadJsonFile(json));
                    missionDataTable.Add(asset);
                }
                Logger.Print($"Loaded {missionDataTable.Count} MissionRuntimeAssets");
            }
            catch (Exception e)
            {
                Logger.PrintWarn($"Error while loading MissionRuntimeAssets");
            }
        }
        public static void LoadScriptsEvent()
        {
            Logger.Print("Loading ScriptsEvents");
            string directoryPath = @"Json/ScriptEvents";
            try
            {
                string[] jsonFiles = Directory.GetFiles(directoryPath, "*.json", SearchOption.AllDirectories);
                foreach (string json in jsonFiles)
                {
                    Dictionary<string, LevelScriptEvent> events = JsonConvert.DeserializeObject<Dictionary<string, LevelScriptEvent>>(ReadJsonFile(json));
                    foreach (KeyValuePair<string, LevelScriptEvent> e in events)
                    {
                        if (levelScriptsEvents.ContainsKey(e.Key))
                        {
                            Logger.PrintWarn($"{e.Key} already added, skipping the one in {json}");
                        }
                        else
                        {
                            levelScriptsEvents.Add(e.Key, e.Value);
                        }

                    }

                }
                Logger.Print($"Loaded {levelScriptsEvents.Count} ScriptsEvents");
            }
            catch (Exception e)
            {
                Logger.PrintWarn($"No ScriptsEvents folder found in Json. Means no Events to execute server side are available.");
            }


        }
        public static void LoadSpawners()
        {
            Logger.Print("Loading Spawners");
            string directoryPath = @"Json/SpawnerConfig";
            try
            {
                string[] jsonFiles = Directory.GetFiles(directoryPath, "*.json", SearchOption.AllDirectories);
                foreach (string json in jsonFiles)
                {
                    SpawnerConfig spawner = JsonConvert.DeserializeObject<SpawnerConfig>(ReadJsonFile(json));
                    spawnerConfigs.Add(spawner);

                }
                Logger.Print($"Loaded {spawnerConfigs.Count} Spawners");
            }
            catch (Exception e)
            {
                Logger.PrintError($"Error occured when loading SpawnerConfigs: " + e.Message);
            }

        }
        public static void LoadLevelDatas()
        {
            Logger.Print("Loading LevelData resources");
            string directoryPath = @"Json/LevelConfig";
            string[] jsonFiles = Directory.GetFiles(directoryPath, "*.json", SearchOption.AllDirectories);
            int allLevelScripts = 0;
            foreach (string json in jsonFiles)
            {

                LevelScene data = JsonConvert.DeserializeObject<LevelScene>(ReadJsonFile(json));
                //Logger.Print($"{data.id}: {data.idNum}, {data.defaultState.exportedSceneConfigPath}");
                data.levelData = new();
                string[] dataPaths = Directory.GetFiles(@"Json/LevelData/" + data.id, "*.json", SearchOption.AllDirectories);
                int i = 0;
                foreach (string path in dataPaths)
                {

                    try
                    {

                        LevelData data_lv = JsonConvert.DeserializeObject<LevelData>(File.ReadAllText(path));
                        if (data_lv.levelScripts == null)
                        {
                            data_lv.levelScripts = new();
                        }
                        data.levelData.Merge(data_lv);
                        i++;
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine(ex.Message);
                        Logger.PrintWarn("Missing LevelData natural spawns file for scene " + data.mapIdStr + " path: " + path);

                    }
                }
                try
                {
                    string[] scriptPaths = Directory.GetFiles(@"Json/LevelScriptData/" + data.levelData.sceneId, "*.json", SearchOption.AllDirectories);

                    foreach (string path in scriptPaths)
                    {
                        try
                        {
                            LevelScriptData script = JsonConvert.DeserializeObject<LevelScriptData>(File.ReadAllText(path));
                            LevelScriptBriefData briefData = null;
                            
                            if(data.levelData.levelScriptBriefDataDict.TryGetValue(script.scriptId, out briefData))
                            {
                               
                                script.properties = briefData.properties;
                                script.propertyIdToKeyMap = briefData.propertyIdToKeyMap;
                            }
                            data.levelData.levelScripts.Add(script);
                            allLevelScripts++;
                        }
                        catch (Exception ex)
                        {
                            Logger.PrintWarn(ex.Message);
                            Logger.PrintWarn("Unable to load LevelScript " + path);

                        }
                    }
                }
                catch (Exception e)
                {
                    Logger.PrintWarn(e.Message);
                    Logger.PrintWarn("Levelscripts for " + json + " doesn't exist apparently. Not fatal error, you can still run the server fine.");
                }

                levelDatas.Add(data);
            }

            Logger.Print($"Loaded {levelDatas.Count} LevelData with {allLevelScripts} LevelScriptData");
        }
        public static int GetItemTemplateId(string item_id)
        {
            return strIdNumTable.item_id.dic[item_id];
        }

        public static string FindFactoryMachineCraftIdUsingCacheItems(List<ItemCount> items, string group)
        {
            // Estrae solo gli ID degli items in input e li ordina
            var inputItemIds = items.Select(item => item.id).OrderBy(id => id).ToList();

            foreach (var recipe in factoryMachineCraftTable.Values.ToList().FindAll(r => r.formulaGroupId == group))
            {
                // Raccoglie tutti gli ID degli ingredienti della ricetta
                var recipeItemIds = new List<string>();
                foreach (var ingr in recipe.ingredients)
                {
                    recipeItemIds.AddRange(ingr.group.Select(item => item.id));
                }

                // Ordina gli ID degli ingredienti della ricetta
                var sortedRecipeItemIds = recipeItemIds.OrderBy(id => id).ToList();

                // Confronta le due liste di ID (ignorando le quantità)
                if (inputItemIds.SequenceEqual(sortedRecipeItemIds))
                {
                    return recipe.id; // Trovata corrispondenza
                }
            }

            return ""; // Nessuna corrispondenza trovata
        }

        public class InteractiveData
        {
            public string id;
            public Dictionary<string, int> propertyKeyToIdMap = new();
            public List<ParamKeyValue> saveProperties = new();
        }
        public class ItemCount
        {
            public int count;
            public string id = "";
            public long tms = DateTime.UtcNow.ToUnixTimestampMilliseconds();

            public ScdFactorySyncItem ToFactoryItemProto()
            {
                return new ScdFactorySyncItem()
                {
                    Count = count,
                    Id = id,
                    Tms = tms
                };
            }
            public bool IsItemAtConveyorEnd(float conveyorSize)
            {
                long spawnTms = tms;
                long endTms = spawnTms + (long)(2000 * conveyorSize);
                long cur = DateTime.UtcNow.ToUnixTimestampMilliseconds();
                return cur > endTms;
            }
        }
        public class FactoryBuildingTable
        {
            public int bandwidth;
            public bool canDelete;
            public string id;
            public bool needPower;
            public int powerConsume;
            public FacBuildingType type;
            public FBuildingRange range;
            public List<FacPort> outputPorts = new();
            public List<FacPort> inputPorts = new();
            public class FacPort
            {
                public int index;
                public int isOutput;
                public bool isPipe;
                public FacPortTrans trans = new();

                public Vector3f GetBack()
                {
                    float angleY = trans.rotation.y % 360f;

                    Vector3f offset;

                    switch ((int)angleY)
                    {
                        default:
                        case 360:
                        case 0:
                            offset = new Vector3f(0, 0, -1);
                            break;
                        case 90:
                            offset = new Vector3f(-1, 0, 0);
                            break;
                        case 180:
                            offset = new Vector3f(0, 0, 1);
                            break;
                        case 270:
                            offset = new Vector3f(1, 0, 0);
                            break;
                    }

                    return trans.position + offset;
                }
                public Vector3f GetFront()
                {
                    float angleY = trans.rotation.y % 360f;

                    Vector3f offset = new();

                    switch ((int)angleY)
                    {
                        default:
                        case 360:
                        case 0:
                            offset = new Vector3f(0, 0, 1);
                            break;
                        case 90:
                            offset = new Vector3f(1, 0, 0);
                            break;
                        case 180:
                            offset = new Vector3f(0, 0, -1);
                            break;
                        case 270:
                            offset = new Vector3f(-1, 0, 0);
                            break;
                    }

                    return trans.position + offset;
                }

                public class FacPortTrans
                {
                    public Vector3f position = new();
                    public Vector3f rotation = new();
                }
            }
            public FCNodeType GetNodeType()
            {
                switch (type)
                {
                    case FacBuildingType.Battle:
                        return FCNodeType.Battle;
                    case FacBuildingType.Hub:
                        return FCNodeType.Hub;
                    case FacBuildingType.SubHub:
                        return FCNodeType.SubHub;
                    case FacBuildingType.MachineCrafter:
                        return FCNodeType.Producer;
                    case FacBuildingType.PowerPort:
                        return FCNodeType.PowerPort;
                    case FacBuildingType.PowerPole:
                        return FCNodeType.PowerPole;
                    case FacBuildingType.PowerDiffuser:
                        return FCNodeType.PowerDiffuser;
                    case FacBuildingType.TravelPole:
                        return FCNodeType.TravelPole;
                    case FacBuildingType.Medic:
                        return FCNodeType.HealTower;
                    case FacBuildingType.Unloader:
                        return FCNodeType.BusUnloader;
                    case FacBuildingType.Loader:
                        return FCNodeType.BusLoader;
                    case FacBuildingType.Miner:
                        return FCNodeType.Collector;
                    case FacBuildingType.Storager:
                        return FCNodeType.DepositBox;
                    default:
                        return FCNodeType.Invalid;
                }
            }
            public struct FBuildingRange
            {
                public int depth;
                public int height;
                public int width;
                public int x;
                public int y;
                public int z;
            }
            public enum FacBuildingType
            {
                Unknown = 0,
                Hub = 1,
                PowerPole = 2,
                PowerStation = 3,
                Storager = 4,
                Crafter = 5,
                MachineCrafter = 6,
                Workshop = 7,
                Miner = 8,
                Trader = 9,
                Loader = 10,
                Unloader = 11,
                Recycler = 12,
                Manufact = 13,
                Medic = 14,
                Soil = 15,
                TravelPole = 16,
                PowerTerminal = 17,
                PowerPort = 18,
                PowerGate = 19,
                Processor = 20,
                Battle = 21,
                SubHub = 22,
                PowerDiffuser = 23,
                FluidContainer = 24,
                FluidPumpIn = 25,
                FluidPumpOut = 26,
                FluidReaction = 27,
                FluidConsume = 28,
                FluidSpray = 29,
                VirtualFluidContainer = 30,
                Empty = 32
            }
        }
        public class AdventureTaskTable
        {
            public int adventureBookStage;
            public string adventureTaskId;
            public string conditionId;
            public ConditionType conditionType;
            public string jumpSystemId;
            public int progressToCompare;
            public string rewardId;
            public int sortId;
            public TaskDescription taskDesc;
            public AdventureTaskType taskType;
        }
        public class TaskDescription
        {
            public string Id;
            public string Text;
        }
        public class DungeonTable
        {
            public string dungeonId;
            public string sceneId;

        }
        public class EquipSuitTable
        {
            public List<string> equipList;
        }
        public class BlocMissionTable
        {
            public string missionId;

        }
        public class ExpItemDataMap
        {
            public int expGain;
        }
        public class CharLevelUpTable
        {
            public int exp;
            public int gold;
        }
        public class GameMechanicTable
        {
            public string gameMechanicsId;
            public int difficulty;
            public string firstPassRewardId;
        }
        public class AttributeModifier
        {
            public AttributeType attrType;
            public double attrValue;
            public List<double> attrValues;
            public ModifierType modifierType;
            public int modifyAttributeType;
        }
        public class EquipTable
        {
            public string domainId;
            public string itemId;
            public ulong minWearLv;
            public int partType;
            public string suitID;
            public List<AttributeModifier> displayAttrModifiers;
            public List<AttributeModifier> equipAttrModifiers;
            public AttributeModifier displayBaseAttrModifier;
        }
        public class WikiGroupTable
        {
            public List<WikiGroup> list;
        }

        public class WikiGroup
        {
            public string groupId;
        }
        public class SpaceShipCharBehaviourTable
        {
            public string charId;
            public string npcId;
        }
        public class SpaceshipRoomInsTable
        {
            public string id;
            public int roomType;
        }
        public class RewardTable
        {
            public string rewardId;

            public List<ItemBundle> itemBundles;
            public class ItemBundle
            {
                public int count;
                public string id;
            }
        }
        public class LevelShortIdTable
        {
            public string sceneName;
            public Dictionary<long, int> ids;
        }
        public class GameSystemConfigTable
        {
            public int unlockSystemType;
            public string systemId;

        }
        public class FacSTTLayerTable
        {
            public string groupId;
            public string layerId;
        }
        public class FacSTTNodeTable
        {
            public string techId;
            public string groupId;
            public bool alreadyUnlock;
            public List<int> uiPos;
            public int sortId;
            public string category;
        }
        public class LevelScene
        {
            [JsonProperty("m_id")]
            public string id;
            [JsonProperty("m_idNum")]
            public int idNum;
            [JsonProperty("m_mapIdStr")]
            public string mapIdStr;
            [JsonProperty("m_isSeamless")]
            public bool isSeamless;
            [JsonProperty("m_defaultState")]
            public DefaultState defaultState = new();
            [JsonProperty("m_playerInitPos")]
            public Vector3f playerInitPos;
            [JsonProperty("m_playerInitRot")]
            public Vector3f playerInitRot;
            [JsonIgnore]
            public LevelData levelData;

            //public List<LevelData> levelDataList;
            public class LevelData
            {
                public string sceneId = "";
                public int levelIdNum;
                public List<LevelEnemyData> enemies = new();
                public List<LevelInteractiveData> interactives = new();
                public List<LevelNpcData> npcs = new();
                public List<LevelScriptData> levelScripts = new();
                public Dictionary<ulong, LevelScriptBriefData> levelScriptBriefDataDict = new();
                public List<WorldWayPointSets> worldWayPointSets = new();
                public List<LevelFactoryRegionData> factoryRegions = new();
                public List<LevelSpawnerData> spawners = new();
                public LevelFunctionAreaData functionArea = new();
                public void Merge(LevelData other)
                {
                    this.sceneId = other.sceneId;
                    this.levelIdNum = other.levelIdNum;
                    this.enemies.AddRange(other.enemies);
                    this.interactives.AddRange(other.interactives);
                    this.npcs.AddRange(other.npcs);
                    this.levelScripts.AddRange(other.levelScripts);
                    this.worldWayPointSets.AddRange(other.worldWayPointSets);
                    this.factoryRegions.AddRange(other.factoryRegions);
                    this.spawners.AddRange(other.spawners);
                    this.functionArea.ranges.AddRange(other.functionArea.ranges);
                    foreach(KeyValuePair<ulong,LevelScriptBriefData> brief in other.levelScriptBriefDataDict)
                    {
                        if(!this.levelScriptBriefDataDict.ContainsKey(brief.Key))
                        this.levelScriptBriefDataDict.Add(brief.Key,brief.Value);
                    }
                    
                }

                public class WorldWayPointSets
                {
                    public int id;
                    public Dictionary<string, int> pointIdToIndex = new();
                }

                public class LevelFunctionAreaData
                {
                    public List<LevelFunctionRangeData> ranges = new();

                    public class LevelFunctionRangeData
                    {
                        public Vector3f m_center = new();
                        public Vector3f m_size = new();

                        public bool IsObjectInside(Vector3f position)
                        {
                            Vector3f halfSize = m_size * 0.5f;

                            return Math.Abs(position.x - m_center.x) <= halfSize.x &&
                                   Math.Abs(position.y - m_center.y) <= halfSize.y &&
                                   Math.Abs(position.z - m_center.z) <= halfSize.z;
                        }
                    }
                }
                public class LevelSpawnerData
                {
                    public ulong spawnerId;
                    public string configId;
                    public ulong belongLevelScriptId;
                }
                public class LevelScriptBriefData
                {
                    public ulong scriptId;
                    public List<ParamKeyValue> properties = new();
                    public Dictionary<int, string> propertyIdToKeyMap = new();
                }

                public class LevelScriptData
                {
                    public ulong scriptId;
                    public string refGameId;
                    
                    public ScriptActionMap actionMap = new();
                    public List<ParamKeyValue> properties = new();
                    public Dictionary<int, string> propertyIdToKeyMap = new();

                    public int GetPropertyId(string key, List<int> toExclude)
                    {
                        foreach (var keyValuePair in propertyIdToKeyMap)
                        {
                            if (keyValuePair.Value == key && !toExclude.Contains(keyValuePair.Key))
                            {
                                return keyValuePair.Key;
                            }
                        }
                        return 0;
                    }

                    public class ScriptActionMap
                    {
                        public ActionDataMap dataMap = new();


                        public class ScriptHeader
                        {
                            public string _uid = "";

                            public EventKey _eventKey = new();

                            public class EventKey
                            {
                                public string constValue = "";
                            }
                        }
                        public class ActionDataMap
                        {
                            public List<ScriptHeader> headerList = new();
                        }
                    }
                }
                public class LevelFactoryRegionData
                {
                    public ulong levelLogicId;
                    public ulong belongLevelScriptId;
                    public ObjectType entityType;
                    public string entityDataIdKey;
                    public bool defaultHide;
                    public Vector3f position;
                    public Vector3f rotation;
                    public Vector3f scale;
                    public bool forceLoad;
                    public string regionId;
                    public List<LevelFactoryRegionAreaData> areas;

                    public class LevelFactoryRegionAreaData
                    {
                        public List<AreaDataLevel> levelData;

                        public class AreaDataLevel
                        {
                            public int level;
                            public List<AreaDataBound> levelBounds;

                            public class AreaDataBound
                            {
                                public Vector3f start;
                                public Vector3f size;
                            }
                        }
                    }

                }
                public class LevelNpcData
                {
                    public ulong levelLogicId;
                    public ulong belongLevelScriptId;
                    public ObjectType entityType;
                    public string entityDataIdKey;
                    public bool defaultHide;
                    public Vector3f position;
                    public Vector3f rotation;
                    public Vector3f scale;
                    public bool forceLoad;
                    public bool doPatrol;
                    public string npcGroupId;
                }
                public class LevelInteractiveData
                {
                    public ulong levelLogicId;
                    public ulong belongLevelScriptId;
                    public ObjectType entityType;
                    public string entityDataIdKey;
                    public bool defaultHide;
                    public Vector3f position;
                    public Vector3f rotation;
                    public Vector3f scale;
                    public bool forceLoad;
                    public int level;
                    public ulong dependencyGroupId;
                    public List<ParamKeyValue> properties;
                    public Dictionary<InteractiveComponentType, List<ParamKeyValue>> componentProperties = new();
                }
                public class ScriptProperty
                {
                    public int RealType;
                    public int ValueType;
                    public List<string> ValueStringList = new();
                    public List<float> ValueFloatList = new();
                    public List<long> ValueIntList = new();
                    public List<bool> ValueBoolList = new();

                    public ScriptProperty()
                    {

                    }
                    public ScriptProperty(DynamicParameter p)
                    {
                        this.RealType = p.RealType;
                        this.ValueType = p.ValueType;
                        this.ValueBoolList.AddRange(p.ValueBoolList.ToList());
                        this.ValueFloatList.AddRange(p.ValueFloatList.ToList());
                        this.ValueIntList.AddRange(p.ValueIntList.ToList());
                        this.ValueStringList.AddRange(p.ValueStringList.ToList());
                    }
                    public DynamicParameter ToProto()
                    {
                        return new DynamicParameter()
                        {
                            RealType = RealType,
                            ValueType = ValueType,
                            ValueStringList = { ValueStringList },
                            ValueBoolList = { ValueBoolList },
                            ValueFloatList = { ValueFloatList },
                            ValueIntList = { ValueIntList },

                        };
                    }
                }
                public class ParamKeyValue
                {
                    public string key;
                    public ParamValue value;

                    public DynamicParameter ToProto()
                    {
                        DynamicParameter param = new()
                        {
                            RealType = (int)value.type,
                            ValueType = (int)value.type,

                        };
                        foreach (var val in value.valueArray)
                        {
                            switch (value.type)
                            {
                                case ParamRealType.LangKey:
                                    param.ValueStringList.Add(val.valueString);
                                    param.ValueType = (int)ParamValueType.String;
                                    break;
                                case ParamRealType.LangKeyList:
                                    param.ValueStringList.Add(val.valueString);
                                    param.ValueType = (int)ParamValueType.StringList;
                                    break;
                                case ParamRealType.String:
                                    param.ValueStringList.Add(val.valueString);
                                    param.ValueType = (int)ParamValueType.String;
                                    break;
                                case ParamRealType.StringList:
                                    param.ValueStringList.Add(val.valueString);
                                    param.ValueType = (int)ParamValueType.StringList;
                                    break;
                                case ParamRealType.Vector3:
                                    param.ValueFloatList.Add(val.ToFloat());
                                    param.ValueType = (int)ParamValueType.FloatList;
                                    break;
                                case ParamRealType.Float:
                                    param.ValueFloatList.Add(val.ToFloat());
                                    param.ValueType = (int)ParamValueType.Float;
                                    break;
                                case ParamRealType.FloatList:
                                    param.ValueFloatList.Add(val.ToFloat());
                                    param.ValueType = (int)ParamValueType.FloatList;
                                    break;
                                case ParamRealType.Int:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.Int;
                                    break;
                                case ParamRealType.IntList:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.IntList;
                                    break;
                                case ParamRealType.Bool:
                                    param.ValueBoolList.Add(val.valueBit64 == 1);
                                    param.ValueType = (int)ParamValueType.Bool;
                                    break;
                                case ParamRealType.Vector3List:
                                    param.ValueFloatList.Add(val.ToFloat());
                                    param.ValueType = (int)ParamValueType.FloatList;
                                    break;
                                case ParamRealType.BoolList:
                                    param.ValueBoolList.Add(val.valueBit64 == 1);
                                    param.ValueType = (int)ParamValueType.BoolList;
                                    break;
                                case ParamRealType.EntityPtr:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.Int;
                                    break;
                                case ParamRealType.EntityPtrList:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.Int;
                                    break;
                                case ParamRealType.UInt64:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.Int;
                                    break;
                                case ParamRealType.UInt:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.Int;
                                    break;
                                case ParamRealType.WaterVolumePtr:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.Int;
                                    break;
                                default:
                                    return null;
                                    break;
                            }
                        }

                        return param;
                    }

                    public ScriptProperty ToScriptProperty()
                    {
                        ScriptProperty param = new()
                        {
                            RealType = (int)value.type,
                            ValueType = (int)value.type,

                        };
                        foreach (var val in value.valueArray)
                        {
                            switch (value.type)
                            {
                                case ParamRealType.LangKey:
                                    param.ValueStringList.Add(val.valueString);
                                    param.ValueType = (int)ParamValueType.String;
                                    break;
                                case ParamRealType.LangKeyList:
                                    param.ValueStringList.Add(val.valueString);
                                    param.ValueType = (int)ParamValueType.StringList;
                                    break;
                                case ParamRealType.String:
                                    param.ValueStringList.Add(val.valueString);
                                    param.ValueType = (int)ParamValueType.String;
                                    break;
                                case ParamRealType.StringList:
                                    param.ValueStringList.Add(val.valueString);
                                    param.ValueType = (int)ParamValueType.StringList;
                                    break;
                                case ParamRealType.Vector3:
                                    param.ValueFloatList.Add(val.ToFloat());
                                    param.ValueType = (int)ParamValueType.FloatList;
                                    break;
                                case ParamRealType.Float:
                                    param.ValueFloatList.Add(val.ToFloat());
                                    param.ValueType = (int)ParamValueType.Float;
                                    break;
                                case ParamRealType.FloatList:
                                    param.ValueFloatList.Add(val.ToFloat());
                                    param.ValueType = (int)ParamValueType.FloatList;
                                    break;
                                case ParamRealType.Int:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.Int;
                                    break;
                                case ParamRealType.IntList:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.IntList;
                                    break;
                                case ParamRealType.Bool:
                                    param.ValueBoolList.Add(val.valueBit64 == 1);
                                    param.ValueType = (int)ParamValueType.Bool;
                                    break;
                                case ParamRealType.Vector3List:
                                    param.ValueFloatList.Add(val.ToFloat());
                                    param.ValueType = (int)ParamValueType.FloatList;
                                    break;
                                case ParamRealType.BoolList:
                                    param.ValueBoolList.Add(val.valueBit64 == 1);
                                    param.ValueType = (int)ParamValueType.BoolList;
                                    break;
                                case ParamRealType.EntityPtr:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.Int;
                                    break;
                                case ParamRealType.EntityPtrList:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.Int;
                                    break;
                                case ParamRealType.UInt64:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.Int;
                                    break;
                                case ParamRealType.WaterVolumePtr:
                                    param.ValueIntList.Add(val.valueBit64);
                                    param.ValueType = (int)ParamValueType.Int;
                                    break;
                                default:
                                    return null;
                                    break;
                            }
                        }

                        return param;
                    }
                    public void Update(DynamicParameter value)
                    {
                        foreach (var item in value.ValueBoolList)
                        {

                        }
                    }

                    public class ParamValue
                    {
                        public ParamRealType type;
                        public ParamValueAtom[] valueArray;
                    }
                    public class ParamValueAtom
                    {
                        public long valueBit64 = 0;
                        public string valueString = "";

                        public float ToFloat()
                        {
                            int intValueFromBit64 = (int)valueBit64;
                            float floatValueFromBit64 = (float)BitConverter.Int64BitsToDouble(valueBit64);
                            //float floatValueFromBit64 = BitConverter.ToSingle(BitConverter.GetBytes(intValueFromBit64), 0);
                            return floatValueFromBit64;
                        }
                        public int ToInt()
                        {
                            int intValueFromBit64 = (int)valueBit64;

                            return intValueFromBit64;
                        }
                    }
                }
                public class LevelEnemyData
                {
                    public ulong levelLogicId;
                    public ulong belongLevelScriptId;
                    public ObjectType entityType;
                    public string entityDataIdKey;
                    public bool defaultHide;
                    public Vector3f position;
                    public Vector3f rotation;
                    public Vector3f scale;
                    public bool forceLoad;
                    public int level;
                    public string overrideAIConfig;
                    public int enemyGroupId;
                    public bool respawnable;

                }
            }
        }
        public class Vector3f
        {
            public float x;
            public float y;
            public float z;

            public override bool Equals(object obj)
            {
                if (obj is Vector3f v)
                {
                    return x == v.x && y == v.y && z == v.z;
                }
                return false;
            }

            public override int GetHashCode()
            {
                return HashCode.Combine(x, y, z);
            }

            public Vector3f()
            {

            }
            public static Vector3f operator *(Vector3f v, float scalar)
            {
                return new Vector3f(v.x * scalar, v.y * scalar, v.z * scalar);
            }
            public static Vector3f operator +(Vector3f v, Vector3f v2)
            {
                return new Vector3f(v.x + v2.x, v.y + v2.y, v.z + v2.z);
            }
            public Vector3f(float x, float y, float z)
            {
                this.x = x;
                this.y = y;
                this.z = z;
            }

            public Vector3f(Vector v) : this()
            {
                this.x = v.X; this.y = v.Y; this.z = v.Z;
            }

            public Vector3f(ScdVec3Int v)
            {
                this.x = v.X; this.y = v.Y; this.z = v.Z;
            }

            public float Distance(Vector3f other)
            {
                float dx = x - other.x;
                float dy = y - other.y;
                float dz = z - other.z;
                return MathF.Sqrt(dx * dx + dy * dy + dz * dz);
            }
            public float DistanceXZ(Vector3f other)
            {
                float dx = x - other.x;
                float dy = 0;
                float dz = z - other.z;
                return MathF.Sqrt(dx * dx + dy * dy + dz * dz);
            }
            public ScdVec3Int ToProtoScd()
            {
                return new ScdVec3Int()
                {
                    X = (int)x,
                    Y = (int)y,
                    Z = (int)z,
                };
            }
            public Vector ToProto()
            {
                return new Vector()
                {
                    X = x,
                    Y = y,
                    Z = z,
                };
            }
        }
        public class DefaultState
        {
            public string sourceSceneName = "";
            public string exportedSceneConfigPath = "";
        }
        public class SettlementBasicDataTable
        {
            public string settlementId;
            public string domainId;
        }

        public class GachaCharPoolTypeTable
        {
            public int type;
            public int hardGuarantee;
            public int softGuarantee;
        }
        public class GachaCharPoolContentTable
        {
            public List<GachaCharPoolItem> list;
        }
        public class GachaCharPoolItem
        {
            public string charId;
            public string isHardGuaranteeItem;
            public int starLevel;
        }
        public class DialogTextTable
        {

        }

        public class StrIdDic
        {
            public Dictionary<string, int> dic = new();
        }
        public class SceneAreaTable
        {
            public string areaId;
            public string sceneId;
            public int areaIndex;
        }
        public class EnemyTable
        {
            public string attrTemplateId;
            public string enemyId;
            public string templateId;
        }

        public class ItemTable
        {
            public ItemValuableDepotType valuableTabType;
            public string id;
            public int maxStackCount;
            public bool backpackCanDiscard;
            public string modelKey;
            public int type;

            public ItemStorageSpace GetStorage()
            {
                return ResourceManager.itemTypeTable[type].storageSpace;
            }
        }
        public class WeaponBasicTable
        {
            public int weaponType;
            public string weaponId;
            public string levelTemplateId;
        }
        public class WeaponUpgradeTemplateTable
        {
            public List<WeaponCurve> list;

            public class WeaponCurve
            {
                public float baseAtk;
                public ulong lvUpExp;
                public ulong lvUpGold;
                public ulong weaponLv;
            }
        }
        public class DomainDataTable
        {
            public string domainId;
            public int sortId;
            public List<string> levelGroup;
            public List<string> settlementGroup;
        }
        public class CollectionTable
        {
            public string prefabId;
        }
        public class CharBreakNodeTable
        {
            public int breakStage;
            public string nodeId;
        }
        public class EnemyAttributeTemplateTable
        {
            public string templateId;
            public List<Attributes> levelDependentAttributes;
            public AttributeList levelIndependentAttributes;
        }
        public class CharGrowthTable
        {
            public Dictionary<string, CharTalentNode> talentNodeMap;
            public string defaultWeaponId;

            public class CharTalentNode
            {
                public string nodeId;
                public TalentNodeType nodeType;
                public List<RequireItem> requiredItem;
            }
        }
        public class RequireItem
        {
            public string id;
            public int count;
        }

        public class Attributes
        {
            public int breakStage;
            public AttributeList Attribute;
            //Enemy
            public List<Attribute> attrs;
        }
        public class AttributeList
        {
            public List<Attribute> attrs;
        }
        public class Attribute
        {
            public int attrType;
            public double attrValue;
        }


    }
}
