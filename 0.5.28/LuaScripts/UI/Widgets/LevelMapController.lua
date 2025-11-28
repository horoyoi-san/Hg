local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
local ControllerMode = MapConst.LEVEL_MAP_CONTROLLER_MODE
local LineType = CS.Beyond.Gameplay.FacMarkLineType
local MarkInfoType = CS.Beyond.GEnums.MarkInfoType
LevelMapController = HL.Class('LevelMapController', UIWidgetBase)
local LEVEL_UPDATE_THREAD_INTERVAL = 0.5
local LEVEL_SWITCH_LOADER_UPDATE_THREAD_INTERVAL = 0.015
local FOLLOW_CHARACTER_LOADER_UPDATE_THREAD_INTERVAL = 0.25
local INVOKE_LEVEL_SWITCH_FINISH_DELAY = 0.2
local FILTER_TYPE_TO_LINE_TYPE_MAP = { [MarkInfoType.HUB] = LineType.Power, [MarkInfoType.PowerPole] = LineType.Power, [MarkInfoType.TravelPole] = LineType.Travel, }
local LINE_TYPE_TO_VISIBLE_LAYER_FIELD_NAME_MAP = { [LineType.Travel] = "travelLineVisibleLayer", [LineType.Power] = "powerLineVisibleLayer", }
local NEED_UPDATE_LOADER_CHARACTER_SQR_MAGNITUDE = 0.002
LevelMapController.m_mode = HL.Field(HL.Number) << -1
LevelMapController.m_levelMapConfig = HL.Field(CS.Beyond.Gameplay.UILevelMapConfig)
LevelMapController.m_currentLevelId = HL.Field(HL.String) << ""
LevelMapController.m_currentIsSingleLevel = HL.Field(HL.Boolean) << false
LevelMapController.m_fixedMarkInstId = HL.Field(HL.String) << ""
LevelMapController.m_customRefreshMark = HL.Field(HL.Function)
LevelMapController.m_onLevelSwitch = HL.Field(HL.Function)
LevelMapController.m_onLevelSwitchStart = HL.Field(HL.Function)
LevelMapController.m_onLevelSwitchFinish = HL.Field(HL.Function)
LevelMapController.m_onTrackingMarkClicked = HL.Field(HL.Function)
LevelMapController.m_switchTweenList = HL.Field(HL.Table)
LevelMapController.m_delayInvokeTimer = HL.Field(HL.Number) << -1
LevelMapController.m_currentMaxScale = HL.Field(HL.Number) << -1
LevelMapController.m_currentMinScale = HL.Field(HL.Number) << -1
LevelMapController.m_visibleMarks = HL.Field(HL.Table)
LevelMapController.m_filteredMarks = HL.Field(HL.Table)
LevelMapController.m_layeredMarks = HL.Field(HL.Table)
LevelMapController.m_currentLayer = HL.Field(HL.Number) << -1
LevelMapController.m_currFollowModeTrackingMarkId = HL.Field(HL.String) << ""
LevelMapController.m_markVisibleRect = HL.Field(RectTransform)
LevelMapController.m_followUpdateTick = HL.Field(HL.Number) << -1
LevelMapController.m_levelUpdateTick = HL.Field(HL.Number) << -1
LevelMapController.m_lastCharacterPos = HL.Field(Vector3)
LevelMapController.m_lastPosChanged = HL.Field(HL.Boolean) << false
LevelMapController.m_currTrackingMarkData = HL.Field(HL.Table)
LevelMapController.m_needShowTrackingMark = HL.Field(HL.Boolean) << false
LevelMapController.m_trackingMarkShowDistPow = HL.Field(HL.Number) << -1
LevelMapController.m_lastTrackingMarkId = HL.Field(HL.String) << ""
LevelMapController.m_trackingMissionMarkIdList = HL.Field(HL.Table)
LevelMapController._OnFirstTimeInit = HL.Override() << function(self)
    if self.m_mode == ControllerMode.LEVEL_SWITCH then
        self:RegisterMessage(MessageConst.ON_LEVEL_MAP_SWITCH_BTN_CLICKED, function(args)
            local targetLevelId = unpack(args)
            self:_SwitchToTargetLevel(targetLevelId)
        end)
        self:RegisterMessage(MessageConst.ON_MAP_FILTER_STATE_CHANGED, function(args)
            self:_RefreshLoaderMarksVisibleStateByFilter()
        end)
    end
    self:RegisterMessage(MessageConst.ON_TRACKING_MAP_MARK, function(args)
        local trackingMarkInstId, unTrackingMarkInstId = unpack(args)
        self:_OnTrackingStateChanged(trackingMarkInstId, unTrackingMarkInstId)
    end)
    self:RegisterMessage(MessageConst.ON_MAP_TRACKING_MISSION_DATA_CHANGED, function(args)
        self:_RefreshMissionTrackingMarks()
    end)
