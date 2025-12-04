using Campofinale.Game;
using Campofinale.Network;
using Campofinale.Protocol;
using System.Numerics;

namespace Campofinale.Packets.Cs
{
    public class HandleCsFinishDialog
    {
        
        [Server.Handler(CsMsgId.CsFinishDialog)]
        public static void Handle(Player session, CsMsgId cmdId, Packet packet)
        {
            CsFinishDialog req = packet.DecodeBody<CsFinishDialog>();
            session.Send(ScMsgId.ScFinishDialog, new ScFinishDialog()
            {
                DialogId=req.DialogId,
                FinishNums = { req.FinishNums },
                OptionIds = { req.OptionIds },
            },packet.csHead.UpSeqid);
           
        }
       
    }
}
