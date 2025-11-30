local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementCommonToast
local settlementSystem = GameInstance.player.settlementSystem
SettlementCommonToastCtrl = HL.Class('SettlementCommonToastCtrl', uiCtrl.UICtrl)
SettlementCommonToastCtrl.m_timerId = HL.Field(HL.Any) << nil
SettlementCommonToastCtrl.s_messages = HL.StaticField(HL.Table) << {}
SettlementCommonToastCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
end
SettlementCommonToastCtrl._OnShowLink = HL.StaticMethod(HL.Table) << function(args)
    local self = UIManager:AutoOpen(PANEL_ID)
    self.view.linkNode.gameObject:SetActiveIfNecessary(true)
    self.view.levelUpNode.gameObject:SetActiveIfNecessary(false)
    local settlementId, mainText, subText = args[1], args[2], args[3]
    local duration = self.view.config.showDuration
    if subText then
        subText = Language[subText]
    end
    subText = subText or Language.LUA_SETTLEMENT_LINK_AND_UNLOCK
    if settlementId ~= nil then
        mainText = mainText or Tables.settlementBasicDataTable[settlementId].settlementName
    end
    self.view.unlockMainText.text = mainText
    self.view.unlockSubText.text = subText
    AudioAdapter.PostEvent("Au_UI_Toast_SettlementCommonToastPanel_Unlock_Open")
    self:_Refresh(duration)
end
SettlementCommonToastCtrl._OnShowUpgrade = HL.StaticMethod(HL.Table) << function(args)
    local self = UIManager:AutoOpen(PANEL_ID)
    self.view.linkNode.gameObject:SetActiveIfNecessary(false)
    self.view.levelUpNode.gameObject:SetActiveIfNecessary(true)
    local settlementId, mainText = unpack(args)
    local duration = self.view.config.showDuration
    if settlementId ~= nil then
        if not mainText then
            AudioAdapter.PostEvent("Au_UI_Toast_SettlementCommonToastPanel_LevelUp_Open")
        end
        mainText = mainText or Tables.settlementBasicDataTable[settlementId].settlementName
        local level = settlementSystem:GetSettlementLevel(settlementId)
        self.view.levelText.text = tostring(level - 1)
        self.view.levelText2.text = tostring(level)
    end
    self.view.levelUpMainText.text = mainText
    self:_StartTimer(1.5, function()
        self.view.textUnlockOrder.gameObject:SetActive(true)
        self.view.textLevelUp.gameObject:SetActive(false)
    end)
    self:_Refresh(duration)
end
SettlementCommonToastCtrl._Refresh = HL.Method(HL.Number) << function(self, duration)
    if self.m_timerId ~= nil then
        self:_ClearTimer(self.m_timerId)
    end
    self.m_timerId = self:_StartTimer(duration, function()
        self.m_timerId = nil
        self:Close()
    end)
end
HL.Commit(SettlementCommonToastCtrl)