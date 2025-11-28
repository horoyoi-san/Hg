using Campofinale.Game.Entities;
using Campofinale.Game.Inventory;
using Campofinale.Packets.Sc;
using Campofinale.Resource;
using Campofinale.Resource.Dynamic;
using Campofinale.Resource.Table;
using MongoDB.Bson.Serialization.Attributes;
using System;
using System.Diagnostics;
using System.Text.Json.Serialization;
using static Campofinale.Resource.Dynamic.SpawnerConfig;
using static Campofinale.Resource.ResourceManager;
using static Campofinale.Resource.ResourceManager.LevelScene.LevelData;
using static Campofinale.Resource.ResourceManager.LevelScene.LevelData.LevelFunctionAreaData;

namespace Campofinale.Game
{
    public class SceneManager
    {
        public List<Scene> scenes = new List<Scene>();
        public Player player;
        public List<Entity> globalEntities = new List<Entity>();
        public SceneManager(Player player) {
        
            this.player = player;   
            
        }
        public void Update()
        {
            if (GetCurScene() != null)
            {
                try
                {
                    GetCurScene().UpdateShowEntities();
                }
                catch(Exception e)
                {

                }
            }
            
        }
        public Entity GetEntity(ulong guid)
        {
            Scene scene = scenes.Find(s => s.sceneNumId == player.curSceneNumId);
            Entity en = globalEntities.Find(e => e.guid == guid);
            if (en != null)
            {
                return en;
            }
            if (scene != null)
            {
                return scene.entities.Find(e => e.guid == guid);
            }

            return null;
        }
        public void LoadCurrentTeamEntities()
        {
            globalEntities.RemoveAll(e => e is EntityCharacter);
            foreach (Char.Character chara in player.GetCurTeam())
            {
                EntityCharacter ch = new(chara.guid, player.roleId);
                globalEntities.Add(ch);
            }
        }
        public void LoadCurrent()
        {
            Scene curscene = GetCurScene();
            string sceneConfigPath = curscene.info().defaultState.exportedSceneConfigPath;
            foreach(Scene scene in scenes.FindAll(s => s.info().defaultState.exportedSceneConfigPath == sceneConfigPath))
            {
                if (scene != null)
                {
                    scene.Load();
                }
            }
           

        }
        public Scene GetScene(int sceneId)
        {
            return scenes.Find(s=>s.sceneNumId==sceneId);
        }
        public Scene GetCurScene()
        {
            return scenes.Find(s => s.sceneNumId == player.curSceneNumId);
        }
        public void SpawnEntity(Entity entity)
        {

            Scene scene = GetCurScene();

            if (scene != null)
            {
                scene.entities.Add(entity);
                //Spawn packet
                player.Send(new PacketScObjectEnterView(player,new List<Entity>{ entity }));
            }
        }
        public void KillEntity(ulong guid, bool killClient=false, int reason=1)
        {
            Scene scene = GetCurScene();

            if (scene != null)
            {
                Entity entity = GetEntity(guid);
                if (entity != null)
                {
                    entity.OnDie();
                    if (killClient)
                    {
                        ScSceneDestroyEntity destroy = new()
                        {
                            Id = guid,
                            Reason = reason,
                            SceneNumId = GetEntity(guid).sceneNumId,
                        };
                        player.Send(Protocol.ScMsgId.ScSceneDestroyEntity, destroy);
                        
                    }
                    if (entity is EntityMonster monster)
                    {
                        LevelScene lv_scene = ResourceManager.GetLevelData(entity.sceneNumId);
                        LevelEnemyData d = lv_scene.levelData.enemies.Find(l => l.levelLogicId == monster.guid);
                        if (d != null)
                        {
                            if (!d.respawnable)
                            {
                                player.noSpawnAnymore.Add(monster.guid);
                            }
                        }
                    }
                    if (scenes.Find(s => s.sceneNumId == entity.sceneNumId) != null)
                    {
                        scenes.Find(s => s.sceneNumId == entity.sceneNumId).entities.Remove(entity);
                    }
                    
                }
                
            }
        }
        public void CreateDrop(Vector3f pos,ResourceManager.RewardTable.ItemBundle bundle)
        {
            ItemTable info = ResourceManager.itemTable[bundle.id];
            Item item = new Item(player.roleId, info.id, bundle.count);
            EntityInteractive drop = new(info.modelKey, player.roleId, pos, new Vector3f(), GetCurScene().sceneNumId)
            {
                type = (ObjectType)5,
                curHp = 100,
                properties =
                {
                    new ParamKeyValue()
                    {
                        key="is_collected",
                        value = new()
                        {
                            type=ParamRealType.Bool,
                            valueArray=new ParamKeyValue.ParamValueAtom[1]
                            {
                                new ParamKeyValue.ParamValueAtom()
                                {

                                    
                                }
                            }
                        }
                    },
                    new ParamKeyValue()
                    {
                        key="item_id",
                        value = new()
                        {
                            type=ParamRealType.String,
                            valueArray=new ParamKeyValue.ParamValueAtom[1]
                            {
                                new ParamKeyValue.ParamValueAtom()
                                {
                                    
                                    valueString=info.id,
                                }
                            }
                        }
                    },

                }
                
            };
           
            
            drop.properties.Add(new ParamKeyValue()
            {
                key = "count",
                value = new()
                {
                    type = ParamRealType.Int,
                    
                    valueArray = new ParamKeyValue.ParamValueAtom[1]
                    {
                        new ParamKeyValue.ParamValueAtom()
                        {
                            valueBit64=bundle.count
                        }
                    }
                }
            });
            if (item.InstanceType())
            {
                drop.properties.Add(new ParamKeyValue()
                {
                    key = "item_inst",
                    value = new()
                    {
                        type = ParamRealType.String,
                        valueArray = new ParamKeyValue.ParamValueAtom[1]
                        {
                            new ParamKeyValue.ParamValueAtom()
                            {
                                valueString=Newtonsoft.Json.JsonConvert.SerializeObject(item.ToProto().Inst)
                            }
                        }
                    }
                });
            }
            SpawnEntity(drop);
        }
        public ulong GetSceneGuid(int sceneNumId)
        {
            return scenes.Find(s=>s.sceneNumId == sceneNumId).guid;
        }
        public void Load()
        {
            foreach (var level in ResourceManager.levelDatas)
            {
                int grade = 1;
                
                if (scenes.Find(s=>s.sceneNumId==level.idNum) == null)
                scenes.Add(new Scene()
                {
                    guid = (ulong)player.random.Next(),
                    ownerId=player.roleId,
                    sceneNumId=level.idNum,
                    grade= grade
                });
            }
        }

