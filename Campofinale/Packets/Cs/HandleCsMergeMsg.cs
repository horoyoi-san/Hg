using System.Drawing;

using Campofinale.Network;
using Campofinale.Protocol;

using Pastel;

namespace Campofinale.Packets.Cs
{
    public class HandleCsMergeMsg
    {

        [Server.Handler(CsMsgId.CsMergeMsg)]
        public static void Handle(Player session, CsMsgId cmdId, Packet p)
        {
            CsMergeMsg req = p.DecodeBody<CsMergeMsg>();



            byte[] allBytes = req.Msg.ToByteArray();
            while (allBytes.Length > 3) {

                byte headLength = Packet.GetByte(allBytes, 0);
                ushort bodyLength = Packet.GetUInt16(allBytes, 1);

                byte[] head = allBytes.AsSpan().Slice(3, headLength).ToArray();
                byte[] body = allBytes.AsSpan().Slice(3+ headLength, bodyLength).ToArray();
                Packet packet = new()
                {
                    finishedBody = body,
                    csHead = CSHead.Parser.ParseFrom(head),
                    cmdId = CSHead.Parser.ParseFrom(head).Msgid,

                };
                if (Server.config.logOptions.packets)
                {
                    Logger.Print("Recieved Packet: " + ((CsMsgId)packet.csHead.Msgid).ToString().Pastel(Color.LightCyan) + $" Id: {packet.csHead.Msgid} with {packet.finishedBody.Length} Bytes");
                    if (Server.config.logOptions.packetBodies)
                        Logger.Print(BitConverter.ToString(packet.finishedBody).Replace("-", string.Empty).ToLower());
                }

                try
                {
                    NotifyManager.Notify(session, (CsMsgId)packet.cmdId, packet);
                }
                catch (Exception e)
                {
                    Logger.PrintError("Error while notify packet: " + e.Message);
                }
                allBytes = allBytes.AsSpan().Slice(3 + headLength + bodyLength).ToArray();
            }

        }
       
    }
}