end
LevelMapController._OnDestroy = HL.Override() << function(self)
    if self.m_mode == ControllerMode.FOLLOW_CHARACTER then
        self.m_followUpdateTick = LuaUpdate:Remove(self.m_followUpdateTick)
        self.m_levelUpdateTick = LuaUpdate:Remove(self.m_levelUpdateTick)
    elseif self.m_mode == ControllerMode.LEVEL_SWITCH then
        if self.m_switchTweenList ~= nil then
            for _, tween in pairs(self.m_switchTweenList) do
                if tween ~= nil then
                    tween:Kill(false)
                end
            end
            self.m_switchTweenList = nil
        end
    end
end
LevelMapController.InitLevelMapController = HL.Method(HL.Number, HL.Opt(HL.Table)) << function(self, mode, customInfo)
    self.m_levelMapConfig = DataManager.uiLevelMapConfig
    customInfo = customInfo or {}
    local initialLevelId = string.isEmpty(customInfo.initialLevelId) and GameInstance.world.curLevelId or customInfo.initialLevelId
    local loaderCustomInfo
    if mode == ControllerMode.FIXED then
        if not string.isEmpty(customInfo.fixedMarkInstId) then
            initialLevelId = GameInstance.player.mapManager:GetMarkInstRuntimeDataLevelId(customInfo.fixedMarkInstId)
            self.m_fixedMarkInstId = customInfo.fixedMarkInstId
        end
        loaderCustomInfo = { needUpdate = false, hidePlayer = customInfo.hidePlayer }
    elseif mode == ControllerMode.LEVEL_SWITCH then
        loaderCustomInfo = { hideOtherLevels = true, needUpdate = false, needDelayUpdateAll = true, }
    elseif mode == ControllerMode.FOLLOW_CHARACTER then
        loaderCustomInfo = { useSingleViewData = true, }
    end
    if not self.m_levelMapConfig.levelConfigInfos:ContainsKey(initialLevelId) then
        return
    end
    self.view.levelMapLoader:InitLevelMapLoader(initialLevelId, loaderCustomInfo)
    self:_SetCurrentLevelId(initialLevelId)
    self.m_customRefreshMark = customInfo.customRefreshMark or function()
    end
    self.m_onLevelSwitch = customInfo.onLevelSwitch or function()
    end
    self.m_onLevelSwitchStart = customInfo.onLevelSwitchStart or function()
    end
    self.m_onLevelSwitchFinish = customInfo.onLevelSwitchFinish or function()
    end
    self.m_onTrackingMarkClicked = customInfo.onTrackingMarkClicked or function()
    end
    self.m_markVisibleRect = customInfo.visibleRect
    self.m_mode = mode
    if mode == ControllerMode.FIXED then
        self:_InitControllerFixedMode()
    elseif mode == ControllerMode.LEVEL_SWITCH then
        self:_InitControllerSwitchMode()
    elseif mode == ControllerMode.FOLLOW_CHARACTER then
        self:_InitControllerFollowMode()
    end
    self:_FirstTimeInit()
