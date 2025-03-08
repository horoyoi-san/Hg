using Campofinale.Game.Entities;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Commands.Handlers
{
    public static class CommandHeal
    {

        [Server.Command("heal", "Revives/Heals your team characters", true)]
        public static void Handle(Player sender, string cmd, string[] args, Player target)
        {
            target.GetCurTeam().ForEach(chara =>
            {
                chara.curHp = chara.CalcAttributes()[AttributeType.MaxHp].val;
                ScCharSyncStatus state = new ScCharSyncStatus()
                {
                    Objid=chara.guid,
                    IsDead=chara.curHp < 1,
                    BattleInfo = new()
                    {
                        Hp=chara.curHp,
                        Ultimatesp=chara.ultimateSp
                    }
                };
                target.Send(ScMsgId.ScCharSyncStatus, state);
            });
            target.Send(ScMsgId.ScSceneRevival, new ScSceneRevival()
            {
                
            });
            target.sceneManager.LoadCurrentTeamEntities();
            target.Send(new PacketScSelfSceneInfo(target,SelfInfoReasonType.SlrReviveRest));
            CommandManager.SendMessage(sender, "Healed!");
        }
    }
}
