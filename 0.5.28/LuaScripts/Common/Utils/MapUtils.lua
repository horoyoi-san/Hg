function openMap(instId, levelId)
    local data = {}
    levelId = string.isEmpty(levelId) and GameInstance.world.curLevelId or levelId
    if not string.isEmpty(instId) then
        levelId = GameInstance.player.mapManager:GetMarkInstRuntimeDataLevelId(instId)
    end
    data.instId = instId
    data.levelId = levelId
    PhaseManager:GoToPhase(PhaseId.Map, data)
end
function openMapByMissionId(missionId, trackDataIdx)
    trackDataIdx = trackDataIdx or 0
    local mapManager = GameInstance.player.mapManager
    local instId = mapManager:GetTrackingMissionMarkInstId(missionId, trackDataIdx)
    openMap(instId)
end
function checkIsValidMarkInstId(instId, ignoreInvisible)
    if instId == nil then
        return false
    end
    local success, markData = GameInstance.player.mapManager:GetMarkInstRuntimeData(instId)
    if not success then
        return false
    end
    if not checkIsValidLevelId(markData.levelId) then
        return false
    end
    if not markData.isVisible and not ignoreInvisible then
        return false
    end
    return true
end
function checkIsValidLevelId(levelId)
    if levelId == nil then
        return false
    end
    if not GameInstance.player.mapManager:IsLevelUnlocked(levelId) then
        return false
    end
    return true
end
function openMapAndSetMarkVisibleIfNecessary(instId)
    GameInstance.player.mapManager:SetStaticMarkVisibleStateWithCallback(instId, true, function()
        openMap(instId)
    end)
end
function switchFromLevelMapToRegionMap(levelId, domainId)
    local topPhase = PhaseManager:GetTopPhaseId()
    if topPhase ~= PhaseId.Map then
        return
    end
    local args
    if levelId ~= nil or domainId ~= nil then
        args = { levelId = levelId, domainId = domainId, }
    end
    PhaseManager:OpenPhase(PhaseId.RegionMap, args, function()
        PhaseManager:ExitPhaseFast(PhaseId.Map)
    end)
end
function switchFromRegionMapToLevelMap(instId, levelId)
    local topPhase = PhaseManager:GetTopPhaseId()
    if topPhase ~= PhaseId.RegionMap then
        return
    end
    local args
    if instId ~= nil or levelId ~= nil then
        args = { instId = instId, levelId = levelId, needTransit = true, }
    end
    PhaseManager:OpenPhaseFast(PhaseId.Map, args)
    PhaseManager:ExitPhaseFast(PhaseId.RegionMap)
end
function closeMapRelatedPhase()
    local topPhase = PhaseManager:GetTopPhaseId()
    if PhaseManager:IsOpen(PhaseId.Map) then
        if topPhase == PhaseId.Map then
            PhaseManager:PopPhase(PhaseId.Map)
        else
            PhaseManager:ExitPhaseFast(PhaseId.Map)
        end
    end
    if PhaseManager:IsOpen(PhaseId.RegionMap) then
        if topPhase == PhaseId.RegionMap then
            PhaseManager:PopPhase(PhaseId.RegionMap)
        else
            PhaseManager:ExitPhaseFast(PhaseId.RegionMap)
        end
    end
end