local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.EquipProducer
local PHASE_ID = PhaseId.EquipProducer
EquipProducerCtrl = HL.Class('EquipProducerCtrl', uiCtrl.UICtrl)
local CELL_COUNT_PER_ROW = 3
local ITEM_ROW_SIZE = 180
local TITLE_ROW_SIZE = 90
local GUIDE_ITEM_PARENT_GO_NAME = { ["item_unit_t1_body_01_parts_spe"] = "ForGuide_t1", ["item_unit_t05_body_01_parts_spe"] = "ForGuide_t05", }
EquipProducerCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_EQUIP_PRODUCE] = '_OnEquipProduce', [MessageConst.ON_EQUIP_TECH_UNLOCK] = '_OnEquipTechUnlock', [MessageConst.GUIDE_EQUIP_PRODUCE_SCROLL_TO_ITEM] = '_OnGuideScrollToItem', }
EquipProducerCtrl.m_equipTechSystem = HL.Field(CS.Beyond.Gameplay.EquipTechSystem)
EquipProducerCtrl.m_currentSelectedFormulaId = HL.Field(HL.String) << ''
EquipProducerCtrl.m_currentSelectedFormulaData = HL.Field(HL.Userdata)
EquipProducerCtrl.m_costCells = HL.Field(HL.Forward("UIListCache"))
EquipProducerCtrl.m_needRefresh = HL.Field(HL.Boolean) << false
EquipProducerCtrl.m_targetFormulaId = HL.Field(HL.String) << ''
EquipProducerCtrl.m_firstSelected = HL.Field(HL.Boolean) << false
EquipProducerCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_equipTechSystem = GameInstance.player.equipTechSystem
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.EquipProducer)
    end)
    self:BindInputPlayerAction("fac_open_equip_producer", function()
        PhaseManager:PopPhase(PhaseId.EquipProducer)
    end)
    self.view.btnProduce.onClick:AddListener(function()
        self:_OnBtnProduceClicked()
    end)
    self.m_costCells = UIUtils.genCellCache(self.view.costCell)
    if args and not string.isEmpty(args.formulaId) then
        self.m_targetFormulaId = args.formulaId
    end
    self:_InitEquipList()
end
EquipProducerCtrl._OnEquipProduce = HL.Method(HL.Table) << function(self, arg)
    local formulaId, equipInstId = unpack(arg)
    local equipFormulaData = Tables.equipFormulaTable[formulaId]
    Notify(MessageConst.SHOW_SYSTEM_REWARDS, { title = Language.LUA_EQUIP_PRODUCE_SUCCESS_TITLE, items = { { id = equipFormulaData.outcomeEquipId, count = 1 } }, })
    self:_RefreshStorage()
    self:_RefreshButton()
    for i = 0, self.view.itemList.count - 1 do
        local cellObj = self.view.itemList:Get(i)
        if cellObj then
            local cell = self.m_getEquipGroupCell(cellObj)
            cell:RefreshCostEnough()
        end
    end
end
EquipProducerCtrl._OnEquipTechUnlock = HL.Method(HL.Table) << function(self, arg)
    self:_RefreshEquipList()
end
EquipProducerCtrl._OnGuideScrollToItem = HL.Method(HL.Table) << function(self, args)
    local itemId = unpack(args)
    self:_ScrollToItem(itemId)
end
EquipProducerCtrl._OnBtnProduceClicked = HL.Method() << function(self)
    self.m_equipTechSystem:ProduceEquip(self.m_currentSelectedFormulaId)
end
EquipProducerCtrl.m_selectedEquipCell = HL.Field(HL.Table)
EquipProducerCtrl._OnItemClicked = HL.Method(HL.Table, HL.Userdata) << function(self, equipCell, equipFormulaData)
    self.m_firstSelected = true
    if self.m_equipTechSystem:IsFormulaUnread(equipFormulaData.formulaId) then
        self.m_equipTechSystem:SetFormulaRead(equipFormulaData.formulaId)
    end
    if self.m_selectedEquipCell then
        self.m_selectedEquipCell.item:SetSelected(false)
    end
    self.m_selectedEquipCell = equipCell
    equipCell.item:SetSelected(true)
    self:_RefreshEquip(equipFormulaData)
