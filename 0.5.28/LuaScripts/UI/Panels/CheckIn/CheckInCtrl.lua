local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CheckIn
local PHASE_ID = PhaseId.CheckIn
CheckInCtrl = HL.Class('CheckInCtrl', uiCtrl.UICtrl)
CheckInCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_ACTIVITY_UPDATED] = 'OnActivityUpdated', [MessageConst.CHECK_IN_REWARD] = 'OnRewardInfo', [MessageConst.ON_LOGIN_CHECK_INTERRUPT] = 'OnInterrupt', [MessageConst.ON_LOGIN_CHECK_RESUME] = 'OnResume', }
local CHECK_IN_PANEL_STATE_NAME = { PART_ONE = "PartOne", PART_TWO = "PartTwo", }
local CHECK_IN_COLLECT_STATE_NAME = { LOCKED = "Locked", CAN_COLLECT = "CanCollect", COLLECTED = "Collected", }
local CHECK_IN_RARE_STATE_NAME = { NORMAL = "Normal", SPECIAL = "Special", }
local CHECK_IN_PANEL_ANIM_NAME = { SWITCH_TO_PART_ONE = "checkin_changeone", SWITCH_TO_PART_TWO = "checkin_changetwo" }
local CHECK_IN_BTN_ANIM_NAME = { CAN_COLLECT = "checkinitem_receive", COLLECTED = "checkinitem_done", SP_CAN_COLLECT = "checkinitemsp_receive", SP_COLLECTED = "checkinitemsp_done", }
CheckInCtrl.m_unlockedDays = HL.Field(HL.Number) << -1
CheckInCtrl.m_unlockedDaysOld = HL.Field(HL.Number) << -1
CheckInCtrl.m_rewardedDays = HL.Field(HL.Number) << -1
CheckInCtrl.m_rewardedDaysOld = HL.Field(HL.Number) << -1
CheckInCtrl.m_maxCheckInDay = HL.Field(HL.Number) << -1
CheckInCtrl.m_showingSecondPart = HL.Field(HL.Boolean) << false
CheckInCtrl.m_activity = HL.Field(CS.Beyond.Gameplay.CheckInActivity)
CheckInCtrl.m_checkInBtnCellGenFun1 = HL.Field(HL.Function)
CheckInCtrl.m_checkInBtnCellGenFun2 = HL.Field(HL.Function)
CheckInCtrl.m_previewCharInfo = HL.Field(CS.Beyond.Gameplay.CharInfo)
CheckInCtrl.m_enableEmptyRewardNode = HL.Field(HL.Boolean) << true
CheckInCtrl.m_audioBlocker = HL.Field(HL.Boolean) << false
CheckInCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_enableEmptyRewardNode = self.view.config.ENABLE_EMPTY_REWARD_NODE
    CheckInCtrl.s_performCloseCallback = true
    if args and not CheckInCtrl.s_loginArgs then
        CheckInCtrl.s_loginArgs = args
    end
    self.view.btnClose.onClick:AddListener(function()
        if CheckInCtrl.s_performCloseCallback and CheckInCtrl.s_loginArgs and CheckInCtrl.s_loginArgs.closeCallback then
            PhaseManager:PopPhase(PHASE_ID, function()
                CheckInCtrl.s_loginArgs.closeCallback()
                CheckInCtrl.s_performCloseCallback = false
                CheckInCtrl.s_loginArgs = nil
            end)
        else
            PhaseManager:PopPhase(PHASE_ID)
        end
    end)
    local activitySystem = GameInstance.player.activitySystem;
    self.m_activity = activitySystem:GetActivity(UIConst.CHECK_IN_CONST.CBT2_CHECK_IN_ID)
    self.m_unlockedDays = self.m_activity.loginDays
    self.m_unlockedDaysOld = self.m_unlockedDays
    self.m_rewardedDays = self.m_activity.rewardDays
    self.m_rewardedDaysOld = self.m_rewardedDays
    self.m_maxCheckInDay = #Tables.checkInRewardTable
    local checkInList1 = self.view.checkInList1
    local checkInList2 = self.view.checkInList2
    self.m_checkInBtnCellGenFun1 = UIUtils.genCachedCellFunction(checkInList1)
    self.m_checkInBtnCellGenFun2 = UIUtils.genCachedCellFunction(checkInList2)
    checkInList1.onUpdateCell:AddListener(function(obj, csIndex)
        local cell = self.m_checkInBtnCellGenFun1(obj)
        if self.m_showingSecondPart then
            return
        end
        self:UpdateCheckInBtn(self.m_showingSecondPart, cell, csIndex)
    end)
    checkInList2.onUpdateCell:AddListener(function(obj, csIndex)
        local cell = self.m_checkInBtnCellGenFun2(obj)
        if not self.m_showingSecondPart then
            return
        end
        self:UpdateCheckInBtn(self.m_showingSecondPart, cell, csIndex)
    end)
    local initSelectSecond = self.m_rewardedDays >= UIConst.CHECK_IN_CONST.PART_SPLIT_NUM
    self:SwitchPart(initSelectSecond, true, false, true)
    local partToggle1 = self.view.tabCell01.toggle
    local partToggleRedDot1 = self.view.tabCell01.redDot
    local partToggle2 = self.view.tabCell02.toggle
    local partToggleRedDot2 = self.view.tabCell02.redDot
    local activeToggle = initSelectSecond and partToggle2 or partToggle1
    activeToggle.isOn = true
    activeToggle.interactable = false
    partToggle1.onValueChanged:AddListener(function(isOn)
        if isOn then
            self:SwitchPart(false)
            partToggle1.interactable = false
            partToggle2.interactable = true
        end
    end)
    partToggle2.onValueChanged:AddListener(function(isOn)
        if isOn then
            self:SwitchPart(true)
            partToggle1.interactable = true
            partToggle2.interactable = false
        end
    end)
    local tabRedDotArgs1 = { checkInActivity = self.m_activity, firstDay = 1, lastDay = UIConst.CHECK_IN_CONST.PART_SPLIT_NUM }
    local tabRedDotArgs2 = { checkInActivity = self.m_activity, firstDay = UIConst.CHECK_IN_CONST.PART_SPLIT_NUM + 1, lastDay = self.m_maxCheckInDay }
    partToggleRedDot1:InitRedDot("CheckInTab", tabRedDotArgs1)
    partToggleRedDot2:InitRedDot("CheckInTab", tabRedDotArgs2)
    self.view.charRewardDayText.text = tostring(Tables.activityConst.CheckInRewardCharDay)
    local charId = Tables.activityConst.CheckInRewardCharId
    self.m_previewCharInfo = GameInstance.player.charBag:CreateClientPerfectPoolCharInfo(charId, ScopeUtil.GetCurrentScope())
    self.view.previewBtn.onClick:AddListener(function()
        CharInfoUtils.openCharInfoBestWay({ initCharInfo = { instId = self.m_previewCharInfo.instId, templateId = self.m_previewCharInfo.templateId, isSingleChar = true, isTrail = false, } })
    end)
    if args then
        if LuaSystemManager.loginCheckSystem.m_isInterrupted then
            self:_StartCoroutine(function()
                coroutine.step()
                if LuaSystemManager.loginCheckSystem.m_isInterrupted then
                    self:Hide()
                end
            end)
        end
    end
