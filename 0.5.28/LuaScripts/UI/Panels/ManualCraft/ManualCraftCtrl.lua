local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ManualCraft
local MAX_MANUFACTURE_LIST_COUNT = 5
local MAX_APPEND_MANUFACTURE_COUNT_LIMIT = 10
local FRAME_RATE = 60
local CraftShowingType = CS.Beyond.GEnums.CraftShowingType
local filterList = { [1] = { type = CraftShowingType.ManualCraftTonic, }, [2] = { type = CraftShowingType.ManualCraftArmament, }, [3] = { type = CraftShowingType.ManualCraftDish, }, [4] = { type = CraftShowingType.ManualArableField, }, }
local sortOptions = { { name = Language.LUA_FAC_CRAFT_SORT_1, sortMode = 1, sortKeys = { "sortId" }, }, { name = Language.LUA_FAC_CRAFT_SORT_2, sortMode = 2, sortKeys = { "rarity", "sortId" }, }, }
ManualCraftCtrl = HL.Class('ManualCraftCtrl', uiCtrl.UICtrl)
ManualCraftCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_MANUAL_WORK_MODIFY] = 'OnManualWorkModify', [MessageConst.ON_MANUAL_WORK_CANCEL] = 'OnManualWorkCancel', [MessageConst.ON_ITEM_COUNT_CHANGED] = 'OnItemCountChanged', }
ManualCraftCtrl.m_inventorySystem = HL.Field(HL.Any)
ManualCraftCtrl.m_facManualCraftSystem = HL.Field(HL.Any)
ManualCraftCtrl.m_cntFilterType = HL.Field(HL.Any)
ManualCraftCtrl.m_cntFilterTypeShow = HL.Field(HL.Table)
ManualCraftCtrl.m_filterTypeTabCellCache = HL.Field(HL.Forward("UIListCache"))
ManualCraftCtrl.m_filterTypeTabClickList = HL.Field(HL.Table)
ManualCraftCtrl.m_sortMode = HL.Field(HL.Number) << 1
ManualCraftCtrl.m_sortIncremental = HL.Field(HL.Boolean) << true
ManualCraftCtrl.m_getCraftCellFunc = HL.Field(HL.Function)
ManualCraftCtrl.m_craftInfoList = HL.Field(HL.Table)
ManualCraftCtrl.m_allIngredientsForDisplayCraft = HL.Field(HL.Table)
ManualCraftCtrl.m_selectedCraftId = HL.Field(HL.String) << ""
ManualCraftCtrl.m_selectedCraftTabType = HL.Field(HL.Any) << ""
ManualCraftCtrl.m_workshopList = HL.Field(HL.Forward("UIListCache"))
ManualCraftCtrl.m_manualCount = HL.Field(HL.Number) << 0
ManualCraftCtrl.m_manufactureListCache = HL.Field(HL.Forward("UIListCache"))
ManualCraftCtrl.m_readCraftIds = HL.Field(HL.Table)
ManualCraftCtrl.m_isMaking = HL.Field(HL.Boolean) << false
ManualCraftCtrl.m_fabricateSoundKey = HL.Field(HL.Number) << 0
ManualCraftCtrl.m_filterSetting = HL.Field(HL.Table)
ManualCraftCtrl.m_realFilterSetting = HL.Field(HL.Table)
ManualCraftCtrl.m_nowTabCell = HL.Field(HL.Any)
ManualCraftCtrl.m_nowCraftCell = HL.Field(HL.Any)
ManualCraftCtrl.m_filterCells = HL.Field(HL.Forward("UIListCache"))
ManualCraftCtrl.m_filterCurNaviIndex = HL.Field(HL.Number) << 0
ManualCraftCtrl.m_jumpId = HL.Field(HL.String) << ""
ManualCraftCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    MAX_MANUFACTURE_LIST_COUNT = Tables.factoryConst.manualWorkQueueLength
    MAX_APPEND_MANUFACTURE_COUNT_LIMIT = Tables.factoryConst.manualWorkCountLimit
    self.m_inventorySystem = GameInstance.player.inventory
    self.m_facManualCraftSystem = GameInstance.player.facManualCraft
    self.m_readCraftIds = {}
    self.m_workshopList = UIUtils.genCellCache(self.view.itemCell)
    if arg then
        self.m_jumpId = arg.jumpId
    end
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.ManualCraft)
    end)
    self.view.craftContent.onUpdateCell:AddListener(function(gameObject, index)
        self:_UpdateCell(gameObject, index)
    end)
    self.view.craftContent.onSelectedCell:AddListener(function(obj, csIndex)
        self:_SelectCraft(self.m_craftInfoList[LuaIndex(csIndex)].id)
    end)
    self.view.productionManualBtn.onClick:AddListener(function()
        UIManager:Open(PanelId.ManualCraftPopups)
    end)
    self.m_sortMode = 1
    self.m_sortIncremental = false
    self.m_filterSetting = {}
    self.m_realFilterSetting = {}
    local list = self.m_facManualCraftSystem:GetAllDomainData()
    for i = 0, list.Count - 1 do
        local domainData = list[i]
        table.insert(self.m_filterSetting, { id = domainData.domainId, domainName = domainData.domainName, defaultIsOn = false, name = domainData.domainName })
    end
    for index, info in ipairs(self.m_filterSetting) do
        local keyName = "ManualCraft.Filter.Tab." .. index
        self.m_filterSetting[index].isOn = Unity.PlayerPrefs.GetInt(keyName, info.defaultIsOn and 1 or 0) == 1
    end
    local selectedFilter = {}
    for _, v in ipairs(self.m_filterSetting) do
        if v.isOn then
            table.insert(selectedFilter, v)
        end
    end
    self.view.filterBtn:InitFilterBtn({
        tagGroups = { { tags = self.m_filterSetting } },
        selectedTags = selectedFilter,
        onConfirm = function(tags)
            if self.m_nowCraftCell then
                self.m_nowCraftCell.defalut.gameObject:SetActive(true)
                self.m_nowCraftCell.selected.gameObject:SetActive(false)
                self.m_nowCraftCell = nil
            end
            for i = 1, #self.m_filterSetting do
                self.m_filterSetting[i].isOn = false
            end
            if tags ~= nil then
                for i = 1, #tags do
                    for j = 1, #self.m_filterSetting do
                        if self.m_filterSetting[j].id == tags[i].id then
                            local keyName = "ManualCraft.Filter.Tab." .. j
                            self.m_filterSetting[j].isOn = true
                            Unity.PlayerPrefs.SetInt(keyName, 1)
                        end
                    end
                end
            end
            self:_RefreshCraftList()
        end,
        getResultCount = function(tags)
            local noSelect = #tags == 0
            local formulaList = self.m_facManualCraftSystem:GetUnlockedFormulaByType(self.m_cntFilterType)
            if noSelect then
                return formulaList.Count
            end
            local craftInfoList = {}
            local count = 0
            local manualCraftData = Tables.factoryManualCraftTable
            if formulaList ~= nil then
                for _, formulaId in pairs(formulaList) do
                    local success, manualCraftInfo = manualCraftData:TryGetValue(formulaId)
                    if success == true then
                        for j = 1, #tags do
                            if (tags[j].id == manualCraftInfo.domainId) then
                                count = count + 1
                            end
                        end
                    end
                end
            end
            return count
        end
    })
    self:_InitFilterTypeTab()
    self.view.sortNodeUp:InitSortNode(sortOptions, function(optData, isIncremental)
        self.m_sortMode = optData.sortMode
        self.m_sortIncremental = isIncremental
        self.m_nowCraftCell.selected.gameObject:SetActive(false)
        self.m_nowCraftCell = nil
        self:_RefreshCraftList()
        for k, v in pairs(self.m_readCraftIds) do
            self.m_facManualCraftSystem:ReadSingleCraft(k)
        end
    end, 0, self.m_sortIncremental, true)
    self.view.btnCommon.onClick:AddListener(function()
        self:_StartCraft()
    end)
    self.view.settingList.gameObject:SetActive(false)
    self.view.gemRecastReddot:InitRedDot("ManualCraftRewardEntry")
    local isUnlock = Utils.isSystemUnlocked(GEnums.UnlockSystemType.ProductManual) and Utils.isInMainScope()
    self.view.productionManualBtn.gameObject:SetActive(isUnlock)
    self:Notify(MessageConst.ON_DISABLE_COMMON_TOAST)
