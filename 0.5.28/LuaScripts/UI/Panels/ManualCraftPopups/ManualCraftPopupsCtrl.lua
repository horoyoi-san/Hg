local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ManualCraftPopups
ManualCraftPopupsCtrl = HL.Class('ManualCraftPopupsCtrl', uiCtrl.UICtrl)
ManualCraftPopupsCtrl.m_itemCellList = HL.Field(HL.Forward("UIListCache"))
ManualCraftPopupsCtrl.m_unlockItemList = HL.Field(HL.Table)
ManualCraftPopupsCtrl.m_unlockItemRewardMap = HL.Field(HL.Table)
ManualCraftPopupsCtrl.m_unlockItemIdCellMap = HL.Field(HL.Table)
ManualCraftPopupsCtrl.m_facManualCraftSystem = HL.Field(HL.Any)
ManualCraftPopupsCtrl.m_inventorySystem = HL.Field(HL.Any)
ManualCraftPopupsCtrl.m_selectIndex = HL.Field(HL.Number) << 0
ManualCraftPopupsCtrl.m_rewardCellList = HL.Field(HL.Forward("UIListCache"))
ManualCraftPopupsCtrl.m_previewCellList = HL.Field(HL.Forward("UIListCache"))
ManualCraftPopupsCtrl.m_getDefaultCell = HL.Field(HL.Function)
ManualCraftPopupsCtrl.m_getSelectCell = HL.Field(HL.Function)
ManualCraftPopupsCtrl.m_needRefreshReward = HL.Field(HL.Boolean) << false
ManualCraftPopupsCtrl.m_sortMode = HL.Field(HL.Number) << 1
ManualCraftPopupsCtrl.m_sortIncremental = HL.Field(HL.Boolean) << false
ManualCraftPopupsCtrl.m_activeScroll = HL.Field(HL.Boolean) << false
ManualCraftPopupsCtrl.m_filterSetting = HL.Field(HL.Table)
ManualCraftPopupsCtrl.m_realData = HL.Field(HL.Table)
ManualCraftPopupsCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_MANUAL_CRAFT_LEVEL_UP] = 'OnGetNewItemLevelUp', [MessageConst.ON_MANUAL_CRAFT_GET_ITEM_REWARD] = 'OnGetReward', [MessageConst.ON_GET_MANUAL_REWARD] = '_OnGetReward' }
local sortOptions = { { name = Language.LUA_FAC_CRAFT_SORT_1, sortMode = 1, sortKeys = { "sortId1", "sortId2", "rarity", "id" }, }, { name = Language.LUA_FAC_CRAFT_SORT_2, sortMode = 2, sortKeys = { "rarity", "sortId1", "sortId2", "id" }, }, }
ManualCraftPopupsCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.selectPanel.gameObject:SetActive(false)
    self.m_facManualCraftSystem = GameInstance.player.facManualCraft
    self.m_inventorySystem = GameInstance.player.inventory
    self.m_selectIndex = 0
    self.m_unlockItemList = nil
    self.m_unlockItemRewardMap = {}
    self.m_unlockItemIdCellMap = {}
    self.view.leftArrow.onClick:AddListener(function()
        if self.m_selectIndex > 1 then
            self.m_activeScroll = true
            self.m_selectIndex = self.m_selectIndex - 1
            self:_UpdateSelectView(false)
            self.view.selectPanel:GetComponent(typeof(CS.Beyond.UI.UIAnimationWrapper)):Play("manualcraftpopups_select_switch")
        end
    end)
    self.view.rightArrow.onClick:AddListener(function()
        if self.m_selectIndex < #self.m_unlockItemList then
            self.m_activeScroll = true
            self.m_selectIndex = self.m_selectIndex + 1
            self:_UpdateSelectView(false)
            self.view.selectPanel:GetComponent(typeof(CS.Beyond.UI.UIAnimationWrapper)):Play("manualcraftpopups_select_switch")
        end
    end)
    self.view.btnBack.onClick:AddListener(function()
        if self.view.selectPanel.gameObject.activeSelf then
            self:_UpdateDefaultView(self.m_needRefreshReward)
        else
            self:PlayAnimationOutAndClose()
        end
    end)
    self:BindInputPlayerAction("common_cancel", function()
        if self.view.selectPanel.gameObject.activeSelf then
            self:_UpdateDefaultView(self.m_needRefreshReward)
        else
            self:PlayAnimationOutAndClose()
        end
    end)
    self.view.returnBtn.onClick:AddListener(function()
        self:_UpdateDefaultView(self.m_needRefreshReward)
    end)
    self.view.btnCommon.onClick:AddListener(function()
        local nowLockData = self.m_unlockItemList[self.m_selectIndex]
        local nowCount = self.m_facManualCraftSystem:GetItemAccumulateCount(nowLockData.itemId)
        local list = CS.Beyond.Lua.UtilsForLua.GetStringList()
        for i = 0, nowLockData.rewardList.Count - 1 do
            local rewardId = nowLockData.rewardList[i]
            local condition = nowLockData.unlockCondition[i]
            local unlockId = nowLockData.unlockIdList[i]
            local haveGet = self.m_facManualCraftSystem:CheckHaveGetReward(unlockId)
            if nowCount >= condition and not haveGet then
                list:Add(unlockId)
            end
        end
        self.m_facManualCraftSystem:ReqManuallyUnlock(Utils.getCurrentScope(), list)
    end)
    self.m_getDefaultCell = self.m_getDefaultCell or UIUtils.genCachedCellFunction(self.view.itemList)
    self.m_getSelectCell = self.m_getSelectCell or UIUtils.genCachedCellFunction(self.view.previewScrollList)
    self.view.itemList.onUpdateCell:AddListener(function(gameObject, index)
        self:_UpdateDefaultCell((gameObject), index)
    end)
    self.view.previewScrollList.onUpdateCell:AddListener(function(gameObject, index)
        self:_UpdateSelectCell((gameObject), index)
    end)
    self.view.previewScrollList:SetPaddingRight(self.view.previewScrollList.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)).rect.width / 2 - 200)
    self.view.previewScrollList:SetPaddingLeft(self.view.previewScrollList.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)).rect.width / 2 - 200)
    self.m_unlockItemList = {}
    for k, v in cs_pairs(self.m_facManualCraftSystem.manufactureUnlockDataMap) do
        table.insert(self.m_unlockItemList, v)
    end
    self.m_sortIncremental = true
    self.view.sortNodeUp:InitSortNode(sortOptions, function(optData, isIncremental)
        self.m_sortMode = optData.sortMode
        self.m_sortIncremental = isIncremental
        self:_UpdateDefaultView(true)
    end, 0, self.m_sortIncremental, true)
    self.m_filterSetting = {}
    local selectedFilter = {}
    local list = self.m_facManualCraftSystem:GetAllDomainData()
    for i = 0, list.Count - 1 do
        local domainData = list[i]
        table.insert(self.m_filterSetting, { id = domainData.domainId, domainName = domainData.domainName, defaultIsOn = true, name = domainData.domainName, isOn = true })
        table.insert(selectedFilter, self.m_filterSetting[i + 1])
    end
    self.view.filterBtn:InitFilterBtn({
        tagGroups = { { tags = self.m_filterSetting } },
        selectedTags = {},
        onConfirm = function(tags)
            for i = 1, #self.m_filterSetting do
                self.m_filterSetting[i].isOn = false
            end
            if tags ~= nil then
                for i = 1, #tags do
                    for j = 1, #self.m_filterSetting do
                        if self.m_filterSetting[j].id == tags[i].id then
                            self.m_filterSetting[j].isOn = true
                        end
                    end
                end
            end
            self:_UpdateDefaultView(true)
        end,
        getResultCount = function(tags)
            local noSelect = #tags == 0
            if noSelect then
                return #self.m_unlockItemList
            end
            local count = 0
            for i = 1, #self.m_realData do
                local itemId = self.m_realData[i].itemId
                local nowCount = self.m_facManualCraftSystem:GetItemAccumulateCount(itemId)
                if nowCount > 0 then
                    if noSelect then
                        count = count + 1
                    else
                        for j = 1, #tags do
                            local gather = Tables.itemGatherTextTable:GetValue(itemId)
                            if gather.domainId == tags[j].id then
                                count = count + 1
                                break
                            end
                        end
                    end
                end
            end
            return count
        end
    })
    self.view.previewScrollList.onCenterIndexChanged:AddListener(function(oldIndex, newIndex)
        if self.m_selectIndex ~= newIndex + 1 and not self.m_activeScroll then
            self.m_selectIndex = newIndex + 1
            self:_UpdateSelectView(false)
            self.m_activeScroll = false
            return
        end
    end)
    self.view.itemList.onGraduallyShowFinish:AddListener(function()
        self.m_needRefreshReward = false
    end)
    self.view.previewScrollList.onScrollEnd:AddListener(function()
        if self.m_activeScroll then
            self.m_activeScroll = false
            self.view.previewScrollList:ScrollToIndex(self.m_selectIndex - 1)
        end
    end)
    self:_UpdateDefaultView(true)
