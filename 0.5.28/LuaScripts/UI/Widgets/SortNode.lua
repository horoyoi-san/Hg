local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SortNode = HL.Class('SortNode', UIWidgetBase)
SortNode.isIncremental = HL.Field(HL.Boolean) << false
SortNode.m_tmpNoCallback = HL.Field(HL.Boolean) << false
SortNode.m_sortOptions = HL.Field(HL.Table)
SortNode.m_onSortChanged = HL.Field(HL.Function)
SortNode.m_onToggleOptList = HL.Field(HL.Function)
SortNode.m_changeIncrementalBindingId = HL.Field(HL.Number) << -1
SortNode._OnFirstTimeInit = HL.Override() << function(self)
    self.view.isIncrementalButton.onClick:AddListener(function()
        self:_ToggleIncremental()
    end)
    self.view.dropDown:Init(function(index, option, isSelected)
        local sortOption = self.m_sortOptions[LuaIndex(index)]
        if sortOption then
            option:SetText(self.m_sortOptions[LuaIndex(index)].name)
        end
    end, function(index)
        if not self.m_tmpNoCallback then
            self:_OnSortChanged()
        end
    end)
    self.view.dropDown.onToggleOptList:AddListener(function(active)
        self:_OnToggleOptList(active)
    end)
end
SortNode._ToggleIncremental = HL.Method() << function(self)
    self.isIncremental = not self.isIncremental
    self:_RefreshIncremental()
    self:_OnSortChanged()
end
SortNode._OnToggleOptList = HL.Method(HL.Boolean) << function(self, active)
    if not DeviceInfo.usingController then
        return
    end
    Notify(MessageConst.SHOW_SORT_POP_OUT, {
        sortOptions = self.m_sortOptions,
        onSortConfirm = function(optionIndex, isAscending)
            self.view.dropDown:SetSelected(optionIndex - 1)
            self.isIncremental = isAscending
            self:_RefreshIncremental()
            self:_OnSortChanged()
        end,
        curIndex = self.view.dropDown.selectedIndex,
        curIsAscending = self.isIncremental,
    })
end
SortNode.InitSortNode = HL.Method(HL.Table, HL.Function, HL.Opt(HL.Number, HL.Boolean, HL.Boolean)) << function(self, sortOptions, onSortChanged, curCSOptionIndex, curIsIncremental, noCallback)
    self:_FirstTimeInit()
    if curIsIncremental == nil then
        self.isIncremental = self.config.DEFAULT_IS_INCREMENTAL
    else
        self.isIncremental = curIsIncremental
    end
    self.m_onSortChanged = onSortChanged
    self.m_sortOptions = sortOptions
    self.m_onToggleOptList = nil
    self:_RefreshIncremental()
    self.m_tmpNoCallback = noCallback == true
    if sortOptions ~= nil and next(sortOptions) ~= nil then
        if curCSOptionIndex then
            self.view.dropDown:Refresh(#self.m_sortOptions, curCSOptionIndex)
        else
            self.view.dropDown:Refresh(#self.m_sortOptions)
        end
    end
    self.m_tmpNoCallback = false
    self.view.dropDown:SetSelected(curCSOptionIndex, true, false)
end
SortNode.SetOnToggleOptListCallback = HL.Method(HL.Function) << function(self, callback)
    self.m_onToggleOptList = callback
end
SortNode._OnSortChanged = HL.Method() << function(self)
    local sortOptData = self:GetCurSortData()
    self.m_onSortChanged(sortOptData, self.isIncremental)
end
SortNode.GetCurSortData = HL.Method().Return(HL.Table) << function(self)
    local data = self.m_sortOptions[LuaIndex(self.view.dropDown.selectedIndex)]
    return data
end
SortNode.GetCurSelectedIndex = HL.Method().Return(HL.Number) << function(self)
    return LuaIndex(self.view.dropDown.selectedIndex)
end
SortNode.GetCurSortKeys = HL.Method().Return(HL.Opt(HL.Table)) << function(self)
    local sortOptData = self:GetCurSortData()
    return sortOptData.keys
end
SortNode.SortCurData = HL.Method() << function(self)
    if self.m_sortOptions then
        self:_OnSortChanged()
    end
end
SortNode._RefreshIncremental = HL.Method() << function(self)
    self.view.isIncrementalButton.text = self.isIncremental and Language.LUA_SORT_NODE_UP or Language.LUA_SORT_NODE_DOWN
    self.view.orderImage.transform.localScale = Vector3(1, self.isIncremental and -1 or 1, 1)
end
HL.Commit(SortNode)
return SortNode