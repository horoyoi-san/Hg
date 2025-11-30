local phaseBase = require_ex('Phase/Core/PhaseBase')
local PHASE_ID = PhaseId.SNS
PhaseSNS = HL.Class('PhaseSNS', phaseBase.PhaseBase)
local SNS_MAIN_PANEL_ID = PanelId.SNSMain
PhaseSNS.m_snsPanelItem = HL.Field(HL.Forward("PhasePanelItem"))
PhaseSNS.s_messages = HL.StaticField(HL.Table) << { [MessageConst.TRY_OPEN_PHASE_SNS] = { 'TryOpenPhaseSNS', false }, }
PhaseSNS.TryOpenPhaseSNS = HL.StaticMethod(HL.Any) << function(arg)
    local dialogId = unpack(arg or {})
    if not string.isEmpty(dialogId) and not GameInstance.player.sns.dialogInfoDic:ContainsKey(dialogId) then
        return
    end
    PhaseManager:OpenPhase(PHASE_ID, arg)
end
PhaseSNS._OnInit = HL.Override() << function(self)
    PhaseSNS.Super._OnInit(self)
end
PhaseSNS._InitAllPhaseItems = HL.Override() << function(self)
    PhaseSNS.Super._InitAllPhaseItems(self)
    self:_InitPhaseSNSItems()
end
PhaseSNS._InitPhaseSNSItems = HL.Method() << function(self)
    self.m_snsPanelItem = self:CreatePhasePanelItem(SNS_MAIN_PANEL_ID, self.arg)
end
PhaseSNS._DoPhaseTransitionIn = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseSNS._DoPhaseTransitionOut = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseSNS._DoPhaseTransitionBehind = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseSNS._DoPhaseTransitionBackToTop = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseSNS._OnActivated = HL.Override() << function(self)
end
PhaseSNS._OnDeActivated = HL.Override() << function(self)
end
PhaseSNS._OnDestroy = HL.Override() << function(self)
    PhaseSNS.Super._OnDestroy(self)
end
PhaseSNS._OnRefresh = HL.Override() << function(self)
    if self.m_snsPanelItem == nil then
        return
    end
    local arg = self.arg
    if arg.chatId and arg.dialogId then
        self.m_snsPanelItem.uiCtrl:JumpToDialogById(arg.chatId, arg.dialogId)
    elseif arg.momentId then
        self.m_snsPanelItem.uiCtrl:JumpToMomentById(arg.momentId)
    end
end
HL.Commit(PhaseSNS)