end
ManualCraftCtrl._StartCraft = HL.Method() << function(self)
    local needItems = self:_GetIngredientItems(self.m_selectedCraftId, self.m_manualCount)
    for _, item in pairs(needItems) do
        local inventoryCount = self:_GetItemCount(item.id)
        local itemName = Tables.itemTable:GetValue(item.id).name
        if inventoryCount < item.count then
            GameAction.ShowUIToast(string.format(Language.LUA_INGREDIENT_NOT_ENOUGH, itemName))
            return
        end
    end
    self.m_facManualCraftSystem:DoManualWork(Utils.getCurrentScope(), self.m_selectedCraftId, self.m_manualCount)
end
ManualCraftCtrl._InitFilterTypeTab = HL.Method() << function(self)
    self.m_cntFilterTypeShow = self.m_cntFilterTypeShow or {}
    self.m_filterTypeTabCellCache = self.m_filterTypeTabCellCache or UIUtils.genCellCache(self.view.tabCell)
    self.m_filterTypeTabClickList = {}
    self.m_filterTypeTabCellCache:Refresh(#filterList, function(cell, index)
        local l = self.m_facManualCraftSystem:GetUnlockedFormulaByType(filterList[index].type)
        if l ~= nil and l.Count > 0 then
            self.m_cntFilterTypeShow[filterList[index].type] = true
            cell.gameObject:SetActive(true)
        else
            self.m_cntFilterTypeShow[filterList[index].type] = false
            cell.gameObject:SetActive(false)
        end
        cell.gameObject.name = "Tab_" .. filterList[index].type:ToString()
        cell.redDot:InitRedDot("ManualCraftType", filterList[index].type)
        local success, craftTypeInfo = Tables.factoryCraftShowingTypeTable:TryGetValue(filterList[index].type:ToInt())
        local clickFUnc = function()
            if self.m_selectedCraftTabType == filterList[index].type then
                return
            end
            for k, v in pairs(self.m_readCraftIds) do
                self.m_facManualCraftSystem:ReadSingleCraft(k)
            end
            if self.m_nowTabCell ~= nil then
                self.m_nowTabCell.defalut.gameObject:SetActive(true)
                self.m_nowTabCell.selected.gameObject:SetActive(false)
            end
            if self.m_nowCraftCell ~= nil then
                self.m_nowCraftCell.defalut.gameObject:SetActive(true)
                self.m_nowCraftCell.selected.gameObject:SetActive(false)
                self.m_nowCraftCell = nil
            end
            self.view.settingList.gameObject:SetActive(false)
            cell.defalut.gameObject:SetActive(false)
            cell.selected.gameObject:SetActive(true)
            self:_SetFilterType(filterList[index].type)
            self.m_selectedCraftTabType = filterList[index].type
            self.m_nowTabCell = cell
        end
        if success then
            cell.defalut.gameObject:SetActive(self.m_selectedCraftTabType ~= filterList[index].type)
            cell.selected.gameObject:SetActive(self.m_selectedCraftTabType == filterList[index].type)
            cell.defalut.text.text = craftTypeInfo.name
            cell.selected.text.text = craftTypeInfo.name
            cell.selected.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MANUAL_CRAFT_TYPE_ICON, craftTypeInfo.icon)
            cell.defalut.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MANUAL_CRAFT_TYPE_ICON, craftTypeInfo.icon)
            cell.button.onClick:AddListener(clickFUnc)
            table.insert(self.m_filterTypeTabClickList, clickFUnc)
        end
    end)
    local isAllHide = true
    if not string.isEmpty(self.m_jumpId) then
        local craftData = Tables.factoryManualCraftTable:GetValue(self.m_jumpId)
        if not self.m_cntFilterTypeShow[craftData.showingType] then
            self.m_jumpId = ""
        end
    end
    if string.isEmpty(self.m_jumpId) then
        for i = 1, #filterList do
            if self.m_cntFilterTypeShow[filterList[i].type] then
                isAllHide = false
                self.m_filterTypeTabClickList[i]()
                break
            end
        end
    else
        local craftData = Tables.factoryManualCraftTable:GetValue(self.m_jumpId)
        for i = 1, #filterList do
            if craftData.showingType == filterList[i].type and self.m_cntFilterTypeShow[filterList[i].type] then
                isAllHide = false
                self.m_filterTypeTabClickList[i]()
            end
        end
    end
    if isAllHide then
        self:_SetEmpty()
    end
