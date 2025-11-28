local autoCalcOrderUICtrl = require_ex('UI/Panels/Base/AutoCalcOrderUICtrl')
local PANEL_ID = PanelId.WalletBar
WalletBarCtrl = HL.Class('WalletBarCtrl', autoCalcOrderUICtrl.AutoCalcOrderUICtrl)
WalletBarCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.HIDE_WALLET_BAR] = 'HideWalletBar', [MessageConst.HIDE_WALLET_BAR_FORCE] = 'HideWalletBarForce', [MessageConst.SHOW_WALLET_BAR_FORCE] = 'ShowWalletBarForce', [MessageConst.PLAY_WALLET_BAR_OUT_ANIM] = 'PlayOutAnim', [MessageConst.ON_BLOCK_KEYBOARD_EVENT_PANEL_ORDER_CHANGED] = 'PanelOrderChanged', }
WalletBarCtrl.m_moneyCells = HL.Field(HL.Forward('UIListCache'))
WalletBarCtrl.m_defaultPaddingTop = HL.Field(HL.Number) << -1
WalletBarCtrl.m_defaultPaddingRight = HL.Field(HL.Number) << -1
WalletBarCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_moneyCells = UIUtils.genCellCache(self.view.moneyCell)
    self.m_attachedPanels = {}
    local padding = self.view.contentLayout.padding
    self.m_defaultPaddingTop = padding.top
    self.m_defaultPaddingRight = padding.right
end
WalletBarCtrl.ShowWalletBar = HL.StaticMethod(HL.Table) << function(args)
    local ctrl = WalletBarCtrl.AutoOpen(PANEL_ID, nil, true)
    ctrl:_AttachToPanel(args)
end
WalletBarCtrl.HideWalletBar = HL.Method(HL.Number) << function(self, panelId)
    self:_CustomHide(panelId)
end
WalletBarCtrl.HideWalletBarForce = HL.Method() << function(self)
    self:Hide()
end
WalletBarCtrl.ShowWalletBarForce = HL.Method() << function(self)
    self:Show()
end
WalletBarCtrl.CustomSetPanelOrder = HL.Override(HL.Opt(HL.Number, HL.Table)) << function(self, maxOrder, args)
    self:SetSortingOrder(maxOrder, false)
    self:UpdateInputGroupState()
    self.m_curArgs = args
    self:_RefreshContent()
    if self:IsShow(true) then
    else
        self:Show()
    end
end
WalletBarCtrl._RefreshContent = HL.Method() << function(self)
    if not self.m_curArgs then
        return
    end
    local padding = self.view.contentLayout.padding
    padding.right = lume.round(self.m_curArgs.paddingRight or self.m_defaultPaddingRight)
    padding.top = lume.round(self.m_curArgs.paddingTop or self.m_defaultPaddingTop)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.contentLayout.transform)
    local moneyIds = self.m_curArgs.moneyIds
    if moneyIds ~= nil then
        self.m_moneyCells:Refresh(#moneyIds, function(cell, index)
            local itemId = moneyIds[index]
            cell:InitMoneyCell(itemId, self.m_curArgs.useMoneyCellAction, self.m_curArgs.useItemIcon)
        end)
    end
end
HL.Commit(WalletBarCtrl)