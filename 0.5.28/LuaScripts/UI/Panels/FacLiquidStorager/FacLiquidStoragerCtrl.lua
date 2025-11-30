local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacLiquidStorager
FacLiquidStoragerCtrl = HL.Class('FacLiquidStoragerCtrl', uiCtrl.UICtrl)
local FILLED_SLOT_BOTTLE_DROP_HINT_TEXT_ID = "ui_fac_pipe_common_fill"
local EMPTY_SLOT_BOTTLE_DROP_HINT_TEXT_ID = "ui_fac_pipe_common_dump"
FacLiquidStoragerCtrl.m_buildingInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.BuildingUIInfo_FluidContainer)
FacLiquidStoragerCtrl.m_updateThread = HL.Field(HL.Thread)
FacLiquidStoragerCtrl.m_dropHelper = HL.Field(HL.Forward('UIDropHelper'))
FacLiquidStoragerCtrl.m_capacityCount = HL.Field(HL.Number) << 0
FacLiquidStoragerCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_START_UI_DRAG] = '_OnStartUiDrag', [MessageConst.ON_END_UI_DRAG] = '_OnEndUiDrag', }
FacLiquidStoragerCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_buildingInfo = arg.uiInfo
    self.view.buildingCommon:InitBuildingCommon(self.m_buildingInfo)
    self.view.facCachePipe:InitFacCachePipe(self.m_buildingInfo, { useSinglePipe = true, })
    self.view.inventoryArea:InitInventoryArea({
        customOnUpdateCell = function(cell, itemBundle)
            self:_RefreshInventoryItemCell(cell, itemBundle)
        end
    })
    self.view.liquidItemSlot.view.facLiquidBg:InitFacLiquidBg()
    GameInstance.remoteFactoryManager:RegisterInterestedUnitId(self.m_buildingInfo.nodeId)
    self:_InitLiquidStoragerUpdateThread()
end
FacLiquidStoragerCtrl.OnClose = HL.Override() << function(self)
    GameInstance.remoteFactoryManager:UnregisterInterestedUnitId(self.m_buildingInfo.nodeId)
end
FacLiquidStoragerCtrl._InitLiquidStoragerUpdateThread = HL.Method() << function(self)
    self:_RefreshLiquidStoragerBasicContent()
    self:_RefreshLiquidStoragerContainerCount()
    self:_RefreshLiquidItemSlot()
    self:_RefreshLiquidBg()
    self.m_updateThread = self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.FAC_COMMON_UI_UPDATE_INTERVAL)
            self:_RefreshLiquidStoragerContainerCount()
            self:_RefreshLiquidItemSlot()
            self:_RefreshLiquidBg()
        end
    end)
end
FacLiquidStoragerCtrl._RefreshLiquidStoragerBasicContent = HL.Method() << function(self)
    local success, storagerData = Tables.factoryFluidContainerTable:TryGetValue(self.m_buildingInfo.nodeHandler.templateId)
    if not success then
        return
    end
    self.m_capacityCount = storagerData.capacity
    self.view.totalText.text = string.format("%d", self.m_capacityCount)
end
FacLiquidStoragerCtrl._RefreshLiquidStoragerContainerCount = HL.Method() << function(self)
    local itemCount = self.m_buildingInfo.fluidContainer.holdItemCount
    self.view.currentText.text = string.format("%d", itemCount)
    local isFull = itemCount == self.m_capacityCount
    local countColor = isFull and self.view.config.CONTAINER_FULL_COUNT_COLOR or self.view.config.NORMAL_COUNT_COLOR
    local itemView = self.view.liquidItemSlot.view.item.view
    self.view.numberNode.color = countColor
    itemView.count.color = countColor
end
FacLiquidStoragerCtrl._RefreshLiquidItemSlot = HL.Method() << function(self)
    local itemId = self.m_buildingInfo.fluidContainer.holdItemId
    local itemCount = self.m_buildingInfo.fluidContainer.holdItemCount
    local isEmpty = string.isEmpty(itemId)
    local itemSlot = self.view.liquidItemSlot
    if isEmpty then
        itemSlot:InitItemSlot()
    else
        itemSlot:InitItemSlot({ id = itemId, count = itemCount, }, true)
        itemSlot.gameObject.name = "Item_" .. itemId
    end
    itemSlot.view.dragItem.enabled = false
    self.m_dropHelper = UIUtils.initUIDropHelper(self.view.liquidItemSlot.view.dropItem, {
        acceptTypes = UIConst.FACTORY_LIQUID_STORAGER_DROP_ACCEPT_INFO,
        onDropItem = function(eventData, dragHelper)
            if self:_ShouldAcceptDrop(dragHelper) then
                self:_OnDropItem(dragHelper)
            end
        end,
    })
