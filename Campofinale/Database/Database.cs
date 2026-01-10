using Campofinale.Game;
using Campofinale.Game.Adventure;
using Campofinale.Game.BP;
using Campofinale.Game.Char;
using Campofinale.Game.Gacha;
using Campofinale.Game.Inventory;
using Campofinale.Game.MissionSys;
using Campofinale.Game.Spaceship;
using Campofinale.Protocol;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Driver;
using StardustUtils;
using System;
using System.Security.Cryptography;
using System.Text;
using static Campofinale.Game.Adventure.AdventureBookManager;
using static Campofinale.Game.BP.BattlePassManager;
using static Campofinale.Game.Factory.FactoryManager;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Database
{
    public class PlayerData
    {
        [BsonId]
        public ulong roleId;

        public string accountId;
        public Vector3f position;
        public Vector3f rotation;
        public int curSceneNumId;
        public uint level = 20;
        public uint xp = 0;
        public uint worldLevel = 3;
        public uint unlockWorldLevel = 3;
        public long lastSetWorldLevelTs = 0;
        public string nickname = "Endministrator";
        public int teamIndex = 0;
        public List<Team> teams = new List<Team>();
        public ulong totalGuidCount = 1;
        public List<int> unlockedSystems = new();
        public List<ulong> noSpawnAnymore = new();
        public long maxDashEnergy = 250;
        public uint curStamina;
        public long nextRecoverTime;
        public long nextDailyReset;
        public List<Scene> scenes = new();
        public Dictionary<int, List<int>> bitsets = new();
        public PlayerSafeZoneInfo savedSafeZone = new();
        public PlayerPersonalData personalData = new();
        public Gender gender = Gender.GenFemale;
        public Dictionary<int, Item> bag = new();
        public byte[] clientSetting = new byte[0];
    }
    public class MissionData
    {
        [BsonId]
        public ulong roleId;
        public List<GameMission> missions = new();
        public List<GameQuest> quests = new();
        public string curMission = "e0m0";
    }
    public class MapMarkData
    {
        [BsonId]
        public ulong roleId;
        // Static map marks: only store discovered/activated mark indices (serverMarkIndex from LevelMapMark config)
        // The actual mark data (position, icon, etc.) is loaded from LevelMapMark.json config table
        public List<int> discoveredStaticMarkIndices = new();
        // Dynamic map marks: player-created custom marks, need full data
        public List<SceneDynamicMapMark> sceneDynamicMapMarkList = new();
        public SceneTrackPoint trackPoint = new();
    }
    public class Account
    {
        public string id;
        public string username;
        public string token;
        public string grantToken;

        public static string GenerateAccountId()
        {
            byte[] bytes = new byte[4];
            RandomNumberGenerator.Fill(bytes);

            // Converte i byte in un intero positivo tra 100000000 e 999999999
            int number = BitConverter.ToInt32(bytes, 0) & int.MaxValue;
            number = 100000000 + (number % 900000000);

            return number.ToString();
        }
    }
    public class Database
    {
        private readonly IMongoDatabase _database;

        public Database(string connectionString, string dbName)
        {
            var client = new MongoClient(connectionString);

            _database = client.GetDatabase(dbName);
        }
        public List<Mail> LoadMails(ulong roleId)
        {
            return _database.GetCollection<Mail>("mails").Find(c => c.owner == roleId).ToList();
        }
        public MissionData LoadMissionData(ulong roleId)
        {
            return _database.GetCollection<MissionData>("missionsData").Find(c => c.roleId == roleId).FirstOrDefault();
        }
        public AdventureBookData LoadAdventureBookData(ulong roleId)
        {
            return _database.GetCollection<AdventureBookData>("adventureBookData").Find(c => c.roleId == roleId).FirstOrDefault();
        }
        public BattlePassPlayerData LoadBPPlayerData(ulong roleId, string currentSeasonId)
        {
            return _database.GetCollection<BattlePassPlayerData>("battlePassData").Find(c => c.roleId == roleId && c.seasonId == currentSeasonId).FirstOrDefault();
        }
        public List<Character> LoadCharacters(ulong roleId)
        {
            return _database.GetCollection<Character>("avatars").Find(c => c.owner == roleId).ToList();
        }
        public List<SpaceshipChar> LoadSpaceshipChars(ulong roleId)
        {
            return _database.GetCollection<SpaceshipChar>("spaceship_chars").Find(c => c.owner == roleId).ToList();
        }
        public List<SpaceshipRoom> LoadSpaceshipRooms(ulong roleId)
        {
            return _database.GetCollection<SpaceshipRoom>("spaceship_rooms").Find(c => c.owner == roleId).ToList();
        }
        public FactoryData LoadFactoryData(ulong roleId)
        {
            return _database.GetCollection<FactoryData>("factory").Find(c => c.roleId == roleId).ToList().FirstOrDefault();
        }
        public MapMarkData LoadMapMarkData(ulong roleId)
        {
            return _database.GetCollection<MapMarkData>("mapMarkData").Find(c => c.roleId == roleId).FirstOrDefault();
        }
        public List<Item> LoadInventoryItems(ulong roleId)
        {
            return _database.GetCollection<Item>("items").Find(c => c.owner == roleId).ToList();
        }
        public void AddGachaTransaction(GachaTransaction transaction)
        {
            if (transaction._id == ObjectId.Empty)
            {
                transaction._id = ObjectId.GenerateNewId();
            }
            var collection = _database.GetCollection<GachaTransaction>("gachas");
            //These transactions never need to be changed
            collection.InsertOne(transaction);
        }
        public List<GachaTransaction> LoadGachaTransaction(ulong roleId, int type)
        {
            return _database.GetCollection<GachaTransaction>("gachas").Find(c => c.ownerId == roleId && c.bannerType == type).ToList();
        }
        public static string GenerateToken(int length)
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
            Random random = new Random();
            StringBuilder result = new StringBuilder(length);

            for (int i = 0; i < length; i++)
            {
                result.Append(chars[random.Next(chars.Length)]);
            }

            return result.ToString();
        }
        public void SavePlayerData(Player player)
        {
            PlayerData data = new()
            {
                accountId = player.accountId,
                curSceneNumId = player.curSceneNumId,
                level = player.level,
                nickname = player.nickname,
                position = player.position,
                rotation = player.rotation,
                roleId = player.roleId,
                teams = player.teams,
                xp = player.xp,
                worldLevel = player.worldLevel,
                unlockWorldLevel = player.unlockWorldLevel,
                lastSetWorldLevelTs = player.lastSetWorldLevelTs,
                totalGuidCount = player.random.v,
                teamIndex = player.teamIndex,
                unlockedSystems = player.unlockedSystems,
                maxDashEnergy = player.maxDashEnergy,
                curStamina = player.curStamina,
                nextRecoverTime = player.nextRecoverTime,
                noSpawnAnymore = player.noSpawnAnymore,
                scenes = player.sceneManager.scenes,
                bitsets = player.bitsetManager.bitsets,
                savedSafeZone = player.savedSaveZone,
                personalData = player.personalData,
                gender = player.gender,
                bag = player.inventoryManager.items.bag,
                nextDailyReset = player.nextDailyReset,
                clientSetting = player.clientSetting
            };
            UpsertPlayerData(data);
        }
        public (string, int) CreateAccount(string username, string? uid)
        {
            Account exist = GetAccountByUsername(username);
            if (exist != null)
            {
                Logger.Print($"Cannot created account with username: {username} beecause it already exist.");
                return ($"Cannot created account with username: {username} beecause it already exist.", 1);
            }
            // check if exist uid.
            if (uid != "" && GetAccountByUid(uid) != null)
            {
                Logger.Print($"Cannot created account with uid: {uid} because it already exist.");
                return ($"Cannot created account with uid: {uid} because it already exist.", 1);
            }
            Account account = new()
            {
                username = username,
                id = uid != "" ? uid : Account.GenerateAccountId(),
                token = GenerateToken(22),
                grantToken = GenerateToken(192)
            };
            UpsertAccount(account);
            Logger.Print($"Account with username: {username} created with Account UID: {account.id}");
            return ($"Account with username: {username} created with Account UID: {account.id}", 0);
        }
        public void UpsertPlayerData(PlayerData player)
        {
            var collection = _database.GetCollection<PlayerData>("players");

            var filter =
                Builders<PlayerData>.Filter.Eq(p => p.roleId, player.roleId)
                &
                Builders<PlayerData>.Filter.Eq(p => p.accountId, player.accountId);

            collection.ReplaceOne(
                filter,
                player,
                new ReplaceOptions { IsUpsert = true }
            );
        }
        public void UpsertMissionData(MissionData data)
        {
            var collection = _database.GetCollection<MissionData>("missionsData");

            var filter =
                Builders<MissionData>.Filter.Eq(p => p.roleId, data.roleId);

            collection.ReplaceOne(
                filter,
                data,
                new ReplaceOptions { IsUpsert = true }
            );
        }
        public void UpsertAccount(Account player)
        {
            var collection = _database.GetCollection<Account>("accounts");

            var filter =
                Builders<Account>.Filter.Eq(p => p.id, player.id)
                &
                Builders<Account>.Filter.Eq(p => p.token, player.token);

            collection.ReplaceOne(
                 filter,
                 player,
                 new ReplaceOptions { IsUpsert = true }
             );
        }
        public void UpsertSpaceshipChar(SpaceshipChar character)
        {
            if (character._id == ObjectId.Empty)
            {
                character._id = ObjectId.GenerateNewId();
            }
            var collection = _database.GetCollection<SpaceshipChar>("spaceship_chars");

            var filter =
                Builders<SpaceshipChar>.Filter.Eq(c => c.id, character.id)
                &
                Builders<SpaceshipChar>.Filter.Eq(c => c.owner, character.owner);

            var result = collection.ReplaceOne(
                filter,
                character,
                new ReplaceOptions { IsUpsert = true }
            );
        }
        public void UpsertSpaceshipRoom(SpaceshipRoom room)
        {
            if (room._id == ObjectId.Empty)
            {
                room._id = ObjectId.GenerateNewId();
            }
            var collection = _database.GetCollection<SpaceshipRoom>("spaceship_rooms");

            var filter =
                Builders<SpaceshipRoom>.Filter.Eq(c => c.id, room.id)
                &
                Builders<SpaceshipRoom>.Filter.Eq(c => c.owner, room.owner);

            var result = collection.ReplaceOne(
                filter,
                room,
                new ReplaceOptions { IsUpsert = true }
            );
        }
        public void UpsertBPPlayerData(BattlePassPlayerData data)
        {
            if (data._id == ObjectId.Empty)
            {
                data._id = ObjectId.GenerateNewId();
            }
            var collection = _database.GetCollection<BattlePassPlayerData>("battlePassData");

            var filter =
                Builders<BattlePassPlayerData>.Filter.Eq(c => c.roleId, data.roleId) &
                Builders<BattlePassPlayerData>.Filter.Eq(c => c.seasonId, data.seasonId);

            var result = collection.ReplaceOne(
                filter,
                data,
                new ReplaceOptions { IsUpsert = true }
            );
        }
        public void UpsertAdventureBookData(AdventureBookManager.AdventureBookData data)
        {
            if (data._id == ObjectId.Empty)
            {
                data._id = ObjectId.GenerateNewId();
            }
            var collection = _database.GetCollection<AdventureBookManager.AdventureBookData>("adventureBookData");

            var filter =
                Builders<AdventureBookManager.AdventureBookData>.Filter.Eq(c => c.roleId, data.roleId);

            var result = collection.ReplaceOne(
                filter,
                data,
                new ReplaceOptions { IsUpsert = true }
            );
        }
        public void UpsertCharacter(Character character)
        {
            if (character._id == ObjectId.Empty)
            {
                character._id = ObjectId.GenerateNewId();
            }
            var collection = _database.GetCollection<Character>("avatars");

            var filter =
                Builders<Character>.Filter.Eq(c => c.guid, character.guid)
                &
                Builders<Character>.Filter.Eq(c => c.owner, character.owner);

            var result = collection.ReplaceOne(
                filter,
                character,
                new ReplaceOptions { IsUpsert = true }
            );
        }
        public void UpsertMail(Mail mail)
        {
            if (mail._id == ObjectId.Empty)
            {
                mail._id = ObjectId.GenerateNewId();
            }
            var collection = _database.GetCollection<Mail>("mails");

            var filter =
                Builders<Mail>.Filter.Eq(c => c.guid, mail.guid)
                &
                Builders<Mail>.Filter.Eq(c => c.owner, mail.owner);

            var result = collection.ReplaceOne(
                filter,
                mail,
                new ReplaceOptions { IsUpsert = true }
            );
        }
        public void UpsertFactoryData(FactoryData item)
        {
            var collection = _database.GetCollection<FactoryData>("factory");

            // Find existing FactoryData by roleId to preserve _id
            // This prevents MongoDB error about immutable _id field when replacing
            var filter = Builders<FactoryData>.Filter.Eq(c => c.roleId, item.roleId);
            FactoryData existingData = collection.Find(filter).FirstOrDefault();

            if (existingData != null)
            {
                // Preserve the existing _id from database to avoid MongoDB error about immutable field
                item._id = existingData._id;
            }
            else if (item._id == ObjectId.Empty)
            {
                // Only generate new _id if FactoryData doesn't exist and _id is empty
                item._id = ObjectId.GenerateNewId();
            }

            var result = collection.ReplaceOne(
                filter,
                item,
                new ReplaceOptions { IsUpsert = true }
            );
        }
        public void UpsertMapMarkData(MapMarkData data)
        {
            var collection = _database.GetCollection<MapMarkData>("mapMarkData");

            var filter = Builders<MapMarkData>.Filter.Eq(c => c.roleId, data.roleId);

            var result = collection.ReplaceOne(
                filter,
                data,
                new ReplaceOptions { IsUpsert = true }
            );
        }
        public void UpsertItem(Item item)
        {
            var collection = _database.GetCollection<Item>("items");

            // If item already has a valid _id, try to find it by _id first
            Item existingItem = null;
            if (item._id != ObjectId.Empty)
            {
                var idFilter = Builders<Item>.Filter.Eq(c => c._id, item._id);
                existingItem = collection.Find(idFilter).FirstOrDefault();
            }

            // If not found by _id, try to find by guid and owner
            if (existingItem == null)
            {
                var guidOwnerFilter =
                    Builders<Item>.Filter.Eq(c => c.guid, item.guid)
                    &
                    Builders<Item>.Filter.Eq(c => c.owner, item.owner);
                existingItem = collection.Find(guidOwnerFilter).FirstOrDefault();
            }

            // Set _id based on what we found
            if (existingItem != null)
            {
                // Preserve the existing _id from database to avoid MongoDB error about immutable field
                item._id = existingItem._id;
            }
            else if (item._id == ObjectId.Empty)
            {
                // Only generate new _id if item doesn't exist and _id is empty
                item._id = ObjectId.GenerateNewId();
            }

            // Use guid and owner filter for ReplaceOne (this is the unique identifier for items)
            var replaceFilter =
                Builders<Item>.Filter.Eq(c => c.guid, item.guid)
                &
                Builders<Item>.Filter.Eq(c => c.owner, item.owner);

            var result = collection.ReplaceOne(
                replaceFilter,
                item,
                new ReplaceOptions { IsUpsert = true }
            );

        }
        public void DeleteItem(Item item)
        {

            var collection = _database.GetCollection<Item>("items");

            var filter =
                Builders<Item>.Filter.Eq(c => c.guid, item.guid)
                &
                Builders<Item>.Filter.Eq(c => c.owner, item.owner);

            var result = collection.DeleteOne(
                filter
            );
        }
        public void DeleteCharacter(Character character)
        {

            var collection = _database.GetCollection<Character>("avatars");

            var filter =
                Builders<Character>.Filter.Eq(c => c.guid, character.guid)
                &
                Builders<Character>.Filter.Eq(c => c.owner, character.owner);

            var result = collection.DeleteOne(
                filter
            );
        }
        public string GrantCode(Account account)
        {
            account.grantToken = GenerateToken(192);
            UpsertAccount(account);
            return account.grantToken;
        }
        public Account GetAccountByToken(string token)
        {
            try
            {
                return _database.GetCollection<Account>("accounts").Find(p => p.token == token).ToList().FirstOrDefault();
            }
            catch (Exception e)
            {
                Logger.PrintError("Error: " + e.Message);
                return null;
            }
        }
        public Account GetAccountByUid(string uid)
        {
            try
            {
                return _database.GetCollection<Account>("accounts").Find(p => p.id == uid).ToList().FirstOrDefault();
            }
            catch (Exception e)
            {
                Logger.PrintError("Error: " + e.Message);
                return null;
            }
        }
        public Account GetAccountByTokenGrant(string token)
        {
            if (Server.config.gameServer.useExternalAuthSdk)
            {
                //TODO get account info from external auth sdk
                return null;
            }
            try
            {
                return _database.GetCollection<Account>("accounts").Find(p => p.grantToken == token).ToList().FirstOrDefault();
            }
            catch (Exception e)
            {
                Logger.PrintError("Error: " + e.Message);
                return null;
            }
        }
        public Account GetAccountByUsername(string username)
        {
            try
            {
                return _database.GetCollection<Account>("accounts").Find(p => p.username == username).ToList().FirstOrDefault();
            }
            catch (Exception e)
            {
                Logger.PrintError("Error: " + e.Message);
                return null;
            }
        }
        public PlayerData GetPlayerById(string id)
        {
            try
            {
                return _database.GetCollection<PlayerData>("players").Find(p => p.accountId == id).ToList().FirstOrDefault();
            }
            catch (Exception e)
            {
                Logger.PrintError("Error occured while loading Player with account id: " + id + " ERROR:\n" + e.Message);
                return null;
            }
        }

        /// <summary>
        /// Reset account by deleting all player data associated with the account.
        /// This will delete: player data, characters, items, spaceship data, mails,
        /// mission data, adventure book data, and factory data, but keeps the account itself.
        /// After reset, the account will behave exactly as a fresh account on next login,
        /// with all systems initialized from clean state.
        /// </summary>
        public bool ResetAccount(string accountId)
        {
            try
            {
                // Get player data first to find roleId
                PlayerData? playerData = GetPlayerById(accountId);
                if (playerData == null)
                {
                    Logger.PrintWarn($"Cannot reset account {accountId}: No player data found.");
                    return false;
                }

                ulong roleId = playerData.roleId;
                int deletedCount = 0;

                // Delete player data
                // Note: Filter by roleId to ensure correct deletion since roleId is [BsonId] (MongoDB _id)
                var playerFilter = Builders<PlayerData>.Filter.Eq(p => p.roleId, roleId);
                var playerCollection = _database.GetCollection<PlayerData>("players");
                var playerResult = playerCollection.DeleteOne(playerFilter);
                deletedCount += (int)playerResult.DeletedCount;
                Logger.Print($"Reset account {accountId}: Deleted {playerResult.DeletedCount} player data record(s).");

                // Delete characters (avatars)
                var charsCollection = _database.GetCollection<Character>("avatars");
                var charsFilter = Builders<Character>.Filter.Eq(c => c.owner, roleId);
                var charsResult = charsCollection.DeleteMany(charsFilter);
                deletedCount += (int)charsResult.DeletedCount;
                Logger.Print($"Reset account {accountId}: Deleted {charsResult.DeletedCount} character record(s).");

                // Delete items
                var itemsCollection = _database.GetCollection<Item>("items");
                var itemsFilter = Builders<Item>.Filter.Eq(i => i.owner, roleId);
                var itemsResult = itemsCollection.DeleteMany(itemsFilter);
                deletedCount += (int)itemsResult.DeletedCount;
                Logger.Print($"Reset account {accountId}: Deleted {itemsResult.DeletedCount} item record(s).");

                // Delete spaceship chars
                var spaceshipCharsCollection = _database.GetCollection<SpaceshipChar>("spaceship_chars");
                var spaceshipCharsFilter = Builders<SpaceshipChar>.Filter.Eq(c => c.owner, roleId);
                var spaceshipCharsResult = spaceshipCharsCollection.DeleteMany(spaceshipCharsFilter);
                deletedCount += (int)spaceshipCharsResult.DeletedCount;
                Logger.Print($"Reset account {accountId}: Deleted {spaceshipCharsResult.DeletedCount} spaceship character record(s).");

                // Delete spaceship rooms
                var spaceshipRoomsCollection = _database.GetCollection<SpaceshipRoom>("spaceship_rooms");
                var spaceshipRoomsFilter = Builders<SpaceshipRoom>.Filter.Eq(r => r.owner, roleId);
                var spaceshipRoomsResult = spaceshipRoomsCollection.DeleteMany(spaceshipRoomsFilter);
                deletedCount += (int)spaceshipRoomsResult.DeletedCount;
                Logger.Print($"Reset account {accountId}: Deleted {spaceshipRoomsResult.DeletedCount} spaceship room record(s).");

                // Delete mails
                var mailsCollection = _database.GetCollection<Mail>("mails");
                var mailsFilter = Builders<Mail>.Filter.Eq(m => m.owner, roleId);
                var mailsResult = mailsCollection.DeleteMany(mailsFilter);
                deletedCount += (int)mailsResult.DeletedCount;
                Logger.Print($"Reset account {accountId}: Deleted {mailsResult.DeletedCount} mail record(s).");

                // Delete mission data
                var missionsCollection = _database.GetCollection<MissionData>("missionsData");
                var missionsFilter = Builders<MissionData>.Filter.Eq(m => m.roleId, roleId);
                var missionsResult = missionsCollection.DeleteMany(missionsFilter);
                deletedCount += (int)missionsResult.DeletedCount;
                Logger.Print($"Reset account {accountId}: Deleted {missionsResult.DeletedCount} mission data record(s).");

                // Delete adventure book data
                var adventureBookCollection = _database.GetCollection<AdventureBookData>("adventureBookData");
                var adventureBookFilter = Builders<AdventureBookData>.Filter.Eq(a => a.roleId, roleId);
                var adventureBookResult = adventureBookCollection.DeleteMany(adventureBookFilter);
                deletedCount += (int)adventureBookResult.DeletedCount;
                Logger.Print($"Reset account {accountId}: Deleted {adventureBookResult.DeletedCount} adventure book data record(s).");

                // Delete factory data
                var factoryCollection = _database.GetCollection<FactoryData>("factory");
                var factoryFilter = Builders<FactoryData>.Filter.Eq(f => f.roleId, roleId);
                var factoryResult = factoryCollection.DeleteMany(factoryFilter);
                deletedCount += (int)factoryResult.DeletedCount;
                Logger.Print($"Reset account {accountId}: Deleted {factoryResult.DeletedCount} factory data record(s).");

                var battlePassCollection = _database.GetCollection<BattlePassPlayerData>("battlePassData");
                var battlePassFilter = Builders<BattlePassPlayerData>.Filter.Eq(a => a.roleId, roleId);
                var battlePassResult = battlePassCollection.DeleteMany(battlePassFilter);
                deletedCount += (int)battlePassResult.DeletedCount;
                Logger.Print($"Reset account {accountId}: Deleted {battlePassResult.DeletedCount} battle pass data record(s).");


                // Note: We don't delete gacha transactions as they are historical records
                // and might be needed for analytics or recovery

                Logger.Print($"Reset account {accountId} completed: Total {deletedCount} record(s) deleted. Account will be treated as fresh on next login.");
                return true;
            }
            catch (Exception e)
            {
                Logger.PrintError($"Error occurred while resetting account {accountId}: {e.Message}");
                Logger.PrintError($"Stack trace: {e.StackTrace}");
                return false;
            }
        }

        /// <summary>
        /// Delete account by account ID.
        /// </summary>
        public bool DeleteAccount(string accountId)
        {
            try
            {
                var accountFilter = Builders<Account>.Filter.Eq(a => a.id, accountId);
                var accountCollection = _database.GetCollection<Account>("accounts");
                var accountResult = accountCollection.DeleteOne(accountFilter);

                if (accountResult.DeletedCount > 0)
                {
                    Logger.Print($"Account {accountId} completely deleted from database.");
                    return true;
                }
                else
                {
                    Logger.PrintWarn($"Account {accountId} not found in accounts collection.");
                    return false;
                }
            }
            catch (Exception e)
            {
                Logger.PrintError($"Error occurred while deleting account {accountId}: {e.Message}");
                Logger.PrintError($"Stack trace: {e.StackTrace}");
                return false;
            }
        }


    }
}