end
LevelMapController._SetCurrentLevelId = HL.Method(HL.String) << function(self, levelId)
    self.m_currentLevelId = levelId
    local configSuccess, levelConfig = DataManager.uiLevelMapConfig.levelConfigInfos:TryGetValue(levelId)
    if configSuccess then
        self.m_currentIsSingleLevel = levelConfig.isSingleLevel
    end
end
LevelMapController._InitControllerFixedMode = HL.Method() << function(self)
    if not string.isEmpty(self.m_fixedMarkInstId) then
        self.view.levelMapLoader:SetLoaderWithMarkPosition(self.m_fixedMarkInstId)
    end
    self.view.levelMapLoader:UpdateAndRefreshAll()
    self:_CustomRefreshFixedModeMarks()
end
LevelMapController._CustomRefreshFixedModeMarks = HL.Method() << function(self)
    local loadedMarkViewDataMap = self.view.levelMapLoader:GetLoadedMarkViewDataMap()
    if loadedMarkViewDataMap == nil or next(loadedMarkViewDataMap) == nil then
        return
    end
    for _, markViewData in pairs(loadedMarkViewDataMap) do
        if self.m_customRefreshMark ~= nil then
            self.m_customRefreshMark(markViewData)
        end
    end
end
LevelMapController._InitControllerSwitchMode = HL.Method() << function(self)
    self.view.levelMapLoader:SetLoaderDataUpdateInterval(LEVEL_SWITCH_LOADER_UPDATE_THREAD_INTERVAL)
    self:_RefreshLoaderStateByLevel(self.m_currentLevelId, false)
    self:_RefreshMissionTrackingMarks()
end
LevelMapController._RefreshLoaderStateByLevel = HL.Method(HL.String, HL.Boolean) << function(self, levelId, moveNeedTween)
    local success, configInfo = self.m_levelMapConfig.levelConfigInfos:TryGetValue(levelId)
    if not success then
        return
    end
    local gridRectLength = self.m_levelMapConfig.gridRectLength
    local tweenDuration = self.view.config.SWITCH_TWEEN_DURATION
    local tweenEase = self.view.config.SWITCH_TWEEN_CURVE
    local tweenData = moveNeedTween and { duration = tweenDuration, ease = tweenEase, } or nil
    self.m_switchTweenList = {}
    self.view.levelMapLoader:SetLoaderLevel(levelId)
    local inCurrentLevel = GameInstance.world.curLevelId == levelId
    self.view.levelMapLoader:SetLoaderPlayerVisibleState(inCurrentLevel)
    if moveNeedTween then
        self.view.levelMapLoader:SetLoaderElementsShownState(false)
    end
    local minScale = configInfo.minScale
    local offset = Vector2(-configInfo.horizontalInitOffsetGridsValue * gridRectLength * minScale, -configInfo.verticalInitOffsetGridsValue * gridRectLength * minScale)
    local loaderPosTween = self.view.levelMapLoader:SetLoaderWithLevelCenterPosition(levelId, offset, tweenData)
    local loaderSizeTween = self.view.levelMapLoader:SetLoaderViewSizeByGridsCount(configInfo.horizontalViewGridsCount, configInfo.verticalViewGridsCount, tweenData)
    if not moveNeedTween then
        self.view.levelMapLoader:UpdateAndRefreshAll()
    end
    if moveNeedTween then
        table.insert(self.m_switchTweenList, loaderPosTween)
        table.insert(self.m_switchTweenList, loaderSizeTween)
    end
    local loaderMoveSize = Vector2(configInfo.horizontalMoveGridsValue * gridRectLength, configInfo.verticalMoveGridsValue * gridRectLength)
    local initialOffset = Vector2(configInfo.horizontalAllInitOffsetGridsValue * gridRectLength, configInfo.verticalAllInitOffsetGridsValue * gridRectLength)
    local targetInfo = { size = loaderMoveSize, scale = minScale, initialOffset = initialOffset, }
    if moveNeedTween then
        self.m_onLevelSwitchStart(targetInfo)
    else
        self:_ResetLoaderMarksVisibleStateByFilter()
        self.m_onLevelSwitch(targetInfo)
    end
    if moveNeedTween then
        local scaleTween = self.view.rectTransform:DOScale(configInfo.minScale, tweenDuration):SetEase(tweenEase)
        local posTween = self.view.rectTransform:DOAnchorPos(initialOffset, tweenDuration):SetEase(tweenEase)
        table.insert(self.m_switchTweenList, scaleTween)
        table.insert(self.m_switchTweenList, posTween)
        for index, tween in ipairs(self.m_switchTweenList) do
            tween:OnComplete(function()
                self.m_switchTweenList[index] = nil
                if not next(self.m_switchTweenList) then
                    self:_ResetLoaderMarksVisibleStateByFilter()
                    self.m_delayInvokeTimer = self:_StartTimer(INVOKE_LEVEL_SWITCH_FINISH_DELAY, function()
                        self.m_onLevelSwitchFinish()
                        self:_ClearTimer(self.m_delayInvokeTimer)
                        self.view.levelMapLoader:SetLoaderElementsShownState(true)
                        self:_RefreshGeneralTrackingMarkInSwitchMode()
                        self:_RefreshMissionRelatedMarksVisibleState()
                    end)
                end
            end)
        end
    else
        self.view.rectTransform.anchoredPosition = Vector2.zero
    end
    self.m_currentMaxScale = configInfo.maxScale
    self.m_currentMinScale = configInfo.minScale
    self:_SetCurrentLevelId(levelId)
    self:_RefreshGeneralTrackingMarkInSwitchMode()