end
FacLiquidStoragerCtrl._RefreshLiquidItemSlotDropHintText = HL.Method(HL.String) << function(self, itemId)
    local isEmptyBottle, isFullBottle = self:_IsEmptyBottleDrop(itemId), self:_IsFullBottleDrop(itemId)
    if not isEmptyBottle and not isFullBottle then
        return
    end
    local textId = isEmptyBottle and FILLED_SLOT_BOTTLE_DROP_HINT_TEXT_ID or EMPTY_SLOT_BOTTLE_DROP_HINT_TEXT_ID
    self.view.liquidItemSlot.view.dropHintText.text = Language[textId]
end
FacLiquidStoragerCtrl._RefreshInventoryItemCell = HL.Method(HL.Userdata, HL.Any) << function(self, cell, itemBundle)
    if cell == nil or itemBundle == nil then
        return
    end
    local itemId = itemBundle.id
    local isEmptyBottle, isFullBottle = self:_IsEmptyBottleDrop(itemId), self:_IsFullBottleDrop(itemId)
    local isBottle = isEmptyBottle or isFullBottle
    local isEmpty = string.isEmpty(itemBundle.id)
    cell.view.forbiddenMask.gameObject:SetActiveIfNecessary(not isBottle and not isEmpty)
    cell.view.dragItem.enabled = isBottle
    cell.view.dropItem.enabled = isBottle or isEmpty
end
FacLiquidStoragerCtrl._RefreshLiquidBg = HL.Method() << function(self)
    local itemSlot = self.view.liquidItemSlot
    local count = 0
    local height = 0
    if not string.isEmpty(self.m_buildingInfo.fluidContainer.holdItemId) then
        count = self.m_buildingInfo.fluidContainer.holdItemCount
        local maxCount = self.m_capacityCount
        if maxCount > 0 then
            height = count / maxCount
        end
    end
    itemSlot.view.facLiquidBg:RefreshLiquidHeight(height)
end
FacLiquidStoragerCtrl._OnStartUiDrag = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if dragHelper == nil then
        return
    end
    if self:_ShouldAcceptDrop(dragHelper) then
        self.view.liquidItemSlot.view.dropItem.enabled = true
        self.view.liquidItemSlot.view.dropHintImg.gameObject:SetActiveIfNecessary(true)
        self:_RefreshLiquidItemSlotDropHintText(dragHelper.info.itemId)
    else
        self.view.liquidItemSlot.view.dropItem.enabled = false
    end
end
FacLiquidStoragerCtrl._OnEndUiDrag = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if dragHelper == nil then
        return
    end
    self.view.liquidItemSlot.view.dropItem.enabled = false
    if self:_ShouldAcceptDrop(dragHelper) then
        self.view.liquidItemSlot.view.dropHintImg.gameObject:SetActiveIfNecessary(false)
    end
end
FacLiquidStoragerCtrl._IsEmptyBottleDrop = HL.Method(HL.String).Return(HL.Boolean) << function(self, itemId)
    return Tables.emptyBottleTable:ContainsKey(itemId)
end
FacLiquidStoragerCtrl._IsFullBottleDrop = HL.Method(HL.String).Return(HL.Boolean) << function(self, itemId)
    return Tables.fullBottleTable:ContainsKey(itemId)
end
FacLiquidStoragerCtrl._ShouldAcceptDrop = HL.Method(HL.Forward('UIDragHelper')).Return(HL.Boolean) << function(self, dragHelper)
    if not self.m_dropHelper:Accept(dragHelper) then
        return false
    end
    local itemId = dragHelper.info.itemId
    local isEmptyBottle, isFullBottle = self:_IsEmptyBottleDrop(itemId), self:_IsFullBottleDrop(itemId)
    if not isEmptyBottle and not isFullBottle then
        return false
    end
    if isEmptyBottle and string.isEmpty(self.m_buildingInfo.fluidContainer.holdItemId) then
        return false
    end
    return true
end
FacLiquidStoragerCtrl._OnDropItem = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    local source = dragHelper.source
    local dragInfo = dragHelper.info
    local core = GameInstance.player.remoteFactory.core
    local componentId = self.m_buildingInfo.fluidContainer.componentId
    if source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.ItemBag then
        core:Message_OpFillingFluidComWithBag(Utils.getCurrentChapterId(), componentId, dragInfo.csIndex)
    elseif source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.FactoryDepot then
        core:Message_OpFillingFluidComWithDepot(Utils.getCurrentChapterId(), componentId, dragInfo.itemId)
    end
end
HL.Commit(FacLiquidStoragerCtrl)