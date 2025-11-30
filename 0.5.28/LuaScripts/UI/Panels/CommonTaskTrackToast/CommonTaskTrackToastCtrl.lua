local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonTaskTrackToast
local ModeType2Toast = { [GEnums.GameModeType.Dungeon] = { Start = "instancesStartToast", Finish = "instancesFinishToast", Fail = "taskFailToast", }, [GEnums.GameModeType.WorldChallenge] = { Start = "taskStartToast", Finish = "taskFinishToast", Fail = "taskFailToast", }, }
CommonTaskTrackToastCtrl = HL.Class('CommonTaskTrackToastCtrl', uiCtrl.UICtrl)
CommonTaskTrackToastCtrl.m_countDownTickId = HL.Field(HL.Number) << -1
CommonTaskTrackToastCtrl.m_showingToastCor = HL.Field(HL.Thread)
CommonTaskTrackToastCtrl.s_messages = HL.StaticField(HL.Table) << {}
CommonTaskTrackToastCtrl.OnShowCommonTaskCountdownToast = HL.StaticMethod(HL.Any) << function(args)
    LuaSystemManager.commonTaskTrackSystem:AddRequest("TrackStartCountdown", function()
        local ctrl = CommonTaskTrackToastCtrl.AutoOpen(PANEL_ID, nil, true)
        if ctrl == nil then
            return
        end
        ctrl:ShowCountdownToast(args)
    end)
end
CommonTaskTrackToastCtrl.OnShowCommonTaskStartToast = HL.StaticMethod(HL.Any) << function(args)
    LuaSystemManager.commonTaskTrackSystem:AddRequest("TrackStartToast", function()
        local ctrl = CommonTaskTrackToastCtrl.AutoOpen(PANEL_ID, nil, true)
        if ctrl == nil then
            return
        end
        ctrl:ShowTaskStartToast(args, function()
            Notify(MessageConst.ON_ONE_COMMON_TASK_PANEL_FINISH, "TrackStartToast")
        end)
    end, function()
        UIManager:Close(PANEL_ID)
    end)
end
CommonTaskTrackToastCtrl.OnShowCommonTaskFinishToast = HL.StaticMethod(HL.Any) << function(args)
    LuaSystemManager.commonTaskTrackSystem:AddRequest("TrackEndToastNW", function()
        local ctrl = CommonTaskTrackToastCtrl.AutoOpen(PANEL_ID, nil, true)
        if ctrl == nil then
            return
        end
        ctrl:ShowTaskFinishToast(args, function()
            Notify(MessageConst.ON_ONE_COMMON_TASK_PANEL_FINISH, "TrackEndToastNW")
        end)
    end, function()
        UIManager:Close(PANEL_ID)
    end)
end
CommonTaskTrackToastCtrl.OnShowCommonTaskFailToast = HL.StaticMethod(HL.Any) << function(args)
    LuaSystemManager.commonTaskTrackSystem:AddRequest("TrackEndToastNW", function()
        local ctrl = CommonTaskTrackToastCtrl.AutoOpen(PANEL_ID, nil, true)
        if ctrl == nil then
            return
        end
        ctrl:ShowTaskFailToast(args, function()
            Notify(MessageConst.ON_ONE_COMMON_TASK_PANEL_FINISH, "TrackEndToastNW")
        end)
    end, function()
        UIManager:Close(PANEL_ID)
    end)
end
CommonTaskTrackToastCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.countdownToast.gameObject:SetActiveIfNecessary(false)
    self.view.taskStartToast.gameObject:SetActiveIfNecessary(false)
    self.view.taskFinishToast.gameObject:SetActiveIfNecessary(false)
    self.view.taskFailToast.gameObject:SetActiveIfNecessary(false)
    self.view.instancesFinishToast.gameObject:SetActiveIfNecessary(false)
    self.view.instancesStartToast.gameObject:SetActiveIfNecessary(false)
end
CommonTaskTrackToastCtrl.OnClose = HL.Override() << function(self)
    if self.m_countDownTickId ~= -1 then
        self.m_countDownTickId = LuaUpdate:Remove(self.m_countDownTickId)
    end
    if self.m_showingToastCor then
        self.m_showingToastCor = self:_ClearCoroutine(self.m_showingToastCor)
    end