end
EquipProducerCtrl.m_unlockedEquipList = HL.Field(HL.Table)
EquipProducerCtrl.m_lockedEquipList = HL.Field(HL.Table)
EquipProducerCtrl.m_filteredUnlockedEquipList = HL.Field(HL.Table)
EquipProducerCtrl.m_filteredLockedEquipList = HL.Field(HL.Table)
EquipProducerCtrl.m_getEquipGroupCell = HL.Field(HL.Function)
EquipProducerCtrl.m_equipGroupCellCount = HL.Field(HL.Number) << 0
EquipProducerCtrl.m_unlockedEquipGroupCellCount = HL.Field(HL.Number) << 0
EquipProducerCtrl.m_lockedEquipGroupCellCount = HL.Field(HL.Number) << 0
EquipProducerCtrl._InitEquipList = HL.Method() << function(self)
    self.m_unlockedEquipList = {}
    self.m_lockedEquipList = {}
    local rarityUnlocked = {}
    local unlockedFormulas = self.m_equipTechSystem:GetUnlockedFormulas()
    for formulaId in cs_pairs(unlockedFormulas) do
        local _, formulaData = Tables.equipFormulaTable:TryGetValue(formulaId)
        if formulaData then
            local _, itemData = Tables.itemTable:TryGetValue(formulaData.outcomeEquipId)
            if itemData then
                rarityUnlocked[itemData.rarity] = true
            end
        end
    end
    for _, formulaData in pairs(Tables.equipFormulaTable) do
        local itemInfo = FilterUtils.processEquipProduce(formulaData)
        if rarityUnlocked[itemInfo.rarity] then
            local targetTable = itemInfo.isUnlocked and self.m_unlockedEquipList or self.m_lockedEquipList
            table.insert(targetTable, itemInfo)
        end
    end
    self:_RefreshEquipListData(self.m_unlockedEquipList, self.m_lockedEquipList)
    if not self.m_getEquipGroupCell then
        self.m_getEquipGroupCell = UIUtils.genCachedCellFunction(self.view.itemList)
        self.view.itemList.getCellSize = function(csIndex)
            if csIndex == self.m_unlockedEquipGroupCellCount then
                return TITLE_ROW_SIZE
            else
                return ITEM_ROW_SIZE
            end
        end
        self.view.itemList.onUpdateCell:AddListener(function(object, csIndex)
            local cell = self.m_getEquipGroupCell(object)
            local nameForGuide
            local itemList = {}
            if csIndex < self.m_unlockedEquipGroupCellCount then
                for i = 1, CELL_COUNT_PER_ROW do
                    local unlockedIndex = csIndex * CELL_COUNT_PER_ROW + i
                    if unlockedIndex <= #self.m_filteredUnlockedEquipList then
                        local itemInfo = self.m_filteredUnlockedEquipList[unlockedIndex]
                        nameForGuide = GUIDE_ITEM_PARENT_GO_NAME[itemInfo.id] or nameForGuide
                        table.insert(itemList, itemInfo)
                    end
                end
            elseif csIndex > self.m_unlockedEquipGroupCellCount then
                for i = 1, CELL_COUNT_PER_ROW do
                    local lockedIndex = (csIndex - self.m_unlockedEquipGroupCellCount - 1) * CELL_COUNT_PER_ROW + i
                    if lockedIndex <= #self.m_filteredLockedEquipList then
                        table.insert(itemList, self.m_filteredLockedEquipList[lockedIndex])
                    end
                end
            end
            local groupArgs = {
                itemList = itemList,
                onItemClicked = function(equipCell, itemInfo)
                    self:_OnItemClicked(equipCell, itemInfo.equipFormulaData)
                end,
                isFirstItemSelected = not self.m_firstSelected and ((self.m_unlockedEquipGroupCellCount > 0 and csIndex == 0) or (self.m_unlockedEquipGroupCellCount == 0 and csIndex == 1)),
            }
            cell:InitEquipProducerGroupItems(groupArgs)
            if nameForGuide then
                cell.gameObject.name = nameForGuide
            end
        end)
    end
    self.view.sortNode:InitSortNode(EquipTechConst.EQUIP_PRODUCE_SORT_OPTION, function(sortOption, isIncremental)
        self:_ApplySortOption(sortOption, isIncremental)
        self:_RefreshEquipList()
    end)
    local filterArgs = {
        tagGroups = FilterUtils.generateConfig_EQUIP_PRODUCE(),
        selectedTags = self.m_selectedFilterTags,
        onConfirm = function(selectedTags)
            self.m_selectedFilterTags = selectedTags
            self:_ApplyFilterOption(selectedTags)
            self:_RefreshEquipList()
        end,
        getResultCount = function(selectedTags)
            return self:_GetFilterResultCount(selectedTags)
        end,
    }
    self.view.filterBtn:InitFilterBtn(filterArgs)
