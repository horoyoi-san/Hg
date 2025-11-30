local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacDumper
local DumperState = { None = "None", Stopped = "Stopped", Normal = "Normal", Paused = "Paused", Full = "Full", Invalid = "Invalid", }
local ContainerState = { None = "None", Empty = "Empty", Normal = "Normal", }
local TipsState = { None = "None", Normal = "Normal", OutSewage = "OutSewage", Invalid = "Invalid", }
local DumperPipeState = { None = "None", Normal = "Normal", Blocked = "Blocked", }
FacDumperCtrl = HL.Class('FacDumperCtrl', uiCtrl.UICtrl)
FacDumperCtrl.m_buildingInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.BuildingUIInfo_FluidPumpOut)
FacDumperCtrl.m_targetContainerInfo = HL.Field(CS.Beyond.Gameplay.Factory.FactoryUtil.FluidContainerInfo)
FacDumperCtrl.m_targetContainer = HL.Field(HL.Userdata)
FacDumperCtrl.m_updateThread = HL.Field(HL.Thread)
FacDumperCtrl.m_currContainerItemId = HL.Field(HL.String) << ""
FacDumperCtrl.m_currContainerItemCount = HL.Field(HL.Number) << -1
FacDumperCtrl.m_currCacheItemId = HL.Field(HL.String) << ""
FacDumperCtrl.m_currCacheItemCount = HL.Field(HL.Number) << -1
FacDumperCtrl.m_outSpeed = HL.Field(HL.Number) << -1
FacDumperCtrl.m_dumperState = HL.Field(HL.String) << ""
FacDumperCtrl.m_containerState = HL.Field(HL.String) << ""
FacDumperCtrl.m_tipsState = HL.Field(HL.String) << ""
FacDumperCtrl.m_dumperPipeState = HL.Field(HL.String) << ""
FacDumperCtrl.m_isContainerItemChanged = HL.Field(HL.Boolean) << true
FacDumperCtrl.m_isContainerItemIncreased = HL.Field(HL.Boolean) << false
FacDumperCtrl.s_messages = HL.StaticField(HL.Table) << {}
FacDumperCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_buildingInfo = arg.uiInfo
    self.view.inventoryArea:InitInventoryArea({
        customOnUpdateCell = function(cell, itemBundle)
            self:_RefreshInventoryItemCell(cell, itemBundle)
        end
    })
    self.view.facCachePipe:InitFacCachePipe(self.m_buildingInfo, { useSinglePipe = true, })
    self.view.facCacheRepository:InitFacCacheRepository({ cache = self.m_buildingInfo.cachePumpOut, isInCache = true, isFluidCache = true, cacheIndex = 1, slotCount = 1, })
    self.view.buildingCommon:InitBuildingCommon(self.m_buildingInfo, {
        onStateChanged = function(state)
            self:_RefreshDumperPipeAnimRunningState()
        end
    })
    self.view.targetContainerNode.liquidBg:InitFacLiquidBg()
    GameInstance.remoteFactoryManager:RegisterInterestedUnitId(self.m_buildingInfo.nodeId)
    self:_InitDumperTargetContainer()
    self:_InitDumperUpdateThread()
end
FacDumperCtrl.OnClose = HL.Override() << function(self)
    GameInstance.remoteFactoryManager:UnregisterInterestedUnitId(self.m_buildingInfo.nodeId)
end
FacDumperCtrl._GetDumperCacheItemData = HL.Method().Return(HL.String, HL.Number) << function(self)
    for itemId, itemCount in pairs(self.m_buildingInfo.cachePumpOut.items) do
        return itemId, itemCount
    end
    return "", 0
end
FacDumperCtrl._InitDumperTargetContainer = HL.Method() << function(self)
    local targetNodeId = self.m_buildingInfo.fluidPumpOut.targetNodeId
    local targetInfo = CSFactoryUtil.GetFluidContainerInfo(targetNodeId)
    self.m_targetContainerInfo = targetInfo
    local targetHandler = CSFactoryUtil.GetNodeHandlerByNodeId(targetNodeId)
    if targetHandler ~= nil then
        local component = FactoryUtils.getBuildingComponentHandlerAtPos(targetHandler, GEnums.FCComponentPos.FluidContainer)
        if component ~= nil then
            self.m_targetContainer = component.fluidContainer
        end
    end
    self:_RefreshTargetContainerBasicContent()
