using Campofinale.Game.Character;
using Campofinale.Game.Entities;
using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using Google.Protobuf;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;
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
