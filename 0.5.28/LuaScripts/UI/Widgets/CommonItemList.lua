local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
local LIST_CONFIG = { [UIConst.COMMON_ITEM_LIST_TYPE.WEAPON_EXHIBIT_GEM] = { infoProcessFunc = "processWeaponGem", filterTagGroupFunc = "generateConfig_WEAPON_EXHIBIT_GEM", sortOption = UIConst.WEAPON_GEM_SORT_OPTION, getDepotFunc = "_GetWeaponGemDepot" }, [UIConst.COMMON_ITEM_LIST_TYPE.GEM_RECAST] = { infoProcessFunc = "processWeaponGem", filterTagGroupFunc = "generateConfig_DEPOT_GEM", sortOption = UIConst.WEAPON_GEM_SORT_OPTION, getDepotFunc = "_GetWeaponGemDepot", }, [UIConst.COMMON_ITEM_LIST_TYPE.WEAPON_EXHIBIT_UPGRADE] = { infoProcessFunc = "processWeaponUpgradeIngredient", sortOption = UIConst.WEAPON_SORT_OPTION, getDepotFunc = "_GetWeaponUpgradeDepot", filterTagGroupFunc = "generateConfig_CHAR_INFO_WEAPON", }, [UIConst.COMMON_ITEM_LIST_TYPE.WEAPON_EXHIBIT_POTENTIAL] = { infoProcessFunc = "processWeaponPotential", sortOption = UIConst.WEAPON_POTENTIAL_SORT_OPTION, hideSort = true, hideFilter = true, getDepotFunc = "_GetWeaponDepot", }, [UIConst.COMMON_ITEM_LIST_TYPE.CHAR_INFO_WEAPON] = { infoProcessFunc = "processWeapon", sortOption = UIConst.WEAPON_SORT_OPTION, getDepotFunc = "_GetWeaponDepot", filterTagGroupFunc = "generateConfig_CHAR_INFO_WEAPON", }, [UIConst.COMMON_ITEM_LIST_TYPE.CHAR_INFO_EQUIP] = { infoProcessFunc = "processEquip", sortOption = UIConst.EQUIP_SORT_OPTION, filterTagGroupFunc = "generateConfig_EQUIP_ENHANCE", getDepotFunc = "_GetEquipDepot" }, [UIConst.COMMON_ITEM_LIST_TYPE.CHAR_INFO_TACTICAL_ITEM] = { infoProcessFunc = "processTacticalItem", sortOption = UIConst.TACTICAL_ITEM_SORT_OPTION, filterTagGroupFunc = "generateConfig_TACTICAL_ITEM", getDepotFunc = "_GetTacticalItemDepot" }, [UIConst.COMMON_ITEM_LIST_TYPE.EQUIP_TECH_EQUIP_ENHANCE] = { infoProcessFunc = "processEquipEnhance", filterTagGroupFunc = "generateConfig_EQUIP_ENHANCE", sortOption = EquipTechConst.EQUIP_ENHANCE_SORT_OPTION, getDepotFunc = "_GetEquipEnhanceDepot" }, [UIConst.COMMON_ITEM_LIST_TYPE.EQUIP_TECH_EQUIP_ENHANCE_MATERIALS] = { infoProcessFunc = "processEquipEnhanceMaterial", filterTagGroupFunc = "generateConfig_EQUIP_ENHANCE_MATERIALS", sortOption = EquipTechConst.EQUIP_ENHANCE_MATERIALS_SORT_OPTION, getDepotFunc = "_GetEquipEnhanceMaterialsDepot" }, }
CommonItemList = HL.Class('CommonItemList', UIWidgetBase)
CommonItemList.m_getItemCell = HL.Field(HL.Function)
CommonItemList.m_itemInfoList = HL.Field(HL.Table)
CommonItemList.m_filteredInfoList = HL.Field(HL.Table)
CommonItemList.m_selectedTags = HL.Field(HL.Table)
CommonItemList.m_curSelectIndex = HL.Field(HL.Number) << 0
CommonItemList.m_curSelectId = HL.Field(HL.Any) << 0
CommonItemList.m_filterTagGroups = HL.Field(HL.Table)
CommonItemList.m_arg = HL.Field(HL.Table)
CommonItemList.m_onClickItem = HL.Field(HL.Function)
CommonItemList.m_onFinishGraduallyShow = HL.Field(HL.Function)
CommonItemList.m_onLongPressItem = HL.Field(HL.Function)
CommonItemList.m_onPressItem = HL.Field(HL.Function)
CommonItemList.m_onReleaseItem = HL.Field(HL.Function)
CommonItemList.m_refreshItemAddOn = HL.Field(HL.Function)
CommonItemList.m_setItemSelected = HL.Field(HL.Function)
CommonItemList.m_getItemBtn = HL.Field(HL.Function)
CommonItemList.m_lastListType = HL.Field(HL.String) << ""
CommonItemList._OnFirstTimeInit = HL.Override() << function(self)
    self.m_getItemCell = UIUtils.genCachedCellFunction(self.view.itemList)
    self.view.itemList.onUpdateCell:AddListener(function(object, csIndex)
        self:_RefreshItemCell(object, LuaIndex(csIndex))
    end)
    self.view.itemList.onSelectedCell:AddListener(function(obj, csIndex)
        self:SetSelectedIndex(LuaIndex(csIndex), true)
    end)
    self.view.itemList.onGraduallyShowFinish:AddListener(function()
        if self.m_onFinishGraduallyShow then
            self.m_onFinishGraduallyShow()
        end
    end)
    self.view.itemList.getCurSelectedIndex = function()
        return CSIndex(self.m_curSelectIndex)
    end
    self:BindInputPlayerAction("char_list_select_up", function()
        self.view.itemList:NavigateSelected(CS.UnityEngine.UI.NaviDirection.Up)
    end)
    self:BindInputPlayerAction("char_list_select_down", function()
        self.view.itemList:NavigateSelected(CS.UnityEngine.UI.NaviDirection.Down)
    end)
    self:BindInputPlayerAction("char_list_select_left", function()
        self.view.itemList:NavigateSelected(CS.UnityEngine.UI.NaviDirection.Left)
    end)
    self:BindInputPlayerAction("char_list_select_right", function()
        self.view.itemList:NavigateSelected(CS.UnityEngine.UI.NaviDirection.Right)
    end)
