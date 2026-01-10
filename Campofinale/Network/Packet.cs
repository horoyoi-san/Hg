using Campofinale.Protocol;
using Google.Protobuf;
using Newtonsoft.Json;
using StardustUtils;
using System.Drawing;
using System.Net;
using System.Security.Cryptography;

namespace Campofinale.Network
{
    public class Packet
    {
        public int cmdId;
        public byte[] finishedBody;
        public CSHead csHead;
        public IMessage set_body;
        public static void PutUInt16(byte[] buf, ushort networkValue, int offset)
        {
            byte[] bytes = BitConverter.GetBytes(networkValue);
            Buffer.BlockCopy(bytes, 0, buf, offset, bytes.Length);
        }

        public static void PutUInt32(byte[] buf, uint networkValue, int offset)
        {
            byte[] bytes = BitConverter.GetBytes(networkValue);
            Buffer.BlockCopy(bytes, 0, buf, offset, bytes.Length);
        }
        public static void PutUInt64(byte[] buf, ulong networkValue, int offset)
        {
            byte[] bytes = BitConverter.GetBytes(networkValue);
            Buffer.BlockCopy(bytes, 0, buf, offset, bytes.Length);
        }
        public static ushort GetUInt16(byte[] buf, int index)
        {
            ushort networkValue = BitConverter.ToUInt16(buf, index);
            return networkValue;
        }

        public static uint GetUInt32(byte[] buf, int index)
        {
            uint networkValue = BitConverter.ToUInt32(buf, index);
            return (uint)IPAddress.NetworkToHostOrder((int)networkValue);
        }
        public static void PutByte(byte[] buf, byte networkValue, int offset)
        {
            byte[] bytes = new byte[1] { networkValue };
            Buffer.BlockCopy(bytes, 0, buf, offset, bytes.Length);
        }
        public static byte GetByte(byte[] buf, int index)
        {
            byte networkValue = buf[index];
            return networkValue;
        }
        /// <summary>
        /// Parse the body using a specific IMessage proto class
        /// </summary>
        /// <typeparam name="TBody"></typeparam>
        /// <returns></returns>
        public TBody DecodeBody<TBody>() where TBody : IMessage<TBody>, new()
        {
            return new MessageParser<TBody>(() => new()).ParseFrom(finishedBody);
        }
        public static void PutByteArray(byte[] destination, byte[] source, int offset)
        {
            if (destination == null)
                throw new ArgumentNullException(nameof(destination));
            if (source == null)
                throw new ArgumentNullException(nameof(source));
            if (offset < 0 || offset > destination.Length - source.Length)
                throw new ArgumentOutOfRangeException(nameof(offset), "Offset is out of range.");

            Buffer.BlockCopy(source, 0, destination, offset, source.Length);
        }
        public static byte[] EncryptWithPublicKey(byte[] data, string publicKey)
        {
            using (RSA rsa = RSA.Create())
            {
                publicKey = publicKey.Replace("-----BEGIN PUBLIC KEY-----", "");
                publicKey = publicKey.Replace("\r", "");
                publicKey = publicKey.Replace("\n", "");
                publicKey = publicKey.Replace("-----END PUBLIC KEY-----", "");
                publicKey = publicKey.Trim();
                Logger.Print(publicKey);
                byte[] publicKey_ = Convert.FromBase64String(publicKey);
                rsa.ImportSubjectPublicKeyInfo(publicKey_, out _);
                return rsa.Encrypt(data, RSAEncryptionPadding.OaepSHA256);
            }
        }
        /// <summary>
        /// Set the data of the packet with the Message Id and the body
        /// </summary>
        /// <param name="msgId"></param>
        /// <param name="body">The proto message</param>
        /// <returns>The current Packet</returns>
        public Packet SetData(ScMsgId msgId, IMessage body)
        {
            set_body = body;
            cmdId = (int)msgId;
            return this;
        }
        /// <summary>
        /// Encode the packet using the Packet class
        /// </summary>
        /// <param name="packet">The packet</param>
        /// <param name="seq">the sequence id</param>
        /// <param name="totalPackCount">the pack count</param>
        /// <param name="currentPackIndex"></param>
        /// <returns></returns>
        public static byte[] EncodePacket(Packet packet, ulong seq = 0, uint totalPackCount = 1, uint currentPackIndex = 0)
        {
            return EncodePacket(packet.cmdId, packet.set_body, seq, totalPackCount, currentPackIndex);
        }
        public static ulong seqNext = 1;

