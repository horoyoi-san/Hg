local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingDungeonToast
RacingDungeonToastCtrl = HL.Class('RacingDungeonToastCtrl', uiCtrl.UICtrl)
RacingDungeonToastCtrl.s_messages = HL.StaticField(HL.Table) << {}
RacingDungeonToastCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    if arg then
        self.view.toastText.text = arg.toast
    end
    self:_StartTimer(3, function()
        self:PlayAnimationOutAndClose()
        UIManager:Open(PanelId.RacingTimeToast)
    end)
end
RacingDungeonToastCtrl._OnShow = HL.StaticMethod() << function(text)
    local isOpen, ctrl = UIManager:IsOpen(PANEL_ID)
    if isOpen then
        UIManager:Close(PANEL_ID)
    end
    UIManager:Open(PANEL_ID, text)
    Notify(MessageConst.MIN_MAP_SHOW, { false })
end
RacingDungeonToastCtrl.OnShowToast = HL.StaticMethod() << function(self, arg)
    RacingDungeonToastCtrl._OnShow(arg)
end
RacingDungeonToastCtrl.OnEnterRacingDungeon = HL.StaticMethod() << function(self)
    RacingDungeonToastCtrl._OnShow(Language.LUA_RACING_DUNGEON_START)
end
HL.Commit(RacingDungeonToastCtrl)