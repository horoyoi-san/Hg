function openCharInfoBestWay(arg)
    if PhaseManager:IsOpen(PhaseId.CharInfo) then
        PhaseManager:ExitPhaseFast(PhaseId.CharInfo)
        PhaseManager:OpenPhase(PhaseId.CharInfo, arg)
    else
        PhaseManager:OpenPhase(PhaseId.CharInfo, arg)
    end
end
function openWeaponInfoBestWay(arg)
    if PhaseManager:IsOpen(PhaseId.WeaponInfo) then
        PhaseManager:ExitPhaseFast(PhaseId.WeaponInfo)
        PhaseManager:OpenPhase(PhaseId.WeaponInfo, arg)
    else
        PhaseManager:OpenPhase(PhaseId.WeaponInfo, arg)
    end
end
function isEndmin(charTemplateId)
    return string.find(charTemplateId, "endmin") ~= nil
end
function checkIsCardInTrail(instId)
    local charInst = getPlayerCharInfoByInstId(instId)
    local isTrail = (charInst and charInst.charType == GEnums.CharType.Trial) or Utils.isInRacingDungeon()
    return isTrail
end
function checkIsWeaponInTrail(weaponInstId)
    return GameUtil.IsClientSpawned(weaponInstId)
end
function getDefExtraHint(charInstId)
    local allAttribute = getCharFinalAttributes(charInstId)
    local finalDef = allAttribute[GEnums.AttributeType.Def]
    local efficiencyOfDEF = Tables.battleConst.efficiencyOfDEF
    local damagePrevent = (1 / (1 + efficiencyOfDEF * finalDef))
    local showInfo = AttributeUtils.generateAttributeShowInfo(GEnums.AttributeType.PhysicalDamageTakenScalar, damagePrevent, { fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR })
    return string.format(Language.LUA_CHAR_INFO_DEF_EXTRA_HINT_FORMAT, showInfo.showValue)
end
local REACH_SHOW_VALUE = 100
function getCharRelationShowValue(relation)
    local reachCount = 0
    for i = 2, #Tables.SpaceshipCharRelationLevelTable do
        local relationCfg = Tables.SpaceshipCharRelationLevelTable:GetValue(i)
        if relation >= relationCfg.favorability then
            reachCount = reachCount + 1
        else
            local lastRelationCfg = Tables.SpaceshipCharRelationLevelTable:GetValue(i - 1)
            local gap = relationCfg.favorability - lastRelationCfg.favorability
            local rate = math.floor((relation - lastRelationCfg.favorability) / gap * REACH_SHOW_VALUE)
            return reachCount * REACH_SHOW_VALUE + rate
        end
    end
    return reachCount * REACH_SHOW_VALUE
end
function generateCharInfoBasicAttrShowInfo(charInstId)
    local allAttribute = getCharFinalAttributes(charInstId)
    local fcAttrInfoList = generateFCAttrShowInfoList(allAttribute, false, UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR)
    local scMainAttrInfoList = generateSCMainAttrShowInfoList(allAttribute, false, UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR)
    local scSubAttrInfoList = generateSCSubAttrShowInfoList(allAttribute, false, UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR)
    return fcAttrInfoList, scMainAttrInfoList, scSubAttrInfoList
end
function _innerGenerateAttrShowInfoListBlack(arg)
    local allAttributes = arg.allAttributes
    local blackMap = arg.blackMap
    local isAttributeDiff = arg.isAttributeDiff == true
    local fromSpecificSystem = arg.fromSpecificSystem
    local showInfoList = {}
    for attributeIndex = 1, GEnums.AttributeType.Enum:ToInt() - 1 do
        local attributeType = GEnums.AttributeType.__CastFrom(attributeIndex)
        if attributeType then
            local attr = allAttributes[attributeType]
            if not _checkIfAttributeInBlackMap(attributeType, attr, blackMap) then
                local attributeShowInfo = _innerGenerateAttrShowInfo(attr, attributeType, isAttributeDiff, fromSpecificSystem)
                if attributeShowInfo then
                    table.insert(showInfoList, attributeShowInfo)
                end
            end
        end
    end
    table.sort(showInfoList, function(a, b)
        return a.sortOrder < b.sortOrder
    end)
    return showInfoList
end
function _checkIfAttributeInBlackMap(attrType, attr, blackMap)
    if not blackMap then
        return false
    end
    local blackCfg = blackMap[attrType]
    if not blackCfg then
        return false
    end
    if blackCfg.forbidAllModifier then
        return true
    end
    local _, attrModifier, _ = AttributeUtils.extractAttrData(attr)
    if attrModifier ~= nil then
        if blackCfg.forbidModifiers[attrModifier] then
            return true
        end
    end
    return false
end
function _innerGenerateAttrShowInfoList(allAttributes, showOrder, isAttributeDiff, noSort, fromSpecificSystem)
    local showInfoList = {}
    if not showOrder then
        for attrType, attr in pairs(allAttributes) do
            local attributeShowInfo = _innerGenerateAttrShowInfo(attr, attrType, isAttributeDiff, fromSpecificSystem)
            if attributeShowInfo then
                table.insert(showInfoList, attributeShowInfo)
            end
        end
    elseif type(showOrder) == "table" then
        for _, attributeType in ipairs(showOrder) do
            local attr = allAttributes[attributeType]
            local attributeShowInfo = _innerGenerateAttrShowInfo(attr, attributeType, isAttributeDiff, fromSpecificSystem)
            if attributeShowInfo then
                table.insert(showInfoList, attributeShowInfo)
            end
        end
    elseif type(showOrder) == "userdata" then
        for i = 1, showOrder.Count do
            local attributeType = showOrder[CSIndex(i)]
            local attr = allAttributes[attributeType]
            local attributeShowInfo = _innerGenerateAttrShowInfo(attr, attributeType, isAttributeDiff, fromSpecificSystem)
            if attributeShowInfo then
                table.insert(showInfoList, attributeShowInfo)
            end
        end
    end
    if noSort ~= true then
        table.sort(showInfoList, function(a, b)
            return a.sortOrder < b.sortOrder
        end)
    end
    return showInfoList
end
function _innerGenerateAttrShowInfo(attr, attrType, isAttributeDiff, fromSpecificSystem)
    if not attr or not attrType then
        return
    end
    local attrValue, attrModifier, enhancedAttrIndex = AttributeUtils.extractAttrData(attr)
    if attrValue then
        local attributeShowInfo = AttributeUtils.generateAttributeShowInfo(attrType, attrValue, { isAttributeDiff = isAttributeDiff, attrModifier = attrModifier, enhancedAttrIndex = enhancedAttrIndex, fromSpecificSystem = fromSpecificSystem, })
        if attributeShowInfo then
            return attributeShowInfo
        end
    end
end
function generateCompositeAttributeShowInfoList(allAttributes, fromSpecificSystem)
    return _innerGenerateAttrShowInfoList(allAttributes, nil, false, false, fromSpecificSystem)
end
function generateFCAttrShowInfoList(allAttributes, isAttrDiff, fromSpecificSystem)
    return _innerGenerateAttrShowInfoList(allAttributes, UIConst.CHAR_INFO_FIRST_CLASS_ATTRIBUTE_SHOW_ORDER, isAttrDiff, false, fromSpecificSystem)
end
function generateSCMainAttrShowInfoList(allAttributes, isAttrDiff, fromSpecificSystem)
    return _innerGenerateAttrShowInfoList(allAttributes, UIConst.CHAR_INFO_SECOND_CLASS_MAIN_ATTRIBUTE_SHOW_ORDER, isAttrDiff, true, fromSpecificSystem)
end
function generateSCSubAttrShowInfoList(allAttributes, isAttrDiff, fromSpecificSystem)
    return _innerGenerateAttrShowInfoListBlack({ allAttributes = allAttributes, blackMap = UIConst.CHAR_INFO_FULL_ATTR_BLACK_MAP, isAttrDiff = isAttrDiff, fromSpecificSystem = fromSpecificSystem, })
end
function generateBasicAttributeShowInfoList(allAttributes, isAttributeDiff)
    local showInfoList = {}
    for _, attributeType in ipairs(UIConst.CHAR_INFO_BASIC_ATTRIBUTE_SHOW_ORDER) do
        local attr = allAttributes[attributeType]
        local attributeShowInfo = _innerGenerateAttrShowInfo({ attrValue = attr, modifierType = GEnums.ModifierType.BaseAddition }, attributeType, isAttributeDiff)
        if attributeShowInfo then
            table.insert(showInfoList, attributeShowInfo)
        end
    end
    return showInfoList
end
function generateUpgradeAttributeShowInfoList(allAttributes, isAttributeDiff)
    local showInfoList = {}
    for _, attributeType in ipairs(UIConst.CHAR_INFO_UPGRADE_ATTRIBUTE_SHOW_ORDER) do
        local attr = allAttributes[attributeType]
        local attributeShowInfo = _innerGenerateAttrShowInfo({ attrValue = attr, modifierType = GEnums.ModifierType.BaseAddition }, attributeType, isAttributeDiff)
        if attributeShowInfo then
            table.insert(showInfoList, attributeShowInfo)
        end
    end
    return showInfoList
end
function checkIsCardInSlot(instId)
    local curSquadSlot = GameInstance.player.squadManager:GetSlotInCurSquad(instId)
    return curSquadSlot ~= nil
end
function getPlayerBreakInfoList()
    local breakData = Tables.charBreakTable
    local breakInfoList = {}
    for i = 1, Tables.characterConst.maxBreak do
        local breakCfg = breakData[i]
        local breakStatus = breakCfg.breakStatus
        table.insert(breakInfoList, { isHide = breakStatus == 0, isBigBreak = breakStatus == 1, })
    end
    return breakInfoList
end
function getPlayerCharInfoByTemplateId(templateId, charType)
    local charBag = GameInstance.player.charBag
    return charBag:GetCharInfoByTemplateId(templateId, charType)
end
function getPlayerCharInfoByInstId(charInstId)
    local charBag = GameInstance.player.charBag
    return charBag:GetCharInfo(charInstId)
end
function getPlayerCharInfoByPresetId(presetId)
    local charBag = GameInstance.player.charBag
    return charBag:GetCharInfoByPresetId(presetId)
end
CHAR_INFO_PAGE_TYPE = { OVERVIEW = 1, WEAPON = 2, EQUIP = 3, TALENT = 5, PROFILE = 6, UPGRADE = 7, PROFILE_SHOW = 10, POTENTIAL = 11, }
function getCharInfoTitle(charTemplateId, pageType)
    local charCfg = Tables.characterTable[charTemplateId]
    if pageType == UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW then
        return string.format(Language.LUA_CHAR_INFO_TITLE_FORMAT, charCfg.name, Language.LUA_CHAR_INFO_TITLE_OVERVIEW)
    elseif pageType == UIConst.CHAR_INFO_PAGE_TYPE.EQUIP then
        return string.format(Language.LUA_CHAR_INFO_TITLE_FORMAT, charCfg.name, Language.LUA_CHAR_INFO_TITLE_EQUIP)
    elseif pageType == UIConst.CHAR_INFO_PAGE_TYPE.TALENT then
        return string.format(Language.LUA_CHAR_INFO_TITLE_FORMAT, charCfg.name, Language.LUA_CHAR_INFO_TITLE_TALENT)
    elseif pageType == UIConst.CHAR_INFO_PAGE_TYPE.PROFILE then
        return string.format(Language.LUA_CHAR_INFO_TITLE_FORMAT, charCfg.name, Language.LUA_CHAR_INFO_TITLE_PROFILE)
    elseif pageType == UIConst.CHAR_INFO_PAGE_TYPE.UPGRADE then
        return string.format(Language.LUA_CHAR_INFO_TITLE_FORMAT, charCfg.name, Language.LUA_CHAR_INFO_TITLE_UPGRADE)
    elseif pageType == UIConst.CHAR_INFO_PAGE_TYPE.PROFILE_SHOW then
    elseif pageType == UIConst.CHAR_INFO_PAGE_TYPE.POTENTIAL then
        return string.format(Language.LUA_CHAR_INFO_TITLE_FORMAT, charCfg.name, Language.LUA_CHAR_INFO_TITLE_POTENTIAL)
    elseif pageType == UIConst.CHAR_INFO_PAGE_TYPE.WEAPON then
        return string.format(Language.LUA_CHAR_INFO_TITLE_FORMAT, charCfg.name, Language.LUA_CHAR_INFO_TITLE_WEAPON)
    end
    return ""
end
function checkIfCharMaxLv(charInstId)
    local charInst = getPlayerCharInfoByInstId(charInstId)
    return charInst.level >= Tables.characterConst.maxLevel
end
function getCharPassiveSkillCount(charTemplateId)
    local charGrowthCfg = Tables.charGrowthTable[charTemplateId]
    local talentNodeMap = charGrowthCfg.talentNodeMap
    local skillIdDict = {}
    for _, talentNode in pairs(talentNodeMap) do
        if talentNode.nodeType == GEnums.TalentNodeType.PassiveSkill then
            local skillId = talentNode.passiveSkillNodeInfo.skillId
            if skillIdDict[skillId] == nil then
                skillIdDict[skillId] = true
            end
        end
    end
    local passiveSkillCount = lume.count(skillIdDict)
    return passiveSkillCount
