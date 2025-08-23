using Campofinale.Game.Inventory;
using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScItemBagScopeModify : Packet
    {

        public PacketScItemBagScopeModify(Player client, Item item) {

            if (item == null)
            {
                SetData(ScMsgId.ScItemBagScopeModify, new ScItemBagScopeModify());
                return;
            }
            ScItemBagScopeModify proto = new ScItemBagScopeModify()
            {
                Depot =
                {
                    {(int)item.ItemType,new ScdItemDepotModify(){
                        
                    }
                    }
                },
                ScopeName=1,
                
            };
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

            SetData(ScMsgId.ScItemBagScopeModify, proto);
        }

    }
}
