using Campofinale.Game;
using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Sc
{
    public class PacketScSyncAllRoleScene : Packet
    {

        public PacketScSyncAllRoleScene(Player client)
        {
            // Get current scene's SubmitEther data, or use default based on domain
            int submitEtherLevel = 1;
            int submitEtherCount = 0;
            var currentScene = client.sceneManager.GetScene(client.curSceneNumId);
            if (currentScene != null)
            {
                submitEtherLevel = currentScene.submitEtherLevel;
                submitEtherCount = currentScene.submitEtherCount;
            }
            else
            {
                // If no scene data, set to max level based on current domain
                string domainId = client.GetCurrentChapter();
                submitEtherLevel = SceneManager.GetMaxSubmitEtherLevelForDomain(domainId);
            }

            ScSyncAllRoleScene role = new ScSyncAllRoleScene()
            {
                SceneGradeInfo =
                {

                },
                UnlockAreaInfo =
                {

                },
                SubmitEtherCount = submitEtherCount,
                SubmitEtherLevel = submitEtherLevel,

            };

            foreach (var scene in ResourceManager.levelGradeTable)
            {
                role.SceneGradeInfo.Add(new SceneGradeInfo()
                {
                    Grade = 1,
                    //LastDownTs= DateTime.UtcNow.ToUnixTimestampMilliseconds()/1000,
                    SceneNumId = GetSceneNumIdFromLevelData(scene.Value.name),

                });
            }
            foreach (var scene in levelDatas)
            {
                AreaUnlockInfo u = new()
                {
                    SceneId = scene.id,

                    UnlockAreaId =
                    {

                    }
                };
                List<SceneAreaTable> areas = sceneAreaTable.Values.ToList().FindAll(a => a.sceneId == scene.id);
                foreach (var area in areas)
                {

                    //  u.UnlockAreaId.Add(area.areaId);
                }
                role.UnlockAreaInfo.Add(u);
            }

            SetData(ScMsgId.ScSyncAllRoleScene, role);
        }

    }
}
