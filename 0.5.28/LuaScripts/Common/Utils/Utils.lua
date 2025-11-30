local localIndex = {}
local locals = {}
setmetatable(locals, {
    ["__index"] = localIndex,
    ["__newindex"] = function(t, k, v)
        localIndex[k] = v
    end,
    ["__mode"] = "kv"
})
setmetatable(localIndex, { ["__index"] = setmetatable({}, { ["__index"] = _G }), ["__mode"] = "kv" })
localIndex["__locals"] = locals
function printDoString(str)
    local logs = {}
    local localPrint = function(...)
        print(...)
        logs = lume.concat(logs, { ..., "\n" })
    end
    local localError = function(...)
        logger.error(...)
        logs = lume.concat(logs, { ..., "\n" })
    end
    if not lume.find({ "\r\n", "\n", "\r" }, str) then
        localPrint("[Run Script]>>>>---- " .. str .. "---- <<<<")
        local hasPrefix = (#str > 1 and str:sub(1, 1) == "=")
        if hasPrefix then
            str = string.sub(str, 2)
        end
        local retStr = "return " .. str
        local retFunc, errMsg = loadstring(retStr)
        if not retFunc and not hasPrefix then
            retFunc, errMsg = loadstring(str)
        end
        if not retFunc then
            localError(errMsg)
        else
            retFunc = setfenv(retFunc, locals)
            local function collectLocals()
                if debug.getinfo(2, "f").func ~= retFunc then
                    return
                end
                local __debug_idx = 1
                while true do
                    local name, value = debug.getlocal(2, __debug_idx)
                    if not name then
                        break
                    end
                    rawset(locals, name, value)
                    __debug_idx = __debug_idx + 1
                end
            end
            local function traceback(msg)
                msg = debug.traceback(msg, 2)
                localError(msg)
                return msg
            end
            local function getReturnValue(status, ...)
                local retNum = select("#", ...)
                return status, retNum, { ... }
            end
            local status, retNum, retVals = getReturnValue(xpcall(retFunc, traceback))
            if status and retNum > 0 then
                local outputStr = ""
                for i = 1, retNum do
                    outputStr = outputStr .. inspect(retVals[i], { ['depth'] = 3 })
                    if i < retNum then
                        outputStr = outputStr .. ", "
                    end
                end
                localPrint(outputStr)
                return logs
            end
        end
        localPrint("> ")
    else
        localPrint("> ")
    end
    return logs
end
function bindLuaRef(item)
    if type(item) ~= "table" then
        item = { gameObject = item.gameObject, transform = item.transform, }
    end
    local luaRef = item.gameObject:GetComponent("LuaReference")
    if luaRef then
        luaRef:BindToLua(item)
    end
    return item
end
function wrapLuaNode(item)
    local luaWidget = item.transform:GetComponent("LuaUIWidget")
    local wrapResult
    if luaWidget then
        wrapResult = UIWidgetManager:Wrap(item)
    else
        wrapResult = Utils.bindLuaRef(item)
        if wrapResult then
            UIUtils.initLuaCustomConfig(wrapResult)
        end
    end
    return wrapResult
end
function genSortFunction(keyList, isIncremental)
    return function(a, b)
        for _, key in ipairs(keyList) do
            local valueA = a[key]
            local valueB = b[key]
            if type(valueA) == "function" then
                valueA = valueA(a)
            end
            if type(valueB) == "function" then
                valueB = valueB(b)
            end
            if valueA ~= valueB then
                if valueA == nil or valueB == nil then
                    if isIncremental then
                        return valueA == nil
                    else
                        return valueA ~= nil
                    end
                end
                if isIncremental then
                    return valueA < valueB
                else
                    return valueA > valueB
                end
            end
        end
        return false
    end
end
function genSortFunctionWithIgnore(keyList, isIncremental, ignoreKeyList)
    return function(a, b)
        for _, key in ipairs(keyList) do
            local valueA = a[key]
            local valueB = b[key]
            if type(valueA) == "function" then
                valueA = valueA(a)
            end
            if type(valueB) == "function" then
                valueB = valueB(b)
            end
            if valueA ~= valueB then
                if valueA == nil or valueB == nil then
                    if isIncremental or lume.find(ignoreKeyList, key) then
                        return valueA == nil
                    else
                        return valueA ~= nil
                    end
                end
                if isIncremental or lume.find(ignoreKeyList, key) then
                    return valueA < valueB
                else
                    return valueA > valueB
                end
            end
        end
        return false
    end
end
function isInclude(table, value)
    for index, v in pairs(table) do
        if v == value then
            return index
        end
    end
    return nil
end
function transferToCameraCoordinate(v)
    local camera = CameraManager.mainCamera
    local forward = camera.transform.forward
    forward.y = 0
    forward = forward.normalized
    local left = camera.transform.right
    left.y = 0
    left = left.normalized
    return v.x * left + v.y * Vector3.up + v.z * forward
end
function tobool(v)
    if type(v) == "number" then
        return not (v == 0)
    elseif type(v) == "string" then
        return not (string.lower(v) == "false")
    end
    return false
end
function syncFreeLookCamWithMain(ctrl, setPitch)
    local angles = GameInstance.cameraManager.mainCamera.transform.rotation.eulerAngles;
    local pitch = angles.x;
    if pitch > 180 then
        pitch = pitch - 360
    end
    local horizontalValue = angles.y;
    if setPitch then
        ctrl:SetCameraVerticalDegrees(pitch, false)
    end
    ctrl:SetCameraHorizontalAngle(horizontalValue, false)
    ctrl:ForceFlush()
end
function getUnlockedCustomObtainWay(itemId)
    local unlockedObtainWayList = {}
    local hasUnlockedObtainWay = false
    local itemCfg = Tables.itemTable:GetValue(itemId)
    for _, obtainWayId in pairs(itemCfg.obtainWayIds) do
        local _, obtainWayCfg = Tables.systemJumpTable:TryGetValue(obtainWayId)
        if obtainWayCfg then
            local isUnlock = (not obtainWayCfg.bindSystem) or isSystemUnlocked(obtainWayCfg.bindSystem)
            if isUnlock then
                hasUnlockedObtainWay = true
                table.insert(unlockedObtainWayList, obtainWayCfg)
            end
        end
    end
    return hasUnlockedObtainWay, unlockedObtainWayList
end
function getItemValuableDepotType(itemId)
    local itemData = Tables.itemTable[itemId]
    return itemData.valuableTabType
end
function isItemInstType(itemId)
    return GameInstance.player.inventory:IsInstItem(itemId)
end
function getItemCount(itemId, forceIncludeCurDepot, allDepot)
    if string.isEmpty(itemId) then
        return 0, 0, 0
    end
    local inventory = GameInstance.player.inventory
    local itemData = Tables.itemTable[itemId]
    if inventory:IsMoneyType(itemData.type) then
        return inventory:GetItemCountInWallet(itemId)
    end
    local valuableDepotType = itemData.valuableTabType
    local isValuableItem = valuableDepotType ~= GEnums.ItemValuableDepotType.Factory
    local bagCount, depotCount, walletCount = 0, 0, 0
    if isValuableItem then
        depotCount = inventory:GetItemCountInDepot(Utils.getCurrentScope(), Utils.getCurrentChapterId(), itemId)
    else
        local isMoney = inventory:IsMoneyType(itemData.type)
        if isMoney then
            walletCount = inventory:GetItemCountInWallet(itemId)
        else
            bagCount = inventory:GetItemCountInBag(Utils.getCurrentScope(), itemId)
            if forceIncludeCurDepot or isInSafeZone() then
                if allDepot or itemData.showAllDepotCount then
                    depotCount = inventory:GetItemCountInAllFacDepot(Utils.getCurrentScope(), itemId)
                else
                    depotCount = inventory:GetItemCountInDepot(Utils.getCurrentScope(), Utils.getCurrentChapterId(), itemId)
                end
            end
        end
    end
    local count = depotCount + bagCount + walletCount
    return count, bagCount, depotCount
end
function getBagItemCount(itemId)
    local inventory = GameInstance.player.inventory
    local bagCount = inventory:GetItemCountInBag(Utils.getCurrentScope(), itemId)
    return bagCount
end
function getDepotItemCount(itemId, scope, domainId)
    if string.isEmpty(itemId) then
        return 0
    end
    scope = scope or Utils.getCurrentScope()
    local chapterId = domainId and ScopeUtil.ChapterIdStr2Int(domainId) or Utils.getCurrentChapterId()
    return GameInstance.player.inventory:GetItemCountInDepot(scope, chapterId, itemId)
end
function getAllFacDepotItemCount(itemId, scope)
    if string.isEmpty(itemId) then
        return 0
    end
    scope = scope or Utils.getCurrentScope()
    return GameInstance.player.inventory:GetItemCountInAllFacDepot(scope, itemId)
end
function getBagItemCount(itemId)
    if string.isEmpty(itemId) then
        return 0
    end
    return GameInstance.player.inventory:GetItemCountInBag(Utils.getCurrentScope(), itemId)
end
function isInFactoryMode()
    return GameInstance.world.inFactoryMode
end
function isInSafeZone()
    if isInFacMainRegion() then
        return true
    end
    return GameInstance.playerController.isInSaveZone and not isInFight()
end
function isInFacMainRegionAndGetIndex()
    local inMainRegion, panel = GameInstance.remoteFactoryManager:IsPlayerPositionInMainRegionAndGetIndex()
    local panelIndex = -1
    if inMainRegion and panel then
        panelIndex = panel.index
    end
    return inMainRegion, panelIndex
end
function isInFacMainRegion()
    return GameInstance.remoteFactoryManager:IsPlayerPositionInMainRegion()
end
function stringJsonToTable(jsonString)
    local value = Json.decode(jsonString)
    return value
end
function enableCameraDOF(data)
    CS.Beyond.Gameplay.View.CameraUtils.EnableDOF(data)
end
function disableCameraDOF()
    CS.Beyond.Gameplay.View.CameraUtils.DisableDOF()
end
function isSystemUnlocked(t)
    if not t or t == GEnums.UnlockSystemType.None then
        return true
    end
    return GameInstance.player.systemUnlockManager:IsSystemUnlockByType(t)
end
function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end
function timestampToDate(timestamp)
    local date = os.date("!*t", timestamp + Utils.getServerTimeZoneOffsetSeconds())
    return string.format("%02d/%02d", date.month, date.day)
end
function timestampToDateYMDHM(timestamp)
    local date = os.date("!*t", timestamp + Utils.getServerTimeZoneOffsetSeconds())
    return string.format("%04d/%02d/%02d %02d:%02d", date.year, date.month, date.day, date.hour, date.min)
end
function triggerVoice(triggerKey, speakerId)
    if not speakerId then
        speakerId = GameInstance.player.squadManager:GetLeaderId()
    end
    VoiceManager:Response(triggerKey, nil, speakerId, GEnums.VoSpeakerType.Characters)
end
function stopDefaultChannelVoice()
    VoiceManager:StopVoiceOnEntity(nil)
end
function checkCGCanSkip(cgId)
    local res, data = DataManager.cgConfig.data:TryGetValue(cgId)
    if not res then
        return false
    end
    local skipType = data.skipType
    local skipTypeInt = skipType:ToInt()
    if skipTypeInt == CS.Beyond.Gameplay.CutsceneSkipType.NoneSkip:ToInt() then
        return false
    elseif skipTypeInt == CS.Beyond.Gameplay.CutsceneSkipType.CanSkip:ToInt() then
        return true
    else
        return GameInstance.player.cinematic:CheckFMVWatched(cgId)
    end
end
function checkCinematicCanSkip(data)
    local skipType = data.skipType
    local key = data.cutsceneName
    local skipTypeInt = skipType:ToInt()
    if skipTypeInt == CS.Beyond.Gameplay.CutsceneSkipType.NoneSkip:ToInt() then
        return false
    elseif skipTypeInt == CS.Beyond.Gameplay.CutsceneSkipType.CanSkip:ToInt() then
        return true
    else
        return GameInstance.player.cinematic:CheckTimelineWatched(key)
    end
end
SkillUtil = CS.Beyond.Gameplay.SkillUtil
function isGameSystemUnlocked(systemId)
    if string.isEmpty(systemId) then
        return true
    end
    local success, sysData = Tables.gameSystemConfigTable:TryGetValue(systemId)
    if success and sysData.unlockSystemType ~= GEnums.UnlockSystemType.None then
        return isSystemUnlocked(sysData.unlockSystemType)
    end
    return true
end
function isInFight()
    return GameInstance.curPlayerState == Const.PlayerState.InFight
end
function isInThrowMode()
    return GameInstance.world.battle.inThrowMode
end
function isInNarrative()
    return GameInstance.world.inNarrative
end
function isRadioPlaying()
    local show, _ = UIManager:IsShow(PanelId.Radio)
    return show
end
function getCurrentScope()
    if UNITY_EDITOR then
        local callerInfo = debug.getinfo(2, "Sl")
        return CS.Beyond.Gameplay.Scope.Create(ScopeUtil.GetCurrentScope(), CS.Beyond.Gameplay.Scope.CreateReason.Query, callerInfo.name, callerInfo.source, callerInfo.currentline)
    else
        return CS.Beyond.Gameplay.Scope.Create(ScopeUtil.GetCurrentScope())
    end
end
function getCurrentChapterId()
    return ScopeUtil.GetCurrentChapterId()
end
function isInMainScope()
    return ScopeUtil.IsMainScope()
end
function isInRpgDungeon()
    return ScopeUtil.IsPlayerInRpgDungeon()
end
function isInBlackbox()
    return ScopeUtil.IsPlayerInBlackbox()
end
function isInDungeon()
    return GameInstance.dungeonManager.inDungeon
end
function isInDungeonFactory()
    local dungeonId = GameInstance.dungeonManager.curDungeonId
    local success, dungeonInfo = Tables.gameMechanicTable:TryGetValue(dungeonId or "")
    if success then
        return dungeonInfo.gameCategory == Tables.dungeonConst.dungeonFactoryCategory
    end
    return false
end
function isInRacingDungeon()
    return GameInstance.player.racingDungeonSystem.isInRacingDungeon
end
function isDepotManualInOutLocked()
    local bData = GameInstance.world.curLevel.levelData.blackbox
    if not bData then
        return false
    end
    return bData.inventory.depotManualInOutLocked
end
function isCurrentMapHasFactoryGrid()
    local mapId = GameInstance.world.curMapIdStr
    local regionMap = GameInstance.remoteFactoryManager:GetVoxelSpaceQuery(mapId)
    return regionMap ~= nil
end
function isSwitchModeDisabled()
    if GameInstance.player.forbidSystem:IsForbidden(ForbidType.ForbidFactoryMode) then
        return true
    end
    if GameInstance.player.forbidSystem:IsForbidden(ForbidType.DisableSwitchMode) then
        return true
    end
    if not isCurrentMapHasFactoryGrid() then
        return true
    end
    return false
end
function shouldShowSwitchModeBtn()
    if GameInstance.player.forbidSystem:IsForbidden(ForbidType.DisableSwitchMode) then
        return false
    end
    if not isCurrentMapHasFactoryGrid() then
        return false
    end
    return true
end
function getPlayerName()
    local playerInfoSystem = GameInstance.player.playerInfoSystem
    return playerInfoSystem.playerName
end
function getPlayerGender()
    local playerInfoSystem = GameInstance.player.playerInfoSystem
    return playerInfoSystem.gender
end
function csList2Table(list)
    local t = {}
    for _, v in pairs(list) do
        t[v] = true
    end
    return t
end
function teleportToPosition(sceneId, position, rotation)
    if string.isEmpty(sceneId) or position == nil or rotation == nil then
        return
    end
    if Utils.isCurSquadAllDead() then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_GAME_MODE_FORBID_FACTORY_WATCH)
        return
    end
    GameAction.TeleportToPosition(sceneId, GEnums.TeleportReason.Map, position, rotation)
