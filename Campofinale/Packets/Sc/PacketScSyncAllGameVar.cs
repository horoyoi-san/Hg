using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;

namespace Campofinale.Packets.Sc
{
    public class PacketScSyncAllGameVar : Packet
    {

        public PacketScSyncAllGameVar(Player client) {

            ScSyncAllGameVar proto = new()
            {
                ServerVars =
                {
                    {(int)ServerGameVarEnum.ServerGameVarDashEnergyLimit,client.maxDashEnergy }, //Dash
                }
            };
            foreach(var id in ResourceManager.strIdNumTable.client_game_var_string_id.dic)
            {
                proto.ClientVars.Add(id.Value, 1);
            }
            SetData(ScMsgId.ScSyncAllGameVar, proto);
        }

    }
}
