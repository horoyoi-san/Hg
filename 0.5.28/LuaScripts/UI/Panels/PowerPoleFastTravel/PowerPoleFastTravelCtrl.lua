local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.PowerPoleFastTravel
PowerPoleFastTravelCtrl = HL.Class('PowerPoleFastTravelCtrl', uiCtrl.UICtrl)
PowerPoleFastTravelCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.TRAVEL_POLE_TRAVEL_ON_ENTER] = 'OnEnterFinish', [MessageConst.TRAVEL_POLE_TRAVEL_ON_REACH] = 'OnReach', [MessageConst.TRAVEL_POLE_TRAVEL_ON_REACH_REFRESH] = 'OnReachRefresh', [MessageConst.TRAVEL_POLE_FAST_EXIT] = 'OnTravelPoleExitFast', [MessageConst.TRAVEL_POLE_SHOW_QTE] = 'ShowQte', [MessageConst.TRAVEL_POLE_HIDE_QTE] = 'HideQte', [MessageConst.TRAVEL_POLE_UPDATE_QTE_COUNTDOWN] = 'UpdateQteCountdown', [MessageConst.TRAVEL_POLE_TRIGGER_DEFAULT_NEXT] = 'TriggerDefaultNext', [MessageConst.TRAVEL_POLE_TRIGGER_CLOSE_PANEL] = 'TriggerClosePanel', [MessageConst.P_ON_COMMON_BACK_CLICKED] = '_OnButtonLeave', }
PowerPoleFastTravelCtrl.m_targetLogicIdList = HL.Field(HL.Userdata)
PowerPoleFastTravelCtrl.m_trackers = HL.Field(HL.Table)
PowerPoleFastTravelCtrl.m_trackersCache = HL.Field(HL.Table)
PowerPoleFastTravelCtrl.m_currentLogicId = HL.Field(HL.Any) << 0
PowerPoleFastTravelCtrl.m_currentIsUpgraded = HL.Field(HL.Boolean) << false
PowerPoleFastTravelCtrl.m_currentAimingLogicId = HL.Field(HL.Any) << 0
PowerPoleFastTravelCtrl.m_lateTickKey = HL.Field(HL.Number) << -1
PowerPoleFastTravelCtrl.m_isMoving = HL.Field(HL.Boolean) << false
PowerPoleFastTravelCtrl.m_nextDestinationLogicId = HL.Field(HL.Any) << 0
PowerPoleFastTravelCtrl.m_buttonConfirmTimer = HL.Field(HL.Number) << -1
PowerPoleFastTravelCtrl.m_qteToggled = HL.Field(HL.Boolean) << false
PowerPoleFastTravelCtrl.m_allowLeave = HL.Field(HL.Boolean) << false
PowerPoleFastTravelCtrl.m_enterFinished = HL.Field(HL.Boolean) << false
PowerPoleFastTravelCtrl.m_waitHideQte = HL.Field(HL.Boolean) << false
PowerPoleFastTravelCtrl.m_isQteClickAnimPlaying = HL.Field(HL.Boolean) << false
PowerPoleFastTravelCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.nodeConfirm.gameObject:SetActiveIfNecessary(false)
    self.view.buttonConfirm.interactable = false
    self.view.buttonConfirm.onClick:AddListener(function()
        self:_OnConfirmButton()
    end)
    self.view.buttonLink.onClick:AddListener(function()
        self:_OnButtonLink()
    end)
    self.view.buttonLeave.onClick:AddListener(function()
        self:_OnButtonLeave()
    end)
    self.view.buttonQte.onClick:AddListener(function()
        self:_OnButtonQte()
    end)
    self:BindInputPlayerAction("common_open_map", function()
    end)
    self.view.hintBar.gameObject:SetActiveIfNecessary(false)
    self.view.qteNode.gameObject:SetActiveIfNecessary(false)
    self.view.nodeSetDefaultNext.gameObject:SetActiveIfNecessary(false)
    self.view.nodeLeave.gameObject:SetActiveIfNecessary(false)
    self.view.buttonLeave.interactable = false
    self.m_enterFinished = false
    self.m_trackers = {}
    self.m_trackersCache = {}
    self.m_targetLogicIdList = nil
    self.view.tracker.gameObject:SetActive(false)
    self.m_lateTickKey = LuaUpdate:Add("LateTick", function(deltaTime)
        self:_UpdateTrackers()
    end)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId }, { "fac_fast_travel_cam_orbit" })
    self:_InitFastTravelPanel(arg)