end
function teleportToEntity(sceneId, targetLogicId)
    if string.isEmpty(sceneId) or targetLogicId == nil then
        return
    end
    if Utils.isCurSquadAllDead() then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_GAME_MODE_FORBID_FACTORY_WATCH)
        return
    end
    GameAction.TeleportToEntity(GEnums.TeleportReason.Map, sceneId, targetLogicId)
end
function teleportToEntityWithCallback(sceneId, targetLogicId, callback)
    if string.isEmpty(sceneId) or targetLogicId == nil then
        return
    end
    if Utils.isCurSquadAllDead() then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_GAME_MODE_FORBID_FACTORY_WATCH)
        return
    end
    GameAction.TeleportToEntityWithCallback(GEnums.TeleportReason.Map, sceneId, targetLogicId, callback)
end
function getCurDomainId()
    return ScopeUtil.GetCurrentChapterIdAsStr()
end
function getCurDomainName()
    return getDomainName(getCurDomainId())
end
function getDomainName(domainId)
    local succ, data = Tables.domainDataTable:TryGetValue(domainId)
    if succ then
        return data.domainName
    else
        logger.error("No Domain Data", domainId)
        return ""
    end
end
function isInSettlementDefenseDefending()
    local towerDefenseGame = GameInstance.player.towerDefenseSystem.towerDefenseGame
    return towerDefenseGame ~= nil and towerDefenseGame.phase == CS.Beyond.Gameplay.Core.TowerDefenseGame.Phase.Defending
