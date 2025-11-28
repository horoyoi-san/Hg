local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ShopTopNode
ShopTopNodeCtrl = HL.Class('ShopTopNodeCtrl', uiCtrl.UICtrl)
ShopTopNodeCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_UI_PANEL_OPENED] = 'OnOpenOtherPanel', }
ShopTopNodeCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    arg.parent = self
    self.view.shopTopNode:InitShopTopNode(arg)
end
ShopTopNodeCtrl.OnOpenOtherPanel = HL.Method(HL.Any) << function(self, arg)
    self.view.shopTopNode:SetSortingOrder()
end
HL.Commit(ShopTopNodeCtrl)