local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SimpleSystem
local btnList = { "backBtn", "settingBtn", "quitBtn" }
SimpleSystemCtrl = HL.Class('SimpleSystemCtrl', uiCtrl.UICtrl)
SimpleSystemCtrl.s_messages = HL.StaticField(HL.Table) << {}
SimpleSystemCtrl.m_selectIndex = HL.Field(HL.Number) << 1
SimpleSystemCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.backBtn.button.onClick:AddListener(function()
        self:_OnClick(1)
    end)
    self.view.settingBtn.button.onClick:AddListener(function()
        self:_OnClick(2)
    end)
    self.view.quitBtn.button.onClick:AddListener(function()
        self:_OnClick(3)
    end)
    self:_InitSimpleSystemController()
end
SimpleSystemCtrl._InitSimpleSystemController = HL.Method() << function(self)
    if not DeviceInfo.usingController then
        return
    end
    self:_InitNavigation()
    self:_RefreshNavigateSelected(self.m_selectIndex)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
SimpleSystemCtrl._InitNavigation = HL.Method() << function(self)
    self:BindInputPlayerAction("common_navigation_up", function()
        self:_NavigateSelected(-1)
    end)
    self:BindInputPlayerAction("common_navigation_down", function()
        self:_NavigateSelected(1)
    end)
    self:BindInputPlayerAction("common_cancel", function()
        PhaseManager:PopPhase(PhaseId.SimpleSystem)
    end)
    self:BindInputPlayerAction("common_confirm", function()
        self:_OnClick(self.m_selectIndex)
    end)
end
SimpleSystemCtrl._NavigateSelected = HL.Method(HL.Number) << function(self, offset)
    local count = #btnList
    local newIndex = (self.m_selectIndex - 1 + offset) % count + 1
    self:_RefreshNavigateSelected(newIndex)
    AudioManager.PostEvent("au_ui_btn_dlg_next")
end
SimpleSystemCtrl._RefreshNavigateSelected = HL.Method(HL.Number) << function(self, newIndex)
    local lastBtn = self.view[btnList[self.m_selectIndex]]
    local newBtn = self.view[btnList[newIndex]]
    lastBtn.textActive.gameObject:SetActive(false)
    lastBtn.bgActive.gameObject:SetActive(false)
    newBtn.textActive.gameObject:SetActive(true)
    newBtn.bgActive.gameObject:SetActive(true)
    self.m_selectIndex = newIndex
end
SimpleSystemCtrl._OnClick = HL.Method(HL.Number) << function(self, index)
    if index == 1 then
        PhaseManager:PopPhase(PhaseId.SimpleSystem)
    elseif index == 2 then
        PhaseManager:OpenPhase(PhaseId.GameSetting)
    elseif index == 3 then
        self:Notify(MessageConst.SHOW_POP_UP, {
            content = Language.LUA_EXIT_GAME_CONFIRM,
            hideBlur = true,
            onConfirm = function()
                logger.info("click quit btn on watch")
                CSUtils.QuitGame(0)
            end,
        })
    end
end
HL.Commit(SimpleSystemCtrl)