end
function isInSettlementDefense()
    return GameInstance.player.towerDefenseSystem.systemInDefense
end
function isInSpaceShip()
    return GameUtil.SpaceshipUtils.IsInSpaceShip()
end
function getServerTimeZoneOffsetHours()
    return CS.Beyond.DateTimeUtils.SERVER_TIME_ZONE.BaseUtcOffset.TotalHours
end
function getServerTimeZoneOffsetSeconds()
    return CS.Beyond.DateTimeUtils.SERVER_TIME_ZONE.BaseUtcOffset.TotalSeconds
end
function getNextCommonServerRefreshTime()
    local timePerDay = 24 * 60 * 60
    local curTime = DateTimeUtils.GetCurrentTimestampBySeconds() + Utils.getServerTimeZoneOffsetSeconds()
    local curDate = os.date("!*t", curTime)
    local today4AM = { year = curDate.year, month = curDate.month, day = curDate.day, hour = UIConst.COMMON_SERVER_UPDATE_TIME, }
    if curDate.hour < UIConst.COMMON_SERVER_UPDATE_TIME then
        return os.time(today4AM) + _getTimeZoneDiffOfClientAndServer()
    else
        return os.time(today4AM) + timePerDay + _getTimeZoneDiffOfClientAndServer()
    end
