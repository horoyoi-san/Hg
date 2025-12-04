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
        if(args.Length < 2) 
        {
            CommandManager.SendMessage(sender, "Use: /give (item|weapon|char) (item/weapon/char id/all) (amount/lvl) [Note: all is available only for items right now]");
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
                        foreach (var i in itemTable)
                        {
                            if (i.Value.GetStorage() != ItemStorageSpace.BagAndFactoryDepot)
                            {
                                if (i.Value.maxStackCount == -1)
                                {
                                    target.inventoryManager.items.Add(new Item(target.roleId, i.Value.id, 100000));
                                }
                                else
                                {
                                    target.inventoryManager.items.Add(new Item(target.roleId, i.Value.id, i.Value.maxStackCount));
                                }
                            }
                        }
                        foreach(ItemValuableDepotType type in Enum.GetValues(typeof(ItemValuableDepotType)))
                        {
                            target.Send(new PacketScItemBagScopeSync(target, type));
                        }
                       
                        target.Send(new PacketScSyncWallet(target));
                        break;
                        return;
                    }
                    Item item=target.inventoryManager.AddItem(args[1], int.Parse(args[2]));
                    message = $"Item {args[1]} was added to {target.nickname}";
                    target.Send(new PacketScItemBagScopeModify(target, item));
                    target.Send(new PacketScSyncWallet(target));
                    break;

                case "weapon":
                    Item wep = target.inventoryManager.AddWeapon(args[1], Convert.ToUInt64(args[2]));
                    message = $"Weapon {args[1]} was added to {target.nickname}";
                    target.Send(new PacketScItemBagScopeModify(target, wep));
                    break;

                case "char":
                    int lvl = int.Parse(args[2]);

                    if(lvl < 1 || lvl > 99) 
                    {
                        CommandManager.SendMessage(sender, "Level can't be less than 1 or more than 99");
                        return;
                    }

                    Character character = new Character(target.roleId, args[1], lvl);

                    if(target.chars.Find(c => c.id == character.id) != null) 
                    {
                        CommandManager.SendMessage(sender, "Character already exists");
                        return;
                    }

                    if(lvl <= 20) character.breakNode = "";
                    if(lvl > 20 && lvl <= 40) character.breakNode = "charBreak20";
                    if(lvl > 40 && lvl <= 60) character.breakNode = "charBreak40";
                    if(lvl > 60 && lvl <= 80) character.breakNode = "charBreak60";
                    if(lvl > 80) character.breakNode = "charBreak70";
                    
                    target.chars.Add(character);
                    target.SaveCharacters();
                    
                    message = $"Character {character.id} was added to {target.nickname}.";
                    CommandManager.SendMessage(sender, message);
                    target.Send(new PacketScCharBagAddChar(target, character));
                    Item weapon = target.inventoryManager.items.Find(i => i.guid == character.weaponGuid);
                    if(weapon!=null)target.Send(new PacketScItemBagScopeModify(target, weapon));
                    return;
                
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