end
ManualCraftCtrl._SetFilterType = HL.Method(HL.Any) << function(self, craftType)
    self.m_nowCraftCell = nil
    self.m_cntFilterType = craftType
    self:_RefreshCraftList()
end
ManualCraftCtrl._SetEmpty = HL.Method() << function(self)
    self.view.emptyNode.gameObject:SetActive(true)
    self.view.middleBarNode.gameObject:SetActive(false)
    self.view.rightBar.gameObject:SetActive(false)
    self.view.topBarNode.gameObject:SetActive(false)
    self:_RefreshStartCraftBtn()
end
ManualCraftCtrl._RefreshCraftList = HL.Method() << function(self)
    if self.m_cntFilterType == null then
        self:_SetEmpty()
        return
    end
    local manualCraftData = Tables.factoryManualCraftTable
    self.m_craftInfoList = {}
    self.m_realFilterSetting = {}
    local filterCount = 0
    local realCount = 0
    local formulaList = self.m_facManualCraftSystem:GetUnlockedFormulaByType(self.m_cntFilterType)
    local noSelectFilter = true
    for _, info in pairs(self.m_filterSetting) do
        if info.isOn then
            noSelectFilter = false
            break
        end
    end
    if formulaList ~= nil then
        for _, formulaId in pairs(formulaList) do
            local success, manualCraftInfo = manualCraftData:TryGetValue(formulaId)
            if success == true then
                realCount = realCount + 1
                self.m_realFilterSetting[manualCraftInfo.domainId] = true
                if noSelectFilter then
                    table.insert(self.m_craftInfoList, manualCraftInfo)
                else
                    for j = 1, #self.m_filterSetting do
                        if not self.m_realFilterSetting[manualCraftInfo.domainId] or (self.m_filterSetting[j].id == manualCraftInfo.domainId and self.m_filterSetting[j].isOn) then
                            table.insert(self.m_craftInfoList, manualCraftInfo)
                        end
                    end
                end
            end
        end
    end
    for _, info in pairs(self.m_realFilterSetting) do
        filterCount = filterCount + 1
    end
    local active = filterCount > 1 or (#self.m_craftInfoList == 0 and realCount > 0)
    self.view.filterBtn.gameObject:SetActive(active)
    if active == false then
        self.view.settingList.gameObject:SetActive(active)
    end
    local sortFunc = Utils.genSortFunction(sortOptions[self.m_sortMode].sortKeys, self.m_sortIncremental)
    local realFunc = function(a, b)
        if self.m_sortMode == 1 then
            local aCanDo = self:_CheckFormulaAvailable(a.id)
            local bCanDo = self:_CheckFormulaAvailable(b.id)
            if aCanDo ~= bCanDo then
                if self.m_sortIncremental then
                    return not aCanDo
                else
                    return aCanDo
                end
            end
            return sortFunc(a, b)
        else
            return sortFunc(a, b)
        end
    end
    table.sort(self.m_craftInfoList, realFunc)
    self.m_allIngredientsForDisplayCraft = {}
    self.m_getCraftCellFunc = self.m_getCraftCellFunc or UIUtils.genCachedCellFunction(self.view.craftContent)
    local selectIndex = 0
    if not string.isEmpty(self.m_jumpId) then
        for i = 1, #self.m_craftInfoList do
            if self.m_craftInfoList[i].id == self.m_jumpId then
                selectIndex = i - 1
                self.m_jumpId = ""
                break
            end
        end
    end
    if #self.m_craftInfoList > 0 then
        self.view.craftContent:SetSelectedIndex(selectIndex, true, true, false)
        self.view.emptyNode.gameObject:SetActive(false)
        self.view.middleBarNode.gameObject:SetActive(true)
        self.view.rightBar.gameObject:SetActive(true)
        self.view.topBarNode.gameObject:SetActive(true)
        self.view.middleBar.gameObject:SetActive(true)
        self.view.itemContent.gameObject:SetActive(true)
        self.view.rightBar.gameObject:SetActive(true)
    elseif realCount > 0 then
        self.view.emptyNode.gameObject:SetActive(false)
        self.view.middleBarNode.gameObject:SetActive(true)
        self.view.middleBar.gameObject:SetActive(false)
        self.view.itemContent.gameObject:SetActive(false)
        self.view.rightBar.gameObject:SetActive(false)
        self.view.topBarNode.gameObject:SetActive(true)
    else
        self:_SetEmpty()
        self.m_workshopList:Refresh(0, function(cell, index)
        end)
    end
    self.view.craftContent:UpdateCount(#self.m_craftInfoList, true)
end
ManualCraftCtrl._UpdateCell = HL.Method(GameObject, HL.Number) << function(self, gameObject, index)
    local luaIdx = LuaIndex(index)
    local craftInfo = self.m_craftInfoList[luaIdx]
    gameObject.name = "Craft_" .. craftInfo.id
    self.m_readCraftIds[craftInfo.id] = true
    local outcomeItemId = craftInfo.outcomes[0].id
    local craftItemCell = self.m_getCraftCellFunc(gameObject)
    craftItemCell.id = craftInfo.id
    local data = Tables.itemTable:GetValue(outcomeItemId)
    craftItemCell.selected.commodityText.text = data.name
    craftItemCell.defalut.commodityText.text = data.name
    craftItemCell.defalut.itemIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, data.iconId)
    craftItemCell.selected.itemIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, data.iconId)
    craftItemCell.notUnlocked.gameObject:SetActive(false)
    UIUtils.setItemRarityImage(craftItemCell.defalut.colorLine, data.rarity)
    UIUtils.setItemRarityImage(craftItemCell.selected.colorLine, data.rarity)
    if self.view.craftContent.curSelectedIndex == index then
        craftItemCell.selected.gameObject:SetActive(true)
        craftItemCell.defalut.gameObject:SetActive(false)
        if self.m_nowCraftCell == nil then
            self.m_nowCraftCell = craftItemCell
        end
        self.m_facManualCraftSystem:ReadSingleCraft(craftInfo.id)
        craftItemCell.defalut.redDot:InitRedDot("ManualCraftItem", craftInfo.id)
    else
        craftItemCell.selected.gameObject:SetActive(false)
        craftItemCell.defalut.gameObject:SetActive(true)
    end
    craftItemCell.button.onClick:RemoveAllListeners()
    craftItemCell.button.onClick:AddListener(function()
        if self.view.craftContent.curSelectedIndex ~= index then
            if self.m_nowCraftCell ~= nil then
                self.m_nowCraftCell.defalut.gameObject:SetActive(true)
            end
            self.m_facManualCraftSystem:ReadSingleCraft(craftInfo.id)
            craftItemCell.defalut.redDot:InitRedDot("ManualCraftItem", craftInfo.id)
            craftItemCell.defalut.gameObject:SetActive(false)
            craftItemCell.selected.gameObject:SetActive(true)
            self.m_nowCraftCell = craftItemCell
            self.view.craftContent:SetSelectedIndex(index)
            self.view.rightBar.gameObject:GetComponent(typeof(CS.Beyond.UI.UIAnimationWrapper)):PlayInAnimation()
        end
    end)
    craftItemCell.defalut.redDot:InitRedDot("ManualCraftItem", craftInfo.id)
    for i = 1, craftInfo.ingredients.Count do
        self.m_allIngredientsForDisplayCraft[craftInfo.ingredients[i - 1].id] = true
    end
    self:_RefreshCraftCellAvailable(craftItemCell, true)
