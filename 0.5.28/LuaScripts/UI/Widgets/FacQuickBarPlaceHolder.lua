local PlaceholderBaseWidget = require_ex('UI/Widgets/PlaceholderBaseWidget')
FacQuickBarPlaceHolder = HL.Class('FacQuickBarPlaceHolder', PlaceholderBaseWidget)
FacQuickBarPlaceHolder.InitFacQuickBarPlaceHolder = HL.Method() << function(self)
    if not Utils.isSystemUnlocked(GEnums.UnlockSystemType.FacMode) then
        return
    end
    self:_InitPlaceholder()
end
FacQuickBarPlaceHolder._InitPlaceholder = HL.Override(HL.Opt(HL.Table)) << function(self, args)
    self.m_playAnimationOutMsg = MessageConst.PLAY_FAC_QUICK_BAR_OUT_ANIM
    self.m_showMsg = MessageConst.SHOW_FAC_QUICK_BAR
    self.m_hideMsg = MessageConst.HIDE_FAC_QUICK_BAR
    FacQuickBarPlaceHolder.Super._InitPlaceholder(self, args)
end
FacQuickBarPlaceHolder.GetArgs = HL.Override().Return(HL.Table) << function(self)
    return { panelId = self.m_panelId, offset = self.config.PANEL_ORDER_OFFSET, showBelt = self.config.SHOW_BELT, showPipe = self.config.SHOW_PIPE, useController = self.config.USE_CONTROLLER, }
end
FacQuickBarPlaceHolder.GetNaviGroup = HL.Method().Return(HL.Opt(CS.Beyond.UI.UISelectableNaviGroup)) << function(self)
    local succ, panelCtrl = UIManager:IsOpen(PanelId.FacQuickBar)
    if succ then
        return panelCtrl.naviGroup
    end
end
FacQuickBarPlaceHolder.GetInputBindingGroupId = HL.Method().Return(HL.Opt(HL.Number)) << function(self)
    local succ, panelCtrl = UIManager:IsOpen(PanelId.FacQuickBar)
    if succ then
        return panelCtrl.view.inputGroup.groupId
    end
end
HL.Commit(FacQuickBarPlaceHolder)
return FacQuickBarPlaceHolder