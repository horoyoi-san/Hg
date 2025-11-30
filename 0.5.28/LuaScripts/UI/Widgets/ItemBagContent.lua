local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
ItemBagContent = HL.Class('ItemBagContent', UIWidgetBase)
ItemBagContent.canDrop = HL.Field(HL.Boolean) << true
ItemBagContent.canQuickDrop = HL.Field(HL.Boolean) << true
ItemBagContent.canPlace = HL.Field(HL.Boolean) << false
ItemBagContent.canSplit = HL.Field(HL.Boolean) << false
ItemBagContent.canClear = HL.Field(HL.Boolean) << false
ItemBagContent.m_updateStopped = HL.Field(HL.Boolean) << false
ItemBagContent.goldItemNum = HL.Field(HL.Number) << -1
ItemBagContent.m_itemBundleList = HL.Field(HL.Any)
ItemBagContent.m_getCell = HL.Field(HL.Function)
ItemBagContent.m_customOnUpdateCell = HL.Field(HL.Function)
ItemBagContent.m_itemCellExtraInfo = HL.Field(HL.Table)
ItemBagContent.m_onClickItemAction = HL.Field(HL.Function)
ItemBagContent._OnFirstTimeInit = HL.Override() << function(self)
    self.m_getCell = UIUtils.genCachedCellFunction(self.view.itemList)
    self.view.itemList.onUpdateCell:AddListener(function(object, csIndex)
        self:_OnUpdateCell(object, csIndex)
    end)
    self.view.dropHint.gameObject:SetActive(false)
    self.view.dropMask.gameObject:SetActive(false)
    self:RegisterMessage(MessageConst.ON_START_UI_DRAG, function(dragHelper)
        self:OnStartUiDrag(dragHelper)
    end)
    self:RegisterMessage(MessageConst.ON_END_UI_DRAG, function(dragHelper)
        self:OnEndUiDrag(dragHelper)
    end)
    self:RegisterMessage(MessageConst.ON_ITEM_BAG_CHANGED, function(args)
        local changedIndexes = unpack(args)
        self:_OnItemBagChanged(changedIndexes, false)
    end)
    self:RegisterMessage(MessageConst.ON_ITEM_BAG_LIMIT_CHANGED, function()
        self:_OnItemBagChanged(nil, true)
    end)
    self:RegisterMessage(MessageConst.ON_SYNC_INVENTORY, function()
        self:_OnItemBagChanged(nil, true)
    end)
    self:RegisterMessage(MessageConst.ON_PUT_ON_RPG_DUNGEON_EQUIP_SUCC, function()
        self:_OnItemBagChanged(nil, true, true)
    end)
    self:RegisterMessage(MessageConst.ON_PUT_OFF_RPG_DUNGEON_EQUIP_SUCC, function()
        self:_OnItemBagChanged(nil, true, true)
    end)
    UIUtils.initUIDropHelper(self.view.dropMask, {
        acceptTypes = UIConst.ITEM_BAG_DROP_MASK_ACCEPT_INFO,
        onDropItem = function(eventData, dragHelper)
            self:_OnDropItem(-1, dragHelper)
        end,
        isDropArea = true,
        quickDropCheckGameObject = self.gameObject,
    })
end
ItemBagContent.OnStartUiDrag = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if self.m_updateStopped then
        return
    end
    if self.view.itemListAutoScrollArea then
    end
    if dragHelper.source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.ItemBag then
        return
    end
    if not self.canDrop or not self.canQuickDrop then
        return
    end
    if UIUtils.isTypeDropValid(dragHelper, UIConst.ITEM_BAG_DROP_ACCEPT_INFO) then
        self.view.quickDropButton.onClick:RemoveAllListeners()
        self.view.quickDropButton.onClick:AddListener(function()
            self:_OnDropItem(-1, dragHelper)
        end)
        self.view.dropHint.gameObject:SetActive(true)
        self.view.dropMask.gameObject:SetActive(true)
    end