end
ManualCraftCtrl._RefreshCraftCellAvailable = HL.Method(HL.Any, HL.Boolean) << function(self, inCraftItemCell, clearTween)
    local craftAvailable = self:_CheckFormulaAvailable(inCraftItemCell.id)
    if craftAvailable then
        inCraftItemCell.selected.craftableText.gameObject:SetActive(true)
        inCraftItemCell.defalut.craftableText.gameObject:SetActive(true)
        inCraftItemCell.defalut.insufficientText.gameObject:SetActive(false)
        inCraftItemCell.selected.insufficientText.gameObject:SetActive(false)
        inCraftItemCell.selected.craftableText.text = Language.LUA_CRAFT_AVAILABLE
        inCraftItemCell.selected.craftableText.color = self.view.config.NORMAL_NUM_COLOR
        inCraftItemCell.defalut.craftableText.color = self.view.config.NORMAL_NUM_COLOR
        inCraftItemCell.defalut.craftableText.text = Language.LUA_CRAFT_AVAILABLE
    else
        inCraftItemCell.selected.craftableText.gameObject:SetActive(false)
        inCraftItemCell.defalut.craftableText.gameObject:SetActive(false)
        inCraftItemCell.defalut.insufficientText.gameObject:SetActive(true)
        inCraftItemCell.selected.insufficientText.gameObject:SetActive(true)
        inCraftItemCell.selected.insufficientText.text = Language.LUA_CRAFT_NOT_AVAILABLE
        inCraftItemCell.selected.insufficientText.color = self.view.config.CRAFT_NOT_AVAILABLE_TEXT_COLOR
        inCraftItemCell.defalut.insufficientText.color = self.view.config.CRAFT_NOT_AVAILABLE_TEXT_COLOR
        inCraftItemCell.defalut.insufficientText.text = Language.LUA_CRAFT_NOT_AVAILABLE
    end
    local color1 = inCraftItemCell.defalut.itemIcon.color
    local color2 = inCraftItemCell.selected.itemIcon.color
    if craftAvailable then
        color1.a = UIConst.ITEM_EXIST_TRANSPARENCY
        color2.a = UIConst.ITEM_EXIST_TRANSPARENCY
        inCraftItemCell.defalut.itemIcon.color = color1
        inCraftItemCell.selected.itemIcon.color = color2
    else
        color1.a = UIConst.ITEM_MISSING_TRANSPARENCY
        color2.a = UIConst.ITEM_MISSING_TRANSPARENCY
        inCraftItemCell.defalut.itemIcon.color = color1
        inCraftItemCell.selected.itemIcon.color = color2
    end
