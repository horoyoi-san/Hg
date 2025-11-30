local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonDrag
CommonDragCtrl = HL.Class('CommonDragCtrl', uiCtrl.UICtrl)
CommonDragCtrl.s_messages = HL.StaticField(HL.Table) << {}
CommonDragCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    CS.Beyond.UI.UIDragItem.s_commonDragObjectParent = self.view.transform
end
HL.Commit(CommonDragCtrl)