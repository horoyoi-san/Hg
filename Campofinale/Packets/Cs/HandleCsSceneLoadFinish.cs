using BeyondTools.VFS.Crypto;
using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using Google.Protobuf;
using Google.Protobuf.WellKnownTypes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Sockets;

using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;
using static Campofinale.Resource.ResourceManager;
using static System.Net.Mime.MediaTypeNames;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneLoadFinish
    {
        [Server.Handler(CsMsgId.CsSceneLoadFinish)]
        public static void HandleSceneFinish(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSceneLoadFinish req = packet.DecodeBody<CsSceneLoadFinish>();


            session.Send(new PacketScSelfSceneInfo(session, SelfInfoReasonType.SlrEnterScene));
            session.sceneManager.LoadCurrentTeamEntities();
            session.sceneManager.LoadCurrent();
            session.LoadFinish = true;
            /*session.Send(ScMessageId.ScSceneClientIdInfo, new ScSceneClientIdInfo()
            {
                RoleIdx = (uint)session.roleId,
                LastMaxIdx = session.random.usedGuids.Max()
            });*/
            if (session.curSceneNumId == 98)
            {
                session.Send(new PacketScSyncGameMode(session, "spaceship"));
            }
            else
            {
                
                if (session.currentDungeon != null && session.curSceneNumId==GetSceneNumIdFromLevelData(session.currentDungeon.table.sceneId))
                {
                    session.Send(new PacketScSyncGameMode(session, "dungeon_race"));
                }
                else
                {
                    session.currentDungeon = null;
                    session.Send(new PacketScSyncGameMode(session, ""));
                }
                    
            }
            session.LoadFinish = true;
        }
    }
}
