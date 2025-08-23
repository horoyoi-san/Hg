using Campofinale.Resource;

namespace Campofinale.Commands.Handlers
{
    public static class CommandKick
    {
        [Server.Command("kick", "kick target", true)]
        public static void Handle(Player sender, string cmd, string[] args, Player target)
        {
            target.Kick(CODE.ErrKickSessionEnd, "Kicked");
            CommandManager.SendMessage(sender,"Kicked " + target.accountId);
        }
    }
}
