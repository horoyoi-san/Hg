using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Commands.Handlers
{
    public static class CommandUnlockAll
    {
        [Server.Command("unlockall", "Unlock all systems",true)]
        public static void Handle(Player sender,string cmd, string[] args, Player target)
        {
            target.unlockedSystems.Clear();
            target.UnlockImportantSystems();
            target.maxDashEnergy = 250;
            foreach (var system in target.unlockedSystems)
            {
                ScUnlockSystem unlocked = new()
                {
                    UnlockSystemType = system,
                };
                target.Send(ScMsgId.ScUnlockSystem, unlocked);
            }
            foreach (int i in ResourceManager.GetAllShortIds())
            {
                target.bitsetManager.AddValue(BitsetType.InteractiveActive, i);
            }
            target.Send(new PacketScSyncAllBitset(target));
            CommandManager.SendMessage(sender, "Unlocked everything");
        }
    }
}