end
function getCharExpInfo(charInstId)
    local charInfo = getPlayerCharInfoByInstId(charInstId)
    local breakStage = charInfo.breakStage
    local breakCfg = Tables.charBreakTable[breakStage]
    local stageLv = breakCfg.maxLevel
    local availableExpItems = breakCfg.availableExpItems
    local curLevel = charInfo.level
    local curExp = charInfo.exp
    local levelUpExp = Tables.charLevelUpTable[curLevel].exp
    return curExp, levelUpExp, curLevel, stageLv, availableExpItems
end
function getSkillGroupSubDescList(charTemplateId, skillGroupId, skillGroupLv)
    local skillGroupCfg = getSkillGroupCfg(charTemplateId, skillGroupId)
    local skillIdList = skillGroupCfg.skillIdList
    local skillDescList = {}
    local skillDescNameList = {}
    for i = 1, #skillIdList do
        local skillId = skillIdList[CSIndex(i)]
        local skillCfg = getSkillCfg(skillId, skillGroupLv)
        if skillCfg then
            local skillExtraInfoList = getSkillExtraInfoList(skillCfg.skillId, skillCfg.level)
            for _, extraInfo in ipairs(skillExtraInfoList) do
                table.insert(skillDescNameList, extraInfo.name)
                table.insert(skillDescList, extraInfo.value)
            end
            for j = 1, #skillCfg.subDescNameList do
                local descName = skillCfg.subDescNameList[CSIndex(j)]
                if descName == nil or string.isEmpty(descName) then
                    break
                end
                table.insert(skillDescNameList, skillCfg.subDescNameList[CSIndex(j)])
            end
            for j = 1, #skillCfg.subDescList do
                local desc = skillCfg.subDescList[CSIndex(j)]
                if desc == nil or string.isEmpty(desc) then
                    break
                end
                table.insert(skillDescList, skillCfg.subDescList[CSIndex(j)])
            end
        end
    end
    return skillDescNameList, skillDescList
end
function getEquipInstListByType(slotPartType, curEquipInstId, charInstId)
    local equipInstList = {}
    local equipDepot = GameInstance.player.inventory.valuableDepots[GEnums.ItemValuableDepotType.Equip]:GetOrFallback(Utils.getCurrentScope())
    if not equipDepot then
        return equipInstList
    end
    local curInst
    local equipDataList = {}
    local equipInstDict = equipDepot.instItems
    for _, itemBundle in pairs(equipInstDict) do
        local equipInst = itemBundle.instData
        local templateId = equipInst.templateId
        local res, equipTemplate = Tables.equipTable:TryGetValue(templateId)
        local itemCfg = Tables.itemTable:GetValue(templateId)
        if not res then
            logger.error(ELogChannel.Cfg, "EquipTemplateId: " .. templateId .. " not in equipBasicTable!!!")
        end
        local level = equipTemplate.minWearLv
        local _, equipData = Tables.equipTable:TryGetValue(templateId)
        local charInfo = getPlayerCharInfoByInstId(charInstId)
        if equipData.partType == slotPartType then
            local data = { equipInst = equipInst, sortId2 = itemCfg.sortId2, canEquip = charInfo and charInfo.equipTierLimit >= itemCfg.rarity and 0 or 1, canEquipReversed = charInfo and charInfo.equipTierLimit >= itemCfg.rarity and 1 or 0, level = Tables.characterConst.maxLevel - level, levelReversed = level, equipped = 1, equippedReversed = 0, }
            if curEquipInstId and curEquipInstId > 0 and curEquipInstId == equipInst.instId then
                data.equipped = 0
                data.equippedReversed = 1
            end
            table.insert(equipDataList, data)
        end
    end
    table.sort(equipDataList, Utils.genSortFunction(UIConst.EQUIP_SORT_OPTION[1].reverseKeys))
    return equipDataList
end
function getEquipByInstId(equipInstId)
    if not equipInstId then
        return
    end
    local _, equipInst = GameInstance.player.inventory:TryGetEquipInst(Utils.getCurrentScope(), equipInstId)
    if not equipInst then
        return
    end
    local equipInstanceData = equipInst.instData
    return equipInstanceData
end
function getEquipMinWearLv(tierLv)
    local hasTier, tierCfg = Tables.equipTierLevelTable:TryGetValue(tierLv)
    if not hasTier then
        return -1
    end
    return tierCfg.equiplevel
end
function getCharAllEquipAttributeShowInfos(charInstId)
    local mainAttrShowInfos = {}
    local extraAttrShowInfos = {}
    local defAttr, mainAttrs, extraAttrs = getCharAllEquipAttributes(charInstId)
    local defAttrShowInfo = AttributeUtils.generateAttributeShowInfo(defAttr.attrType, defAttr.attrValue, { attrModifier = defAttr.attrModifier, })
    for _, attr in ipairs(mainAttrs) do
        local attributeShowInfo = AttributeUtils.generateAttributeShowInfo(attr.attrType, attr.attrValue, { attrModifier = attr.attrModifier, })
        table.insert(mainAttrShowInfos, attributeShowInfo)
    end
    table.sort(mainAttrShowInfos, function(a, b)
        return a.sortOrder < b.sortOrder
    end)
    for _, attr in ipairs(extraAttrs) do
        local attributeShowInfo = AttributeUtils.generateAttributeShowInfo(attr.attrType, attr.attrValue, { attrModifier = attr.attrModifier, })
        table.insert(extraAttrShowInfos, attributeShowInfo)
    end
    table.sort(extraAttrShowInfos, function(a, b)
        return a.sortOrder < b.sortOrder
    end)
    return defAttrShowInfo, mainAttrShowInfos, extraAttrShowInfos
end
local ATTR_MODIFIER_MERGE_RULE = { ADD = 1, MULTIPLY = 2, }
local DEFAULT_MERGE_RULE = ATTR_MODIFIER_MERGE_RULE.ADD
local EQUIP_ATTR_MODIFIER_TYPE_MERGE_RULE = { [GEnums.ModifierType.FinalMultiplier] = ATTR_MODIFIER_MERGE_RULE.MULTIPLY, [GEnums.ModifierType.BaseFinalMultiplier] = ATTR_MODIFIER_MERGE_RULE.MULTIPLY, }
function getCharAllEquipAttributes(charInstId)
    local defAttr = { attrType = GEnums.AttributeType.Def, attrValue = 0, attrModifier = GEnums.ModifierType.BaseAddition, }
    local attrType2ModifierDict = {}
    local attrModifierDataList = getAllEquipInstAttributes(charInstId)
    for _, attr in ipairs(attrModifierDataList) do
        local keyAttrType = attr.keyAttrType
        local modifierType = attr.modifierType
        local attrValue = attr.attrValue
        if modifierType == GEnums.ModifierType.BaseAddition and keyAttrType == GEnums.AttributeType.Def then
            if defAttr == nil then
                defAttr = { attrValue = 0, attrType = GEnums.AttributeType.Def, attrModifier = modifierType, }
            end
            defAttr.attrValue = defAttr.attrValue + attrValue
        else
            if attrType2ModifierDict[keyAttrType] == nil then
                attrType2ModifierDict[keyAttrType] = {}
            end
            local modifierDict = attrType2ModifierDict[keyAttrType]
            if modifierDict[modifierType] == nil then
                modifierDict[modifierType] = attrValue
            else
                if EQUIP_ATTR_MODIFIER_TYPE_MERGE_RULE[modifierType] == ATTR_MODIFIER_MERGE_RULE.MULTIPLY then
                    modifierDict[modifierType] = modifierDict[modifierType] * attrValue
                else
                    modifierDict[modifierType] = modifierDict[modifierType] + attrValue
                end
            end
        end
    end
    local mainAttrs = {}
    for attrType, modifierDict in pairs(attrType2ModifierDict) do
        for modifierType, mergedAttrValue in pairs(modifierDict) do
            table.insert(mainAttrs, { attrValue = mergedAttrValue, attrType = attrType, attrModifier = modifierType, })
        end
    end
    return defAttr, mainAttrs, {}
end
function getAllEquipInstAttributes(charInstId)
    local attrTypeDataList = {}
    local charInst = getPlayerCharInfoByInstId(charInstId)
    for slotIndex, equipInstId in pairs(charInst.equipCol) do
        local baseAttr, attrs = getEquipInstAttributes(equipInstId)
        table.insert(attrTypeDataList, baseAttr)
        for _, attr in ipairs(attrs) do
            table.insert(attrTypeDataList, attr)
        end
    end
    return attrTypeDataList
end
function getEquipShowAttributes(instId)
    local equipInst = getEquipByInstId(instId)
    return _genEquipShowAttributes(equipInst.templateId, getEquipInstAttributes(instId))
end
function getEquipTemplateShowAttributes(equipTemplateId)
    return _genEquipShowAttributes(equipTemplateId, getEquipTemplateAttributes(equipTemplateId))
end
local EQUIP_MAIN_ATTR_INDEX = 2
function _genEquipShowAttributes(templateId, equipAttr, attrs)
    local defAttrShowInfo = AttributeUtils.generateAttributeShowInfo(equipAttr.keyAttrType, equipAttr.attrValue, { attrModifier = equipAttr.modifierType, })
    local mainAttrShowList = {}
    local extraAttrShowList = {}
    for index, attrDisplayInfo in ipairs(attrs) do
        local attrShowInfo = AttributeUtils.generateAttributeShowInfo(attrDisplayInfo.keyAttrType, attrDisplayInfo.attrValue, { attrModifier = attrDisplayInfo.modifierType, enhancedAttrIndex = attrDisplayInfo.enhancedAttrIndex, })
        if LuaIndex(attrDisplayInfo.enhancedAttrIndex) <= EQUIP_MAIN_ATTR_INDEX then
            table.insert(mainAttrShowList, attrShowInfo)
        else
            table.insert(extraAttrShowList, attrShowInfo)
        end
    end
    mainAttrShowList = lume.sort(mainAttrShowList, function(a, b)
        return a.enhancedAttrIndex < b.enhancedAttrIndex
    end)
    extraAttrShowList = lume.sort(extraAttrShowList, function(a, b)
        return a.enhancedAttrIndex < b.enhancedAttrIndex
    end)
    return defAttrShowInfo, mainAttrShowList, extraAttrShowList
end
function getEquipTemplateAttributes(templateId)
    local _, equipData = Tables.equipTable:TryGetValue(templateId)
    if not equipData then
        return
    end
    local attrs = {}
    for i = 1, equipData.displayAttrModifiers.Count do
        local attrModifier = equipData.displayAttrModifiers[CSIndex(i)]
        local attrInfo = { attrType = attrModifier.attrType, attrValue = attrModifier.attrValue, modifierType = attrModifier.modifierType, enhancedAttrIndex = attrModifier.enhancedAttrIndex, }
        if string.isEmpty(attrModifier.compositeAttr) then
            attrInfo.keyAttrType = attrModifier.attrType
        else
            attrInfo.keyAttrType = attrModifier.compositeAttr
        end
        table.insert(attrs, attrInfo)
    end
    local displayEquipAttrModifier = equipData.displayBaseAttrModifier
    local baseAttr = { keyAttrType = displayEquipAttrModifier.attrType, attrType = displayEquipAttrModifier.attrType, attrValue = displayEquipAttrModifier.attrValue, modifierType = displayEquipAttrModifier.modifierType, enhancedAttrIndex = displayEquipAttrModifier.enhancedAttrIndex, }
    return baseAttr, attrs
end
function getEquipInstAttributes(instId)
    local equipInstData = getEquipByInstId(instId)
    local baseAttr, attrs = getEquipTemplateAttributes(equipInstData.templateId)
    for _, attrInfo in ipairs(attrs) do
        attrInfo.attrValue = EquipTechUtils.getEnhancedAttrValue(attrInfo, equipInstData)
    end
    return baseAttr, attrs
end
local allEquipExtraAttrList = nil
function getAllEquipExtraAttrList()
    if allEquipExtraAttrList then
        return allEquipExtraAttrList
    end
    local allEquipExtraAttrTable = {}
    for _, equipData in pairs(Tables.equipTable) do
        for _, attrModifier in pairs(equipData.displayAttrModifiers) do
            if LuaIndex(attrModifier.enhancedAttrIndex) > EQUIP_MAIN_ATTR_INDEX then
                local attrKey = string.isEmpty(attrModifier.compositeAttr) and attrModifier.attrType or attrModifier.compositeAttr
                allEquipExtraAttrTable[attrKey] = true
            end
        end
    end
    allEquipExtraAttrList = {}
    for attrKey, _ in pairs(allEquipExtraAttrTable) do
        table.insert(allEquipExtraAttrList, attrKey)
    end
    return allEquipExtraAttrList