end
CommonItemList.InitCommonItemList = HL.Method(HL.Table) << function(self, arg)
    self:_FirstTimeInit()
    self.m_arg = arg
    local listConfig = LIST_CONFIG[arg.listType]
    self.m_onClickItem = arg.onClickItem
    self.m_onFinishGraduallyShow = arg.onFinishGraduallyShow
    self.m_onLongPressItem = arg.onLongPressItem
    self.m_onPressItem = arg.onPressItem
    self.m_onReleaseItem = arg.onReleaseItem
    self.m_refreshItemAddOn = arg.refreshItemAddOn
    self.m_setItemSelected = arg.setItemSelected or function(cell, selected)
        if cell and cell.item then
            cell.item.view.selectedBG.gameObject:SetActive(selected)
        end
    end
    self.m_getItemBtn = arg.getItemBtn or function(cell)
        return cell.item.view.button
    end
    self.m_curSelectIndex = 0
    self.m_curSelectId = 0
    self.m_filteredInfoList = {}
    self.m_itemInfoList = {}
    if self.m_lastListType ~= arg.listType then
        self:_InitSortNode(listConfig)
        self:_InitFilterNode(listConfig)
    end
    self.m_lastListType = arg.listType
    self:Refresh(arg)
end
CommonItemList.PlayGraduallyShow = HL.Method() << function(self, arg)
    local selectIndex = self:_GetDefaultSelectIndex()
    self:_RefreshItemList(self.m_filteredInfoList, false, selectIndex)
end
CommonItemList.GetItemDepotCount = HL.Method().Return(HL.Number) << function(self)
    if not self.m_itemInfoList then
        return 0
    end
    return #self.m_itemInfoList