end
ManualCraftPopupsCtrl._SortAndFilter = HL.Method() << function(self)
    if not self.m_realData then
        self.m_realData = self.m_unlockItemList
    end
    self.m_unlockItemList = self.m_realData
    local noSelect = true
    for i = 1, #self.m_filterSetting do
        if self.m_filterSetting[i].isOn then
            noSelect = false
            break
        end
    end
    local sortData = {}
    for i = 1, #self.m_unlockItemList do
        local itemId = self.m_unlockItemList[i].itemId
        local nowCount = self.m_facManualCraftSystem:GetItemAccumulateCount(itemId)
        if nowCount > 0 then
            if noSelect then
                table.insert(sortData, self.m_unlockItemList[i])
            else
                for j = 1, #self.m_filterSetting do
                    local gather = Tables.itemGatherTextTable:GetValue(itemId)
                    if self.m_filterSetting[j].isOn and gather.domainId == self.m_filterSetting[j].id then
                        table.insert(sortData, self.m_unlockItemList[i])
                        break
                    end
                end
            end
        end
    end
    local nowSelectItem = nil
    if self.m_selectIndex then
        nowSelectItem = self.m_unlockItemList[self.m_selectIndex]
    end
    table.sort(sortData, function(a, b)
        local itemId1 = a.itemId
        local itemId2 = b.itemId
        local canGet1 = self.m_facManualCraftSystem:CheckHaveRewardByItemNoGet(itemId1) > 0
        local canGet2 = self.m_facManualCraftSystem:CheckHaveRewardByItemNoGet(itemId2) > 0
        if canGet1 ~= canGet2 then
            return canGet1
        end
        local allGet1 = self.m_facManualCraftSystem:CheckAllGet(itemId1)
        local allGet2 = self.m_facManualCraftSystem:CheckAllGet(itemId2)
        if allGet1 ~= allGet2 then
            return not allGet1
        end
        local itemData1 = Tables.itemTable:GetValue(itemId1)
        local itemData2 = Tables.itemTable:GetValue(itemId2)
        local sortKeys = sortOptions[self.m_sortMode].sortKeys
        for i = 1, #sortKeys do
            local key = sortKeys[i]
            local value1 = itemData1[key]
            local value2 = itemData2[key]
            if value1 ~= value2 then
                if self.m_sortIncremental then
                    return value1 < value2
                else
                    return value1 > value2
                end
            end
        end
        return false
    end)
    self.m_unlockItemList = sortData
    if nowSelectItem then
        for i = 1, #self.m_unlockItemList do
            if self.m_unlockItemList[i].itemId == nowSelectItem.itemId then
                self.m_selectIndex = i
                break
            end
        end
    end
