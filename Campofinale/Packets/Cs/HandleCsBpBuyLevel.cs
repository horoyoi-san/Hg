using Campofinale.Network;
using Campofinale.Protocol;
using Campofinale.Packets.Sc;

namespace Campofinale.Packets.Cs
{
    public class HandleCsBpBuyLevel
    {
        [Server.Handler(CsMsgId.CsBpBuyLevel)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsBpBuyLevel req = packet.DecodeBody<CsBpBuyLevel>();

            bool success = session.battlePassManager.PurchaseLevels(req.TargetLevel);

            if (success)
            {
                var response = new ScBpBuyLevel
                {
                    TargetLevel = req.TargetLevel
                };
                session.Send(new PacketScBpBuyLevel(session, response));

                var levelUpdate = new ScBpLevelModify
                {
                    LevelData = session.battlePassManager.GetLevelData()
                };
                session.Send(new PacketScBpLevelModify(session, levelUpdate));
            }
        }
    }
}

