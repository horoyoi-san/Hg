using Campofinale.Game.Entities;
using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using StardustUtils;
using System;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneInteractSpInteractive
    {

        [Server.Handler(CsMsgId.CsSceneInteractSpInteractive)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneInteractSpInteractive req = packet.DecodeBody<CsSceneInteractSpInteractive>();
            Entity entity = session.sceneManager.GetEntity(req.ObjId);
            if (entity != null)
            {
                LevelScene scene = ResourceManager.GetLevelData(entity.sceneNumId);
                switch (req.OpType)
                {
                    case SpInteractiveOpType.DefaultInteract:
                    case SpInteractiveOpType.SetState:
                        try
                        {
                            session.bitsetManager.AddValue(BitsetType.InteractiveTwoState, ResourceManager.levelShortIdTable[scene.id].ids[(long)entity.guid]);
                        }
                        catch (Exception e)
                        {
                            Logger.PrintError(e.Message);
                        }
                        try
                        {
                            session.bitsetManager.AddValue(BitsetType.InteractiveActive, ResourceManager.levelShortIdTable[scene.id].ids[(long)entity.guid]);
                        }
                        catch(Exception e)
                        {
                            Logger.PrintError(e.Message);
                        }
                        
                        break;
                    
                    case SpInteractiveOpType.PickDropPackItem:
                        EntityInteractive interactive = entity as EntityInteractive;
                        if (interactive.templateId== "int_doodad_flower_2")
                        {
                            session.inventoryManager.AddRewards("reward_doodad_moss_3", interactive.Position, 1);
                        }
                        if (interactive.templateId == "int_doodad_flower_1")
                        {
                            session.inventoryManager.AddRewards("reward_doodad_moss_3", interactive.Position, 1);
                        }
                        session.sceneManager.KillEntity(interactive.guid, true, 1);
                        break;
                    default:
                        Logger.PrintWarn($"Unimplemented SpInteractiveOpType.{(SpInteractiveOpType)req.OpType}");
                        break;
                }
                session.Send(new PacketScSyncAllBitset(session));
                ScSceneInteractSpInteractive rsp = new()
                {
                    ObjId = req.ObjId,
                    
                };
                session.Send(ScMsgId.ScSceneInteractSpInteractive, rsp,packet.csHead.UpSeqid);
            }
            
        }
       
    }
}
