local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
RewardItems = HL.Class('RewardItems', UIWidgetBase)
RewardItems.m_getCell = HL.Field(HL.Function)
RewardItems.m_items = HL.Field(HL.Table)
RewardItems.m_collected = HL.Field(HL.Boolean) << false
RewardItems._OnFirstTimeInit = HL.Override() << function(self)
    self.m_getCell = UIUtils.genCachedCellFunction(self.view.scrollList)
    self.view.scrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateCell(self.m_getCell(obj), LuaIndex(csIndex))
    end)
end
RewardItems.InitRewardItems = HL.Method(HL.Any, HL.Opt(HL.Boolean)) << function(self, items, collected)
    self:_FirstTimeInit()
    if type(items) == "string" then
        local rewardId = items
        items = UIUtils.getRewardItems(rewardId)
    end
    self.m_items = items
    local count = #self.m_items
    if self.config.MAX_SHOW_COUNT > 0 then
        count = math.min(count, self.config.MAX_SHOW_COUNT)
    end
    self.m_collected = collected == true
    self.view.scrollList:UpdateCount(count)
end
RewardItems._OnUpdateCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local bundle = self.m_items[index]
    cell:InitItem(bundle, true)
    cell.view.rewardedCover.gameObject:SetActive(self.m_collected)
end
HL.Commit(RewardItems)
return RewardItems