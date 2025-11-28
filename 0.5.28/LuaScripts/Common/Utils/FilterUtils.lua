local CALC_TYPE = { AND = "AND", OR = "OR", }
BASIC_FILTER_CONFIG = { DEPOT_WEAPON = { { title = Language.LUA_WIKI_FILTER_GROUP_NAME_WEAPON_TYPE, tags = { { groupType = "WeaponType", name = Language[string.format("LUA_WEAPON_TYPE_%d", GEnums.WeaponType.Sword:ToInt())], funcName = "_filterByWeaponType", param = GEnums.WeaponType.Sword, }, { groupType = "WeaponType", name = Language[string.format("LUA_WEAPON_TYPE_%d", GEnums.WeaponType.Wand:ToInt())], funcName = "_filterByWeaponType", param = GEnums.WeaponType.Wand, }, { groupType = "WeaponType", name = Language[string.format("LUA_WEAPON_TYPE_%d", GEnums.WeaponType.Claymores:ToInt())], funcName = "_filterByWeaponType", param = GEnums.WeaponType.Claymores, }, { groupType = "WeaponType", name = Language[string.format("LUA_WEAPON_TYPE_%d", GEnums.WeaponType.Lance:ToInt())], funcName = "_filterByWeaponType", param = GEnums.WeaponType.Lance, }, { groupType = "WeaponType", name = Language[string.format("LUA_WEAPON_TYPE_%d", GEnums.WeaponType.Pistol:ToInt())], funcName = "_filterByWeaponType", param = GEnums.WeaponType.Pistol, }, } }, { title = Language.LUA_ITEM_FILTER_GROUP_TITLE_RARITY, tags = { { groupType = "WeaponRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 3), funcName = "_filterByRarity", param = 3, }, { groupType = "WeaponRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 4), funcName = "_filterByRarity", param = 4, }, { groupType = "WeaponRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 5), funcName = "_filterByRarity", param = 5, }, { groupType = "WeaponRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 6), funcName = "_filterByRarity", param = 6, }, } }, }, DEPOT_WEAPON_DESTROY = { { tags = { { name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 2), funcName = "_filterByRarity", param = 2, }, { name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 3), funcName = "_filterByRarity", param = 3, }, { name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 4), funcName = "_filterByRarity", param = 4, }, { name = Language.LUA_DEPOT_FILTER_OPTION_UNLOCK, funcName = "_filterByUnlock", param = true, }, } } }, DEPOT_EQUIP_DESTROY = { { title = Language.LUA_ITEM_FILTER_GROUP_TITLE_RARITY, tags = { { groupType = "EquipRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 1), funcName = "_filterByRarity", param = 1, }, { groupType = "EquipRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 2), funcName = "_filterByRarity", param = 2, }, { groupType = "EquipRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 3), funcName = "_filterByRarity", param = 3, }, { groupType = "EquipRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 4), funcName = "_filterByRarity", param = 4, }, { groupType = "EquipRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 5), funcName = "_filterByRarity", param = 5, }, } }, { title = Language.LUA_ITEM_FILTER_GROUP_UNLOCK, tags = { { groupType = "EquipUnlock", name = Language.LUA_DEPOT_FILTER_OPTION_UNLOCK, funcName = "_filterByUnlock", param = true, }, } }, }, }
FILTER_EQUIP_GROUP_PART_TYPE = { title = Language.LUA_DEPOT_FILTER_GROUP_TITLE_EQUIP_TYPE, tags = { { groupType = "EquipType", name = Language.LUA_WIKI_FILTER_NAME_EQUIP_PART_BODY, funcName = "_filterByPartType", param = GEnums.PartType.Body, }, { groupType = "EquipType", name = Language.LUA_WIKI_FILTER_NAME_EQUIP_PART_HAND, funcName = "_filterByPartType", param = GEnums.PartType.Hand, }, { groupType = "EquipType", name = Language.LUA_WIKI_FILTER_NAME_EQUIP_PART_EDC, funcName = "_filterByPartType", param = GEnums.PartType.EDC, }, } }
FILTER_EQUIP_GROUP_ENHANCE = { title = Language.LUA_DEPOT_FILTER_GROUP_TITLE_PRODUCTION_TYPE, tags = { { groupType = "ProductionType", name = Language.LUA_DEPOT_FILTER_OPTION_ENHANCE_EQUIP, funcName = "_filterByEnhanceEquip", param = true, }, } }
FILTER_CHAR_INFO_WEAPON = { { title = Language.LUA_ITEM_FILTER_GROUP_TITLE_RARITY, tags = { { groupType = "WeaponRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 3), funcName = "_filterByRarity", param = 3, }, { groupType = "WeaponRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 4), funcName = "_filterByRarity", param = 4, }, { groupType = "WeaponRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 5), funcName = "_filterByRarity", param = 5, }, { groupType = "WeaponRarity", name = string.format(Language.LUA_DEPOT_FILTER_OPTION_RARITY, 6), funcName = "_filterByRarity", param = 6, }, } } }
FILTER_GEM_ENABLE_ON_WEAPON = { title = Language.LUA_GEM_ENABLE_ON_WEAPON_TITLE, tags = { { groupType = "GemEnableOnWeapon", name = Language.LUA_GEM_ENABLE_ON_WEAPON, funcName = "_filterByGemEnableOnWeapon", param = true, }, } }
EQUIP_PART_FILTER_TYPE = { GEnums.CraftShowingType.EquipBody, GEnums.CraftShowingType.EquipHead, GEnums.CraftShowingType.EquipRing }
FILTER_EQUIP_PRODUCE_GROUP_SUFFICIENCY = { title = Language.LUA_EQUIP_PRODUCE_FILTER_GROUP_TITLE_SUFFICIENCY, tags = { { groupType = "EquipProduceSufficiency", name = Language.LUA_EQUIP_PRODUCE_FILTER_NAME_SUFFICIENCY, funcName = "_filterByEquipProduceSufficiency", param = true, } } }
FILTER_EQUIP_FORMULA_GROUP_LOCKED = { title = Language.LUA_EQUIP_FORMULA_FILTER_GROUP_TITLE_LOCKED, tags = { { groupType = "EquipFormulaLocked", name = Language.LUA_EQUIP_FORMULA_FILTER_NAME_LOCKED, funcName = "_filterByEquipFormulaLocked", param = true, }, { groupType = "EquipFormulaLocked", name = Language.LUA_EQUIP_FORMULA_FILTER_NAME_UNLOCKED, funcName = "_filterByEquipFormulaLocked", param = false, } } }
FILTER_EQUIP_ENHANCED_GROUP = { title = Language.LUA_EQUIP_ENHANCED_FILTER_GROUP_TITLE_ENHANCED, tags = { { groupType = "EquipEnhanced", name = Language.LUA_EQUIP_ENHANCE_FILTER_NAME_ENHANCED, funcName = "_filterByEquipEnhanced", param = true, }, } }
function processItemDefault(itemId, instId)
    local _, itemData = Tables.itemTable:TryGetValue(itemId)
    if not itemData then
        logger.error("itemData is nil, templateId: " .. itemId)
        return nil
    end
    local indexId = instId
    if indexId == nil or indexId == 0 then
        indexId = itemId
    end
    local info = { id = itemId, instId = instId, indexId = indexId, data = itemData, rarity = itemData.rarity, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2, }
    local isNew = instId and GameInstance.player.inventory:IsNewItem(itemId, instId) or GameInstance.player.inventory:IsNewItem(itemId)
    info.newOrder = isNew and 1 or 0
    info.realId = instId and (itemId .. instId) or itemId
    return info
end
function processWeaponUpgradeIngredient(templateId, instId)
    local infoDefault
    local isWeapon = instId ~= nil and instId > 0
    if isWeapon then
        infoDefault = processWeapon(templateId, instId)
        infoDefault.forceSortKey = 0
        infoDefault.forceSortKeyReverse = 0
    else
        infoDefault = processItemDefault(templateId, instId)
        infoDefault.forceSortKey = infoDefault.rarity
        infoDefault.forceSortKeyReverse = -infoDefault.rarity
    end
    if not infoDefault then
        return nil
    end
    infoDefault.inventoryCount = isWeapon and 1 or Utils.getItemCount(templateId)
    infoDefault.ingredientIndex = infoDefault.rarity
    infoDefault.isWeapon = isWeapon
    return infoDefault
end
function processWeapon(templateId, instId)
    local infoDefault = processItemDefault(templateId, instId)
    if not infoDefault then
        return nil
    end
    local weaponInst = CharInfoUtils.getWeaponByInstId(instId)
    if not weaponInst then
        return nil
    end
    local weaponCfg = Tables.weaponBasicTable:GetValue(templateId)
    if not weaponCfg then
        return nil
    end
    infoDefault.weaponLv = weaponInst.weaponLv
    infoDefault.weaponType = weaponCfg.weaponType
    infoDefault.isWeapon = true
    return infoDefault
end
function processWeaponPotential(templateId, instId)
    local infoWeapon = processWeapon(templateId, instId)
    local weaponInst = CharInfoUtils.getWeaponByInstId(instId)
    infoWeapon.noGemAttached = weaponInst.attachedGemInstId <= 0 and 1 or 0
    return infoWeapon
end
function processWeaponGem(templateId, instId, extraArgs)
    local infoDefault = processItemDefault(templateId, instId)
    if not infoDefault then
        return nil
    end
    if not instId then
        return infoDefault
    end
    local gemInst = CharInfoUtils.getGemByInstId(instId)
    if not gemInst then
        return infoDefault
    end
    infoDefault.enableOnWeapon = false
    infoDefault.enableOnWeaponIndex = -1
    local skillMap = {}
    for _, skillTerm in pairs(gemInst.termList) do
        skillMap[skillTerm.termId] = true
        local weaponSkillList = extraArgs and extraArgs.weaponSkillList
        if weaponSkillList then
            local termCfg = Tables.gemTable:GetValue(skillTerm.termId)
            for _, weaponSkill in pairs(weaponSkillList) do
                local skillCfg = CharInfoUtils.getSkillCfg(weaponSkill.skillId, weaponSkill.level)
                if skillCfg.tagId == termCfg.tagId then
                    infoDefault.enableOnWeapon = true
                    infoDefault.enableOnWeaponIndex = 1
                end
            end
        end
    end
    infoDefault.skillMap = skillMap
    return infoDefault
end
function processEquip(templateId, instId, extraArgs)
    local infoDefault = processItemDefault(templateId, instId)
    if not infoDefault then
        return nil
    end
    local _, equipTemplate = Tables.equipTable:TryGetValue(templateId)
    if equipTemplate then
        infoDefault.minWearLv = equipTemplate.minWearLv
        infoDefault.partType = equipTemplate.partType
        infoDefault.suitId = equipTemplate.suitID
        infoDefault.equipData = equipTemplate
    end
    if instId then
        local equipInst = CharInfoUtils.getEquipByInstId(instId)
        infoDefault.num_canEquip = 0
        if equipInst then
            local maxWearLimit = extraArgs and extraArgs.maxWearLimit or 0
            local canEquip = maxWearLimit == nil or infoDefault.rarity <= maxWearLimit
            infoDefault.num_canEquip = canEquip and 1 or 0
        end
    end
    return infoDefault
end
function processEquipProduce(equipFormulaData)
    local infoDefault = processEquip(equipFormulaData.outcomeEquipId)
    if not infoDefault then
        return nil
    end
    infoDefault.isUnlocked = FactoryUtils.isEquipFormulaUnlocked(equipFormulaData.formulaId)
    infoDefault.equipFormulaData = equipFormulaData
    local isCostEnough = true
    for i = 0, equipFormulaData.costItemId.Count - 1 do
        local itemId = equipFormulaData.costItemId[i]
        if not string.isEmpty(itemId) and i < equipFormulaData.costItemNum.Count and equipFormulaData.costItemNum[i] > Utils.getItemCount(itemId, true, true) then
            isCostEnough = false
            break
        end
    end
    infoDefault.isCostEnough = isCostEnough
    return infoDefault
end
function processEquipEnhance(templateId, instId)
    local infoDefault = processEquip(templateId, instId)
    if not infoDefault then
        return nil
    end
    infoDefault.equipInstData = CharInfoUtils.getEquipByInstId(instId)
    infoDefault.equipEnhanceLevel = infoDefault.equipInstData:IsMaxEnhanced() and -1 or infoDefault.equipInstData:GetEnhanceLevel()
    return infoDefault
end
function processEquipEnhanceMaterial(templateId, instId, extraArgs)
    local infoDefault = processEquip(templateId, instId)
    if not infoDefault then
        return nil
    end
    infoDefault.equipInstData = CharInfoUtils.getEquipByInstId(instId)
    infoDefault.equipEnhanceSuccessProb = EquipTechUtils.getEquipEnhanceSuccessProbability(infoDefault.equipInstData, extraArgs.attrShowInfo)
    return infoDefault
end
function generateConfig_EQUIP_ENHANCE()
    local filterConfig = {}
    table.insert(filterConfig, _generateAttrTypeFilterGroup({ GEnums.AttributeType.Str, GEnums.AttributeType.Agi, GEnums.AttributeType.Wisd, GEnums.AttributeType.Will, "All", }))
    table.insert(filterConfig, _generateAttrTypeFilterGroup(CharInfoUtils.getAllEquipExtraAttrList(), Language.LUA_DEPOT_FILTER_GROUP_TITLE_EQUIP_EXTRA_ATTR_TYPE))
    table.insert(filterConfig, _generateEquipSuitFilterGroup())
    return filterConfig
end
function generateConfig_EQUIP_ENHANCE_MATERIALS()
    local filterConfig = {}
    table.insert(filterConfig, FILTER_EQUIP_ENHANCED_GROUP)
    return filterConfig
end
function generateConfig_DEPOT_WEAPON()
    return BASIC_FILTER_CONFIG.DEPOT_WEAPON
end
function generateConfig_CHAR_INFO_WEAPON()
    return FILTER_CHAR_INFO_WEAPON
end
function generateConfig_DEPOT_GEM()
    local weaponGemFilterCfg = {}
    local gemSkillFilterGroup = _generateGemSkillFilterGroup()
    table.insert(weaponGemFilterCfg, gemSkillFilterGroup)
    return weaponGemFilterCfg
end
function generateConfig_DEPOT_EQUIP()
    local suitFilterConfigs = _generateEquipSuitFilterGroup()
    local filterConfig = {}
    table.insert(filterConfig, _generateAttrTypeFilterGroup({ GEnums.AttributeType.Str, GEnums.AttributeType.Agi, GEnums.AttributeType.Wisd, GEnums.AttributeType.Will, "All", }))
    table.insert(filterConfig, _generateAttrTypeFilterGroup(CharInfoUtils.getAllEquipExtraAttrList(), Language.LUA_DEPOT_FILTER_GROUP_TITLE_EQUIP_EXTRA_ATTR_TYPE))
    table.insert(filterConfig, FILTER_EQUIP_GROUP_PART_TYPE)
    table.insert(filterConfig, suitFilterConfigs)
    table.insert(filterConfig, _generateDomainFilterGroup())
    return filterConfig
end
function generateConfig_CHARINFO_EQUIP()
    local suitFilterConfigs = _generateEquipSuitFilterGroup()
    local filterConfig = {}
    table.insert(filterConfig, suitFilterConfigs)
    return filterConfig
end
function generateConfig_WEAPON_EXHIBIT_GEM()
    local weaponGemFilterCfg = {}
    local gemSkillFilterGroup = _generateGemSkillFilterGroup()
    table.insert(weaponGemFilterCfg, FILTER_GEM_ENABLE_ON_WEAPON)
    table.insert(weaponGemFilterCfg, gemSkillFilterGroup)
    return weaponGemFilterCfg
end
function generateConfig_DEPOT_EQUIP_DESTROY()
    return BASIC_FILTER_CONFIG.DEPOT_EQUIP_DESTROY
end
function generateConfig_EQUIP_PRODUCE()
    local filterConfig = {}
    table.insert(filterConfig, FILTER_EQUIP_PRODUCE_GROUP_SUFFICIENCY)
    table.insert(filterConfig, _generateAttrTypeFilterGroup({ GEnums.AttributeType.Str, GEnums.AttributeType.Agi, GEnums.AttributeType.Wisd, GEnums.AttributeType.Will, "All", }))
    table.insert(filterConfig, _generateAttrTypeFilterGroup(CharInfoUtils.getAllEquipExtraAttrList(), Language.LUA_DEPOT_FILTER_GROUP_TITLE_EQUIP_EXTRA_ATTR_TYPE))
    table.insert(filterConfig, _generateEquipSuitFilterGroup())
    table.insert(filterConfig, FILTER_EQUIP_GROUP_PART_TYPE)
    table.insert(filterConfig, _generateEquipRarityFilterGroup(1, 5))
    return filterConfig
end
function _generateEquipRarityFilterGroup(minRarity, maxRarity)
    local tags = {}
    for i = minRarity, maxRarity do
        local tag = { groupType = "ItemRarity", name = Language[string.format("LUA_EQUIP_FILTER_NAME_RARITY_%d", i)], funcName = "_filterByRarity", param = i, }
        table.insert(tags, tag)
    end
    local tagGroup = { title = Language.LUA_EQUIP_FILTER_GROUP_TITLE_RARITY, tags = tags, }
    return tagGroup
end
function _generateDomainFilterGroup()
    local tags = {}
    for _, domainCfg in pairs(Tables.domainDataTable) do
        local tag = { groupType = "Domain", name = domainCfg.domainName, funcName = "_filterByDomain", param = domainCfg.domainId, }
        table.insert(tags, tag)
    end
    local tagGroup = { title = Language.LUA_FILTER_GROUP_TITLE_DOMAIN, tags = tags, }
    return tagGroup
end
function _generateAttrTypeFilterGroup(attrTypeList, tagGroupTitle)
    local tags = {}
    for _, attrType in pairs(attrTypeList) do
        local isCompositeAttr = type(attrType) == "string"
        local attrShowCfg = isCompositeAttr and AttributeUtils.getCompositeAttributeShowCfg(attrType) or AttributeUtils.getAttributeShowCfg(attrType)
        if attrShowCfg then
            local tag = { groupType = "EquipAttrType", name = attrShowCfg.name, funcName = "_filterByAttrType", param = attrType, calcType = CALC_TYPE.AND, }
            table.insert(tags, tag)
        end
    end
    tagGroupTitle = tagGroupTitle or Language.LUA_DEPOT_FILTER_GROUP_TITLE_EQUIP_ATTR_TYPE
    local tagGroup = { title = tagGroupTitle, tags = tags, }
    return tagGroup
end
function _generateEquipSuitFilterGroup()
    local tags = {}
    for _, suitCfg in pairs(Tables.equipSuitTable) do
        local list = suitCfg.list
        local suitPieceCfg = list[CSIndex(1)]
        if suitPieceCfg then
            local tag = { groupType = "Suit", name = suitPieceCfg.suitName, funcName = "_filterByEquipSuit", param = suitPieceCfg.suitID, }
            table.insert(tags, tag)
        end
    end
    table.insert(tags, { groupType = "Suit", name = Language.LUA_DEPOT_FILTER_OPTION_NO_SUIT, funcName = "_filterByEquipSuit", param = "", })
    table.sort(tags, Utils.genSortFunction({ "tag" }))
    local suitFilterConfigs = { title = Language.LUA_DEPOT_FILTER_GROUP_TITLE_EQUIP_SUIT, tags = tags, }
    return suitFilterConfigs
end
function _generateGemSkillFilterGroup()
    local tags = {}
    for _, gemTermCfg in pairs(Tables.gemTable) do
        local tag = { groupType = "GemSkill", name = gemTermCfg.tagName, sortOrder = gemTermCfg.sortOrder, funcName = "_filterByGemSkill", param = gemTermCfg.gemTermId, calcType = CALC_TYPE.AND, }
        table.insert(tags, tag)
    end
    table.sort(tags, function(a, b)
        return a.sortOrder < b.sortOrder
    end)
    local suitFilterConfigs = { title = Language.LUA_DEPOT_FILTER_GROUP_TITLE_GEM_SKILL, tags = tags, }
    return suitFilterConfigs
end
function checkIfPassFilter(itemInfo, filterConfigs)
    local filterGroups = {}
    for _, filterConfig in pairs(filterConfigs) do
        local groupType = filterConfig.groupType or "Default"
        local calcType = filterConfig.calcType or CALC_TYPE.OR
        if not filterGroups[groupType] then
            filterGroups[groupType] = { isPass = false, calcType = calcType, filters = {}, }
        end
        table.insert(filterGroups[groupType].filters, filterConfig)
    end
    for _, filterGroup in pairs(filterGroups) do
        filterGroup.isPass = _checkIfGroupPassFilter(itemInfo, filterGroup)
    end
    for _, filterGroup in pairs(filterGroups) do
        if not filterGroup.isPass then
            return false
        end
    end
    return true
end
function _checkIfGroupPassFilter(itemInfo, filterGroup)
    local calcType = filterGroup.calcType
    for _, filterConfig in pairs(filterGroup.filters) do
        local funcName = filterConfig.funcName
        local filterFunc = FilterUtils[funcName]
        local isPass = filterFunc(itemInfo, filterConfig.param)
        if calcType == CALC_TYPE.AND then
            if not isPass then
                return false
            end
        else
            if isPass then
                return true
            end
        end
    end
    if calcType == CALC_TYPE.AND then
        return true
    else
        return false
    end
end
function _filterByDomain(info, domainId)
    return info.equipData.domainId == domainId
end
function _filterByAttrType(info, attrType)
    local isCompositeAttr = type(attrType) == "string"
    local attrModifiers = info.equipData.displayAttrModifiers
    for i = 0, attrModifiers.Count - 1 do
        if (isCompositeAttr and attrModifiers[i].compositeAttr == attrType) or (not isCompositeAttr and attrModifiers[i].attrType == attrType) then
            return true
        end
    end
    return false
end
function _filterByWeaponType(info, weaponType)
    if info.weaponType == GEnums.WeaponType.All then
        return true
    end
    return info.weaponType == weaponType
end
function _filterByRarity(info, rarity)
    return info.rarity == rarity
end
function _filterByEnhanceEquip(info, wantEnhanceEquip)
    return false
end
function _filterByUnlock(info, unlock)
    if not info.instId or info.instId <= 0 then
        return true
    end
    return not GameInstance.player.inventory:IsItemLocked(Utils.getCurrentScope(), info.id, info.instId)
end
function _filterByPartType(info, equipType)
    return info.partType == equipType
end
function _filterByEquipSuit(info, suitId)
    return info.suitId == suitId
end
function _filterByGemSkill(info, gemTermId)
    local skillMap = info.skillMap
    if not skillMap then
        return false
    end
    for termId, _ in pairs(skillMap) do
        if termId == gemTermId then
            return true
        end
    end
    return false
end
function _filterByGemEnableOnWeapon(info, param)
    if param == nil then
        param = false
    end
    return info.enableOnWeapon == param
end
function _filterByEquipProduceSufficiency(info, sufficient)
    return info.isCostEnough == sufficient
end
function _filterByEquipFormulaLocked(info, locked)
    return locked == not FactoryUtils.isEquipFormulaUnlocked(info.formulaId)
end
function _filterByEquipEnhanced(info, enhanced)
    return info.equipInstData:IsEnhanced() == enhanced
end
TACTICAL_ITEM_FILTER_INFO = { { title = Language.LUA_TACTICAL_ITEM_FILTER_GROUP_NAME_EFFECT, tags = { { name = Language.LUA_TACTICAL_ITEM_FILTER_NAME_EFFECT_HEAL, groupType = "TacticalItemEffect", funcName = "_filterByTacticalItemEffect", param = GEnums.ItemUseEffectType.Heal, }, { name = Language.LUA_TACTICAL_ITEM_FILTER_NAME_EFFECT_REVIVE, groupType = "TacticalItemEffect", funcName = "_filterByTacticalItemEffect", param = GEnums.ItemUseEffectType.Revive, }, { name = Language.LUA_TACTICAL_ITEM_FILTER_NAME_EFFECT_BUFF, groupType = "TacticalItemEffect", funcName = "_filterByTacticalItemEffect", param = GEnums.ItemUseEffectType.Buff, }, } }, { title = Language.LUA_TACTICAL_ITEM_FILTER_GROUP_NAME_TARGET_NUM, tags = { { name = Language.LUA_TACTICAL_ITEM_FILTER_NAME_TARGET_NUM_SINGLE, groupType = "TacticalItemTargetNum", funcName = "_filterByTacticalItemTargetNum", param = GEnums.ItemUseTargetNumType.Single, }, { name = Language.LUA_TACTICAL_ITEM_FILTER_NAME_TARGET_NUM_ALL, groupType = "TacticalItemTargetNum", funcName = "_filterByTacticalItemTargetNum", param = GEnums.ItemUseTargetNumType.All, }, } }, }
function generateConfig_TACTICAL_ITEM()
    return TACTICAL_ITEM_FILTER_INFO
end
function processTacticalItem(itemId, instId)
    local info = processItemDefault(itemId, instId)
    local useItemData = Tables.useItemTable:GetValue(itemId)
    info.effectType = useItemData.effectType
    info.targetNumType = useItemData.targetNumType
    info.curCount = Utils.getBagItemCount(itemId)
    return info
end
function _filterByTacticalItemEffect(info, effectType)
    return info.effectType == effectType
end
function _filterByTacticalItemTargetNum(info, targetNumType)
    return info.targetNumType == targetNumType
end