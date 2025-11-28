local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ItemSplit
CommonItemNumSelectCtrl = HL.Class('CommonItemNumSelectCtrl', uiCtrl.UICtrl)
CommonItemNumSelectCtrl.s_messages = HL.StaticField(HL.Table) << {}
CommonItemNumSelectCtrl.m_itemId = HL.Field(HL.String) << ''
CommonItemNumSelectCtrl.m_count = HL.Field(HL.Number) << 1
CommonItemNumSelectCtrl.m_curCount = HL.Field(HL.Number) << 1
CommonItemNumSelectCtrl.m_onComplete = HL.Field(HL.Function)
CommonItemNumSelectCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.view.btnCancel.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.view.btnConfirm.onClick:AddListener(function()
        self:_OnClickConfirm()
    end)
    self.m_itemId = args.id
    self.m_count = args.count
    self.m_onComplete = args.onComplete
    self.view.numberSelector:InitNumberSelector(1, 1, self.m_count, function(newNum)
        self:_OnNumChanged(newNum)
    end)
    self.m_curCount = self.m_count
    UIUtils.displayItemBasicInfos(self.view, self.loader, self.m_itemId)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
CommonItemNumSelectCtrl.OnClose = HL.Override() << function(self)
    if self.m_onComplete then
        self.m_onComplete()
    end
end
CommonItemNumSelectCtrl._OnNumChanged = HL.Method(HL.Number) << function(self, num)
    self.m_curCount = num
end
CommonItemNumSelectCtrl._OnClickConfirm = HL.Method() << function(self)
    self.m_onComplete(self.m_curCount)
    self:PlayAnimationOutAndClose()
end
HL.Commit(CommonItemNumSelectCtrl)