local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
RepositoryContent = HL.Class('RepositoryContent', UIWidgetBase)
RepositoryContent.m_acceptDrop = HL.Field(HL.Boolean) << false
RepositoryContent.m_disableAutoHighlightForDrop = HL.Field(HL.Boolean) << false
RepositoryContent.m_showAllSlot = HL.Field(HL.Boolean) << false
RepositoryContent.m_showEmptyChoice = HL.Field(HL.Boolean) << false
RepositoryContent.m_isIncremental = HL.Field(HL.Boolean) << false
RepositoryContent.m_repository = HL.Field(CS.Beyond.Gameplay.RemoteFactory.FBUtil.Cache)
RepositoryContent.m_insertCustomListData = HL.Field(HL.Function)
RepositoryContent.m_allItemInfoList = HL.Field(HL.Table)
RepositoryContent.m_itemInfoList = HL.Field(HL.Table)
RepositoryContent.m_itemInfoCount = HL.Field(HL.Number) << 0
RepositoryContent.m_typeLimitCount = HL.Field(HL.Number) << -1
RepositoryContent.m_index = HL.Field(HL.Number) << -1
RepositoryContent.m_curDropHighlightId = HL.Field(HL.String) << ''
RepositoryContent.m_dropHelper = HL.Field(HL.Forward('UIDropHelper'))
RepositoryContent.m_customOnUpdateCell = HL.Field(HL.Function)
RepositoryContent.m_onClickItemAction = HL.Field(HL.Function)
RepositoryContent.m_getCell = HL.Field(HL.Function)
RepositoryContent.m_registeredChangeCallback = HL.Field(HL.Function)
RepositoryContent.m_showingTypes = HL.Field(HL.Table)
RepositoryContent.m_sortKeys = HL.Field(HL.Table)
RepositoryContent._OnFirstTimeInit = HL.Override() << function(self)
    self.m_getCell = UIUtils.genCachedCellFunction(self.view.itemList, function(object)
        return UIWidgetManager:Wrap(object)
    end)
    self.view.itemList.onUpdateCell:AddListener(function(object, csIndex)
        self:_OnUpdateCell(object, LuaIndex(csIndex))
    end)
    self.view.dropMask.gameObject:SetActive(false)
    self.view.dragMask.gameObject:SetActive(false)
    self.m_dropHelper = UIUtils.initUIDropHelper(self.view.dropMask, {
        acceptTypes = UIConst.FACTORY_REPO_DROP_ACCEPT_INFO,
        onDropItem = function(_, dragHelper)
            self:OnDropItem(dragHelper)
        end,
        isDropArea = true,
        quickDropCheckGameObject = self.gameObject,
        dropPriority = 1,
    })
    self:RegisterMessage(MessageConst.ON_START_UI_DRAG, function(dragHelper)
        self:OnStartUiDrag(dragHelper)
    end)
    self:RegisterMessage(MessageConst.ON_END_UI_DRAG, function(dragHelper)
        if self.m_dropHelper:Accept(dragHelper) and dragHelper.info.repository ~= self.m_repository then
            self.view.dropMask.gameObject:SetActive(false)
            self:_CancelDropHighlight()
        end
        self.view.dragMask.gameObject:SetActive(false)
    end)
    self.m_registeredChangeCallback = function(changedItems, hasNewOrRemove)
        self:_OnRepositoryChanged(changedItems, hasNewOrRemove)
    end