end
ManualCraftCtrl._SelectCraft = HL.Method(HL.String) << function(self, craftId)
    local lastSelectedCraftId = self.m_selectedCraftId
    self.m_selectedCraftId = craftId
    self:_PlayCraftListSelectEffect(lastSelectedCraftId)
    self:_RefreshCraftNode(true)
end
ManualCraftCtrl._RefreshCraftNode = HL.Method(HL.Opt(HL.Boolean)) << function(self, needResetManualCount)
    local maxFormulaWorkTimes = 0
    local success, craftInfo = Tables.factoryManualCraftTable:TryGetValue(self.m_selectedCraftId)
    if not success then
        return
    end
    self.m_workshopList:Refresh(3, function(cell, index)
        if index <= craftInfo.ingredients.Count then
            local ingredientItem = craftInfo.ingredients[index - 1]
            local inventoryCount = self:_GetItemCount(ingredientItem.id)
            cell.itemBigBlack.gameObject:SetActive(true)
            cell.itemBigBlack:InitItem({ id = ingredientItem.id, count = 1 }, true)
            cell.itemBigBlack.canUse = false
            cell.emptyBG.gameObject:SetActive(false)
            cell.commonStorageNodeNew.gameObject:SetActive(true)
            local inventoryCount = self:_GetItemCount(ingredientItem.id)
            if index == 1 then
                maxFormulaWorkTimes = inventoryCount // ingredientItem.count
            else
                maxFormulaWorkTimes = math.min(maxFormulaWorkTimes, inventoryCount // ingredientItem.count)
                end
        else
            cell.itemBigBlack.gameObject:SetActive(false)
            cell.emptyBG.gameObject:SetActive(true)
            cell.commonStorageNodeNew.gameObject:SetActive(false)
        end
    end)
    maxFormulaWorkTimes = math.max(maxFormulaWorkTimes, 1)
    maxFormulaWorkTimes = math.min(maxFormulaWorkTimes, MAX_APPEND_MANUFACTURE_COUNT_LIMIT)
    if success and craftInfo.outcomes.Count > 0 then
        local outcomeItem = craftInfo.outcomes[0].id
        local item = Tables.itemTable:GetValue(outcomeItem)
        if item.type == GEnums.ItemType.CardExp then
        end
        self.view.currentIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, item.iconId)
        self.view.itemDescNode:InitItemDescNode(item.id)
        self.view.mainTitle.text = item.name
        local itemTypeName = UIUtils.getItemTypeName(outcomeItem)
        self.view.subtitleText.text = itemTypeName
    end
    local c = 1
    if not needResetManualCount then
        c = math.min(self.m_manualCount, maxFormulaWorkTimes)
    end
    self.view.numberSelector_New:InitNumberSelector(c, 1, maxFormulaWorkTimes, function(cntCount)
        self.m_manualCount = cntCount
        self:_RefreshCraftCount()
    end, false, 0)
    UIUtils.setItemRarityImage(self.view.qualityLight, Tables.itemTable:GetValue(craftInfo.outcomes[0].id).rarity)
