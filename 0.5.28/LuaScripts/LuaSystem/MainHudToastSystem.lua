local LuaSystemBase = require_ex('LuaSystem/LuaSystemBase')
MainHudToastSystem = HL.Class('MainHudToastSystem', LuaSystemBase.LuaSystemBase)
MainHudToastSystem._InitConfigs = HL.Method() << function(self)
    self.configs = { DashBarUpgrade = { order = -1, needWait = true, }, FacTechPointGained = { order = 1, needWait = true, }, CenterRewards = { order = 2, needWait = true, finishWhenInterrupt = true, }, AdventureLevelUp = { order = 3, needWait = true, finishWhenInterrupt = true, }, PuzzlePickup = { order = 5, needWait = true, finishWhenInterrupt = true, }, ImportantReward = { order = 6, needWait = true, }, MapRegionToast = { order = 98, needWait = true, finishWhenInterrupt = true, }, SpaceshipHudTips = { order = 99, needWait = true, }, GetItemToast = { order = 100, needWait = false, }, FirstGotItem = { order = 100, needWait = false, }, UnlockPRTS = { order = 100, needWait = false, }, }
    for k, v in pairs(self.configs) do
        v.name = k
    end
end
MainHudToastSystem.m_pendingRequests = HL.Field(HL.Table)
MainHudToastSystem.configs = HL.Field(HL.Table)
MainHudToastSystem.m_nextRequestId = HL.Field(HL.Number) << 1
MainHudToastSystem.m_isShowing = HL.Field(HL.Boolean) << false
MainHudToastSystem.m_tryStartToastTimerId = HL.Field(HL.Number) << -1
MainHudToastSystem.m_ignoreMissionAni = HL.Field(HL.Boolean) << false
MainHudToastSystem.MainHudToastSystem = HL.Constructor() << function(self)
    self:_InitConfigs()
    self.m_pendingRequests = {}
    self:RegisterMessage(MessageConst.ON_ONE_MAIN_HUD_TOAST_FINISH, function(type)
        self:OnOneMainHudToastFinish(type)
    end)
    self:RegisterMessage(MessageConst.ON_IN_MAIN_HUD_CHANGED, function(arg)
        local inMainHud = unpack(arg)
        if inMainHud then
            self:_TryAddStartToastTimer()
        else
            self:Interrupt()
        end
    end)
    self:RegisterMessage(MessageConst.ON_COMPLETE_MISSION_ANIM_START, function()
        self:_TryAddStartToastTimer(true)
    end)
    self:RegisterMessage(MessageConst.ON_FINISH_MISSION_HUD_ANIM, function()
        self:_TryAddStartToastTimer()
    end)
    self:RegisterMessage(MessageConst.ON_GUIDE_STOPPED, function(arg)
        local isForce = unpack(arg)
        if isForce then
            self:_TryAddStartToastTimer()
        end
    end)
    self:RegisterMessage(MessageConst.ON_ONE_COMMON_TASK_PANEL_FINISH, function()
        self:_TryAddStartToastTimer()
    end)
    self:RegisterMessage(MessageConst.ON_COMMON_BLEND_IN, function()
        self:Interrupt()
    end)
    self:RegisterMessage(MessageConst.ON_COMMON_BLEND_OUT, function()
        self:_TryAddStartToastTimer()
    end)
    self:RegisterMessage(MessageConst.COMMON_START_BLOCK_MAIN_HUD_TOAST, function()
        self:Interrupt()
    end)
    self:RegisterMessage(MessageConst.COMMON_END_BLOCK_MAIN_HUD_TOAST, function()
        self:_TryAddStartToastTimer()
    end)
    self:RegisterMessage(MessageConst.ON_LEAVE_TOWER_DEFENSE_DEFENDING_PHASE, function()
        self:Interrupt()
    end)
    self:RegisterMessage(MessageConst.ON_TOWER_DEFENSE_LEVEL_REWARDS_FINISHED, function()
        self:_TryAddStartToastTimer()
    end)
end
MainHudToastSystem.AddRequest = HL.Method(HL.String, HL.Function) << function(self, type, action)
    logger.info("MainHudToastSystem.AddRequest", type)
    local requestId = self.m_nextRequestId
    self.m_nextRequestId = self.m_nextRequestId + 1
    local cfg = self.configs[type]
    local request = { id = requestId, type = type, action = action, order = cfg.order, finishWhenInterrupt = cfg.finishWhenInterrupt, }
    table.insert(self.m_pendingRequests, request)
    table.sort(self.m_pendingRequests, Utils.genSortFunction({ "order", "id" }, true))
    self:_TryAddStartToastTimer()
end
MainHudToastSystem.GetCurShowingRequest = HL.Method().Return(HL.Opt(HL.Table)) << function(self)
    return self.m_pendingRequests[1]
