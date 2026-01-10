using Campofinale.Network;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using StardustUtils;
using System.Linq;

namespace Campofinale.Packets.Cs
{
    public class HandleCsDomainDepotUnlockReq
    {
        [Server.Handler(CsMsgId.CsDomainDepotUnlockReq)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsDomainDepotUnlockReq req = packet.DecodeBody<CsDomainDepotUnlockReq>();

            bool success = session.domainDepotManager.UnlockDomainDepot(req.DomainDepotId);
            if (!success)
            {
                Logger.PrintWarn($"[HandleCsDomainDepotUnlockReq] Failed to unlock domain depot {req.DomainDepotId} for player {session.roleId}");
                return;
            }

            ScDomainDepotUnlockRsp rsp = new ScDomainDepotUnlockRsp()
            {
                DomainDepotId = req.DomainDepotId
            };
            session.Send(ScMsgId.ScDomainDepotUnlockRsp, rsp, packet.csHead.UpSeqid);

            var bitsetValues = session.bitsetManager.bitsets[(int)BitsetType.UnlockDomainDepot];
            session.Send(new PacketScBitsetAdd(session, (int)BitsetType.UnlockDomainDepot, bitsetValues.Select(v => (uint)v).ToList()), packet.csHead.UpSeqid);
        }
    }
}