end
function getNextWeeklyServerRefreshTime()
    local timePerDay = 24 * 60 * 60
    local curTime = DateTimeUtils.GetCurrentTimestampBySeconds() + Utils.getServerTimeZoneOffsetSeconds()
    local curDate = os.date("!*t", curTime)
    local today4AM = { year = curDate.year, month = curDate.month, day = curDate.day, hour = UIConst.COMMON_SERVER_UPDATE_TIME, }
    local weekDay = curDate.wday - 1
    if weekDay == 0 then
        weekDay = 7
    end
    if weekDay == 1 and curDate.hour < UIConst.COMMON_SERVER_UPDATE_TIME then
        return os.time(today4AM) + _getTimeZoneDiffOfClientAndServer()
    end
    local deltaDays = 8 - weekDay
    return os.time(today4AM) + timePerDay * deltaDays + _getTimeZoneDiffOfClientAndServer()
end
function _getTimeZoneDiffOfClientAndServer()
    return CS.System.TimeZoneInfo.Local:GetUtcOffset(CS.System.DateTime.Now).TotalSeconds - Utils.getServerTimeZoneOffsetSeconds()
end
function getNextMonthlyServerRefreshTime()
    local timePerDay = 24 * 60 * 60
    local curTime = DateTimeUtils.GetCurrentTimestampBySeconds() + Utils.getServerTimeZoneOffsetSeconds()
    local curDate = os.date("!*t", curTime)
    local today4AM = { year = curDate.year, month = curDate.month, day = curDate.day, hour = UIConst.COMMON_SERVER_UPDATE_TIME, }
    local monthDay = curDate.day
    if monthDay == 1 and curDate.hour < UIConst.COMMON_SERVER_UPDATE_TIME then
        return os.time(today4AM) + _getTimeZoneDiffOfClientAndServer()
    end
    local monthTotalDays = os.date("%d", os.time({ year = curDate.year, month = curDate.month + 1, day = 0, }))
    local deltaDays = monthTotalDays + 1 - monthDay
    return os.time(today4AM) + timePerDay * deltaDays + _getTimeZoneDiffOfClientAndServer()