end
LevelMapController._SwitchToTargetLevel = HL.Method(HL.String) << function(self, levelId)
    self:_RefreshLoaderStateByLevel(levelId, true)
end
LevelMapController._ResetLoaderMarksVisibleStateByFilter = HL.Method() << function(self)
    self:_UpdateLoaderMarksVisibleData()
    self:_RefreshLoaderMarksVisibleStateByFilter()
end
LevelMapController._UpdateLoaderMarksVisibleData = HL.Method() << function(self)
    local loadedMarkViewDataMap = self.view.levelMapLoader:GetLoadedMarkViewDataMap()
    if loadedMarkViewDataMap == nil or next(loadedMarkViewDataMap) == nil then
        return
    end
    self.m_visibleMarks = {}
    for _, markViewData in pairs(loadedMarkViewDataMap) do
        if markViewData.isVisible and not markViewData.isHidden then
            self.m_visibleMarks[markViewData.instId] = markViewData
        end
    end
end
LevelMapController._RefreshLoaderMarksVisibleStateByFilter = HL.Method() << function(self)
    self.m_filteredMarks = {}
    for instId, markViewData in pairs(self.m_visibleMarks) do
        local filterType = markViewData.filterType
        self.m_filteredMarks[instId] = not GameInstance.player.mapManager:HasFilterFlag(filterType)
        self:_RefreshLoaderMarkVisibleState(instId)
    end
    self:_RefreshLoaderLineVisibleState()
end
LevelMapController._RefreshLoaderMarksVisibleStateByLayer = HL.Method(HL.Number) << function(self, layer)
    self.m_layeredMarks = {}
    for instId, markViewData in pairs(self.m_visibleMarks) do
        local visible = markViewData.visibleLayer <= layer
        self.m_layeredMarks[instId] = visible
        self:_RefreshLoaderMarkVisibleState(instId)
    end
    self.m_currentLayer = layer
    self:_RefreshLoaderLineVisibleState()
end
LevelMapController._RefreshLoaderMarkVisibleState = HL.Method(HL.String) << function(self, markInstId)
    local markViewData = self.m_visibleMarks[markInstId]
    if markViewData == nil then
        return
    end
    local isVisible = true
    if not self.m_currentIsSingleLevel then
        if self.m_filteredMarks ~= nil then
            isVisible = isVisible and self.m_filteredMarks[markInstId] == true
        end
        if self.m_layeredMarks ~= nil then
            isVisible = isVisible and self.m_layeredMarks[markInstId] == true
        end
    end
    markViewData.mark.gameObject:SetActiveIfNecessary(isVisible)
