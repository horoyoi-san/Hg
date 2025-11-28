local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementDefensePrepareHud
SettlementDefensePrepareHudCtrl = HL.Class('SettlementDefensePrepareHudCtrl', uiCtrl.UICtrl)
local LEAVE_AREA_TOAST_TEXT_ID = "ui_fac_settlement_defence_prepare_stage_quit"
local WAIT_ANIMATION_PLAY_COUNT = 2
SettlementDefensePrepareHudCtrl.m_levelId = HL.Field(HL.String) << ""
SettlementDefensePrepareHudCtrl.m_updateTick = HL.Field(HL.Number) << -1
SettlementDefensePrepareHudCtrl.m_taskTrackCtrl = HL.Field(HL.Forward("UICtrl"))
SettlementDefensePrepareHudCtrl.m_outAnimPlayCount = HL.Field(HL.Number) << 0
SettlementDefensePrepareHudCtrl.m_btnLock = HL.Field(HL.Boolean) << false
SettlementDefensePrepareHudCtrl.s_messages = HL.StaticField(HL.Table) << {}
SettlementDefensePrepareHudCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local towerDefenseSystem = GameInstance.player.towerDefenseSystem
    self.m_btnLock = false
    self.m_levelId = towerDefenseSystem.activeTdId
    if string.isEmpty(self.m_levelId) then
        return
    end
    self.view.startButton.onClick:AddListener(function()
        if self.m_btnLock then
            return
        end
        towerDefenseSystem:EnterDefendingPhase()
        self.m_btnLock = true
    end)
    self.view.leaveButton.onClick:AddListener(function()
        if self.m_btnLock then
            return
        end
        towerDefenseSystem:LeavePreparingPhase()
        self.m_btnLock = true
    end)
    local success, levelTableData = Tables.towerDefenseTable:TryGetValue(self.m_levelId)
    if success then
        local isRaid = levelTableData.tdType == GEnums.TowerDefenseLevelType.Raid
        self.view.normalStartIcon.gameObject:SetActive(not isRaid)
        self.view.raidStartIcon.gameObject:SetActive(isRaid)
    end
    self.m_updateTick = LuaUpdate:Add("LateTick", function(deltaTime)
        self:_RefreshBtnGroupPosition()
    end)
end
SettlementDefensePrepareHudCtrl.OnClose = HL.Override() << function(self)
    self.m_updateTick = LuaUpdate:Remove(self.m_updateTick)
end
SettlementDefensePrepareHudCtrl._RefreshBtnGroupPosition = HL.Method() << function(self)
    if not self.view.btnGroup.gameObject.activeInHierarchy then
        return
    end
    if self.m_taskTrackCtrl == nil then
        local success, taskTrackCtrl = UIManager:IsOpen(PanelId.CommonTaskTrackHud)
        if not success then
            return
        end
        self.m_taskTrackCtrl = taskTrackCtrl
    end
    self.view.btnGroup.position = self.m_taskTrackCtrl:GetContentBottomFollowPosition()
end
SettlementDefensePrepareHudCtrl._TryInvokeCloseCallback = HL.Method() << function(self)
    self.m_outAnimPlayCount = self.m_outAnimPlayCount - 1
    if self.m_outAnimPlayCount > 0 then
        return
    end
    self:Close()
end
SettlementDefensePrepareHudCtrl._PlayBtnGroupAnimOut = HL.Method() << function(self)
    self.view.btnGroupAnim:PlayOutAnimation(function()
        self.view.btnGroup.gameObject:SetActive(false)
        self:_TryInvokeCloseCallback()
    end)
end
SettlementDefensePrepareHudCtrl._PlayTitleAnimOut = HL.Method() << function(self)
    self.view.titleAnim:PlayOutAnimation(function()
        self:_TryInvokeCloseCallback()
    end)
end
SettlementDefensePrepareHudCtrl.CloseDefensePrepareHud = HL.Method(HL.Boolean, HL.Boolean) << function(self, needAreaLeave, closeDirectly)
    if closeDirectly then
        self:Close()
    else
        self.m_outAnimPlayCount = WAIT_ANIMATION_PLAY_COUNT
        if needAreaLeave then
            self.view.toastText.text = Language[LEAVE_AREA_TOAST_TEXT_ID]
            self:_PlayBtnGroupAnimOut()
            TimerManager:StartTimer(self.view.config.LEAVE_AREA_DELAY, function()
                self:_PlayTitleAnimOut()
            end)
        else
            self:_PlayBtnGroupAnimOut()
            self:_PlayTitleAnimOut()
        end
    end
end
HL.Commit(SettlementDefensePrepareHudCtrl)