local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.DesEquipPopUp
DesEquipPopUpCtrl = HL.Class('DesEquipPopUpCtrl', uiCtrl.UICtrl)
DesEquipPopUpCtrl.s_messages = HL.StaticField(HL.Table) << {}
DesEquipPopUpCtrl.m_args = HL.Field(HL.Table)
DesEquipPopUpCtrl.m_getItemCell = HL.Field(HL.Function)
DesEquipPopUpCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.view.confirmButton.onClick:AddListener(function()
        self:_OnClickConfirm()
    end)
    self.view.cancelButton.onClick:AddListener(function()
        self:_OnClickCancel()
    end)
    self.m_getItemCell = UIUtils.genCachedCellFunction(self.view.itemScrollList)
    self.view.itemScrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateItemCell(self.m_getItemCell(obj), LuaIndex(csIndex))
    end)
    self.m_args = args
    self.view.itemScrollList:UpdateCount(#self.m_args.items)
    local returnId = self.m_args.returnItemId
    local returnCount = self.m_args.returnItemCount
    self.view.returnItem:InitItem({ id = returnId, count = returnCount }, true)
    local needReturnOverHint = not GameInstance.player.inventory:CanItemBagOrValuableDepotPutInItem(Utils.getCurrentScope(), returnId, returnCount)
    self.view.returnOverHint.gameObject:SetActive(needReturnOverHint)
end
DesEquipPopUpCtrl._OnUpdateItemCell = HL.Method(HL.Forward("Item"), HL.Number) << function(self, cell, index)
    cell:InitItem(self.m_args.items[index], true)
end
DesEquipPopUpCtrl._OnClickConfirm = HL.Method() << function(self)
    local args = self.m_args
    self:PlayAnimationOutWithCallback(function()
        self:Close()
        if args.onConfirm then
            args.onConfirm()
        end
    end)
end
DesEquipPopUpCtrl._OnClickCancel = HL.Method() << function(self)
    local onCancel = self.m_args.onCancel
    self:PlayAnimationOutWithCallback(function()
        self:Close()
        if onCancel then
            onCancel()
        end
    end)
end
HL.Commit(DesEquipPopUpCtrl)