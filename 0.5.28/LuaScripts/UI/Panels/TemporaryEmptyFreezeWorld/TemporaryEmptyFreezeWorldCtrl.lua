local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.TemporaryEmptyFreezeWorld
TemporaryEmptyFreezeWorldCtrl = HL.Class('TemporaryEmptyFreezeWorldCtrl', uiCtrl.UICtrl)
TemporaryEmptyFreezeWorldCtrl.s_messages = HL.StaticField(HL.Table) << {}
TemporaryEmptyFreezeWorldCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
end
HL.Commit(TemporaryEmptyFreezeWorldCtrl)