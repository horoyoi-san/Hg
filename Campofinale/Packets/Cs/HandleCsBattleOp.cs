using Campofinale.Game;
using Campofinale.Game.Char;
using Campofinale.Game.Entities;
using Campofinale.Network;
using Campofinale.Protocol;
using StardustUtils;

namespace Campofinale.Packets.Cs
{
    public class HandleCsBattleOp
    {
        //TODO AbilityManager
        [Server.Handler(CsMsgId.CsBattleOp)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsBattleOp req = packet.DecodeBody<CsBattleOp>();

            foreach (BattleClientOpData data in req.ClientData.OpList)
            {
                switch (data.OpType)
                {
                    case BattleActionOperateType.BattleOpEntityValueModify:
                        OnEntityValueModify(session, data);
                        break;
                    case BattleActionOperateType.BattleOpSkillStartCast:
                        OnSkillStartCast(session, data);
                        break;
                    case BattleActionOperateType.BattleOpSkillEndCast:
                        OnSkillEndCast(session, data);
                        break;
                    case BattleActionOperateType.BattleOpTriggerAction:
                        OnTriggerAction(session, data.TriggerActionOpData);
                        break;
                    case BattleActionOperateType.BattleOpEntityDie:
                        OnEntityDie(session, data.EntityDieOpData);
                        break;
                    case BattleActionOperateType.BattleOpUpdateDataVersion:
                    case BattleActionOperateType.BattleOpResetBattleData:
                    case BattleActionOperateType.BattleOpEnablePassiveSkill:
                    case BattleActionOperateType.BattleOpTriggerKeyword:
                    case BattleActionOperateType.BattleOpShieldValueModify:
                    case BattleActionOperateType.BattleOpUpdateAtbInfo:
                    case BattleActionOperateType.BattleOpModifyBattleState:
                    case BattleActionOperateType.BattleOpModifyPoiseValue:
                    case BattleActionOperateType.BattleOpSetBuffEnableState:
                    case BattleActionOperateType.BattleOpAddBuff:
                    case BattleActionOperateType.BattleOpFinishBuff:
                    case BattleActionOperateType.BattleOpSkillAttach:
                    case BattleActionOperateType.BattleOpSkillDetach:
                    case BattleActionOperateType.BattleOpSwitchMode:
                        break;
                    default:
                        Logger.PrintWarn($"Unimplemented BattleActionOperateType.{data.OpType}");
                        break;
                }
            }

        }

        private static void OnEntityDie(Player session, BattleEntityDieOpData data)
        {
            if (session.sceneManager.GetEntity(data.EntityInstId) != null)
            {
                if (Server.config.logOptions.debugPrint)
                {
                    Logger.PrintWarn("Killed entity with guid: " + data.EntityInstId);
                }
                session.sceneManager.KillEntity(data.EntityInstId);
            }


        }

        private static void OnTriggerAction(Player session, BattleTriggerActionOpData data)
        {
            if (data == null) return;
            switch (data.Action.ActionType)
            {
                case ServerBattleActionType.BattleActionDamage:
                    foreach (BattleDamageDetail item in data.Action.DamageAction.Details)
                    {
                        DamageEntity(session, item);

                    }
                    break;
                case ServerBattleActionType.BattleActionHeal:
                    foreach (BattleHealActionDetail item in data.Action.HealAction.Details)
                    {
                        HealEntity(session, item);
                    }
                    break;
                case ServerBattleActionType.BattleActionSpawnEnemy:
                    if (data.Action.SpawnEnemyAction != null)
                        foreach (BattleSpawnEnemyActionDetail enemy in data.Action.SpawnEnemyAction.Details)
                        {
                            Scene scene = session.sceneManager.GetScene(enemy.SceneNumId);
                            scene.SpawnEnemy(enemy);
                        }
                    break;
                case ServerBattleActionType.BattleActionCreateBuff:
                case ServerBattleActionType.BattleActionLaunchProjectile:
                    break;
                default:
                    Logger.PrintWarn($"Unimplemented ServerBattleActionType.{data.Action.ActionType}");
                    break;
            }
        }

        public static void HealEntity(Player session, BattleHealActionDetail detail)
        {
            Entity en = session.sceneManager.GetEntity(detail.TargetId);
            if (en != null)
            {
                Logger.Print("Healing +" + detail.Value + "hp");
                en.Heal(detail.Value);
            }
        }

        public static void DamageEntity(Player session, BattleDamageDetail detail)
        {
            Entity en = session.sceneManager.GetEntity(detail.TargetId);

            if (en != null)
            {
                en.Damage(detail.Value);
                if (Server.config.logOptions.debugPrint)
                {
                    Logger.PrintWarn("Damaged entity with dmg: " + detail.Value);
                }
            }
        }
        private static void OnSkillStartCast(Player session, BattleClientOpData data)
        {
            ulong casterId = data.OwnerId;
            Character character = session.chars.Find(c => c.guid == casterId);
            if (character != null)
            {
                ScCharSyncStatus s = new()
                {
                    BattleInfo = new()
                    {
                        Hp = character.curHp,
                        Ultimatesp = character.ultimateSp
                    },
                    Objid = character.guid,

                };

                session.Send(ScMsgId.ScCharSyncStatus, s);
            }
            else
            {
                //Manage normal entity
            }
        }
        private static void OnSkillEndCast(Player session, BattleClientOpData data)
        {
            ulong casterId = data.OwnerId;

            Character character = session.chars.Find(c => c.guid == casterId);
            if (character != null)
            {
                ScCharSyncStatus s = new()
                {
                    BattleInfo = new()
                    {
                        Hp = character.curHp,
                        Ultimatesp = character.ultimateSp
                    },
                    Objid = character.guid,
                };
                session.Send(ScMsgId.ScCharSyncStatus, s);
            }
            else
            {
                //Manage normal entity
            }
        }

        private static void OnEntityValueModify(Player session, BattleClientOpData data)
        {
            Character character = session.chars.Find(c => c.guid == data.EntityValueModifyData.EntityInstId);
            if (character != null)
            {

                character.curHp = data.EntityValueModifyData.Value.Hp;
                character.ultimateSp = data.EntityValueModifyData.Value.Ultimatesp;
                ScCharSyncStatus s = new()
                {
                    BattleInfo = new()
                    {
                        Hp = character.curHp,
                        Ultimatesp = character.ultimateSp
                    },
                    Objid = character.guid,
                };
                session.Send(ScMsgId.ScCharSyncStatus, s);
            }
            else
            {
                //Manage normal entity
            }
            // data.EntityValueModifyData.
        }
    }
}