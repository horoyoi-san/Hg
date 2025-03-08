// Copyright (c) 2025, Shimizu Izumi. All rights reserved.

using Campofinale.Network;
using Campofinale.Protocol;

namespace Campofinale.Packets.Cs
{
    public class HandleCsSceneSubmitItem
    {
        [Server.Handler(CsMsgId.CsSceneSubmitItem)]
        public static void Handle(Player session, CsMsgId msgId, Packet packet)
        {
            CsSceneSubmitItem req = packet.DecodeBody<CsSceneSubmitItem>();
            
            session.Send(ScMsgId.ScSceneSubmitItem, new ScSceneSubmitItem
            {
                SubmitId = req.SubmitId,
                Ret = true
            });
        }
    }
}