        public void UnloadAllByConfigPath(string sceneConfigPath)
        {
            foreach (Scene scene in scenes.FindAll(s => s.info().defaultState.exportedSceneConfigPath == sceneConfigPath))
            {
                if (scene != null)
                {
                    scene.Unload();
                }
            }
        }
    }
    public class LevelScript
    {
        public ulong scriptId;
        public int state; 
        public Dictionary<string, ScriptProperty> properties = new();
    }
    public class Scene
    {
        public ulong ownerId;
        public ulong guid;
        public int sceneNumId;
        public Dictionary<string, int> collections = new();
        [BsonIgnore,JsonIgnore]
        public List<Entity> entities = new();
        [BsonIgnore, JsonIgnore]
        public List<ulong> activeScripts = new();

        public List<LevelScript> scripts = new();
        public int grade = 1;

        public int GetCollection(string id)
        {
            if (collections.ContainsKey(id))
            {
                return collections[id];
            }
            return 0; 
        }

        public void AddCollection(string id,int amt)
        {
            if (collections.ContainsKey(id))
            {
                collections[id] += amt;
            }
            else
            {
                collections.Add(id, amt);
            }
        }
        public List<Entity> GetEntityExcludingChar()
        {
            return entities.FindAll(c => c is not EntityCharacter);
        }

