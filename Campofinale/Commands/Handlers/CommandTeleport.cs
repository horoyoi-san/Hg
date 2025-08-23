using static Campofinale.Resource.ResourceManager;
using Campofinale.Packets.Sc;
using MongoDB.Bson;
using System.Globalization;

namespace Campofinale.Commands.Handlers
{
    public class CommandTeleport
    {
        [Server.Command("tp", "Teleports player", true)]
        public static void Handle(Player sender, string cmd, string[] args, Player target) 
        {
            if (args.Length < 3)
            {
                CommandManager.SendMessage(sender, "Use: /tp (x) (y) (z)\nYou can use ~ to use current player coordinate");
                CommandManager.SendMessage(sender, $"\nCurrent player position: {target.position.ToJson()}");
                return;
            }

            for (int i=0; i < args.Length; i++) 
            {
                args[i] = args[i].Replace(",", ".");
            }

            float[] pos = [target.position.x, target.position.y, target.position.z];

            for (int i=0; i < args.Length; i++) {
                if(args[i] == "~") continue;
                
                float curPos = pos[i];
                pos[i] = float.Parse(args[i].StartsWith("--") ? args[i].Trim('-') : args[i], CultureInfo.InvariantCulture);
                if (args[i].StartsWith('+')) pos[i] += curPos;
                if (args[i].StartsWith("--")) pos[i] = curPos - pos[i];
            }

            Vector3f position = new Vector3f(new Vector()
            {
                X = pos[0],
                Y = pos[1],
                Z = pos[2]
            });

            target.position = position;
            target.Send(new PacketScEnterSceneNotify(target, target.curSceneNumId, position));
            CommandManager.SendMessage(sender, $"Player teleported to {target.position.ToJson()}");
        }
    }
}
