local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SettlementOrderItem = HL.Class('SettlementOrderItem', UIWidgetBase)
SettlementOrderItem.m_rewardItemCache = HL.Field(HL.Forward("UIListCache"))
SettlementOrderItem.m_costItemCache = HL.Field(HL.Forward("UIListCache"))
SettlementOrderItem._OnFirstTimeInit = HL.Override() << function(self)
    self.m_rewardItemCache = UIUtils.genCellCache(self.view.rewardItem)
    if self.view.costItem ~= nil then
        self.m_costItemCache = UIUtils.genCellCache(self.view.costItem)
    end
end
SettlementOrderItem.InitSettlementOrderItem = HL.Method(HL.String) << function(self, settlementId)
    self:_FirstTimeInit()
    local settlementSystem = GameInstance.player.settlementSystem
    local orderId = settlementSystem:GetSettlementOrderId(settlementId)
    local orderData = Tables.settlementOrderDataTable[orderId]
    local rewardData = Tables.rewardTable[orderData.rewardId]
    if self.view.nameText then
        self.view.nameText.text = orderData.name
    end
    local exact, isEnhanced = settlementSystem:GetExactExpReward(settlementId)
    local rewardItemBundles = {}
    if exact.Item1 > 0 then
        local rewardItemBundle = { id = Tables.settlementConst.stmExpItemId, count = exact.Item1, isEnhanced = isEnhanced }
        table.insert(rewardItemBundles, rewardItemBundle)
    end
    local rewardEnhanced = exact.Item2 == 0 and 1 or exact.Item2
    for _, itemBundles in pairs(rewardData.itemBundles) do
        if itemBundles.count > 0 then
            table.insert(rewardItemBundles, { id = itemBundles.id, count = math.floor(itemBundles.count * rewardEnhanced), isEnhanced = rewardEnhanced > 1 })
        end
    end
    self.m_rewardItemCache:Refresh(#rewardItemBundles, function(cell, luaIndex)
        cell.gameObject.name = "Item_" .. rewardItemBundles[luaIndex].id
        cell:InitItem(rewardItemBundles[luaIndex], true)
        if rewardItemBundles[luaIndex].isEnhanced then
            cell.view.count.color = self.view.config.COUNT_TEXT_COLOR_UP
        else
            cell.view.count.color = self.view.config.COUNT_TEXT_COLOR_NORMAL
        end
    end)
    if self.view.costItem ~= nil then
        self.m_costItemCache:Refresh(#orderData.costItems, function(cell, luaIndex)
            cell:InitItem(orderData.costItems[luaIndex - 1], true)
        end)
    end
end
HL.Commit(SettlementOrderItem)
return SettlementOrderItem