end
CheckInCtrl.SwitchPart = HL.Method(HL.Boolean, HL.Opt(HL.Boolean, HL.Boolean, HL.Boolean, HL.Boolean)) << function(self, showSecondPart, skipSwitchAnim, skipGradually, isInit, noScrolling)
    if self.m_lastPerformingBtn ~= nil then
        self.m_lastPerformingBtn = nil
        self:_PostCollectPerformance()
        return
    end
    if isInit == true then
        self.view.simpleStateController:SetState(showSecondPart and CHECK_IN_PANEL_STATE_NAME.PART_TWO or CHECK_IN_PANEL_STATE_NAME.PART_ONE)
    else
        self:_SwitchPanelView(showSecondPart and true or false, skipSwitchAnim and true or false)
    end
    self.m_showingSecondPart = showSecondPart
    local activeList = showSecondPart and self.view.checkInList2 or self.view.checkInList1;
    if not showSecondPart then
        self:UpdateCheckInBtn(false, self.view.specialCheckInBtn, CSIndex(UIConst.CHECK_IN_CONST.PART_SPLIT_NUM))
        self.view.recruitTxt.text = self.m_activity.rewardDays >= Tables.activityConst.CheckInRewardCharDay and Language.LUA_CHECK_IN_CHAR_COLLECTED or Language.LUA_CHECK_IN_CHAR_NOT_COLLECTED
    end
    local btnCntCurPart = showSecondPart and self.m_maxCheckInDay - UIConst.CHECK_IN_CONST.PART_SPLIT_NUM or UIConst.CHECK_IN_CONST.PART_SPLIT_NUM
    local btnListCntCurPart = showSecondPart and btnCntCurPart or btnCntCurPart - 1
    if not skipGradually then
        self.m_rewardedDaysOld = self.m_rewardedDays
        self.m_unlockedDaysOld = self.m_unlockedDays
    end
    local targetIndex = 0
    local indexBaseCurPart = showSecondPart and UIConst.CHECK_IN_CONST.PART_SPLIT_NUM or 0
    if not noScrolling then
        local lastCollectedBtnIndex = self.m_activity.rewardDays - indexBaseCurPart
        if lastCollectedBtnIndex > 0 then
            targetIndex = math.min(lastCollectedBtnIndex + 1, btnListCntCurPart)
        else
            targetIndex = 1
        end
    end
    self.m_audioBlocker = false
    if skipSwitchAnim and not isInit then
        activeList:UpdateCount(btnListCntCurPart, false, false, false, skipGradually and true or false)
        if targetIndex ~= 0 then
            activeList:ScrollToIndex(CSIndex(targetIndex))
        end
    else
        local alignType = targetIndex == btnListCntCurPart and CS.Beyond.UI.UIScrollList.ScrollAlignType.Bottom or CS.Beyond.UI.UIScrollList.ScrollAlignType.Top
        activeList:UpdateCount(btnListCntCurPart, CSIndex(targetIndex), false, false, skipGradually and true or false, alignType)
    end
    if self.m_rewardedDaysOld ~= self.m_rewardedDays and (self.m_rewardedDays <= indexBaseCurPart or self.m_rewardedDaysOld >= btnListCntCurPart + btnCntCurPart) then
        self:_PostCollectPerformance()
    end
    self.m_rewardedDaysOld = self.m_rewardedDays
    self.m_unlockedDaysOld = self.m_unlockedDays
    local activeLayoutTime = self.m_showingSecondPart and self.view.layoutTime02 or self.view.layoutTime01
    local endTime = self.m_activity.endTime
    local curServerTime = DateTimeUtils.GetCurrentTimestampBySeconds()
    local endDate = os.date("!*t", endTime + Utils.getServerTimeZoneOffsetSeconds())
    activeLayoutTime.remainingTime.text = string.format(Language.LUA_CHECK_IN_REMAINING_DAYS, math.ceil((endTime - curServerTime) / (3600 * 24)))
    activeLayoutTime.endTime.text = Utils.appendUTC(string.format(Language.LUA_CHECK_IN_END_DATE, endDate.month, endDate.day, endDate.hour, endDate.min))
