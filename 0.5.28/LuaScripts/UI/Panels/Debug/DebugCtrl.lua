local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Debug
local DebugManager = CS.Beyond.DebugManager.instance
DebugCtrl = HL.Class('DebugCtrl', uiCtrl.UICtrl)
DebugCtrl.s_messages = HL.StaticField(HL.Table) << {}
DebugCtrl.SetDebugPanelBlockInput = HL.StaticMethod(HL.Any) << function(arg)
    local ctrl = DebugCtrl.AutoOpen(PANEL_ID, nil, false)
    local isShown = unpack(arg)
    if isShown then
        ctrl:ChangeCurPanelBlockSetting(true, Types.EPanelMultiTouchTypes.Both)
    else
        ctrl:ChangeCurPanelBlockSetting(false, Types.EPanelMultiTouchTypes.Both)
    end
end
HL.Commit(DebugCtrl)