end
ManualCraftPopupsCtrl._UpdateDefaultView = HL.Method(HL.Boolean) << function(self, needSortAndFilter)
    self.view.selectPanel:GetComponent(typeof(CS.Beyond.UI.UIAnimationWrapper)):Play("manualcraftpopups_select_out", function()
        self.view.selectPanel.gameObject:SetActive(false)
    end)
    self.view.defaultScrollbarVertical.gameObject:SetActive(true)
    self.view.bottomBg.gameObject:SetActive(true)
    self.view.itemList.gameObject:SetActive(true)
    self.view.btnBack.gameObject:SetActive(true)
    if needSortAndFilter then
        self:_SortAndFilter()
    end
    self.view.itemList:UpdateCount(#self.m_unlockItemList)
    self.view.sortNodeUp.gameObject:SetActive(true)
    self.view.emptyStateTextNode.gameObject:SetActive(true)
    local gatherMap = {}
    for i = 1, #self.m_realData do
        local itemId = self.m_realData[i].itemId
        local nowCount = self.m_facManualCraftSystem:GetItemAccumulateCount(itemId)
        local gather = Tables.itemGatherTextTable:GetValue(itemId)
        if nowCount > 0 then
            gatherMap[gather.domainId] = true
        end
    end
    local count = 0
    for k, v in pairs(gatherMap) do
        count = count + 1
    end
    self.view.filterBtn.gameObject:SetActive(count > 1)
    if self.m_selectIndex then
        self.m_activeScroll = true
        self.view.previewScrollList:ScrollToIndex(self.m_selectIndex - 1)
    end
end
ManualCraftPopupsCtrl._UpdateDefaultCell = HL.Method(GameObject, HL.Number) << function(self, cell, index)
    index = index + 1
    cell = self.m_getDefaultCell(cell)
    local item = self.m_unlockItemList[index]
    local itemData = Tables.itemTable:GetValue(item.itemId)
    cell.gameObject.name = "CardsCell_" .. item.itemId
    cell.itemIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, itemData.iconId)
    cell.commodityText.text = itemData.name
    UIUtils.setItemRarityImage(cell.qualityColor, itemData.rarity)
    local needRefresh = self.m_needRefreshReward
    if not self.m_unlockItemRewardMap[cell] then
        self.m_unlockItemRewardMap[cell] = UIUtils.genCellCache(cell.cell)
        needRefresh = true
    end
    if not self.m_unlockItemIdCellMap[cell] then
        self.m_unlockItemIdCellMap[cell] = item.itemId
    else
        if self.m_unlockItemIdCellMap[cell] ~= item.itemId then
            needRefresh = true
            self.m_unlockItemIdCellMap[cell] = item.itemId
        end
    end
    local _, data = self.m_facManualCraftSystem.manufactureUnlockDataMap:TryGetValue(item.itemId)
    local allGet = self.m_facManualCraftSystem:CheckAllGet(item.itemId)
    cell.redDot:InitRedDot("ManualCraftReward", { itemId = item.itemId })
    if allGet then
        cell.finishBgNode.gameObject:SetActive(true)
    else
        cell.finishBgNode.gameObject:SetActive(false)
    end
    local path = Tables.itemGatherTextTable:GetValue(item.itemId).icon
    cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MANUAL_CRAFT_TYPE_ICON, path)
    local unlockRewardList = self.m_unlockItemRewardMap[cell]
    if needRefresh then
        unlockRewardList:Refresh(data.rewardList.Count, function(rewardCell, rewardIndex)
            rewardCell.gameObject:SetActive(true)
            rewardIndex = rewardIndex - 1
            local rewardId = data.rewardList[rewardIndex]
            local count = data.rewardCount[rewardIndex]
            local condition = data.unlockCondition[rewardIndex]
            local unlockId = data.unlockIdList[rewardIndex]
            local haveGet = self.m_facManualCraftSystem:CheckHaveGetReward(unlockId)
            rewardCell.gameObject:SetActive(true)
            rewardCell.itemBigBlack:InitItem({ id = rewardId, count = count }, false)
            local nowCount = self.m_facManualCraftSystem:GetItemAccumulateCount(data.itemId)
            rewardCell.notAvailable.gameObject:SetActive(not haveGet and nowCount < condition)
            rewardCell.availableEffect.gameObject:SetActive(not haveGet and nowCount >= condition)
            rewardCell.rewardedCover.gameObject:SetActive(haveGet)
            self:_UpdateProgress(rewardCell.manufactureProgress, data, rewardIndex)
            if data.rewardList.Count == rewardIndex + 1 then
            end
        end)
    end
    cell.button.onClick:RemoveAllListeners()
    cell.button.onClick:AddListener(function()
        self.m_selectIndex = index
        self.m_activeScroll = true
        self:_UpdateSelectView(false)
        self.view.selectPanel:GetComponent(typeof(CS.Beyond.UI.UIAnimationWrapper)):Play("manualcraftpopups_select_in")
    end)