end
function getCharSuitInfoList(instId, focusSuitId)
    local suitInfoList = {}
    local charEntityInfo = getPlayerCharInfoByInstId(instId)
    local equipCol = charEntityInfo.equipCol
    local suitTable = {}
    local suit2Slots = {}
    for slotIndex, equipInstId in pairs(equipCol) do
        local equipInstanceData = getEquipByInstId(equipInstId)
        local templateId = equipInstanceData.templateId
        local _, equipData = Tables.equipTable:TryGetValue(templateId)
        local suitId = equipData.suitID
        if not suit2Slots[suitId] then
            suit2Slots[suitId] = {}
        end
        if not focusSuitId or focusSuitId == suitId then
            suitTable[suitId] = suitTable[suitId] and suitTable[suitId] + 1 or 1
            suit2Slots[suitId][slotIndex] = true
        end
    end
    for suitId, suitCount in pairs(suitTable) do
        table.insert(suitInfoList, { suitId = suitId, suitCount = suitCount, })
    end
    suitInfoList = lume.sort(suitInfoList, function(a, b)
        return a.suitCount > b.suitCount
    end)
    return suitInfoList, suit2Slots
end
function getCharTableData(charTemplateId)
    local tableData = nil
    local res, characterData = Tables.charGrowthTable:TryGetValue(charTemplateId)
    if res then
        tableData = characterData
    end
    return tableData
end
function getCharBaseAttributes(instId, baseTypeMask)
    local charInfo = getPlayerCharInfoByInstId(instId)
    return _getSlotBaseAttributes(charInfo, baseTypeMask)
end
function getCharArmedAttributes(instId, armedTypeMask, baseTypeMask)
    local charInfo = getPlayerCharInfoByInstId(instId)
    return _getSlotArmedAttributes(charInfo, armedTypeMask, baseTypeMask)
end
function getCharFinalAttributes(instId)
    local charInfo = getPlayerCharInfoByInstId(instId)
    return getCharFinalAttributesFromSpecificCache(charInfo.attributes)
end
function getCharFinalAttributesFromSpecificCache(allAttributes)
    local attributes = {}
    for i = 1, GEnums.AttributeType.Enum:ToInt() - 1 do
        local attributeType = GEnums.AttributeType.__CastFrom(i)
        if attributeType then
            attributes[attributeType] = allAttributes:GetValue(attributeType)
        end
    end
    return attributes
end
function getQualifiedEquipBreakNodeIdByEquipTierLimit(equipTierLimit)
    for nodeId, nodeCfg in pairs(Tables.charBreakNodeTable) do
        if nodeCfg.equipTierLimit == equipTierLimit and nodeCfg.talentNodeType == GEnums.TalentNodeType.EquipBreak then
            return nodeId
        end
    end
end
function checkCharInTeam(charInstId, teamIndex)
    if not teamIndex or teamIndex <= 0 then
        return -1
    end
    local teamInfo = GameInstance.player.charBag.teamList[CSIndex(teamIndex)]
    local memberList = teamInfo.memberList
    for index = 1, memberList.Count do
        local teamMember = memberList[CSIndex(index)]
        local instId = teamMember.charId
        if instId == charInstId then
            return index
        end
    end
    return -1
end
function getCharInfoList(csTeamIndex)
    local charBag = GameInstance.player.charBag
    local charInfoList = {}
    local playerChars = charBag.charInfos
    if csTeamIndex == nil then
        csTeamIndex = GameInstance.player.squadManager.curSquadIndex
    end
    local teamInfo = charBag.teamList[csTeamIndex]
    local memberList = teamInfo.memberList
    for i = 1, memberList.Count do
        local teamMember = memberList[CSIndex(i)]
        local instId = teamMember.charId
        local charInfo = playerChars[instId]
        local templateId = charInfo.templateId
        local charCfg = Tables.characterTable:GetValue(templateId)
        local item = { instId = instId, templateId = charInfo.templateId, level = charInfo.level, ownTime = charInfo.ownTime, rarity = charCfg.rarity, slotIndex = i, slotReverseIndex = Const.BATTLE_SQUAD_MAX_CHAR_NUM - i, sortOrder = charCfg.sortOrder, singleSelect = true, }
        table.insert(charInfoList, item)
    end
    for instId, charInfo in pairs(playerChars) do
        local isClientOnly = GameUtil.IsRuntimeClientId(instId)
        if (not isClientOnly) and (checkCharInTeam(instId, LuaIndex(csTeamIndex)) <= 0) then
            local templateId = charInfo.templateId
            local charCfg = Tables.characterTable:GetValue(templateId)
            local item = { instId = instId, templateId = templateId, ownTime = charInfo.ownTime, level = charInfo.level, rarity = charCfg.rarity, slotIndex = Const.BATTLE_SQUAD_MAX_CHAR_NUM + 1, slotReverseIndex = -1, sortOrder = charCfg.sortOrder, }
            table.insert(charInfoList, item)
        end
    end
    charInfoList = lume.sort(charInfoList, Utils.genSortFunction(UIConst.CHAR_FORMATION_LIST_SORT_OPTION[1].reverseKeys))
    return charInfoList
end
function getSingleCharInfoList(charInstId)
    return getCharInfoListByInstIdList({ charInstId })
end
function getCharInfoListByInstIdList(charInstIdList)
    local charInfoList = {}
    for _, charInstId in pairs(charInstIdList) do
        local charInfo = getPlayerCharInfoByInstId(charInstId)
        local charData = getCharTableData(charInfo.templateId)
        local item = { instId = charInstId, templateId = charInfo.templateId, level = charInfo.level, ownTime = charInfo.ownTime, rarity = charData.rarity, slotIndex = Const.BATTLE_SQUAD_MAX_CHAR_NUM + 1, slotReverseIndex = -1, }
        table.insert(charInfoList, item)
    end
    return charInfoList
end
function checkCharInLockedTeam(charInfo, lockedTeamData)
    local isLocked = false
    local isReplaceable = false
    local isInLockedTeam = false
    for _, char in ipairs(lockedTeamData.chars) do
        if char.charInstId == charInfo.instId then
            isInLockedTeam = true
            break
        end
        if char.isReplaceable and char.charId == charInfo.templateId then
            isLocked = true
            isReplaceable = true
        end
    end
    return isInLockedTeam, isLocked, isReplaceable
end
function getCharInfoListWithLockedTeamData(lockedTeamData)
    local charBag = GameInstance.player.charBag
    local charInfoList = {}
    local playerChars = charBag.charInfos
    local allCount = 0
    if lockedTeamData then
        for i, char in ipairs(lockedTeamData.chars) do
            local charInfo = getPlayerCharInfoByInstId(char.charInstId)
            local charData = getCharTableData(char.charId)
            local item = { instId = char.charInstId, templateId = char.charId, level = charInfo.level, ownTime = charInfo.ownTime, rarity = charData.rarity, slotIndex = i, slotReverseIndex = Const.BATTLE_SQUAD_MAX_CHAR_NUM - i, isLocked = char.isLocked, isTrail = char.isTrail, isReplaceable = char.isReplaceable, }
            table.insert(charInfoList, item)
            allCount = allCount + 1
        end
        if lockedTeamData.lockedTeamMemberCount == lockedTeamData.maxTeamMemberCount and not lockedTeamData.hasReplaceable then
            return charInfoList, allCount
        end
    end
    for instId, charInfo in pairs(playerChars) do
        local isClientOnly = GameUtil.IsRuntimeClientId(instId)
        local isInLockedTeam, isLock, isReplaceable = checkCharInLockedTeam(charInfo, lockedTeamData)
        if not isInLockedTeam and not isClientOnly then
            local templateId = charInfo.templateId
            local charData = getCharTableData(templateId)
            local item = { instId = instId, templateId = templateId, ownTime = charInfo.ownTime, level = charInfo.level, rarity = charData.rarity, slotIndex = Const.BATTLE_SQUAD_MAX_CHAR_NUM + 1, slotReverseIndex = -1, isLocked = isLock, isReplaceable = isReplaceable, }
            table.insert(charInfoList, item)
            if not isReplaceable and not charInfo.isDead then
                allCount = allCount + 1
            end
        end
    end
    local hasValue
    local charTeamData
    hasValue, charTeamData = Tables.charTeamTable:TryGetValue(lockedTeamData.teamConfigId)
    if hasValue then
        for _, charPresetId in pairs(charTeamData.presetCharList) do
            local charPresetData
            hasValue, charPresetData = Tables.charPresetTable:TryGetValue(charPresetId)
            if hasValue then
                local charInfo = getPlayerCharInfoByPresetId(charPresetId)
                local isInLockedTeam, isLock, isReplaceable = checkCharInLockedTeam(charInfo, lockedTeamData)
                if not isInLockedTeam then
                    local charData = getCharTableData(charInfo.templateId)
                    local item = { instId = charInfo.instId, templateId = charInfo.templateId, level = charInfo.level, ownTime = charInfo.ownTime, rarity = charData.rarity, slotIndex = Const.BATTLE_SQUAD_MAX_CHAR_NUM + 1, slotReverseIndex = -1, isTrail = true, isLocked = isLock, isReplaceable = isReplaceable, }
                    table.insert(charInfoList, item)
                    if not isReplaceable then
                        allCount = allCount + 1
                    end
                end
            end
        end
    end
    return charInfoList, allCount
end
function getLeaderCharInfo()
    local leaderIndex = GameInstance.player.squadManager.leaderIndex
    local curSquad = GameInstance.player.squadManager.curSquad
    local slot = curSquad.slots[leaderIndex]
    local charInstId = slot.charInstId
    local isClientOnly = GameUtil.IsRuntimeClientId(charInstId)
    if isClientOnly then
        local firstAvailableChar = getServerEndmin()
        return firstAvailableChar
    end
    local playerChar = getPlayerCharInfoByInstId(charInstId)
    if playerChar ~= nil then
        local charInfo = { instId = playerChar.instId, templateId = playerChar.templateId, }
        return charInfo
    else
        return nil
    end
end
function getServerEndmin()
    local charBag = GameInstance.player.charBag
    local playerChars = charBag.charInfos
    for instId, charInfo in pairs(playerChars) do
        local isClientOnly = GameUtil.IsRuntimeClientId(instId)
        if (not isClientOnly) and CharInfoUtils.isEndmin(charInfo.templateId) then
            return { instId = instId, templateId = charInfo.templateId }
        end
    end
end
function getCharDisplayData(templateId)
    local data
    local res, displayData = DataManager.characterDisplayConfig.data:TryGetValue(templateId)
    if res then
        data = displayData
    end
    return data
end
function getCharHeightData(charHeight)
    local res, displayData = DataManager.characterHeightConfig.heightDataDict:TryGetValue(charHeight)
    if not res then
        return
    end
    return displayData
end
function getCharHeadSpriteName(templateId)
    return UIConst.UI_SPRITE_CHAR_HEAD, UIConst.UI_CHAR_HEAD_PREFIX .. templateId
end
function getCharHeadSquareSpriteName(templateId)
    return UIConst.UI_SPRITE_CHAR_HEAD_SQUARE, UIConst.UI_CHAR_HEAD_PREFIX .. templateId
end
function getCharPaperAttributes(templateId, level, breakStage)
    local attributes = {}
    local _, attributesWithStringKey = DataManager.characterAttributeTable:TryGetData(templateId, level, breakStage)
    return attributesWithStringKey
end
function _getSlotBaseAttributes(charInfo, typeMask)
    if typeMask == nil then
        typeMask = UIConst.CHAR_INFO_ATTRIBUTE_ALL_FILTER_MASK
    end
    local attributes = {}
    for i = 1, GEnums.AttributeType.Enum:ToInt() - 1 do
        local attributeType = GEnums.AttributeType.__CastFrom(i)
        if attributeType then
            attributes[attributeType] = charInfo.attributes:GetBaseValue(attributeType, typeMask)
        end
    end
    return attributes
end
function _getSlotArmedAttributes(charInfo, armedTypeMask, baseTypeMask)
    if armedTypeMask == nil then
        armedTypeMask = UIConst.CHAR_INFO_ATTRIBUTE_ALL_FILTER_MASK
    end
    if baseTypeMask == nil then
        baseTypeMask = UIConst.CHAR_INFO_ATTRIBUTE_ALL_FILTER_MASK
    end
    local attributes = {}
    for i = 1, GEnums.AttributeType.Enum:ToInt() - 1 do
        local attributeType = GEnums.AttributeType.__CastFrom(i)
        if attributeType then
            attributes[attributeType] = charInfo.attributes:GetArmedValue(attributeType, armedTypeMask, baseTypeMask)
        end
    end
    return attributes
end
function _getSlotFinalAttributes(charInfo)
    local attributes = {}
    if charInfo.attributes == nil then
        logger.error("CharInfoUtils->Can't get char attributes, charTemplateId:" .. charInfo.templateId)
        return attributes
    end
    local attributes = {}
    for i = 1, GEnums.AttributeType.Enum:ToInt() - 1 do
        local attributeType = GEnums.AttributeType.__CastFrom(i)
        if attributeType then
            attributes[attributeType] = charInfo.attributes:GetValue(attributeType)
        end
    end
    return attributes
end
function getAllWeaponList(weaponType)
    local weaponList = {}
    local res, weaponInstDict = GameInstance.player.inventory:TryGetAllWeaponInstItems(Utils.getCurrentScope())
    if res then
        for weaponInstId, itemBundle in pairs(weaponInstDict) do
            local instInfo = getWeaponInstInfo(weaponInstId)
            local weaponInfo = FilterUtils.processWeapon(instInfo.weaponTemplateId, instInfo.weaponInstId)
            weaponInfo.instInfo = instInfo
            if not weaponType or instInfo.weaponCfg.weaponType == weaponType then
                table.insert(weaponList, weaponInfo)
            end
        end
    end
    return weaponList
