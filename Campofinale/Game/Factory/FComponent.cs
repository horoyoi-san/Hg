using Campofinale.Game.Factory.Components;
using Campofinale.Resource;
using MongoDB.Bson.Serialization.Attributes;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Game.Factory
{
    [BsonDiscriminator(Required = true)]
    [BsonKnownTypes(typeof(FComponentSelector))]

    public class FComponent
    {
        public class FCompInventory
        {
            public ScdFacComInventory ToProto()
            {
                return new ScdFacComInventory()
                {

                };
            }
        }
        public uint compId;
        public FCComponentType type;
        public FCompInventory inventory;
        public FCComponentPos customPos = FCComponentPos.Invalid;
        public FComponent(uint id, FCComponentType t, FCComponentPos custom= FCComponentPos.Invalid)
        {
            this.compId = id;
            this.type = t;
            this.customPos = custom;
        }
        public FCComponentPos GetComPos()
        {
            if(customPos  == FCComponentPos.Invalid)
            {
                switch (type)
                {
                    case FCComponentType.PowerPole:
                        return FCComponentPos.PowerPole;
                    case FCComponentType.TravelPole:
                        return FCComponentPos.TravelPole;
                    case FCComponentType.Battle:
                        return FCComponentPos.Battle1;
                    case FCComponentType.Producer:
                        return FCComponentPos.Producer;
                    case FCComponentType.FormulaMan:
                        return FCComponentPos.FormulaMan;
                    case FCComponentType.BusLoader:
                        return FCComponentPos.BusLoader;
                    case FCComponentType.StablePower:
                        return FCComponentPos.StablePower;
                    case FCComponentType.Selector:
                        return FCComponentPos.Selector;
                    case FCComponentType.PowerSave:
                        return FCComponentPos.PowerSave;
                    default:
                        return FCComponentPos.Invalid;
                }
            }
            
            return customPos;
        }
        public ScdFacCom ToProto()
        {
            ScdFacCom proto = new ScdFacCom()
            {
                ComponentType = (int)type,
                ComponentId = compId,
                
            };
            SetComponentInfo(proto);
            return proto;
        }

        public virtual void SetComponentInfo(ScdFacCom proto)
        {
            if (inventory != null)
            {
                proto.Inventory = inventory.ToProto();
            }
            else if (type == FCComponentType.PowerPole)
            {
                proto.PowerPole = new()
                {
                    
                };
            }
        }

        public virtual FComponent Init()
        {
            switch (type)
            {
                case FCComponentType.Inventory:
                    inventory = new();
                    break;
                default:
                    break;
            }
            return this;
        }

        
    }
}