end
ManualCraftCtrl.OnItemCountChanged = HL.Method(HL.Any) << function(self, args)
    if string.isEmpty(self.m_selectedCraftId) then
        return
    end
    local changedItemId2DiffCount, _ = unpack(args)
    local manualCraftData = Tables.factoryManualCraftTable
    local success, craftInfo = manualCraftData:TryGetValue(self.m_selectedCraftId)
    local needRefreshCount = false
    if success then
        for i = 1, craftInfo.ingredients.Count do
            if changedItemId2DiffCount:ContainsKey(craftInfo.ingredients[i - 1].id) then
                needRefreshCount = true
                break
            end
        end
        if changedItemId2DiffCount:ContainsKey(craftInfo.outcomes[0].id) then
            needRefreshCount = true
        end
    end
    if needRefreshCount then
        self:_RefreshCraftCount()
        self:_RefreshCraftNode()
    end
    if self.m_allIngredientsForDisplayCraft then
        for itemId, _ in pairs(changedItemId2DiffCount) do
            if self.m_allIngredientsForDisplayCraft[itemId] then
                for i = 1, #self.m_craftInfoList do
                    local gameObject = self.view.craftContent:Get(CSIndex(i))
                    if gameObject then
                        local craftCell = self.m_getCraftCellFunc(gameObject)
                        if craftCell then
                            self:_RefreshCraftCellAvailable(craftCell, false)
                        end
                    end
                end
                break
            end
        end
    end
end
ManualCraftCtrl._RefreshCraftCount = HL.Method() << function(self)
    self:_RefreshStartCraftBtn()
    if string.isEmpty(self.m_selectedCraftId) then
        return
    end
    local manualCraftData = Tables.factoryManualCraftTable
    local success, craftInfo = manualCraftData:TryGetValue(self.m_selectedCraftId)
    if success then
        self.m_workshopList:Refresh(3, function(cell, index)
            if index <= craftInfo.ingredients.Count then
                local itemId = craftInfo.ingredients[CSIndex(index)].id
                local count = craftInfo.ingredients[CSIndex(index)].count
                local demandCount = math.floor(count * self.m_manualCount)
                local inventoryCount = self:_GetItemCount(itemId)
                cell.itemBigBlack:UpdateCountSimple(demandCount, demandCount > inventoryCount)
                UIUtils.setItemStorageCountText(cell.commonStorageNodeNew, itemId, count, false)
            end
        end)
        if craftInfo.outcomes.Count > 0 then
            local outcomeItem = craftInfo.outcomes[0]
            UIUtils.setItemStorageCountText(self.view.commonStorageNodeNew, outcomeItem.id, outcomeItem.count)
            local outcomeCount = math.floor(outcomeItem.count * self.m_manualCount)
            self.view.curNumberText.text = outcomeCount
        end
    end
end
ManualCraftCtrl._RefreshStartCraftBtn = HL.Method() << function(self)
    local manufactureData = self.m_facManualCraftSystem.manufactureData:GetOrFallback(Utils.getCurrentScope())
    local available = not string.isEmpty(self.m_selectedCraftId) and self:_CheckFormulaAvailable(self.m_selectedCraftId)
    if available then
        self.view.btnCommon.gameObject:SetActive(true)
        if self.m_manualCount > 0 and manufactureData.queue.Count < MAX_MANUFACTURE_LIST_COUNT then
            self.view.btnCommon.interactable = true
        else
            self.view.btnCommon.interactable = false
        end
        self.view.notEnoughBtn.gameObject:SetActive(false)
    else
        self.view.btnCommon.gameObject:SetActive(false)
        self.view.notEnoughBtn.gameObject:SetActive(true)
    end
end
ManualCraftCtrl._PlayCraftListSelectEffect = HL.Method(HL.String) << function(self, lastSelectedCraftId)
    for idx, craftInfo in ipairs(self.m_craftInfoList) do
        local gameObject = self.view.craftContent:Get(CSIndex(idx))
        if gameObject then
            local craftCell = self.m_getCraftCellFunc(gameObject)
            local craftAvailable = self:_CheckFormulaAvailable(craftInfo.id)
            if craftInfo.id == self.m_selectedCraftId then
                craftCell.animationWrapper:Play("manualcraft_compositecell_select_in")
            else
                if craftInfo.id == lastSelectedCraftId then
                    local cell = craftCell
                    cell.defalut.gameObject:SetActive(true)
                    craftCell.animationWrapper:Play("manualcraft_compositecell_select_out", function()
                        if cell ~= self.m_nowCraftCell and self.m_nowCraftCell then
                            cell.selected.gameObject:SetActive(false)
                        end
                    end)
                end
            end
        end
    end
end
ManualCraftCtrl._RefreshMakingState = HL.Method() << function(self)
end
ManualCraftCtrl._ToggleFabricateSound = HL.Method(HL.Boolean) << function(self, isOn)
    if isOn then
        if self.m_fabricateSoundKey == 0 then
            self.m_fabricateSoundKey = AudioManager.PostEvent("au_ui_fac_manualcraft_fabricate")
        end
    else
        if self.m_fabricateSoundKey ~= 0 then
            AudioManager.StopSoundByPlayingId(self.m_fabricateSoundKey)
            self.m_fabricateSoundKey = 0
        end
    end
end
ManualCraftCtrl._OnClickFilter = HL.Method(HL.Any) << function(self, selected)
    for index, info in ipairs(self.m_filterSetting) do
        local keyName = "ManualCraft.Filter.Tab." .. index
        self.m_filterSetting[index].isOn = Unity.PlayerPrefs.GetInt(keyName, info.defaultIsOn and 1 or 0) == 1
    end
    local realList = {}
    for i = 1, #self.m_filterSetting do
        if self.m_realFilterSetting[self.m_filterSetting[i].id] then
            table.insert(realList, self.m_filterSetting[i])
        end
    end
    self.m_filterCells = self.m_filterCells or UIUtils.genCellCache(self.view.settingCell)
    self.m_filterCells:Refresh(#realList, function(cell, index)
        local info = realList[index]
        cell.toggle.isOn = info.isOn
        cell.toggle.onValueChanged:RemoveAllListeners()
        cell.toggle.onValueChanged:AddListener(function(isOn)
            self:_ToggleFilterSettingCell(index, isOn)
        end)
        cell.topLineImg.enabled = index ~= 1
        cell.selectName.text = info.domainName
        cell.notSelectName.text = info.domainName
        cell.gameObject.name = "Cell_" .. index
    end)
    self:_ToggleFilter(not self.view.settingList.gameObject.activeSelf, true)