end
ManualCraftPopupsCtrl._UpdateSelectView = HL.Method(HL.Boolean) << function(self, needSortAndFilter)
    self.view.itemList.gameObject:SetActive(false)
    self.view.selectPanel.gameObject:SetActive(true)
    self.view.sortNodeUp.gameObject:SetActive(false)
    self.view.emptyStateTextNode.gameObject:SetActive(false)
    self.view.filterBtn.gameObject:SetActive(false)
    self.view.bottomBg.gameObject:SetActive(false)
    self.view.btnBack.gameObject:SetActive(false)
    self.view.leftArrow.interactable = self.m_selectIndex > 1
    self.view.rightArrow.interactable = self.m_selectIndex < #self.m_unlockItemList
    self.view.defaultScrollbarVertical.gameObject:SetActive(false)
    if needSortAndFilter then
        self:_SortAndFilter()
    end
    self.m_activeScroll = true
    local itemId = self.m_unlockItemList[self.m_selectIndex].itemId
    self.m_rewardCellList = self.m_rewardCellList or UIUtils.genCellCache(self.view.rewardCell)
    local _, data = self.m_facManualCraftSystem.manufactureUnlockDataMap:TryGetValue(self.m_unlockItemList[self.m_selectIndex].itemId)
    self.view.previewScrollList:UpdateCount(#self.m_unlockItemList)
    self.view.previewScrollList:ScrollToIndex(self.m_selectIndex - 1)
    local allChildCount = self.view.progressBar.transform.childCount
    local haveGet = self.m_facManualCraftSystem:CheckHaveRewardByItemNoGet(itemId)
    local allGet = self.m_facManualCraftSystem:CheckHaveRewardByItemAllGet(itemId)
    self.view.btnCommon.gameObject:SetActive(haveGet > 0)
    self.view.completBtn.gameObject:SetActive(allGet)
    for i = 0, allChildCount - 1 do
        self.view.progressBar.transform:GetChild(i).gameObject:SetActive(false)
    end
    local gatherText = Tables.itemGatherTextTable:GetValue(itemId).desc
    self.view.previewText.text = UIUtils.resolveTextStyle(gatherText)
    self.m_rewardCellList:Refresh(data.rewardList.Count, function(cell, index)
        index = CSIndex(index)
        local rewardId = data.rewardList[index]
        local count = data.rewardCount[index]
        local condition = data.unlockCondition[index]
        local unlockId = data.unlockIdList[index]
        local nowCount = self.m_facManualCraftSystem:GetItemAccumulateCount(data.itemId)
        local haveGet = self.m_facManualCraftSystem:CheckHaveGetReward(unlockId);
        cell.receivedNode.gameObject:SetActive(haveGet)
        cell.available.gameObject:SetActive(not haveGet and nowCount >= condition)
        cell.notAvailable.gameObject:SetActive(not haveGet and nowCount < condition)
        cell.receivedNode.finish.gameObject:SetActive(haveGet)
        cell.available.receiveBtn.onClick:RemoveAllListeners()
        cell.available.receiveBtn.onClick:AddListener(function()
            self.m_facManualCraftSystem:ReqManuallyUnlock(Utils.getCurrentScope(), unlockId)
        end)
        local nowCount = self.m_facManualCraftSystem:GetItemAccumulateCount(data.itemId)
        self.view.progressText.text = nowCount
        local view = {}
        self.view.progressBar.transform:GetChild(index):GetComponent(typeof(CS.Beyond.Lua.LuaReference)):BindToLua(view)
        self:_UpdateProgress(view, data, index)
        local itemDaa = { id = rewardId, count = count }
        local activeNode = cell.available
        if nowCount < condition then
            activeNode = cell.notAvailable
        elseif haveGet then
            activeNode = cell.receivedNode
        else
            activeNode = cell.available
        end
        if activeNode.itemBigBlack then
            activeNode.itemBigBlack:InitItem(itemDaa, true)
        end
        activeNode.commodityText.text = Tables.itemTable:GetValue(rewardId).name
    end)
    self.view.previewScrollList:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect)).horizontal = false
