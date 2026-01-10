using static Campofinale.Resource.ResourceManager;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Utils;
using MongoDB.Bson;
using System.Globalization;

namespace Campofinale.Commands.Handlers
{
    public static class CommandMove
    {
        [Server.Command("mv", "Moves player by direction and distance", true)]
        public static void Handle(Player sender, string cmd, string[] args, Player target)
        {
            if (args.Length < 2)
            {
                CommandManager.SendMessage(sender, "Use: /mv (direction|deg) (distance) [direction|deg] [distance]");
                CommandManager.SendMessage(sender, "Direction accepts w/s/a/d, up/down, or a degree offset relative to the current facing.");
                return;
            }

            // Parse first vector
            if (!ParseVector(args, 0, out float offsetX1, out float offsetY1, out float offsetZ1, target.rotation.y))
            {
                CommandManager.SendMessage(sender, "Invalid first vector parameters.");
                return;
            }

            // Parse second vector if provided (4 or more args)
            float offsetX2 = 0f, offsetY2 = 0f, offsetZ2 = 0f;
            if (args.Length >= 4)
            {
                if (!ParseVector(args, 2, out offsetX2, out offsetY2, out offsetZ2, target.rotation.y))
                {
                    CommandManager.SendMessage(sender, "Invalid second vector parameters.");
                    return;
                }
            }

            // Combine both vectors
            Vector3f position = new Vector3f(
                target.position.x + offsetX1 + offsetX2,
                target.position.y + offsetY1 + offsetY2,
                target.position.z + offsetZ1 + offsetZ2
            );

            target.position = position;

            // Use ScSceneTeleport with ServerTime and TpUuid for proper in-scene teleportation
            uint unixTimestamp = (uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            var generator = new SnowflakeIdGenerator(machineId: 1);
            long id = generator.GenerateId();

            var teleport = new ScSceneTeleport
            {
                SceneNumId = target.curSceneNumId,
                Position = position.ToProto(),
                Rotation = target.rotation.ToProto(),
                TeleportReason = 0,
                ServerTime = unixTimestamp,
                TpUuid = (ulong)id
            };

            ulong leaderId = target.teams.Count > target.teamIndex
                ? target.teams[target.teamIndex].leader
                : 0;
            if (leaderId != 0)
            {
                teleport.ObjIdList.Add(leaderId);
            }

            target.Send(ScMsgId.ScSceneTeleport, teleport);
            CommandManager.SendMessage(sender, $"Player moved to {target.position.ToJson()}");
        }

        // Parse a single vector from args starting at startIndex
        // Returns true if successful, false otherwise
        private static bool ParseVector(string[] args, int startIndex, out float offsetX, out float offsetY, out float offsetZ, float yaw)
        {
            offsetX = 0f;
            offsetY = 0f;
            offsetZ = 0f;

            if (startIndex + 1 >= args.Length)
                return false;

            // Parse distance
            if (!float.TryParse(args[startIndex + 1].Replace(",", "."), NumberStyles.Float, CultureInfo.InvariantCulture, out float distance))
            {
                return false;
            }

            // Parse direction
            float directionDegrees;
            bool isVerticalMovement = false;
            float verticalOffset = 0f;
            string directionArg = args[startIndex].ToLowerInvariant();

            switch (directionArg)
            {
                case "up":
                    // Allow moving upwards along the vertical axis.
                    isVerticalMovement = true;
                    verticalOffset = distance;
                    directionDegrees = 0f;
                    break;
                case "down":
                    // Allow moving downwards along the vertical axis.
                    isVerticalMovement = true;
                    verticalOffset = -distance;
                    directionDegrees = 0f;
                    break;
                case "w":
                    directionDegrees = 0f;
                    break;
                case "s":
                    directionDegrees = 180f;
                    break;
                case "a":
                    directionDegrees = -90f;
                    break;
                case "d":
                    directionDegrees = 90f;
                    break;
                default:
                    if (!float.TryParse(args[startIndex].Replace(",", "."), NumberStyles.Float, CultureInfo.InvariantCulture, out directionDegrees))
                    {
                        return false;
                    }
                    break;
            }

            // Calculate horizontal displacement relative to the player's yaw.
            float finalDegrees = yaw + directionDegrees;
            float radians = finalDegrees * (MathF.PI / 180f);
            offsetX = MathF.Sin(radians) * distance;
            offsetZ = MathF.Cos(radians) * distance;

            if (isVerticalMovement)
            {
                // Prevent unintended horizontal displacement when moving vertically.
                offsetX = 0f;
                offsetZ = 0f;
            }

            offsetY = verticalOffset;
            return true;
        }
    }
}