end
EquipProducerCtrl._RefreshEquipListData = HL.Method(HL.Table, HL.Table) << function(self, unlockedEquipList, lockedEquipList)
    self.m_filteredUnlockedEquipList = unlockedEquipList
    self.m_filteredLockedEquipList = lockedEquipList
    self.m_equipGroupCellCount = 0
    self.m_unlockedEquipGroupCellCount = math.ceil(#unlockedEquipList / CELL_COUNT_PER_ROW)
    self.m_lockedEquipGroupCellCount = math.ceil(#lockedEquipList / CELL_COUNT_PER_ROW)
    self.m_equipGroupCellCount = self.m_unlockedEquipGroupCellCount + self.m_lockedEquipGroupCellCount
    if self.m_lockedEquipGroupCellCount > 0 then
        self.m_equipGroupCellCount = self.m_equipGroupCellCount + 1
    end
end
EquipProducerCtrl._RefreshEquipList = HL.Method() << function(self)
    local containerSize = (self.m_unlockedEquipGroupCellCount + self.m_lockedEquipGroupCellCount) * ITEM_ROW_SIZE
    if self.m_lockedEquipGroupCellCount > 0 then
        containerSize = containerSize + TITLE_ROW_SIZE
    end
    self.view.itemList.overrideContainSize = containerSize
    self.m_firstSelected = false
    self.view.itemList:UpdateCount(self.m_equipGroupCellCount, 0, true)
    if self.m_equipGroupCellCount == 0 then
        self:_RefreshEquip(nil)
    end
end
EquipProducerCtrl._ApplySortOption = HL.Method(HL.Table, HL.Boolean) << function(self, sortOption, isIncremental)
    local sortFunc = Utils.genSortFunction(sortOption.keys, isIncremental)
    table.sort(self.m_filteredUnlockedEquipList, sortFunc)
    table.sort(self.m_filteredLockedEquipList, sortFunc)
end
EquipProducerCtrl.m_selectedFilterTags = HL.Field(HL.Table)
EquipProducerCtrl._ApplyFilterOption = HL.Method(HL.Table) << function(self, tagInfoList)
    local filteredUnlockedEquipList = {}
    local filteredLockedEquipList = {}
    if not tagInfoList or not next(tagInfoList) then
        filteredUnlockedEquipList = self.m_unlockedEquipList
        filteredLockedEquipList = self.m_lockedEquipList
    else
        for _, itemInfo in pairs(self.m_unlockedEquipList) do
            if FilterUtils.checkIfPassFilter(itemInfo, tagInfoList) then
                table.insert(filteredUnlockedEquipList, itemInfo)
            end
        end
        for _, itemInfo in pairs(self.m_lockedEquipList) do
            if FilterUtils.checkIfPassFilter(itemInfo, tagInfoList) then
                table.insert(filteredLockedEquipList, itemInfo)
            end
        end
    end
    self:_RefreshEquipListData(filteredUnlockedEquipList, filteredLockedEquipList)
end
EquipProducerCtrl._GetFilterResultCount = HL.Method(HL.Table).Return(HL.Number) << function(self, tagInfoList)
    local resultCount = 0
    for _, itemInfo in pairs(self.m_unlockedEquipList) do
        if FilterUtils.checkIfPassFilter(itemInfo, tagInfoList) then
            resultCount = resultCount + 1
        end
    end
    for _, itemInfo in pairs(self.m_lockedEquipList) do
        if FilterUtils.checkIfPassFilter(itemInfo, tagInfoList) then
            resultCount = resultCount + 1
        end
    end
    return resultCount
end
EquipProducerCtrl._ScrollToItem = HL.Method(HL.String) << function(self, itemId)
    local indexScrollTo = 0
    for csIndex = 0, self.m_equipGroupCellCount - 1 do
        if csIndex < self.m_unlockedEquipGroupCellCount then
            for i = 1, CELL_COUNT_PER_ROW do
                local unlockedIndex = csIndex * CELL_COUNT_PER_ROW + i
                if unlockedIndex <= #self.m_filteredUnlockedEquipList then
                    local itemInfo = self.m_filteredUnlockedEquipList[unlockedIndex]
                    if itemInfo.id == itemId then
                        indexScrollTo = csIndex
                        break
                    end
                end
            end
        elseif csIndex > self.m_unlockedEquipGroupCellCount then
            for i = 1, CELL_COUNT_PER_ROW do
                local lockedIndex = (csIndex - self.m_unlockedEquipGroupCellCount - 1) * CELL_COUNT_PER_ROW + i
                if lockedIndex <= #self.m_filteredLockedEquipList then
                    local itemInfo = self.m_filteredLockedEquipList[lockedIndex]
                    if itemInfo.id == itemId then
                        indexScrollTo = csIndex
                        break
                    end
                end
            end
        end
    end
    self.view.itemList:ScrollToIndex(indexScrollTo)
end
EquipProducerCtrl._RefreshEquip = HL.Method(HL.Userdata) << function(self, equipFormulaData)
    local isEmpty = equipFormulaData == nil
    self:_ActiveEmpty(isEmpty)
    if isEmpty then
        self.m_costCells:Refresh(3, function(cell, luaIndex)
            cell.gameObject.name = tostring(luaIndex)
            cell.emptyBG.gameObject:SetActive(true)
            cell.content.gameObject:SetActive(false)
        end)
        return
    end
    local equipItemId = equipFormulaData.outcomeEquipId
    EquipTechUtils.setEquipBaseInfo(self.view.equipBaseInfo, self.loader, equipItemId)
    self.m_storageDataList = {}
    self.m_currentSelectedFormulaData = equipFormulaData
    self.m_currentSelectedFormulaId = equipFormulaData.formulaId
    self.m_costCells:Refresh(equipFormulaData.costItemId.Count, function(cell, luaIndex)
        cell.gameObject.name = tostring(luaIndex)
        local csIndex = CSIndex(luaIndex)
        local itemId = equipFormulaData.costItemId[csIndex]
        local itemNum = csIndex < equipFormulaData.costItemNum.Count and equipFormulaData.costItemNum[csIndex] or 0
        local hasItem = not string.isEmpty(itemId) and itemNum > 0
        cell.emptyBG.gameObject:SetActive(not hasItem)
        cell.content.gameObject:SetActive(hasItem)
        if hasItem then
            cell.itemBigBlack:InitItem({ id = itemId, count = itemNum }, true)
            cell.itemBigBlack:UpdateCountSimple(itemNum, Utils.getItemCount(itemId, true, true) < itemNum)
            local storageData = {}
            storageData.widget = cell.storage
            storageData.itemId = itemId
            storageData.needCount = itemNum
            table.insert(self.m_storageDataList, storageData)
        end
    end)
    local storageData = {}
    storageData.widget = self.view.storage
    storageData.itemId = equipItemId
    storageData.needCount = 0
    table.insert(self.m_storageDataList, storageData)
    local itemData = Tables.itemTable[equipItemId]
    self.view.currentIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, itemData.iconId)
    UIUtils.setItemRarityImage(self.view.qualityLight, itemData.rarity)
    self.view.equipDetails.weaponAttributeNode:InitEquipAttributeNodeByTemplateId(equipItemId)
    self.view.equipDetails.equipSuitNode:InitEquipSuitNode(equipItemId)
    local equipCfg = Tables.equipTable[equipItemId]
    local equipType = equipCfg.partType
    local equipTypeName = Language[UIConst.CHAR_INFO_EQUIP_TYPE_TILE_PREFIX .. LuaIndex(equipType:ToInt())]
    self.view.equipTitleTxt.text = string.format(Language.LUA_EQUIP_PRODUCE_TITLE_FORMAT, equipTypeName)
    self:_RefreshStorage()
    self:_RefreshButton()
end
EquipProducerCtrl.m_storageDataList = HL.Field(HL.Table)
EquipProducerCtrl._RefreshStorage = HL.Method() << function(self)
    self.m_isCostItemEnough = true
    for _, storageData in ipairs(self.m_storageDataList) do
        local itemCount = Utils.getItemCount(storageData.itemId, true, true)
        storageData.widget:InitStorageNode(itemCount, storageData.needCount, true)
        if itemCount < storageData.needCount then
            self.m_isCostItemEnough = false
        end
    end
end
EquipProducerCtrl.m_isCostItemEnough = HL.Field(HL.Boolean) << false
EquipProducerCtrl._RefreshButton = HL.Method() << function(self)
    local isUnlocked = FactoryUtils.isEquipFormulaUnlocked(self.m_currentSelectedFormulaData.formulaId)
    local isEquipProduceEnabled = false
    if Utils.isInFacMainRegion() then
        if Utils.isInBlackbox() then
            local curSceneInfo = GameInstance.remoteFactoryManager.currentSceneInfo
            isEquipProduceEnabled = CS.Beyond.Gameplay.RemoteFactory.RemoteFactoryUtil.IsHubEquipCraftEnabledInBlackbox(curSceneInfo)
        else
            isEquipProduceEnabled = true
        end
    end
    self.view.jumpConTip.gameObject:SetActive(isUnlocked and not isEquipProduceEnabled)
    self.view.btnProduce.gameObject:SetActive(isEquipProduceEnabled and isUnlocked and self.m_isCostItemEnough)
    self.view.unableTip.gameObject:SetActive(not isUnlocked or (not self.m_isCostItemEnough and isEquipProduceEnabled))
    self.view.txtUnableNumber.gameObject:SetActive(not isUnlocked and self.m_currentSelectedFormulaData.unlockType == GEnums.EquipFormulaUnlockType.AdventureLevel)
    local unableText
    if not isUnlocked then
        unableText = Language.LUA_EQUIP_PRODUCE_FORMULA_LOCKED
        local unlockType = self.m_currentSelectedFormulaData.unlockType
        if unlockType == GEnums.EquipFormulaUnlockType.AdventureLevel then
            unableText = string.format(Language.LUA_EQUIP_PRODUCE_ADVENTURE_LEVEL_LOCKED_FORMAT, self.m_currentSelectedFormulaData.unlockValue)
            self.view.txtUnableNumber.text = string.format(Language.LUA_EQUIP_PRODUCE_ADVENTURE_LEVEL_FORMAT, GameInstance.player.adventure.adventureLevelData.lv)
        elseif unlockType == GEnums.EquipFormulaUnlockType.MapExploration then
            unableText = Language.LUA_EQUIP_PRODUCE_MAP_EXPLORE_LOCKED_DESC
        end
    elseif not self.m_isCostItemEnough then
        unableText = Language.LUA_EQUIP_PRODUCE_ITEM_NOT_ENOUGH
    end
    if not string.isEmpty(unableText) then
        self.view.txtUnable.text = unableText
    end
end
EquipProducerCtrl.m_isEmpty = HL.Field(HL.Boolean) << false
EquipProducerCtrl._ActiveEmpty = HL.Method(HL.Boolean) << function(self, isEmpty)
    self.m_isEmpty = isEmpty
    self.view.rightContent.gameObject:SetActive(not isEmpty)
    self.view.currentIcon.gameObject:SetActive(not isEmpty)
    self.view.storage.gameObject:SetActive(not isEmpty)
    self.view.qualityLight.gameObject:SetActive(not isEmpty)
    self.view.emptyResearchNode.gameObject:SetActive(isEmpty)
    self.view.equipTitleTxt.gameObject:SetActive(not isEmpty)
end
HL.Commit(EquipProducerCtrl)