end
PowerPoleFastTravelCtrl.OnEnterFinish = HL.Method() << function(self)
    self.m_enterFinished = true
    self.view.hintBar.gameObject:SetActiveIfNecessary(true)
    self.view.nodeConfirm.gameObject:SetActiveIfNecessary(true)
    self.m_allowLeave = GameInstance.world.gameMechManager.travelPoleBrain:GetTravelPoleAllowLeave(self.m_currentLogicId)
    self.view.nodeLeave.gameObject:SetActiveIfNecessary(self.m_allowLeave)
end
PowerPoleFastTravelCtrl.OnReach = HL.Method() << function(self)
    AudioAdapter.PostEvent("au_ui_travel_pole_pause")
    self.view.hintBar.gameObject:SetActiveIfNecessary(true)
    self.m_isMoving = false
    self.m_qteToggled = false
    self.m_currentLogicId = self.m_nextDestinationLogicId
    self.m_currentIsUpgraded = GameInstance.world.gameMechManager.travelPoleBrain:CheckTravelPoleIsUpgradedByLid(self.m_currentLogicId)
    self.m_nextDestinationLogicId = 0
    self.view.nodeConfirm.gameObject:SetActiveIfNecessary(false)
    self.m_allowLeave = GameInstance.world.gameMechManager.travelPoleBrain:GetTravelPoleAllowLeave(self.m_currentLogicId)
    self.view.nodeLeave.gameObject:SetActiveIfNecessary(self.m_allowLeave)
    self.m_targetLogicIdList = GameInstance.world.gameMechManager.travelPoleBrain:GetLinkedTravelPoleInfoList(self.m_currentLogicId)
end
PowerPoleFastTravelCtrl.OnReachRefresh = HL.Method() << function(self)
    self.m_targetLogicIdList = GameInstance.world.gameMechManager.travelPoleBrain:GetLinkedTravelPoleInfoList(self.m_currentLogicId)
end
PowerPoleFastTravelCtrl.OnTravelPoleExitFast = HL.Method() << function(self)
    AudioAdapter.PostEvent("au_ui_travel_pole_stop")
    if PhaseManager:IsOpen(PhaseId.PowerPoleFastTravel) and PhaseManager:GetTopPhaseId() == PhaseId.PowerPoleFastTravel then
        PhaseManager:PopPhase(PhaseId.PowerPoleFastTravel)
    end
end
PowerPoleFastTravelCtrl.ShowQte = HL.Method() << function(self)
    self.view.qteNode.gameObject:SetActiveIfNecessary(true)
end
PowerPoleFastTravelCtrl.HideQte = HL.Method() << function(self)
    if self.m_isQteClickAnimPlaying then
        self.m_waitHideQte = true
    else
        self:_PlayQteOutAnimAndHide()
    end
end
PowerPoleFastTravelCtrl.UpdateQteCountdown = HL.Method(HL.Table) << function(self, args)
    local value = unpack(args)
    self.view.qteCountdown.fillAmount = value
end
PowerPoleFastTravelCtrl.TriggerDefaultNext = HL.Method(HL.Table) << function(self, args)
    local defaultNextLid = unpack(args)
    self:_BeginTravel(defaultNextLid)
