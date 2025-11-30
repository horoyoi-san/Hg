local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ReadingPopUp
local PHASE_ID = PhaseId.ReadingPopUp
ReadingPopUpCtrl = HL.Class('ReadingPopUpCtrl', uiCtrl.UICtrl)
ReadingPopUpCtrl.s_messages = HL.StaticField(HL.Table) << {}
ReadingPopUpCtrl.m_readId = HL.Field(HL.String) << ""
ReadingPopUpCtrl.m_onCloseCallback = HL.Field(HL.Any)
ReadingPopUpCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PHASE_ID)
    end)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
    local id, callback = unpack(arg)
    self.m_readId = id
    self.m_onCloseCallback = callback
end
ReadingPopUpCtrl._ShowContent = HL.Method() << function(self)
    local richContent = Tables.richContentTable:GetValue(self.m_readId)
    if richContent then
        EventLogManagerInst:GameEvent_ReadNarrativeContent(self.m_readId)
        self.view.richContent:SetContentById(self.m_readId)
    else
        logger.error("can't find contentId " .. tostring(self.m_readId))
    end
end
ReadingPopUpCtrl.OnShowReadingPopPanel = HL.StaticMethod(HL.Table) << function(arg)
    PhaseManager:OpenPhase(PHASE_ID, arg, nil, true)
end
ReadingPopUpCtrl.OnShow = HL.Override() << function(self)
    self:_ShowContent()
end
ReadingPopUpCtrl.OnClose = HL.Override() << function(self)
    local richContent = Tables.richContentTable:GetValue(self.m_readId)
    if richContent then
        EventLogManagerInst:GameEvent_CloseNarrativeContent(self.m_readId)
    end
    GameInstance.player.readingSystem:ReqSetRichContentReadingPopFinish(self.m_readId)
    if self.m_onCloseCallback ~= nil then
        self.m_onCloseCallback()
    end
end
HL.Commit(ReadingPopUpCtrl)