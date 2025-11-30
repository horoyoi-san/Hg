local phaseBase = require_ex('Phase/Core/PhaseBase')
local PHASE_ID = PhaseId.Dialog
PhaseDialog = HL.Class('PhaseDialog', phaseBase.PhaseBase)
local clearPhases = { PhaseId.CharInfo, PhaseId.CharFormation, }
local recordPanelId = PanelId.DialogRecord
local skipPopUpPanelId = PanelId.DialogSkipPopUp
PhaseDialog.s_messages = HL.StaticField(HL.Table) << { [MessageConst.DIALOG_CLEAR_PHASES_WITH_CAM] = { 'ClearPhasesWithCam', false }, [MessageConst.ON_INTERACT_NPC] = { 'OnDialogStart', false }, [MessageConst.ON_DIALOG_START] = { 'OnDirectDialogStart', false }, [MessageConst.ON_EXIT_DIALOG] = { 'OnExitDialog', true }, [MessageConst.ON_PLAY_DIALOG_TRUNK] = { 'OnPlayDialogTrunk', true }, [MessageConst.ON_SHOW_DIALOG_OPTION] = { 'OnShowDialogOption', true }, [MessageConst.DIALOG_PANEL_SHOW_FULL_BG] = { 'OnShowDialogFullBg', true }, [MessageConst.ON_DIALOG_ENV_TALK_CHANGED] = { 'OnDialogEnvTalkChanged', true }, [MessageConst.P_ON_COMMON_BACK_CLICKED] = { 'OnCommonBackClicked' }, [MessageConst.DIALOG_OPEN_UI] = { "OpenUI", true }, [MessageConst.DIALOG_CLOSE_UI] = { 'CloseUI', true }, [MessageConst.DIALOG_SEND_PRESENT_END] = { "OnSendPresentEnd", true }, [MessageConst.P_NEXT_TRUNK] = { 'Next' }, [MessageConst.P_DIALOG_REFRESH_CTRL_BUTTON] = { 'SetCtrlButtonVisible' }, [MessageConst.P_OPEN_DIALOG_RECORD] = { '_OpenDialogRecord' }, [MessageConst.P_HIDE_DIALOG_RECORD] = { '_HideDialogRecord' }, [MessageConst.P_OPEN_DIALOG_SKIP_POP_UP] = { '_OpenDialogSkipPopUp' }, [MessageConst.P_HIDE_DIALOG_SKIP_POP_UP] = { '_HideDialogSkipPopUp' }, [MessageConst.P_SKIP_DIALOG] = { '_SkipDialog' }, }
PhaseDialog.m_panelItem = HL.Field(HL.Forward("PhasePanelItem"))
PhaseDialog.m_targetGroup = HL.Field(HL.Forward("PhaseGameObjectItem"))
PhaseDialog.m_inited = HL.Field(HL.Boolean) << false
PhaseDialog.doingOut = HL.Field(HL.Boolean) << false
PhaseDialog.m_onRightMouseButtonPress = HL.Field(HL.Function)
PhaseDialog.m_onDrag = HL.Field(HL.Function)
PhaseDialog.s_nextDialog = HL.StaticField(HL.String) << ""
PhaseDialog._OnInit = HL.Override() << function(self)
    PhaseDialog.Super._OnInit(self)
    UIManager:ToggleBlockObtainWaysJump("IN_CINEMATIC", true)
end
PhaseDialog.ClearPhasesWithCam = HL.StaticMethod(HL.Opt(HL.Any)) << function(_)
    for _, phaseId in pairs(clearPhases) do
        local isOpen, phase = PhaseManager:IsOpen(phaseId)
        if isOpen then
            PhaseManager:ExitPhaseFast(phaseId)
        end
    end
end
PhaseDialog.OnDialogStart = HL.StaticMethod(HL.Table) << function(arg)
    arg.fast = true
    local isOpen, _ = PhaseManager:IsOpen(PhaseId.Dialog)
    if not isOpen then
        PhaseDialog.AutoOpen(PHASE_ID, arg)
    else
        if phase.doingOut then
            local nextDialog = GameInstance.world.dialogManager.dialogId
            logger.info("Dialog already open: " .. nextDialog)
            PhaseDialog.s_nextDialog = nextDialog
        end
    end