end
ManualCraftCtrl._ToggleFilter = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, active, noAnimation)
    if self.view.settingList.gameObject.activeSelf == active then
        return
    end
    self.view.settingList.transform:DOKill()
    if noAnimation then
        self.view.settingList.gameObject:SetActive(active)
    else
        self.view.settingList.gameObject:SetActive(true)
        if active then
            self.view.settingList:PlayInAnimation()
        else
            self.view.settingList:PlayOutAnimation(function()
                self.view.settingList.gameObject:SetActive(false)
            end)
        end
    end
    if active and DeviceInfo.usingController then
        self.m_filterCurNaviIndex = 1
        Notify(MessageConst.SHOW_AS_CONTROLLER_SMALL_MENU, { panelId = PANEL_ID, isGroup = true, id = filterNode.inputBindingGroupMonoTarget.groupId, hintPlaceholder = self.view.controllerHintPlaceholder, rectTransform = filterNode.settingList.transform, })
    else
        self.m_filterCurNaviIndex = -1
        Notify(MessageConst.CLOSE_CONTROLLER_SMALL_MENU, PANEL_ID)
    end
    self:_RefreshfilterNaviSelected()
    AudioAdapter.PostEvent(active and "au_ui_menu_sequence_open" or "au_ui_menu_sequence_close")
end
ManualCraftCtrl._ToggleFilterSettingCell = HL.Method(HL.Number, HL.Opt(HL.Boolean)) << function(self, index, active)
    local info = self.m_filterSetting[index]
    if active == nil then
        active = not info.isOn
    end
    info.isOn = active
    local keyName = "ManualCraft.Filter.Tab." .. index
    Unity.PlayerPrefs.SetInt(keyName, active and 1 or 0)
    self.m_filterSetting[index].isOn = active
    self:_RefreshCraftList()
end
ManualCraftCtrl._RefreshfilterNaviSelected = HL.Method() << function(self)
    self.m_filterCells:Update(function(cell, index)
        cell.controllerSelectedHintNode.gameObject:SetActive(index == self.m_filterCurNaviIndex)
    end)
end
ManualCraftCtrl._RefreshManufactureList = HL.Method() << function(self)
end
ManualCraftCtrl._GetIngredientItems = HL.Method(HL.String, HL.Number).Return(HL.Table) << function(self, formulaId, count)
    local manualCraftTable = Tables.factoryManualCraftTable
    local success, craftInfo = manualCraftTable:TryGetValue(formulaId)
    local ret = {}
    if success then
        for i, v in pairs(craftInfo.ingredients) do
            table.insert(ret, { id = v.id, count = v.count * count })
        end
    end
    return ret
end
ManualCraftCtrl._GetOutcomeItems = HL.Method(HL.String, HL.Number).Return(HL.Table) << function(self, formulaId, count)
    local manualCraftTable = Tables.factoryManualCraftTable
    local success, craftInfo = manualCraftTable:TryGetValue(formulaId)
    local ret = {}
    if success then
        for i, v in pairs(craftInfo.outcomes) do
            table.insert(ret, { id = v.id, count = v.count * count })
        end
    end
    return ret
end
ManualCraftCtrl._GetItemCount = HL.Method(HL.String).Return(HL.Any) << function(self, itemId)
    local count = Utils.getItemCount(itemId, false, true)
    return count
end
ManualCraftCtrl._IsValuableItem = HL.Method(HL.String).Return(HL.Boolean) << function(self, itemId)
    local itemData = Tables.itemTable[itemId]
    local valuableDepotType = itemData.valuableTabType
    if valuableDepotType ~= CS.Beyond.GEnums.ItemValuableDepotType.Factory then
        return true
    else
        return false
    end
end
ManualCraftCtrl._CheckFormulaAvailable = HL.Method(HL.String).Return(HL.Boolean) << function(self, formulaId)
    local manualCraftTable = Tables.factoryManualCraftTable
    local success, craftInfo = manualCraftTable:TryGetValue(formulaId)
    if success then
        local needItems = self:_GetIngredientItems(formulaId, 1)
        for _, item in pairs(needItems) do
            local inventoryCount = self:_GetItemCount(item.id)
            if inventoryCount < item.count then
                return false
            end
        end
    end
    return true
