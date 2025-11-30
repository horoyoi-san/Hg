local WikiUtils = {}
function WikiUtils.isWikiEntryUnread(wikiEntryId)
    return GameInstance.player.wikiSystem:GetWikiEntryState(wikiEntryId) == CS.Beyond.Gameplay.WikiSystem.EWikiEntryState.Unread
end
function WikiUtils.canShowWikiEntry(itemId)
    local wikiEntryId = WikiUtils.getWikiEntryIdFromItemId(itemId)
    if wikiEntryId and GameInstance.player.wikiSystem:GetWikiEntryState(wikiEntryId) ~= CS.Beyond.Gameplay.WikiSystem.EWikiEntryState.Locked then
        return true
    end
    return false
end
function WikiUtils.getWikiEntryIdFromItemId(itemId)
    if string.isEmpty(itemId) then
        return nil
    end
    local _, wikiEntryId = Tables.wikiEntryDataReverseTable:TryGetValue(itemId)
    return wikiEntryId
end
function WikiUtils.getWikiEntryShowDataFromItemId(id)
    local wikiEntryId = WikiUtils.getWikiEntryIdFromItemId(id)
    if not wikiEntryId then
        return
    end
    local _, wikiEntryData = Tables.wikiEntryDataTable:TryGetValue(wikiEntryId)
    if wikiEntryData then
        for categoryType, wikiGroupDataList in pairs(Tables.wikiGroupTable) do
            for _, wikiGroupData in pairs(wikiGroupDataList.list) do
                if wikiGroupData.groupId == wikiEntryData.groupId then
                    local wikiEntryShowData = { wikiCategoryType = categoryType, wikiGroupData = wikiGroupData, wikiEntryData = wikiEntryData }
                    return wikiEntryShowData
                end
            end
        end
    end
end
function WikiUtils.getWikiGroupShowDataList(wikiCategoryType, targetWikiEntryId, includeLocked)
    local foundWikiEntryShowData = nil
    local wikiSystem = GameInstance.player.wikiSystem
    local _, wikiGroupDataList = Tables.wikiGroupTable:TryGetValue(wikiCategoryType)
    if wikiGroupDataList then
        local wikiGroupShowDataList = {}
        for _, wikiGroupData in pairs(wikiGroupDataList.list) do
            local _, wikiEntryList = Tables.wikiEntryTable:TryGetValue(wikiGroupData.groupId)
            if wikiEntryList then
                local wikiEntryShowDataList = {}
                for _, wikiEntryId in pairs(wikiEntryList.list) do
                    local isUnlocked = wikiSystem:GetWikiEntryState(wikiEntryId) ~= CS.Beyond.Gameplay.WikiSystem.EWikiEntryState.Locked
                    if includeLocked or isUnlocked then
                        local _, wikiEntryData = Tables.wikiEntryDataTable:TryGetValue(wikiEntryId)
                        if wikiEntryData then
                            local wikiEntryShowData = { wikiCategoryType = wikiCategoryType, wikiGroupData = wikiGroupData, wikiEntryData = wikiEntryData, isUnlocked = isUnlocked, }
                            table.insert(wikiEntryShowDataList, wikiEntryShowData)
                            if targetWikiEntryId == wikiEntryId then
                                foundWikiEntryShowData = wikiEntryShowData
                            end
                        end
                    end
                end
                if #wikiEntryShowDataList > 0 then
                    local wikiGroupShowData = { wikiCategoryType = wikiCategoryType, wikiGroupData = wikiGroupData, wikiEntryShowDataList = wikiEntryShowDataList }
                    table.insert(wikiGroupShowDataList, wikiGroupShowData)
                end
            end
        end
        return wikiGroupShowDataList, foundWikiEntryShowData
    end
end
function WikiUtils.isWikiCategoryUnlocked(wikiCategoryType)
    local wikiSystem = GameInstance.player.wikiSystem
    local _, wikiGroupDataList = Tables.wikiGroupTable:TryGetValue(wikiCategoryType)
    if wikiGroupDataList then
        for _, wikiGroupData in pairs(wikiGroupDataList.list) do
            local _, wikiEntryList = Tables.wikiEntryTable:TryGetValue(wikiGroupData.groupId)
            if wikiEntryList then
                for _, wikiEntryId in pairs(wikiEntryList.list) do
                    if wikiSystem:GetWikiEntryState(wikiEntryId) ~= CS.Beyond.Gameplay.WikiSystem.EWikiEntryState.Locked then
                        return true
                    end
                end
            end
        end
    end
    return false
end
function WikiUtils.getWeaponSkillShowDataList(weaponTemplateId)
    local wikiSystem = GameInstance.player.wikiSystem
    local skillIdToShowData = {}
    local currentShowDataList = {}
    local commonShowDataList = {}
    local weaponBasicData = Tables.weaponBasicTable[weaponTemplateId]
    for _, skillId in pairs(weaponBasicData.weaponSkillList) do
        local showData = { skillId = skillId, weaponDataList = { { id = weaponTemplateId, isUnlocked = true, } }, isCurrentWeaponSkill = true, isUnlocked = true, }
        skillIdToShowData[skillId] = showData
        table.insert(currentShowDataList, showData)
    end
    local _, wikiGroupDataList = Tables.wikiGroupTable:TryGetValue(WikiConst.EWikiCategoryType.Weapon)
    if wikiGroupDataList then
        for _, wikiGroupData in pairs(wikiGroupDataList.list) do
            local _, wikiEntryList = Tables.wikiEntryTable:TryGetValue(wikiGroupData.groupId)
            if wikiEntryList then
                for _, wikiEntryId in pairs(wikiEntryList.list) do
                    local _, wikiEntryData = Tables.wikiEntryDataTable:TryGetValue(wikiEntryId)
                    if wikiEntryData and wikiEntryData.refItemId ~= weaponTemplateId then
                        local isWeaponUnlocked = wikiSystem:GetWikiEntryState(wikiEntryId) ~= CS.Beyond.Gameplay.WikiSystem.EWikiEntryState.Locked
                        weaponBasicData = Tables.weaponBasicTable[wikiEntryData.refItemId]
                        for _, skillId in pairs(weaponBasicData.weaponSkillList) do
                            local showData = skillIdToShowData[skillId]
                            if not showData then
                                showData = { skillId = skillId, weaponDataList = { { id = wikiEntryData.refItemId, isUnlocked = isWeaponUnlocked, } }, isUnlocked = true }
                                skillIdToShowData[skillId] = showData
                                table.insert(commonShowDataList, showData)
                            else
                                table.insert(showData.weaponDataList, { id = wikiEntryData.refItemId, isUnlocked = isWeaponUnlocked, })
                            end
                        end
                    end
                end
            end
        end
    end
    local sortFunc = Utils.genSortFunction({ "skillId" }, true)
    table.sort(commonShowDataList, sortFunc)
    return lume.concat(currentShowDataList, commonShowDataList)
end
local historySearchKeywords = {}
function WikiUtils.getHistorySearchKeywords()
    return historySearchKeywords
end
function WikiUtils.addHistorySearchKeyword(keyword)
    if lume.find(historySearchKeywords, keyword) then
        return
    end
    if #historySearchKeywords >= WikiConst.MAX_HISTORY_KEYWORD_COUNT then
        table.remove(historySearchKeywords, 1)
    end
    table.insert(historySearchKeywords, keyword)
end
_G.WikiUtils = WikiUtils
return WikiUtils