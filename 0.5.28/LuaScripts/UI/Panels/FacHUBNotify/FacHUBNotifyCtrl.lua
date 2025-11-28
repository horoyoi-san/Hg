local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacHUBNotify
FacHUBNotifyCtrl = HL.Class('FacHUBNotifyCtrl', uiCtrl.UICtrl)
FacHUBNotifyCtrl.s_messages = HL.StaticField(HL.Table) << {}
FacHUBNotifyCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeBtn.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    local info = GameInstance.player.facSpMachineSystem.offlineInfo
    self.view.stopTimeTxt.text = os.date("!" .. Language.LUA_FAC_OFFLINE_OS_DATE_FORMAT, info.endOfflineCalcTimestamp + Utils.getServerTimeZoneOffsetSeconds())
end
HL.Commit(FacHUBNotifyCtrl)