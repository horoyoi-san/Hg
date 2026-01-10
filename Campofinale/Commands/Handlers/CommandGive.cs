using Campofinale.Game.Char;
using Campofinale.Game.Inventory;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using Campofinale.Resource;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Commands.Handlers;

public static class CommandGive
{
    [Server.Command("give", "Give items, weapons or characters", true)]
    public static void Handle(Player sender, string cmd, string[] args, Player target)
    {
        if (args.Length < 2)
        {
            CommandManager.SendMessage(sender, "Use: /give (item|weapon|char|equip) (item/weapon/char id/all) (amount/lvl) [Note: all is available only for items right now]");
            return;
        }

        string message = "";
        try
        {
            switch (args[0])
            {
                case "item":
                    if (args[1] == "all")
                    {
                        // Add all items from ItemTable.json, each 10000
                        const int allAmount = 10000;
                        var allItemIds = itemTable.Keys.ToList();
                        int addedCount = 0;

                        foreach (string itemId in allItemIds)
                        {
                            try
                            {
                                target.inventoryManager.AddItem(itemId, allAmount, notify: false);
                                addedCount++;
                            }
                            catch (Exception)
                            {
                                // Silently skip items that can't be added (e.g., non-item entries)
                            }
                        }

                        // add extra money
                        target.inventoryManager.AddItem("item_diamond", 1000000, notify: false);
                        target.inventoryManager.AddItem("item_gold", 1000000, notify: false);
                        target.inventoryManager.AddItem("item_originium_recharge", 1000000, notify: false);
                        target.inventoryManager.AddItem("item_domain_tundra_coupon", 1000000, notify: false);
                        target.inventoryManager.AddItem("item_domain_jinlong_coupon", 1000000, notify: false);

                        // Batch send all inventory sync packets to refresh all depots
                        foreach (ItemValuableDepotType type in Enum.GetValues<ItemValuableDepotType>())
                        {
                            if (type != ItemValuableDepotType.Invalid)
                            {
                                target.Send(new PacketScItemBagScopeSync(target, type));
                            }
                        }
                        target.Send(new PacketScSyncWallet(target));
                        target.Save(); // Save complete player state to database
                        message = $"Added {addedCount} items to {target.nickname}";
                        break;
                    }

                    // Check if the third argument exists and is a valid integer
                    if (args.Length < 3 || !int.TryParse(args[2], out int amount))
                    {
                        CommandManager.SendMessage(sender, "Amount must be a number");
                        return;
                    }

                    var targetItemId = args[1];
                    Item item = target.inventoryManager.AddItem(targetItemId, amount, notify: true);
                    message = $"Item {targetItemId} was added to {target.nickname}";
                    target.Send(new PacketScItemBagScopeSync(target, item.ItemType));
                    target.Send(new PacketScSyncWallet(target));
                    target.Save();
                    break;

                case "weapon":
                    if (args.Length < 3 || !int.TryParse(args[2], out int amount2))
                    {
                        CommandManager.SendMessage(sender, "Amount must be a number");
                        return;
                    }
                    Item wep = target.inventoryManager.AddWeapon(args[1], Convert.ToUInt64(args[2]));
                    message = $"Weapon {args[1]} was added to {target.nickname}";
                    // Weapons are instance type items, send both Modify and Sync packets
                    // Modify packet notifies the change, Sync packet refreshes the entire depot view
                    target.Send(new PacketScItemBagScopeModify(target, wep));
                    target.Send(new PacketScItemBagScopeSync(target, wep.ItemType));
                    target.Save(); // Save complete player state to database
                    break;

                case "char":
                    int lvl = int.Parse(args[2]);
                    var charId = args[1];

                    if (lvl < 1 || lvl > 99)
                    {
                        CommandManager.SendMessage(sender, "Level can't be less than 1 or more than 99");
                        return;
                    }

                    bool isNewCharacter = false;
                    // if character already exists, use the existing one and level it up.
                    Character? character = target.chars.Find(c => c.id == charId);
                    if (character == null)
                    {
                        character = new Character(target.roleId, charId, lvl); ;
                        isNewCharacter = true;
                    }
                    else
                    {
                        character.level = lvl;
                    }

                    if (lvl <= 20) character.breakNode = "";
                    if (lvl > 20 && lvl <= 40) character.breakNode = "charBreak20";
                    if (lvl > 40 && lvl <= 60) character.breakNode = "charBreak40";
                    if (lvl > 60 && lvl <= 80) character.breakNode = "charBreak60";
                    if (lvl > 80) character.breakNode = "charBreak70";

                    if (isNewCharacter)
                    {
                        target.chars.Add(character);
                        target.Send(new PacketScCharBagAddChar(target, character));
                    }
                    else
                    {
                        target.Send(new PacketScSyncCharBagInfo(target));
                    }
                    target.SaveCharacters();
                    target.Save(); // Save complete player state to database

                    message = $"Character {character.id} was added to {target.nickname}.";
                    CommandManager.SendMessage(sender, message);
                    Item weapon = target.inventoryManager.items.Find(i => i.guid == character.weaponGuid);
                    if (weapon != null) target.Send(new PacketScItemBagScopeModify(target, weapon));
                    return;

                // give all equipment
                case "equip":
                    {
                        var allEquipIds = equipTable.Keys.ToList();

                        foreach (string equipId in allEquipIds)
                        {
                            target.inventoryManager.AddItem(equipId, 1, notify: false);
                        }
                        message = $"Equipment was added to {target.nickname}";
                        target.Send(new PacketScItemBagScopeSync(target, ItemValuableDepotType.Equip));
                        target.Save();
                        break;
                    }
                default:
                    CommandManager.SendMessage(sender, "Unknown argument, use item, weapon or character");
                    return;
            }


            CommandManager.SendMessage(sender, $"{message}.");
        }
        catch (Exception err)
        {
            CommandManager.SendMessage(sender, $"An error occurred: {err}");
        }
    }
}