end
ItemBagContent.OnEndUiDrag = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if self.m_updateStopped then
        return
    end
    if self.view.itemListAutoScrollArea then
    end
    if dragHelper.source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.ItemBag then
        return
    end
    if not self.canQuickDrop then
        return
    end
    if UIUtils.isTypeDropValid(dragHelper, UIConst.ITEM_BAG_DROP_ACCEPT_INFO) then
        self.view.dropHint.gameObject:SetActive(false)
        self.view.dropMask.gameObject:SetActive(false)
    end
end
ItemBagContent.InitItemBagContent = HL.Method(HL.Opt(HL.Function, HL.Table)) << function(self, onClickItemAction, otherArgs)
    self:_FirstTimeInit()
    self.m_readItemIds = {}
    self.m_onClickItemAction = onClickItemAction
    otherArgs = otherArgs or {}
    self.canPlace = otherArgs.canPlace == true
    self.canSplit = otherArgs.canSplit == true
    self.canClear = otherArgs.canClear == true
    self.m_itemCellExtraInfo = otherArgs.itemCellExtraInfo
    self.m_customOnUpdateCell = otherArgs.customOnUpdateCell
    self.m_updateStopped = false
    self:Refresh()
end
ItemBagContent.StopUpdate = HL.Method(HL.Boolean) << function(self, cacheAllCell)
    self.m_updateStopped = true
    if cacheAllCell then
        self.view.itemList:UpdateCount(0)
    end
end
ItemBagContent.StartUpdate = HL.Method() << function(self)
    if not self.m_updateStopped then
        return
    end
    self.m_updateStopped = false
    self:Refresh()
end
ItemBagContent.RefreshChangeGold = HL.Method(HL.Table) << function(self, Args)
    self.m_itemBundleList = Args.itemBundleList
    self.goldItemNum = Args.goldItemNum
    self:Refresh()
end
ItemBagContent.Refresh = HL.Method(HL.Opt(HL.Boolean)) << function(self, skipGraduallyShow)
    self.view.itemList:UpdateCount(GameInstance.player.inventory.itemBag:GetOrFallback(Utils.getCurrentScope()).maxSlotCount, false, false, false, skipGraduallyShow == true)
end
ItemBagContent._OnUpdateCell = HL.Method(GameObject, HL.Number) << function(self, object, csIndex)
    local cell = self.m_getCell(object)
    local itemBag = GameInstance.player.inventory.itemBag:GetOrFallback(Utils.getCurrentScope())
    local slotLimit = itemBag.slots.Count
    local item = csIndex < slotLimit and itemBag.slots[csIndex] or nil
    if item then
        self:_UpdateNormalSlot(cell, item, csIndex)
    else
        self:_UpdateLockSlot(cell, csIndex)
    end
    cell.item:ShowPickUpLogo(true)
