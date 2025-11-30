local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonTaskTrackCountdown
local Component = { Countdown = 1, Counting = 2, }
CommonTaskTrackCountdownCtrl = HL.Class('CommonTaskTrackCountdownCtrl', uiCtrl.UICtrl)
CommonTaskTrackCountdownCtrl.m_countDownTickId = HL.Field(HL.Number) << -1
CommonTaskTrackCountdownCtrl.m_isCountdownPause = HL.Field(HL.Boolean) << false
CommonTaskTrackCountdownCtrl.m_countingTickId = HL.Field(HL.Number) << -1
CommonTaskTrackCountdownCtrl.m_isCountingPause = HL.Field(HL.Boolean) << false
CommonTaskTrackCountdownCtrl.m_originalAnchoredPos = HL.Field(Vector2)
CommonTaskTrackCountdownCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_COMMON_TASK_COUNTDOWN_SWITCH_ON] = "OnCommonTaskCountdownSwitchOn", [MessageConst.ON_CLOSE_COMMON_TASK_COUNTDOWN] = "OnCloseCommonTaskCountdown", [MessageConst.ON_COMMON_TASK_COUNTING_SWITCH_ON] = "OnCommonTaskCountingSwitchOn", [MessageConst.ON_FINISH_COMMON_TASK_COUNTING] = "OnFinishCommonTaskCounting", [MessageConst.ON_ADD_HEAD_BAR] = 'OnAddHeadBar', [MessageConst.ON_REMOVE_HEAD_BAR] = 'OnRemoveHeadBar', }
CommonTaskTrackCountdownCtrl.OnShowCommonTaskCountdown = HL.StaticMethod(HL.Any) << function(args)
    local ctrl = CommonTaskTrackCountdownCtrl.AutoOpen(PANEL_ID, args, true)
    ctrl:ShowCountdown(args)
end
CommonTaskTrackCountdownCtrl.OnStartCommonTaskCounting = HL.StaticMethod() << function(args)
    local ctrl = CommonTaskTrackCountdownCtrl.AutoOpen(PANEL_ID, args, true)
    ctrl:StartCounting(args)
end
CommonTaskTrackCountdownCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_originalAnchoredPos = self.view.main.anchoredPosition
end
CommonTaskTrackCountdownCtrl.OnClose = HL.Override() << function(self)
    if self.m_countDownTickId > 0 then
        self.m_countDownTickId = LuaUpdate:Remove(self.m_countDownTickId)
    end
    if self.m_countingTickId > 0 then
        self.m_countingTickId = LuaUpdate:Remove(self.m_countingTickId)
    end
end
CommonTaskTrackCountdownCtrl._ToggleComponentOn = HL.Method(HL.Number) << function(self, component)
    self.view.countdown.gameObject:SetActiveIfNecessary(component == Component.Countdown)
    self.view.counting.gameObject:SetActiveIfNecessary(component == Component.Counting)
end
CommonTaskTrackCountdownCtrl._IsWorldFreeze = HL.Method().Return(HL.Boolean) << function(self)
    local isOpen, ctrl = UIManager:IsOpen(PanelId.CommonPopUp)
    return UIWorldFreezeManager:IsUIWorldFreeze() or isOpen and ctrl.m_timeScaleHandler > 0
end
CommonTaskTrackCountdownCtrl.ShowCountdown = HL.Method(HL.Any) << function(self, arg)
    self:_ToggleComponentOn(Component.Countdown)
    local countdownDurationMilli, expireTimestampMilli, cb = unpack(arg)
    local countdownDuration = countdownDurationMilli / 1000
    local curTimestamp = DateTimeUtils.GetCurrentTimestampBySeconds()
    local expireTimestamp = expireTimestampMilli and expireTimestampMilli / 1000 or curTimestamp + countdownDuration
    local curLeftTime = expireTimestamp - curTimestamp
    self.view.countdown.countDownTxt.text = UIUtils.getLeftTimeToSecondFull(curLeftTime)
    self.view.countdown.fill.fillAmount = curLeftTime / countdownDuration
    self.m_countDownTickId = LuaUpdate:Add("Tick", function(deltaTime)
        if self.m_isCountdownPause then
            return
        end
        if self:_IsWorldFreeze() then
            expireTimestamp = expireTimestamp + deltaTime
            return
        end
        local curTs = DateTimeUtils.GetCurrentTimestampBySeconds()
        local leftTime = math.max(expireTimestamp - curTs, 0)
        local countdownNode = self.view.countdown
        countdownNode.countDownTxt.text = UIUtils.getLeftTimeToSecondFull(leftTime)
        countdownNode.fill.fillAmount = leftTime / countdownDuration
        if expireTimestamp - curTs <= 0 then
            if cb then
                cb()
            end
            self.m_countDownTickId = LuaUpdate:Remove(self.m_countDownTickId)
            self:PlayAnimationOut(UIConst.PANEL_PLAY_ANIMATION_OUT_COMPLETE_ACTION_TYPE.Close)
        end
    end)
end
CommonTaskTrackCountdownCtrl.StartCounting = HL.Method(HL.Any) << function(self, arg)
    self:_ToggleComponentOn(Component.Counting)
    arg = arg or { DateTimeUtils.GetCurrentTimestampByMilliseconds() }
    local startCountingTimestampMilli = unpack(arg)
    local curCounting = (DateTimeUtils.GetCurrentTimestampByMilliseconds() - startCountingTimestampMilli) / 1000
    self.view.counting.countingTxt.text = UIUtils.getLeftTimeToSecondFull(curCounting)
    local tickInterval = 0
    self.m_countDownTickId = LuaUpdate:Add("Tick", function(deltaTime)
        if self.m_isCountdownPause then
            return
        end
        if self:_IsWorldFreeze() then
            return
        end
        tickInterval = tickInterval + deltaTime
        if tickInterval < UIConst.COMMON_UI_TIME_UPDATE_INTERVAL then
            return
        end
        tickInterval = 0
        curCounting = curCounting + UIConst.COMMON_UI_TIME_UPDATE_INTERVAL
        self.view.counting.countingTxt.text = UIUtils.getLeftTimeToSecondFull(curCounting)
    end)
end
CommonTaskTrackCountdownCtrl.OnCloseCommonTaskCountdown = HL.Method() << function(self)
    self:Close()
end
CommonTaskTrackCountdownCtrl.OnFinishCommonTaskCounting = HL.Method() << function(self)
    self:Close()
end
CommonTaskTrackCountdownCtrl.OnCommonTaskCountdownSwitchOn = HL.Method(HL.Any) << function(self, arg)
    local isOn = unpack(arg)
    self.m_isCountdownPause = not isOn
end
CommonTaskTrackCountdownCtrl.OnCommonTaskCountingSwitchOn = HL.Method(HL.Any) << function(self, arg)
    local isOn = unpack(arg)
    self.m_isCountingPause = not isOn
    self:_RefreshCountingTime()
end
CommonTaskTrackCountdownCtrl.OnAddHeadBar = HL.Method(HL.Table) << function(self, args)
    self:_StartCoroutine(function()
        local succ, ctrl = UIManager:IsOpen(PanelId.BattleBossInfo)
        if succ then
            self.view.main.position = ctrl:GetFollowPointPosition()
        end
    end)
end
CommonTaskTrackCountdownCtrl.OnRemoveHeadBar = HL.Method(HL.Table) << function(self, args)
    self.view.main.anchoredPosition = self.m_originalAnchoredPos
end
HL.Commit(CommonTaskTrackCountdownCtrl)