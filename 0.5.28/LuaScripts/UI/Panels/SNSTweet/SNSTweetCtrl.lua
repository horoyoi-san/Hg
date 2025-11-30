local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SNSTweet
SNSTweetCtrl = HL.Class('SNSTweetCtrl', uiCtrl.UICtrl)
SNSTweetCtrl.s_messages = HL.StaticField(HL.Table) << {}
SNSTweetCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnClose.onClick:AddListener(function()
        self:Close()
    end)
    self.view.moment:InitSNSMoment()
end
HL.Commit(SNSTweetCtrl)