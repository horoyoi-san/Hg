using Campofinale.Game.Entities;
using Campofinale.Resource;

namespace Campofinale.Commands.Handlers
{
    public static class CommandSpawn
    {
        [Server.Command("spawn", "Spawn command", true)]
        public static void Handle(Player sender, string cmd, string[] args, Player target)
        {
            if (args.Length < 2)
            {
                CommandManager.SendMessage(sender, "Example: spawn (id) (level) (count)");
                return;
            }
            string templateId = args[0];
            int level = int.Parse(args[1]);
            int count = int.Parse(args[2]);
            if (level < 1)
            {
                CommandManager.SendMessage(sender, "Level can't be less than 1");
                return;
            }
            if (count < 1)
            {
                CommandManager.SendMessage(sender, "Count can't be less than 1");
                return;
            }
            switch (templateId.Split("_")[0])
            {
                case "eny":
                    if (ResourceManager.enemyTable.ContainsKey(templateId))
                    {
                        for (int i = 0; i < count; i++)
                        {
                            EntityMonster mon = new(templateId, level, target.roleId, target.position, target.rotation, target.curSceneNumId);
                            target.sceneManager.SpawnEntity(mon);
                        }
                    }
                    else
                    {
                        CommandManager.SendMessage(sender, "Monster template id not found");
                    }

                    break;
                default:
                    CommandManager.SendMessage(sender, "Unsupported template id to spawn: " + templateId.Split("_")[0]);
                    break;
            }
            /*target.Send(ScMessageId.ScSpawnEnemy, new ScSpawnEnemy()
            {
                ClientKey=2,
                EnemyInstIds = { info.Detail.MonsterList[0].CommonInfo.Id }
            });*/

        }
    }
}
