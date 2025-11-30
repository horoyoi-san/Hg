local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
FacCraftList = HL.Class('FacCraftList', UIWidgetBase)
FacCraftList.m_typeCells = HL.Field(HL.Forward('UIListCache'))
FacCraftList.m_typeIndex = HL.Field(HL.Number) << 1
FacCraftList.m_crafts = HL.Field(HL.Table)
FacCraftList.m_sortOptions = HL.Field(HL.Table)
FacCraftList.curList = HL.Field(HL.Table)
FacCraftList.craftList = HL.Field(CS.Beyond.UI.UIScrollList)
FacCraftList.m_customOnClickType = HL.Field(HL.Function)
FacCraftList.m_customOnRefreshList = HL.Field(HL.Function)
FacCraftList.m_filterTags = HL.Field(HL.Table)
FacCraftList._OnCreate = HL.Override() << function(self)
    self.craftList = self.view.craftList
end
FacCraftList._OnFirstTimeInit = HL.Override() << function(self)
    local inInit = true
    self.m_typeCells = UIUtils.genCellCache(self.view.typesNode.typeCell)
    self.m_sortOptions = { { name = Language.LUA_FAC_CRAFT_SORT_1, keys = { "sortId", "rarity", "id" }, }, { name = Language.LUA_FAC_CRAFT_SORT_2, keys = { "rarity", "sortId", "id" }, }, }
    self.view.sortNode:InitSortNode(self.m_sortOptions, function(optData, isIncremental)
        self:_OnSortChanged(optData, isIncremental)
    end, nil, true, true)
    local filterTagGroups = {}
    for _, v in pairs(Tables.factorySpecialCraftTable) do
        local info = { name = v.name, groupId = v.recipeGroupId, sortId = v.sortId, }
        table.insert(filterTagGroups, info)
    end
    table.sort(filterTagGroups, Utils.genSortFunction({ "sortId" }, true))
    self.view.filterBtn:InitFilterBtn({
        tagGroups = { { tags = filterTagGroups } },
        onConfirm = function(tags)
            if inInit then
                return
            end
            if tags then
                self.m_filterTags = {}
                for _, v in ipairs(tags) do
                    self.m_filterTags[v.groupId] = true
                end
            else
                self.m_filterTags = nil
            end
            self:_ApplyFilter()
            self:RefreshCraftList()
        end,
        getResultCount = function(tags)
            return self:_GetContentFilterResultCount(tags)
        end,
    })
    inInit = false
end
FacCraftList._ApplyFilter = HL.Method() << function(self)
    local tags = self.m_filterTags
    local allCraftList = self.m_crafts[self.m_typeIndex].list
    local curList = {}
    for _, v in ipairs(allCraftList) do
        if not tags then
            table.insert(curList, v)
        else
            for _, groupId in pairs(v.data.belongingGroupIds) do
                if tags[groupId] then
                    table.insert(curList, v)
                    break
                end
            end
        end
    end
    self.curList = curList
end
FacCraftList._GetContentFilterResultCount = HL.Method(HL.Opt(HL.Table)).Return(HL.Number) << function(self, tags)
    local tagDic = {}
    for _, v in ipairs(tags) do
        tagDic[v.groupId] = true
    end
    local allCraftList = self.m_crafts[self.m_typeIndex].list
    local count = 0
    for _, v in ipairs(allCraftList) do
        for _, groupId in pairs(v.data.belongingGroupIds) do
            if tagDic[groupId] then
                count = count + 1
                break
            end
        end
    end
    return count
end
FacCraftList.InitFacCraftList = HL.Method(HL.Table, HL.Opt(HL.Function, HL.Function)) << function(self, crafts, onClickType, onRefresh)
    self:_FirstTimeInit()
    self.m_typeIndex = 1
    self.m_crafts = {}
    self.m_customOnClickType = onClickType
    self.m_customOnRefreshList = onRefresh
    for i = 1, #crafts do
        if #crafts[i].list > 0 then
            table.insert(self.m_crafts, crafts[i])
        end
    end
    self.m_typeCells:Refresh(#self.m_crafts, function(cell, index)
        local info = self.m_crafts[index]
        cell.gameObject.name = "Cell_" .. index
        if cell.name then
            cell.name.text = info.name
        end
        if cell.dimName then
            cell.dimName.text = info.name
        end
        if cell.lightName then
            cell.lightName.text = info.name
        end
        if info.icon then
            local sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_WORKSHOP_CRAFT_TYPE_ICON, info.icon)
            cell.lightIcon.sprite = sprite
            cell.dimIcon.sprite = sprite
            cell.lightIconShadow:LoadSprite(UIConst.UI_SPRITE_FAC_WORKSHOP_CRAFT_TYPE_ICON, info.icon .. "_shadow")
        end
        cell.toggle.isOn = index == self.m_typeIndex
        cell.toggle.onValueChanged:AddListener(function(isOn)
            if isOn then
                self:_OnClickType(index)
            end
        end)
    end)
    self:_OnClickType(self.m_typeIndex, true)
    self.view.sortNode:SortCurData()
end
FacCraftList._OnClickType = HL.Method(HL.Number, HL.Opt(HL.Boolean)) << function(self, typeIndex, isInit)
    if not isInit and self.m_typeIndex == typeIndex then
        return
    end
    self.m_typeIndex = typeIndex
    local info = self.m_crafts[typeIndex]
    self.view.titleTxt.text = info.name
    self:_ApplyFilter()
    if not isInit then
        if self.m_customOnClickType then
            self.m_customOnClickType()
        end
        self:RefreshCraftList()
    end
end
FacCraftList.RefreshCraftList = HL.Method() << function(self)
    local count = #self.curList
    self.craftList:UpdateCount(count)
    self.view.emptyNode.gameObject:SetActive(count == 0)
    if self.m_customOnRefreshList then
        self.m_customOnRefreshList()
    end
end
FacCraftList._OnSortChanged = HL.Method(HL.Table, HL.Boolean) << function(self, optData, isIncremental)
    self:_SortData(optData.keys, isIncremental)
    self:_ApplyFilter()
    self:RefreshCraftList()
end
FacCraftList._SortData = HL.Method(HL.Table, HL.Boolean) << function(self, keys, isIncremental)
    for _, v in ipairs(self.m_crafts) do
        table.sort(v.list, Utils.genSortFunction(keys, isIncremental))
    end
end
HL.Commit(FacCraftList)
return FacCraftList