end
ManualCraftPopupsCtrl._UpdateSelectCell = HL.Method(GameObject, HL.Number) << function(self, cell, index)
    index = index + 1
    cell = self.m_getSelectCell(cell)
    local previewId = self.m_unlockItemList[index].itemId
    local activeNode = cell.select
    if self.m_selectIndex == index then
        cell.select.gameObject:SetActive(true)
        cell.unselected.gameObject:SetActive(false)
        activeNode = cell.select
    else
        cell.select.gameObject:SetActive(false)
        cell.unselected.gameObject:SetActive(true)
        activeNode = cell.unselected
    end
    local itemData = Tables.itemTable:GetValue(previewId)
    activeNode.commodityText.text = itemData.name
    activeNode.itemIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, itemData.iconId)
    UIUtils.setItemRarityImage(activeNode.qualityColor, itemData.rarity)
    local path = Tables.itemGatherTextTable:GetValue(previewId).icon
    cell.select.typeIcon1.sprite = self:LoadSprite(UIConst.UI_SPRITE_MANUAL_CRAFT_TYPE_ICON, path)
    cell.unselected.typeIcon2.sprite = self:LoadSprite(UIConst.UI_SPRITE_MANUAL_CRAFT_TYPE_ICON, path)
    cell.button.onClick:RemoveAllListeners()
    cell.button.onClick:AddListener(function()
        if self.m_selectIndex == index then
            return
        end
        self.m_selectIndex = index
        self.m_facManualCraftSystem:ReadRewardByItem(previewId)
        self:_UpdateSelectView(false)
        self.view.selectPanel:GetComponent(typeof(CS.Beyond.UI.UIAnimationWrapper)):Play("manualcraftpopups_select_switch")
    end)
    cell.redDot:InitRedDot("ManualCraftReward", { itemId = self.m_unlockItemList[index].itemId })
