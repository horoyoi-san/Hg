using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Resource;
using static Campofinale.Game.Adventure.AdventureBookManager;

namespace Campofinale.Packets.Sc
{
    public class PacketScAdventureBookSync : Packet
    {
        public PacketScAdventureBookSync(Player player) {
            ScAdventureBookSync proto = new ScAdventureBookSync() {
                AdventureBookStage=player.adventureBookManager.data.adventureBookStage,
                DailyActivation=player.adventureBookManager.data.dailyActivation,
            };
            foreach (GameAdventureTask task in player.adventureBookManager.data.tasks)
            {
                proto.Tasks.Add(task.ToProto());
            }
            SetData(ScMsgId.ScAdventureBookSync, proto);
        }
    }
}
