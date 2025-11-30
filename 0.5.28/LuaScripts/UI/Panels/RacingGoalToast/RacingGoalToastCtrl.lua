local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingGoalToast
RacingGoalToastCtrl = HL.Class('RacingGoalToastCtrl', uiCtrl.UICtrl)
RacingGoalToastCtrl.s_messages = HL.StaticField(HL.Table) << {}
RacingGoalToastCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    if args then
        self.view.descText.text = args[1]
    end
end
RacingGoalToastCtrl.OnShow = HL.Override() << function(self)
    self:_StartTimer(3, function()
        self:PlayAnimationOutAndClose()
    end)
end
RacingGoalToastCtrl.OnShowToast = HL.StaticMethod(HL.Table) << function(args)
    local isOpen, ctrl = UIManager:IsOpen(PANEL_ID)
    if isOpen then
        UIManager:Close(PANEL_ID)
    end
    UIManager:Open(PANEL_ID, args)
end
HL.Commit(RacingGoalToastCtrl)