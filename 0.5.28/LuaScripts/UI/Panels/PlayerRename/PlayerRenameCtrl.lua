local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.PlayerRename
local PHASE_ID = PhaseId.PlayerRename
local State = { Default = 0, SecondCheck = 1, }
PlayerRenameCtrl = HL.Class('PlayerRenameCtrl', uiCtrl.UICtrl)
PlayerRenameCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_CHECK_PLAYER_NAME_SUCCESS] = '_OnNameCheckSuccess', [MessageConst.ON_CHECK_PLAYER_NAME_FAILED] = '_OnNameCheckFailed', [MessageConst.ON_SET_PLAYER_NAME] = '_OnNameSetSuccess', }
PlayerRenameCtrl.m_input = HL.Field(HL.String) << ""
PlayerRenameCtrl.m_isValid = HL.Field(HL.Boolean) << true
PlayerRenameCtrl.m_checked = HL.Field(HL.Boolean) << false
PlayerRenameCtrl.m_state = HL.Field(HL.Number) << 0
PlayerRenameCtrl.m_select = HL.Field(HL.Boolean) << true
PlayerRenameCtrl.m_onFinish = HL.Field(HL.Any)
PlayerRenameCtrl.m_inited = HL.Field(HL.Boolean) << false
PlayerRenameCtrl.m_caret = HL.Field(HL.Any)
PlayerRenameCtrl.m_tailTickId = HL.Field(HL.Number) << -1
PlayerRenameCtrl.OnSetPlayerNameStart = HL.StaticMethod(HL.Table) << function(arg)
    PhaseManager:OpenPhaseFast(PHASE_ID, arg)
end
PlayerRenameCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local onFinish = unpack(arg)
    self.m_onFinish = onFinish
    self.m_caret = nil
    self.view.userRoleInputField.onValueChanged:AddListener(function(text)
        self:_OnValueChanged(text)
    end)
    self.view.userRoleInputField.onValidateInput = function(input, charIndex, addedChar)
        return self:_ValidateInput(addedChar)
    end
    self.view.userRoleInputField.caretWidth = 0
    self.view.userRoleInputField.onSelect:AddListener(function(_)
        self.m_select = true
        self:_RefreshInputField()
    end)
    self.view.userRoleInputField.onDeselect:AddListener(function(_)
        self.m_select = false
        self:_RefreshInputField()
    end)
    self.view.sureBtn.onClick:AddListener(function()
        self:_OnSureBtnClicked()
    end)
    self.view.againBtn.onClick:AddListener(function()
        self:_SwitchState(State.Default)
    end)
    self.view.sureSecondBtn.onClick:AddListener(function()
        GameInstance.player.playerInfoSystem:SetPlayerName(self.m_input)
    end)
    self.view.touchBtn.onClick:AddListener(function()
        self:_SelectToEnd()
    end)
    if DeviceInfo.isPCorConsole then
        self.view.scaleControlNode.transform.localScale = Vector3.one * CS.Beyond.UI.UIConst.PC_REFERENCE_RESOLUTION_SCALE
    end
    self.m_tailTickId = LuaUpdate:Add("TailTick", function(deltaTime)
        self:TailTick(deltaTime)
    end)
end
PlayerRenameCtrl._SelectToEnd = HL.Method(HL.Opt(HL.Boolean)) << function(self, force)
    if not self.m_select or force then
        self.view.userRoleInputField:Select()
        self.view.userRoleInputField:ActivateInputField()
        self.view.userRoleInputField.caretPosition = UIUtils.getStringLength(self.view.userRoleInputField.text)
        self.view.userRoleInputField.selectionAnchorPosition = self.view.userRoleInputField.caretPosition
        self.view.userRoleInputField.selectionFocusPosition = UIUtils.getStringLength(self.view.userRoleInputField.text)
    end
end
PlayerRenameCtrl.TailTick = HL.Method(HL.Number) << function(self, deltaTime)
    local deviceType = DeviceInfo.inputType
    if deviceType == DeviceInfo.InputType.Keyboard then
        self:_SelectToEnd(true)
    end
    self:_RefreshCaret()
end
PlayerRenameCtrl.OnShow = HL.Override() << function(self)
    local deviceType = DeviceInfo.inputType
    if deviceType == DeviceInfo.InputType.Keyboard then
        self.view.userRoleInputField:Select()
    end
    self.view.userRoleInputField:ActivateInputField()
    self:_SwitchState(State.Default)
    self.view.idPlayerTxt.text = string.format("UID: %s", CSUtils.GetCurrentUID())
    self:_RefreshHint()
