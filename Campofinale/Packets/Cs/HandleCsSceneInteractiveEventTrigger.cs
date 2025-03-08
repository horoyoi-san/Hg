using Campofinale.Game.Character;
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

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneInteractiveEventTrigger
    {

        [Server.Handler(CsMsgId.CsSceneInteractiveEventTrigger)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneInteractiveEventTrigger  req = packet.DecodeBody<CsSceneInteractiveEventTrigger>();
            
            
            EntityInteractive entity = (EntityInteractive)session.sceneManager.GetEntity(req.Id);
            if (entity != null)
            {
                if(entity.Interact(req.EventName, req.Properties))
                {

                }
                else
                {
                    ScSceneTriggerClientInteractiveEvent tr = new()
                    {
                        EventName = req.EventName,
                        Id = req.Id,
                        SceneNumId = req.SceneNumId,
                        
                    };
                    session.Send(ScMsgId.ScSceneTriggerClientInteractiveEvent, tr);
                }
            }
            
        }
       
    }
}