end
PowerPoleFastTravelCtrl._InitFastTravelPanel = HL.Method(HL.Table) << function(self, args)
    local poleLogicId = unpack(args)
    self.m_isMoving = false
    self.m_currentLogicId = poleLogicId
    self.m_currentIsUpgraded = GameInstance.world.gameMechManager.travelPoleBrain:CheckTravelPoleIsUpgradedByLid(self.m_currentLogicId)
    AudioAdapter.PostEvent("au_ui_travel_pole_transfer")
    self.m_targetLogicIdList = GameInstance.world.gameMechManager.travelPoleBrain:GetLinkedTravelPoleInfoList(self.m_currentLogicId)
end
PowerPoleFastTravelCtrl._UpdateTrackers = HL.Method() << function(self)
    if self.m_targetLogicIdList == nil then
        return
    end
    local targetScrPosDict = {}
    local targetDistanceDict = {}
    local targetIconStatusDict = {}
    local targetStatusDict = {}
    local targetIsHighlightedDict = {}
    local targetLineDict = {}
    local logicIdList = {}
    local mainCharacterPos = GameInstance.world.gameMechManager.travelPoleBrain.handRailPos
    for _, linkInfo in pairs(self.m_targetLogicIdList) do
        if linkInfo.entity.isValid then
            local screenPos, isInside = UIUtils.objectPosToUI(linkInfo.targetPos, self.uiCamera)
            table.insert(targetScrPosDict, screenPos)
            table.insert(targetDistanceDict, linkInfo.targetPos - mainCharacterPos)
            table.insert(targetIconStatusDict, GameInstance.world.gameMechManager.travelPoleBrain:GetTravelPoleIcon(self.m_currentLogicId, linkInfo.logicId))
            table.insert(targetStatusDict, GameInstance.world.gameMechManager.travelPoleBrain:GetTravelPoleStatus(self.m_currentLogicId, linkInfo.logicId))
            table.insert(targetIsHighlightedDict, false)
            if linkInfo.line == nil then
                table.insert(targetLineDict, 0)
            else
                table.insert(targetLineDict, linkInfo.line)
            end
            table.insert(logicIdList, linkInfo.logicId)
        end
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
    local nearestIndex = -1
    local nearestDistance = 99999999
    for i = 1, #targetScrPosDict do
        if self.m_trackers[i].tracker.allowToHighlight then
            local screenPos = targetScrPosDict[i]
            local distToCenter = screenPos.x * screenPos.x + screenPos.y * screenPos.y
            if distToCenter < nearestDistance then
                nearestIndex = i
                nearestDistance = distToCenter
            end
        end
    end
    local newFocus = false
    if self.m_isMoving then
        self.view.nodeConfirm.gameObject:SetActiveIfNecessary(false)
        self.view.buttonConfirm.interactable = false
        self.m_currentAimingLogicId = 0
    else
        if self.m_enterFinished then
            self.view.nodeConfirm.gameObject:SetActiveIfNecessary(true)
            self.view.buttonConfirm.interactable = true
        end
        if nearestIndex > 0 and nearestDistance < 600000 then
            targetIsHighlightedDict[nearestIndex] = true
            local newAniming = logicIdList[nearestIndex]
            if newAniming ~= self.m_currentAimingLogicId then
                newFocus = true
                AudioAdapter.PostEvent("au_ui_travel_pole_correct")
            end
            self.m_currentAimingLogicId = newAniming
        else
            self.m_currentAimingLogicId = 0
        end
    end
    for i = 1, #targetScrPosDict do
        local item = self.m_trackers[i]
        if item then
            local uiPos, uiAngle, isOutBound = UIUtils.mapScreenPosToEllipseEdge(targetScrPosDict[i], self.view.config.ELLIPSE_X_RADIUS, self.view.config.ELLIPSE_Y_RADIUS)
            local isHighlighted = targetIsHighlightedDict[i]
            if self.m_isMoving then
                if self.m_nextDestinationLogicId == logicIdList[i] then
                    isHighlighted = true
                else
                    isHighlighted = false
                end
            end
            item.tracker:UpdatePosition(uiPos, uiAngle, isOutBound)
            item.tracker:UpdateDistance(targetDistanceDict[i])
            item.tracker:UpdateStatus(targetStatusDict[i])
            item.tracker:UpdateIsHighlighted(isHighlighted)
            if targetLineDict[i] ~= 0 then
                targetLineDict[i]:SetStatus(targetStatusDict[i])
                targetLineDict[i]:SetIsHighlighted(isHighlighted)
            end
            item.tracker:UpdateIconStatus(targetIconStatusDict[i])
            if isHighlighted and newFocus then
                item.tracker:PlayFocus()
            end
        end
    end
    if GameInstance.world.gameMechManager.travelPoleBrain.isFactoryTravelPole then
        local aimingIsUpgared = false
        if self.m_currentAimingLogicId ~= 0 then
            aimingIsUpgared = GameInstance.world.gameMechManager.travelPoleBrain:CheckTravelPoleIsUpgradedByLid(self.m_currentAimingLogicId)
        end
        local showDefaultNext = self.view.buttonConfirm.interactable and self.m_currentIsUpgraded and aimingIsUpgared
        self.view.nodeSetDefaultNext.gameObject:SetActiveIfNecessary(showDefaultNext)
    end
    if self.m_isMoving or self.m_qteToggled then
        self.view.nodeConfirm.gameObject:SetActiveIfNecessary(false)
        self.view.buttonConfirm.interactable = false
        self.view.nodeLeave.gameObject:SetActiveIfNecessary(false)
        self.view.buttonLeave.interactable = false
    else
        if self.m_enterFinished then
            self.view.nodeLeave.gameObject:SetActiveIfNecessary(self.m_allowLeave)
            self.view.buttonLeave.interactable = true
        end
    end
