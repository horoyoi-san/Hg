local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GeneralTracker
local MissionType = CS.Beyond.Gameplay.MissionSystem.MissionType
local TrackData = CS.Beyond.Gameplay.MissionSystem.TrackData
local STANDARD_HORIZONTAL_RESOLUTION = CS.Beyond.UI.UIConst.STANDARD_HORIZONTAL_RESOLUTION
local STANDARD_VERTICAL_RESOLUTION = CS.Beyond.UI.UIConst.STANDARD_VERTICAL_RESOLUTION
local TRACKER_STATE_SHOW = 1
local TRACKER_STATE_HIDE = 2
local TRACKER_STATE_SHOW_TO_HIDE = 3
local TRACKER_STATE_ACTIVE = 1
local TRACKER_STATE_INACTIVE = 2
local SIGNAL_1 = 1
local SIGNAL_2 = 2
local LuaNodeCache = require_ex('Common/Utils/LuaNodeCache')
local CommonTrackingPointStyleType = CS.Beyond.Gameplay.CommonTrackingPointStyleType
local TOO_FAR_DISTANCE = 15
GeneralTrackerCtrl = HL.Class('GeneralTrackerCtrl', uiCtrl.UICtrl)
GeneralTrackerCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_TRACK_MISSION_CHANGE] = '_OnTrackMissionChange', [MessageConst.ON_MISSION_STATE_CHANGE] = '_OnMissionStateChange', [MessageConst.ON_QUEST_STATE_CHANGE] = '_OnQuestStateChange', [MessageConst.ON_QUEST_OBJECTIVE_UPDATE] = '_OnQuestObjectiveUpdate', }
GeneralTrackerCtrl.missionTrackerDisplayDuration = HL.StaticField(HL.Number) << 0
GeneralTrackerCtrl.missionTrackerStartShowSignal = HL.StaticField(HL.Number) << 0
GeneralTrackerCtrl.OnShowMissionTracker = HL.StaticMethod() << function()
    GeneralTrackerCtrl.missionTrackerStartShowSignal = SIGNAL_1
    GeneralTrackerCtrl.missionTrackerDisplayDuration = 0
end
GeneralTrackerCtrl.m_trackerData = HL.Field(HL.Table)
GeneralTrackerCtrl.m_trackers = HL.Field(HL.Table)
GeneralTrackerCtrl.m_trackersCache = HL.Field(HL.Table)
GeneralTrackerCtrl.m_missionTrackerData = HL.Field(HL.Table)
GeneralTrackerCtrl.m_missionTrackers = HL.Field(HL.Table)
GeneralTrackerCtrl.m_missionTrackersCache = HL.Field(HL.Table)
GeneralTrackerCtrl.m_rootTransform = HL.Field(HL.Userdata)
GeneralTrackerCtrl.m_missionTrackerUpdateHandler = HL.Field(HL.Any)
GeneralTrackerCtrl.m_commonTrackerData = HL.Field(HL.Table)
GeneralTrackerCtrl.m_commonTrackers = HL.Field(HL.Table)
GeneralTrackerCtrl.m_commonTrackerUpdateHandler = HL.Field(HL.Number) << -1
GeneralTrackerCtrl.m_commonTrackerNodeCache = HL.Field(LuaNodeCache)
GeneralTrackerCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_rootTransform = self.view.gameObject:GetComponent(typeof(RectTransform))
    if self.m_trackers == nil then
        self.m_trackers = {}
    end
    if self.m_trackersCache == nil then
        self.m_trackersCache = {}
    end
    self.m_missionTrackers = self.m_missionTrackers or {}
    self.m_missionTrackersCache = self.m_missionTrackersCache or {}
    self.m_missionTrackerData = self.m_missionTrackerData or {}
    self.m_commonTrackers = {}
    self.m_commonTrackerData = {}
    self.m_commonTrackerNodeCache = LuaNodeCache(self.view.commonTrackerNode, self.view.main)
    self.view.tracker.gameObject:SetActive(false)
    self:_StartCoroutine(self:_Tick())
    self.view.missionTrackerUpdate.ALPHA_IN_FIGHT = self.view.config.ALPHA_IN_FIGHT
    self.view.missionTrackerUpdate.ALPHA_TIME_OUT = self.view.config.ALPHA_TIME_OUT
    self.view.missionTrackerUpdate.MISSION_TRACKER_SHOW_DURATION = self.view.config.MISSION_TRACKER_SHOW_DURATION
    self.view.missionTrackerUpdate.ELLIPSE_X_RADIUS = self.view.config.ELLIPSE_X_RADIUS
    self.view.missionTrackerUpdate.ELLIPSE_Y_RADIUS = self.view.config.ELLIPSE_Y_RADIUS
    self.view.missionTrackerUpdate.rootTransform = self.m_rootTransform
    self.view.missionTrackerUpdate.missionTracker = self.view.missionTracker.gameObject
    self.view.missionTrackerUpdate.main = self.view.main
