local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingDungeonMapToast
RacingDungeonMapToastCtrl = HL.Class('RacingDungeonMapToastCtrl', uiCtrl.UICtrl)
RacingDungeonMapToastCtrl.s_messages = HL.StaticField(HL.Table) << {}
RacingDungeonMapToastCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    if args then
        self.view.nameText.text = args[1]
    end
    self.view.descText.gameObject:SetActive(false)
end
RacingDungeonMapToastCtrl.OnShow = HL.Override() << function(self)
    self:_StartTimer(3, function()
        UIManager:Close(PANEL_ID)
    end)
end
RacingDungeonMapToastCtrl.OnShowToast = HL.StaticMethod(HL.Table) << function(args)
    local isOpen, ctrl = UIManager:IsOpen(PANEL_ID)
    if isOpen then
        UIManager:Close(PANEL_ID)
    end
    UIManager:Open(PANEL_ID, args)
end
HL.Commit(RacingDungeonMapToastCtrl)