end
RepositoryContent.InitRepositoryContent = HL.Method(CS.Beyond.Gameplay.RemoteFactory.FBUtil.Cache, HL.Opt(HL.Function, HL.Table)) << function(self, repository, onClickItemAction, otherArgs)
    self:_FirstTimeInit()
    self:_ClearRegister()
    self.m_repository = repository
    repository.onCacheChanged:AddListener(self.m_registeredChangeCallback)
    self.m_onClickItemAction = onClickItemAction
    otherArgs = otherArgs or {}
    self.m_showingTypes = otherArgs.showingTypes
    self.m_showAllSlot = otherArgs.showAllSlot == true
    self.m_customOnUpdateCell = otherArgs.customOnUpdateCell
    self.m_insertCustomListData = otherArgs.insertCustomListData
    self.m_disableAutoHighlightForDrop = otherArgs.disableAutoHighlightForDrop == true
    self.m_showEmptyChoice = otherArgs.showEmptyChoice == true
    self.m_index = otherArgs.index
    self.m_acceptDrop = true
    if otherArgs.typeLimitCount then
        self.m_typeLimitCount = otherArgs.typeLimitCount
    end
    self.m_isIncremental = true
    self.m_sortKeys = { "rarity", "sortId1", "sortId2" }
    self:RefreshAll()
end
RepositoryContent._CreateItemInfo = HL.Method(HL.String, HL.Number).Return(HL.Table) << function(self, id, count)
    local data = Tables.itemTable:GetValue(id)
    local facItemData = Tables.factoryItemTable:GetValue(id)
    local info = { id = id, count = count, maxStackCount = data.maxBackpackStackCount, data = data, showingType = data.showingType, facItemData = facItemData, }
    return info
end
RepositoryContent.ToggleAcceptDrop = HL.Method(HL.Boolean) << function(self, active)
    self.m_acceptDrop = active
end
RepositoryContent.OnStartUiDrag = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if self:_ShouldAcceptDrop(dragHelper) then
        self.view.quickDropButton.onClick:RemoveAllListeners()
        self.view.quickDropButton.onClick:AddListener(function()
            self:OnDropItem(dragHelper)
        end)
        self.view.dropMask.gameObject:SetActive(true)
        self.view.dropMask:ToggleHighlight(false)
        self:_FindAndHighlightForDrop(dragHelper)
    end
end
RepositoryContent._ShouldAcceptDrop = HL.Method(HL.Forward('UIDragHelper')).Return(HL.Boolean) << function(self, dragHelper)
    if not self.m_acceptDrop then
        return false
    end
    if not self.m_dropHelper:Accept(dragHelper) then
        return false
    end
    if dragHelper.repository == self.m_repository then
        return false
    end
    local succ, data = Tables.factoryItemTable:TryGetValue(dragHelper.info.itemId)
    if not succ or data.buildingBufferStackLimit <= 0 then
        return false
    end
    return true
end
RepositoryContent.RefreshAll = HL.Method() << function(self)
    if not self.m_repository then
        return
    end
    local allItemInfoList = {}
    for id, count in pairs(self.m_repository.items) do
        local info = self:_CreateItemInfo(id, count)
        table.insert(allItemInfoList, info)
    end
    if self.m_insertCustomListData then
        self.m_insertCustomListData(allItemInfoList, self.m_repository)
    end
    self.m_allItemInfoList = allItemInfoList
    self:ChangeShowingType(self.m_showingTypes)
end
RepositoryContent.ChangeShowingType = HL.Method(HL.Table) << function(self, showingTypes)
    local itemInfoList = {}
    self.m_showingTypes = showingTypes
    for _, info in ipairs(self.m_allItemInfoList) do
        if not showingTypes or lume.find(showingTypes, info.showingType) then
            table.insert(itemInfoList, info)
        end
    end
    self.m_itemInfoList = itemInfoList
    self:OnSortChanged()