end
ItemBagContent._UpdateNormalSlot = HL.Method(HL.Userdata, HL.Userdata, HL.Number) << function(self, cell, item, csIndex)
    cell:InitItemSlot(item, function()
        self:_OnClickItem(csIndex)
    end)
    cell.item.canPlace = self.canPlace
    cell.item.canSplit = self.canSplit
    cell.item.canClear = self.canClear
    cell.item.slotIndex = csIndex
    local id = item.id
    local isEmpty = string.isEmpty(id)
    if isEmpty then
        cell.gameObject.name = "Item__" .. csIndex
    else
        cell.gameObject.name = "Item_" .. id
        cell.item.view.button.clickHintTextId = "virtual_mouse_hint_item_tips"
    end
    cell.item:UpdateRedDot()
    if cell.item.redDot.curIsActive then
        self.m_readItemIds[id] = true
    end
    if self.m_itemCellExtraInfo then
        cell.item:SetExtraInfo(self.m_itemCellExtraInfo)
    end
    if not isEmpty then
        local data = Tables.itemTable:GetValue(id)
        local count = item.count
        if count >= data.maxBackpackStackCount then
            cell.item.view.count.color = self.view.config.ITEM_SLOT_FULL_COLOR
            cell.item.view.count.fontSharedMaterial = self.view.config.ITEM_SLOT_FULL_MAT
        else
            cell.item.view.count.color = Color.white
            cell.item.view.count.fontSharedMaterial = self.view.config.ITEM_SLOT_NORMAL_MAT
        end
        local canAbandon = GameInstance.player.inventory:CanDestroyItem(Utils.getCurrentScope(), id)
        local dragHelper = UIUtils.initUIDragHelper(cell.view.dragItem, {
            source = UIConst.UI_DRAG_DROP_SOURCE_TYPE.ItemBag,
            type = data.type,
            csIndex = csIndex,
            itemId = id,
            count = count,
            instId = item.instId,
            onBeginDrag = function()
                self.view.itemList:SetCellCanCache(csIndex, false)
                cell.item:Read()
            end,
            onEndDrag = function()
                self.view.itemList:SetCellCanCache(csIndex, true)
            end,
            onDropTargetChanged = function(enterObj, dropHelper)
                local dragObj = cell.view.dragItem.curDragObj
                local dragItem = dragObj:GetComponent("LuaUIWidget").table[1]
                if not dropHelper or not dropHelper.info.isAbandon then
                    dragItem.view.abandonNode.gameObject:SetActive(false)
                    return
                end
                dragItem.view.abandonNode.gameObject:SetActive(true)
                dragItem.view.canAbandonNode.gameObject:SetActive(canAbandon)
                dragItem.view.cantAbandonNode.gameObject:SetActive(not canAbandon)
            end,
        })
        cell:InitPressDrag()
        if count > 0 then
            cell.item.actionMenuArgs = { source = UIConst.UI_DRAG_DROP_SOURCE_TYPE.ItemBag, machineCacheArea = self:GetUICtrl().view.cacheArea, }
        end
    end
    if not isEmpty and Utils.isInRpgDungeon() then
        cell.view.equippedNode.gameObject:SetActive(GameInstance.player.rpgDungeonSystem:IsEquipped(item.instId))
    else
        cell.view.equippedNode.gameObject:SetActive(false)
    end
    UIUtils.initUIDropHelper(cell.view.dropItem, {
        acceptTypes = UIConst.ITEM_BAG_DROP_ACCEPT_INFO,
        onDropItem = function(eventData, dragHelper)
            self:_OnDropItem(csIndex, dragHelper)
        end,
    })
    if self.m_customOnUpdateCell then
        self.m_customOnUpdateCell(cell, item, csIndex)
    end
end
ItemBagContent._UpdateLockSlot = HL.Method(HL.Userdata, HL.Number) << function(self, cell, csIndex)
    cell.gameObject.name = "Item__" .. csIndex
    cell:InitLockSlot()
    UIUtils.initUIDropHelper(cell.view.dropItem, {
        acceptTypes = UIConst.ITEM_BAG_DROP_ACCEPT_INFO,
        onDropItem = function(eventData, dragHelper)
            Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_BAG_SLOT_LOCKED)
        end,
    })
    if self.m_customOnUpdateCell then
        self.m_customOnUpdateCell(cell, nil, csIndex)
    end
