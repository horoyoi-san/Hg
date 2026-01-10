using Campofinale.Resource;
using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.IdGenerators;
using static Campofinale.Resource.ResourceManager;
using Google.Protobuf.Collections;
using Campofinale.Packets.Sc;
using Campofinale.Protocol;
using StardustUtils;

namespace Campofinale.Game.Inventory
{
    /// <summary>
    /// Represents an item instance in the game.
    /// Stores only dynamic data (level, xp, owner, etc.) - static configuration data is loaded from ResourceManager tables.
    /// </summary>
    public class Item
    {
        // ===== Database Fields =====
        [BsonId(IdGenerator = typeof(ObjectIdGenerator))]
        public ObjectId _id { get; set; }
        [BsonElement("templateId")]
        public string id; // Item template ID, references ItemTable and potentially EquipTable
        public ulong guid;

        // ===== Common Fields =====
        private int _amount = 1;
        /// <summary>
        /// Item stack count. For instance-type items (maxStackCount == 1), amount is always forced to 1.
        /// </summary>
        [BsonElement("amount")]
        public int amount
        {
            get => _amount;
            set
            {
                if (!string.IsNullOrEmpty(id))
                {
                    ItemTable? itemConfig = ResourceManager.GetItemTable(id);
                    if (itemConfig != null && itemConfig.maxStackCount == 1)
                    {
                        _amount = 1;
                        return;
                    }
                }
                _amount = value;
            }
        }

        public ulong owner; // Player role ID who owns this item
        public bool locked = false; // Whether item is locked from being discarded/consumed

        // ===== Instance-Specific Fields (Equipment/Weapon) =====
        public ulong level = 1; // Current level (can be upgraded)
        public ulong xp; // Experience points for leveling up
        public ulong breakthroughLv; // Breakthrough level (ascension)
        public ulong refineLv; // Refinement level
        public ulong attachGemId; // Attached gem instance ID (for weapons)

        /// <summary>
        /// Equipment attribute enhancement levels.
        /// Key: attrIndex (from EquipTable.equipAttrModifiers)
        /// Value: enhancement level (0-3, indexes into equipAttrModifiers[i].attrValues array)
        /// Example: {0: 2, 1: 1} means first attribute enhanced to level 2, second to level 1
        /// </summary>
        public Dictionary<int, int> enhanceAttrLevels = new();

        // ===== Runtime Fields (Not Stored in DB) =====
        [BsonIgnore]
        public ItemTable ItemConfig => ResourceManager.GetItemTable(id);
        [BsonIgnore]
        public EquipTable? EquipConfig =>
            ResourceManager.equipTable.TryGetValue(id, out var config) ? config : null;

