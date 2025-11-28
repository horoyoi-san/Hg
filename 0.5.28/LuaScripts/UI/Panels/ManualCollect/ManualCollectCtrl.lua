local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ManualCollect
local PHASE_ID = PhaseId.ManualCollect
ManualCollectCtrl = HL.Class('ManualCollectCtrl', uiCtrl.UICtrl)
ManualCollectCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ITEM_SUBMIT_RECYCLE_RESULT] = 'OnSubmitRecycleItem', }
ManualCollectCtrl.m_onlyShow = HL.Field(HL.Boolean) << false
ManualCollectCtrl.m_selectDynamic = HL.Field(HL.Boolean) << true
ManualCollectCtrl.m_itemTotalCount = HL.Field(HL.Number) << 0
ManualCollectCtrl.m_hasSubmittedItems = HL.Field(HL.Table)
ManualCollectCtrl.m_canSubmitItems = HL.Field(HL.Table)
ManualCollectCtrl.m_selectedItems = HL.Field(HL.Table)
ManualCollectCtrl.m_selectedNum = HL.Field(HL.Number) << 0
ManualCollectCtrl.m_singleSelectGridIndex = HL.Field(HL.Number) << 0
ManualCollectCtrl.m_singleSelectListIndex = HL.Field(HL.Number) << 0
ManualCollectCtrl.m_getItemCell = HL.Field(HL.Function)
ManualCollectCtrl.m_gridItemCellCache = HL.Field(HL.Forward("UIListCache"))
ManualCollectCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local onlyShow = arg.onlyShow
    self.m_onlyShow = not not onlyShow
    self.m_hasSubmittedItems = {}
    self.m_canSubmitItems = {}
    self.m_selectedItems = {}
    self.view.btnClose.onClick:RemoveAllListeners()
    self.view.btnClose.onClick:AddListener(function()
        self:_DoNext(1)
    end)
    self.view.downNode.selectAllBtn.onClick:RemoveAllListeners()
    self.view.downNode.selectAllBtn.onClick:AddListener(function()
        self:_SelectAll()
    end)
    self.view.downNode.clearAllBtn.onClick:RemoveAllListeners()
    self.view.downNode.clearAllBtn.onClick:AddListener(function()
        self:_ClearAll()
    end)
    self.view.downNode.tipsBtn.onClick:RemoveAllListeners()
    self.view.downNode.tipsBtn.onClick:AddListener(function()
        self:_ShowMoneyTips()
    end)
    self.view.downNode.confirmBtn.onClick:RemoveAllListeners()
    self.view.downNode.confirmBtn.onClick:AddListener(function()
        local itemIds = {}
        for itemId, _ in pairs(self.m_selectedItems) do
            table.insert(itemIds, itemId)
        end
        GameInstance.player.inventory:SendItemSubmitRecycle(itemIds)
    end)
    self.m_gridItemCellCache = UIUtils.genCellCache(self.view.showListNode.propGridContent.propCell)
    if self.m_onlyShow then
        self.m_getItemCell = UIUtils.genCachedCellFunction(self.view.showListNode.itemList)
    else
        self.m_getItemCell = UIUtils.genCachedCellFunction(self.view.listNode.itemList)
    end
    self.view.listNode.itemList.onUpdateCell:AddListener(function(object, csIndex)
        self:_OnUpdateItemList(self.m_getItemCell(object), LuaIndex(csIndex))
    end)
    self.view.showListNode.itemList.onUpdateCell:AddListener(function(object, csIndex)
        local canSubmitDynamic = self:_GetCanSubmitDynamic()
        if canSubmitDynamic then
            self:_OnUpdateItemList(self.m_getItemCell(object), LuaIndex(csIndex))
        else
            self:_OnUpdateHasCollectedItem(self.m_getItemCell(object), LuaIndex(csIndex))
        end
    end)
end
ManualCollectCtrl.OnShow = HL.Override() << function(self)
    self:_RefreshTitle()
    self:_RefreshList()
