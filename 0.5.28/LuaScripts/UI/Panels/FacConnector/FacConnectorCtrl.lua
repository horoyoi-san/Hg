local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacSplitter
FacConnectorCtrl = HL.Class('FacConnectorCtrl', uiCtrl.UICtrl)
local CONNECTOR_START_PORT_INDEX = 1
local CONNECTOR_MAX_PORTS_COUNT = 4
local SINGLE_CONNECTOR_ITEM_INDEX = 0
FacConnectorCtrl.s_messages = HL.StaticField(HL.Table) << {}
FacConnectorCtrl.m_nodeId = HL.Field(HL.Any)
FacConnectorCtrl.m_uiInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.LogisticUnitUIInfo_BoxBridge)
FacConnectorCtrl.m_updateThread = HL.Field(HL.Thread)
FacConnectorCtrl.m_connectorItems = HL.Field(HL.Table)
FacConnectorCtrl.m_lastValidConnectorItems = HL.Field(HL.Table)
FacConnectorCtrl.m_skipIndexMap = HL.Field(HL.Table)
FacConnectorCtrl.m_inBeltInfoList = HL.Field(HL.Table)
FacConnectorCtrl.m_outBeltInfoList = HL.Field(HL.Table)
FacConnectorCtrl.m_inBindingAnimMap = HL.Field(HL.Table)
FacConnectorCtrl.m_outBindingAnimMap = HL.Field(HL.Table)
FacConnectorCtrl.m_inItemAnimMap = HL.Field(HL.Table)
FacConnectorCtrl.m_outItemAnimMap = HL.Field(HL.Table)
FacConnectorCtrl.m_itemSpriteCache = HL.Field(HL.Table)
FacConnectorCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_uiInfo = arg.uiInfo
    local nodeId = self.m_uiInfo.nodeId
    self.m_nodeId = nodeId
    local connectorData = FactoryUtils.getLogisticData(self.m_uiInfo.nodeHandler.templateId)
    local buildingData = { nodeId = arg.uiInfo.nodeId }
    setmetatable(buildingData, { __index = connectorData })
    self.view.buildingCommon:InitBuildingCommon(nil, {
        data = buildingData,
        customRightButtonOnClicked = function()
            self:_OnDeleteConnectorButtonClicked()
        end,
    })
    local speed = connectorData.msPerRound > 0 and 1000 / connectorData.msPerRound or 0
    self.view.buildingCommon.view.speedText.text = string.format("%.1f", 1000 / connectorData.msPerRound)
    self.view.buildingCommon:ChangeBuildingStateDisplay(GEnums.FacBuildingState.Normal)
    self.view.buildingCommon.view.stopLine.gameObject:SetActive(speed <= 0)
    self.view.buildingCommon.view.normalLine.gameObject:SetActive(speed > 0)
    self.m_connectorItems = {}
    self.m_lastValidConnectorItems = {}
    self.m_itemSpriteCache = {}
    self:_InitConnectorUpdateThread()
    self:_InitConveyorEvent()
    self:_InitAnimDataMap()
    self:_InitConveyorBindingAnim()
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
FacConnectorCtrl.OnClose = HL.Override() << function(self)
    self:_ClearConveyorEvent()
    self.m_updateThread = self:_ClearCoroutine(self.m_updateThread)
end
FacConnectorCtrl._InitConveyorEvent = HL.Method() << function(self)
    self.m_inBeltInfoList, self.m_outBeltInfoList = FactoryUtils.getBuildingPortState(self.m_uiInfo.nodeId, false)
    if self.m_inBeltInfoList ~= nil then
        for _, inBeltInfo in pairs(self.m_inBeltInfoList) do
            if inBeltInfo.isBinding then
                GameInstance.remoteFactoryManager:RegisterInterestedUnitId(inBeltInfo.touchNodeId)
            end
        end
    end
    if self.m_outBeltInfoList ~= nil then
        for _, outBeltInfo in pairs(self.m_outBeltInfoList) do
            if outBeltInfo.isBinding then
                GameInstance.remoteFactoryManager:RegisterInterestedUnitId(outBeltInfo.touchNodeId)
            end
        end
    end
    MessageManager:Register(MessageConst.ON_CONVEYOR_CHANGE, function(args)
        self:_OnConveyorChanged(args)
    end, self)
