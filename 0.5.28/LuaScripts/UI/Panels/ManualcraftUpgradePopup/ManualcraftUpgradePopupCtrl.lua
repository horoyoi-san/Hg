local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ManualcraftUpgradePopup
ManualcraftUpgradePopupCtrl = HL.Class('ManualcraftUpgradePopupCtrl', uiCtrl.UICtrl)
ManualcraftUpgradePopupCtrl.m_index = HL.Field(HL.Number) << 0
ManualcraftUpgradePopupCtrl.m_itemList = HL.Field(HL.Table)
ManualcraftUpgradePopupCtrl.m_cellList = HL.Field(HL.Any)
ManualcraftUpgradePopupCtrl.s_messages = HL.StaticField(HL.Table) << {}
ManualcraftUpgradePopupCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_index = 1
    self.m_itemList = {}
    for i = 1, #arg.itemList do
        table.insert(self.m_itemList, arg.itemList[i])
    end
    self.view.closeButton.onClick:AddListener(function()
        UIManager:Close(PANEL_ID)
    end)
    self.view.mask.onClick:AddListener(function()
        if self.m_index == #self.m_itemList then
            UIManager:Close(PANEL_ID)
        else
            self.m_index = #self.m_itemList
            self:_OnUpdateUI()
        end
    end)
    self.view.btnLeftArrow.onClick:AddListener(function()
        if self.m_index > 1 then
            self.m_index = self.m_index - 1
            self:_OnUpdateUI()
        end
    end)
    self.view.btnRightArrow.onClick:AddListener(function()
        if self.m_index < #self.m_itemList then
            self.m_index = self.m_index + 1
            self:_OnUpdateUI()
        end
    end)
    self.m_cellList = UIUtils.genCellCache(self.view.cell)
    self:_OnUpdateUI()
end
ManualcraftUpgradePopupCtrl._OnUpdateUI = HL.Method() << function(self)
    local id = self.m_itemList[self.m_index]
    local rewardId = Tables.factoryManualCraftFormulaUnlockTable:GetValue(id).rewardItemId1
    local itemId = Tables.factoryManualCraftUpgradeTable:GetValue(rewardId).levelUpItemId
    local levelUpData = Tables.equipItemTable:GetValue(itemId)
    local data = Tables.itemTable:GetValue(itemId)
    self.view.itemText.text = data.name
    self.view.itemIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, data.iconId)
    self.view.btnLeftArrow.gameObject:SetActive(self.m_index > 1)
    self.view.btnRightArrow.gameObject:SetActive(self.m_index < #self.m_itemList)
    self.view.bottomText.text = string.format(Language.LUA_FAC_MANUAL_CRAFT_LEVEL_UP, data.name)
    self.view.beforeNum.text = levelUpData.chargeCount
    self.view.afterNum.text = levelUpData.levelUpChargeCount
    self.m_cellList:Refresh(#self.m_itemList, function(cell, index)
        cell.selected.gameObject:SetActive(index == self.m_index)
        cell.defalut.gameObject:SetActive(index ~= self.m_index)
    end)
end
HL.Commit(ManualcraftUpgradePopupCtrl)