end
LevelMapController._RefreshLoaderLineVisibleState = HL.Method() << function(self)
    self.view.levelMapLoader:SetLoaderLineVisibleState(true)
    local invisibleLineList = {}
    for lineType, fieldName in pairs(LINE_TYPE_TO_VISIBLE_LAYER_FIELD_NAME_MAP) do
        local isVisible = self.m_currentLayer >= self.m_levelMapConfig[fieldName]
        if not isVisible then
            invisibleLineList[lineType] = true
        end
    end
    for filterType, lineType in pairs(FILTER_TYPE_TO_LINE_TYPE_MAP) do
        if GameInstance.player.mapManager:HasFilterFlag(filterType) then
            invisibleLineList[lineType] = true
        end
    end
    for lineType, _ in pairs(invisibleLineList) do
        self.view.levelMapLoader:SetLoaderLineVisibleStateByType(lineType, false)
    end
end
LevelMapController._SetTrackingMissionMarksOnClickedCallbackInSwitchMode = HL.Method() << function(self)
    local trackingMissionMarks = self.view.levelMapLoader:GetMissionTrackingMarks()
    if trackingMissionMarks == nil then
        return
    end
    for instId, trackingMark in pairs(trackingMissionMarks) do
        trackingMark.levelMapMark:SetCustomMarkOnClickCallback(function()
            local relatedMark = self.view.levelMapLoader:GetLoadedMarkByInstId(instId)
            self.m_onTrackingMarkClicked(instId, trackingMark, relatedMark)
        end)
    end
end
LevelMapController._GetIsMarkRealVisible = HL.Method(HL.String).Return(HL.Boolean) << function(self, markInstId)
    return self.m_filteredMarks[markInstId] and self.m_layeredMarks[markInstId]
end
LevelMapController._InitControllerFollowMode = HL.Method() << function(self)
    self.view.levelMapLoader:SetLoaderDataUpdateInterval(FOLLOW_CHARACTER_LOADER_UPDATE_THREAD_INTERVAL)
    self:_RefreshLoaderStateByCharacter(true)
    self:_RefreshMissionTrackingMarks()
    self:_InitGeneralTrackingMarkInFollowMode()
    self.view.levelMapLoader:UpdateAndRefreshAll()
    local uiCtrl = self:GetUICtrl()
    self.m_followUpdateTick = LuaUpdate:Add("Tick", function(deltaTime)
        if uiCtrl:IsShow() then
            self:_RefreshLoaderStateByCharacter(false)
            self:_TickRefreshTrackingRelatedMarksVisibleStateInFollowMode()
        end
    end)
    local nextUpdateTime = 0
    self.m_levelUpdateTick = LuaUpdate:Add("TailTick", function()
        if Time.unscaledTime < nextUpdateTime then
            return
        end
        nextUpdateTime = Time.unscaledTime + LEVEL_UPDATE_THREAD_INTERVAL
        if uiCtrl:IsShow() then
            self:_UpdateLoaderLevel()
            self:_UpdateAndRefreshGeneralTrackingMarkInFollowMode(false)
        end
    end, true)
end
LevelMapController._UpdateLoaderLevel = HL.Method() << function(self)
    local levelId = GameInstance.world.curLevelId
    if levelId == self.m_currentLevelId then
        return
    end
    self:_SetCurrentLevelId(levelId)
    self.view.levelMapLoader:SetLoaderLevel(levelId)
end
LevelMapController._RefreshLoaderStateByCharacter = HL.Method(HL.Boolean) << function(self, forceRefresh)
    local currCharPos = self.view.levelMapLoader:GetLoaderCharacterWorldPosition()
    local posChanged = Vector3.SqrMagnitude(currCharPos - self.m_lastCharacterPos) >= NEED_UPDATE_LOADER_CHARACTER_SQR_MAGNITUDE
    if posChanged ~= self.m_lastPosChanged or forceRefresh then
        if posChanged == true then
            self.view.levelMapLoader:SetLoaderNeedUpdate(posChanged)
            self.view.levelMapLoader:UpdateAndRefreshAll()
        end
    end
    self.m_lastCharacterPos = currCharPos
    self.m_lastPosChanged = posChanged
    self.view.levelMapLoader:SetLoaderWithPlayerPosition()