end
RepositoryContent.OnSortChanged = HL.Method() << function(self)
    local list = self.m_itemInfoList
    table.sort(list, Utils.genSortFunction(self.m_sortKeys, self.m_isIncremental))
    if self.m_showEmptyChoice then
        table.insert(list, 1, { id = "", count = 0, extraOrder = 1, })
    end
    if self.m_showAllSlot then
        local curCount = #list
        local limit = self.m_typeLimitCount
        if limit < 0 then
            local countPerPage = self.view.itemList.maxShowingCellCount
            limit = (math.floor(curCount / countPerPage) + 1) * countPerPage
            if self.m_showEmptyChoice then
                limit = limit - 1
            end
        end
        if limit > curCount then
            for _ = 1, limit - curCount do
                table.insert(list, { id = "", count = 0, })
            end
        end
    end
    self.m_itemInfoCount = #list
    if string.isEmpty(self.m_curDropHighlightId) then
        self.view.itemList:UpdateCount(self.m_itemInfoCount)
    else
        local index
        for k, v in ipairs(self.m_itemInfoList) do
            if v.id == self.m_curDropHighlightId then
                index = k
                break
            end
        end
        if index then
            self.view.itemList:UpdateCount(self.m_itemInfoCount)
        else
            self.view.itemList:UpdateCount(self.m_itemInfoCount + 1)
        end
    end
end
RepositoryContent._OnUpdateCell = HL.Method(GameObject, HL.Number) << function(self, object, luaIndex)
    local cell = self.m_getCell(object)
    if luaIndex > self.m_itemInfoCount then
        cell:InitItemSlot()
        cell.item:SetSelected(true)
        return
    end
    local info = self.m_itemInfoList[luaIndex]
    cell:InitItemSlot(info, function()
        self:_OnClickItem(luaIndex)
    end)
    cell.item.canClear = true
    local isDropHighlight = (not string.isEmpty(self.m_curDropHighlightId)) and (self.m_curDropHighlightId == info.id)
    local isDragging = cell.view.dragItem.inDragging
    cell.item:SetSelected(cell.item.showingTips or isDragging or isDropHighlight)
    if string.isEmpty(info.id) then
        cell.gameObject.name = "Item__" .. CSIndex(luaIndex)
    else
        cell.gameObject.name = "Item_" .. info.id
        cell.item.view.button.clickHintTextId = "virtual_mouse_hint_item_tips"
    end
    cell.view.dropItem.enabled = false
    if info.count > 0 then
        local data = Tables.itemTable:GetValue(info.id)
        local dragCount = math.min(info.count or 0, info.maxStackCount or 0)
        local dragHelper = UIUtils.initUIDragHelper(cell.view.dragItem, {
            source = UIConst.UI_DRAG_DROP_SOURCE_TYPE.Repository,
            type = data.type,
            repository = self.m_repository,
            itemId = info.id,
            count = dragCount,
            onBeginDrag = function()
                self.view.dragMask.gameObject:SetActive(true)
            end,
            onEndDrag = function()
                self.view.dragMask.gameObject:SetActive(false)
            end,
        })
        cell:InitPressDrag()
        cell.view.dragItem.onUpdateDragObject:AddListener(function(dragObj)
            local dragItem = UIWidgetManager:Wrap(dragObj)
            dragItem:InitItem({ id = info.id, count = dragCount })
        end)
    end
    if self.m_customOnUpdateCell then
        self.m_customOnUpdateCell(cell, info, luaIndex)
    end
end
RepositoryContent._OnClickItem = HL.Method(HL.Number) << function(self, luaIndex)
    local item = self.m_itemInfoList[luaIndex]
    local cell = self.m_getCell(luaIndex)
    if self.m_onClickItemAction then
        self.m_onClickItemAction(item.id)
    elseif not string.isEmpty(item.id) then
        cell.item:ShowTips()
    end