end
ItemBagContent._OnDropItem = HL.Method(HL.Number, HL.Forward('UIDragHelper')) << function(self, csIndex, dragHelper)
    local inventory = GameInstance.player.inventory
    local source = dragHelper.source
    local dragInfo = dragHelper.info
    local core = GameInstance.player.remoteFactory.core
    if csIndex < 0 then
        csIndex = inventory.itemBag:GetOrFallback(Utils.getCurrentScope()):GetFirstValidSlotIndex(dragInfo.itemId)
    end
    if csIndex < 0 then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_BAG_NO_EMPTY_SLOT)
        return
    end
    if source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.Storage then
        core:Message_OpMoveItemGridBoxToBag(Utils.getCurrentChapterId(), dragInfo.storage.componentId, dragInfo.csIndex, csIndex)
    elseif source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.Repository then
        local itemBundle = GameInstance.player.inventory.itemBag:GetOrFallback(Utils.getCurrentScope()).slots[csIndex]
        if not dragInfo.isIn then
            if itemBundle ~= nil and not string.isEmpty(itemBundle.id) and itemBundle.id ~= dragInfo.itemId then
                return
            end
        else
            if itemBundle ~= nil and not dragInfo.canFacCacheDrop(itemBundle.id) then
                Notify(MessageConst.SHOW_TOAST, Language["ui_fac_common_bag_drop_same_item"])
                return
            end
        end
        core:Message_OpMoveItemCacheToBag(Utils.getCurrentChapterId(), dragInfo.repository.componentId, csIndex, dragInfo.cacheGridIndex)
    elseif source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.FactoryDepot then
        if Utils.isDepotManualInOutLocked() then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_DEPOT_MANUAL_IN_OUT_LOCKED)
            return
        end
        local itemBundle = GameInstance.player.inventory.itemBag:GetOrFallback(Utils.getCurrentScope()).slots[csIndex]
        if string.isEmpty(itemBundle.id) or itemBundle.id == dragInfo.itemId then
            inventory:FactoryDepotMoveToItemBag(Utils.getCurrentScope(), Utils.getCurrentChapterId(), dragInfo.itemId, dragInfo.count, csIndex)
        end
    elseif source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.ItemBag then
        inventory:MoveInItemBag(Utils.getCurrentScope(), dragInfo.csIndex, csIndex)
    end
end
ItemBagContent._OnClickItem = HL.Method(HL.Number) << function(self, csIndex)
    local item = GameInstance.player.inventory.itemBag:GetOrFallback(Utils.getCurrentScope()).slots[csIndex]
    local cell = self.m_getCell(LuaIndex(csIndex))
    if self.m_onClickItemAction then
        self.m_onClickItemAction(item.id, cell, csIndex)
    elseif not string.isEmpty(item.id) then
        cell.item:ShowTips()
        cell.item:Read()
    end
end
ItemBagContent._OnItemBagChanged = HL.Method(HL.Opt(HL.Userdata, HL.Boolean, HL.Boolean)) << function(self, changedIndexes, refreshAll, skipGraduallyShow)
    if self.m_updateStopped then
        return
    end
    if refreshAll then
        self:Refresh(skipGraduallyShow)
        return
    end
    for _, slotIndex in pairs(changedIndexes) do
        local obj = self.view.itemList:Get(slotIndex)
        if obj then
            self:_OnUpdateCell(obj, slotIndex)
        end
    end
end
ItemBagContent.GetCell = HL.Method(HL.Any).Return(HL.Opt(HL.Forward("ItemSlot"))) << function(self, objOrIndex)
    return self.m_getCell(objOrIndex)
end
ItemBagContent.m_readItemIds = HL.Field(HL.Table)
ItemBagContent.ReadCurShowingItems = HL.Method() << function(self)
    if not self.m_readItemIds or not next(self.m_readItemIds) then
        return
    end
    local ids = {}
    for k, _ in pairs(self.m_readItemIds) do
        table.insert(ids, k)
    end
    self.m_readItemIds = {}
    GameInstance.player.inventory:ReadNewItems(ids)
end
ItemBagContent.ToggleCanDrop = HL.Method(HL.Boolean) << function(self, active)
    self.canDrop = active
end
ItemBagContent.ToggleCanQuickDrop = HL.Method(HL.Boolean) << function(self, active)
    self.canQuickDrop = active
end
HL.Commit(ItemBagContent)
return ItemBagContent