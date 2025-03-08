using Campofinale.Network;
using Campofinale.Protocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace Campofinale.Packets.Sc
{
    public class PacketScSyncBaseData : Packet
    {

        public PacketScSyncBaseData(Player client) {

            ScSyncBaseData proto = new ScSyncBaseData()
            {
                Roleid = client.roleId,
                Level = client.level,
                Exp=client.xp,
                RoleName = client.nickname,
                Gender = Gender.GenFemale,
                ShortId="1",
                
            };

            SetData(ScMsgId.ScSyncBaseData, proto);
        }

    }
}
