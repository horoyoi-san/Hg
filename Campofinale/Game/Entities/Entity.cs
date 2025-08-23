using Campofinale.Resource;
using System.Threading;
using static Campofinale.Resource.ResourceManager;
using static Campofinale.Resource.ResourceManager.LevelScene.LevelData;

namespace Campofinale.Game.Entities
{
    public class Entity
    {
        public ulong guid;
        public int level;
        public ulong worldOwner;
        public double curHp;
        public ulong levelLogicId;
        public ulong belongLevelScriptId;
        public int dependencyGroupId;
        public ObjectType type;
        public Vector3f Position=new();
        public Vector3f Rotation = new();
        public Vector3f BornPos=new();
        public Vector3f BornRot=new();
        public List<ParamKeyValue> properties=new();
        public int sceneNumId;
        public bool spawned = false;
        public bool defaultHide = false;
        public Entity()
        {

        }
        public Entity(ulong guid, int level, ulong worldOwner,int scene)
        {
            this.guid = guid;
            this.level = level;
            this.worldOwner = worldOwner;
            this.sceneNumId = scene;
        }
        public virtual void Damage(double dmg)
        {

        }

        public virtual void Heal(double heal)
        {

        }
        public virtual void OnDie()
        {

        }
        public virtual bool Interact(string eventName, Google.Protobuf.Collections.MapField<string, DynamicParameter> properties)
        {
            return false;
        }
        public Player GetOwner()
        {
            return Server.clients.Find(c => c.roleId == worldOwner);
        }
    }
}
