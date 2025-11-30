local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonActionMenu
CommonActionMenuCtrl = HL.Class('CommonActionMenuCtrl', uiCtrl.UICtrl)
CommonActionMenuCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.HIDE_COMMON_ACTION_MENU] = 'HideCommonActionMenu', }
CommonActionMenuCtrl.m_cells = HL.Field(HL.Forward('UIListCache'))
CommonActionMenuCtrl.m_args = HL.Field(HL.Table)
CommonActionMenuCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeMaskBtn.onClick:AddListener(function()
        self:HideCommonActionMenu()
    end)
    self.m_cells = UIUtils.genCellCache(self.view.btnCell)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
CommonActionMenuCtrl.ShowCommonActionMenu = HL.StaticMethod(HL.Table) << function(args)
    local self = UIManager:AutoOpen(PANEL_ID)
    UIManager:SetTopOrder(PANEL_ID)
    self:_RefreshContent(args)
end
CommonActionMenuCtrl._RefreshContent = HL.Method(HL.Table) << function(self, args)
    self.m_args = args
    local actions = args.actions
    self.m_cells:Refresh(#actions, function(cell, index)
        local info = actions[index]
        cell.button.onClick:RemoveAllListeners()
        local isAction = info.action ~= nil
        cell.actionNode.gameObject:SetActive(isAction)
        cell.titleNode.gameObject:SetActive(not isAction)
        if isAction then
            cell.text.text = info.text
            cell.button.onClick:AddListener(function()
                self:_OnClickCell(index)
            end)
        else
            cell.titleText.text = info.text
        end
        if index == 1 then
            InputManagerInst.controllerNaviManager:SetTarget(cell.button)
        end
    end)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.content)
    local notchSize = CS.Beyond.DeviceInfoManager.NotchPaddingInCanvas(self.view.transform).x
    local padding = { bottom = 100, left = notchSize, right = notchSize, }
    UIUtils.updateTipsPosition(self.view.content, self.m_args.transform, self.view.rectTransform, self.uiCamera, UIConst.UI_TIPS_POS_TYPE.RightTop, padding)
end
CommonActionMenuCtrl._OnClickCell = HL.Method(HL.Number) << function(self, index)
    local args = self.m_args
    self:HideCommonActionMenu()
    args.actions[index].action()
end
CommonActionMenuCtrl.HideCommonActionMenu = HL.Method() << function(self)
    local onClose = self.m_args.onClose
    if onClose then
        onClose()
    end
    self:PlayAnimationOutAndHide()
end
CommonActionMenuCtrl.OnHide = HL.Override() << function(self)
    self.m_args = nil
end
HL.Commit(CommonActionMenuCtrl)