end
MainHudToastSystem.GetCurShowingRequestType = HL.Method().Return(HL.Opt(HL.String)) << function(self)
    local request = self.m_pendingRequests[1]
    if request then
        return request.type
    end
end
MainHudToastSystem._TryAddStartToastTimer = HL.Method(HL.Opt(HL.Boolean)) << function(self, ignoreMissionAni)
    if self.m_isShowing or self.m_pendingRequests[1] == nil then
        logger.info("MainHudToastSystem._AddStartToastTimer Skipped")
        return
    end
    if ignoreMissionAni then
        self.m_ignoreMissionAni = true
    end
    if self.m_tryStartToastTimerId > 0 then
        logger.info("MainHudToastSystem._AddStartToastTimer Duplicated")
        return
    end
    logger.info("MainHudToastSystem._AddStartToastTimer Succ")
    self.m_tryStartToastTimerId = self:_StartTimer(0, function()
        self:_TryStartToast()
    end)
end
MainHudToastSystem._TryStartToast = HL.Method() << function(self)
    logger.info("MainHudToastSystem._TryStartToast")
    self.m_tryStartToastTimerId = -1
    if GameInstance.player.guide.isInForceGuide and not Utils.isInBlackbox() then
        return
    end
    if not GameInstance.world.inMainHud then
        return
    end
    if GameInstance.player.inventory.isProcessingRewardToastData then
        return
    end
    if not self.m_ignoreMissionAni and UIManager:IsShow(PanelId.MissionHud) and GameInstance.player.mission:HasMissionCompleteAnimInList() then
        return
    end
    if UIManager:IsShow(PanelId.MissionCompletePop) then
        return
    end
    if LuaSystemManager.commonTaskTrackSystem:HasRequest() then
        return
    end
    if CameraManager:IsCommonTempControllerActive() then
        return
    end
    if Utils.isInSettlementDefense() then
        return
    end
    self.m_isShowing = true
    self.m_ignoreMissionAni = false
    self:_StartFirstRequest()
end
MainHudToastSystem._StartFirstRequest = HL.Method() << function(self)
    local request = self.m_pendingRequests[1]
    request.order = math.mininteger
    local cfg = self.configs[request.type]
    logger.info("MainHudToastSystem._StartFirstRequest", request.type, request)
    request.action()
    if not cfg.needWait then
        self:OnOneMainHudToastFinish(request.type)
    end
end
MainHudToastSystem._CheckAllMainHudToastFinish = HL.Method() << function(self)
    if self.m_pendingRequests[1] ~= nil then
        return
    end
    Notify(MessageConst.ALL_MAIN_HUD_TOAST_FINISH)
end
MainHudToastSystem.OnOneMainHudToastFinish = HL.Method(HL.String) << function(self, type)
    logger.info("MainHudToastSystem.OnOneMainHudToastFinish", type)
    if not self.m_isShowing then
        logger.error("OnOneMainHudToastFinish: Not isShowing", type)
        return
    end
    local request = self.m_pendingRequests[1]
    if request.type ~= type then
        logger.error("OnOneMainHudToastFinish: Type Not Match", type, request)
        return
    end
    table.remove(self.m_pendingRequests, 1)
    if self.m_pendingRequests[1] then
        self:_StartFirstRequest()
    else
        self.m_isShowing = false
        logger.info("MainHudToastSystem showing finished")
        self:_CheckAllMainHudToastFinish()
    end
end
MainHudToastSystem.Interrupt = HL.Method() << function(self)
    self.m_tryStartToastTimerId = self:_ClearTimer(self.m_tryStartToastTimerId)
    if not self.m_isShowing then
        return
    end
    logger.info("MainHudToastSystem.Interrupt")
    self.m_isShowing = false
    local request = self.m_pendingRequests[1]
    Notify(MessageConst.INTERRUPT_MAIN_HUD_TOAST)
    if request.finishWhenInterrupt then
        table.remove(self.m_pendingRequests, 1)
        self:_CheckAllMainHudToastFinish()
    end
end
MainHudToastSystem.RemoveToastsOfType = HL.Method(HL.String) << function(self, toastType)
    local needRestart = false
    local requestCnt = #self.m_pendingRequests
    if requestCnt == 0 then
        return
    end
    if self.m_isShowing then
        local currentToast = self.m_pendingRequests[1]
        if currentToast.type == toastType then
            if currentToast.finishWhenInterrupt then
                requestCnt = requestCnt - 1
            end
            self:Interrupt()
            needRestart = true
        end
    end
    local reservedCnt = 0
    local newPendingRequests = {}
    for i = 1, requestCnt do
        if self.m_pendingRequests[i].type ~= toastType then
            reservedCnt = reservedCnt + 1
            newPendingRequests[reservedCnt] = self.m_pendingRequests[i]
        end
    end
    self.m_pendingRequests = newPendingRequests
    if needRestart then
        self:_TryAddStartToastTimer()
    end
end
HL.Commit(MainHudToastSystem)
return MainHudToastSystem