end
GeneralTrackerCtrl.OnShow = HL.Override() << function(self)
    GeneralTrackerCtrl.missionTrackerDisplayDuration = 0
    GeneralTrackerCtrl.missionTrackerStartShowSignal = SIGNAL_2
    self:_UpdateMissionTrackers()
    self.m_missionTrackerUpdateHandler = LuaUpdate:Add("TailTick", function()
        self:_UpdateMissionTrackers()
    end)
    self:_UpdateCommonTrackers()
    self.m_commonTrackerUpdateHandler = LuaUpdate:Add("TailTick", function()
        self:_UpdateCommonTrackers()
    end)
end
GeneralTrackerCtrl.OnHide = HL.Override() << function(self)
    LuaUpdate:Remove(self.m_missionTrackerUpdateHandler)
    self.m_missionTrackerUpdateHandler = nil
    LuaUpdate:Remove(self.m_commonTrackerUpdateHandler)
    self.m_commonTrackerUpdateHandler = -1
end
GeneralTrackerCtrl.OnClose = HL.Override() << function(self)
    LuaUpdate:Remove(self.m_missionTrackerUpdateHandler)
    self.m_missionTrackerUpdateHandler = nil
    LuaUpdate:Remove(self.m_commonTrackerUpdateHandler)
    self.m_commonTrackerUpdateHandler = -1
end
GeneralTrackerCtrl._Tick = HL.Method().Return(HL.Function) << function(self)
    return function()
        while true do
            self:_UpdateTrackers()
            coroutine.step()
        end
    end
end
GeneralTrackerCtrl.UpdateEntityHeadPointDict = HL.Method(HL.Table) << function(self, arg)
    self.m_trackerData = arg
end
GeneralTrackerCtrl._UpdateTrackers = HL.Method() << function(self)
    local targetScrPosDict = {}
    local logicIdList = {}
    self:Notify(MessageConst.UPDATE_GENERAL_TRACKER)
    for _, data in pairs(self.m_trackerData) do
        local screenPos, isInside = UIUtils.objectPosToUI(data.worldPos, self.uiCamera)
        table.insert(targetScrPosDict, screenPos)
    end
    if #self.m_trackers > #targetScrPosDict then
        for i = #self.m_trackers, #targetScrPosDict + 1, -1 do
            self.m_trackers[i].obj:SetActive(false)
            table.insert(self.m_trackersCache, self.m_trackers[i])
            table.remove(self.m_trackers, i)
        end
    end
    if #self.m_trackers < #targetScrPosDict then
        for i = #self.m_trackers + 1, #targetScrPosDict do
            table.insert(self.m_trackers, self:_CreateNewTracker())
        end
    end
    for i = 1, #targetScrPosDict do
        local item = self.m_trackers[i]
        if item then
            local uiPos, uiAngle, isOutBound = UIUtils.mapScreenPosToEllipseEdge(targetScrPosDict[i], self.view.config.ELLIPSE_X_RADIUS, self.view.config.ELLIPSE_Y_RADIUS)
            item.tracker:UpdatePosition(uiPos, uiAngle, isOutBound)
        end
    end
end
GeneralTrackerCtrl._CreateNewTracker = HL.Method().Return(HL.Table) << function(self)
    local cacheCount = #self.m_trackersCache
    if cacheCount > 0 then
        local cacheObj = self.m_trackersCache[cacheCount]
        cacheObj.obj:SetActive(true)
        table.remove(self.m_trackersCache, cacheCount)
        return cacheObj
    end
    local obj = CSUtils.CreateObject(self.view.tracker.gameObject, self.view.main.transform)
    obj:SetActive(true)
    local item = {}
    item.obj = obj
    item.tracker = obj:GetComponent(typeof(CS.Beyond.UI.UIGeneralTracker))
    return item
end
GeneralTrackerCtrl.UpdateMissionEntityHeadPointDict = HL.Method(HL.Table) << function(self, arg)
    self.m_missionTrackerData = arg
