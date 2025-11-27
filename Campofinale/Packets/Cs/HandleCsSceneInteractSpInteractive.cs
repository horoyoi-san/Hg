using Campofinale.Game.Entities;
using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
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
                    case SpInteractiveOpType.CommonActive:
                        session.bitsetManager.AddValue(Resource.BitsetType.InteractiveActive, ResourceManager.levelShortIdTable[scene.id].ids[(long)entity.guid]);
                        break;
                    case SpInteractiveOpType.DoodadCommonPick:
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
                        break;
                }
                session.Send(new PacketScSyncAllBitset(session));
                ScSceneInteractSpInteractive rsp = new()
                {
                    ObjId = req.ObjId,
                    
                };
                session.Send(ScMsgId.ScSceneInteractSpInteractive, rsp);
            }
            
        }
       
    }
}
