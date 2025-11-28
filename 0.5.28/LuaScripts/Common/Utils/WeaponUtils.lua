WEAPON_EXP_ITEM_LIST = { "item_weapon_upgrade_low", "item_weapon_upgrade_mid", "item_weapon_upgrade_high", }
function canWeaponUpgrade(weaponInstId)
    local weaponInst = CharInfoUtils.getWeaponByInstId(weaponInstId)
    local weaponExhibitInfo = CharInfoUtils.getWeaponExhibitBasicInfo(weaponInst.templateId, weaponInstId)
    local curLv = weaponExhibitInfo.curLv
    local stageLv = weaponExhibitInfo.stageLv
    if curLv >= stageLv then
        return false
    end
    local curExp = weaponExhibitInfo.curExp
    local nextLvExp = weaponExhibitInfo.nextLvExp
    local expNeedToUpgrade = nextLvExp - curExp
    if curExp >= nextLvExp then
        return false
    end
    local nextLvGold = weaponExhibitInfo.nextLvGold
    local curGold = Utils.getItemCount(UIConst.INVENTORY_MONEY_IDS[1])
    if curGold < nextLvGold then
        return false
    end
    local expSum = 0
    for i = 1, Tables.characterConst.weaponExpItem.Count do
        local itemId = Tables.characterConst.weaponExpItem[CSIndex(i)]
        local _, itemCfg = Tables.itemTable:TryGetValue(itemId)
        local inventoryCount = Utils.getItemCount(itemId)
        local itemExp = CalcItemExp(itemCfg)
        expSum = expSum + itemExp * inventoryCount
        if expSum >= expNeedToUpgrade then
            return true
        end
    end
    local weaponDepot = GameInstance.player.inventory.valuableDepots[GEnums.ItemValuableDepotType.Weapon]:GetOrFallback(Utils.getCurrentScope())
    local weaponInstDict = weaponDepot.instItems
    for _, itemBundle in pairs(weaponInstDict) do
        local weaponInst = itemBundle.instData
        local weaponTemplateId = weaponInst.templateId
        local _, itemCfg = Tables.itemTable:TryGetValue(weaponTemplateId)
        local isEquipped = weaponInst.equippedCharServerId and weaponInst.equippedCharServerId > 0
        local isSameEquip = weaponInst.instId == weaponInstId
        local isLocked = weaponInst.isLocked
        local hasGem = weaponInst.attachedGemInstId > 0
        if (not isEquipped) and (not isSameEquip) and (not isLocked) and (not hasGem) then
            local itemExp = CalcItemExp(itemCfg, weaponInst)
            expSum = expSum + itemExp
        end
        if expSum >= expNeedToUpgrade then
            return true
        end
    end
    return false
end
function canWeaponBreakthrough(weaponInstId)
    local weaponInst = CharInfoUtils.getWeaponByInstId(weaponInstId)
    local weaponExhibitInfo = CharInfoUtils.getWeaponExhibitBasicInfo(weaponInst.templateId, weaponInstId)
    local curBreakthroughLv = weaponExhibitInfo.curBreakthroughLv
    local maxBreakthroughLv = weaponExhibitInfo.maxBreakthroughLv
    if weaponExhibitInfo.curLv >= weaponExhibitInfo.maxLv then
        return false
    end
    if weaponExhibitInfo.curLv < weaponExhibitInfo.stageLv then
        return false
    end
    if curBreakthroughLv >= maxBreakthroughLv then
        return false
    end
    local breakthroughTemplateCfg = weaponExhibitInfo.breakthroughTemplateCfg
    local toBreakthroughCfg = breakthroughTemplateCfg.list[curBreakthroughLv]
    if not toBreakthroughCfg then
        return false
    end
    local breakthroughGold = weaponExhibitInfo.breakthroughGold
    local curGold = Utils.getItemCount(UIConst.INVENTORY_MONEY_IDS[1])
    if curGold < breakthroughGold then
        return false
    end
    local breakItemList = toBreakthroughCfg.breakItemList
    for _, itemInfo in pairs(breakItemList) do
        local id = itemInfo.id
        local needCount = itemInfo.count
        local inventoryCount = Utils.getItemCount(id)
        if inventoryCount < needCount then
            return false
        end
    end
    return true
end
function CalcItemExp(itemCfg, weaponInst)
    local rarity = itemCfg.rarity
    local _, rarityCfg = Tables.weaponExpItemTable:TryGetValue(rarity)
    if not rarityCfg then
        logger.error("WeaponExhibitUpgradeCtrl->Can't find weapon exp item info, rarity: " .. rarity)
        return 0
    end
    local baseExp = weaponInst ~= nil and rarityCfg.weaponExp or rarityCfg.itemExp
    local compensateExp = weaponInst and _CalcWeaponCompensateExp(weaponInst, rarity) or 0
    return baseExp + compensateExp
end
function _CalcWeaponCompensateExp(weaponInst, rarity)
    local templateId = weaponInst.templateId
    local _, weaponCfg = Tables.weaponBasicTable:TryGetValue(templateId)
    if not weaponCfg then
        logger.error("WeaponExhibitUpgradeCtrl->Can't find weapon basic info, templateId: " .. templateId)
        return 0
    end
    local levelTemplateId = weaponCfg.levelTemplateId
    local _, levelCfg = Tables.weaponUpgradeTemplateSumTable:TryGetValue(levelTemplateId)
    if not levelCfg then
        logger.error("WeaponExhibitUpgradeCtrl->Can't find weapon level info, levelTemplateId: " .. levelTemplateId)
        return 0
    end
    local _, expItemData = Tables.weaponExpItemTable:TryGetValue(rarity)
    if not expItemData then
        logger.error("WeaponExhibitUpgradeCtrl->Can't find weapon exp item info, rarity: " .. rarity)
        return 0
    end
    local convertRatio = expItemData.weaponExpConvertRatio
    local curExp = weaponInst.exp
    local weaponLv = weaponInst.weaponLv
    local expSum = levelCfg.list[CSIndex(weaponLv)].lvUpExpSum
    return math.floor((curExp + expSum) * convertRatio)
end