end
PowerPoleFastTravelCtrl._CreateNewTracker = HL.Method().Return(HL.Table) << function(self)
    local cacheCount = #self.m_trackersCache
    if cacheCount > 0 then
        local cacheObj = self.m_trackersCache[cacheCount]
        cacheObj.obj:SetActive(true)
        table.remove(self.m_trackersCache, cacheCount)
        return cacheObj
    end
    local obj = CSUtils.CreateObject(self.view.tracker.gameObject, self.view.trackerParent)
    obj:SetActive(true)
    local item = {}
    item.obj = obj
    item.tracker = obj:GetComponent(typeof(CS.Beyond.UI.UIPowerPoleFastTravelTracker))
    return item
end
PowerPoleFastTravelCtrl._OnConfirmButton = HL.Method() << function(self)
    if not GameInstance.world.gameMechManager.travelPoleBrain.allowButtonBeginTravel then
        return
    end
    if self.m_isMoving then
        return
    end
    self.view.buttonConfirmAnimationWrapper:PlayWithTween("polefasttravelbuttonconfirm_in")
    self:_BeginTravel(self.m_currentAimingLogicId)
end
PowerPoleFastTravelCtrl._BeginTravel = HL.Method(HL.Any) << function(self, nextLogicId)
    if not GameInstance.world.gameMechManager.travelPoleBrain.allowBeginTravel then
        return
    end
    if not nextLogicId or nextLogicId <= 0 then
        if GameInstance.world.gameMechManager.travelPoleBrain.isFactoryTravelPole then
            self:Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_FAST_TRAVEL_NO_TARGET_TOAST)
        end
        return
    end
    if not GameInstance.world.gameMechManager.travelPoleBrain:BeginTravelToStuckTest(self.m_currentLogicId, nextLogicId) then
        return
    end
    if nextLogicId ~= 0 then
        for iCs, linkInfo in pairs(self.m_targetLogicIdList) do
            local i = iCs + 1
            local item = self.m_trackers[i]
            if item ~= nil then
                if linkInfo.entity.isValid then
                    if linkInfo.logicId ~= nextLogicId then
                        item.tracker:UpdateIsHighlighted(false)
                        if linkInfo.line ~= nil then
                            linkInfo.line:SetIsHighlighted(false)
                        end
                    else
                        item.tracker:UpdateIsHighlighted(true)
                        if linkInfo.line ~= nil then
                            linkInfo.line:SetIsHighlighted(true)
                        end
                    end
                end
            end
        end
        AudioAdapter.PostEvent("au_ui_travel_pole_confirm_start")
        self.view.hintBar.gameObject:SetActiveIfNecessary(false)
        GameInstance.world.gameMechManager.travelPoleBrain:BeginTravelTo(nextLogicId)
        self.m_targetLogicIdList = GameInstance.world.gameMechManager.travelPoleBrain:GetLinkedTravelPoleInfoList(self.m_currentLogicId)
        self.m_nextDestinationLogicId = nextLogicId
        self.m_isMoving = true
        self.m_qteToggled = false
    end
