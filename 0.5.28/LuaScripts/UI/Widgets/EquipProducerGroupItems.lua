local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
EquipProducerGroupItems = HL.Class('EquipProducerGroupItems', UIWidgetBase)
local UNLOCK_DESC = { [GEnums.EquipFormulaUnlockType.DefaultUnlock] = "", [GEnums.EquipFormulaUnlockType.AdventureLevel] = Language.ui_produce_formul_level, [GEnums.EquipFormulaUnlockType.MapExploration] = Language.ui_produce_formul_map, }
EquipProducerGroupItems.m_itemList = HL.Field(HL.Table)
EquipProducerGroupItems.m_itemCellList = HL.Field(HL.Table)
EquipProducerGroupItems.m_equipTechSystem = HL.Field(HL.Userdata)
EquipProducerGroupItems._OnFirstTimeInit = HL.Override() << function(self)
end
EquipProducerGroupItems.InitEquipProducerGroupItems = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    self.m_itemList = args.itemList
    self.m_equipTechSystem = GameInstance.player.equipTechSystem
    CSUtils.UIContainerResize(self.view.itemNode, #self.m_itemList)
    self.m_itemCellList = {}
    for i, itemInfo in ipairs(self.m_itemList) do
        local cell = Utils.wrapLuaNode(self.view.itemNode:GetChild(i - 1))
        table.insert(self.m_itemCellList, cell)
        local equipFormulaData = itemInfo.equipFormulaData
        cell.item:InitItem({ id = itemInfo.id }, function()
            args.onItemClicked(cell, itemInfo)
        end)
        cell.item.view.levelNode.gameObject:SetActive(itemInfo.isUnlocked)
        cell.redDot:InitRedDot("EquipFormula", equipFormulaData.formulaId)
        cell.gameObject.name = itemInfo.id
        local isCostEnough = true
        if itemInfo.isUnlocked then
            isCostEnough = self:_GetCostEnough(equipFormulaData)
        else
            cell.lockTxt.text = UNLOCK_DESC[equipFormulaData.unlockType]
        end
        cell.lockNode.gameObject:SetActive(not itemInfo.isUnlocked)
        cell.insufficientNode.gameObject:SetActive(itemInfo.isUnlocked and not isCostEnough)
        if args.isFirstItemSelected and i == 1 then
            args.onItemClicked(cell, itemInfo)
        end
    end
    self.view.titleNode.gameObject:SetActive(not self.m_itemList or #self.m_itemList == 0)
end
EquipProducerGroupItems.RefreshCostEnough = HL.Method() << function(self)
    for i, itemInfo in ipairs(self.m_itemList) do
        if itemInfo.isUnlocked then
            local cell = self.m_itemCellList[i]
            local isCostEnough = self:_GetCostEnough(itemInfo.equipFormulaData)
            cell.insufficientNode.gameObject:SetActive(itemInfo.isUnlocked and not isCostEnough)
        end
    end
end
EquipProducerGroupItems._GetCostEnough = HL.Method(HL.Userdata).Return(HL.Boolean) << function(self, equipFormulaData)
    local isCostEnough = true
    for i = 0, equipFormulaData.costItemId.Count - 1 do
        local itemId = equipFormulaData.costItemId[i]
        if not string.isEmpty(itemId) and i < equipFormulaData.costItemNum.Count and equipFormulaData.costItemNum[i] > Utils.getItemCount(itemId, true, true) then
            isCostEnough = false
            break
        end
    end
    return isCostEnough
end
HL.Commit(EquipProducerGroupItems)
return EquipProducerGroupItems