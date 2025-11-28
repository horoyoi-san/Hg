local EquipTechUtils = {}
function EquipTechUtils.hasEquipSuit(equipTemplateId)
    local hasValue, equipTemplate = Tables.equipTable:TryGetValue(equipTemplateId)
    if not hasValue then
        return false
    end
    local suitId = equipTemplate.suitID
    local hasSuit, _ = Tables.equipSuitTable:TryGetValue(suitId)
    return hasSuit
end
function EquipTechUtils.canEquipEnhance(templateId)
    local hasValue
    local itemData
    hasValue, itemData = Tables.itemTable:TryGetValue(templateId)
    if hasValue and itemData.rarity == 5 then
        return true
    end
    return false
end
function EquipTechUtils.getEquipEnhanceItemList(partType)
    local hasValue
    local itemList = {}
    local equipDepot = GameInstance.player.inventory.valuableDepots[GEnums.ItemValuableDepotType.Equip]:GetOrFallback(Utils.getCurrentScope())
    if equipDepot then
        for _, itemBundle in pairs(equipDepot.instItems) do
            local equipInst = itemBundle.instData
            local templateId = equipInst.templateId
            local equipData
            hasValue, equipData = Tables.equipTable:TryGetValue(templateId)
            if hasValue and (not partType or equipData.partType == partType) and EquipTechUtils.canEquipEnhance(templateId) then
                table.insert(itemList, itemBundle)
            end
        end
    end
    return itemList
end
function EquipTechUtils.getEquipEnhanceMaterialsItemList(partType, attrShowInfo, equipInstId)
    local hasValue
    local itemList = {}
    local equipDepot = GameInstance.player.inventory.valuableDepots[GEnums.ItemValuableDepotType.Equip]:GetOrFallback(Utils.getCurrentScope())
    if equipDepot then
        for _, itemBundle in pairs(equipDepot.instItems) do
            local equipInstData = itemBundle.instData
            local templateId = equipInstData.templateId
            local equipData
            hasValue, equipData = Tables.equipTable:TryGetValue(templateId)
            if equipInstData.instId ~= equipInstId and hasValue and equipData.partType == partType and EquipTechUtils.canEquipEnhance(templateId) then
                if EquipTechUtils.getEquipEnhanceSuccessProbability(equipInstData, attrShowInfo) > EquipTechConst.EEquipEnhanceSuccessProb.None then
                    table.insert(itemList, itemBundle)
                end
            end
        end
    end
    return itemList
end
function EquipTechUtils.getEquipEnhanceSuccessProbability(equipInstData, attrShowInfo)
    if not equipInstData then
        return EquipTechConst.EEquipEnhanceSuccessProb.None
    end
    local hasValue
    local equipData
    hasValue, equipData = Tables.equipTable:TryGetValue(equipInstData.templateId)
    if not equipData then
        return EquipTechConst.EEquipEnhanceSuccessProb.None
    end
    for _, attrModifier in pairs(equipData.displayAttrModifiers) do
        if attrModifier.modifierType == attrShowInfo.attrModifier and ((attrShowInfo.isCompositeAttr and attrShowInfo.attributeType == attrModifier.compositeAttr) or (not attrShowInfo.isCompositeAttr and attrShowInfo.attributeType == attrModifier.attrType)) then
            local enhancedAttrValue = EquipTechUtils.getEnhancedAttrValue(attrModifier, equipInstData)
            local finalAttrValue = AttributeUtils.modifyAttributeValue(attrModifier.attrType, enhancedAttrValue, attrShowInfo.attrShowCfg.showPercent)
            if finalAttrValue > attrShowInfo.modifiedValue then
                return EquipTechConst.EEquipEnhanceSuccessProb.High
            elseif finalAttrValue == attrShowInfo.modifiedValue then
                return EquipTechConst.EEquipEnhanceSuccessProb.Normal
            else
                return EquipTechConst.EEquipEnhanceSuccessProb.None
            end
        end
    end
    return EquipTechConst.EEquipEnhanceSuccessProb.None
end
function EquipTechUtils.getEnhancedAttrValue(attrInfo, equipInstData, isNextLevel)
    local enhancedLevel = equipInstData:GetAttrEnhanceLevel(attrInfo.enhancedAttrIndex)
    if isNextLevel then
        enhancedLevel = enhancedLevel + 1
    end
    if enhancedLevel <= 0 then
        return attrInfo.attrValue
    end
    local enhancedRatioList = Tables.equipConst.defaultEnhancedRatio
    local enhancedRatio = enhancedRatioList[enhancedLevel - 1]
    return attrInfo.attrValue * enhancedRatio
end
function EquipTechUtils.getEquipInstData(equipInstId)
    local _, equipInstData = CS.Beyond.Gameplay.EquipUtil.TryGetEquipInstData(Utils.getCurrentScope(), equipInstId)
    return equipInstData
end
function EquipTechUtils.getAttrShowValueText(attrShowInfo, isNextLevel, equipInstId)
    local showValueText = attrShowInfo.showValue
    if isNextLevel then
        local equipInstData = EquipTechUtils.getEquipInstData(equipInstId)
        if equipInstData then
            local targetAttrModifier = nil
            local equipData = Tables.equipTable[equipInstData.templateId]
            for _, attrModifier in pairs(equipData.displayAttrModifiers) do
                if attrModifier.enhancedAttrIndex == attrShowInfo.enhancedAttrIndex then
                    targetAttrModifier = attrModifier
                    break
                end
            end
            local attrValue = EquipTechUtils.getEnhancedAttrValue(targetAttrModifier, equipInstData, true)
            local modifiedAttrValue = AttributeUtils.modifyAttributeValue(attrShowInfo.attributeType, attrValue, attrShowInfo.attrShowCfg.showPercent)
            showValueText = AttributeUtils.generateShowValue(modifiedAttrValue, attrShowInfo.attrShowCfg.showPercent)
        end
    end
    return string.format(Language.LUA_WEAPON_EXHIBIT_UPGRADE_ADD_FORMAT, showValueText)
end
function EquipTechUtils.setEquipBaseInfo(view, loader, equipTemplateId)
    local itemData = Tables.itemTable[equipTemplateId]
    local equipCfg = Tables.equipTable[equipTemplateId]
    if view.equipName then
        view.equipName.text = itemData.name
    end
    view.levelNum.text = equipCfg.minWearLv
    local equipType = equipCfg.partType
    local equipTypeName = Language[UIConst.CHAR_INFO_EQUIP_TYPE_TILE_PREFIX .. LuaIndex(equipType:ToInt())]
    local equipTypeSpriteName = UIConst.EQUIP_TYPE_TO_ICON_NAME[equipType]
    view.equipTypeName.text = equipTypeName
    view.equipTypeIcon.sprite = UIUtils.loadSprite(loader, UIConst.UI_SPRITE_EQUIP_PART_ICON, equipTypeSpriteName)
    if view.rarityLightImg then
        UIUtils.setItemRarityImage(view.rarityLightImg, itemData.rarity)
    end
    if view.rarityImg then
        UIUtils.setItemRarityImage(view.rarityImg, itemData.rarity)
    end
end
_G.EquipTechUtils = EquipTechUtils
return EquipTechUtils