end
PowerPoleFastTravelCtrl._OnButtonLink = HL.Method() << function(self)
    if self.m_isMoving ~= true and self.m_currentAimingLogicId ~= nil then
        local result = GameInstance.world.gameMechManager.travelPoleBrain:SetDefaultNext(self.m_currentAimingLogicId)
        if result == 2 then
            self:Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_TRAVEL_POLE_RECURSIVE_LINK)
        end
    end
end
PowerPoleFastTravelCtrl._OnButtonQte = HL.Method() << function(self)
    if not GameInstance.world.gameMechManager.travelPoleBrain.allowButtonQte then
        return
    end
    GameInstance.world.gameMechManager.travelPoleBrain:TriggerQte(self.m_nextDestinationLogicId)
    self.m_isQteClickAnimPlaying = true
    self.view.qteAnimationWrapper:PlayWithTween("polefasttravelbuttonqte_in", function()
        self.m_isQteClickAnimPlaying = false
        if self.m_waitHideQte then
            self:_PlayQteOutAnimAndHide()
            self.m_waitHideQte = false
        end
    end)
    self.m_qteToggled = true
end
PowerPoleFastTravelCtrl._OnButtonLeave = HL.Method() << function(self)
    if not GameInstance.world.gameMechManager.travelPoleBrain.allowButtonLeave then
        return
    end
    if self.m_currentAimingLogicId ~= 0 and self.m_targetLogicIdList ~= nil then
        for iCs, linkInfo in pairs(self.m_targetLogicIdList) do
            if linkInfo.entity.isValid then
                local item = self.m_trackers[iCs + 1]
                item.tracker:UpdateIsHighlighted(false)
                if linkInfo.line ~= nil then
                    linkInfo.line:SetIsHighlighted(false)
                end
            end
        end
    end
    AudioAdapter.PostEvent("au_ui_travel_pole_end")
    GameInstance.world.gameMechManager.travelPoleBrain:ExitTravelMode(self.m_currentLogicId)
end
PowerPoleFastTravelCtrl.TriggerClosePanel = HL.Method() << function(self)
    if PhaseManager:IsOpen(PhaseId.PowerPoleFastTravel) and PhaseManager:GetTopPhaseId() == PhaseId.PowerPoleFastTravel then
        PhaseManager:PopPhase(PhaseId.PowerPoleFastTravel)
    end
end
PowerPoleFastTravelCtrl._PlayQteOutAnimAndHide = HL.Method() << function(self)
    self.view.qteAnimationWrapper:PlayWithTween("polefasttravelbuttonqte_out", function()
        self.view.qteNode.gameObject:SetActiveIfNecessary(false)
    end)
end
PowerPoleFastTravelCtrl.OnClose = HL.Override() << function(self)
    LuaUpdate:Remove(self.m_lateTickKey)
    self:Notify(MessageConst.ON_EXIT_TRAVEL_MODE)
end
HL.Commit(PowerPoleFastTravelCtrl)