using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsLogout
    {
        [Server.Handler(CsMsgId.CsLogout)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            // save player data when logout.
            session.Save();
        }
    }
}