end
ManualCraftPopupsCtrl._UpdateProgress = HL.Method(HL.Any, HL.Any, HL.Number) << function(self, cell, unlockData, index)
    cell.gameObject:SetActive(true)
    cell.text.text = tostring(unlockData.unlockCondition[index])
    local nowCount = self.m_facManualCraftSystem:GetItemAccumulateCount(unlockData.itemId)
    local isUnlock = nowCount >= unlockData.unlockCondition[index]
    cell.selected.gameObject:SetActive(isUnlock)
    cell.selectedLine.gameObject:SetActive(false)
    cell.text.color = isUnlock and Color.black or Color.white
    if cell.defalutLine then
        cell.defalutLine.gameObject:SetActive(false)
        if index < unlockData.rewardList.Count - 1 then
            cell.defalutLine.gameObject:SetActive(true)
            if cell.line then
                cell.line.gameObject:SetActive(true)
            end
        end
    end
    if index < unlockData.rewardList.Count - 1 then
        cell.selectedLine.gameObject:SetActive(true)
        local lastCount = index ~= 0 and unlockData.unlockCondition[index] or 0
        if nowCount == 1 then
            nowCount = 0
        end
        cell.selectedLine.fillAmount = (nowCount - lastCount) / (unlockData.unlockCondition[index + 1] - lastCount)
    end
    if unlockData.rewardList.Count < 5 and index == unlockData.rewardList.Count - 1 and cell.line then
        cell.line.gameObject:SetActive(false)
    end
