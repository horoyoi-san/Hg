using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Commands.Handlers
{
    public static class CommandHeal
    {

        [Server.Command("heal", "Revives/Heals your team characters", true)]
        public static void Handle(Player sender, string cmd, string[] args, Player target)
        {
            target.RestTeam();
            
            target.Send(ScMsgId.ScSceneRevival, new ScSceneRevival()
            {
                
            });
            target.sceneManager.LoadCurrentTeamEntities();
            target.Send(new PacketScSelfSceneInfo(target,SelfInfoReasonType.SlrReviveRest));
            CommandManager.SendMessage(sender, "Healed!");
        }
    }
}
