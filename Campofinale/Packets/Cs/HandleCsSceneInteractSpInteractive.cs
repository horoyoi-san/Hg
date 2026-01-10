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
                        // Only record state in bitset if this interactive has a shortId mapping
                        // Not all interactive objects need persistent state tracking (e.g. dynamic/temporary objects)
                        if (ResourceManager.levelShortIdTable[scene.id].ids.ContainsKey((long)entity.guid))
                        {
                            long shortId = ResourceManager.levelShortIdTable[scene.id].ids[(long)entity.guid];
                            session.bitsetManager.AddValue(BitsetType.InteractiveTwoState, (int)shortId);
                            session.bitsetManager.AddValue(BitsetType.InteractiveActive, (int)shortId);
                        }
                        break;

                    case SpInteractiveOpType.PickDropPackItem:
                        EntityInteractive interactive = entity as EntityInteractive;
                        if (interactive.templateId == "int_doodad_flower_2")
                        {
                            session.inventoryManager.AddRewards("reward_doodad_moss_3", interactive.Position, 1);
                        }
                        if (interactive.templateId == "int_doodad_flower_1")
                        {
                            session.inventoryManager.AddRewards("reward_doodad_moss_3", interactive.Position, 1);
                        }
                        session.sceneManager.KillEntity(interactive.guid, true, 1);
                        break;
                    case SpInteractiveOpType.DoodadCommonBreak:
                        // DoodadCommonBreak: Client sends HP ratio update, server just acknowledges
                        // No special handling needed, just send response
                        break;
                    default:
                        Logger.PrintWarn($"Unimplemented SpInteractiveOpType.{(SpInteractiveOpType)req.OpType}");
                        break;
                }
                session.Send(new PacketScSyncAllBitset(session));
            }
            else
            {
                Logger.PrintWarn($"CsSceneInteractSpInteractive: Entity not found for objId={req.ObjId}, opType={req.OpType}");
            }

            // Always send response with UpSeqid to complete the RPC request, even if entity is null
            // Client waits for this response packet with matching UpSeqid
            ScSceneInteractSpInteractive rsp = new()
            {
                ObjId = req.ObjId,
            };
            session.Send(ScMsgId.ScSceneInteractSpInteractive, rsp, packet.csHead.UpSeqid);
        }

    }
}