end
PhaseDialog.OnDirectDialogStart = HL.StaticMethod(HL.Opt(HL.Table)) << function(data)
    local arg = { direct = true, fast = true, }
    local isOpen, phase = PhaseManager:IsOpen(PhaseId.Dialog)
    if not isOpen then
        PhaseDialog.AutoOpen(PHASE_ID, arg)
    else
        if phase.doingOut then
            local nextDialog = GameInstance.world.dialogManager.dialogId
            logger.info("Dialog already open: " .. nextDialog)
            PhaseDialog.s_nextDialog = nextDialog
        end
    end
end
PhaseDialog.OnShowDialogFullBg = HL.Method(HL.Table) << function(self, data)
    local actionData = unpack(data)
    self:_DoShowFullBg(actionData)
end
PhaseDialog.OnDialogEnvTalkChanged = HL.Method(HL.Table) << function(self, arg)
    self:_GetPanelPhaseItem(PanelId.HeadLabelInDialog).uiCtrl:RefreshEnvTalk(arg)
end
PhaseDialog._InitAllPhaseItems = HL.Override() << function(self)
    PhaseDialog.Super._InitAllPhaseItems(self)
    self.m_panelItem = self:_GetPanelPhaseItem(PanelId.Dialog)
    self.m_panelItem.uiCtrl:Hide()
end
PhaseDialog.OnCommonBackClicked = HL.Method() << function(self)
end
PhaseDialog.OnExitDialog = HL.Method(HL.Opt(HL.Any)) << function(self, arg)
    local fast = false
    if arg then
        fast = unpack(arg)
    end
    UIManager:Hide(PanelId.CommonPopUp)
    if not fast then
        self.doingOut = true
        self.m_panelItem.uiCtrl:PlayAnimationOutWithCallback(function()
            self:ExitSelfFast()
            if not string.isEmpty(PhaseDialog.s_nextDialog) then
                PhaseDialog.s_nextDialog = ""
                PhaseDialog.OnDirectDialogStart()
            end
        end)
    else
        self:ExitSelfFast()
    end
end
PhaseDialog.OnPlayDialogTrunk = HL.Method(HL.Table) << function(self, data)
    local trunkNodeData, fastMode, npcId, npcGroupId = unpack(data)
    self:_DoPlayDialogTrunk(trunkNodeData, fastMode, npcId, npcGroupId)
end
PhaseDialog.OnShowDialogOption = HL.Method(HL.Table) << function(self, data)
    local options = unpack(data)
    self:_DoShowDialogOption(options)
end
PhaseDialog._DoPlayDialogTrunk = HL.Method(CS.Beyond.Gameplay.DTTrunkNodeData, HL.Opt(HL.Boolean, HL.Any, HL.Any)) << function(self, trunkNodeData, fastMode, npcId, npcGroupId)
    self.m_panelItem.uiCtrl:Show()
    self.m_panelItem.uiCtrl:SetTrunk(trunkNodeData, fastMode, npcId, npcGroupId)
    self.m_inited = true
end
PhaseDialog._DoShowDialogOption = HL.Method(HL.Userdata) << function(self, options)
    self.m_panelItem.uiCtrl:SetTrunkOption(options)
    self.m_inited = true
end
PhaseDialog._DoShowFullBg = HL.Method(CS.Beyond.Gameplay.DialogFullBgActionData) << function(self, actionData)
    self.m_panelItem.uiCtrl:SetFullBg(actionData)
    self.m_panelItem.uiCtrl:Show()
    self.m_inited = true
end
PhaseDialog._AddRegisters = HL.Method() << function(self)
    local touchPanel = self.m_panelItem.uiCtrl:GetTouchPanel()
    if not touchPanel then
        return
    end
    if not self.m_onDrag then
        self.m_onDrag = function(eventData)
            self:_MoveCamera(eventData.delta)
        end
    end
    touchPanel.onDrag:AddListener(self.m_onDrag)
    if BEYOND_DEBUG then
        if not self.m_onRightMouseButtonPress then
            self.m_onRightMouseButtonPress = function(delta)
                self:_MoveCamera(delta)
            end
        end
        touchPanel.onRightMouseButtonPress:AddListener(self.m_onRightMouseButtonPress)
    end
