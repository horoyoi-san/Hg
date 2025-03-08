using Campofinale.Network;
using Campofinale.Protocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Packets.Sc
{
    public class PacketScGameMechanicsSync : Packet
    {

        public PacketScGameMechanicsSync(Player client) {

            ScGameMechanicsSync mechanics = new()
            {
                GameUnlockConditions =
                {

                },

            };
            
            foreach (var item in gameMechanicTable)
            {
                mechanics.GameRecords.Add(new ScdGameMechanicsRecord()
                {
                    GameId = item.Value.gameMechanicsId,
                    IsPass = true,

                });
            }
            SetData(ScMsgId.ScGameMechanicsSync, mechanics);
        }

    }
}