end
function appendUTC(timeStr)
    local hour = getServerTimeZoneOffsetHours()
    if hour >= 0 then
        return string.format("%s (UTC+%d)", timeStr, math.abs(hour))
    else
        return string.format("%s (UTC-%d)", timeStr, math.abs(hour))
    end
end
function checkSettlementOrderCanSubmit(settlementId, domainId, context)
    local orderId = GameInstance.player.settlementSystem:GetSettlementOrderId(settlementId)
    if orderId == nil then
        return CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.None
    end
    local itemConsumeDic = {}
    local orderData = Tables.settlementOrderDataTable[orderId]
    for _, costItem in pairs(orderData.costItems) do
        if context[costItem.id] == nil then
            context[costItem.id] = Utils.getDepotItemCount(costItem.id, nil, domainId)
        end
        itemConsumeDic[costItem.id] = itemConsumeDic[costItem.id] and itemConsumeDic[costItem.id] + costItem.count or costItem.count
    end
    local canSubmit = true
    for id, count in pairs(itemConsumeDic) do
        if context[id] < count then
            canSubmit = false
            break
        end
    end
    if canSubmit then
        for id, count in pairs(itemConsumeDic) do
            context[id] = context[id] - count
        end
    end
    return canSubmit
end
function getOrderSubmitStateBySettlementId(domainId, settlementId, itemContext)
    local oneCanSubmit = false
    local oneCantSubmit = false
    local orderId = GameInstance.player.settlementSystem:GetSettlementOrderId(settlementId)
    if orderId ~= nil then
        local canSubmit = checkSettlementOrderCanSubmit(settlementId, domainId, itemContext)
        if canSubmit then
            oneCanSubmit = true
        else
            oneCantSubmit = true
        end
    end
    if oneCanSubmit and not oneCantSubmit then
        return CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.All
    elseif oneCanSubmit and oneCantSubmit then
        return CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Part
    elseif oneCantSubmit then
        return CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Zero
    else
        return CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.None
    end