end
PhaseDialog._ClearRegisters = HL.Method() << function(self)
    if not self.m_panelItem then
        return
    end
    local touchPanel = self.m_panelItem.uiCtrl:GetTouchPanel()
    if not touchPanel or not self.m_onRightMouseButtonPress then
        return
    end
    touchPanel.onDrag:RemoveListener(self.m_onDrag)
    if BEYOND_DEBUG then
        touchPanel.onRightMouseButtonPress:RemoveListener(self.m_onRightMouseButtonPress)
    end
end
PhaseDialog._MoveCamera = HL.Method(HL.Userdata) << function(self, delta)
    CameraManager:OnInput(UIUtils.getNormalizedScreenX(delta.x), UIUtils.getNormalizedScreenY(delta.y))
end
PhaseDialog._OnActivated = HL.Override() << function(self)
    self:_TryShowTrunk()
    self:_TryShowOptions()
    self:_AddRegisters()
    self:_InitPhaseDialogController()
end
PhaseDialog._OnDeActivated = HL.Override() << function(self)
    self:_ClearRegisters()
    self:_ClearPhaseDialogController()
end
PhaseDialog._TryShowTrunk = HL.Method() << function(self)
    local mainFlowHandle = GameInstance.world.dialogManager.mainFlowHandle
    if not self.m_inited and mainFlowHandle ~= nil and mainFlowHandle.trunkNodeData then
        self:_DoPlayDialogTrunk(mainFlowHandle.trunkNodeData, true, mainFlowHandle.npcId, mainFlowHandle.templateId)
    else
        self.m_panelItem.uiCtrl:RefreshTrunk()
    end
end
PhaseDialog._TryShowOptions = HL.Method() << function(self)
    local options = GameInstance.world.dialogManager.options
    if not self.m_inited and options.Count > 0 then
        self:_DoShowDialogOption(options)
    end
end
PhaseDialog._OnDestroy = HL.Override() << function(self)
    UIManager:ToggleBlockObtainWaysJump("IN_CINEMATIC", false)
    self.m_panelItem = nil
end
PhaseDialog.OpenUI = HL.Method(HL.Table) << function(self, arg)
    local panelIdStr, paramStr = unpack(arg)
    local panelId = PanelId[panelIdStr]
    local param = not string.isEmpty(paramStr) and Utils.stringJsonToTable(paramStr) or {}
    self.m_panelItem.uiCtrl:PlayAnimationOutWithCallback(function()
        if Utils.isInclude(UIConst.DIALOG_OPEN_UI_USE_PANEL, panelId) then
            self:CreatePhasePanelItem(PanelId[panelId], param)
        else
            local res = PhaseManager:OpenPhase(PhaseId[panelIdStr], param)
            if not res then
                logger.error("Dialog OpenUI fail!!!", panelIdStr)
                GameInstance.world.dialogManager:Next()
            end
        end
    end)
end
PhaseDialog.CloseUI = HL.Method(HL.Table) << function(self, arg)
    local panelId, phaseId, nextIndex, notFastMode = unpack(arg)
    local panelItem = panelId and self:_GetPanelPhaseItem(panelId) or nil
    if panelItem and Utils.isInclude(UIConst.DIALOG_OPEN_UI_USE_PANEL, panelId) then
        self:RemovePhasePanelItem(panelItem)
    elseif phaseId then
        if not not notFastMode then
            PhaseManager:PopPhase(phaseId)
        else
            PhaseManager:ExitPhaseFast(phaseId)
        end
    end
    self.m_panelItem.uiCtrl:PlayAnimationIn()
    if nextIndex then
        self:Next(nextIndex)
    end
