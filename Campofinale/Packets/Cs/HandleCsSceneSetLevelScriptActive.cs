using Campofinale.Game.Char;
using Campofinale.Game.Entities;
using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using Campofinale.Resource.Json;
using StardustUtils;
using System.Net.Sockets;
using static Campofinale.Resource.ResourceManager.LevelScene.LevelData;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneSetLevelScriptActive
    {
        [Server.Handler(CsMsgId.CsSceneSetLevelScriptActive)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneSetLevelScriptActive req = packet.DecodeBody<CsSceneSetLevelScriptActive>();
            LevelScriptData data = ResourceManager.GetLevelData(session.curSceneNumId).levelData.levelScripts.Find(s=>s.scriptId==req.ScriptId);
            if (data != null)
            if (data.refGameId != null && session.currentDungeon != null)
            {
                if (session.currentDungeon.table.dungeonId != data.refGameId)
                {
                    return;
                }
            }
            var sceneScript = session.sceneManager.GetCurScene().scripts.Find(s => s.scriptId == req.ScriptId);

            if (sceneScript != null)
            {
                
                if (req.IsActive)
                {
                    sceneScript.state = 3;
                }
                else
                {
                    sceneScript.state = 2;
                }
                ScSceneLevelScriptStateNotify rsp = new ScSceneLevelScriptStateNotify()
                {
                    SceneNumId = req.SceneNumId,
                    ScriptId = req.ScriptId,

                    State = sceneScript.state
                };

                if (!session.sceneManager.GetCurScene().activeScripts.Contains(req.ScriptId))
                {
                    session.sceneManager.GetCurScene().activeScripts.Add(req.ScriptId);
                    session.sceneManager.GetCurScene().UpdateShowEntities();
                }
                session.Send(ScMsgId.ScSceneLevelScriptStateNotify, rsp,packet.csHead.UpSeqid);
                session.Send(ScMsgId.ScSceneLevelScriptStageChange, new ScSceneLevelScriptStageChange()
                {
                    SceneNumId = req.SceneNumId,
                    ScriptId = req.ScriptId,
                    Stage=0
                });
            }


        }

        [Server.Handler(CsMsgId.CsSceneSetLevelScriptStart)]
        public static void HandleCsSceneSetLevelScriptStart(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneSetLevelScriptStart req = packet.DecodeBody<CsSceneSetLevelScriptStart>();
            LevelScriptData data = ResourceManager.GetLevelData(session.curSceneNumId).levelData.levelScripts.Find(s => s.scriptId == req.ScriptId);
            if(data!=null)
            if (data.refGameId != null && session.currentDungeon != null)
            {
                if (session.currentDungeon.table.dungeonId != data.refGameId)
                {
                    return;
                }
            }
            var sceneScript = session.sceneManager.GetCurScene().scripts.Find(s => s.scriptId == req.ScriptId);
            if (sceneScript != null)
            {
                
               
                if (req.IsStart)
                {
                    sceneScript.state = 4;
                }
                else
                {
                    sceneScript.state = 3;
                }
                ScSceneLevelScriptStateNotify rsp = new ScSceneLevelScriptStateNotify()
                {
                    SceneNumId = req.SceneNumId,
                    ScriptId = req.ScriptId,

                    State = sceneScript.state,
                    
                };
                session.Send(ScMsgId.ScSceneLevelScriptStateNotify, rsp,packet.csHead.UpSeqid);
            }
            


        }
        
        public static void ExecuteEventAction(Player player, ScriptAction action, CsSceneLevelScriptEventTrigger req)
        {
            switch (action.action)
            {
                case ScriptActionType.CompleteQuest:
                    player.missionSystem.CompleteQuest(action.valueStr[0]);
                    break;
                case ScriptActionType.ProcessQuest:
                    player.missionSystem.ProcessQuest(action.valueStr[0]);
                    break;
                case ScriptActionType.SpawnEnemy:
                    foreach (ulong id in action.valueUlong)
                    {
                        player.sceneManager.GetCurScene().SpawnEnemy(id,true);
                    }
                    
                    break;
                case ScriptActionType.SpawnEnemyByScriptId:
                    foreach(ulong id in action.valueUlong)
                    {
                        player.sceneManager.GetCurScene().SpawnEnemyByScriptId(id);
                    }
                    break;
                case ScriptActionType.UnlockSystem:
                    UnlockSystemType type = (UnlockSystemType)Enum.Parse(typeof(UnlockSystemType), action.valueStr[0]);
                    player.UnlockSystem(type);
                    break;
                case ScriptActionType.EnterScene:
                    player.EnterScene((int)action.valueUlong[0]);
                    break;
                case ScriptActionType.CompleteMission:
                    player.missionSystem.CompleteMission(action.valueStr[0]);
                    break;
                case ScriptActionType.AddMission:
                    player.missionSystem.AddMission(action.valueStr[0],MissionState.Processing,true);
                    if(action.valueUlong !=null)
                    if(action.valueUlong.Length > 0)
                    {
                        
                        player.missionSystem.TrackMission(action.valueStr[0]);
                    }
                    break;
                case ScriptActionType.StartSpawner:

                    ScSceneMonsterSpawnerStart start = new()
                    {
                        SceneNumId = player.curSceneNumId,
                        SpawnerId = action.valueUlong[0],

                    };
                    player.Send(ScMsgId.ScSceneMonsterSpawnerStart,start);
                    break;
                case ScriptActionType.AddCharacter:
                    Character chara =player.AddCharacter(action.valueStr[0],(int) action.valueUlong[0],true);
                    player.AddToTeam(player.teamIndex, chara.guid);
                    break;
                case ScriptActionType.ChangeScriptPropertyBool:
                    int i = 0;
                    ScSceneUpdateLevelScriptProperty update1 = new()
                    {
                        SceneNumId = req.SceneNumId,
                        ScriptId = req.ScriptId,
                        
                    };
                    foreach (string keyId in action.valueStr)
                    {
                        long val = (long)action.valueUlong[i];
                       
                        LevelScriptData levelscript = ResourceManager.GetLevelData(player.curSceneNumId).levelData.levelScripts.Find(l => l.scriptId == req.ScriptId);
                        if (levelscript != null)
                        {
                            int key = levelscript.GetPropertyId(keyId, new List<int>());
                            ParamKeyValue v = new()
                            {
                                key = keyId,
                                value = new ParamKeyValue.ParamValue()
                                {
                                    type = ParamRealType.Bool,
                                    valueArray = new[]
                                    {
                                        new ParamKeyValue.ParamValueAtom()
                                        {
                                            valueBit64=val,
                                            
                                        }
                                    }
                                }
                            };
                            update1.Properties.Add(key, v.ToProto());
                        }
                        
                        i++;
                        
                    }
                    player.Send(ScMsgId.ScSceneUpdateLevelScriptProperty, update1);
                    break;
                case ScriptActionType.StartScript:
                    foreach (ulong id in action.valueUlong)
                    {
                        
                        ScSceneLevelScriptStateNotify rsp = new ScSceneLevelScriptStateNotify()
                        {
                            SceneNumId = req.SceneNumId,
                            ScriptId = id,

                            State = 4
                        };

                        player.Send(ScMsgId.ScSceneLevelScriptStateNotify, rsp);
                    }
                    break;
                case ScriptActionType.CallClientEvent:
                    foreach(string id in action.valueStr)
                    {
                        LevelScriptData levelscript = ResourceManager.GetLevelData(player.curSceneNumId).levelData.levelScripts.Find(l => l.actionMap.dataMap.headerList.Any(h=>h._eventKey.constValue==id));
                        if(action.valueUlong.Count() > 0)
                        {
                            levelscript = ResourceManager.GetLevelData(player.curSceneNumId).levelData.levelScripts.Find(l => l.scriptId== action.valueUlong[0]);
                        }
                        ScSceneTriggerClientLevelScriptEvent trigger = new()
                        {
                            EventName = id,
                            SceneNumId = req.SceneNumId,
                            ScriptId = levelscript== null ? req.ScriptId : levelscript.scriptId,
                        };

                        player.Send(ScMsgId.ScSceneTriggerClientLevelScriptEvent, trigger);
                    }
                    break;
                default:
                    Logger.PrintWarn("Script Action not implemented");
                    break;
            }
        }
        [Server.Handler(CsMsgId.CsSceneLevelScriptEventTrigger)]
        public static void HandleCsSceneLevelScriptEventTrigger(Player session, CsMsgId cmdId, Packet packet)
        {
            
            CsSceneLevelScriptEventTrigger req = packet.DecodeBody<CsSceneLevelScriptEventTrigger>();
            Logger.Print(req.Properties.ToString());
           
            if (ResourceManager.levelScriptsEvents.TryGetValue(req.EventName, out LevelScriptEvent levelScriptEvent))
            {
                Logger.Print($"Event {req.EventName.Pastel(ConsoleColor.Yellow)} Executed.");
                Logger.Print($"{levelScriptEvent.comment}");
                levelScriptEvent.actions.ForEach(a =>
                {
                    ExecuteEventAction(session, a,req);
                });
            }
            else
            {
                Logger.PrintWarn($"Event {req.EventName.Pastel(ConsoleColor.White)} is NOT implemented. INFO: [");
                Logger.PrintWarn($" Scene: {req.SceneNumId.ToString().Pastel(ConsoleColor.White)}, Pos: {session.position.ToProto().ToString()} ");
                Logger.PrintWarn($" ScriptID: {req.ScriptId.ToString().Pastel(ConsoleColor.White)} ");
                Logger.PrintWarn($"]");
            }

            ScSceneUpdateLevelScriptProperty update1 = new()
            {
                SceneNumId = req.SceneNumId,
                ScriptId = req.ScriptId,
               
            };
            LevelScriptData levelscript= ResourceManager.GetLevelData(session.curSceneNumId).levelData.levelScripts.Find(l=>l.scriptId == req.ScriptId);
            var sceneScript = session.sceneManager.GetCurScene().scripts.Find(s => s.scriptId == req.ScriptId);
            
            if (levelscript != null && sceneScript != null) {
                foreach (var item in req.Properties)
                {
                    int key = levelscript.GetPropertyId(item.Key, new List<int>());

                    sceneScript.properties[item.Key] = new ScriptProperty(item.Value);
                    update1.Properties.Add(key, item.Value);
                }
            }
            session.Send(ScMsgId.ScSceneUpdateLevelScriptProperty, update1);
            
            /*ScSceneUpdateLevelScriptProperty update2 = new()
            {
                SceneNumId = req.SceneNumId,
                ScriptId = req.ScriptId,
                

            };
            session.Send(ScMsgId.ScSceneUpdateLevelScriptProperty, update2);*/
            ScSceneLevelScriptEventTrigger rsp = new ScSceneLevelScriptEventTrigger()
            {
                
            };
            
            session.Send(ScMsgId.ScSceneLevelScriptEventTrigger, rsp,packet.csHead.UpSeqid);

        }
    }
}