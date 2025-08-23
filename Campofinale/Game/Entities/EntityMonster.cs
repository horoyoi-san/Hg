using Campofinale.Protocol;
using Campofinale.Resource;
using Campofinale.Resource.Table;
using System.Threading;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Entities
{
    public class EntityMonster : Entity
    {
        public string templateId;
        public ulong originId;
        public EntityMonster()
        {

        }
        public EntityMonster(string templateId, int level, ulong worldOwner, Vector3f pos, Vector3f rot, int scene, ulong g=0)
        {
            if (g == 0)
            {
                this.guid = (ulong)new Random().NextInt64();
            }
            else
            {
                this.guid = g;
            }
            
            this.level = level;
            this.worldOwner = worldOwner;
            this.Position = pos;
            this.Rotation = rot;
            this.BornPos = pos;
            this.BornRot = rot;
            this.templateId = templateId;
            this.curHp = GetAttribValue(AttributeType.MaxHp);
            this.sceneNumId=scene;
        }
        public double GetAttribValue(AttributeType type)
        {
            return GetAttributes().Find(a => a.AttrType == (int)type).Value;
        }
        public List<AttrInfo> GetAttributes()
        {
            List<AttrInfo> attrInfo = new();
            EnemyTable table = ResourceManager.enemyTable[templateId];
            if(level >= enemyAttributeTemplateTable[table.attrTemplateId].levelDependentAttributes.Count)
            {
                level = 80;
            }
            enemyAttributeTemplateTable[table.attrTemplateId].levelDependentAttributes[level-1].attrs.ForEach(attr =>
            {
                attrInfo.Add(new AttrInfo()
                {
                    AttrType = attr.attrType,
                    BasicValue = attr.attrValue,
                    Value = attr.attrValue

                });

            });
            enemyAttributeTemplateTable[table.attrTemplateId].levelIndependentAttributes.attrs.ForEach(attr =>
            {
                attrInfo.Add(new AttrInfo()
                {
                    AttrType = attr.attrType,
                    BasicValue = attr.attrValue,
                    Value = attr.attrValue

                });

            });

            return attrInfo;
        }
        
        public SceneMonster ToProto()
        {
            SceneMonster proto = new SceneMonster()
            {
                Level = level,
                CommonInfo = new()
                {
                    Hp = curHp,
                    Id = guid,
                    Templateid = templateId,
                    BelongLevelScriptId = belongLevelScriptId,
                    SceneNumId = sceneNumId,
                    Position = Position.ToProto(),
                    Rotation = Rotation.ToProto(),
                    
                    Type =(int) ObjectTypeIndex.Enemy, 
                },
                OriginId= originId,
                Attrs =
                {
                    GetAttributes()
                },
                BattleInfo = new()
                {
                    
                },
                
            };
            return proto;
        }
        public override void OnDie()
        {
            if (!wikiEnemyDropTable.ContainsKey(templateId)) return;
            WikiEnemyDropTable table = wikiEnemyDropTable[templateId];
            if (table!=null)
            {
                table.dropItemIds.ForEach(id =>
                {
                    GetOwner().sceneManager.CreateDrop(Position, new RewardTable.ItemBundle()
                    {
                        id = id,
                        count = 1
                    });
                });
            }
            
        }
        public override void Damage(double dmg)
        {
            curHp -= dmg;
            ScEntityPropertyChange prop = new()
            {
                InstId = guid,
                Info = new()
                {
                    Hp = curHp,
                   

                }
            };
            GetOwner().Send(ScMsgId.ScEntityPropertyChange, prop);
        }

        public override void Heal(double heal)
        {
            curHp += heal;
        }

    }
}