end
PhaseDialog.OnSendPresentEnd = HL.Method(HL.Table) << function(self, data)
    local success = data.success
    local deltaFav = data.deltaFav
    local selectedItems = data.selectedItems
    local nextIndex = data.nextIndex
    local levelChanged = data.levelChanged
    self:CloseUI({ PanelId.FriendShipPresent, PhaseId.FriendShipPresent, nextIndex, })
    if success then
        self.m_panelItem.uiCtrl:ShowPresentSuccess(levelChanged, deltaFav, selectedItems)
    end
end
PhaseDialog.Next = HL.Method(HL.Opt(HL.Number)) << function(self, num)
    num = num or -1
    GameInstance.world.dialogManager:Next(num)
end
PhaseDialog.SetCtrlButtonVisible = HL.Method(HL.Boolean) << function(self, visible)
    local panelItem = self:_GetPanelPhaseItem(PanelId.Dialog)
    if panelItem then
        panelItem.uiCtrl:SetCtrlButtonVisible(visible)
    end
end
PhaseDialog._OpenDialogRecord = HL.Method() << function(self)
    local panelItem = self:_GetPanelPhaseItem(recordPanelId)
    if not panelItem then
        panelItem = self:CreatePhasePanelItem(recordPanelId)
    end
    panelItem.uiCtrl:Show()
end
PhaseDialog._HideDialogRecord = HL.Method() << function(self)
    local panelItem = self:_GetPanelPhaseItem(recordPanelId)
    if panelItem then
        panelItem.uiCtrl:Hide()
    end
end
PhaseDialog._OpenDialogSkipPopUp = HL.Method() << function(self)
    local summaryId = GameInstance.world.dialogManager.summaryId
    if string.isEmpty(summaryId) then
        local dialogId = GameInstance.world.dialogManager.dialogId
        if not string.isEmpty(dialogId) then
            Notify(MessageConst.SHOW_POP_UP, {
                content = Language.LUA_CONFIRM_SKIP_DIALOG,
                onConfirm = function()
                    GameInstance.world.dialogManager:SkipDialog(dialogId)
                end
            })
        end
    else
        local panelItem = self:_GetPanelPhaseItem(skipPopUpPanelId)
        if not panelItem then
            panelItem = self:CreatePhasePanelItem(skipPopUpPanelId)
        end
        panelItem.uiCtrl:Show()
        panelItem.uiCtrl:RefreshSummary(summaryId)
    end
end
PhaseDialog._HideDialogSkipPopUp = HL.Method() << function(self)
    local panelItem = self:_GetPanelPhaseItem(skipPopUpPanelId)
    if panelItem then
        panelItem.uiCtrl:Hide()
    end
end
PhaseDialog._SkipDialog = HL.Method() << function(self)
    local dialogId = GameInstance.world.dialogManager.dialogId
    if not string.isEmpty(dialogId) then
        GameInstance.world.dialogManager:SkipDialog(dialogId)
    end
    self:_HideDialogSkipPopUp()
end
PhaseDialog.m_dialogControllerThread = HL.Field(HL.Thread)
PhaseDialog._InitPhaseDialogController = HL.Method() << function(self)
    if not DeviceInfo.usingController then
        return
    end
    self.m_dialogControllerThread = self:_StartCoroutine(function()
        while true do
            coroutine.step()
            self:_UpdateControllerMoveCamera()
        end
    end)
end
PhaseDialog._ClearPhaseDialogController = HL.Method() << function(self)
    if self.m_dialogControllerThread ~= nil then
        self.m_dialogControllerThread = self:_ClearCoroutine(self.m_dialogControllerThread)
    end
end
PhaseDialog._UpdateControllerMoveCamera = HL.Method() << function(self)
    if not DeviceInfo.usingController then
        return
    end
    if not self:_GetIsControllerDialogCameraValid() then
        return
    end
    local stickValue = InputManagerInst:GetGamepadStickValue(false)
    if InputManager.CheckGamepadStickInDeadZone(stickValue) then
        return
    end
    self:_MoveCamera(JsonConst.CONTROLLER_DIALOG_CAMERA_MOVE_SPEED[1] * stickValue)
end
PhaseDialog._GetIsControllerDialogCameraValid = HL.Method().Return(HL.Boolean) << function(self)
    return self.m_panelItem.uiCtrl.view.inputGroup.groupEnabled
end
HL.Commit(PhaseDialog)