end
CommonItemList.GetItemInfoByIndex = HL.Method(HL.Number).Return(HL.Opt(HL.Table)) << function(self, index)
    if not self.m_filteredInfoList then
        return
    end
    return self.m_filteredInfoList[index]
end
CommonItemList.GetItemInfoByIndexId = HL.Method(HL.Any).Return(HL.Opt(HL.Table)) << function(self, indexId)
    if not self.m_filteredInfoList then
        return
    end
    for _, itemInfo in pairs(self.m_filteredInfoList) do
        if itemInfo.indexId == indexId then
            return itemInfo
        end
    end
end
CommonItemList.Refresh = HL.Method(HL.Table) << function(self, arg)
    local skipGraduallyShow = arg.skipGraduallyShow == true
    local itemInfoList = self:_CollectItemInfoList(LIST_CONFIG[self.m_arg.listType], self.m_arg)
    if not itemInfoList then
        return
    end
    local filteredList = self:_ApplyFilter(itemInfoList, self.m_selectedTags)
    filteredList = self:_ApplySort(filteredList, self.view.sortNode:GetCurSortData(), self.view.sortNode.isIncremental)
    if arg.onlyRefreshData then
        return
    end
    self.m_itemInfoList = itemInfoList
    self.m_filteredInfoList = filteredList
    local selectIndex = self:_GetDefaultSelectIndex()
    self:_RefreshItemList(filteredList, skipGraduallyShow, selectIndex)
end
CommonItemList.GetCurSelectedItem = HL.Method().Return(HL.Opt(HL.Any)) << function(self)
    local curGo = self.view.itemList:Get(CSIndex(self.m_curSelectIndex))
    if curGo then
        return curGo
    end
end
CommonItemList.IsAnyItemSelecting = HL.Method().Return(HL.Boolean) << function(self)
    return self.m_curSelectIndex > 0
end
CommonItemList.RefreshCellById = HL.Method(HL.Any) << function(self, id)
    for index, filteredInfo in pairs(self.m_filteredInfoList) do
        if type(filteredInfo.indexId) == type(id) and filteredInfo.indexId == id then
            local curGo = self.view.itemList:Get(CSIndex(index))
            if curGo then
                self:_RefreshItemCell(curGo, index)
            end
        end
    end
end
CommonItemList.RefreshCellByIndex = HL.Method(HL.Number) << function(self, index)
    local curGo = self.view.itemList:Get(CSIndex(index))
    if curGo then
        self:_RefreshItemCell(curGo, index)
    end
end
CommonItemList.RefreshAllCells = HL.Method() << function(self)
    for index, itemInfo in pairs(self.m_filteredInfoList) do
        local curGo = self.view.itemList:Get(CSIndex(index))
        if curGo then
            self:_RefreshItemCell(curGo, index)
        end
    end
end
CommonItemList.RefreshAllCellsItemAddOn = HL.Method() << function(self)
    for index, itemInfo in pairs(self.m_filteredInfoList) do
        local curGo = self.view.itemList:Get(CSIndex(index))
        if curGo then
            local listCell = self.m_getItemCell(curGo)
            if self.m_refreshItemAddOn then
                self.m_refreshItemAddOn(listCell, itemInfo)
            end
        end
    end
end
CommonItemList.SetSelectedId = HL.Method(HL.Any, HL.Boolean, HL.Opt(HL.Boolean)) << function(self, id, realClick, noScroll)
    if not id then
        self:SetSelectedIndex(1, realClick, noScroll)
        return
    end
    local index = self:_GetIndexByIndexId(id)
    if index then
        self:SetSelectedIndex(index, realClick, noScroll)
        return
    end
    self:SetSelectedIndex(1, realClick, noScroll)