end
function getWeaponInstInfo(weaponInstId)
    local res, itemBundle = GameInstance.player.inventory:TryGetWeaponInst(Utils.getCurrentScope(), weaponInstId)
    if not res then
        return
    end
    local weaponInst = itemBundle.instData
    local weaponTemplateId = weaponInst.templateId
    local _, itemCfg = Tables.itemTable:TryGetValue(weaponTemplateId)
    local weaponExhibitInfo = CharInfoUtils.getWeaponExhibitBasicInfo(weaponTemplateId, weaponInstId)
    local mainAttributeList, subAttributeList = CharInfoUtils.getWeaponShowAttributes(weaponInstId)
    local _, weaponCfg = Tables.weaponBasicTable:TryGetValue(weaponTemplateId)
    local data = { weaponInst = weaponInst, weaponInstId = weaponInst.instId, weaponTemplateId = weaponTemplateId, weaponExhibitInfo = weaponExhibitInfo, mainAttributeList = mainAttributeList, subAttributeList = subAttributeList, itemCfg = itemCfg, weaponCfg = weaponCfg, }
    return data
end
function getCharCurWeapon(charInstId)
    local charInfo = getPlayerCharInfoByInstId(charInstId)
    local weaponInstId = charInfo.weaponInstId
    return getWeaponInstInfo(weaponInstId)
end
function getWeaponByInstId(weaponInstId)
    local _, weaponInst = GameInstance.player.inventory:TryGetWeaponInst(Utils.getCurrentScope(), weaponInstId)
    if not weaponInst then
        return
    end
    local equipInstanceData = weaponInst.instData
    return equipInstanceData
end
function getGemByInstId(gemInstId)
    local _, getInst = GameInstance.player.inventory:TryGetGemInst(Utils.getCurrentScope(), gemInstId)
    if not getInst then
        return
    end
    local gemInstData = getInst.instData
    return gemInstData
end
function getGemLeadSkillTermId(gemInstId)
    local gemInst = getGemByInstId(gemInstId)
    if not gemInst then
        return
    end
    local maxCost = -1
    local maxCostTermId
    for _, skillTerm in pairs(gemInst.termList) do
        local challengerCfg = Tables.gemTable:GetValue(skillTerm.termId)
        if challengerCfg.isSkillTerm then
            if skillTerm.cost > maxCost then
                maxCost = skillTerm.cost
                maxCostTermId = skillTerm.termId
            elseif skillTerm.cost == maxCost then
                local curMaxTermCfg = Tables.gemTable:GetValue(maxCostTermId)
                local challengerCfg = Tables.gemTable:GetValue(skillTerm.termId)
                if challengerCfg and curMaxTermCfg then
                    if challengerCfg.sortOrder > curMaxTermCfg.sortOrder then
                        maxCost = skillTerm.cost
                        maxCostTermId = skillTerm.termId
                    end
                end
            end
        end
    end
    return maxCostTermId
end
function getWeaponBreakthroughInfo(weaponInstId, breakthroughLevel)
    local _, weaponInst = GameInstance.player.inventory:TryGetWeaponInst(Utils.getCurrentScope(), weaponInstId)
    local weaponInstData = weaponInst.instData
    if not weaponInstData then
        logger.error("CharInfoUtils->Can't get weapon inst from inventory, weaponInstId: " .. weaponInstId)
        return
    end
    if not breakthroughLevel then
        breakthroughLevel = weaponInstData.breakthroughLv
    end
    local weaponTemplateId = weaponInst.id
    local _, weaponCfg = Tables.weaponBasicTable:TryGetValue(weaponTemplateId)
    if not weaponCfg then
        logger.error("CharInfoUtils->Can't get weapon basic info, templateId: " .. weaponTemplateId)
        return
    end
    local breakthroughTemplateId = weaponCfg.breakthroughTemplateId
    local _, breakthroughTemplateCfg = Tables.weaponBreakThroughTemplateTable:TryGetValue(breakthroughTemplateId)
    if not breakthroughTemplateCfg then
        logger.error("CharInfoUtils->Can't get weapon breakthrough info, breakthroughTemplateId: " .. breakthroughTemplateId)
        return
    end
    for i, templateCfg in pairs(breakthroughTemplateCfg.list) do
        if templateCfg.breakthroughShowLv == breakthroughLevel then
            return templateCfg
        end
    end
end
function getWeaponExhibitBasicInfo(weaponTemplateId, weaponInstId)
    local _, weaponCfg = Tables.weaponBasicTable:TryGetValue(weaponTemplateId)
    if not weaponCfg then
        logger.error("CharInfoUtils->Can't get weapon basic info, templateId: " .. weaponTemplateId)
        return
    end
    local _, weaponItemCfg = Tables.itemTable:TryGetValue(weaponTemplateId)
    if not weaponItemCfg then
        logger.error("CharInfoUtils->Can't get weapon item info, templateId: " .. weaponTemplateId)
        return
    end
    local weaponInst = getWeaponByInstId(weaponInstId)
    local weaponExhibitInfo = {}
    local gemItemCfg
    local gemInst
    if weaponInst.attachedGemInstId and weaponInst.attachedGemInstId > 0 then
        gemInst = getGemByInstId(weaponInst.attachedGemInstId)
        local gemTemplateId = gemInst.templateId
        gemItemCfg = Tables.itemTable:GetValue(gemTemplateId)
    end
    weaponExhibitInfo.weaponInst = weaponInst
    weaponExhibitInfo.weaponCfg = weaponCfg
    weaponExhibitInfo.itemCfg = weaponItemCfg
    weaponExhibitInfo.gemItemCfg = gemItemCfg
    weaponExhibitInfo.gemInst = gemInst
    local expInfo = getWeaponExpInfo(weaponInstId)
    if not expInfo then
        logger.error("CharInfoUtils->Can't get weapon exp info, weaponInstId: " .. weaponInstId)
        return weaponExhibitInfo
    end
    weaponExhibitInfo.breakthroughGold = expInfo.breakthroughGold
    weaponExhibitInfo.curBreakthroughLv = expInfo.curBreakthroughLv
    weaponExhibitInfo.maxBreakthroughLv = expInfo.maxBreakthroughLv
    weaponExhibitInfo.breakthroughTemplateCfg = expInfo.breakthroughTemplateCfg
    weaponExhibitInfo.breakthroughInfoList = expInfo.breakthroughInfoList
    weaponExhibitInfo.curLv = expInfo.curLv
    weaponExhibitInfo.maxLv = expInfo.maxLv
    weaponExhibitInfo.stageLv = expInfo.stageLv
    weaponExhibitInfo.nextLvGold = expInfo.nextLvGold
    weaponExhibitInfo.nextLvExp = expInfo.nextLvExp
    weaponExhibitInfo.curExp = expInfo.curExp
    return weaponExhibitInfo
end
function getWeaponExpInfo(weaponInstId, targetBreakLv)
    local expInfo = {}
    local weaponInst = getWeaponByInstId(weaponInstId)
    local _, weaponCfg = Tables.weaponBasicTable:TryGetValue(weaponInst.templateId)
    if not weaponCfg then
        logger.error("CharInfoUtils->Can't get weapon basic info, templateId: " .. weaponInst.templateId)
        return
    end
    local breakthroughTemplateId = weaponCfg.breakthroughTemplateId
    local _, breakthroughTemplateCfg = Tables.weaponBreakThroughTemplateTable:TryGetValue(breakthroughTemplateId)
    if not breakthroughTemplateCfg then
        logger.error("CharInfoUtils->Can't get weapon breakthrough info, breakthroughTemplateId: " .. breakthroughTemplateId)
        return
    end
    local weaponInst = getWeaponByInstId(weaponInstId)
    local levelUpTemplateId = weaponCfg.levelTemplateId
    local hasLevelUpCfg, levelUpCfg = Tables.weaponUpgradeTemplateTable:TryGetValue(levelUpTemplateId)
    if not hasLevelUpCfg then
        logger.error("CharInfoUtils->Can't get weapon level up info, levelUpTemplateId: " .. levelUpTemplateId)
        return
    end
    local nextLvExp = -1
    local nextLvGold = -1
    if levelUpCfg.list.Count >= CSIndex(weaponInst.weaponLv + 1) then
        nextLvExp = levelUpCfg.list[CSIndex(weaponInst.weaponLv)].lvUpExp
        nextLvGold = levelUpCfg.list[CSIndex(weaponInst.weaponLv)].lvUpGold
    end
    local maxLv = weaponCfg.maxLv
    if targetBreakLv == nil then
        targetBreakLv = weaponInst.breakthroughLv
    end
    local maxBreak, breakLv2StageLv = getWeaponBreakLv2StageLv(weaponInst.templateId)
    local stageLv = breakLv2StageLv[targetBreakLv]
    expInfo.curBreakthroughLv = weaponInst.breakthroughLv
    expInfo.maxBreakthroughLv = maxBreak
    expInfo.breakthroughTemplateCfg = breakthroughTemplateCfg
    expInfo.curLv = weaponInst.weaponLv
    expInfo.maxLv = maxLv
    expInfo.stageLv = stageLv
    expInfo.nextLvGold = nextLvGold
    expInfo.nextLvExp = nextLvExp
    expInfo.curExp = weaponInst.exp
    return expInfo
end
function getWeaponBreakLv2StageLv(templateId)
    local _, weaponCfg = Tables.weaponBasicTable:TryGetValue(templateId)
    if not weaponCfg then
        logger.error("CharInfoUtils->Can't get weapon basic info, templateId: " .. templateId)
        return
    end
    local breakLv2StageLv = {}
    local breakthroughTemplateId = weaponCfg.breakthroughTemplateId
    local _, breakthroughTemplateCfg = Tables.weaponBreakThroughTemplateTable:TryGetValue(breakthroughTemplateId)
    local maxLv = weaponCfg.maxLv
    local maxStageLv = 1
    local maxBreak = 0
    for i = 1, breakthroughTemplateCfg.list.Count - 1 do
        local breakCfg = breakthroughTemplateCfg.list[CSIndex(i)]
        local nextBreakCfg = breakthroughTemplateCfg.list[CSIndex(i + 1)]
        if maxLv > nextBreakCfg.breakthroughShowLv then
            breakLv2StageLv[breakCfg.breakthroughShowLv] = nextBreakCfg.breakthroughLv
            maxBreak = nextBreakCfg.breakthroughShowLv
            maxStageLv = math.max(maxStageLv, nextBreakCfg.breakthroughShowLv)
        end
    end
    if maxStageLv < maxLv then
        breakLv2StageLv[maxBreak] = maxLv
    end
    return maxBreak, breakLv2StageLv
end
function getWeaponShowAttributes(instanceId, level)
    if level == nil then
        local weaponInst = getWeaponByInstId(instanceId)
        level = weaponInst.weaponLv
    end
    local mainAttrDict, subAttrDict = getWeaponShowAttributeDict(instanceId, level)
    local mainAttrShowAttributes = AttributeUtils.generateAttributeShowInfoListByModifierGroup(mainAttrDict)
    local subAttrShowAttributes = AttributeUtils.generateAttributeShowInfoListByModifierGroup(subAttrDict)
    return mainAttrShowAttributes, subAttrShowAttributes
end
function getWeaponShowAttributesByTemplateId(templateId, level)
    local hasValue, mainAttributeTuple = CS.Beyond.Gameplay.WeaponUtil.TryGetWeaponAttrModifierData(templateId, level)
    if hasValue then
        local mainAttrShowAttributes = AttributeUtils.generateAttributeShowInfoListByModifierGroup(_generateWeaponAttrDict(mainAttributeTuple))
        return mainAttrShowAttributes
    end
end
function getWeaponShowAttributesByTemplateIdWithBasicLevel(templateId)
    return getWeaponShowAttributesByTemplateId(templateId, 1)
end
function getWeaponShowAttributesByTemplateIdWithMaxLevel(templateId)
    local hasValue, basicData = Tables.weaponBasicTable:TryGetValue(templateId)
    if hasValue then
        return getWeaponShowAttributesByTemplateId(templateId, basicData.maxLv)
    end
end
function getWeaponShowAttributeDict(instanceId, level)
    local hasValue, attrTupleList = CS.Beyond.Gameplay.WeaponUtil.TryGetWeaponAttrModifierData(Utils.getCurrentScope(), instanceId, level)
    if not hasValue then
        logger.error("CharInfoUtils->Can't get weapon attributes, instanceId:" .. instanceId)
        return
    end
    local mainAttrDict = {}
    for i, attrTuple in pairs(attrTupleList) do
        local attrShowInfo = _generateWeaponAttributeData(attrTuple)
        mainAttrDict[attrShowInfo.attrType] = { [attrShowInfo.modifierType] = attrShowInfo, }
    end
    return mainAttrDict, {}
end
function _generateWeaponAttrDict(attrTupleList)
    local attrDict = {}
    for _, attrTuple in pairs(attrTupleList) do
        local attrShowInfo = _generateWeaponAttributeData(attrTuple)
        attrDict[attrShowInfo.attrType] = { [attrShowInfo.modifierType] = attrShowInfo, }
    end
    return attrDict
