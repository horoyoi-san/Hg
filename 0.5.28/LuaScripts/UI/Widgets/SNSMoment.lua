local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSMoment = HL.Class('SNSMoment', UIWidgetBase)
SNSMoment.m_unreadCount = HL.Field(HL.Number) << 0
SNSMoment.m_moments = HL.Field(HL.Table)
SNSMoment.m_getCellFunc = HL.Field(HL.Function)
SNSMoment._OnFirstTimeInit = HL.Override() << function(self)
    self.m_getCellFunc = UIUtils.genCachedCellFunction(self.view.scrollList)
    self.view.scrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateMomentCell(self.m_getCellFunc(obj), LuaIndex(csIndex))
    end)
end
SNSMoment.InitSNSMoment = HL.Method() << function(self)
    self:_FirstTimeInit()
    local unreadMoments = {}
    local readMoments = {}
    self.m_moments = {}
    for k, v in pairs(GameInstance.player.sns.momentInfoDic) do
        local data = { id = v.momentId, ts = v.timestamp, }
        if v.hasRead then
            table.insert(readMoments, data)
        else
            table.insert(unreadMoments, data)
        end
    end
    table.sort(unreadMoments, function(a, b)
        return a.ts > b.ts
    end)
    table.sort(readMoments, function(a, b)
        return a.ts > b.ts
    end)
    for i, v in ipairs(unreadMoments) do
        table.insert(self.m_moments, v.id)
    end
    for i, v in ipairs(readMoments) do
        table.insert(self.m_moments, v.id)
    end
    self.m_unreadCount = #unreadMoments
    self.view.scrollList:UpdateCount(#self.m_moments)
    self.view.jumpBtn.onClick:RemoveAllListeners()
    if self.m_unreadCount == 0 then
        self.view.jumpBtnNode.gameObject:SetActiveIfNecessary(false)
    else
        self.view.jumpBtnNode.gameObject:SetActiveIfNecessary(true)
        self.view.jumpBtn.onClick:AddListener(function()
            self:_JumpToUnRead()
        end)
    end
end
SNSMoment._OnUpdateMomentCell = HL.Method(HL.Any, HL.Number) << function(self, cell, luaIndex)
    cell:InitSNSMomentCell(self.m_moments[luaIndex], function()
        local transform = cell.transform
        LayoutRebuilder.ForceRebuildLayoutImmediate(transform)
        self.view.scrollList:NotifyCellSizeChange(CSIndex(luaIndex), transform.sizeDelta.y)
    end)
    cell.view.dividerNode.gameObject:SetActiveIfNecessary(luaIndex == self.m_unreadCount and self.m_unreadCount < #self.m_moments)
end
SNSMoment._JumpToUnRead = HL.Method() << function(self)
    self.view.scrollList:ScrollToIndex(CSIndex(self.m_unreadCount))
end
SNSMoment.JumpToMoment = HL.Method(HL.String) << function(self, momentId)
    local jumpIndex = lume.find(self.m_moments, momentId)
    if jumpIndex then
        self.view.scrollList:ScrollToIndex(CSIndex(jumpIndex), true)
    end
end
HL.Commit(SNSMoment)
return SNSMoment