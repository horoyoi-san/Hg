local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonTips
CommonTipsCtrl = HL.Class('CommonTipsCtrl', uiCtrl.UICtrl)
CommonTipsCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.SHOW_COMMON_TIPS] = 'ShowCommonTips', }
CommonTipsCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.main.gameObject:SetActive(false)
end
CommonTipsCtrl.ShowCommonTips = HL.Method(HL.Table) << function(self, args)
    UIManager:SetTopOrder(PANEL_ID)
    self.view.main.gameObject:SetActive(true)
    self.view.text.text = args.text
    UIUtils.updateTipsPosition(self.view.main.transform, args.transform, self.view.rectTransform, self.uiCamera, args.posType)
end
HL.Commit(CommonTipsCtrl)