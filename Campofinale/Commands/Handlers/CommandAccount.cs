using Campofinale.Database;

namespace Campofinale.Commands.Handlers
{
    public static class CommandAccount
    {
        [Server.Command("account", "account command")]
        public static void Handle(Player sender, string cmd, string[] args, Player target)
        {
            if (sender != null)
            {
                CommandManager.SendMessage(sender, "This command can't be used ingame");
                return;
            }
            if (args.Length < 2)
            {
                defaultResponse(sender);
                return;
            }
            string username = purifyUsername(args[1]);
            if (username == "")
            {
                CommandManager.SendMessage(sender, "Username is invalid");
                return;
            }
            switch (args[0].ToLower())
            {
                case "create":
                    var (message, code) = DatabaseManager.db.CreateAccount(username, args.Length > 2 ? args[2] : "");
                    CommandManager.SendMessage(sender, message);
                    break;
                case "reset":
                    Account account = DatabaseManager.db.GetAccountByUsername(username);
                    if (account == null)
                    {
                        CommandManager.SendMessage(sender, $"Account with username '{username}' not found.");
                        return;
                    }
                    // If player is online, disconnect them first
                    Player onlinePlayer = Server.clients.Find(p => p.accountId == account.id);
                    if (onlinePlayer != null)
                    {
                        onlinePlayer.Disconnect();
                        CommandManager.SendMessage(sender, $"Disconnected online player with account {account.id}.");
                    }
                    bool success = DatabaseManager.db.ResetAccount(account.id);
                    if (success)
                    {
                        CommandManager.SendMessage(sender, $"Account '{username}' (ID: {account.id}) has been reset. All player data deleted. Player will start fresh on next login.");
                    }
                    else
                    {
                        CommandManager.SendMessage(sender, $"Failed to reset account '{username}'. Check server logs for details.");
                    }
                    break;
                case "delete":
                    Account accountToDelete = DatabaseManager.db.GetAccountByUsername(username);
                    if (accountToDelete == null)
                    {
                        CommandManager.SendMessage(sender, $"Account with username '{username}' not found.");
                        return;
                    }
                    // If player is online, disconnect them first
                    Player onlinePlayerToDelete = Server.clients.Find(p => p.accountId == accountToDelete.id);
                    if (onlinePlayerToDelete != null)
                    {
                        onlinePlayerToDelete.Disconnect();
                        CommandManager.SendMessage(sender, $"Disconnected online player with account {accountToDelete.id}.");
                    }
                    // First reset all player data, then delete account
                    DatabaseManager.db.ResetAccount(accountToDelete.id);
                    bool deleteSuccess = DatabaseManager.db.DeleteAccount(accountToDelete.id);
                    if (deleteSuccess)
                    {
                        CommandManager.SendMessage(sender, $"Account '{username}' (ID: {accountToDelete.id}) has been completely deleted from database.");
                    }
                    else
                    {
                        CommandManager.SendMessage(sender, $"Failed to delete account '{username}'. Check server logs for details.");
                    }
                    break;
                default:
                    defaultResponse(sender);
                    break;
            }
        }

        private static void defaultResponse(Player? sender)
        {
            CommandManager.SendMessage(sender, "Usage: account create|reset|delete <username> <uid> (uid is optional)");
            CommandManager.SendMessage(sender, "  create <username> <uid> - Create a new account");
            CommandManager.SendMessage(sender, "  reset <username>  - Reset account data (keeps account, deletes all player data)");
            CommandManager.SendMessage(sender, "  delete <username> - Delete account completely (including account record)");
        }

        private static string purifyUsername(string username)
        {
            // Handle null or empty input
            if (string.IsNullOrEmpty(username))
            {
                return "";
            }

            // Find the position of '@' symbol
            int atIndex = username.IndexOf('@');
            if (atIndex >= 0)
            {
                // Extract username part before '@'
                username = username.Substring(0, atIndex);
            }

            // Trim whitespace from start and end, but preserve internal spaces
            return username.Trim();
        }
    }
}