end
ManualCraftCtrl.OnManualWorkModify = HL.Method(HL.Any) << function(self, arg)
    local manufactureData = self.m_facManualCraftSystem.manufactureData:GetOrFallback(Utils.getCurrentScope())
    if manufactureData.inBlock then
        GameAction.ShowUIToast(Language.LUA_BAG_FULL)
    end
    local info = {
        title = Language.LUA_FAC_CRAFT_ITEM_SUCCESS_MAKE,
        onComplete = function()
        end,
    }
    arg = arg[1]
    local manualCraftTable = Tables.factoryManualCraftTable
    local success, craftInfo = manualCraftTable:TryGetValue(arg.FormulaId)
    info.items = {}
    local outItems = self:_GetOutcomeItems(arg.FormulaId, arg.Count)
    for _, item in pairs(outItems) do
        table.insert(info.items, { id = item.id, count = item.count, })
    end
    local _arg = { info, craftInfo.itemId, self:_GetIngredientItems(arg.FormulaId, arg.Count) }
    UIManager:Open(PanelId.CompositeToast, _arg)
    self:_RefreshCraftNode()
    self:_RefreshManufactureList()
end
ManualCraftCtrl.OnGetNewManualFormula = HL.StaticMethod(HL.Any) << function(args)
    local newFormulaIds = unpack(args)
    local isOpen, ctrl = UIManager:IsOpen(PANEL_ID)
    if isOpen then
        ctrl:_OnGetNewManualFormula(args)
        ctrl:_RefreshCraftNode()
        ctrl:_RefreshManufactureList()
    else
        if newFormulaIds.Count == 1 then
            local _, craftInfo = Tables.factoryManualCraftTable:TryGetValue(newFormulaIds[0])
            if craftInfo then
                Notify(MessageConst.SHOW_TOAST, string.format(Language.LUA_CRAFT_UNLOCK, craftInfo.name))
            end
        elseif newFormulaIds.Count > 1 then
            local _, craftInfo = Tables.factoryManualCraftTable:TryGetValue(newFormulaIds[0])
            if craftInfo then
                Notify(MessageConst.SHOW_TOAST, string.format(Language.LUA_MULTIPLE_CRAFT_UNLOCK, craftInfo.name, newFormulaIds.Count))
            end
        end
    end
end
ManualCraftCtrl._OnGetNewManualFormula = HL.Method(HL.Any) << function(self, args)
    local newFormulaIds = unpack(args)
    for _, formulaId in pairs(newFormulaIds) do
        local _, formulaData = Tables.factoryManualCraftTable:TryGetValue(formulaId)
        if formulaData then
            for i, k in pairs(filterList) do
                if k.type == formulaData.showingType and not self.m_cntFilterTypeShow[k.type] then
                    self.m_filterTypeTabCellCache:GetItem(i).gameObject:SetActive(true)
                    self.m_cntFilterTypeShow[k.type] = true
                end
            end
            self:_StartTimer(1, function()
                Notify(MessageConst.SHOW_TOAST, string.format(Language.LUA_CRAFT_UNLOCK, formulaData.name))
            end)
        end
    end
    self.m_selectedCraftTabType = nil
    if self.m_cntFilterType == nil then
        for i, k in pairs(filterList) do
            if self.m_cntFilterTypeShow[k.type] then
                self:_SetFilterType(k.type)
                break
            end
        end
    else
        for i, k in pairs(filterList) do
            if k.type == self.m_cntFilterType then
                self:_SetFilterType(self.m_cntFilterType)
                break
            end
        end
    end
end
ManualCraftCtrl.OnUnlockManualCraft = HL.StaticMethod(HL.Any) << function(args)
    local newItems = unpack(args)
    local info = {
        title = Language.LUA_FAC_MANUAL_CRAFT_UNLOCK,
        subTitle = Language.LUA_LOST_AND_FOUND_GET_ALL,
        onComplete = function()
        end,
    }
    info.items = {}
    for _, v in pairs(newItems) do
        local id = Tables.factoryManualCraftFormulaUnlockTable:GetValue(v).rewardItemId1
        table.insert(info.items, { id = id, count = 1, })
    end
    Notify(MessageConst.SHOW_SYSTEM_REWARDS, info)
end
ManualCraftCtrl.OnManualWorkCancel = HL.Method(HL.Any) << function(self, arg)
    local backItems, breakItems = unpack(arg)
    local showItems = {}
    for itemId, itemCount in pairs(backItems) do
        table.insert(showItems, { id = itemId, count = itemCount })
    end
    if self.m_fabricateSoundKey ~= 0 then
        AudioManager.StopSoundByPlayingId(self.m_fabricateSoundKey)
        self.m_fabricateSoundKey = 0
    end
    AudioManager.PostEvent("au_ui_fac_manualcraft_terminate")
    GameAction.ShowUIToast(Language.LUA_MANUAL_WORK_HAS_BEEN_CANCELLED)
end
ManualCraftCtrl.OnShow = HL.Override() << function(self)
    self:_RefreshMakingState()
end
ManualCraftCtrl.OnHide = HL.Override() << function(self)
    self:_ToggleFabricateSound(false)
end
ManualCraftCtrl.OnClose = HL.Override() << function(self)
    local craftIds = {}
    for craftId, _ in pairs(self.m_readCraftIds) do
        table.insert(craftIds, craftId)
    end
    self.m_facManualCraftSystem:ReadCrafts(craftIds)
    self:_ToggleFabricateSound(false)
    self:Notify(MessageConst.ON_ENABLE_COMMON_TOAST)
end
ManualCraftCtrl.OnAnimationInFinished = HL.Override() << function(self)
    local obj = self.view.craftContent:Get(0)
    if obj then
        InputManagerInst:MoveVirtualMouseTo(obj.transform, self.uiCamera)
    end
end
HL.Commit(ManualCraftCtrl)