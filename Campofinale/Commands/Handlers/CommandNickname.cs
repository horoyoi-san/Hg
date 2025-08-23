using Campofinale.Packets.Sc;

namespace Campofinale.Commands.Handlers
{

    public static class CommandNickname
    {
        [Server.Command("nickname", "Changes nickname", true)]
        public static void Handle(Player sender, string cmd, string[] args, Player target)
        {
            if (args.Length < 1)
            {
                CommandManager.SendMessage(sender, "Use: /nickname (your new nickname)");
                return;
            }

            target.nickname = string.Join(" ", args);
            target.Save();
            target.Send(new PacketScSetName(target, target.nickname));
            CommandManager.SendMessage(sender, $"Nickname was changed to {target.nickname}");
        }
    }
}