end
ManualCollectCtrl._UpdateItemData = HL.Method() << function(self)
    self.m_canSubmitItems = {}
    self.m_hasSubmittedItems = {}
    self.m_itemTotalCount = 0
    for itemId, _ in pairs(Tables.itemSubmitRecycleTable) do
        local hasSubmitted = GameInstance.player.inventory:HasItemRecycled(itemId)
        local validItemManualCraft = Utils.validItemManualCraft(itemId)
        local hasCraft, unlock = Utils.unlockCraft(itemId)
        local itemCount = GameInstance.player.inventory:GetItemCountInBag(Utils.getCurrentScope(), itemId)
        if hasSubmitted then
            table.insert(self.m_hasSubmittedItems, itemId)
        else
            if (self.m_onlyShow and unlock) or itemCount > 0 then
                local tbData = Tables.itemTable[itemId]
                local data = { itemId = itemId, count = itemCount, countEnough = itemCount > 0 and 1 or 0, rarity = tbData.rarity, unlock = unlock and 1 or 0, validItemManualCraft = (validItemManualCraft and itemCount == 0) and 1 or 0, sortId = tbData.sortId1, }
                table.insert(self.m_canSubmitItems, data)
            end
        end
        table.sort(self.m_canSubmitItems, Utils.genSortFunction({ "validItemManualCraft", "countEnough", "rarity", "sortId" }, false))
        self.m_itemTotalCount = self.m_itemTotalCount + 1
    end
    if self.m_onlyShow then
        self.m_selectDynamic = #self.m_canSubmitItems >= self.m_itemTotalCount / 2
    else
        self.m_selectDynamic = true
    end
end
ManualCollectCtrl._OnUpdateItemList = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local data = self.m_canSubmitItems[index]
    local itemId = data.itemId
    local count = data.count
    cell.commonStorageNodeNew.gameObject:SetActive(true)
    cell.commonStorageNodeNew:InitStorageNode(count, 0, true, true)
    cell.rewardItemBlack.view.receive.gameObject:SetActive(false)
    local itemCount = GameInstance.player.inventory:GetItemCountInBag(Utils.getCurrentScope(), itemId)
    local validItemManualCraft = Utils.validItemManualCraft(itemId)
    cell.rewardItemBlack.view.tool.gameObject:SetActive(itemCount == 0 and validItemManualCraft)
    local itemBundle = { id = itemId, }
    if not self.m_onlyShow then
        itemBundle.count = 1
    end
    local canSubmitDynamic = self:_GetCanSubmitDynamic()
    cell.rewardItemBlack:InitItem(itemBundle, function()
        self:_ClearLastSingleSelect()
        self:_OnItemClicked(index, cell, itemBundle)
        if not self.m_onlyShow or canSubmitDynamic then
            self.m_singleSelectListIndex = index
        else
            self.m_singleSelectGridIndex = index
        end
    end)
    if count == 0 and self.m_onlyShow then
        cell.rewardItemBlack.view.icon:SetAlpha(0.3)
    else
        cell.rewardItemBlack.view.icon:SetAlpha(1)
    end
    local selected = canSubmitDynamic and index == self.m_singleSelectListIndex or index == self.m_singleSelectGridIndex
    cell.rewardItemBlack.view.selectedBG.gameObject:SetActive(selected)
    self:_RefreshSingleItemSelected(cell)
end
ManualCollectCtrl._GetCanSubmitDynamic = HL.Method().Return(HL.Boolean) << function(self)
    local canSubmitDynamic = self.m_onlyShow and #self.m_canSubmitItems > #self.m_hasSubmittedItems
    return canSubmitDynamic
end
ManualCollectCtrl._OnUpdateHasCollectedItem = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local itemId = self.m_hasSubmittedItems[index]
    cell.rewardItemBlack.view.receive.gameObject:SetActive(true)
    cell.rewardItemBlack.view.tool.gameObject:SetActive(false)
    local canSubmitDynamic = self:_GetCanSubmitDynamic()
    local itemBundle = { id = itemId, }
    cell.commonStorageNodeNew.gameObject:SetActive(false)
    local singleSelect
    cell.rewardItemBlack:InitItem(itemBundle, function()
        self:_ClearLastSingleSelect()
        self:_OnItemClicked(index, cell, itemBundle)
        if canSubmitDynamic then
            self.m_singleSelectGridIndex = index
        else
            self.m_singleSelectListIndex = index
        end
    end)
    if canSubmitDynamic then
        singleSelect = index == self.m_singleSelectListIndex
    else
        singleSelect = index == self.m_singleSelectGridIndex
    end
    cell.rewardItemBlack.view.selectedBG.gameObject:SetActive(singleSelect)