end
CheckInCtrl._SwitchPanelView = HL.Method(HL.Boolean, HL.Boolean) << function(self, switchToSecondPart, skipAnim)
    local animationWrapper = self.view.stateAnimationWrapper
    local clipName = switchToSecondPart and CHECK_IN_PANEL_ANIM_NAME.SWITCH_TO_PART_TWO or CHECK_IN_PANEL_ANIM_NAME.SWITCH_TO_PART_ONE
    if skipAnim then
        animationWrapper:SampleClipAtPercent(clipName, 1)
    else
        animationWrapper:Play(clipName)
    end
end
CheckInCtrl.UpdateCheckInBtn = HL.Method(HL.Boolean, HL.Table, HL.Number) << function(self, isSecondPart, cell, csIndex)
    local dayLuaIndex = LuaIndex(csIndex) + (isSecondPart and UIConst.CHECK_IN_CONST.PART_SPLIT_NUM or 0)
    local dayStr = tostring(dayLuaIndex)
    cell.nameDayTxt.text = dayStr
    if cell.nameDayTxtCollected then
        cell.nameDayTxtCollected.text = dayStr
    end
    local hasValue, rewardData = Tables.checkInRewardTable:TryGetValue(dayLuaIndex)
    cell.button.interactable = false
    if not hasValue then
        return
    end
    if dayLuaIndex ~= UIConst.CHECK_IN_CONST.PART_SPLIT_NUM then
        if not isSecondPart then
            if rewardData.isKeyReward then
                cell.rareStateController:SetState(CHECK_IN_RARE_STATE_NAME.SPECIAL)
            else
                cell.rareStateController:SetState(CHECK_IN_RARE_STATE_NAME.NORMAL)
            end
        end
    end
    local oldItemState = CheckInCtrl._GetItemState(dayLuaIndex, self.m_unlockedDaysOld, self.m_rewardedDaysOld);
    local itemState = CheckInCtrl._GetItemState(dayLuaIndex, self.m_unlockedDays, self.m_rewardedDays);
    local rewardItems = UIUtils.getRewardItems(rewardData.rewardId)
    local displayItems = { [1] = cell.reward01, [2] = cell.reward02, [3] = cell.reward03 }
    for key, displayItem in pairs(displayItems) do
        local item = displayItem.rewardItem
        local itemBundle = rewardItems[key]
        if self.m_enableEmptyRewardNode then
            displayItem.gameObject:SetActive(true)
        end
        if not itemBundle then
            if self.m_enableEmptyRewardNode then
                item.gameObject:SetActive(false)
                displayItem.emptyState.gameObject:SetActive(true)
            else
                displayItem.gameObject:SetActive(false)
            end
        else
            item.gameObject:SetActive(true)
            displayItem.emptyState.gameObject:SetActive(false)
            item:InitItem(itemBundle, true)
            item.view.rewardedCover.gameObject:SetActive(itemState == 2)
        end
    end
    local unlockAnim = (isSecondPart and rewardData.isKeyReward) and CHECK_IN_BTN_ANIM_NAME.SP_CAN_COLLECT or CHECK_IN_BTN_ANIM_NAME.CAN_COLLECT
    local collectAnim = (isSecondPart and rewardData.isKeyReward) and CHECK_IN_BTN_ANIM_NAME.SP_COLLECTED or CHECK_IN_BTN_ANIM_NAME.COLLECTED
    cell.button.interactable = itemState == 1
    cell.animationWrapper:ClearTween()
    if oldItemState == itemState then
        if itemState == 0 then
            cell.animationWrapper:SampleClipAtPercent(unlockAnim, 0)
        elseif itemState == 1 then
            cell.animationWrapper:SampleClipAtPercent(unlockAnim, 1)
        else
            cell.animationWrapper:SampleClipAtPercent(collectAnim, 1)
        end
    else
        if itemState == 1 then
            cell.animationWrapper:Play(unlockAnim)
        else
            self.m_lastPerformingBtn = cell
            if self.m_audioBlocker == false then
                self.m_audioBlocker = true
                AudioManager.PostEvent("Au_UI_Event_CheckInPanel_Receive")
            end
            cell.animationWrapper:Play(collectAnim, function()
                if self.m_lastPerformingBtn == cell then
                    self.m_lastPerformingBtn = nil
                    self:_PostCollectPerformance()
                end
            end)
        end
    end
    cell.button.onClick:RemoveAllListeners()
    cell.button.onClick:AddListener(function()
        self:CollectReward()
    end)