end
function _generateWeaponAttributeData(attrTuple)
    local attrData = {}
    local attrType, modifierType, attrValue = attrTuple.Item1, attrTuple.Item2, attrTuple.Item3
    attrData.attrType = attrType
    attrData.modifierType = modifierType
    attrData.attrValue = attrValue
    return attrData
end
function getCharTalentInTable(templateId, breakStage)
    local charData = getCharTableData(templateId)
    local talentDataBundle = charData.talentDataBundle
    local talents = {}
    for _, talentData in pairs(talentDataBundle) do
        local talentBreakStage = talentData.breakStage
        if talentBreakStage <= breakStage then
            table.insert(talents, talentData)
        end
    end
    return talents
end
function getCharBreakStageTalents(templateId, breakStage, targetBreakStage, needCurrent)
    local talents = getCharActiveTalent(templateId, breakStage)
    local targetTalents = getCharTalentInTable(templateId, targetBreakStage)
    local unlockTalents = {}
    local enhancedTalents = {}
    local tmpUnlockTalents = {}
    local tmpEnhancedTalents = {}
    for _, targetTalent in pairs(targetTalents) do
        local tmpBreakStage = targetTalent.breakStage
        local targetIndex = targetTalent.talentIndex
        local tmpUnlockTalent = tmpUnlockTalents[targetIndex]
        local tmpEnhancedTalent = tmpEnhancedTalents[targetIndex]
        if not talents[targetIndex] ~= nil then
            if not tmpUnlockTalent then
                tmpUnlockTalents[targetIndex] = targetTalent
            elseif tmpUnlockTalent.breakStage > tmpBreakStage then
                tmpUnlockTalents[targetIndex] = targetTalent
            end
        elseif talents[targetIndex].breakStage < targetTalent.breakStage or needCurrent then
            if not tmpEnhancedTalent then
                tmpEnhancedTalents[targetIndex] = targetTalent
            elseif tmpEnhancedTalent.breakStage == talents[targetIndex].breakStage then
                tmpEnhancedTalents[targetIndex] = targetTalent
            elseif targetTalent.breakStage ~= talents[targetIndex].breakStage and tmpEnhancedTalent.breakStage > targetTalent.breakStage then
                tmpEnhancedTalents[targetIndex] = targetTalent
            end
        end
    end
    for _, talent in pairs(tmpUnlockTalents) do
        table.insert(unlockTalents, { talentData = talent })
    end
    for targetIndex, talent in pairs(tmpEnhancedTalents) do
        table.insert(enhancedTalents, { talentData = needCurrent and talents[targetIndex] or talent, nextBreakStage = talent.breakStage, })
    end
    local resTalents = { unlockTalents = unlockTalents, enhancedTalents = enhancedTalents, }
    return resTalents
end
function getCharFacSkillUnlockBreakStage(templateId, facSkillId)
    local breakStage = -1
    local facSkills = Tables.characterTable:GetValue(templateId).facSkills
    for _, facSkill in pairs(facSkills) do
        if facSkill.skillId == facSkillId then
            breakStage = facSkill.breakStage
            break
        end
    end
    return breakStage
end
function getFacSkillSlotIndex(templateId)
    local index2skill = {}
    local skill2Index = {}
    local charData = getCharTableData(templateId)
    local facSkills = charData.facSkills
    for _, facSkill in pairs(facSkills) do
        local skillIndex = facSkill.skillIndex
        local skillId = facSkill.skillId
        if not index2skill[skillIndex] then
            index2skill[skillIndex] = {}
        end
        skill2Index[skillId] = skillIndex
        index2skill[skillIndex][skillId] = facSkill
    end
    return index2skill, skill2Index
end
function getCharBreakStageFacSkills(templateId, breakStage, targetBreakStage, needCurrent)
    local skills = GameInstance.player.facCharacterSystem:GetSkill(templateId, breakStage)
    local targetSkills = GameInstance.player.facCharacterSystem:GetSkill(templateId, targetBreakStage)
    local unlockFacSkills = {}
    local upgradeFacSkills = {}
    local curSkills = {}
    local tmpSkills = {}
    local index2skill, skill2Index = getFacSkillSlotIndex(templateId)
    for _, facSkillId in pairs(skills) do
        local skillIndex = skill2Index[facSkillId]
        curSkills[skillIndex] = facSkillId
    end
    for _, facSkillId in pairs(targetSkills) do
        local skillIndex = skill2Index[facSkillId]
        tmpSkills[skillIndex] = facSkillId
    end
    for skillIndex, facSkillId in pairs(tmpSkills) do
        if not curSkills[skillIndex] then
            local skillData = Tables.factorySkillTable:GetValue(facSkillId)
            table.insert(unlockFacSkills, skillData)
        end
    end
    for skillIndex, facSkillId in pairs(curSkills) do
        local res, needBreakStage = GameInstance.player.facCharacterSystem:HaveAdvancedSkill(templateId, facSkillId)
        local skillData = Tables.factorySkillTable:GetValue(facSkillId)
        if needCurrent then
            table.insert(upgradeFacSkills, skillData)
        elseif (res and needBreakStage == targetBreakStage) then
            local nextSkillId = tmpSkills[skillIndex]
            skillData = Tables.factorySkillTable:GetValue(nextSkillId)
            table.insert(upgradeFacSkills, skillData)
        end
    end
    local facSkills = { unlockFacSkills = unlockFacSkills, upgradeFacSkills = upgradeFacSkills, }
    return facSkills
end
function getCharActiveTalent(templateId, breakStage)
    local talents = {}
    return talents
end
function getTalentSkillData(talentData)
    local skillDatas = {}
    for _, talentEffect in pairs(talentData.talentEffects) do
        if talentEffect.talentEffectType == GEnums.TalentEffectType.AddPassiveSkill then
            local skillId = talentEffect.passiveSkillId
            local level = talentEffect.passiveSkillLevel
            local res, skillPatchData = DataManager:TryGetSkillPatchData(skillId, level)
            if res then
                table.insert(skillDatas, skillPatchData)
            end
        end
    end
    return skillDatas
end
function getTalentMaxBreakStage(templateId, talentIndex)
    local characterData = getCharTableData(templateId)
    local maxBreakStage = -1
    local talentDataBundle = characterData.talentDataBundle
    for luaIndex = 1, talentDataBundle.Count do
        local talent = talentDataBundle[CSIndex(luaIndex)]
        if talent.talentIndex == talentIndex then
            maxBreakStage = math.max(maxBreakStage, talent.breakStage)
        end
    end
    return maxBreakStage
end
function checkIfSkillElite(skillId, skillLv)
end
function getCharCurTalentNodes(charInstId)
    local charInfo = getPlayerCharInfoByInstId(charInstId)
    local templateId = charInfo.templateId
    local potentialLevel = 0
    local skillNodeList = _getCharSkillNodeList(templateId, potentialLevel)
    local attributeNodeList = {}
    local passiveNodeATable = {}
    local passiveNodeBTable = {}
    local breakNodeTable = {}
end
function _getCharSkillNodeList(templateId, potentialLevel)
    local charGrowthData = Tables.charGrowthTable:GetValue(templateId)
    local skillId2LevelNode = {}
    for _, skillLevelData in ipairs(charGrowthData.skillLevelUp) do
        local skillId = skillLevelData.skillId
        if not skillId2LevelNode[skillId] then
            skillId2LevelNode[skillId] = {}
        end
        local skillLevelList = skillId2LevelNode[skillId]
        table.insert(skillLevelList, skillLevelData)
    end
    return skillId2LevelNode
end
function classifyMainSkillUpgradeNodes(instId, potentialLevel)
    local mainSkills = {}
    local showOrderList = {}
    local charInst = getPlayerCharInfoByInstId(instId)
    local charGrowthData = Tables.charGrowthTable:GetValue(charInst.templateId)
    local allSkillNode = charGrowthData.skillLevelUp
    for i, skillNode in pairs(allSkillNode) do
        local skillGroupId = skillNode.skillGroupId
        local skillGroupCfg = getSkillGroupCfg(charInst.templateId, skillGroupId)
        if mainSkills[skillGroupId] == nil then
            mainSkills[skillGroupId] = {}
            for index, skillGroupType in ipairs(UIConst.CHAR_INFO_SKILL_SHOW_ORDER) do
                if skillGroupCfg.skillGroupType == skillGroupType then
                    showOrderList[index] = skillGroupId
                end
            end
        end
    end
    for i, skillUpgradeList in pairs(mainSkills) do
        table.sort(skillUpgradeList, function(a, b)
            return a.level < b.level
        end)
    end
    return mainSkills, showOrderList
end
function getCharSpaceshipSkillUpgradeList(templateId)
    local shipSkills = {}
    local charSpaceShipSkillList = Tables.spaceshipCharSkillTable[templateId].skillList
    for _, charSkillCfg in pairs(charSpaceShipSkillList) do
        local skillIndex = charSkillCfg.skillIndex
        if shipSkills[skillIndex] == nil then
            shipSkills[skillIndex] = {}
        end
        local skillCfg = Tables.spaceshipSkillTable[charSkillCfg.skillId]
        table.insert(shipSkills[skillIndex], { charSkillCfg = charSkillCfg, skillCfg = skillCfg })
    end
    for i, shipSkillList in pairs(shipSkills) do
        table.sort(shipSkillList, function(a, b)
            return a.skillCfg.level < b.skillCfg.level
        end)
    end
    return shipSkills
end
function classifyTalentNode(templateId, potentialLevel)
    local attrNodeList = {}
    local passiveSkillNodes = {}
    local shipSkills = {}
    local charGrowthData = Tables.charGrowthTable:GetValue(templateId)
    local allTalentNode = charGrowthData.talentNodeMap
    for nodeId, nodeInfo in pairs(allTalentNode) do
        local nodeType = nodeInfo.nodeType
        if nodeType == GEnums.TalentNodeType.PassiveSkill then
            local index = nodeInfo.passiveSkillNodeInfo.index
            if passiveSkillNodes[index] == nil then
                passiveSkillNodes[index] = {}
            end
            table.insert(passiveSkillNodes[index], nodeInfo)
        elseif nodeType == GEnums.TalentNodeType.Attr then
            table.insert(attrNodeList, nodeInfo)
        elseif nodeType == GEnums.TalentNodeType.FactorySkill then
            local shipSkillId = nodeInfo.nodeId
            local skillIndex = nodeInfo.factorySkillNodeInfo.index
            if shipSkills[skillIndex] == nil then
                shipSkills[skillIndex] = {}
            end
            table.insert(shipSkills[skillIndex], nodeInfo)
        end
    end
    table.sort(attrNodeList, function(a, b)
        if a.attributeNodeInfo.breakStage ~= b.attributeNodeInfo.breakStage then
            return a.attributeNodeInfo.breakStage < b.attributeNodeInfo.breakStage
        else
            local attrTypeA = a.attributeNodeInfo.attributeModifier.attrType
            local attrTypeB = b.attributeNodeInfo.attributeModifier.attrType
            return attrTypeA:ToInt() < attrTypeB:ToInt()
        end
    end)
    for index, skillNodeList in pairs(passiveSkillNodes) do
        table.sort(skillNodeList, function(a, b)
            return a.passiveSkillNodeInfo.breakStage < b.passiveSkillNodeInfo.breakStage
        end)
    end
    for i, shipSkillNodeList in pairs(shipSkills) do
        table.sort(shipSkillNodeList, function(a, b)
            return a.factorySkillNodeInfo.breakStage < b.factorySkillNodeInfo.breakStage
        end)
    end
    local passiveSkillNodeList = {}
    for index, nodeList in pairs(passiveSkillNodes) do
        local nodeIndex = nodeList[1].passiveSkillNodeInfo.index
        passiveSkillNodeList[nodeIndex] = nodeList
    end
    local facSkillNodeList = {}
    for skillIndex, nodeList in pairs(shipSkills) do
        table.insert(facSkillNodeList, { skillIndex = skillIndex, nodeList = nodeList, })
    end
    return attrNodeList, passiveSkillNodeList, facSkillNodeList
end
function getSkillType(templateId, skillId)
    local res, skillTable = Tables.skillLockTable:TryGetValue(templateId)
    if res then
        local bundleData = skillTable.BundleData
        for _, skillData in pairs(bundleData) do
            if skillData.skillId == skillId then
                return skillData.skillType
            end
        end
    end
    return nil
end
function getPlayerCharSkillByTypeUnlock(charInstId, templateId, skillType, level, teamIndex)
    return getPlayerCharSkillByType(charInstId, templateId, skillType, level, true, teamIndex)
end
function getSkillDataById(skillId, level)
    local get, skillPatchData = DataManager:TryGetSkillPatchData(skillId, level)
    if not get then
        skillPatchData = nil
    end
    local skillData = { patchData = skillPatchData, level = level, }
    return skillData
