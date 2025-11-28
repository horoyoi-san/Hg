local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
FacCacheSlot = HL.Class('FacCacheSlot', UIWidgetBase)
local FILLED_SLOT_BOTTLE_DROP_HINT_TEXT_ID = "ui_fac_pipe_common_fill"
local EMPTY_SLOT_BOTTLE_DROP_HINT_TEXT_ID = "ui_fac_pipe_common_dump"
FacCacheSlot.m_slotIndex = HL.Field(HL.Number) << -1
FacCacheSlot.m_isFluid = HL.Field(HL.Boolean) << false
FacCacheSlot.m_itemInfo = HL.Field(HL.Table)
FacCacheSlot.m_isBlocked = HL.Field(HL.Boolean) << false
FacCacheSlot.m_cache = HL.Field(CS.Beyond.Gameplay.RemoteFactory.FBUtil.Cache)
FacCacheSlot.m_isInCache = HL.Field(HL.Boolean) << false
FacCacheSlot.m_onDropCallback = HL.Field(HL.Function)
FacCacheSlot.m_isDropEnabled = HL.Field(HL.Boolean) << true
FacCacheSlot.m_producerInfo = HL.Field(HL.Userdata)
FacCacheSlot._OnFirstTimeInit = HL.Override() << function(self)
    self:_InitSlotDrag()
    self.view.liquidItemSlot.view.facLiquidBg:InitFacLiquidBg()
end
FacCacheSlot.InitFacCacheSlot = HL.Method(HL.Table) << function(self, slotData)
    self:_FirstTimeInit()
    if slotData == nil then
        return
    end
    self.m_slotIndex = slotData.slotIndex
    self.m_isFluid = slotData.isFluid
    self.m_itemInfo = slotData.itemInfo
    self.m_cache = slotData.cache
    self.m_isInCache = slotData.isInCache
    self.m_onDropCallback = slotData.onDropCallback or function()
    end
    self.m_lockFormulaId = slotData.lockFormulaId or ""
    self.m_producerInfo = slotData.producerInfo
    self:_InitItemSlot()
    self:_UpdateContent()
end
FacCacheSlot._OnClickItemSlot = HL.Method(HL.Forward('ItemSlot'), HL.Table) << function(self, itemSlot, info)
    if DeviceInfo.usingController then
        itemSlot.item:ShowActionMenu()
        return
    end
    itemSlot.item:SetSelected(true)
    itemSlot.item:ShowTips(nil, function()
        itemSlot.item:SetSelected(false)
    end)
end
FacCacheSlot._InitItemSlot = HL.Method() << function(self)
    self.view.itemSlot.gameObject:SetActiveIfNecessary(not self.m_isFluid)
    self.view.liquidItemSlot.gameObject:SetActiveIfNecessary(self.m_isFluid)
end
FacCacheSlot._GetCurrentItemSlot = HL.Method().Return(HL.Userdata) << function(self)
    return self.m_isFluid and self.view.liquidItemSlot or self.view.itemSlot
