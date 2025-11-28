using BeyondTools.VFS.Crypto;
using Campofinale.Database;
using Campofinale.Game;
using Campofinale.Game.Char;
using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using System.Security.Cryptography;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Cs
{
    public class HandleCsLogin
    {
        [Server.Handler(CsMsgId.CsSetGender)]
        public static void HandleCsSetGender(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSetGender req = packet.DecodeBody<CsSetGender>();
            if(session.chars.Count < 2)
            {
                if (req.Gender == Gender.GenMale)
                {
                    session.AddCharacter("chr_0002_endminm", true);
                    session.RemoveCharacter("chr_0003_endminf");
                }
                else
                {
                    session.AddCharacter("chr_0003_endminf", true);
                    session.RemoveCharacter("chr_0002_endminm");
                }
                
                session.teamIndex = 0;
                session.teams[0].leader = session.chars[0].guid;
                session.teams[0].members = new() { session.chars[0].guid };
                ScCharBagSetTeam setTeam = new()
                {
                    CharTeam = { session.teams[0].members },
                    LeaderId = session.teams[0].leader,
                    ScopeName = 1,
                    TeamIndex = 0,
                    TeamType = CharBagTeamType.Main,
                };
                
                session.Send(ScMsgId.ScCharBagSetTeam, setTeam);
                session.Send(new PacketScCharBagSetCurrTeamIndex(session));
                
                session.Send(new PacketScSelfSceneInfo(session,SelfInfoReasonType.SlrChangeTeam));
            }
            
            ScSetGender rsp = new()
            {
                Gender = req.Gender,
            };
            session.gender = rsp.Gender;
            
            session.Send(ScMsgId.ScSetGender, rsp);
            
        }
        [Server.Handler(CsMsgId.CsLogin)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsLogin req = packet.DecodeBody<CsLogin>();
            if(Server.clients.Count > Server.config.serverOptions.maxPlayers)
            {
                session.Send(ScMsgId.ScNtfErrorCode, new ScNtfErrorCode()
                {
                    Details = "Server Full",
                    ErrorCode = (int)CODE.ErrCommonServerOverload,
                });
                session.Disconnect();
                return;
            }
            Account account = DatabaseManager.db.GetAccountByTokenGrant(req.Token);
            if (account==null)
            {
                session.Send(ScMsgId.ScNtfErrorCode, new ScNtfErrorCode()
                {
                    Details = "Auth Error",
                    ErrorCode = (int)CODE.ErrLoginProcessLogin,
                });
                session.Disconnect();
                return;
            }
            ScLogin rsp = new()
            {
               
                Uid = req.Uid,
                IsFirstLogin = false,
                IsReconnect=false,
                LastRecvUpSeqid = packet.csHead.UpSeqid,
                ServerTimeZone=2,
                ServerTime=DateTime.UtcNow.ToUnixTimestampMilliseconds(),
            };
            byte[] encKey = GenerateRandomBytes(32);
            //string serverPublicKeyPem = req.ClientPublicKey.ToStringUtf8();
           // byte[] serverPublicKey = ConvertPemToBytes(serverPublicKeyPem);
            //byte[] encryptedEncKey = EncryptWithRsa(encKey, serverPublicKey);
            byte[] serverEncrypNonce = GenerateRandomBytes(12);
           // rsp.ServerEncrypNonce = ByteString.CopyFrom(serverEncrypNonce);
           // rsp.ServerPublicKey = ByteString.CopyFrom(encryptedEncKey);
       
           // CSChaCha20 cipher = new CSChaCha20(encKey, serverEncrypNonce, 1);
            if (req.ClientVersion == GameConstants.GAME_VERSION || req.ClientVersion == GameConstants.GAME_VERSION_ANDROID)
            {
                if (account == null)
                {
                    session.Send(ScMsgId.ScNtfErrorCode, new ScNtfErrorCode()
                    {
                        Details = "Account error",
                        ErrorCode = (int)CODE.ErrLoginProcessLogin,
                    });
                    session.Disconnect();
                    return;
                }
                bool exist=session.Load(account.id);
                
                rsp.Uid = ""+session.accountId;
                if (!exist)
                {
                    rsp.IsFirstLogin = true;
                    //session.gender = Gender.GenInvalid;

                    //session.Send(ScMsgId.ScLogin, rsp);
                    //session.Send(new PacketScSyncBaseData(session));
                    //return;
                }
                session.Send(ScMsgId.ScLogin, rsp);
                
            }
            else
            {
                session.Send(ScMsgId.ScNtfErrorCode, new ScNtfErrorCode()
                {
                    Details="Unsupported client version",
                    ErrorCode= (int)CODE.ErrCommonClientVersionNotEqual
                });
                session.Disconnect();
                return;
            }
            session.Send(new PacketScSyncBaseData(session));
            session.Send(ScMsgId.ScSceneClientIdInfo, new ScSceneClientIdInfo()
            {
              RoleIdx=6,
              LastMaxIdx=session.random.v
            });
            session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.Weapon));
            session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.WeaponGem));
            session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.Equip));
            session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.CommercialItem));
            session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.Factory));
            session.Send(new PacketScItemBagScopeSync(session, ItemValuableDepotType.SpecialItem));
            session.Send(new PacketScSyncAllMail(session));
            session.Send(new PacketScSceneCollectionSync(session));
            session.Send(new PacketScSyncAllMission(session));
            session.Send(new PacketScGachaSync(session));
            ScSettlementSyncAll settlements = new ScSettlementSyncAll()
            {
                LastTickTime = DateTime.UtcNow.ToUnixTimestampMilliseconds(),
                
            };
            int stid = 3;
            foreach (var item in settlementBasicDataTable)
            {
                settlements.Settlements.Add(new Settlement()
                {
                    Level = 1,
                    SettlementId = item.Value.settlementId,
                    RequireId = "item_plant_grass_powder_2",
                    Exp = 1,
                    Reports =
                    {

                    },
                    UnlockTs = DateTime.UtcNow.AddHours(1).ToUnixTimestampMilliseconds(),
                    AutoSubmit = false,
                    LastManualSubmitTime = DateTime.UtcNow.ToUnixTimestampMilliseconds(),
                    
                    OfficerCharTemplateId = characterTable.Values.ToList()[stid].charId,

                    
                });
                stid++;
            }
            
            session.Send(ScMsgId.ScSettlementSyncAll, settlements);
            session.Send(new PacketScSyncAllRoleScene(session));
            session.Send(new PacketScGameMechanicsSync(session));
            
            session.Send(new PacketScSyncWallet(session));
            session.Send(new PacketScSyncAllGameVar(session));
            session.Send(new PacketScSyncAllUnlock(session));
            session.Send(new PacketScSyncAllBitset(session));
            session.Send(new PacketScSyncAllMiniGame(session));

            session.Send(new PacketScShopSync(session));
            session.Send(new PacketScAchieveSync(session));
            string json = File.ReadAllText("93_ScSceneMapMarkSync.json");
            ScSceneMapMarkSync chapter = Newtonsoft.Json.JsonConvert.DeserializeObject<ScSceneMapMarkSync>(json);
            session.Send(ScMsgId.ScSceneMapMarkSync, chapter);
            session.Send(new PacketScAdventureBookSync(session));
            session.Send(new PacketScAdventureSyncAll(session));
            session.Send(new PacketScFactorySync(session));
            session.Send(new PacketScFactorySyncScope(session));
            session.Send(new PacketScFactorySyncChapter(session, "domain_1"));
            session.Send(new PacketScFactorySyncChapter(session, "domain_2"));
            session.Send(new PacketScSyncCharBagInfo(session));
            session.Send(new PacketScSyncAllDialog(session));
            session.Send(new PacketScSpaceshipSync(session));
            session.Send(new PacketScSyncFullDungeonStatus(session));
            session.Send(new PacketScActivitySync(session));
            session.Send(ScMsgId.ScDomainDevelopmentSystemSync, new ScDomainDevelopmentSystemSync() {

                Domains =
                {
                    new DomainDevelopment()
                    {
                        ChapterId="domain_1",
                        DevDegree = new()
                        {
                            Level=1,
                            
                        },
                        
                    },
                    new DomainDevelopment()
                    {
                        ChapterId="domain_2",
                        DevDegree = new()
                        {
                            Level=1,

                        },

                    }
                }
            });
            session.Send(ScMsgId.ScSyncAllWiki, new ScSyncAllWiki()
            {
                
            });
            session.Send(ScMsgId.ScPaySyncCashShops, new ScPaySyncCashShops() { ShopMgr=new()});
            session.Send(new PacketScSnsGetChatList(session));
            session.Send(ScMsgId.ScSyncFullDataEnd, new ScSyncFullDataEnd());
            session.Send(new PacketScFriendListSimpleSync(session));
            //session.Send(new PacketScFriendListQuery(session));
            session.Send(new PacketScFriendPersonalDataSync(session));
            session.EnterScene();
            session.Initialized = true;
            session.Update();
            session.adventureBookManager.data.dailyLogin++;
            session.adventureBookManager.TaskUpdate(ConditionType.CheckStatisticVal, null);


        }
        static byte[] GenerateRandomBytes(int length)
        {
            using var rng = new RNGCryptoServiceProvider();
            byte[] bytes = new byte[length];
            rng.GetBytes(bytes);
            return bytes;
        }
        static byte[] ConvertPemToBytes(string pem)
        {
            string base64Key = pem
                .Replace("-----BEGIN PUBLIC KEY-----", "")
                .Replace("-----END PUBLIC KEY-----", "")
                .Replace("\n", "")
                .Replace("\r", "");
            return Convert.FromBase64String(base64Key);
        }

        // Crittografare con RSA (PKCS#1)
        static byte[] EncryptWithRsa(byte[] data, byte[] publicKeyBytes)
        {
            var rsa = RSA.Create();
            rsa.ImportSubjectPublicKeyInfo(publicKeyBytes, out _);
            return rsa.Encrypt(data, RSAEncryptionPadding.Pkcs1);
        }

    }
}