end
FacConnectorCtrl._ClearConveyorEvent = HL.Method() << function(self)
    if self.m_inBeltInfoList ~= nil then
        for _, inBeltInfo in pairs(self.m_inBeltInfoList) do
            if inBeltInfo.isBinding then
                GameInstance.remoteFactoryManager:UnregisterInterestedUnitId(inBeltInfo.touchNodeId)
            end
        end
    end
    if self.m_outBeltInfoList ~= nil then
        for _, outBeltInfo in pairs(self.m_outBeltInfoList) do
            if outBeltInfo.isBinding then
                GameInstance.remoteFactoryManager:UnregisterInterestedUnitId(outBeltInfo.touchNodeId)
            end
        end
    end
    MessageManager:UnregisterAll(self)
end
FacConnectorCtrl._InitConnectorUpdateThread = HL.Method() << function(self)
    self:_UpdateConnectorItems()
    self.m_updateThread = self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.FAC_COMMON_UI_UPDATE_INTERVAL)
            self:_UpdateConnectorItems()
        end
    end)
end
FacConnectorCtrl._UpdateConnectorItems = HL.Method() << function(self)
    self.m_skipIndexMap = {}
    for index = CONNECTOR_START_PORT_INDEX, CONNECTOR_MAX_PORTS_COUNT do
        if not self.m_skipIndexMap[index] then
            local inSuccess, inItemList = CSFactoryUtil.GetLogisticInfo(Utils.getCurrentChapterId(), self.m_uiInfo.nodeId, true, CSIndex(index), false)
            local inItemId = ""
            if inSuccess and inItemList.Count > 0 then
                inItemId = inItemList[inItemList.Count - 1]
                self:_UpdatePortIndexSkipMap(index)
            end
            local inIndex = self:_GetViewIndexByConnectorPortIndex(index, true)
            self:_RefreshConnectorItemState(inIndex, inItemId)
            local outSuccess, outItemList = CSFactoryUtil.GetLogisticInfo(Utils.getCurrentChapterId(), self.m_uiInfo.nodeId, false, CSIndex(index), false)
            local outItemId = ""
            if outSuccess and outItemList.Count > 0 then
                outItemId = outItemList[outItemList.Count - 1]
                self:_UpdatePortIndexSkipMap(index)
            end
            local outIndex = self:_GetViewIndexByConnectorPortIndex(index, false)
            self:_RefreshConnectorItemState(outIndex, outItemId)
        end
    end
end
FacConnectorCtrl._UpdatePortIndexSkipMap = HL.Method(HL.Number) << function(self, portLuaIndex)
    if portLuaIndex % 2 == 0 then
        self.m_skipIndexMap[portLuaIndex - 1] = true
    else
        self.m_skipIndexMap[portLuaIndex + 1] = true
    end
end
FacConnectorCtrl._GetViewIndexByConnectorPortIndex = HL.Method(HL.Number, HL.Boolean).Return(HL.Number) << function(self, portLuaIndex, isIn)
    if isIn then
        return portLuaIndex % 2 == 0 and portLuaIndex - 1 or portLuaIndex
    else
        return portLuaIndex % 2 == 0 and portLuaIndex or portLuaIndex + 1
    end
end
FacConnectorCtrl._RefreshConnectorItemState = HL.Method(HL.Number, HL.String) << function(self, index, itemId)
    local viewItemName = string.format("itemLogistics%d", index)
    local viewItem = self.view[viewItemName]
    local lastItemId = self.m_connectorItems[index]
    if lastItemId == nil and string.isEmpty(itemId) then
        viewItem:InitItem({ id = "", count = 0, })
        self.m_connectorItems[index] = ""
        return
    end
    local lastValidItemId = self.m_lastValidConnectorItems[index]
    local scope, domain = Utils.getCurrentScope(), Utils.getCurDomainId()
    local count = string.isEmpty(itemId) and 0 or Utils.getDepotItemCount(itemId, scope, domain)
    if string.isEmpty(itemId) and not string.isEmpty(lastValidItemId) then
        count = Utils.getDepotItemCount(lastValidItemId, scope, domain)
    end
    if itemId ~= lastItemId then
        if string.isEmpty(itemId) then
            if not string.isEmpty(lastValidItemId) then
                local lastValidCount = Utils.getDepotItemCount(lastValidItemId, scope, domain)
                if lastValidCount > 0 then
                    viewItem.view.contentCanvasGroup.alpha = UIConst.ITEM_MISSING_TRANSPARENCY
                end
            end
        else
            viewItem:InitItem({ id = itemId, count = count, isInfinite = FactoryUtils.isItemInfiniteInFactoryDepot(itemId), }, true)
            viewItem.view.contentCanvasGroup.alpha = UIConst.ITEM_EXIST_TRANSPARENCY
            self.m_lastValidConnectorItems[index] = itemId
        end
        self.m_connectorItems[index] = itemId
    else
        viewItem:UpdateCountSimple(count)
    end
