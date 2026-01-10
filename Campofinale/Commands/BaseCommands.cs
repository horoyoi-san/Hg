namespace Campofinale.Commands
{
    public static class BaseCommands
    {


        [Server.Command("scene", "Change scene", true)]
        public static void SceneCmd(Player sender, string cmd, string[] args, Player target)
        {
            if (args.Length < 1) return;
            int sceneNumId = int.Parse(args[0]);
            target.EnterScene(sceneNumId);
            CommandManager.SendMessage(sender, "Changing scene");

        }
        [Server.Command("target", "Set a target uid. default to first online player if no argument is provided", false)]
        public static void TargetCmd(Player sender, string cmd, string[] args, Player target)
        {
            if (sender != null)
            {
                CommandManager.SendMessage(sender, "This command can't be used ingame");
                return;
            }

            // Get the default target if no argument, otherwise null.
            Player? defaultTarget = args.Length > 0 ? null : Server.clients.FirstOrDefault();
            string? id = args.Length > 0 ? args[0] : defaultTarget?.accountId;

            if (string.IsNullOrEmpty(id))
            {
                CommandManager.SendMessage(sender, "Use: /target (uid)");
                return;
            }

            // Attempt to find online player by accountId
            Player? player = Server.clients.Find(c => c.accountId == id);

            if (player == null)
            {
                CommandManager.SendMessage(sender, "Only online players can be set as target");
                return;
            }

            CommandManager.targetId = id;
            CommandManager.SendMessage(sender, "Set Target player to " + id);
        }
    }
}