end
function getPlayerCharSkillByType(charInstId, templateId, skillGroupType, level, onlyUnlock)
    local charInfo
    if charInstId ~= nil and not templateId then
        charInfo = getPlayerCharInfoByInstId(charInstId)
        templateId = charInfo.templateId
    end
    local _, charGrowthData = Tables.charGrowthTable:TryGetValue(templateId)
    local skillGroupData
    if charGrowthData then
        for _, data in pairs(charGrowthData.skillGroupMap) do
            if data.skillGroupType == skillGroupType then
                skillGroupData = data
            end
        end
    end
    local skills = {}
    local skillLevelUpData = getCharSkillLevelData(templateId)
    if charGrowthData and skillGroupData then
        local maxLevel
        local inUse = true
        local skillId = skillGroupData.skillId
        local skillGroupId = skillGroupData.skillGroupId
        local res, skillInfo = CS.Beyond.Gameplay.SkillUtil.TryGetCharSkillGroupInfo(charInstId, skillGroupId)
        local unlock = true
        if res then
            if not level then
                level = skillInfo.level
            end
            maxLevel = skillInfo.maxLevel
        else
            if not level then
                level = 1
            end
            maxLevel = level
        end
        local realMaxLevel = skillLevelUpData[skillGroupId] and skillLevelUpData[skillGroupId].realMaxLevel or maxLevel
        local find, skillData = Tables.skillPatchTable:TryGetValue(skillId)
        if find and skillData then
            local _, skillPatchData = DataManager:TryGetSkillPatchData(skillId, level)
            local btnSkillInfo = { skillId = skillId, patchData = skillPatchData, bundleData = skillGroupData, level = level, maxLevel = maxLevel, inUse = inUse, unlock = unlock, realMaxLevel = realMaxLevel, breakStage = 0, }
            if not onlyUnlock or (onlyUnlock and unlock) then
                table.insert(skills, btnSkillInfo)
            end
        end
    end
    table.sort(skills, Utils.genSortFunction({ "breakStage" }, true))
    return skills
end
function getPlayerCharCurSkills(charInstId)
    local skills = {}
    for skillType, btnIndex in pairs(UIConst.SKILL_TYPE_2_BTN_INDEX) do
        local skillList = getPlayerCharSkillByType(charInstId, nil, skillType, nil, nil)
        skills[btnIndex] = skillList
    end
    return skills
end
function getCharInfoSkillGroupBgColor(skillGroupCfg)
    local firstSkillId = skillGroupCfg.skillIdList[0]
    local firstSkillCfg = CharInfoUtils.getSkillCfg(firstSkillId, 1)
    local iconBgType = firstSkillCfg.iconBgType
    if iconBgType == CS.Beyond.GEnums.DamageType.Fire then
        return Color(1, 0.384, 0.239)
    elseif iconBgType == CS.Beyond.GEnums.DamageType.Pulse then
        return Color(1, 0.753, 0)
    elseif iconBgType == CS.Beyond.GEnums.DamageType.Cryst then
        return Color(0.129, 0.776, 0.816)
    elseif iconBgType == CS.Beyond.GEnums.DamageType.Natural then
        return Color(0.671, 0.749, 0)
    else
        return Color(0.373, 0.373, 0.373)
    end
end
function getCharSkillGroupCfgByType(templateId, skillGroupType)
    local get, charGrowthData = Tables.charGrowthTable:TryGetValue(templateId)
    if not get then
        return nil
    end
    for _, data in pairs(charGrowthData.skillGroupMap) do
        if data.skillGroupType == skillGroupType and #data.skillIdList > 0 then
            return data
        end
    end
    return nil
end
function getCharFirstSkillIdByType(templateId, skillGroupType)
    local get, charGrowthData = Tables.charGrowthTable:TryGetValue(templateId)
    if not get then
        return nil
    end
    for _, data in pairs(charGrowthData.skillGroupMap) do
        if data.skillGroupType == skillGroupType and #data.skillIdList > 0 then
            return data.skillIdList[0]
        end
    end
    return nil
end
function getCharSkillLevelData(templateId)
    local data = {}
    local charData = getCharTableData(templateId)
    local skillLevelUp = charData.skillLevelUp
    for _, skillLevelData in pairs(skillLevelUp) do
        local skillGroupId = skillLevelData.skillGroupId
        local level = skillLevelData.level
        if not data[skillGroupId] then
            data[skillGroupId] = { realMaxLevel = 1, }
        end
        data[skillGroupId][level] = skillLevelData
        data[skillGroupId].realMaxLevel = math.max(data[skillGroupId].realMaxLevel, level)
    end
    return data
end
function getSkillTypeName(skillType)
    local skillTypeText
    if skillType == Const.SkillTypeEnum.NormalSkill then
        skillTypeText = Language.LUA_NORMAL_SKILL
    elseif skillType == Const.SkillTypeEnum.UltimateSkill then
        skillTypeText = Language.LUA_ULTIMATE_SKILL
    else
        skillTypeText = Language.LUA_NORMAL_ATTACK
    end
    return skillTypeText
end
function getBreakStageUnlockSkills(templateId, breakStage)
    local charTable = getCharTableData(templateId)
    local skills = {}
    local res, breakStageEffectData = charTable.breakStageEffect:TryGetValue(breakStage)
    if res then
        skills = breakStageEffectData.skillUnlock
    end
    return skills
end
function getCharSkillUpgradeNextBreakStage(templateId, breakStage, skillType)
    local targetBreakStage
    local charTable = getCharTableData(templateId)
    local maxBreakStage = Tables.characterConst.maxBreak
    if maxBreakStage == breakStage then
        return targetBreakStage
    end
    for i = breakStage + 1, maxBreakStage do
        local res, breakStageEffectData = charTable.breakStageEffect:TryGetValue(i)
        if res then
            for _, data in pairs(breakStageEffectData.skillEffect) do
                if data.skillType == skillType then
                    targetBreakStage = i
                    break
                end
            end
        end
        if targetBreakStage then
            break
        end
    end
    return targetBreakStage
end
function getCharSkillLevelInfo(charInfo, skillGroupId)
    local charInst = getPlayerCharInfoByInstId(charInfo.instId)
    local skillGroupList = charInst.skillGroupLevelInfoList
    for _, skillGroupInfo in pairs(skillGroupList) do
        if skillGroupInfo.skillGroupId == skillGroupId then
            return skillGroupInfo
        end
    end
    logger.error(string.format("角色养成->角色templateId[%s]缺少技能组[%s]", charInst.templateId, skillGroupId))
    return nil
end
function getCharSkillLevelByType(templateId, skillGroupType)
    local skillInfo = getCharSkillLevelInfoByType(templateId, skillGroupType)
    if skillInfo == nil then
        return 1
    end
    return skillInfo.level
end
function getCharSkillLevelInfoByType(charInfo, skillGroupType)
    local templateId = charInfo.templateId
    local get, charGrowthData = Tables.charGrowthTable:TryGetValue(templateId)
    if not get then
        return nil
    end
    local skillGroupId
    for _, data in pairs(charGrowthData.skillGroupMap) do
        if data.skillGroupType == skillGroupType then
            skillGroupId = data.skillGroupId
            break
        end
    end
    if skillGroupId == nil then
        return nil
    end
    local skillLevelInfo = getCharSkillLevelInfo(charInfo, skillGroupId)
    if skillLevelInfo == nil then
        return nil
    end
    return skillLevelInfo
end
function getSkillCfg(skillId, skillLv)
    local get, talentSkillCfg = Tables.SkillPatchTable:TryGetValue(skillId)
    if not get then
        logger.error("CharInfoTalentCtrl->_RefreshPassiveSkillCell: skillId not found in SkillPatchTable, skillId = " .. tostring(skillId))
        return
    end
    local exactSkillCfg
    for i, skillCfg in pairs(talentSkillCfg.SkillPatchDataBundle) do
        if skillCfg.level == skillLv then
            exactSkillCfg = skillCfg
            break
        end
    end
    return exactSkillCfg
end
function getShipSkillCfg(skillId)
    local get, skillCfg = Tables.spaceshipSkillTable:TryGetValue(skillId)
    if not get then
        logger.error("CharInfoTalentCtrl->_RefreshPassiveSkillCell: skillId not found in spaceshipSkillTable, skillId = " .. tostring(skillId))
        return
    end
    return skillCfg
end
function getSkillGroupCfg(charId, skillGroupId)
    local charGrowthData = Tables.CharGrowthTable[charId]
    local get, skillGroupData = charGrowthData.skillGroupMap:TryGetValue(skillGroupId)
    return skillGroupData
end
function getTalentNodeCfg(charTemplateId, nodeId)
    local charGrowthCfg = Tables.charGrowthTable[charTemplateId]
    local success, nodeCfg = charGrowthCfg.talentNodeMap:TryGetValue(nodeId)
    if success then
        return nodeCfg
    end
end
function getCharSpaceshipSkillIndex(templateId, skillId)
    local charSpaceShipSkillList = Tables.spaceshipCharSkillTable[templateId].skillList
    for _, skillCfg in pairs(charSpaceShipSkillList) do
        if skillCfg.skillId == skillId then
            return skillCfg.skillIndex
        end
    end
end
function getSkillTalentNodeBySkillId(charTemplateId, skillGroupId, skillLv)
    local charGrowthCfg = Tables.charGrowthTable[charTemplateId]
    local skillUpgradeList = charGrowthCfg.skillLevelUp
    for _, skillUpgradeCfg in pairs(skillUpgradeList) do
        if skillUpgradeCfg.skillGroupId == skillGroupId and skillUpgradeCfg.level == skillLv then
            return skillUpgradeCfg
        end
    end
end
function getPassiveSkillTalentNodeByIndex(charTemplateId, nodeIndex, nodeLevel)
    local foundNodeList = getAllPassiveSkillTalentNodeByIndex(charTemplateId, nodeIndex)
    if nodeLevel then
        for i, talentNode in pairs(foundNodeList) do
            if talentNode.passiveSkillNodeInfo.level == nodeLevel then
                return talentNode
            end
        end
    end
end
function getShipSkillIdByTalentNodeId(charTemplateId, nodeId)
    local charGrowthCfg = Tables.charGrowthTable[charTemplateId]
    local talentNodeMap = charGrowthCfg.talentNodeMap
    local talentNode = talentNodeMap[nodeId]
    if talentNode.nodeType ~= GEnums.TalentNodeType.FactorySkill then
        return
    end
    local index = talentNode.factorySkillNodeInfo.index
    local level = talentNode.factorySkillNodeInfo.level
    local shipSkillList = Tables.spaceshipCharSkillTable[charTemplateId].skillList
    for _, shipSkill in pairs(shipSkillList) do
        if shipSkill.skillIndex == index then
            local shipSkillCfg = Tables.spaceshipSkillTable[shipSkill.skillId]
            if shipSkillCfg.level == level then
                return shipSkill.skillId
            end
        end
    end
end
function getAllPassiveSkillTalentNodeByIndex(charTemplateId, nodeIndex)
    local charGrowthCfg = Tables.charGrowthTable[charTemplateId]
    local talentNodeMap = charGrowthCfg.talentNodeMap
    local foundNodeList = {}
    for _, talentNode in pairs(talentNodeMap) do
        local passiveSkillNodeInfo = talentNode.passiveSkillNodeInfo
        if talentNode.nodeType == GEnums.TalentNodeType.PassiveSkill and passiveSkillNodeInfo.index == nodeIndex then
            table.insert(foundNodeList, talentNode)
        end
    end
    return foundNodeList
end
function getShipSkillTalentNodeBySkillId(charTemplateId, skillId)
    local shipSkillCfg = Tables.spaceshipSkillTable[skillId]
    local skillLevel = shipSkillCfg.level
    local charShipSkillList = Tables.spaceshipCharSkillTable[charTemplateId].skillList
    for _, shipSkill in pairs(charShipSkillList) do
        if shipSkill.skillId == skillId then
            local skillIndex = shipSkill.skillIndex
            local charGrowthCfg = Tables.charGrowthTable[charTemplateId]
            local talentNodeMap = charGrowthCfg.talentNodeMap
            for _, talentNode in pairs(talentNodeMap) do
                if talentNode.nodeType == GEnums.TalentNodeType.FactorySkill and talentNode.factorySkillNodeInfo.index == skillIndex and talentNode.factorySkillNodeInfo.level == skillLevel then
                    return talentNode
                end
            end
        end
    end
end
function getAttributeNodeStatus(charInstId, attrNodeId)
    local lockText
    local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
    local attrNodeCfg = CharInfoUtils.getTalentNodeCfg(charInst.templateId, attrNodeId)
    local friendshipValue = CSPlayerDataUtil.GetCharFriendshipByInstId(charInst.instId)
    local isBelowFriendshipValue = friendshipValue < attrNodeCfg.attributeNodeInfo.favorability
    local isBelowBreakStage = attrNodeCfg.attributeNodeInfo.breakStage > charInst.breakStage
    if isBelowFriendshipValue then
        lockText = Language.LUA_CHAR_INFO_TALENT_BELOW_FRIENDSHIP_TOAST
    end
    if isBelowBreakStage then
        lockText = string.format(Language.LUA_CHAR_INFO_TALENT_UPGRADE_BREAK_LOCK_HINT, attrNodeCfg.attributeNodeInfo.breakStage)
    end
    local isLock = isBelowBreakStage or (friendshipValue < attrNodeCfg.attributeNodeInfo.favorability)
    local isActive = charInst.talentInfo.attributeNodes:Contains(attrNodeId)
    return isActive, isLock, lockText
end
function getCharBreakNodeFromStageAndEquipTier(breakStage, equipTierLimit)
    for nodeId, nodeCfg in pairs(Tables.charBreakNodeTable) do
        if nodeCfg.breakStage == breakStage and nodeCfg.equipTierLimit == equipTierLimit then
            return nodeId
        end
    end
