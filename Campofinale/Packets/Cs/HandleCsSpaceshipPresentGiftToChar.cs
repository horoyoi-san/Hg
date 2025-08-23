using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSpaceshipPresentGiftToChar
    {

        [Server.Handler(CsMsgId.CsSpaceshipPresentGiftToChar)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsSpaceshipPresentGiftToChar req = packet.DecodeBody<CsSpaceshipPresentGiftToChar>();
            session.spaceshipManager.GiftToChar(req);
           
        }
       
    }
}
