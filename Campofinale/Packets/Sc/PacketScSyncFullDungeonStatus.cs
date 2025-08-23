using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Sc
{
    public class PacketScSyncFullDungeonStatus : Packet
    {

        public PacketScSyncFullDungeonStatus(Player session) {
            ScSyncFullDungeonStatus dungeonStatus = new()
            {
                CurStamina = session.curStamina,
                MaxStamina = session.maxStamina,
                NextRecoverTime = session.nextRecoverTime / 1000,
            };

            SetData(ScMsgId.ScSyncFullDungeonStatus, dungeonStatus);
        }

    }
}