end
GeneralTrackerCtrl._worldPosToTrackerUIData = HL.Method(Vector3).Return(Vector2, HL.Number, HL.Boolean) << function(self, worldPos)
    local screenPos3D = CameraManager.mainCamera:WorldToScreenPoint(worldPos)
    if screenPos3D.z < 0 then
        screenPos3D.x = -screenPos3D.x
        screenPos3D.y = -screenPos3D.y
    end
    local panelRect = self.m_rootTransform.rect
    local nx, ny = UIUtils.getNormalizedScreenX(screenPos3D.x), UIUtils.getNormalizedScreenY(screenPos3D.y)
    local screenPos = Vector2(panelRect.x + panelRect.width * nx, panelRect.y + panelRect.height * ny)
    local xRadius = self.view.config.ELLIPSE_X_RADIUS / STANDARD_HORIZONTAL_RESOLUTION * panelRect.width
    local yRadius = self.view.config.ELLIPSE_Y_RADIUS / STANDARD_VERTICAL_RESOLUTION * panelRect.height
    local uiPos, uiAngle, isOutBound = UIUtils.mapScreenPosToEllipseEdge(screenPos, xRadius, yRadius)
    return uiPos, uiAngle, isOutBound
end
GeneralTrackerCtrl.ResetMissionTrackerDisplayDuration = HL.StaticMethod() << function()
    GeneralTrackerCtrl.missionTrackerDisplayDuration = 0
end
GeneralTrackerCtrl._OnTrackMissionChange = HL.Method() << function(self)
    GeneralTrackerCtrl.ResetMissionTrackerDisplayDuration()
end
GeneralTrackerCtrl._OnMissionStateChange = HL.Method(HL.Any) << function(self, arg)
    local missionId, missionState = unpack(arg)
    GeneralTrackerCtrl.ResetMissionTrackerDisplayDuration()
end
GeneralTrackerCtrl._OnQuestStateChange = HL.Method(HL.Any) << function(self, arg)
    local questId, questState = unpack(arg)
    GeneralTrackerCtrl.ResetMissionTrackerDisplayDuration()
end
GeneralTrackerCtrl._OnQuestObjectiveUpdate = HL.Method(HL.Any) << function(self, arg)
    local questId = unpack(arg)
    GeneralTrackerCtrl.ResetMissionTrackerDisplayDuration()
end
GeneralTrackerCtrl._UpdateMissionTrackers = HL.Method() << function(self)
    if self:IsHide() then
        return
    end
    local missionHudOpen, missionHudCtrl = UIManager:IsOpen(PanelId.MissionHud)
    GeneralTrackerCtrl.missionTrackerDisplayDuration = GeneralTrackerCtrl.missionTrackerDisplayDuration + Time.deltaTime
    local inTopView = false
    if LuaSystemManager.facSystem.inTopView then
        inTopView = true
    end
    local trackDataChange = self.view.missionTrackerUpdate:UpdateMissionTrackers(missionHudOpen, inTopView, GeneralTrackerCtrl.missionTrackerDisplayDuration, GeneralTrackerCtrl.missionTrackerStartShowSignal)
    if trackDataChange then
        GeneralTrackerCtrl.ResetMissionTrackerDisplayDuration()
    end
    GeneralTrackerCtrl.missionTrackerStartShowSignal = 0
end
GeneralTrackerCtrl._UpdateCommonTrackers = HL.Method() << function(self)
    if self:IsHide() then
        return
    end
    self.m_commonTrackerData = self.m_commonTrackerData or {}
    local commonTrackingSystem = GameInstance.player.commonTrackingPoint
    local commonTrackingDataList = commonTrackingSystem:GetCommonTrackingPointDataForScene()
    local playerPos = GameUtil.playerPos
    for csData, csIndex in cs_pairs(commonTrackingDataList) do
        local data = self.m_commonTrackerData[LuaIndex(csIndex)] or {}
        data.worldPos = csData.relativePos + playerPos
        data.distance = csData.relativePos.magnitude
        data.styleType = csData.styleType
        data.showTrackingPoint = csData.showTrackingPoint
        self.m_commonTrackerData[LuaIndex(csIndex)] = data
    end
    local curCount = commonTrackingDataList.Count
    local oldCount = #self.m_commonTrackers
    if oldCount < curCount then
        for i = oldCount + 1, curCount do
            table.insert(self.m_commonTrackers, self.m_commonTrackerNodeCache:Get())
        end
    else
        for i = (oldCount - curCount), 1, -1 do
            local removeIndex = curCount + i
            local tracker = self.m_commonTrackers[removeIndex]
            self.m_commonTrackerNodeCache:Cache(tracker)
            self.m_commonTrackers[removeIndex] = nil
            self.m_commonTrackerData[removeIndex] = nil
        end
    end
    for i, data in ipairs(self.m_commonTrackerData) do
        local trackerNode = self.m_commonTrackers[i]
        if data.showTrackingPoint then
            self:_ShowCommonTrackerItem(data, trackerNode)
            self:_UpdateTrackerInfo(data, trackerNode)
        else
            self:_HideCommonTrackerItem(data, trackerNode)
        end
    end
