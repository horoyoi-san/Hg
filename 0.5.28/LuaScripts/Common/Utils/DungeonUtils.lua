function isDungeonUnlock(dungeonId)
    return GameInstance.dungeonManager:IsDungeonUnlocked(dungeonId)
end
function diffActionByConditionId(conditionId)
    local conditionCfg = Tables.gameMechanicConditionTable[conditionId]
    local conditionType = conditionCfg.conditionType
    local param = conditionCfg.parameter[0]
    if conditionType == GEnums.ConditionType.CheckPassGameMechanicsId then
        local preDungeonId = param.valueStringList[0]
        local dungeonTypeCfg = Tables.dungeonTypeTable[Tables.gameMechanicTable[preDungeonId].gameCategory]
        local _, instId = GameInstance.player.mapManager:GetMapMarkInstId(dungeonTypeCfg.mapMarkType, Tables.dungeonTable[preDungeonId].dungeonSeriesId)
        MapUtils.openMap(instId)
    elseif conditionType == GEnums.ConditionType.CheckSceneGrade then
        local levelId = param.valueStringList[0]
        MapUtils.openMap(nil, levelId)
    elseif conditionType == GEnums.ConditionType.QuestStateEqual then
        local questId = param.valueStringList[0]
        local missionId = GameInstance.player.mission:GetMissionIdByQuestId(questId)
        PhaseManager:OpenPhase(PhaseId.Mission, { autoSelect = missionId, useBlackMask = true })
    elseif conditionType == GEnums.ConditionType.MissionStateEqual then
        local missionId = param.valueStringList[0]
        PhaseManager:OpenPhase(PhaseId.Mission, { autoSelect = missionId, useBlackMask = true })
    else
        Notify(MessageConst.SHOW_TOAST, "Error")
    end
end
function getConditionCanJump(dungeonId, conditionId)
    local conditionCfg = Tables.gameMechanicConditionTable[conditionId]
    local conditionType = conditionCfg.conditionType
    local param = conditionCfg.parameter[0]
    if conditionType == GEnums.ConditionType.CheckPassGameMechanicsId then
        local preDungeonId = param.valueStringList[0]
        local dungeonCfg = Tables.dungeonTable[dungeonId]
        local preDungeonCfg = Tables.dungeonTable[preDungeonId]
        return dungeonCfg.dungeonSeriesId ~= preDungeonCfg.dungeonSeriesId
    end
    return true
end
function getUncompletedConditionIds(dungeonId)
    local uncompletedConditionIds = {}
    local _, gameUnlockCondition = GameInstance.player.subGameSys:TryGetSubGameUnlockCondition(dungeonId)
    for conditionId, completed in pairs(gameUnlockCondition.unlockConditionFlags) do
        if not completed then
            table.insert(uncompletedConditionIds, conditionId)
        end
    end
    return uncompletedConditionIds
end
function getEntryLocation(levelId, ignoreDomain)
    if string.isEmpty(levelId) then
        return ""
    end
    local domainId = DataManager.levelBasicInfoTable:get_Item(levelId).domainName
    local levelName = Tables.levelDescTable[levelId].showName
    if ignoreDomain then
        return levelName
    else
        local succ, domainDataCfg = Tables.domainDataTable:TryGetValue(domainId)
        if succ then
            return domainDataCfg.domainName .. "-" .. levelName
        else
            return levelName
        end
    end
end
function getListByStr(str)
    return string.isEmpty(str) and {} or string.split(str, "\n")
end
function isDungeonTrain(dungeonId)
    local gameMechanicCfg = Tables.gameMechanicTable[dungeonId]
    return gameMechanicCfg.gameCategory == "dungeon_train"
end
function onClickExitDungeonBtn()
    local dungeonId = GameInstance.dungeonManager.curDungeonId
    if string.isEmpty(dungeonId) then
        return
    end
    local gameMechanicCfg = Tables.gameMechanicTable[dungeonId]
    local dungeonTypeCfg = Tables.dungeonTypeTable[gameMechanicCfg.gameCategory]
    local confirmHint = dungeonTypeCfg.stopConfirmText
    if gameMechanicCfg.gameCategory == "dungeon_char" and GameInstance.dungeonManager:IsDungeonPassed(dungeonId) then
        confirmHint = Language.LUA_DUNGEON_CHAR_STOP_CONFIRM_AFTER_SETTLEMENT
    end
    Notify(MessageConst.SHOW_POP_UP, {
        content = confirmHint,
        onConfirm = function()
            GameInstance.dungeonManager:LeaveDungeon()
        end,
        freezeWorld = true,
        freezeServer = true,
    })
end
function isDungeonHasFeatureInfo(dungeonId)
    if string.isEmpty(dungeonId) then
        return false
    end
    local dungeonCfg = Tables.dungeonTable[dungeonId]
    return not string.isEmpty(dungeonCfg.featureDesc)
end