using Campofinale.Game.Entities;
using Campofinale.Network;
using Campofinale.Protocol;
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
    public class HandlCsMoveObjectMove
    {

        [Server.Handler(CsMsgId.CsMoveObjectMove)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsMoveObjectMove req = packet.DecodeBody<CsMoveObjectMove>();
            foreach (var moveInfo in req.MoveInfo)
            {
              
                if (moveInfo.Objid == session.teams[session.teamIndex].leader)
                {
                    session.position = new Vector3f(moveInfo.MotionInfo.Position);
                    session.rotation = new Vector3f(moveInfo.MotionInfo.Rotation);
                }
                else
                {
                    Entity entity = session.sceneManager.GetEntity(moveInfo.Objid);

                    if (entity != null && entity is not EntityCharacter)
                    {
                        entity.Position = new Vector3f(moveInfo.MotionInfo.Position);
                        entity.Rotation = new Vector3f(moveInfo.MotionInfo.Rotation);
                    }
                }
                
            }
            ScMoveObjectMove proto = new()
            {
                MoveInfo =
                {
                    req.MoveInfo,
                },
                ServerNotify=false,
                
            };

            session.Send(ScMsgId.ScMoveObjectMove, proto);
        }
       
    }
}