        public void Unload()
        {
            List<ulong> guids = new();
            foreach(Entity e in GetEntityExcludingChar().FindAll(e => e.spawned))
            {
                guids.Add(e.guid);
                e.spawned = false;
            }
            entities.Clear();
            GetOwner().Send(new PacketScObjectLeaveView(GetOwner(), guids));
        }
        public LevelScene info()
        {
            return levelDatas.Find(l => l.idNum == sceneNumId);
        }
        public void Load()
        {
            if (grade == 0)
            {
                grade = 1;
            }
            Unload();
            LevelScene lv_scene = ResourceManager.GetLevelData(sceneNumId);
            
            LevelGradeInfo sceneGrade = null;
            LevelGradeTable table = null;
            ResourceManager.levelGradeTable.TryGetValue(lv_scene.id, out table);
            if (table != null)
            {
                sceneGrade=table.grades.Find(g=>g.grade==grade);
            }
            if (sceneGrade == null)
            {
                sceneGrade = new();
            }
            lv_scene.levelData.interactives.ForEach(en =>
            {
                if (GetOwner().noSpawnAnymore.Contains(en.levelLogicId) && sceneNumId != 87)
                {
                    return;
                }
                EntityInteractive entity = new(en.entityDataIdKey, ownerId, en.position, en.rotation, sceneNumId, en.levelLogicId)
                {
                    belongLevelScriptId=en.belongLevelScriptId,
                    dependencyGroupId=en.dependencyGroupId,
                    levelLogicId= en.levelLogicId,
                    type = en.entityType,
                    properties= en.properties,
                    componentProperties=en.componentProperties,
                };
                entities.Add(entity);
            });
            lv_scene.levelData.factoryRegions.ForEach(en =>
            {
                if (GetOwner().noSpawnAnymore.Contains(en.levelLogicId) && sceneNumId!=87)
                {
                    return;
                }
                EntityInteractive entity = new(en.entityDataIdKey, ownerId, en.position, en.rotation, sceneNumId, en.levelLogicId)
                {
                    belongLevelScriptId = en.belongLevelScriptId,
                    dependencyGroupId = 0,
                    levelLogicId = en.levelLogicId,
                    type = en.entityType,
                };
                
                entities.Add(entity);
            });
            lv_scene.levelData.enemies.ForEach(en =>
            {
                if(GetOwner().noSpawnAnymore.Contains(en.levelLogicId) && sceneNumId != 87) return;
                
                EntityMonster entity = new(en.entityDataIdKey,sceneGrade.monsterBaseLevel+ en.level,ownerId,en.position,en.rotation, sceneNumId, en.levelLogicId)
                {
                    type=en.entityType,
                    belongLevelScriptId=en.belongLevelScriptId,
                    levelLogicId = en.levelLogicId,
                    
                };
                entity.defaultHide=en.defaultHide;
                entities.Add(entity);
            });
            lv_scene.levelData.npcs.ForEach(en =>
            {
                
                if (en.npcGroupId.Contains("chr") && sceneNumId == 98) return;
                EntityNpc entity = new(en.entityDataIdKey,ownerId,en.position,en.rotation, sceneNumId, en.levelLogicId)
                {
                    belongLevelScriptId = en.belongLevelScriptId,
                    levelLogicId = en.levelLogicId,
                    type = en.entityType,
                    
                };
                entity.defaultHide = en.defaultHide;
                entities.Add(entity);
            });
            GetOwner().factoryManager.chapters.ForEach(ch =>
            {
                ch.nodes.ForEach(n =>
                {
                    if (n.sceneNumId == sceneNumId)
                    {
                        n.SendEntity(GetOwner(), ch.chapterId);
                    }
                });
            });
            UpdateShowEntities();
        }
        