        private static void LogPacket(string direction, int msgId, int dataLength, object? body = null, bool isScMessage = true)
        {
            if (Server.config == null || !Server.config.logOptions.packets) return;

            bool shouldHide = false;
            string msgName = "";

            if (isScMessage)
            {
                var msgIdEnum = (ScMsgId)msgId;
                shouldHide = Server.scMessageToHide.Contains(msgIdEnum);
                msgName = msgIdEnum.ToString();
            }
            else
            {
                var msgIdEnum = (CsMsgId)msgId;
                shouldHide = Server.csMessageToHide.Contains(msgIdEnum);
                msgName = msgIdEnum.ToString();
            }

            if (shouldHide) return;

            Color logColor = direction == "Sending" ? Color.LightBlue : Color.Yellow;
            Logger.Print($"{direction} Packet: {msgName.Pastel(logColor)} Id: {msgId} with {dataLength} Bytes");

            // Output packet body if configured for this message
            if (Server.config.logOptions.packetBodyMessages.Contains(msgName))
            {
                if (body != null && !(body is byte[]))
                {
                    try
                    {
                        string bodyJson = JsonConvert.SerializeObject(body, Formatting.Indented);
                        Logger.Print($"Packet Body for {msgName}: {bodyJson}");
                    }
                    catch
                    { }
                }
            }
        }
        /// <summary>
        /// Encode the packet using the msgId and the body
        /// </summary>
        /// <param name="msgId"></param>
        /// <param name="body"></param>
        /// <param name="seqNext_"></param>
        /// <param name="totalPackCount"></param>
        /// <param name="currentPackIndex"></param>
        /// <returns></returns>
        public static byte[] EncodePacket(int msgId, IMessage body, ulong seqNext_ = 0, uint totalPackCount = 1, uint currentPackIndex = 0)
        {
            if (seqNext_ == 0)
            {
                seqNext_ = seqNext;
            }
            seqNext++;
            CSHead head = new() { Msgid = msgId, UpSeqid = seqNext_, DownSeqid = seqNext, TotalPackCount = totalPackCount, CurrentPackIndex = currentPackIndex };
            int totalSerializedDataSize = 3 + head.ToByteArray().Length + body.ToByteArray().Length;
            byte[] data = new byte[totalSerializedDataSize];
            PutByte(data, (byte)head.ToByteArray().Length, 0);
            PutUInt16(data, (ushort)body.ToByteArray().Length, 1);
            PutByteArray(data, head.ToByteArray(), 3);
            PutByteArray(data, body.ToByteArray(), 3 + head.ToByteArray().Length);
            LogPacket("Sending", msgId, data.Length, body, true);

            return data;
        }
        /// <summary>
        /// Encode the packet with msgId and body as byte array
        /// </summary>
        /// <param name="msgId"></param>
        /// <param name="body"></param>
        /// <param name="seqNext_"></param>
        /// <param name="totalPackCount"></param>
        /// <param name="currentPackIndex"></param>
        /// <returns></returns>
        public static byte[] EncodePacket(int msgId, byte[] body, ulong seqNext_ = 0, uint totalPackCount = 1, uint currentPackIndex = 0)
        {
            if (seqNext_ == 0)
            {
                seqNext_ = seqNext;
            }
            if (currentPackIndex == 0)
            {
                seqNext++;
            }

            CSHead head = new() { Msgid = msgId, UpSeqid = seqNext_, DownSeqid = seqNext, TotalPackCount = totalPackCount, CurrentPackIndex = currentPackIndex };
            int totalSerializedDataSize = 3 + head.ToByteArray().Length + body.Length;
            byte[] data = new byte[totalSerializedDataSize];
            PutByte(data, (byte)head.ToByteArray().Length, 0);
            PutUInt16(data, (ushort)body.Length, 1);
            PutByteArray(data, head.ToByteArray(), 3);
            PutByteArray(data, body, 3 + head.ToByteArray().Length);
            LogPacket("Sending", msgId, data.Length, body, true);

            return data;
        }
        /// <summary>
        /// Read the byteArray as a valid packet
        /// </summary>
        /// <param name="client"></param>
        /// <param name="byteArray"></param>
        /// <returns>The decoded packet</returns>
        public static Packet Read(Player client, byte[] byteArray)
        {
            byte headLength = GetByte(byteArray, 0);
            ushort bodyLength = GetUInt16(byteArray, 1);

            byte[] csHeadBytes = new byte[headLength];
            byte[] BodyBytes = new byte[bodyLength];
            Array.Copy(byteArray, 3, csHeadBytes, 0, headLength);
            Array.Copy(byteArray, 3 + headLength, BodyBytes, 0, bodyLength);
            CSHead csHead_ = CSHead.Parser.ParseFrom(csHeadBytes);
            LogPacket("Received", csHead_.Msgid, BodyBytes.Length, null, false);
            seqNext = csHead_.UpSeqid;
            return new Packet() { csHead = csHead_, finishedBody = BodyBytes, cmdId = csHead_.Msgid };
        }
        /// <summary>
        /// Read the byteArray as a valid packet
        /// </summary>
        /// <param name="byteArray"></param>
        /// <returns>The decoded packet</returns>
        public static Packet Read(byte[] byteArray)
        {
            byte headLength = GetByte(byteArray, 0);
            ushort bodyLength = GetUInt16(byteArray, 1);

            byte[] csHeadBytes = new byte[headLength];
            byte[] BodyBytes = new byte[bodyLength];
            Array.Copy(byteArray, 3, csHeadBytes, 0, headLength);
            Array.Copy(byteArray, 3 + headLength, BodyBytes, 0, bodyLength);
            CSHead csHead_ = CSHead.Parser.ParseFrom(csHeadBytes);
            LogPacket("Received", csHead_.Msgid, BodyBytes.Length, null, false);
            seqNext = csHead_.UpSeqid;
            return new Packet() { csHead = csHead_, finishedBody = BodyBytes, cmdId = csHead_.Msgid };
        }
    }
}