end
function getExactSkillIdInSkillGroup(skillGroupData, skillLv)
    for _, skillData in pairs(skillGroupData.skillIdList) do
        if skillData.level == skillLv then
            return skillData.skillId
        end
    end
end
function getCharBreakNodeStatus(charInstId, nodeId)
    local charInst = getPlayerCharInfoByInstId(charInstId)
    local charBreakCostMap = Tables.charGrowthTable[charInst.templateId].charBreakCostMap
    local breakCfg = charBreakCostMap[nodeId]
    local isLockByLv = false
    local isLockByEquipTier = breakCfg.equipTierLimit > charInst.equipTierLimit
    local isLockByBreakStage = breakCfg.breakStage - 1 > charInst.breakStage
    if charInst.breakStage == breakCfg.breakStage - 1 and (not isLockByEquipTier) then
        local breakStageCfg = Tables.charBreakStageTable[breakCfg.breakStage - 1]
        isLockByLv = breakStageCfg.maxCharLevel > charInst.level
    end
    local isLock = isLockByEquipTier or isLockByBreakStage or isLockByLv
    local isActive = charInst.breakStage >= breakCfg.breakStage
    return isActive, isLock, { isLockByLv = isLockByLv, }
end
function getEquipBreakNodeStatus(charInstId, nodeId)
    local charInst = getPlayerCharInfoByInstId(charInstId)
    local charBreakCostMap = Tables.charGrowthTable[charInst.templateId].charBreakCostMap
    local breakCfg = charBreakCostMap[nodeId]
    local isActive = false
    if breakCfg.breakStage < charInst.breakStage then
        isActive = true
    elseif breakCfg.breakStage == charInst.breakStage then
        isActive = breakCfg.nodeId == charInst.talentInfo.latestBreakNode
    end
    local isLock = breakCfg.breakStage > charInst.breakStage
    return isActive, isLock, {}
end
function getPassiveSkillNodeStatus(charInstId, nodeId)
    local charInst = getPlayerCharInfoByInstId(charInstId)
    local nodeCfg = getTalentNodeCfg(charInst.templateId, nodeId)
    local passiveSkillNodeInfo = nodeCfg.passiveSkillNodeInfo
    local isActive, isLock, lockText = _innerGetPassiveSkillNodeStatus(charInstId, nodeId)
    if isActive or isLock then
        return isActive, isLock, lockText
    end
    local foundNodeList = getAllPassiveSkillTalentNodeByIndex(charInst.templateId, passiveSkillNodeInfo.index)
    table.sort(foundNodeList, function(a, b)
        return a.passiveSkillNodeInfo.level < b.passiveSkillNodeInfo.level
    end)
    local nextNodeCfg = foundNodeList[passiveSkillNodeInfo.level + 1]
    if nextNodeCfg then
        local nextActive = _innerGetPassiveSkillNodeStatus(charInstId, nextNodeCfg.nodeId)
        if nextActive then
            return true, false
        end
    end
    if passiveSkillNodeInfo.level > 1 then
        local previousNodeCfg = foundNodeList[passiveSkillNodeInfo.level - 1]
        if previousNodeCfg then
            local lastActive, lastLock = _innerGetPassiveSkillNodeStatus(charInstId, previousNodeCfg.nodeId)
            if not lastActive then
                return false, true, Language.LUA_CHAR_INFO_TALENT_PREVIOUS_SKILL_INACTIVE
            end
        end
    end
    return false, false
end
function _innerGetPassiveSkillNodeStatus(charInstId, nodeId)
    local charInst = getPlayerCharInfoByInstId(charInstId)
    local nodeCfg = getTalentNodeCfg(charInst.templateId, nodeId)
    local passiveSkillNodeInfo = nodeCfg.passiveSkillNodeInfo
    local isActive = charInst.talentInfo.latestPassiveSkillNodes:Contains(nodeId)
    if isActive then
        return true, false
    end
    local isLock = passiveSkillNodeInfo.breakStage > charInst.breakStage
    if isLock then
        local lockText = string.format(Language.LUA_CHAR_INFO_TALENT_UPGRADE_BREAK_LOCK_HINT, passiveSkillNodeInfo.breakStage)
        return false, true, lockText
    end
    return false, false
end
function getShipSkillTalentNodeByIndex(charTemplateId, index, level)
    local charGrowthCfg = Tables.charGrowthTable[charTemplateId]
    local talentNodeMap = charGrowthCfg.talentNodeMap
    for nodeId, nodeCfg in pairs(talentNodeMap) do
        if nodeCfg.nodeType == GEnums.TalentNodeType.FactorySkill then
            local factorySkillNodeInfo = nodeCfg.factorySkillNodeInfo
            if factorySkillNodeInfo.index == index and factorySkillNodeInfo.level == level then
                return nodeCfg
            end
        end
    end
end
function getShipSkillNodeStatus(charInstId, nodeId)
    local charInst = getPlayerCharInfoByInstId(charInstId)
    local nodeCfg = getTalentNodeCfg(charInst.templateId, nodeId)
    local factorySkillNodeInfo = nodeCfg.factorySkillNodeInfo
    local isActive, isLock, lockText = _innerGetFacSkillNodeStatus(charInstId, nodeId)
    if isActive or isLock then
        return isActive, isLock, lockText
    end
    local foundNodeList = getAllFactorySkillTalentNodeByIndex(charInst.templateId, factorySkillNodeInfo.index)
    table.sort(foundNodeList, function(a, b)
        return a.factorySkillNodeInfo.level < b.factorySkillNodeInfo.level
    end)
    local nextNodeCfg = foundNodeList[factorySkillNodeInfo.level + 1]
    if nextNodeCfg then
        local nextActive = _innerGetFacSkillNodeStatus(charInstId, nextNodeCfg.nodeId)
        if nextActive then
            return true, false
        end
    end
    if factorySkillNodeInfo.level > 1 then
        local previousNodeCfg = foundNodeList[factorySkillNodeInfo.level - 1]
        if previousNodeCfg then
            local lastActive, lastLock = _innerGetFacSkillNodeStatus(charInstId, previousNodeCfg.nodeId)
            if not lastActive then
                return false, true, Language.LUA_CHAR_INFO_TALENT_PREVIOUS_SKILL_INACTIVE
            end
        end
    end
    return false, false
end
function getAllFactorySkillTalentNodeByIndex(templateId, index)
    local foundNodeList = {}
    local charGrowthCfg = Tables.charGrowthTable[templateId]
    local talentNodeMap = charGrowthCfg.talentNodeMap
    for i, nodeCfg in pairs(talentNodeMap) do
        if nodeCfg.nodeType == GEnums.TalentNodeType.FactorySkill then
            local factorySkillNodeInfo = nodeCfg.factorySkillNodeInfo
            if factorySkillNodeInfo.index == index then
                table.insert(foundNodeList, nodeCfg)
            end
        end
    end
    return foundNodeList
end
function _innerGetFacSkillNodeStatus(charInstId, nodeId)
    local charInst = getPlayerCharInfoByInstId(charInstId)
    local nodeCfg = getTalentNodeCfg(charInst.templateId, nodeId)
    local factorySkillNodeInfo = nodeCfg.factorySkillNodeInfo
    local isActive = charInst.talentInfo.latestFactorySkillNodes:Contains(nodeId)
    if isActive then
        return true, false
    end
    local isLock = factorySkillNodeInfo.breakStage > charInst.breakStage
    if isLock then
        local lockText = string.format(Language.LUA_CHAR_INFO_TALENT_UPGRADE_BREAK_LOCK_HINT, factorySkillNodeInfo.breakStage)
        return false, true, lockText
    end
    return false, false
end
function getSkillCanUpgradeLv(skillGroupType, breakStage)
    local stageCfg = Tables.charBreakStageTable[breakStage]
    local canUpgradeLv = 0
    if skillGroupType == GEnums.SkillGroupType.NormalAttack then
        canUpgradeLv = stageCfg.normalAttackSkillLevel
    elseif skillGroupType == GEnums.SkillGroupType.NormalSkill then
        canUpgradeLv = stageCfg.normalSkillLevel
    elseif skillGroupType == GEnums.SkillGroupType.UltimateSkill then
        canUpgradeLv = stageCfg.ultimateSkillLevel
    elseif skillGroupType == GEnums.SkillGroupType.ComboSkill then
        canUpgradeLv = stageCfg.comboSkillLevel
    else
        logger.error("CharInfoTalentCtrl->getSkillCanUpgradeLv: skillType can't upgrade !!!!, skillType = " .. tostring(skillGroupType))
    end
    return canUpgradeLv
end
function getSkillDesc(skillId, skillLv)
    local skillDesc = Utils.SkillUtil.GetSkillDescription(skillId, skillLv)
    local resolveTextStyle = UIUtils.resolveTextStyle(skillDesc)
    return resolveTextStyle
end
function getGroupSkillExtraInfoList(skillGroupId, skillLv)
end
function getSkillExtraInfoList(skillId, skillLv)
    local skillExtraInfoList = {}
    local _, skillPatchData = DataManager:TryGetSkillPatchData(skillId, skillLv)
    local cooldownTime = skillPatchData.coolDown
    local costType = skillPatchData.costType
    local costValue = skillPatchData.costValue
    if costType == GEnums.CostType.Atb then
        if costValue > 0 and math.abs(costValue) > 0.01 then
            local roundedValue = lume.round(costValue)
            table.insert(skillExtraInfoList, { name = Language.LUA_CHAR_INFO_SKILL_COST_ATB, value = roundedValue, })
        end
    end
    if costType == GEnums.CostType.UltimateSp then
        if costValue > 0 and math.abs(costValue) > 0.01 then
            local roundedValue = lume.round(costValue)
            table.insert(skillExtraInfoList, { name = Language.LUA_CHAR_INFO_SKILL_COST_SP, value = roundedValue, })
        end
    end
    if cooldownTime and cooldownTime > 0 and math.abs(cooldownTime) > 0.01 then
        local roundedValue = lume.round(cooldownTime * 10) / 10
        if (roundedValue * 10) % 10 == 0 then
            roundedValue = math.floor(roundedValue)
        end
        table.insert(skillExtraInfoList, { name = Language.LUA_CHAR_INFO_SKILL_DURATION, value = string.format(Language.LUA_CHAR_INFO_SKILL_DURATION_FORMAT, roundedValue), })
    end
    return skillExtraInfoList
end
function isCharBreakCostEnough(templateId, nodeId)
    local _, charGrowthData = Tables.charGrowthTable:TryGetValue(templateId)
    if not charGrowthData then
        return false
    end
    local _, charBreakDetailData = charGrowthData.charBreakCostMap:TryGetValue(nodeId)
    if not charBreakDetailData then
        return false
    end
    for _, itemBundle in pairs(charBreakDetailData.requiredItem) do
        if Utils.getItemCount(itemBundle.id, true) < itemBundle.count then
            return false
        end
    end
    return true
end
function isCharTalentCostEnough(templateId, nodeId)
    local _, charGrowthData = Tables.charGrowthTable:TryGetValue(templateId)
    if not charGrowthData then
        return false
    end
    local _, talentNode = charGrowthData.talentNodeMap:TryGetValue(nodeId)
    if not talentNode then
        return false
    end
    for _, itemBundle in pairs(talentNode.requiredItem) do
        if Utils.getItemCount(itemBundle.id, true) < itemBundle.count then
            return false
        end
    end
    return true
end
function isSkillGroupLevelUpCostEnough(templateId, skillGroupId, skillLv)
    local skillLevelUpData = CharInfoUtils.getSkillTalentNodeBySkillId(templateId, skillGroupId, skillLv)
    if not skillLevelUpData then
        return false
    end
    if skillLevelUpData.goldCost > 0 then
        if Utils.getItemCount(UIConst.INVENTORY_MONEY_IDS[1], true) < skillLevelUpData.goldCost then
            return false
        end
    end
    for _, itemBundle in pairs(skillLevelUpData.itemBundle) do
        if Utils.getItemCount(itemBundle.id, true) < itemBundle.count then
            return false
        end
    end
    return true
end
function getCharInfoProfile(templateId)
    local profile = {}
    local charData = Tables.characterTable[templateId]
    if charData then
        profile = { profileVoice = charData.profileVoice, profileRecord = charData.profileRecord, }
    end
    return profile
end
function IsFullLockedTeam(dungeonId)
    local formationData
    local curDungeonId = dungeonId or GameInstance.dungeonManager.curDungeonId
    local _, subGameData = DataManager.subGameInstDataTable:TryGetValue(curDungeonId)
    if subGameData and not string.isEmpty(subGameData.teamConfigId) then
        formationData = CharInfoUtils.getLockedFormationData(subGameData.teamConfigId, false)
        if formationData and formationData.lockedTeamMemberCount == formationData.maxTeamMemberCount and not formationData.hasReplaceable then
            return true, formationData
        end
    end
    return false, formationData