end
FacCacheSlot._UpdateContent = HL.Method() << function(self)
    local info = self.m_itemInfo
    local isEmpty = not info or string.isEmpty(info.id)
    local itemSlot = self:_GetCurrentItemSlot()
    local dragEnabled = not isEmpty and info.count ~= nil and info.count > 0
    if isEmpty then
        itemSlot:InitItemSlot()
        itemSlot.gameObject.name = "Item__" .. CSIndex(self.m_slotIndex)
    else
        if not dragEnabled then
            itemSlot.view.dragItem.enabled = false
        end
        itemSlot:InitItemSlot(info, function()
            self:_OnClickItemSlot(itemSlot, info)
        end)
        itemSlot.gameObject.name = "Item_" .. info.id
        itemSlot.item.view.button.clickHintTextId = "virtual_mouse_hint_item_tips"
    end
    if Tables.liquidTable:ContainsKey(info.id) then
        dragEnabled = false
    end
    itemSlot.view.dragItem.enabled = dragEnabled
    if self.m_isFluid then
        self:_RefreshLiquidBg()
    else
        itemSlot.view.dropHintEmptyText.gameObject:SetActiveIfNecessary(isEmpty or info.count <= 0)
        itemSlot.view.dropHintFilledText.gameObject:SetActiveIfNecessary(not isEmpty and info.count > 0)
    end
    self.m_dropHelper = UIUtils.initUIDropHelper(itemSlot.view.dropItem, {
        acceptTypes = UIConst.FACTORY_REPO_DROP_ACCEPT_INFO,
        onDropItem = function(eventData, dragHelper)
            if self:_ShouldAcceptDrop(dragHelper) then
                self:_OnDropItem(dragHelper)
            end
        end,
    })
    itemSlot.item.view.button.onIsNaviTargetChanged = function(active)
        if active then
            self:_TryDisableHoverBindingOnEmptyItem()
        end
    end
    self:_TryDisableHoverBindingOnEmptyItem()
    if isEmpty then
        return
    end
    if info.count > 0 then
        local data = Tables.itemTable:GetValue(info.id)
        local dragCount = math.min(info.count or 0, info.maxStackCount or 0)
        self.m_dragHelper = UIUtils.initUIDragHelper(itemSlot.view.dragItem, {
            source = UIConst.UI_DRAG_DROP_SOURCE_TYPE.Repository,
            type = data.type,
            repository = self.m_cache,
            isIn = self.m_isInCache,
            itemId = info.id,
            count = dragCount,
            cacheGridIndex = CSIndex(self.m_slotIndex),
            canFacCacheDrop = function(id)
                return self:_CheckIsValidProducerDropBagItem(id)
            end
        })
        itemSlot:InitPressDrag()
        itemSlot.view.dragItem.onUpdateDragObject:AddListener(function(dragObj)
            local dragItem = UIWidgetManager:Wrap(dragObj)
            dragItem:InitItem({ id = info.id, count = dragCount })
        end)
        itemSlot.item.actionMenuArgs = { source = UIConst.UI_DRAG_DROP_SOURCE_TYPE.Repository, componentId = self.m_cache.componentId, cacheGridIndex = CSIndex(self.m_slotIndex), }
        itemSlot.item:AddHoverBinding("common_quick_drop", function()
            itemSlot:QuickDrop()
        end)
        InputManagerInst:SetBindingText(itemSlot.item.view.button.hoverConfirmBindingId, Language["key_hint_item_open_action_menu"])
    end
    local color = info.count < info.maxStackCount and self.config.COLOR_NORMAL or self.config.COLOR_MAX_STACK
    local colorFormatterPrefix = string.format("<color=#%sff>", color)
    itemSlot.view.item:UpdateCountWithColor(info.count, colorFormatterPrefix .. "%s" .. "</color>")
end
FacCacheSlot._TryDisableHoverBindingOnEmptyItem = HL.Method() << function(self)
    local itemInfo = self.m_itemInfo
    if not itemInfo or not itemInfo.count or itemInfo.count == 0 then
        local itemSlot = self:_GetCurrentItemSlot()
        InputManagerInst:ToggleBinding(itemSlot.item.view.button.hoverConfirmBindingId, false)
        return
    end
end
FacCacheSlot._RefreshLiquidBg = HL.Method() << function(self)
    if not self.m_isFluid then
        return
    end
    local count = 0
    local height = 0
    if not string.isEmpty(self.m_itemInfo.id) then
        count = self.m_itemInfo.count
        local maxCount = self.m_itemInfo.maxStackCount
        if maxCount > 0 then
            height = count / maxCount
        end
    end
    self.view.liquidItemSlot.view.facLiquidBg:RefreshLiquidHeight(height)
end
FacCacheSlot.m_dragHelper = HL.Field(HL.Forward('UIDragHelper'))
FacCacheSlot._InitSlotDrag = HL.Method() << function(self)
    self:RegisterMessage(MessageConst.ON_START_UI_DRAG, function(dragHelper)
        self:_OnStartUiDrag(dragHelper)
    end)
    self:RegisterMessage(MessageConst.ON_END_UI_DRAG, function(dragHelper)
        self:_OnEndUiDrag(dragHelper)
    end)
end
FacCacheSlot._OnStartUiDrag = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if dragHelper == nil then
        return
    end
    local itemSlot = self:_GetCurrentItemSlot()
    if self:_ShouldAcceptDrop(dragHelper) then
        itemSlot.view.dropItem.enabled = true
        itemSlot.view.dropHintImg.gameObject:SetActiveIfNecessary(true)
        if self.m_isFluid then
            self:_RefreshFluidSlotDropHintText(dragHelper.info.itemId)
        end
    else
        itemSlot.view.dropItem.enabled = false
    end