end
PlayerRenameCtrl.OnClose = HL.Override() << function(self)
    self.m_tailTickId = LuaUpdate:Remove(self.m_tailTickId)
end
PlayerRenameCtrl._RefreshInputField = HL.Method() << function(self)
    local default = self.m_state == State.Default
    self.view.blockNode.gameObject:SetActive(not default)
    self.view.caretLightImage.gameObject:SetActive(default and self.m_select)
    self.view.holdText.gameObject:SetActive(not self.m_select)
end
PlayerRenameCtrl._OnSureBtnClicked = HL.Method() << function(self)
    local count = UIUtils.getStringLength(self.m_input)
    if self.m_isValid and count > 0 then
        GameInstance.player.playerInfoSystem:CheckPlayerName(self.m_input)
    end
end
PlayerRenameCtrl._RefreshHint = HL.Method() << function(self)
    self.m_isValid = UIUtils.checkInputValid(self.m_input)
    local count = UIUtils.getStringLength(self.m_input)
    local gray = not self.m_isValid or count <= 0
    self.view.normalSureImage.gameObject:SetActive(gray)
    self.view.selectSureImg.gameObject:SetActive(not gray)
    self.view.warnNode.gameObject:SetActive(not self.m_isValid)
    self.view.renameTipsTxt.gameObject:SetActive(self.m_isValid)
end
PlayerRenameCtrl._RefreshCaret = HL.Method() << function(self)
    if not self.m_caret then
        self.m_caret = self.view.userRoleInputField.transform:FindRecursive("Caret")
    end
    if not self.m_inited then
        if self.m_caret and self.m_caret.gameObject.activeSelf then
            self.m_caret.gameObject:SetActive(false)
            self.m_inited = true
        end
    end
end
PlayerRenameCtrl._SwitchState = HL.Method(HL.Number) << function(self, state)
    local default = state == State.Default
    self.view.renameTipsTxt.gameObject:SetActive(default)
    self.view.selectTipsTxt.gameObject:SetActive(not default)
    self.view.sureBtn.gameObject:SetActive(default)
    self.view.sureSecondBtn.gameObject:SetActive(not default)
    self.view.againBtn.gameObject:SetActive(not default)
    self.m_state = state
    self:_RefreshInputField()
    self:_SelectToEnd()
    if default then
        self.view.userRoleInputField.enabled = true
    else
        self.view.userRoleInputField.enabled = false
    end
end
PlayerRenameCtrl._ValidateInput = HL.Method(HL.Number).Return(HL.Any) << function(self, addedChar)
    local tmpInput = self.m_input .. utf8.char(addedChar)
    local length = I18nUtils.GetTextRealLength(tmpInput)
    if length > UIConst.INPUT_FIELD_NAME_CHARACTER_LIMIT then
        self.view.userRoleInputField.isLastKeyBackspace = true
        return ""
    else
        return addedChar
    end
end
PlayerRenameCtrl._OnValueChanged = HL.Method(HL.String) << function(self, input)
    if self.m_state ~= State.Default then
        return
    end
    local realInput = string.gsub(input, " ", "")
    if string.len(realInput) > string.len(self.m_input) then
        AudioAdapter.PostEvent("Au_UI_Event_Type")
    end
    self.m_input = realInput
    self.view.userRoleInputField.text = realInput
    self:_RefreshHint()
    self.m_checked = false
end
PlayerRenameCtrl._OnNameCheckSuccess = HL.Method() << function(self)
    self.m_checked = true
    self:_SwitchState(State.SecondCheck)
end
PlayerRenameCtrl._OnNameCheckFailed = HL.Method() << function(self)
    self.view.userRoleInputField:Select()
end
PlayerRenameCtrl._OnNameSetSuccess = HL.Method() << function(self)
    AudioAdapter.PostEvent("Au_UI_Event_PlayerRename_End")
    self:PlayAnimationOutWithCallback(function()
        PhaseManager:ExitPhaseFast(PHASE_ID)
        local onFinish = self.m_onFinish
        if onFinish then
            onFinish()
        end
    end)
end
HL.Commit(PlayerRenameCtrl)