end
function getLockedFormationData(teamConfigId, createClientCharInfo)
    if string.isEmpty(teamConfigId) then
        return nil
    end
    local hasValue
    local charTeamData
    hasValue, charTeamData = Tables.charTeamTable:TryGetValue(teamConfigId)
    if not hasValue then
        return nil
    end
    local shouldShowTrailTips = #charTeamData.presetCharList > 0
    if createClientCharInfo then
        for _, charPresetId in pairs(charTeamData.presetCharList) do
            GameInstance.player.charBag:CreateClientCharInfo(charPresetId, ScopeUtil.GetCurrentScope())
        end
    end
    local lockedTeamData = {}
    lockedTeamData.teamConfigId = teamConfigId
    lockedTeamData.maxTeamMemberCount = charTeamData.maxMemberCount
    local chars = {}
    for _, charPresetId in pairs(charTeamData.presetTeam) do
        local charPresetData
        hasValue, charPresetData = Tables.charPresetTable:TryGetValue(charPresetId)
        if hasValue then
            local charInfo = { charId = CS.Beyond.Gameplay.CharUtils.GetCharTemplateId(charPresetData.charId), charPresetId = charPresetId, isLocked = true, isTrail = true, isReplaceable = false, }
            if createClientCharInfo then
                local csCharInfo = CharInfoUtils.getPlayerCharInfoByPresetId(charPresetId)
                charInfo.charInstId = csCharInfo.instId
                charInfo.charId = csCharInfo.templateId
            end
            table.insert(chars, charInfo)
        end
        shouldShowTrailTips = false
    end
    local hasReplaceable = false
    for _, charId in pairs(charTeamData.requireCharTids) do
        charId = CS.Beyond.Gameplay.CharUtils.GetCharTemplateId(charId)
        local found = false
        for _, charInfo in ipairs(chars) do
            if charInfo.charId == charId then
                charInfo.isReplaceable = true
                found = true
                hasReplaceable = true
                break
            end
        end
        if not found then
            if createClientCharInfo then
                local foundCharInfo
                local trailCharInfos = GameInstance.player.charBag.clientCharInfos
                for _, trailCharInfo in cs_pairs(trailCharInfos) do
                    if trailCharInfo.templateId == charId then
                        foundCharInfo = trailCharInfo
                        break
                    end
                end
                if not foundCharInfo then
                    foundCharInfo = CharInfoUtils.getPlayerCharInfoByTemplateId(charId, GEnums.CharType.Default)
                end
                local charInfo = { charId = charId, charInstId = foundCharInfo.instId, isLocked = true, isTrail = foundCharInfo.charType == GEnums.CharType.Trial, isReplaceable = true, }
                table.insert(chars, charInfo)
            else
                local isTrail = false
                for _, charPresetId in pairs(charTeamData.presetCharList) do
                    local charPresetData
                    hasValue, charPresetData = Tables.charPresetTable:TryGetValue(charPresetId)
                    if hasValue and CS.Beyond.Gameplay.CharUtils.GetCharTemplateId(charPresetData.charId) == charId then
                        isTrail = true
                        break
                    end
                end
                local charInfo = { charId = charId, isLocked = true, isTrail = isTrail, isReplaceable = true, }
                table.insert(chars, charInfo)
            end
            hasReplaceable = true
        end
        shouldShowTrailTips = false
    end
    lockedTeamData.chars = chars
    lockedTeamData.lockedTeamMemberCount = #chars
    lockedTeamData.hasReplaceable = hasReplaceable
    lockedTeamData.shouldShowTrailTips = shouldShowTrailTips
    return lockedTeamData
end
function getLockedFormationCharTipsShow(charInfo)
    local isShowFixed = charInfo.isLocked == true and not charInfo.isReplaceable
    local isShowTrail = charInfo.isTrail and not isShowFixed
    return isShowFixed, isShowTrail
end
function getHpBase(charInfo)
    return getAttrBaseDefault(charInfo.instId, GEnums.AttributeType.MaxHp)
end
function getAtkBase(charInfo)
    return getAttrBaseDefault(charInfo.instId, GEnums.AttributeType.Atk)
end
function getAtkScalar(charInfo)
    local charInst = getPlayerCharInfoByInstId(charInfo.instId)
    local attributes = charInst.attributes
    local mainAttrScalar = attributes:GetAtkFinalScalarFromMainAttribute()
    local subAttrScalar = attributes:GetAtkFinalScalarFromSubAttribute()
    local mainAttrScalarShowInfo = AttributeUtils.generateAttributeShowInfo(GEnums.AttributeType.Atk, mainAttrScalar + subAttrScalar, { forceShowPercent = UIConst.ATTRIBUTE_GENERATE_FORCE_PERCENT.HAS_PERCENT, fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR, })
    return "+" .. mainAttrScalarShowInfo.showValue, mainAttrScalarShowInfo.attributeValue
end
function getDefBase(charInfo)
    return getAttrBaseDefault(charInfo.instId, GEnums.AttributeType.Def)
end
function getAttrBaseDefault(charInstId, attrType)
    local attrShowInfo = AttributeUtils.generateAttributeShowInfo(attrType, getCharBaseAttributes(charInstId)[attrType], { fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR })
    return attrShowInfo.showValue, attrShowInfo.attributeValue
end
function getHpDetailList(charInfo, finalValue)
    local detailList = {}
    local charInst = getPlayerCharInfoByInstId(charInfo.instId)
    local attributes = charInst.attributes
    local rawHp = attributes:GetRawValue(GEnums.AttributeType.MaxHp)
    local rawHpShowValue = AttributeUtils.generateAttributeShowInfo(GEnums.AttributeType.MaxHp, rawHp, { fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR }).showValue
    table.insert(detailList, { showName = Language.LUA_CHAR_INFO_FULL_ATTRIBUTE_HP_RAW, showValue = rawHpShowValue, })
    local hpByStr = attributes:GetHpBaseAddFromStrAttribute()
    local hpByStrShowValue = AttributeUtils.generateAttributeShowInfo(GEnums.AttributeType.MaxHp, hpByStr, { fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR }).showValue
    table.insert(detailList, { showName = Language.LUA_CHAR_INFO_FULL_ATTRIBUTE_HP_BY_STR, showValue = hpByStrShowValue, })
    local baseHp = attributes:GetBaseValue(GEnums.AttributeType.MaxHp, UIConst.CHAR_INFO_ATTRIBUTE_ALL_FILTER_MASK)
    local otherBaseHp = baseHp - rawHp - hpByStr
    if math.abs(otherBaseHp) < 0.001 then
        return detailList
    end
    return detailList
end
function getAtkBaseDetailList(charInfo, finalValue)
    local detailList = {}
    local charInst = getPlayerCharInfoByInstId(charInfo.instId)
    local attributes = charInst.attributes
    local baseAtkWeapon = 0
    local weaponInstId = charInst.weaponInstId
    local _, itemBundle = GameInstance.player.inventory:TryGetWeaponInst(Utils.getCurrentScope(), weaponInstId)
    local weaponInst = itemBundle.instData
    local weaponAttrDict = getWeaponShowAttributeDict(weaponInst.instId, weaponInst.weaponLv)
    if weaponAttrDict[GEnums.AttributeType.Atk] then
        for modifierType, attrInfo in pairs(weaponAttrDict[GEnums.AttributeType.Atk]) do
            if modifierType == GEnums.ModifierType.BaseAddition then
                baseAtkWeapon = attrInfo.attrValue
            end
        end
    end
    table.insert(detailList, { showName = Language.LUA_CHAR_INFO_FULL_ATTRIBUTE_ATK_WEAPON, showValue = AttributeUtils.generateAttributeShowInfo(GEnums.AttributeType.Atk, baseAtkWeapon, { fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR }).showValue })
    local baseAtkChar = attributes:GetBaseValue(GEnums.AttributeType.Atk, UIConst.CHAR_INFO_ATTRIBUTE_NONE_FILTER_MASK)
    table.insert(detailList, { showName = Language.LUA_CHAR_INFO_FULL_ATTRIBUTE_ATK_CHAR, showValue = AttributeUtils.generateAttributeShowInfo(GEnums.AttributeType.Atk, baseAtkChar, { fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR }).showValue })
    local baseAtk = attributes:GetBaseValue(GEnums.AttributeType.Atk, UIConst.CHAR_INFO_ATTRIBUTE_ALL_FILTER_MASK)
    local baseAtkOther = baseAtk - baseAtkWeapon - baseAtkChar
    if math.abs(baseAtkOther) < 0.001 then
        return detailList
    end
    local baseAtkOtherShowValue = AttributeUtils.generateAttributeShowInfo(GEnums.AttributeType.Atk, baseAtkOther, { fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR }).showValue
    table.insert(detailList, { showName = Language.LUA_CHAR_INFO_FULL_ATTRIBUTE_OTHER, showValue = baseAtkOtherShowValue, })
    return detailList
end
function getAtkScalarDetailList(charInfo, finalValue)
    local detailList = {}
    local charInst = getPlayerCharInfoByInstId(charInfo.instId)
    local attributes = charInst.attributes
    local charCfg = Tables.characterTable[charInfo.templateId]
    local mainAttrShowCfg = AttributeUtils.getAttributeShowCfg(charCfg.mainAttrType)
    local subAttrShowCfg = AttributeUtils.getAttributeShowCfg(charCfg.subAttrType)
    local mainAttrScalar = attributes:GetAtkFinalScalarFromMainAttribute()
    local subAttrScalar = attributes:GetAtkFinalScalarFromSubAttribute()
    local mainAttrScalarShowInfo = AttributeUtils.generateAttributeShowInfo(GEnums.AttributeType.Atk, mainAttrScalar, { forceShowPercent = UIConst.ATTRIBUTE_GENERATE_FORCE_PERCENT.HAS_PERCENT, fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR })
    local subAttrScalarShowInfo = AttributeUtils.generateAttributeShowInfo(GEnums.AttributeType.Atk, subAttrScalar, { forceShowPercent = UIConst.ATTRIBUTE_GENERATE_FORCE_PERCENT.HAS_PERCENT, fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR })
    table.insert(detailList, { showName = string.format(Language.LUA_CHAR_INFO_FULL_ATTRIBUTE_ATK_SCALAR_FORMAT, mainAttrShowCfg.name), showValue = "+" .. mainAttrScalarShowInfo.showValue, })
    table.insert(detailList, { showName = string.format(Language.LUA_CHAR_INFO_FULL_ATTRIBUTE_ATK_SCALAR_FORMAT, subAttrShowCfg.name), showValue = "+" .. subAttrScalarShowInfo.showValue, })
    return detailList
end
function getDefDetailList(charInfo, finalAttr)
    local detailList = {}
    local charInst = getPlayerCharInfoByInstId(charInfo.instId)
    local attributes = charInst.attributes
    local equipDef = attributes:GetBaseValue(GEnums.AttributeType.Def, UIConst.CHAR_INFO_ATTRIBUTE_EQUIP_FILTER_MASK)
    local equipDefShowValue = AttributeUtils.generateAttributeShowInfo(GEnums.AttributeType.Def, equipDef, { fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR }).showValue
    table.insert(detailList, { showName = Language.LUA_CHAR_INFO_FULL_ATTRIBUTE_DEF_BASE, showValue = equipDefShowValue, })
    local baseDef = attributes:GetBaseValue(GEnums.AttributeType.Def, UIConst.CHAR_INFO_ATTRIBUTE_ALL_FILTER_MASK)
    local extraBaseDef = baseDef - equipDef
    if math.abs(extraBaseDef) < 0.001 then
        return detailList
    end
    local extraBaseDefShowValue = AttributeUtils.generateAttributeShowInfo(GEnums.AttributeType.Def, extraBaseDef, { fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR }).showValue
    table.insert(detailList, { showName = Language.LUA_CHAR_INFO_FULL_ATTRIBUTE_DEF_OTHER, showValue = extraBaseDefShowValue, })
    return detailList
end
function getHpExtra(charInfo)
    return getAttrExtraDefault(charInfo.instId, GEnums.AttributeType.MaxHp)
end
function getAtkExtra(charInfo, finalAttrInfo)
    local charInst = getPlayerCharInfoByInstId(charInfo.instId)
    local attributes = charInst.attributes
    local baseAtk = attributes:GetBaseValue(GEnums.AttributeType.Atk, UIConst.CHAR_INFO_ATTRIBUTE_ALL_FILTER_MASK)
    local scalar = attributes:GetAtkFinalScalarFromMainAttribute() + attributes:GetAtkFinalScalarFromSubAttribute()
    local finalValue = finalAttrInfo.attributeValue
    local modifierValue = baseAtk * (1 + scalar)
    local attrShowInfo = AttributeUtils.generateAttributeShowInfo(GEnums.AttributeType.Atk, finalValue - modifierValue, { fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR })
    return attrShowInfo.showValue, finalValue - modifierValue
end
function getDefExtra(charInfo)
    return getAttrExtraDefault(charInfo.instId, GEnums.AttributeType.Def)
end
function getAttrExtraDefault(charInstId, attrType)
    local finalAttr = getCharFinalAttributes(charInstId)[attrType]
    local baseAttr = getCharBaseAttributes(charInstId)[attrType]
    local attrShowInfo = AttributeUtils.generateAttributeShowInfo(attrType, finalAttr - baseAttr, { fromSpecificSystem = UIConst.CHAR_INFO_ATTRIBUTE_SPECIFIC_SYSTEM.CHAR_FULL_ATTR })
    return attrShowInfo.showValue, finalAttr - baseAttr
end