end
CheckInCtrl._GetItemState = HL.StaticMethod(HL.Number, HL.Number, HL.Number).Return(HL.Number) << function(dayLuaIndex, unlockDays, rewardedDays)
    if dayLuaIndex > unlockDays then
        return 0
    end
    if dayLuaIndex <= rewardedDays then
        return 2
    end
    return 1
end
CheckInCtrl.m_waitingShowReward = HL.Field(HL.Boolean) << false
CheckInCtrl.m_waitingReward = HL.Field(HL.Table)
CheckInCtrl.m_lastPerformingBtn = HL.Field(HL.Table)
CheckInCtrl.CollectReward = HL.Method() << function(self)
    self.m_activity:GainCheckInReward()
end
CheckInCtrl.OnActivityUpdated = HL.Method(HL.Table) << function(self, args)
    local id = unpack(args)
    if id ~= UIConst.CHECK_IN_CONST.CBT2_CHECK_IN_ID then
        return
    end
    if self.m_rewardedDays < self.m_activity.rewardDays then
        if self.m_waitingReward ~= nil then
            self:_DoCollectPerformance()
        else
            self.m_waitingShowReward = true
        end
    else
        self.m_unlockedDaysOld = self.m_unlockedDays
        self.m_rewardedDaysOld = self.m_rewardedDays
        self.m_unlockedDays = self.m_activity.loginDays
        self.m_rewardedDays = self.m_activity.rewardDays
        self:SwitchPart(self.m_showingSecondPart, true, true)
    end
