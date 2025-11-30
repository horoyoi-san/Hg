local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.EndingToast
local PHASE_ID = PhaseId.EndingToast
EndingToastCtrl = HL.Class('EndingToastCtrl', uiCtrl.UICtrl)
EndingToastCtrl.s_messages = HL.StaticField(HL.Table) << {}
EndingToastCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.mask.onClick:AddListener(function()
        PhaseManager:PopPhase(PHASE_ID)
    end)
end
EndingToastCtrl._OnShowEndingToast = HL.StaticMethod() << function()
    PhaseManager:OpenPhase(PHASE_ID)
end
HL.Commit(EndingToastCtrl)