using Campofinale.Game.Inventory;
using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Sc
{
    public class PacketScItemBagScopeModify : Packet
    {

        public PacketScItemBagScopeModify(Player client, Item item)
        {

            if (item == null)
            {
                SetData(ScMsgId.ScItemBagScopeModify, new ScItemBagScopeModify());
                return;
            }

            ScItemBagScopeModify proto = new ScItemBagScopeModify()
            {
                ScopeName = 1,
            };

            // ItemType already handles Factory -> SpecialItem conversion for maxBackpackStackCount > 0
            if (item.ItemType == ItemValuableDepotType.Factory)
            {
                proto.FactoryDepot.Add("domain_1", new ScdItemDepotModify());
                if (item.InstanceType())
                {
                    if (item.amount <= 0)
                    {
                        proto.FactoryDepot["domain_1"].DelInstList.Add(item.guid);
                    }
                    else
                    {
                        proto.FactoryDepot["domain_1"].InstList.Add(item.ToProto());
                    }
                }
                else
                {
                    proto.FactoryDepot["domain_1"].Items.Add(item.id, item.amount);
                }
            }
            else
            {
                proto.Depot.Add((int)item.ItemType, new ScdItemDepotModify());
                if (item.InstanceType())
                {
                    if (item.amount <= 0)
                    {
                        proto.Depot[(int)item.ItemType].DelInstList.Add(item.guid);
                    }
                    else
                    {
                        proto.Depot[(int)item.ItemType].InstList.Add(item.ToProto());
                    }
                }
                else
                {
                    proto.Depot[(int)item.ItemType].Items.Add(item.id, item.amount);
                }
            }

            SetData(ScMsgId.ScItemBagScopeModify, proto);
        }

    }
}
