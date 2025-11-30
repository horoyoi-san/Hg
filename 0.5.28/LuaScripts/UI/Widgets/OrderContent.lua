local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
OrderContent = HL.Class('OrderContent', UIWidgetBase)
OrderContent.m_rewardItemCache = HL.Field(HL.Forward("UIListCache"))
OrderContent.m_costItemCache = HL.Field(HL.Forward("UIListCache"))
OrderContent._OnFirstTimeInit = HL.Override() << function(self)
    self.m_rewardItemCache = UIUtils.genCellCache(self.view.rewardItem)
    self.m_costItemCache = UIUtils.genCellCache(self.view.costItem)
end
OrderContent.InitOrderContent = HL.Method(HL.String, HL.Number, HL.String) << function(self, orderId, index, domainId)
    self:_FirstTimeInit()
    local orderData = Tables.settlementOrderDataTable[orderId]
    local rewardData = Tables.rewardTable[orderData.rewardId]
    self.view.indexText.text = tostring(index)
    self.view.orderName.text = orderData.name
    local rewardItemBundles = {}
    if Tables.settlementOrderDataTable[orderId].stmExp > 0 then
        table.insert(rewardItemBundles, { id = Tables.settlementConst.stmExpItemId, count = Tables.settlementOrderDataTable[orderId].stmExp })
    end
    for _, itemBundles in pairs(rewardData.itemBundles) do
        if itemBundles.count > 0 then
            table.insert(rewardItemBundles, { id = itemBundles.id, count = itemBundles.count, })
        end
    end
    self.m_rewardItemCache:Refresh(#rewardItemBundles, function(cell, luaIndex)
        cell:InitItem(rewardItemBundles[luaIndex], true)
    end)
    self.m_costItemCache:Refresh(#orderData.costItems, function(cell, luaIndex)
        local costItem = orderData.costItems[luaIndex - 1]
        local storageCount = Utils.getDepotItemCount(costItem.id, nil, domainId)
        cell.Item:InitItem(costItem, true)
        cell.numberText.text = tostring(storageCount)
        if costItem.count > storageCount then
            cell.numberText.color = self.view.config.NUMBER_TEXT_COLOR_RED
        else
            cell.numberText.color = self.view.config.NUMBER_TEXT_COLOR_NORMAL
        end
    end)
end
HL.Commit(OrderContent)
return OrderContent