local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Test2
Test2Ctrl = HL.Class('Test2Ctrl', uiCtrl.UICtrl)
Test2Ctrl.s_messages = HL.StaticField(HL.Table) << {}
Test2Ctrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
end
Test2Ctrl.XXX = HL.Method() << function(self)
end
HL.Commit(Test2Ctrl)