end
ManualCollectCtrl._ClearLastSingleSelect = HL.Method() << function(self)
    if self.m_singleSelectGridIndex > 0 then
        local gridCell = self.m_gridItemCellCache:Get(self.m_singleSelectGridIndex)
        if gridCell then
            gridCell.rewardItemBlack.view.selectedBG.gameObject:SetActive(false)
        end
    end
    self.m_singleSelectGridIndex = 0
    if self.m_singleSelectListIndex > 0 then
        local listCell = self.m_getItemCell(self.m_singleSelectListIndex)
        if listCell then
            listCell.rewardItemBlack.view.selectedBG.gameObject:SetActive(false)
        end
    end
    self.m_singleSelectListIndex = 0
end
ManualCollectCtrl._RefreshSingleItemSelected = HL.Method(HL.Table) << function(self, cell)
    if not self.m_onlyShow then
        local itemId = cell.rewardItemBlack.id
        local selected = not not self.m_selectedItems[itemId]
        cell.rewardItemBlack.view.toggle.gameObject:SetActive(selected)
    end
end
ManualCollectCtrl._OnItemClicked = HL.Method(HL.Number, HL.Table, HL.Table) << function(self, index, cell, itemBundle)
    local itemId = itemBundle.id
    local selected = self.m_selectedItems[itemId]
    if selected then
        self.m_selectedItems[itemId] = nil
        self.m_selectedNum = self.m_selectedNum - 1
    else
        self.m_selectedItems[itemId] = true
        self.m_selectedNum = self.m_selectedNum + 1
    end
    cell.rewardItemBlack.view.selectedBG.gameObject:SetActive(true)
    self:_ShowItemTips(itemId)
    self:_RefreshSingleItemSelected(cell)
    self:_RefreshDownNode()
end
ManualCollectCtrl._SelectAll = HL.Method() << function(self)
    self.m_selectedNum = #self.m_canSubmitItems
    for _, data in pairs(self.m_canSubmitItems) do
        local itemId = data.itemId
        self.m_selectedItems[itemId] = true
    end
    self:_RefreshAllItemSelected()
end
ManualCollectCtrl._ClearAll = HL.Method() << function(self)
    self.m_selectedNum = 0
    self.m_selectedItems = {}
    self:_RefreshAllItemSelected()
end
ManualCollectCtrl._RefreshAllItemSelected = HL.Method() << function(self)
    for i = 1, self.view.listNode.itemList.count do
        local cell = self.m_getItemCell(i)
        if cell then
            self:_RefreshSingleItemSelected(cell)
        end
    end
    self:_RefreshDownNode()
end
ManualCollectCtrl._ShowMoneyTips = HL.Method() << function(self)
    local itemId = "item_diamond"
    Notify(MessageConst.SHOW_ITEM_TIPS, {
        transform = self.view.downNode.tipsBtn.transform,
        itemId = itemId,
        posType = UIConst.UI_TIPS_POS_TYPE.LeftDown,
        onClose = function()
            self:_ClearLastSingleSelect()
        end
    })
end
ManualCollectCtrl._ShowItemTips = HL.Method(HL.String) << function(self, itemId)
    Notify(MessageConst.SHOW_ITEM_TIPS, {
        transform = self.view.itemTipsAttachNode.transform,
        itemId = itemId,
        posType = UIConst.UI_TIPS_POS_TYPE.LeftTop,
        onClose = function()
            self:_ClearLastSingleSelect()
        end
    })
end
ManualCollectCtrl._RefreshTitle = HL.Method() << function(self)
    self.view.submitTitle.gameObject:SetActive(not self.m_onlyShow)
    self.view.recycleTitle.gameObject:SetActive(self.m_onlyShow)