        public void SpawnEntity(Entity en,bool spawnedCheck=true)
        {
            en.spawned = true;
            GetOwner().Send(new PacketScObjectEnterView(GetOwner(), new List<Entity>() { en }));
        }
        public bool GetActiveScript(ulong id)
        {
            LevelScript script = scripts.Find(s => s.scriptId == id);
            if (script != null)
            {
                return script.state > 2;
            }
            else
            {
                return true;
            }
        }

        //Bug on scene 101: spawning entities in this way make the game break if you try to load another scene from scene 101
        public async void UpdateShowEntities()
        {
            List<Entity> toSpawn = new();
            List<Entity> toCheck = GetEntityExcludingChar().FindAll(e => e.spawned == false);
            toCheck.Sort((a, b) => a.Position.Distance(GetOwner().position).CompareTo(b.Position.Distance(GetOwner().position)));
            foreach (Entity e in toCheck)
            {
                if(e.Position.Distance(GetOwner().position) > 300 && sceneNumId != 87)
                {
                    continue;
                }
                if(e.spawned==false)
                {
                    if (!e.defaultHide)
                    {
                        if (GetActiveScript(e.belongLevelScriptId))
                        {
                            toSpawn.Add(e);
                            e.spawned = true;
                        }
                    }
                    
                }
                
            }
            if (toSpawn.Count > 0)
            {
                for (int i = 0; i < toSpawn.Count; i += 5)
                {
                    int chunkSize = Math.Min(5, toSpawn.Count - i);
                    var chunk = toSpawn.GetRange(i, chunkSize);
                    
                    GetOwner().Send(new PacketScObjectEnterView(GetOwner(), chunk));
                }
            }
        }

        public Player GetOwner()
        {
            return Server.clients.Find(c => c.roleId == ownerId);
        }
        public void SpawnEnemyByScriptId(ulong id)
        {
            GetEntityExcludingChar().FindAll(e => e.belongLevelScriptId == id).ForEach(e =>
            {
                e.spawned = true;
            });
            GetOwner().Send(new PacketScObjectEnterView(GetOwner(), GetEntityExcludingChar().FindAll(e => e.belongLevelScriptId == id)));
        }
        public void SpawnEnemy(ulong v, bool scriptSpawn=false)
        {
            LevelScene lv_scene = ResourceManager.GetLevelData(sceneNumId);
            LevelEnemyData en = lv_scene.levelData.enemies.Find(e=>e.levelLogicId == v);
            if(en!=null)
            {
                EntityMonster entity = new(en.entityDataIdKey, en.level, ownerId, en.position, en.rotation, sceneNumId, en.levelLogicId)
                {
                    type = en.entityType,
                    belongLevelScriptId = en.belongLevelScriptId,
                    levelLogicId = en.levelLogicId,
                };
                entities.Add(entity);
                Logger.Print($"Enemy Id {v} found on scene {sceneNumId}:{lv_scene.mapIdStr}");
                SpawnEntity(entity);
            }
            else
            {
                Logger.PrintWarn($"Enemy Id {v} not found on scene {sceneNumId}:{lv_scene.mapIdStr}");
            }
        }

        public void SpawnWaveEnemy(ulong spawnerId, int waveId)
        {
            LevelSpawnerData data=info().levelData.spawners.Find(s => s.spawnerId == spawnerId);
            if (data!=null)
            {
                SpawnerConfig config = spawnerConfigs.Find(s => s.configId == data.configId);
                if (config != null)
                {
                    foreach(var group in config.waveMap[$"{waveId}"].groupMap.Values)
                    {
                        foreach (var act in group.actionMap.Values)
                        {
                            EnemyLibraryData enemyData = config.enemyLibrary.Find(e=>e.key==act.libraryKey);
                            if (enemyData != null)
                            {
                                entities.Add(new EntityMonster(enemyData.enemyId, enemyData.enemyLevel, ownerId, act.position, act.rotation, sceneNumId)
                                {
                                    
                                    defaultHide = false,
                                    spawned = false,
                                    belongLevelScriptId = data.belongLevelScriptId
                                });
                            }
                            
                        }
                    }
                }
            }
        }
    }
}