end
GeneralTrackerCtrl._ShowCommonTrackerItem = HL.Method(HL.Table, HL.Any) << function(self, trackerData, trackerNode)
    trackerNode.blackboxTracker.gameObject:SetActiveIfNecessary(trackerData.styleType == CommonTrackingPointStyleType.Blackbox)
    trackerNode.campfireTracker.gameObject:SetActiveIfNecessary(trackerData.styleType == CommonTrackingPointStyleType.Campfire)
    trackerNode.commonTracker.gameObject:SetActiveIfNecessary(trackerData.styleType == CommonTrackingPointStyleType.Common)
    local trackerStyle = self:_GetTrackerStyleByType(trackerData, trackerNode)
    if trackerStyle.animationWrapper and trackerData.state ~= TRACKER_STATE_SHOW then
        trackerStyle.animationWrapper:PlayInAnimation()
    end
    trackerData.state = TRACKER_STATE_SHOW
end
GeneralTrackerCtrl._GetTrackerStyleByType = HL.Method(HL.Table, HL.Any).Return(HL.Any) << function(self, trackerData, trackerNode)
    local trackerStyle = trackerNode.blackboxTracker
    if trackerData.styleType == CommonTrackingPointStyleType.Blackbox then
        trackerStyle = trackerNode.blackboxTracker
    elseif trackerData.styleType == CommonTrackingPointStyleType.Common then
        trackerStyle = trackerNode.commonTracker
    elseif trackerData.styleType == CommonTrackingPointStyleType.Campfire then
        trackerStyle = trackerNode.campfireTracker
    end
    return trackerStyle
end
GeneralTrackerCtrl._UpdateTrackerInfo = HL.Method(HL.Table, HL.Any) << function(self, trackerData, trackerNode)
    local screenPos, isInside = UIUtils.objectPosToUI(trackerData.worldPos, self.uiCamera)
    local panelRect = self.m_rootTransform.rect
    local xRadius = self.view.config.ELLIPSE_X_RADIUS / STANDARD_HORIZONTAL_RESOLUTION * panelRect.width
    local yRadius = self.view.config.ELLIPSE_Y_RADIUS / STANDARD_VERTICAL_RESOLUTION * panelRect.height
    local uiPos, uiAngle, isOutBound = UIUtils.mapScreenPosToEllipseEdge(screenPos, xRadius, yRadius)
    local trackerStyle = self:_GetTrackerStyleByType(trackerData, trackerNode)
    trackerNode.rectTransform.anchoredPosition = uiPos
    trackerStyle.arrowRotator.localRotation = Quaternion.Euler(0, 0, uiAngle)
    trackerStyle.arrowRotator.gameObject:SetActiveIfNecessary(isOutBound)
    if trackerStyle.distanceTxt then
        local tooFar = trackerData.distance > TOO_FAR_DISTANCE
        local needShowDistance = not isOutBound and tooFar
        trackerStyle.distanceTxt.gameObject:SetActiveIfNecessary(needShowDistance)
        if needShowDistance then
            trackerStyle.distanceTxt.text = string.format("%dM", math.floor(trackerData.distance))
        end
    end
end
GeneralTrackerCtrl._HideCommonTrackerItem = HL.Method(HL.Table, HL.Any) << function(self, trackerData, trackerNode)
    if trackerData.state ~= TRACKER_STATE_HIDE then
        local doAction = function()
            trackerNode.blackboxTracker.gameObject:SetActiveIfNecessary(false)
            trackerNode.campfireTracker.gameObject:SetActiveIfNecessary(false)
            trackerNode.commonTracker.gameObject:SetActiveIfNecessary(false)
        end
        local trackerStyle = self:_GetTrackerStyleByType(trackerData, trackerNode)
        if trackerStyle.animationWrapper then
            trackerStyle.animationWrapper:PlayOutAnimation(doAction)
        else
            doAction()
        end
    end
    trackerData.state = TRACKER_STATE_HIDE
end
HL.Commit(GeneralTrackerCtrl)