end
CheckInCtrl._DoCollectPerformance = HL.Method() << function(self)
    self.view.btnClose.interactable = false
    self.m_unlockedDaysOld = self.m_unlockedDays
    self.m_rewardedDaysOld = self.m_rewardedDays
    self.m_unlockedDays = self.m_activity.loginDays
    self.m_rewardedDays = self.m_activity.rewardDays
    self:SwitchPart(self.m_showingSecondPart, true, true, false, true)
end
CheckInCtrl._PostCollectPerformance = HL.Method() << function(self)
    self.m_waitingReward.onComplete = function()
        self.view.btnClose.interactable = true
        Notify(MessageConst.ON_CHECK_IN_UPDATED)
        if self.m_rewardedDays >= UIConst.CHECK_IN_CONST.PART_SPLIT_NUM then
            if self.view.tabCell02.toggle.isOn then
                self:SwitchPart(true, true, true)
            else
                self.view.tabCell02.toggle.isOn = true
            end
        else
            if self.view.tabCell01.toggle.isOn then
                self:SwitchPart(false, true, true)
            else
                self.view.tabCell01.toggle.isOn = true
            end
        end
    end
    Notify(MessageConst.SHOW_SYSTEM_REWARDS, self.m_waitingReward)
    self.m_waitingReward = nil
end
CheckInCtrl.OnRewardInfo = HL.Method(HL.Table) << function(self, args)
    local rewardPack = unpack(args)
    self.m_waitingReward = { items = rewardPack.itemBundleList, chars = rewardPack.chars }
    if self.m_waitingShowReward then
        self.m_waitingShowReward = false
        self:_DoCollectPerformance()
    end
end
CheckInCtrl.s_loginArgs = HL.StaticField(HL.Table)
CheckInCtrl.s_performCloseCallback = HL.StaticField(HL.Boolean) << false
CheckInCtrl.OnInterrupt = HL.StaticMethod(HL.String) << function(loginStepKey)
    if loginStepKey ~= LoginCheckConst.LOGIN_CHECK_STEP_KEY.CHECK_IN then
        return
    end
    if PhaseManager:IsOpen(PHASE_ID) then
        CheckInCtrl.s_performCloseCallback = false
        PhaseManager:ExitPhaseFast(PHASE_ID)
    end
end
CheckInCtrl.OnResume = HL.StaticMethod(HL.String) << function(loginStepKey)
    if loginStepKey ~= LoginCheckConst.LOGIN_CHECK_STEP_KEY.CHECK_IN then
        return
    end
    if not PhaseManager:IsPhaseRepeated(PHASE_ID) then
        PhaseManager:OpenPhaseFast(PHASE_ID)
    end
end
CheckInCtrl.OnClose = HL.Override() << function(self)
    GameInstance.player.charBag:ClearAllClientCharInfo()
end
HL.Commit(CheckInCtrl)