end
FacCacheSlot._OnEndUiDrag = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if dragHelper == nil then
        return
    end
    local itemSlot = self:_GetCurrentItemSlot()
    itemSlot.view.dropItem.enabled = false
    if self:_ShouldAcceptDrop(dragHelper) then
        itemSlot.view.dropHintImg.gameObject:SetActiveIfNecessary(false)
    end
end
FacCacheSlot.m_dropHelper = HL.Field(HL.Forward('UIDropHelper'))
FacCacheSlot._ShouldAcceptDrop = HL.Method(HL.Forward('UIDragHelper')).Return(HL.Boolean) << function(self, dragHelper)
    if not self.m_isDropEnabled then
        return false
    end
    if not self.m_dropHelper:Accept(dragHelper) then
        return false
    end
    if dragHelper.info.repository == self.m_cache then
        return false
    end
    local itemId = dragHelper.info.itemId
    local success, data = Tables.factoryItemTable:TryGetValue(itemId)
    if not success then
        return false
    end
    if data.itemState then
        return false
    end
    if self.m_isFluid then
        local isEmptyBottle, isFullBottle = self:_IsEmptyBottleDrop(itemId), self:_IsFullBottleDrop(itemId)
        if not isEmptyBottle and not isFullBottle then
            return false
        end
        if isEmptyBottle and string.isEmpty(self.view.liquidItemSlot.view.item.id) then
            return false
        end
        if not self.m_isInCache and not isEmptyBottle then
            return false
        end
    else
        if data.buildingBufferStackLimit <= 0 then
            return false
        end
        if not self.m_isInCache then
            return false
        end
    end
    return true
end
FacCacheSlot._OnDropItem = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    local source = dragHelper.source
    local dragInfo = dragHelper.info
    local core = GameInstance.player.remoteFactory.core
    local componentId = self.m_cache.componentId
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
        if self:_IsFluidModeBottleDrop(dragInfo.itemId) then
            core:Message_OpFillingFluidComWithDepot(Utils.getCurrentChapterId(), componentId, dragInfo.itemId)
        else
            if self:_CheckIsValidItemInLockFormula(dragInfo.itemId) then
                if not self:_CheckIsValidProducerDropBagItem(dragInfo.itemId) then
                    Notify(MessageConst.SHOW_TOAST, Language["ui_fac_common_bag_drop_same_item"])
                    return
                end
                core:Message_OpMoveItemDepotToCache(Utils.getCurrentChapterId(), dragInfo.itemId, componentId, CSIndex(self.m_slotIndex))
            end
        end
    elseif source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.ItemBag then
        if self:_IsFluidModeBottleDrop(dragInfo.itemId) then
            core:Message_OpFillingFluidComWithBag(Utils.getCurrentChapterId(), componentId, dragInfo.csIndex)
        else
            if self:_CheckIsValidItemInLockFormula(dragInfo.itemId) then
                if not self:_CheckIsValidProducerDropBagItem(dragInfo.itemId) then
                    Notify(MessageConst.SHOW_TOAST, Language["ui_fac_common_bag_drop_same_item"])
                    return
                end
                core:Message_OpMoveItemBagToCache(Utils.getCurrentChapterId(), dragInfo.csIndex, componentId, CSIndex(self.m_slotIndex))
            end
        end
    end
    if dragInfo.itemId then
        local cptHandler = FactoryUtils.getBuildingComponentHandler(componentId)
        local buildingNode = cptHandler.belongNode
        local worldPos = GameInstance.remoteFactoryManager.visual:BuildingGridToWorld(Vector2(buildingNode.transform.position.x, buildingNode.transform.position.z))
        EventLogManagerInst:GameEvent_FactoryItemPush(buildingNode.nodeId, buildingNode.templateId, GameInstance.remoteFactoryManager.currentSceneName, worldPos, dragInfo.itemId, dragInfo.count, self.m_cache.items)
    end
end
FacCacheSlot._IsFluidModeBottleDrop = HL.Method(HL.String).Return(HL.Boolean) << function(self, itemId)
    return self.m_isFluid and (self:_IsEmptyBottleDrop(itemId) or self:_IsFullBottleDrop(itemId))
end
FacCacheSlot._IsEmptyBottleDrop = HL.Method(HL.String).Return(HL.Boolean) << function(self, itemId)
    return Tables.emptyBottleTable:ContainsKey(itemId)
end
FacCacheSlot._IsFullBottleDrop = HL.Method(HL.String).Return(HL.Boolean) << function(self, itemId)
    return Tables.fullBottleTable:ContainsKey(itemId)
