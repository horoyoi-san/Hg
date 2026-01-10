using Campofinale.Protocol;
using Google.Protobuf;
using System.Reflection;

namespace Campofinale.Network
{
    /// <summary>
    /// Utility class for parsing protobuf packet bodies to JSON format
    /// </summary>
    public static class PacketBodyParser
    {
        private static readonly JsonFormatter jsonFormatter = new JsonFormatter(new JsonFormatter.Settings(false));

        /// <summary>
        /// Try to parse packet body as protobuf message and return JSON string, fallback to hex if parsing fails
        /// </summary>
        public static string TryParsePacketBody(CsMsgId msgId, byte[] body)
        {
            try
            {
                // Try to parse based on message ID
                IMessage? message = TryParseMessage(msgId, body);
                if (message != null)
                {
                    // Use JsonFormatter to format the message
                    return jsonFormatter.Format(message);
                }
            }
            catch (Exception)
            {
                // If parsing fails, fallback to hex
            }

            // Fallback to hex string
            return BitConverter.ToString(body).Replace("-", string.Empty).ToLower();
        }

        /// <summary>
        /// Try to parse message body based on message ID using reflection to automatically find message type
        /// This avoids manually maintaining a switch case for each message type
        /// </summary>
        private static IMessage? TryParseMessage(CsMsgId msgId, byte[] body)
        {
            try
            {
                // Get enum name (e.g., "CsSceneRepatriate" from CsMsgId.CsSceneRepatriate)
                string? msgName = Enum.GetName(typeof(CsMsgId), msgId);
                if (string.IsNullOrWhiteSpace(msgName))
                {
                    return null;
                }

                // Try to find the message type in the protocol assembly
                Assembly protocolAssembly = typeof(CsLogin).Assembly;
                Type? messageType = protocolAssembly.GetType($"Campofinale.Protocol.{msgName}")
                                  ?? protocolAssembly.GetType(msgName);

                if (messageType == null)
                {
                    return null;
                }

                // Get the Parser property (static property on all protobuf message types)
                PropertyInfo? parserProperty = messageType.GetProperty("Parser",
                    BindingFlags.Public | BindingFlags.Static);

                if (parserProperty == null)
                {
                    return null;
                }

                // Get the parser instance and parse the message
                if (parserProperty.GetValue(null) is MessageParser parser)
                {
                    return parser.ParseFrom(body);
                }

                return null;
            }
            catch (Exception)
            {
                return null;
            }
        }
    }
}