end
function getOrderSubmitStateByDomainId(domainId, itemContext)
    local oneCanSubmit = false
    local oneCantSubmit = false
    for i, settlementId in pairs(Tables.domainDataTable[domainId].settlementGroup) do
        local orderId = GameInstance.player.settlementSystem:GetSettlementOrderId(settlementId)
        if orderId ~= nil then
            local canSubmit = checkSettlementOrderCanSubmit(settlementId, domainId, itemContext)
            if canSubmit then
                oneCanSubmit = true
            else
                oneCantSubmit = true
            end
        end
    end
    if oneCanSubmit and not oneCantSubmit then
        return CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.All
    elseif oneCanSubmit and oneCantSubmit then
        return CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Part
    elseif oneCantSubmit then
        return CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Zero
    else
        return CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.None
    end
end
function intToEnum(enumType, value)
    return CS.System.Enum.ToObject(enumType, value)
end
function needMissionHud()
    if isInDungeonFactory() then
        return false
    end
    if GameInstance.player.mission:InDungeon() and not GameInstance.player.mission:InCharDungeon() then
        return false
    end
    if GameInstance.mode.hideMissionHud then
        return false
    end
    return true
end
function canJumpToSystem(jumpId)
    local cfg = Tables.systemJumpTable[jumpId]
    local isUnlock = Utils.isSystemUnlocked(cfg.bindSystem)
    if isUnlock then
        local phaseId = PhaseId[cfg.phaseId]
        local phaseArgs
        if not string.isEmpty(cfg.phaseArgs) then
            phaseArgs = Json.decode(cfg.phaseArgs)
        end
        if not phaseId or PhaseManager:CheckCanOpenPhase(phaseId, phaseArgs) then
            return true
        end
    end
    return false