end
LevelMapController._RefreshGeneralRelatedMarkVisibleStateInFollowMode = HL.Method() << function(self)
    if string.isEmpty(self.m_currFollowModeTrackingMarkId) then
        return
    end
    local currMark = self.view.levelMapLoader:GetLoadedMarkByInstId(self.m_currFollowModeTrackingMarkId)
    if currMark == nil then
        return
    end
    currMark.content.gameObject:SetActive(false)
end
LevelMapController._TickRefreshTrackingRelatedMarksVisibleStateInFollowMode = HL.Method() << function(self)
    self:_RefreshGeneralRelatedMarkVisibleStateInFollowMode()
    self:_RefreshMissionRelatedMarksVisibleState()
end
LevelMapController._OnTrackingStateChanged = HL.Method(HL.String, HL.String) << function(self, trackingMarkInstId, unTrackingMarkInstId)
    if self.m_mode == ControllerMode.LEVEL_SWITCH then
        self:_RefreshGeneralTrackingMarkInSwitchMode()
    elseif self.m_mode == ControllerMode.FOLLOW_CHARACTER then
        self:_UpdateGeneralTrackingMarkDataInFollowMode()
        self:_UpdateAndRefreshGeneralTrackingMarkInFollowMode(true)
    end
end
LevelMapController._RefreshGeneralTrackingMarkInSwitchMode = HL.Method() << function(self)
    local mapManager = GameInstance.player.mapManager
    local trackingMarkInstId = mapManager.trackingMarkInstId
    if not string.isEmpty(trackingMarkInstId) and mapManager:GetMarkInstRuntimeDataLevelId(trackingMarkInstId) ~= self.m_currentLevelId then
        local trackingRect = self.view.levelMapLoader:GetMarkRectTransformByInstId(trackingMarkInstId)
        if trackingRect == nil then
            trackingMarkInstId = ""
        else
            local uiCamera = self:GetUICtrl().uiCamera
            local screenPos = self:GetUICtrl().uiCamera:WorldToScreenPoint(trackingRect.position)
            local isOut = not UIUtils.isScreenPosInRectTransform(screenPos, self.m_markVisibleRect, uiCamera)
            if isOut then
                trackingMarkInstId = ""
            end
        end
    end
    self:_RefreshGeneralRelatedMarkVisibleState(self.m_lastTrackingMarkId, trackingMarkInstId)
    self.view.levelMapLoader:SetGeneralTrackingMarkState(trackingMarkInstId)
    local trackingMark = self.view.levelMapLoader:GetGeneralTrackingMark()
    if not string.isEmpty(trackingMarkInstId) then
        trackingMark.levelMapMark:SetCustomMarkOnClickCallback(function()
            local relatedMark = self.view.levelMapLoader:GetLoadedMarkByInstId(trackingMarkInstId)
            self.m_onTrackingMarkClicked(trackingMarkInstId, trackingMark, relatedMark)
        end)
    end
    self.m_lastTrackingMarkId = trackingMarkInstId
end
LevelMapController._InitGeneralTrackingMarkInFollowMode = HL.Method() << function(self)
    self.m_trackingMarkShowDistPow = self.m_levelMapConfig.trackingMarkShowDistance ^ 2
    self:_UpdateGeneralTrackingMarkDataInFollowMode()
    self:_UpdateAndRefreshGeneralTrackingMarkInFollowMode(true)