end
CommonItemList.SetSelectedIndex = HL.Method(HL.Number, HL.Boolean, HL.Opt(HL.Boolean)) << function(self, luaIndex, realClick, noScroll)
    if luaIndex == nil then
        return
    end
    if not noScroll and CSIndex(luaIndex) >= 0 then
        self.view.itemList:ScrollToIndex(CSIndex(luaIndex), true)
    end
    local curCell
    local curGo = self.view.itemList:Get(CSIndex(self.m_curSelectIndex))
    if curGo then
        curCell = self.m_getItemCell(curGo)
        if curCell then
            self.m_setItemSelected(curCell, false)
        end
    end
    local nextCell
    local nextGo = self.view.itemList:Get(CSIndex(luaIndex))
    if nextGo then
        nextCell = self.m_getItemCell(nextGo)
        if nextCell then
            self.m_setItemSelected(nextCell, true)
        end
    end
    local selectedInfo = self.m_filteredInfoList[luaIndex]
    if not selectedInfo then
        return
    end
    self.m_curSelectIndex = luaIndex
    self.m_curSelectId = selectedInfo and self.m_filteredInfoList[luaIndex].indexId or 0
    if UNITY_EDITOR or DEVELOPMENT_BUILD then
        logger.info(string.format("CommonItemList->选中物品TemplateId [   %s   ]", selectedInfo.id))
    end
    if self.m_onClickItem then
        self.m_onClickItem({ itemInfo = selectedInfo, realClick = realClick, nextCell = nextCell, curCell = curCell })
    end
end
CommonItemList._GetIndexByIndexId = HL.Method(HL.Any).Return(HL.Opt(HL.Number)) << function(self, id)
    for index, filteredInfo in pairs(self.m_filteredInfoList) do
        if type(filteredInfo.indexId) == type(id) and filteredInfo.indexId == id then
            return index
        end
    end
end
CommonItemList._InitSortNode = HL.Method(HL.Table) << function(self, listConfig)
    local sortOption = listConfig.sortOption or {}
    self.view.sortNode.gameObject:SetActive(listConfig.hideSort ~= true)
    local sortCount = #sortOption
    self.view.sortNode:InitSortNode(sortOption, function(optData, isIncremental)
        local filteredList = self.m_filteredInfoList
        if not filteredList then
            return
        end
        filteredList = self:_ApplySort(filteredList, optData, isIncremental)
        self:_RefreshItemList(filteredList, false, 1, false)
        if #filteredList <= 0 then
            return
        end
    end, nil, false, true)
end
CommonItemList._InitFilterNode = HL.Method(HL.Table) << function(self, listConfig)
    local filterTagGroups = {}
    local filterTagGroupFunc = listConfig.filterTagGroupFunc
    if filterTagGroupFunc and FilterUtils[filterTagGroupFunc] then
        filterTagGroups = FilterUtils[filterTagGroupFunc]() or {}
    end
    self.m_selectedTags = {}
    self.m_filterTagGroups = filterTagGroups
    local hasFilter = (filterTagGroups ~= nil) and (next(filterTagGroups) ~= nil)
    self.view.filterBtn.gameObject:SetActive(listConfig.hideFilter ~= true and hasFilter)
    if not hasFilter then
        return
    end
    local filterArgs = {
        tagGroups = filterTagGroups,
        selectedTags = self.m_selectedTags,
        onConfirm = function(tags)
            self:_OnFilterConfirm(tags)
        end,
        getResultCount = function(tags)
            return self:_OnFilterGetCount(tags)
        end
    }
    if self.view.filterBtnWithText then
        self.view.filterBtn.gameObject:SetActive(false)
        self.view.filterBtnWithText.gameObject:SetActive(hasFilter)
        self.view.filterBtnWithText:InitFilterBtn(filterArgs)
    else
        self.view.filterBtn.gameObject:SetActive(hasFilter)
        self.view.filterBtn:InitFilterBtn(filterArgs)
    end