end
RepositoryContent.OnDropItem = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    local source = dragHelper.source
    local dragInfo = dragHelper.info
    local core = GameInstance.player.remoteFactory.core
    local componentId = self.m_repository.componentId
    if source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.Storage then
        logger.error("未实现: 从工厂 Storage Drop 过来")
        return
    elseif source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.Repository then
        if dragInfo.itemId then
            core:Message_OpMoveItemCacheToCache(Utils.getCurrentChapterId(), dragInfo.repository.componentId, dragInfo.itemId, componentId)
        else
            logger.error("未实现: 从工厂 Repo Drop 过来, 尝试转移整个Repo")
            return
        end
    elseif source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.FactoryDepot then
        core:Message_OpMoveItemDepotToCache(Utils.getCurrentChapterId(), dragInfo.itemId, componentId)
    elseif source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.ItemBag then
        core:Message_OpMoveItemBagToCache(Utils.getCurrentChapterId(), dragInfo.csIndex, componentId)
    end
    if dragInfo.itemId then
        local cptHandler = FactoryUtils.getBuildingComponentHandler(componentId)
        local buildingNode = cptHandler.belongNode
        local worldPos = GameInstance.remoteFactoryManager.visual:BuildingGridToWorld(Vector2(buildingNode.transform.position.x, buildingNode.transform.position.z))
        EventLogManagerInst:GameEvent_FactoryItemPush(buildingNode.nodeId, buildingNode.templateId, GameInstance.remoteFactoryManager.currentSceneName, worldPos, dragInfo.itemId, dragInfo.count, self.m_repository.items)
    end
end
RepositoryContent._OnRepositoryChanged = HL.Method(HL.Userdata, HL.Boolean) << function(self, changedItems, hasNewOrRemove)
    if hasNewOrRemove then
        self:RefreshAll()
        for _, id in pairs(changedItems) do
            local count = self.m_repository:GetCount(id)
            CS.Beyond.Gameplay.Conditions.OnFacCurMachineCacheAddItem.Trigger(id, count)
        end
    else
        for _, id in pairs(changedItems) do
            local count = self.m_repository:GetCount(id)
            self:_RefreshSingleItem(id, count)
            CS.Beyond.Gameplay.Conditions.OnFacCurMachineCacheAddItem.Trigger(id, count)
        end
    end
end
RepositoryContent._RefreshSingleItem = HL.Method(HL.String, HL.Number) << function(self, itemId, count)
    local slotIndex
    for index, v in ipairs(self.m_itemInfoList) do
        if v.id == itemId then
            slotIndex = index
            if count then
                v.count = count
            end
        end
    end
    if slotIndex then
        local obj = self.view.itemList:Get(CSIndex(slotIndex))
        if obj then
            self:_OnUpdateCell(obj, slotIndex)
        end
    end
end
RepositoryContent._FindAndHighlightForDrop = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if self.m_disableAutoHighlightForDrop then
        return
    end
    local id = dragHelper:GetId()
    self.m_curDropHighlightId = id
    local index
    for k, v in ipairs(self.m_itemInfoList) do
        if v.id == id then
            index = k
            break
        end
    end
    if index then
        local object = self.view.itemList:Get(CSIndex(index))
        if object then
            local cell = self.m_getCell(object)
            cell.item:SetSelected(true)
        end
    else
        index = self.m_itemInfoCount + 1
        self.view.itemList:UpdateCount(index, false, false, true)
    end
    self.view.itemList:ScrollToIndex(CSIndex(index))
end
RepositoryContent._CancelDropHighlight = HL.Method() << function(self)
    if self.m_disableAutoHighlightForDrop then
        return
    end
    local id = self.m_curDropHighlightId
    self.m_curDropHighlightId = nil
    local index
    for k, v in ipairs(self.m_itemInfoList) do
        if v.id == id then
            index = k
            break
        end
    end
    if index then
        local object = self.view.itemList:Get(CSIndex(index))
        if object then
            local cell = self.m_getCell(object)
            cell.item:SetSelected(false)
        end
    else
        self.view.itemList:UpdateCount(self.m_itemInfoCount, false, false, true)
    end
end
RepositoryContent._ClearRegister = HL.Method() << function(self)
    if self.m_repository then
        self.m_repository.onCacheChanged:RemoveListener(self.m_registeredChangeCallback)
    end
end
RepositoryContent._OnDestroy = HL.Override() << function(self)
    self:_ClearRegister()
end
HL.Commit(RepositoryContent)
return RepositoryContent