end
ManualCollectCtrl._RefreshList = HL.Method() << function(self)
    self:_UpdateItemData()
    local listNode = self.view.listNode
    local showListNode = self.view.showListNode
    self.view.listNode.gameObject:SetActive(not self.m_onlyShow)
    self.view.showListNode.gameObject:SetActive(self.m_onlyShow)
    if self.m_onlyShow then
        local canSubmitDynamic = self:_GetCanSubmitDynamic()
        local grid = self.view.showListNode.propGridContent
        local gridNode = grid.propGridNode
        local hasTitle = self.view.showListNode.hasCollectPropTitle
        local needTitle = self.view.showListNode.needCollectTitleContent
        gridNode.padding.top = self.view.config.GRID_PADDING_TOP
        LayoutRebuilder.ForceRebuildLayoutImmediate(hasTitle.transform)
        LayoutRebuilder.ForceRebuildLayoutImmediate(needTitle.transform)
        local needHeight = needTitle.transform.rect.height
        local hasHeight = hasTitle.transform.rect.height
        local gridHeight
        hasTitle.transform:SetParent(showListNode.container)
        needTitle.transform:SetParent(showListNode.container)
        grid.transform:SetParent(showListNode.container)
        needTitle.transform.localPosition = Vector3.zero
        if canSubmitDynamic then
            self.m_gridItemCellCache:Refresh(#self.m_hasSubmittedItems, function(cell, index)
                self:_OnUpdateHasCollectedItem(cell, index)
            end)
            LayoutRebuilder.ForceRebuildLayoutImmediate(grid.transform)
            LayoutRebuilder.ForceRebuildLayoutImmediate(grid.transform.parent)
            gridHeight = grid.transform.rect.height
            showListNode.itemList:UpdateCount(#self.m_canSubmitItems)
            LayoutRebuilder.ForceRebuildLayoutImmediate(showListNode.transform.parent)
            local bottomPadding = showListNode.itemList:GetPadding().bottom
            showListNode.itemList:TryRecalculateSize()
            local itemListHeight = showListNode.container.transform.rect.height - bottomPadding
            hasTitle.transform.localPosition = Vector3(0, -needHeight - itemListHeight, 0)
            grid.transform.localPosition = Vector3(0, -needHeight - itemListHeight - hasHeight, 0)
            showListNode.itemList:SetPaddingTop(needHeight + self.view.config.LIST_PADDING_TOP)
            showListNode.itemList:SetPaddingBottom(hasHeight + gridHeight)
        else
            self.m_gridItemCellCache:Refresh(#self.m_canSubmitItems, function(cell, index)
                self:_OnUpdateItemList(cell, index)
            end)
            LayoutRebuilder.ForceRebuildLayoutImmediate(grid.transform)
            gridHeight = grid.transform.rect.height
            showListNode.itemList:UpdateCount(#self.m_hasSubmittedItems)
            grid.transform.localPosition = Vector3(0, -needHeight, 0)
            hasTitle.transform.localPosition = Vector3(0, -needHeight - gridHeight, 0)
            showListNode.itemList:SetPaddingTop(hasHeight + needHeight + gridHeight + self.view.config.LIST_PADDING_TOP)
            showListNode.itemList:SetPaddingBottom(0)
        end
    else
        local propTitleContent = listNode.propTitleContent
        LayoutRebuilder.ForceRebuildLayoutImmediate(propTitleContent.transform)
        local titleHeight = propTitleContent.rectTransform.rect.height
        propTitleContent.transform:SetParent(listNode.container)
        propTitleContent.transform.localPosition = Vector3.zero
        listNode.itemList:SetPaddingTop(titleHeight)
        listNode.itemList:UpdateCount(#self.m_canSubmitItems)
    end
    self:_RefreshDownNode()
end
ManualCollectCtrl._GetMoneyNum = HL.Method().Return(HL.Number) << function(self)
    local itemSubmitRecycleReward = Tables.globalConst.itemSubmitRecycleReward
    local itemBundle = UIUtils.getRewardFirstItem(itemSubmitRecycleReward)
    local count = itemBundle.count
    return count * self.m_selectedNum
end
ManualCollectCtrl._RefreshDownNode = HL.Method() << function(self)
    local downNode = self.view.downNode
    downNode.gameObject:SetActive(not self.m_onlyShow)
    if not self.m_onlyShow then
        downNode.confirmBtn.gameObject:SetActive(self.m_selectedNum > 0)
        downNode.textName.gameObject:SetActive(self.m_selectedNum <= 0)
        downNode.textNum.text = string.format("%d", self:_GetMoneyNum())
        self.view.listNode.propTitleContent.textNumber.text = string.format("%d/%d", self.m_selectedNum, #self.m_canSubmitItems)
    end
end
ManualCollectCtrl._DoNext = HL.Method(HL.Number) << function(self, nextIndex)
    self:PlayAnimationOutWithCallback(function()
        self:Notify(MessageConst.DIALOG_CLOSE_UI, { PANEL_ID, PHASE_ID, nextIndex })
    end)
end
ManualCollectCtrl.OnSubmitRecycleItem = HL.Method(HL.Table) << function(self, arg)
    local res = unpack(arg)
    local nextIndex = res and 0 or 1
    self:_DoNext(nextIndex)
end
HL.Commit(ManualCollectCtrl)