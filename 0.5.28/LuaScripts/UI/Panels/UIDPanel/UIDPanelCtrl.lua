local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.UIDPanel
UIDPanelCtrl = HL.Class('UIDPanelCtrl', uiCtrl.UICtrl)
UIDPanelCtrl.s_messages = HL.StaticField(HL.Table) << {}
UIDPanelCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    if BEYOND_INNER_DEBUG then
        self.view.text.text = string.format("UID: %s VER:%s", CSUtils.GetCurrentUID(), CS.Beyond.GlobalOptions.instance.lastCL)
    else
        self.view.text.text = string.format("UID: %s", CSUtils.GetCurrentUID())
    end
    pcall(function()
        local channel = CS.Beyond.Cfg.RemoteNetworkCfg.instance.data.channel
        if string.find(channel, "inner") then
            self.view.text01.text = Language.LUA_TALPHA_INNER_ALERT
        end
    end)
end
UIDPanelCtrl.OnEnterMainGame = HL.StaticMethod() << function()
    UIManager:Open(PANEL_ID)
end
HL.Commit(UIDPanelCtrl)