end
function jumpToSystem(jumpId)
    local cfg = Tables.systemJumpTable[jumpId]
    local isUnlock = Utils.isSystemUnlocked(cfg.bindSystem)
    if not isUnlock then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_SYSTEM_LOCK)
        return
    end
    local phaseId = PhaseId[cfg.phaseId]
    local phaseArgs
    if not string.isEmpty(cfg.phaseArgs) then
        phaseArgs = Json.decode(cfg.phaseArgs)
    end
    PhaseManager:GoToPhase(phaseId, phaseArgs)
end
function unlockCraft(itemId)
    local hasCraft, craftIds = Tables.factoryItemAsManualCraftOutcomeTable:TryGetValue(itemId)
    local unlock = true
    if hasCraft then
        unlock = false
        for _, craftId in pairs(craftIds.list) do
            unlock = GameInstance.player.facManualCraft:IsCraftUnlocked(craftId)
            if unlock then
                break
            end
        end
    end
    return hasCraft, unlock
end
function validItemManualCraft(itemId)
    local res = false
    local hasCraft, craftIds = Tables.factoryItemAsManualCraftOutcomeTable:TryGetValue(itemId)
    if hasCraft then
        for _, craftId in pairs(craftIds.list) do
            local unlock = GameInstance.player.facManualCraft:IsCraftUnlocked(craftId)
            if unlock then
                res = validManualCraft(craftId)
                if res then
                    break
                end
            end
        end
    end
    return res
end
function validManualCraft(craftId)
    local res = true
    local inTb, craftData = Tables.factoryManualCraftTable:TryGetValue(craftId)
    res = inTb
    if inTb then
        for _, itemBundle in pairs(craftData.ingredients) do
            local count = getBagItemCount(itemBundle.id)
            if count < itemBundle.count then
                res = false
                break
            end
        end
    end
    return res
end
function nextStaminaRecoverLeftTime()
    local nextRecoverTime = GameInstance.player.inventory.staminaNextRecoverTime
    local curTime = DateTimeUtils.GetCurrentTimestampBySeconds()
    local nextLeftTime = nextRecoverTime - curTime
    if (nextLeftTime <= 0) then
        return 0
    else
        return nextLeftTime
    end
end
function fullStaminaRecoverLeftTime()
    local nextLeftTime = Utils.nextStaminaRecoverLeftTime()
    local curStamina = GameInstance.player.inventory.curStamina
    local maxStamina = GameInstance.player.inventory.maxStamina
    local fullLeftTime = (maxStamina - curStamina - 1) * Tables.dungeonConst.staminaRecoverDuration + nextLeftTime
    if (fullLeftTime <= 0) then
        return 0
    else
        return fullLeftTime
    end
end
function tryGetTableCfg(table, id)
    local hasCfg, cfg = table:TryGetValue(id)
    if not hasCfg then
        logger.error(ELogChannel.Cfg, "[Utils.tryGetTableCfg] missing cfg, id = " .. id)
        return nil
    end
    return cfg
end
function getStaminaLimit(level)
    local limit = Tables.dungeonConst.initStaminaLimit
    for _, cfg in pairs(Tables.adventureLevelTable) do
        limit = limit + cfg.raiseMaxStamina
        if cfg.level == level then
            break
        end
    end
    return limit
end
function getImgGenderDiffPath(imgText)
    local path = string.match(imgText, UIConst.UI_RICH_CONTENT_IMG_GENDER_DIFF_MATCH)
    if not path then
        path = imgText
    else
        local isMale = Utils.getPlayerGender() == CS.Proto.GENDER.GenMale
        if isMale then
            path = string.format(UIConst.UI_RICH_CONTENT_IMG_GENDER_DIFF_FORMAT_MALE, path)
        else
            path = string.format(UIConst.UI_RICH_CONTENT_IMG_GENDER_DIFF_FORMAT_FEMALE, path)
        end
    end
    return path
end
function isCurSquadAllDead()
    return GameInstance.player.squadManager:IsCurSquadAllDead()
end