        public Item()
        {
        }
        public Item(ulong owner, string id, int amt)
        {
            this.owner = owner;
            this.id = id;
            this.amount = amt;
            guid = GetOwner().random.Next();
        }
        public Item(ulong owner, string id, ulong level)
        {
            this.owner = owner;
            this.id = id;
            this.amount = 1;
            this.level = level;
            guid = GetOwner().random.Next();
        }
        // ===== Item Classification Methods =====
        /// <summary>
        /// Gets the storage space type for this item from ItemTypeTable.
        /// </summary>
        public ItemStorageSpace StorageSpace()
        {
            ItemTable itemConfig = ResourceManager.GetItemTable(id);
            int itemType = itemConfig.type;

            if (ResourceManager.itemTypeTable.TryGetValue(itemType, out var itemTypeConfig))
            {
                return itemTypeConfig.storageSpace;
            }

            // Fallback to legacy logic
            return itemConfig.maxBackpackStackCount < 0
                ? ItemStorageSpace.ValuableDepot
                : ItemStorageSpace.BagAndFactoryDepot;
        }
        public ItemValuableDepotType ItemType
        {
            get
            {
                ItemTable itemConfig = GetItemTable();
                ItemValuableDepotType type = itemConfig.valuableTabType;

                // Reroute open-world gatherables (Factory items with positive backpack stack) to bag
                if (type == ItemValuableDepotType.Factory && itemConfig.maxBackpackStackCount > 0)
                {
                    return ItemValuableDepotType.SpecialItem;
                }

                return type;
            }
        }
        public bool InstanceType()
        {
            switch (ItemType)
            {
                case ItemValuableDepotType.Weapon:
                case ItemValuableDepotType.WeaponGem:
                case ItemValuableDepotType.Equip:
                case ItemValuableDepotType.MissionItem:
                    return true;
                default:
                    return false;
            }
        }
        // ===== Equipment-Specific Methods =====
        /// <summary>
        /// Gets default level for item creation based on item type.
        /// </summary>
        public ulong GetDefaultLevel()
        {
            switch (ItemType)
            {
                case ItemValuableDepotType.Weapon:
                    return 1;
                case ItemValuableDepotType.Equip:
                    return EquipConfig?.minWearLv ?? 1;
                default:
                    return 0;
            }
        }
        /// <summary>
        /// Gets equipment attribute modifiers from EquipTable.
        /// Returns empty list if not an equipment item.
        /// </summary>
        public List<AttributeModifier> GetEquipAttributeModifier()
        {
            return EquipConfig?.equipAttrModifiers ?? new List<AttributeModifier>();
        }
        public ItemTable GetItemTable()
        {
            return ResourceManager.GetItemTable(id);
        }
        /// <summary>
        /// Converts this item to protobuf message format for network transmission.
        /// </summary>
        public virtual ScdItemGrid ToProto()
        {
            try
            {
                switch (ItemType)
                {
                    case ItemValuableDepotType.WeaponGem:
                        return new ScdItemGrid()
                        {
                            Count = 1,
                            Id = id,
                            Inst = new()
                            {
                                InstId = guid,
                                Gem = new()
                                {
                                    GemId = guid,
                                    TemplateId = ResourceManager.GetItemTemplateId(id),
                                    WeaponId = GetOwner().inventoryManager.items.Find(i => i.attachGemId == guid)?.guid ?? 0,
                                },
                                IsLock = locked
                            }
                        };

                    case ItemValuableDepotType.Weapon:
                        Player? owner = GetOwner();
                        return new ScdItemGrid()
                        {
                            Count = 1,
                            Id = id,
                            Inst = new()
                            {
                                InstId = guid,
                                Weapon = new()
                                {
                                    InstId = guid,
                                    TemplateId = ResourceManager.GetItemTemplateId(id),
                                    Exp = xp,
                                    WeaponLv = level,
                                    RefineLv = refineLv,
                                    BreakthroughLv = breakthroughLv,
                                    EquipCharId = owner?.chars.Find(c => c.weaponGuid == guid)?.guid ?? 0,
                                    AttachGemId = attachGemId,
                                },
                                IsLock = locked
                            }
                        };

                    case ItemValuableDepotType.Equip:
                        Player? equipOwner = GetOwner();
                        int templateId = ResourceManager.GetItemTemplateId(id);

                        if (templateId == 0)
                        {
                            Logger.PrintWarn($"[Item.ToProto] Equipment {id} has invalid templateId (0)");
                        }
                        ScdItemGrid equip = new ScdItemGrid()
                        {
                            Count = 1,
                            Id = id,
                            Inst = new()
                            {
                                InstId = guid,
                                Equip = new()
                                {
                                    EquipCharId = equipOwner?.chars.Find(c => c.IsEquipped(guid))?.guid ?? 0,
                                    Equipid = guid,
                                    Templateid = templateId,
                                },
                                IsLock = locked
                            }
                        };

                        // avoid duplicates
                        var addedIndices = new HashSet<int>();
                        foreach (var modifier in GetEquipAttributeModifier())
                        {
                            if (modifier.attrValues == null || modifier.attrValues.Count == 0)
                                continue;

                            if (addedIndices.Contains(modifier.attrIndex))
                            {
                                Logger.PrintWarn($"[Item.ToProto] Duplicate attrIndex {modifier.attrIndex} in equipment {id}, skipping");
                                continue;
                            }

                            int enhanceLevel = enhanceAttrLevels.GetValueOrDefault(modifier.attrIndex, 0);
                            enhanceLevel = Math.Clamp(enhanceLevel, 0, modifier.attrValues.Count - 1);

                            equip.Inst.Equip.Enhance.Add(modifier.attrIndex, enhanceLevel);
                            addedIndices.Add(modifier.attrIndex);
                        }
                        return equip;

                    default:
                        return new ScdItemGrid()
                        {
                            Count = amount,
                            Id = id,
                        };
                }
            }
            catch (Exception e)
            {
                Logger.PrintError($"[Item.ToProto] Error converting item {id} to proto: {e.Message}");
                return new ScdItemGrid()
                {
                    Count = amount,
                    Id = id,
                };
            }
        }
        public Player GetOwner()
        {
            return Server.clients.Find(c => c.roleId == this.owner);
        }

        /// <summary>
        /// Calculates resulting level, gold cost, and remaining XP after adding experience.
        /// </summary>
        public (ulong newLevel, ulong goldCost, ulong remainingXp) CalculateLevelAndGoldCost(ulong addedXp)
        {
            ulong gold = 0;
            ulong curLevel = this.level;
            WeaponBasicTable table = ResourceManager.weaponBasicTable[id];
            WeaponUpgradeTemplateTable upgradeTable = ResourceManager.weaponUpgradeTemplateTable[table.levelTemplateId];
            while (addedXp >= upgradeTable.list.Find(c => c.weaponLv == curLevel).lvUpExp)
            {
                gold += upgradeTable.list.Find(c => c.weaponLv == curLevel).lvUpGold;
                addedXp -= upgradeTable.list.Find(c => c.weaponLv == curLevel).lvUpExp;
                curLevel++;
                if (curLevel >= 80)
                {
                    curLevel = 80;
                    break;
                }
            }
            return (curLevel, gold, addedXp);
        }
        public ulong GetMaterialExp(string id)
        {
            switch (id)
            {
                case "item_weapon_expcard_low":
                    return 200;
                case "item_weapon_expcard_mid":
                    return 1000;
                case "item_weapon_expcard_high":
                    return 10000;
                default:
                    return 0;
            }
        }
        public void LevelUp(MapField<string, ulong> costItemId2Count, RepeatedField<ulong> costWeaponIds)
        {
            // TODO: add exp from costWeapons
            ulong addedXp = 0;
            foreach (var material in costItemId2Count)
            {
                addedXp += GetMaterialExp(material.Key) * material.Value;
            }

            (ulong newLevel, ulong goldCost, ulong remainingXp) = CalculateLevelAndGoldCost(xp + addedXp);

            costItemId2Count.Add("item_gold", goldCost);

            if (GetOwner().inventoryManager.ConsumeItems(costItemId2Count))
            {
                this.level = newLevel;
                this.xp = remainingXp;

                ScWeaponAddExp levelUp = new()
                {
                    Weaponid = guid,
                    WeaponLv = level,
                    NewExp = xp,
                };
                GetOwner().Send(ScMsgId.ScWeaponAddExp, levelUp);
                GetOwner().Send(new PacketScSyncWallet(GetOwner()));
            }
        }
    }
}