end
ManualCraftPopupsCtrl._GetItemCount = HL.Method(HL.String).Return(HL.Any) << function(self, itemId)
    if Utils.isInSafeZone() or self:_IsValuableItem(itemId) then
        return self.m_inventorySystem:GetItemCount(Utils.getCurrentScope(), Utils.getCurrentChapterId(), itemId)
    else
        return self.m_inventorySystem:GetItemCountInBag(Utils.getCurrentScope(), itemId)
    end
end
ManualCraftPopupsCtrl._IsValuableItem = HL.Method(HL.String).Return(HL.Boolean) << function(self, itemId)
    local itemData = Tables.itemTable[itemId]
    local valuableDepotType = itemData.valuableTabType
    if valuableDepotType ~= CS.Beyond.GEnums.ItemValuableDepotType.Factory then
        return true
    else
        return false
    end
end
ManualCraftPopupsCtrl.OnGetNewItemLevelUp = HL.Method(HL.Any) << function(self, args)
    self.m_needRefreshReward = true
    UIManager:Open(PanelId.ManualcraftUpgradePopup, { itemList = args })
    if self.view.selectPanel.gameObject.activeSelf then
        self:_UpdateSelectView(false)
    else
        self:_UpdateDefaultView(true)
    end
end
ManualCraftPopupsCtrl._OnGetReward = HL.Method(HL.Any) << function(self, newItems)
    self.m_needRefreshReward = true
    self:OnGetReward(newItems)
    if self.view.selectPanel.gameObject.activeSelf then
        self:_UpdateSelectView(false)
    else
        self:_UpdateDefaultView(true)
    end
end
ManualCraftPopupsCtrl.OnGetReward = HL.Method(HL.Any) << function(self, newItems)
    local idList = newItems[1]
    local info = {
        title = Language.LUA_FAC_MANUAL_CRAFT_REWARD,
        onComplete = function()
        end,
    }
    info.items = {}
    local levelUp = {}
    for i = 0, idList.Count - 1 do
        local id = idList[i]
        local data = Tables.factoryManualCraftFormulaUnlockTable:GetValue(id)
        local itemId = data.rewardItemId1
        local count = data.rewardItemCount1
        local itemData = Tables.itemTable:GetValue(itemId)
        table.insert(info.items, { id = itemId, count = count, })
        if itemData.type == CS.Beyond.GEnums.ItemType.FormulaLevelUp then
            table.insert(levelUp, id)
        end
    end
    if #levelUp > 0 then
        if #info.items > 0 then
            info.onComplete = function()
                Notify(MessageConst.ON_MANUAL_CRAFT_LEVEL_UP, levelUp)
            end
        else
            Notify(MessageConst.ON_MANUAL_CRAFT_LEVEL_UP, levelUp)
        end
    end
    if #info.items > 0 then
        Notify(MessageConst.SHOW_SYSTEM_REWARDS, info)
    end
end
ManualCraftPopupsCtrl.OnClose = HL.Override() << function(self)
    self.view.previewScrollList.onScrollEnd:RemoveAllListeners()
end
HL.Commit(ManualCraftPopupsCtrl)