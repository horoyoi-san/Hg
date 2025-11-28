local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.HeadBar
HeadBarCtrl = HL.Class('HeadBarCtrl', uiCtrl.UICtrl)
HeadBarCtrl.s_messages = HL.StaticField(HL.Table) << {}
HeadBarCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:_CreateWorldObjectRoot(true)
    self.view.csHeadBarCtrl:OnCreate(self.m_worldAutoRoot)
end
HeadBarCtrl.OnClose = HL.Override() << function(self)
    self.view.csHeadBarCtrl:OnClose()
end
HeadBarCtrl.OnHide = HL.Override() << function(self)
    self.view.csHeadBarCtrl:OnHide()
end
HeadBarCtrl.OnShow = HL.Override() << function(self)
    self.view.csHeadBarCtrl:OnShow()
end
HL.Commit(HeadBarCtrl)