end
FacConnectorCtrl._OnDeleteConnectorButtonClicked = HL.Method() << function(self)
    if not FactoryUtils.canDelBuilding(self.m_nodeId, true) then
        return
    end
    PhaseManager:ExitPhaseFast(PhaseId.FacMachine)
    GameInstance.player.remoteFactory.core:Message_OpDismantle(Utils.getCurrentChapterId(), self.m_nodeId)
end
FacConnectorCtrl._InitAnimDataMap = HL.Method() << function(self)
    self.m_inBindingAnimMap = { { decoAnimWrapper = self.view.arrowDecoAnimationIn1, decoAnimName = "facconnector_arrow", conveyorAnimWrapper = self.view.conveyorAnimationIn1, conveyorAnimName = "facconvergerarrow_loop", }, { decoAnimWrapper = self.view.arrowDecoAnimationIn2, decoAnimName = "facconnector_arrow", conveyorAnimWrapper = self.view.conveyorAnimationIn2, conveyorAnimName = "facconvergerarrow_loop", }, }
    self.m_outBindingAnimMap = { { decoAnimWrapper = self.view.arrowDecoAnimationOut1, decoAnimName = "facconnector_arrow", conveyorAnimWrapper = self.view.conveyorAnimationOut1, conveyorAnimName = "facconvergerarrow_rightloop", }, { decoAnimWrapper = self.view.arrowDecoAnimationOut2, decoAnimName = "facconnector_arrow", conveyorAnimWrapper = self.view.conveyorAnimationOut2, conveyorAnimName = "facconvergerarrow_rightloop", }, }
    self.m_inItemAnimMap = { { animationNode = self.view.itemAnimationIn1, animationName = "connector_itemleft_changed", }, { animationNode = self.view.itemAnimationIn2, animationName = "connector_item_changed", } }
    self.m_outItemAnimMap = { { animationNode = self.view.itemAnimationOut1, animationName = "connector_itemrightdown_changed", }, { animationNode = self.view.itemAnimationOut2, animationName = "connector_itemright_changed", }, }
end
FacConnectorCtrl._GetAnimIndexFromBeltInfoIndex = HL.Method(HL.Number).Return(HL.Number) << function(self, index)
    return math.ceil(index / 2.0)
end
FacConnectorCtrl._InitConveyorBindingAnim = HL.Method() << function(self)
    for inIndex, inBeltInfo in ipairs(self.m_inBeltInfoList) do
        local animInfo = self.m_inBindingAnimMap[self:_GetAnimIndexFromBeltInfoIndex(inIndex)]
        if animInfo ~= nil then
            animInfo.decoAnimWrapper:PlayWithTween(animInfo.decoAnimName)
            animInfo.conveyorAnimWrapper:PlayWithTween(animInfo.conveyorAnimName)
        end
    end
    for outIndex, outBeltInfo in ipairs(self.m_outBeltInfoList) do
        local animInfo = self.m_outBindingAnimMap[self:_GetAnimIndexFromBeltInfoIndex(outIndex)]
        if animInfo ~= nil then
            animInfo.decoAnimWrapper:PlayWithTween(animInfo.decoAnimName)
            animInfo.conveyorAnimWrapper:PlayWithTween(animInfo.conveyorAnimName)
        end
    end
end
FacConnectorCtrl._OnConveyorChanged = HL.Method(HL.Any) << function(self, args)
    local bindingNodeId, componentId, isIn, itemList = unpack(args)
    local infoList = isIn and self.m_outBeltInfoList or self.m_inBeltInfoList
    local animMap = isIn and self.m_outItemAnimMap or self.m_inItemAnimMap
    for index, info in ipairs(infoList) do
        if info.touchNodeId == bindingNodeId then
            local animInfo = animMap[self:_GetAnimIndexFromBeltInfoIndex(index)]
            if animInfo ~= nil then
                animInfo.animationNode.animationWrapper:ClearTween()
                animInfo.animationNode.animationWrapper:PlayWithTween(animInfo.animationName)
                if itemList ~= nil and itemList.Count > 0 then
                    local itemId = itemList[SINGLE_CONNECTOR_ITEM_INDEX]
                    if self.m_itemSpriteCache[itemId] == nil then
                        local success, itemData = Tables.itemTable:TryGetValue(itemId)
                        if success then
                            self.m_itemSpriteCache[itemId] = self:LoadSprite(UIConst.UI_SPRITE_ITEM, itemData.iconId)
                        end
                    end
                    animInfo.animationNode.image.sprite = self.m_itemSpriteCache[itemId]
                end
            end
        end
    end
end
HL.Commit(FacConnectorCtrl)