end
FacDumperCtrl._InitDumperUpdateThread = HL.Method() << function(self)
    self:_UpdateAndRefreshAll()
    self.m_updateThread = self:_StartCoroutine(function()
        while true do
            coroutine.step(UIConst.FAC_COMMON_UI_UPDATE_INTERVAL)
            self:_UpdateAndRefreshAll()
        end
    end)
end
FacDumperCtrl._IsCacheEmpty = HL.Method().Return(HL.Boolean) << function(self)
    return string.isEmpty(self.m_currCacheItemId) or self.m_currCacheItemCount == 0
end
FacDumperCtrl._IsContainerEmpty = HL.Method().Return(HL.Boolean) << function(self)
    return string.isEmpty(self.m_currContainerItemId) or self.m_currContainerItemCount == 0
end
FacDumperCtrl._GetDumperState = HL.Method().Return(HL.String) << function(self)
    if self:_IsCacheEmpty() then
        return self.m_outSpeed > 0 and DumperState.Normal or DumperState.Stopped
    else
        if self.m_outSpeed == 0 then
            if self.m_currContainerItemCount == self.m_targetContainerInfo.maxAmount then
                return DumperState.Full
            else
                if self.m_currCacheItemId == self.m_currContainerItemId then
                    return DumperState.Paused
                else
                    return DumperState.Invalid
                end
            end
        else
            return DumperState.Normal
        end
    end
end
FacDumperCtrl._GetContainerState = HL.Method().Return(HL.String) << function(self)
    if self:_IsContainerEmpty() then
        return ContainerState.Empty
    else
        return ContainerState.Normal
    end
end
FacDumperCtrl._GetTipsState = HL.Method().Return(HL.String) << function(self)
    if FacConst.SEWAGE_LIQUID_ITEM_ID_LIST[self.m_currCacheItemId] then
        return TipsState.OutSewage
    else
        if not string.isEmpty(self.m_currCacheItemId) and not string.isEmpty(self.m_currContainerItemId) then
            if self.m_currCacheItemId ~= self.m_currContainerItemId then
                return TipsState.Invalid
            else
                return TipsState.Normal
            end
        else
            return TipsState.Normal
        end
    end
end
FacDumperCtrl._GetDumperPipeState = HL.Method().Return(HL.String) << function(self)
    if self.m_outSpeed == 0 and not self:_IsCacheEmpty() then
        return DumperPipeState.Blocked
    else
        return DumperPipeState.Normal
    end
end
FacDumperCtrl._UpdateAndRefreshAll = HL.Method() << function(self)
    self:_UpdateDumperData()
    self:_UpdateAndRefreshDumperState()
    self:_UpdateAndRefreshContainerState()
    self:_UpdateAndRefreshTipsState()
    self:_UpdateAndRefreshDumperPipeState()
    self:_RefreshContainerItem()
    self:_RefreshOutSpeed()
    self:_RefreshLiquidBg()
end
FacDumperCtrl._UpdateDumperData = HL.Method() << function(self)
    local holdItem = self.m_targetContainer.holdItem
    local containerItemId = holdItem == nil and "" or holdItem.id
    local containerItemCount = holdItem == nil and 0 or holdItem.count
    local cacheItemId, cacheItemCount = self:_GetDumperCacheItemData()
    self.m_isContainerItemChanged = self.m_currContainerItemId ~= containerItemId
    self.m_isContainerItemIncreased = self.m_currContainerItemCount >= 0 and self.m_currContainerItemCount < containerItemCount
    self.m_currContainerItemId = containerItemId
    self.m_currContainerItemCount = containerItemCount
    self.m_currCacheItemId = cacheItemId
    self.m_currCacheItemCount = cacheItemCount
    self.m_outSpeed = self.m_buildingInfo.fluidPumpOut.lastRoundPumpCount
end
FacDumperCtrl._UpdateAndRefreshDumperState = HL.Method() << function(self)
    local state = self:_GetDumperState()
    if state == self.m_dumperState then
        return
    end
    self.view.contentController:SetState(state)
    self.m_dumperState = state
end
FacDumperCtrl._UpdateAndRefreshContainerState = HL.Method() << function(self)
    local state = self:_GetContainerState()
    if state == self.m_containerState then
        return
    end
    self.view.targetContainerNode.stateController:SetState(state)
    self.m_containerState = state
    local isEmpty = state == ContainerState.Empty
    UIUtils.PlayAnimationAndToggleActive(self.view.targetContainerNode.emptyAnim, isEmpty)