end
LevelMapController._UpdateAndRefreshGeneralTrackingMarkInFollowMode = HL.Method(HL.Boolean) << function(self, forceRefresh)
    local characterData = self.view.levelMapLoader:GetLoaderCharacterData()
    if characterData == nil then
        return
    end
    local needShow = false
    if self.m_currTrackingMarkData.levelId == self.m_currentLevelId then
        needShow = true
    else
        local sqrMagnitude = Vector3.SqrMagnitude(characterData.worldPos - self.m_currTrackingMarkData.worldPos)
        needShow = sqrMagnitude <= self.m_trackingMarkShowDistPow
    end
    if self.m_needShowTrackingMark == needShow and not forceRefresh then
        return
    end
    self.m_needShowTrackingMark = needShow
    self:_RefreshGeneralTrackingMarkInFollowMode()
end
LevelMapController._UpdateGeneralTrackingMarkDataInFollowMode = HL.Method() << function(self)
    local mapManager = GameInstance.player.mapManager
    local trackingMarkInstId = mapManager.trackingMarkInstId
    self.m_currTrackingMarkData = { instId = trackingMarkInstId, worldPos = Vector3.zero, levelId = "", }
    if not string.isEmpty(trackingMarkInstId) then
        local success, markData = mapManager:GetMarkInstRuntimeData(trackingMarkInstId)
        if success then
            self.m_currTrackingMarkData.worldPos = markData.position
            self.m_currTrackingMarkData.levelId = markData.levelId
        end
    end
end
LevelMapController._RefreshGeneralRelatedMarkVisibleState = HL.Method(HL.String, HL.String) << function(self, lastId, currId)
    local lastMark = self.view.levelMapLoader:GetLoadedMarkByInstId(lastId)
    local currMark = self.view.levelMapLoader:GetLoadedMarkByInstId(currId)
    if lastMark ~= nil then
        lastMark.content.gameObject:SetActive(lastId ~= currId)
    end
    if currMark ~= nil then
        currMark.content.gameObject:SetActive(false)
    end
end
LevelMapController._RefreshGeneralTrackingMarkInFollowMode = HL.Method() << function(self)
    local trackingMarkInstId = GameInstance.player.mapManager.trackingMarkInstId
    if not self.m_needShowTrackingMark then
        trackingMarkInstId = ""
    end
    self:_RefreshGeneralRelatedMarkVisibleState(self.m_lastTrackingMarkId, trackingMarkInstId)
    self.view.levelMapLoader:SetGeneralTrackingMarkState(trackingMarkInstId)
    self.m_lastTrackingMarkId = trackingMarkInstId
    self.m_currFollowModeTrackingMarkId = trackingMarkInstId
end
LevelMapController._RefreshMissionTrackingMarks = HL.Method() << function(self)
    self.m_trackingMissionMarkIdList = {}
    for markId, _ in cs_pairs(GameInstance.player.mapManager.trackingMissionMarkList) do
        table.insert(self.m_trackingMissionMarkIdList, markId)
    end
    self.view.levelMapLoader:SetMissionTrackingMarkState(self.m_trackingMissionMarkIdList)
    self:_RefreshMissionRelatedMarksVisibleState()
    if self.m_mode == ControllerMode.LEVEL_SWITCH then
        self:_SetTrackingMissionMarksOnClickedCallbackInSwitchMode()
    end
end
LevelMapController._RefreshMissionRelatedMarksVisibleState = HL.Method() << function(self)
    if self.m_trackingMissionMarkIdList == nil then
        return
    end
    for _, id in pairs(self.m_trackingMissionMarkIdList) do
        local mark = self.view.levelMapLoader:GetLoadedMarkByInstId(id)
        if mark ~= nil then
            mark.content.gameObject:SetActive(false)
        end
    end
end
LevelMapController.GetControllerCurrentMaxScale = HL.Method().Return(HL.Number) << function(self)
    return self.m_currentMaxScale
end
LevelMapController.GetControllerCurrentMinScale = HL.Method().Return(HL.Number) << function(self)
    return self.m_currentMinScale
end
LevelMapController.GetControllerCurrentLevelId = HL.Method().Return(HL.String) << function(self)
    return self.m_currentLevelId
