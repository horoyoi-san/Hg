using Campofinale.Network;
using Campofinale.Protocol;
using Google.Protobuf;

namespace Campofinale.Packets.Sc
{
    public class PacketScSyncBaseData : Packet
    {

        public PacketScSyncBaseData(Player client) {

            ScSyncBaseData proto = new ScSyncBaseData()
            {
                Roleid = client.roleId,
                Level = client.level,
                Exp = client.xp,
                RoleName = client.nickname,
                Gender = client.gender,
                ShortId = "1",
                ClientSetting = ByteString.CopyFrom(client.clientSetting)
            };
            SetData(ScMsgId.ScSyncBaseData, proto);
        }

    }
}
