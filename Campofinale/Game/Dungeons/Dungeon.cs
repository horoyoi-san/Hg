using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Dungeons
{
    public class Dungeon
    {
        public DungeonTable table;
        public Vector3f prevPlayerPos;
        public Vector3f prevPlayerRot;
        public int prevPlayerSceneNumId;
        public Player player;
        public CsEnterDungeon req;
        public Dungeon()
        {

        }
        public string GetSceneId()
        {
            if(table.sceneId.Length > 0)
            {
                return table.sceneId;
            }
            else
            {
                return table.levelId;
            }
        }
        public void Enter()
        {
            player.sceneManager.GetScene(GetSceneNumIdFromLevelData(GetSceneId())).activeScripts.Clear();
            player.sceneManager.GetScene(GetSceneNumIdFromLevelData(GetSceneId())).scripts.ForEach(script =>
            {
                script.state = 1;
            });
            ScEnterDungeon enter = new()
            {
                DungeonId = table.dungeonId,
                SceneId = GetSceneId(),
            };
            player.Send(new PacketScSyncAllUnlock(player));

            player.EnterScene(GetSceneNumIdFromLevelData(GetSceneId()));
            player.Send(ScMsgId.ScEnterDungeon, enter);
        }
        public void Leave()
        {
            ScLeaveDungeon rsp = new()
            {
                DungeonId = table.dungeonId,
            };
            player.Send(new PacketScSyncAllUnlock(player));
            player.currentDungeon = null;
            player.EnterScene(prevPlayerSceneNumId, prevPlayerPos, prevPlayerRot);
            player.Send(ScMsgId.ScLeaveDungeon, rsp);
        }
    }
}