end
LevelMapController.GetControllerMarkRectTransform = HL.Method(HL.String).Return(Unity.RectTransform) << function(self, markInstId)
    local mapManager = GameInstance.player.mapManager
    local trackingMarkInstId = mapManager.trackingMarkInstId
    if markInstId == trackingMarkInstId then
        local mark = self.view.levelMapLoader:GetGeneralTrackingMark()
        return mark.rectTransform
    end
    local trackingMissionMarks = self.view.levelMapLoader:GetMissionTrackingMarks()
    for instId, trackingMissionMark in pairs(trackingMissionMarks) do
        if instId == markInstId then
            return trackingMissionMark.rectTransform
        end
    end
    return self.view.levelMapLoader:GetMarkRectTransformByInstId(markInstId)
end
LevelMapController.GetControllerNearbyMarkList = HL.Method(HL.String, HL.Number, HL.Number).Return(HL.Table) << function(self, targetInstId, length, scale)
    length = length / scale / 2.0
    local targetViewData = self.m_visibleMarks[targetInstId]
    if targetViewData == nil then
        return {}
    end
    local targetMark = targetViewData.mark
    local targetPos = targetMark.rectTransform.anchoredPosition
    local tempResult = {}
    for instId, markViewData in pairs(self.m_visibleMarks) do
        if instId ~= targetInstId and self:_GetIsMarkRealVisible(instId) then
            local isValidMark = self.view.levelMapLoader:GetLoadedMarkByInstId(instId) ~= nil
            if isValidMark then
                local mark = markViewData.mark
                local pos = mark.rectTransform.anchoredPosition
                if math.abs(pos.x - targetPos.x) <= length and math.abs(pos.y - targetPos.y) <= length then
                    local validNearby = true
                    if instId == GameInstance.player.mapManager.trackingMarkInstId then
                        local trackingMark = self.view.levelMapLoader:GetGeneralTrackingMark()
                        if trackingMark.levelMapLimitInRect ~= nil and trackingMark.levelMapLimitInRect.isLimitedInRect then
                            validNearby = false
                        end
                    end
                    if self.m_trackingMissionMarkIdList ~= nil then
                        for _, missionInstId in ipairs(self.m_trackingMissionMarkIdList) do
                            if instId == missionInstId then
                                local trackingMarks = self.view.levelMapLoader:GetMissionTrackingMarks()
                                local trackingMark = trackingMarks[instId]
                                if trackingMark ~= nil and trackingMark.levelMapLimitInRect ~= nil and trackingMark.levelMapLimitInRect.isLimitedInRect then
                                    validNearby = false
                                end
                            end
                        end
                    end
                    if validNearby then
                        table.insert(tempResult, markViewData)
                    end
                end
            end
        end
    end
    table.sort(tempResult, Utils.genSortFunction({ "sortId" }, false))
    local result = { targetInstId }
    for _, markViewData in ipairs(tempResult) do
        table.insert(result, markViewData.instId)
    end
    return result
end
LevelMapController.GetControllerMarkByInstId = HL.Method(HL.String).Return(HL.Any) << function(self, instId)
    return self.view.levelMapLoader:GetLoadedMarkByInstId(instId)
end
LevelMapController.RefreshLoaderMarksVisibleStateByLayer = HL.Method(HL.Number) << function(self, layer)
    self:_RefreshLoaderMarksVisibleStateByLayer(layer)
end
LevelMapController.ResetSwitchModeToTargetLevelState = HL.Method(HL.String) << function(self, levelId)
    local targetSuccess, targetLevelConfig = DataManager.levelConfigTable:TryGetData(levelId)
    if not targetSuccess then
        return
    end
    local currSuccess, currLevelConfig = DataManager.levelConfigTable:TryGetData(self.m_currentLevelId)
    if not currSuccess then
        return
    end
    if targetLevelConfig.mapIdStr ~= currLevelConfig.mapIdStr then
        self.view.levelMapLoader:ResetToTargetMapAndLevel(levelId)
    end
    self:_RefreshLoaderStateByLevel(levelId, false)
    self:_RefreshMissionTrackingMarks()
end
HL.Commit(LevelMapController)
return LevelMapController