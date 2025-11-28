local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Test1
Test1Ctrl = HL.Class('Test1Ctrl', uiCtrl.UICtrl)
Test1Ctrl.s_messages = HL.StaticField(HL.Table) << {}
Test1Ctrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
end
Test1Ctrl.XXX = HL.Method() << function(self)
end
HL.Commit(Test1Ctrl)