end
CommonTaskTrackToastCtrl.ShowCountdownToast = HL.Method(HL.Any, HL.Opt(HL.Function)) << function(self, args, endFunc)
    self:Notify(MessageConst.ON_HUD_BTN_VISIBLE_CHANGE, { false })
    local countdownDuration, cb = unpack(args)
    local toast = self.view.countdownToast
    toast.gameObject:SetActiveIfNecessary(true)
    toast.contentTimeStart.gameObject:SetActiveIfNecessary(false)
    toast.contentTimeNumber.gameObject:SetActiveIfNecessary(false)
    local freq = 1
    local tickInterval = 1
    local leftTime = countdownDuration
    self.m_countDownTickId = LuaUpdate:Add("Tick", function(deltaTime)
        if TimeManagerInst.timeScale == 0 then
            return
        end
        tickInterval = tickInterval + deltaTime
        if tickInterval < freq then
            return
        end
        tickInterval = 0
        local showStart = leftTime <= 0
        if showStart then
            if leftTime == 0 then
                AudioAdapter.PostEvent("Au_UI_Toast_TaskTrack_CountdownToast_Start")
            end
        else
            toast.startNumberTxt.text = math.ceil(leftTime)
            AudioAdapter.PostEvent("Au_UI_Toast_TaskTrack_CountdownToast_Number")
        end
        toast.contentTimeStart.gameObject:SetActiveIfNecessary(showStart)
        toast.contentTimeNumber.gameObject:SetActiveIfNecessary(not showStart)
        toast.animation:SampleToInAnimationEnd()
        toast.animation:PlayInAnimation()
        if leftTime <= -1 then
            if cb ~= nil and not string.isEmpty(GameInstance.mode.curSubGameId) then
                cb()
            end
            if endFunc then
                endFunc()
            end
            toast.animation:PlayOutAnimation(function()
                self:Close()
            end)
            self.m_countDownTickId = LuaUpdate:Remove(self.m_countDownTickId)
            self:Notify(MessageConst.ON_HUD_BTN_VISIBLE_CHANGE, { true })
        end
        leftTime = leftTime - freq
    end)
end
CommonTaskTrackToastCtrl.ShowTaskStartToast = HL.Method(HL.Any, HL.Opt(HL.Function)) << function(self, args, endFunc)
    self:_RefreshToast("Start", args, endFunc)
    AudioAdapter.PostEvent("Au_UI_Toast_TaskTrack_TaskStartToast_Open")
end
CommonTaskTrackToastCtrl.ShowTaskFinishToast = HL.Method(HL.Any, HL.Opt(HL.Function)) << function(self, args, endFunc)
    self:_RefreshToast("Finish", args, endFunc)
    AudioAdapter.PostEvent("Au_UI_Toast_TaskTrack_TaskFinishToast_Open")
end
CommonTaskTrackToastCtrl.ShowTaskFailToast = HL.Method(HL.Any, HL.Opt(HL.Function)) << function(self, args, endFunc)
    self:_RefreshToast("Fail", args, endFunc)
    AudioAdapter.PostEvent("Au_UI_Toast_TaskTrack_TaskFailToast_Open")
end
CommonTaskTrackToastCtrl._RefreshToast = HL.Method(HL.String, HL.Any, HL.Opt(HL.Function)) << function(self, toastType, args, endFunc)
    self:Notify(MessageConst.ON_HUD_BTN_VISIBLE_CHANGE, { false })
    local instId = unpack(args)
    local taskTitle = ""
    local taskDesc = ""
    local hasTableData, gameMechanicData = Tables.gameMechanicTable:TryGetValue(instId)
    local hasSubGameData, subGameData = DataManager.subGameInstDataTable:TryGetValue(instId)
    if not hasSubGameData then
        logger.error("未找到s%玩法实例数据", instId)
        return
    end
    local toastTbl = ModeType2Toast[subGameData.modeType]
    local toastNode = self.view[toastTbl[toastType]]
    toastNode.gameObject:SetActiveIfNecessary(true)
    if toastType == "Start" then
        if hasTableData then
            taskTitle = gameMechanicData.gameName
            taskDesc = gameMechanicData.desc
        end
        if not subGameData.showDesc then
            taskDesc = ""
        end
    elseif toastType == "Finish" then
        local success, successInfoText = subGameData.successInfo:TryGetText()
        if success then
            taskTitle = successInfoText
        else
            taskTitle = Language.LUA_COMMON_TASK_TRACK_TOAST_SUCC_DESC
        end
    elseif toastType == "Fail" then
        local success, failInfoText = subGameData.failInfo:TryGetText()
        if success then
            taskTitle = failInfoText
        else
            taskTitle = Language.LUA_COMMON_TASK_TRACK_TOAST_FAIL_DESC
        end
    end
    local descEmpty = string.isEmpty(taskDesc)
    if not descEmpty then
        toastNode.taskTxt.text = taskDesc
    end
    toastNode.taskTxt.gameObject:SetActive(not descEmpty)
    toastNode.titleTxt.text = taskTitle
    self.m_showingToastCor = self:_StartCoroutine(function()
        local inAnimLength = toastNode.animation:GetInClipLength()
        toastNode.animation:PlayInAnimation()
        coroutine.wait(inAnimLength)
        local outAnimLength = toastNode.animation:GetOutClipLength()
        toastNode.animation:PlayOutAnimation()
        coroutine.wait(outAnimLength)
        self:Close()
        self:Notify(MessageConst.ON_HUD_BTN_VISIBLE_CHANGE, { true })
        if endFunc then
            endFunc()
        end
    end)
end
HL.Commit(CommonTaskTrackToastCtrl)