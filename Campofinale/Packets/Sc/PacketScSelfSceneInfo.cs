using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Sc
{
    public class PacketScSelfSceneInfo : Packet
    {

        public PacketScSelfSceneInfo(Player session, SelfInfoReasonType infoReason = SelfInfoReasonType.SlrEnterScene) {

            ScSelfSceneInfo sceneInfo = new()
            {
                SceneId = session.sceneManager.GetSceneGuid(session.curSceneNumId),
                SceneNumId = session.curSceneNumId,
                SelfInfoReason = (int)infoReason,
                    
                TeamInfo = new()
                {
                    CurLeaderId = session.teams[session.teamIndex].leader,
                    TeamIndex = session.teamIndex,
                    TeamType = CharBagTeamType.Main
                    
                },
                
                
                Detail = new()
                {
                    TeamIndex = session.teamIndex,
                    
                },
                LevelScripts =
                {

                }
            };
            if (session.currentDungeon != null)
            {
                sceneInfo.Dungeon = new()
                {
                    DungeonId = session.currentDungeon.table.dungeonId,
                };
            }
            else
            {
                sceneInfo.Empty = new()
                {
                    
                };
            }
            foreach (var item in ResourceManager.sceneAreaTable)
            {
                if(session.curSceneNumId==ResourceManager.GetSceneNumIdFromLevelData(item.Value.sceneId))
                    sceneInfo.UnlockArea.Add(item.Value.areaId);
            }
            session.teams[session.teamIndex].members.ForEach(m =>
            {
                sceneInfo.Detail.CharList.Add(session.chars.Find(c => c.guid == m).ToSceneProto());
            });

            if (infoReason == SelfInfoReasonType.SlrSeamlesslyEnterScene)
            {
                sceneInfo.TeamInfo = null;
            }
            if(infoReason!= SelfInfoReasonType.SlrChangeTeam)
            ResourceManager.GetLevelData(session.curSceneNumId).levelData.levelScripts.ForEach(l =>
            {
                LevelScriptInfo script = new LevelScriptInfo()
                {
                    ScriptId = l.scriptId,
                    IsDone = false,
                    State = 2,
                    
                };
                var sceneScript=session.sceneManager.GetCurScene().scripts.Find(s => s.scriptId == l.scriptId);
                if (sceneScript == null)
                {
                    sceneScript = new()
                    {
                        scriptId = l.scriptId,
                        
                        state = 2
                    };
                    l.properties.ForEach(p =>
                    {
                        if(!sceneScript.properties.ContainsKey(p.key))
                        sceneScript.properties.Add(p.key,p.ToScriptProperty());
                    });
                    
                    session.sceneManager.GetCurScene().scripts.Add(sceneScript);
                }
                if (Server.config.serverOptions.disableLevelscripts)
                {
                    script.State = 1;
                }
                else
                {
                    script.State = sceneScript.state;
                }
                
                int i = 0;
                foreach (var item in sceneScript.properties)
                {
                   if(item.Value != null)
                   {
                        DynamicParameter p = item.Value.ToProto();
                        if (p != null)
                            script.Properties.Add(l.GetPropertyId(item.Key, script.Properties.Keys.ToList()), p);
                   }
                   
                }
                sceneInfo.LevelScripts.Add(script);
            });
            SetData(ScMsgId.ScSelfSceneInfo, sceneInfo);
            
           
        }

    }
}