end
FacDumperCtrl._UpdateAndRefreshTipsState = HL.Method() << function(self)
    local state = self:_GetTipsState()
    if state == self.m_tipsState then
        return
    end
    local isShown = state ~= TipsState.Normal
    UIUtils.PlayAnimationAndToggleActive(self.view.tipsAnim, isShown, function()
        self.view.tipsController:SetState(state)
    end)
    self.m_tipsState = state
end
FacDumperCtrl._UpdateAndRefreshDumperPipeState = HL.Method() << function(self)
    local state = self:_GetDumperPipeState()
    if state == self.m_dumperPipeState then
        return
    end
    self.view.dumperPipeNode.stateController:SetState(state)
    local isBlocked = state == DumperPipeState.Blocked
    UIUtils.PlayAnimationAndToggleActive(self.view.dumperPipeNode.blockedAnim, isBlocked)
    self.m_dumperPipeState = state
    self:_RefreshDumperPipeAnimRunningState()
end
FacDumperCtrl._RefreshTargetContainerBasicContent = HL.Method() << function(self)
    if self.m_targetContainerInfo == nil then
        return
    end
    self.view.targetContainerNode.targetNameText.text = self.m_targetContainerInfo.name
    local isInfinite = self.m_targetContainerInfo.isInfinite
    self.view.targetContainerNode.maxCountText.text = isInfinite and Language.LUA_ITEM_INFINITE_COUNT or string.format("%d", self.m_targetContainerInfo.maxAmount)
    local success, tableData = Tables.factoryFluidPumpOutTable:TryGetValue(self.m_buildingInfo.nodeHandler.templateId)
    if success then
        self.view.maxSpeedText.text = string.format("%d", tableData.maximumSuply)
    end
end
FacDumperCtrl._RefreshContainerItem = HL.Method() << function(self)
    if not self.m_isContainerItemChanged then
        local isInfinite = self.m_targetContainerInfo.isInfinite
        self.view.targetContainerNode.currentCountText.text = isInfinite and Language.LUA_ITEM_INFINITE_COUNT or string.format("%d", self.m_currContainerItemCount)
        if self.m_isContainerItemIncreased then
            self.view.dumperPipeNode.itemAnim:PlayWithTween("dumper_item_changed")
        end
        return
    end
    local itemData = { id = self.m_currContainerItemId, }
    self.view.targetContainerNode.targetItem:InitItem(itemData, true)
    local success, tableData = Tables.itemTable:TryGetValue(self.m_currContainerItemId)
    if success then
        self.view.targetContainerNode.itemNameText.text = tableData.name
    end
end
FacDumperCtrl._RefreshOutSpeed = HL.Method() << function(self)
    self.view.currSpeedText.text = string.format("%d", self.m_outSpeed)
    self.view.currSpeedText.color = self.m_outSpeed > 0 and self.view.config.NORMAL_SPEED_COLOR or self.view.config.STOPPED_SPEED_COLOR
end
FacDumperCtrl._RefreshInventoryItemCell = HL.Method(HL.Userdata, HL.Any) << function(self, cell, itemBundle)
    if cell == nil or itemBundle == nil then
        return
    end
    local itemId = itemBundle.id
    local isEmptyBottle = Tables.emptyBottleTable:ContainsKey(itemId)
    local isFullBottle = Tables.fullBottleTable:ContainsKey(itemId)
    local isBottle = isEmptyBottle or isFullBottle
    local isEmpty = string.isEmpty(itemBundle.id)
    cell.view.forbiddenMask.gameObject:SetActiveIfNecessary(not isBottle and not isEmpty)
    cell.view.dragItem.enabled = isBottle
    cell.view.dropItem.enabled = isBottle or isEmpty
end
FacDumperCtrl._RefreshDumperPipeAnimRunningState = HL.Method() << function(self)
    local isRunning = self.view.buildingCommon.lastState == GEnums.FacBuildingState.Normal
    local animName = isRunning and "dumper_decoarrow_loop" or "dumper_decoarrow_defult"
    if self.view.dumperPipeNode.normalAnim.curStateName == animName then
        return
    end
    self.view.dumperPipeNode.normalAnim:PlayWithTween(animName)
end
FacDumperCtrl._RefreshLiquidBg = HL.Method() << function(self)
    local count = 0
    local height = 0
    if not string.isEmpty(self.m_currContainerItemId) then
        count = self.m_currContainerItemCount
        if self.m_targetContainerInfo.isInfinite then
            height = 0
        else
            local maxCount = self.m_targetContainerInfo.maxAmount
            height = count / maxCount
        end
    end
    self.view.targetContainerNode.liquidBg:RefreshLiquidHeight(height)
end
HL.Commit(FacDumperCtrl)