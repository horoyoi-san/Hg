local phaseBase = require_ex('Phase/Core/PhaseBase')
local PHASE_ID = PhaseId.AdventureStage
PhaseAdventureBook = HL.Class('PhaseAdventureBook', phaseBase.PhaseBase)
PhaseAdventureBook.m_curPanelItem = HL.Field(HL.Forward("PhasePanelItem"))
PhaseAdventureBook.m_panelItemDic = HL.Field(HL.Table)
PhaseAdventureBook.m_bookPanel = HL.Field(HL.Forward("PhasePanelItem"))
PhaseAdventureBook.s_messages = HL.StaticField(HL.Table) << {}
PhaseAdventureBook._OnInit = HL.Override() << function(self)
    PhaseAdventureBook.Super._OnInit(self)
end
PhaseAdventureBook._DoPhaseTransitionIn = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    self.m_panelItemDic = {}
    self.m_bookPanel = self:CreatePhasePanelItem(PanelId.AdventureBook, self.arg)
end
PhaseAdventureBook._OnRefresh = HL.Override() << function(self)
    if not self.m_bookPanel then
        return
    end
    Notify(MessageConst.ON_CHANGE_ADVENTURE_BOOK_TAB, self.arg)
end
PhaseAdventureBook._DoPhaseTransitionOut = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseAdventureBook._DoPhaseTransitionBehind = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseAdventureBook._DoPhaseTransitionBackToTop = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseAdventureBook._OnActivated = HL.Override() << function(self)
end
PhaseAdventureBook._OnDeActivated = HL.Override() << function(self)
end
PhaseAdventureBook._OnDestroy = HL.Override() << function(self)
    PhaseAdventureBook.Super._OnDestroy(self)
end
PhaseAdventureBook.OnTabChange = HL.Method(HL.Table) << function(self, arg)
    if arg.panelId == nil then
        return
    end
    if self.m_curPanelItem then
        self.m_curPanelItem.uiCtrl:Hide()
    end
    local panelItem
    if self.m_panelItemDic[arg.panelId] then
        panelItem = self.m_panelItemDic[arg.panelId]
    else
        panelItem = self:CreatePhasePanelItem(arg.panelId)
        self.m_panelItemDic[arg.panelId] = panelItem
    end
    panelItem.uiCtrl:Show()
    self.m_curPanelItem = panelItem
end
HL.Commit(PhaseAdventureBook)