end
FacCacheSlot._RefreshFluidSlotDropHintText = HL.Method(HL.String) << function(self, itemId)
    local isEmptyBottle, isFullBottle = self:_IsEmptyBottleDrop(itemId), self:_IsFullBottleDrop(itemId)
    if not isEmptyBottle and not isFullBottle then
        return
    end
    local textId = isEmptyBottle and FILLED_SLOT_BOTTLE_DROP_HINT_TEXT_ID or EMPTY_SLOT_BOTTLE_DROP_HINT_TEXT_ID
    self.view.liquidItemSlot.view.dropHintText.text = Language[textId]
end
FacCacheSlot._CheckIsValidProducerDropBagItem = HL.Method(HL.String).Return(HL.Boolean) << function(self, itemId)
    if self.m_producerInfo == nil then
        return true
    end
    local checkCacheList = { self.m_producerInfo.cacheIn1, self.m_producerInfo.cacheIn2, self.m_producerInfo.cacheIn3, self.m_producerInfo.cacheIn4, self.m_producerInfo.cacheFluidIn1, self.m_producerInfo.cacheFluidIn2, self.m_producerInfo.cacheFluidIn3, self.m_producerInfo.cacheFluidIn4, }
    local checkFunc = function(cache)
        if cache == nil then
            return true
        end
        for id, _ in cs_pairs(cache.items) do
            if id == itemId then
                local success, order = cache.itemOrderMap:TryGetValue(id)
                if success and LuaIndex(order) ~= self.m_slotIndex then
                    return false
                end
            end
        end
        return true
    end
    for _, cache in pairs(checkCacheList) do
        local result = checkFunc(cache)
        if not checkFunc(cache) then
            return false
        end
    end
    return true
end
FacCacheSlot.m_lockFormulaId = HL.Field(HL.String) << ""
FacCacheSlot._CheckIsValidItemInLockFormula = HL.Method(HL.String).Return(HL.Boolean) << function(self, itemId)
    if string.isEmpty(self.m_lockFormulaId) then
        return true
    end
    local success, craftData = Tables.factoryMachineCraftTable:TryGetValue(self.m_lockFormulaId)
    if not success then
        return true
    end
    local isValid = false
    for _, itemBundleGroup in pairs(craftData.ingredients) do
        for _, itemBundle in pairs(itemBundleGroup.group) do
            if itemBundle.id == itemId then
                isValid = true
                break
            end
        end
    end
    if not isValid then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_FORBID_CHANGE_FORMULA)
    end
    return isValid
end
FacCacheSlot.RefreshSlotBlockState = HL.Method(HL.Boolean) << function(self, isBlocked)
    if self.m_isBlocked == isBlocked then
        return
    end
    local itemSlot = self:_GetCurrentItemSlot()
    local itemSlotView = itemSlot.view
    local itemView = itemSlotView.item.view
    UIUtils.PlayAnimationAndToggleActive(itemView.blockMaskAnimationWrapper, isBlocked)
    self.m_isBlocked = isBlocked
end
FacCacheSlot.GetNormalSlotLine = HL.Method().Return(HL.Userdata) << function(self)
    return self.view.itemSlot.view.facLineCell
end
FacCacheSlot.GetCurrentNormalSlotItemId = HL.Method().Return(HL.String) << function(self)
    return self.view.itemSlot.view.item.id
end
FacCacheSlot.PlaySlotAnimation = HL.Method(HL.String, HL.Opt(HL.Function)) << function(self, animationName, callback)
    if self.m_isBlocked then
        return
    end
    local slot = self:_GetCurrentItemSlot()
    slot.view.animationWrapper:PlayWithTween(animationName, callback)
end
FacCacheSlot.TryDropItem = HL.Method(HL.Forward('UIDragHelper')).Return(HL.Boolean) << function(self, dragHelper)
    if not self:_ShouldAcceptDrop(dragHelper) then
        return false
    end
    if dragHelper.info.itemId ~= self.m_itemInfo.id and not string.isEmpty(self.m_itemInfo.id) then
        return false
    end
    self:_OnDropItem(dragHelper)
    return true
end
FacCacheSlot.SetSlotDropEnabled = HL.Method(HL.Boolean) << function(self, isEnabled)
    self.m_isDropEnabled = isEnabled
end
HL.Commit(FacCacheSlot)
return FacCacheSlot