end
CommonItemList._RefreshItemList = HL.Method(HL.Table, HL.Boolean, HL.Number, HL.Opt(HL.Boolean)) << function(self, filteredList, skipGraduallyShow, realIndex, realClick)
    local isEmpty = filteredList == nil or #filteredList == 0
    self.view.emptyNode.gameObject:SetActive(isEmpty)
    if self.view.itemList.gameObject.activeInHierarchy then
        local layoutGroups = self.view.transform:GetComponentsInParent(typeof(CS.UnityEngine.UI.HorizontalOrVerticalLayoutGroup))
        for i = 1, layoutGroups.Length do
            local layoutGroup = layoutGroups[CSIndex(i)]
            LayoutRebuilder.ForceRebuildLayoutImmediate(layoutGroup.transform)
        end
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.main.transform)
        self.view.itemList:TryRecalculateSize()
    end
    self.view.itemList:UpdateCount(#filteredList, CSIndex(realIndex), false, false, skipGraduallyShow == true)
    if realIndex > 0 then
        if realClick == nil then
            realClick = true
        end
        self:SetSelectedIndex(realIndex, realClick, true)
    end
    if isEmpty then
        if self.m_arg.onFilterNone then
            self.m_arg.onFilterNone()
        end
    end
end
CommonItemList._GetDefaultSelectIndex = HL.Method(HL.Opt(HL.Number)).Return(HL.Number) << function(self, forceSelectIndex)
    local defaultSelectIndex = -1
    if self.m_arg.defaultSelectedIndex ~= nil then
        defaultSelectIndex = self.m_arg.defaultSelectedIndex
    end
    if self.m_arg.selectedIndexId ~= nil then
        local tryIndex = self:_GetIndexByIndexId(self.m_arg.selectedIndexId)
        if tryIndex then
            defaultSelectIndex = tryIndex
        end
    end
    if forceSelectIndex then
        defaultSelectIndex = forceSelectIndex
    end
    return defaultSelectIndex
end
CommonItemList._RefreshItemCell = HL.Method(HL.Userdata, HL.Number) << function(self, object, index)
    local listCell = self.m_getItemCell(object)
    local item = listCell.item
    local itemInfo = self.m_filteredInfoList[index]
    if itemInfo == nil then
        return
    end
    local count
    if itemInfo.itemInst ~= nil then
        count = 1
    elseif self.m_arg.itemCount_onlyBag then
        count = Utils.getBagItemCount(itemInfo.id)
    else
        count = itemInfo.itemInst ~= nil and 1 or Utils.getItemCount(itemInfo.id)
    end
    local instId
    if itemInfo.itemInst then
        instId = itemInfo.itemInst.instId
    end
    item:InitItem({ id = itemInfo.itemCfg.id, instId = instId, count = count, }, true)
    local itemBtn = self.m_getItemBtn(listCell)
    if itemBtn then
        itemBtn.onClick:RemoveAllListeners()
        itemBtn.onClick:AddListener(function()
            self:SetSelectedIndex(index, true, true)
        end)
        itemBtn.onLongPress:RemoveAllListeners()
        itemBtn.onLongPress:AddListener(function()
            if self.m_onLongPressItem then
                self.m_onLongPressItem(itemInfo)
            end
        end)
        itemBtn.onPressStart:RemoveAllListeners()
        itemBtn.onPressStart:AddListener(function()
            if self.m_onPressItem then
                self.m_onPressItem(itemInfo)
            end
        end)
        itemBtn.onPressEnd:RemoveAllListeners()
        itemBtn.onPressEnd:AddListener(function()
            if self.m_onReleaseItem then
                self.m_onReleaseItem(itemInfo)
            end
        end)
    end
    if self.m_refreshItemAddOn then
        self.m_refreshItemAddOn(listCell, itemInfo)
    end
    self.m_setItemSelected(listCell, self.m_curSelectId == itemInfo.indexId)
end
CommonItemList._OnFilterConfirm = HL.Method(HL.Table) << function(self, tags)
    local itemInfoList = self.m_itemInfoList
    local filteredList = self:_ApplyFilter(itemInfoList, tags)
    filteredList = self:_ApplySort(filteredList, self.view.sortNode:GetCurSortData(), self.view.sortNode.isIncremental)
    self.m_selectedTags = tags
    self.m_filteredInfoList = filteredList
    self:_RefreshItemList(filteredList, false, 1, false)
end
CommonItemList._OnFilterGetCount = HL.Method(HL.Table).Return(HL.Number) << function(self, tags)
    local resultCount = 0
    if not tags or not next(tags) then
        return resultCount
    end
    for _, itemInfo in pairs(self.m_itemInfoList) do
        if FilterUtils.checkIfPassFilter(itemInfo, tags) then
            resultCount = resultCount + 1
        end
    end
    return resultCount
end
CommonItemList._ApplyFilter = HL.Method(HL.Table, HL.Table).Return(HL.Table) << function(self, itemInfoList, selectedTags)
    if not selectedTags or not next(selectedTags) then
        return itemInfoList
    end
    local filteredList = {}
    for _, itemInfo in pairs(itemInfoList) do
        if FilterUtils.checkIfPassFilter(itemInfo, selectedTags) then
            table.insert(filteredList, itemInfo)
        end
    end
    return filteredList
end
CommonItemList._ApplySort = HL.Method(HL.Table, HL.Table, HL.Boolean).Return(HL.Table) << function(self, itemInfoList, optData, isIncremental)
    if not optData or not next(optData) then
        return itemInfoList
    end
    if isIncremental == nil then
        isIncremental = true
    end
    local sortKeys = optData.keys
    if isIncremental and optData.reverseKeys ~= nil then
        sortKeys = optData.reverseKeys
    end
    table.sort(itemInfoList, Utils.genSortFunction(sortKeys, isIncremental))
    return itemInfoList
end
CommonItemList._CollectItemInfoList = HL.Method(HL.Table, HL.Table).Return(HL.Table) << function(self, listConfig, arg)
    local itemInfoList = {}
    local index = 1
    local depotFunc = listConfig.getDepotFunc
    local itemDepot = self[depotFunc](self, arg)
    if not itemDepot then
        return
    end
    for _, itemBundle in pairs(itemDepot) do
        local templateId = itemBundle.id
        local instId = itemBundle.instId or 0
        local instData = itemBundle.instData
        local _, itemCfg = Tables.itemTable:TryGetValue(templateId)
        if not itemCfg then
            logger.error("CommonItemList-> Can't get itemCfg for templateId: " .. templateId)
        else
            local infoProcessFunc = listConfig.infoProcessFunc
            local itemInfo = FilterUtils[infoProcessFunc](templateId, instId, arg)
            itemInfo.itemCfg = itemCfg
            itemInfo.itemInst = instData
            table.insert(itemInfoList, itemInfo)
            index = index + 1
        end
    end
    return itemInfoList
end
CommonItemList._GetWeaponGemDepot = HL.Method(HL.Table).Return(HL.Table) << function(self, arg)
    local filteredInstItems = {}
    local gemDepot = GameInstance.player.inventory.valuableDepots[GEnums.ItemValuableDepotType.WeaponGem]:GetOrFallback(Utils.getCurrentScope())
    local filter_rarity = arg.filter_rarity
    for _, gemInst in pairs(gemDepot.instItems) do
        local gemCfg = Tables.itemTable:GetValue(gemInst.id)
        if gemCfg then
            local passRarityFilter = (not filter_rarity) or (gemCfg.rarity == filter_rarity)
            if passRarityFilter then
                table.insert(filteredInstItems, gemInst)
            end
        end
    end
    return filteredInstItems
end
CommonItemList._GetWeaponUpgradeDepot = HL.Method(HL.Table).Return(HL.Table) << function(self, arg)
    local weaponDepot = self:_GetWeaponDepot(arg)
    for i = 1, Tables.characterConst.weaponExpItem.Count do
        local itemId = Tables.characterConst.weaponExpItem[CSIndex(i)]
        table.insert(weaponDepot, { id = itemId })
    end
    return weaponDepot
end
CommonItemList._GetTacticalItemDepot = HL.Method(HL.Table).Return(HL.Table) << function(self, arg)
    local useItems = {}
    local filter_isFound = arg.filter_isFound
    for i, cfg in pairs(Tables.equipItemTable) do
        local passFoundFilter = (not filter_isFound) or GameInstance.player.inventory:IsItemFound(cfg.itemId)
        if passFoundFilter then
            table.insert(useItems, { id = cfg.itemId })
        end
    end
    return useItems
end
CommonItemList._GetEquipDepot = HL.Method(HL.Table).Return(HL.Table) << function(self, arg)
    local filteredInstItems = {}
    local filter_equipType = arg.filter_equipType
    local charInst
    local charInstId = arg.charInstId
    if charInstId then
        charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
    end
    local equipDepot = GameInstance.player.inventory.valuableDepots[GEnums.ItemValuableDepotType.Equip]:GetOrFallback(Utils.getCurrentScope())
    if equipDepot then
        for _, itemBundle in pairs(equipDepot.instItems) do
            local equipInst = itemBundle.instData
            local templateId = equipInst.templateId
            local _, itemCfg = Tables.itemTable:TryGetValue(templateId)
            if not itemCfg then
                logger.error(ELogChannel.Cfg, "EquipTemplateId: " .. templateId .. " not in equipBasicTable!!!")
                return filteredInstItems
            end
            local _, equipTemplateCfg = Tables.equipTable:TryGetValue(templateId)
            if not equipTemplateCfg then
                logger.error(ELogChannel.Cfg, "EquipTemplateId: " .. templateId .. " not in equipTable!!!")
                return filteredInstItems
            end
            local passEquipTypeFilter = (not filter_equipType) or (equipTemplateCfg.partType == filter_equipType)
            if passEquipTypeFilter then
                table.insert(filteredInstItems, itemBundle)
            end
        end
    end
    return filteredInstItems
end
CommonItemList._GetWeaponDepot = HL.Method(HL.Table).Return(HL.Table) << function(self, arg)
    local filteredInstItems = {}
    local filter_weaponType = arg.filter_weaponType
    local filter_not_equipped = arg.filter_not_equipped
    local filter_templateId = arg.filter_templateId
    local filter_not_instId = arg.filter_not_instId
    local filter_not_maxPotential = arg.filter_not_maxPotential
    local res, weaponInstDict = GameInstance.player.inventory:TryGetAllWeaponInstItems(Utils.getCurrentScope())
    if res then
        for _, itemBundle in pairs(weaponInstDict) do
            local _, weaponCfg = Tables.weaponBasicTable:TryGetValue(itemBundle.id)
            if weaponCfg then
                local passWeaponTypeFilter = (not filter_weaponType) or (weaponCfg.weaponType == filter_weaponType)
                local passEquippedFilter = (not filter_not_equipped) or (itemBundle.instData.equippedCharServerId == 0)
                local passPotentialFilter = (not filter_not_maxPotential) or (itemBundle.instData.refineLv < UIConst.CHAR_MAX_POTENTIAL)
                local passInstIdFilter = (not filter_not_instId) or (itemBundle.instId ~= filter_not_instId)
                local passTemplateIdFilter = (not filter_templateId) or (itemBundle.id == filter_templateId)
                if passWeaponTypeFilter and passEquippedFilter and passInstIdFilter and passTemplateIdFilter and passPotentialFilter then
                    table.insert(filteredInstItems, itemBundle)
                end
            end
        end
    end
    return filteredInstItems
end
CommonItemList._GetEquipEnhanceDepot = HL.Method(HL.Table).Return(HL.Table) << function(self, args)
    return EquipTechUtils.getEquipEnhanceItemList(args.filter_equipType)
end
CommonItemList._GetEquipEnhanceMaterialsDepot = HL.Method(HL.Table).Return(HL.Table) << function(self, args)
    return EquipTechUtils.getEquipEnhanceMaterialsItemList(args.filter_equipType, args.attrShowInfo, args.equipInstId)
end
HL.Commit(CommonItemList)
return CommonItemList