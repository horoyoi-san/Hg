local LogisticPortLinkageStatus = FacCoreNS.FactoryGridLogisticSystem.LogisticPortLinkageStatus
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacUnloader
FacUnloaderCtrl = HL.Class('FacUnloaderCtrl', uiCtrl.UICtrl)
local INVALID_COUNT_TEXT = "--"
local INVALID_SUB_INDEX = -1
FacUnloaderCtrl.s_messages = HL.StaticField(HL.Table) << {}
FacUnloaderCtrl.m_nodeId = HL.Field(HL.Any)
FacUnloaderCtrl.m_isHUBPort = HL.Field(HL.Boolean) << false
FacUnloaderCtrl.m_subIndex = HL.Field(HL.Number) << 1
FacUnloaderCtrl.m_uiInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.BuildingUIInfo)
FacUnloaderCtrl.m_selector = HL.Field(CS.Beyond.Gameplay.RemoteFactory.FBUtil.Selector)
FacUnloaderCtrl.m_isSelectorLocked = HL.Field(HL.Boolean) << false
FacUnloaderCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_uiInfo = arg.uiInfo
    local nodeId = self.m_uiInfo.nodeId
    self.m_nodeId = nodeId
    self.m_subIndex = arg.subIndex or INVALID_SUB_INDEX
    self:_InitUnloaderBuildingInfo()
    self:_InitUnloadingSelectNode()
    self:_UpdateTransferItem()
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.FAC_COMMON_UI_UPDATE_INTERVAL)
            self:_UpdateTransferItem()
        end
    end)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
    CS.Beyond.Gameplay.Conditions.OnOpenFacUnloaderPanel.Trigger(self.m_selector.selectItemId)
    GameInstance.player.remoteFactory.core:Message_HSFB(Utils.getCurrentChapterId(), false, { 1 })
    GameInstance.remoteFactoryManager:RegisterInterestedUnitId(nodeId)
end
FacUnloaderCtrl.OnClose = HL.Override() << function(self)
    GameInstance.player.remoteFactory.core:Message_HSFB(Utils.getCurrentChapterId(), true, { 1 })
    GameInstance.remoteFactoryManager:UnregisterInterestedUnitId(self.m_nodeId)
end
FacUnloaderCtrl._InitUnloaderBuildingInfo = HL.Method() << function(self)
    local subIndex = self.m_subIndex
    self.m_isHUBPort = subIndex ~= nil and subIndex ~= INVALID_SUB_INDEX
    if not self.m_isHUBPort then
        self.view.buildingCommon:InitBuildingCommon(self.m_uiInfo)
        self.m_selector = self.m_uiInfo.selector
        self.view.facCacheBelt:InitFacCacheBelt(self.m_uiInfo, {
            noGroup = true,
            stateRefreshCallback = function(portInfo)
                self:_RefreshBlockState(portInfo.isBlock)
            end
        })
    else
        local unloaderData = Tables.factoryBuildingTable:GetValue("unloader_1")
        local fakeData = { name = Language.LUA_FAC_HUB_INPUT .. subIndex, itemId = FactoryUtils.getBuildingItemId("unloader_1"), nodeId = self.m_uiInfo.nodeId, }
        setmetatable(fakeData, { __index = unloaderData })
        self.view.buildingCommon:InitBuildingCommon(nil, { data = fakeData })
        self.view.buildingCommon.nodeId = self.m_nodeId
        self.view.buildingCommon.view.descText.text = Language["ui_fac_hub_unloader_des"]
        self.m_selector = self.m_uiInfo["selector" .. subIndex]
        self.view.facCacheBelt:InitFacCacheBelt(self.m_uiInfo, {
            noGroup = true,
            outIndexList = { subIndex },
            stateRefreshCallback = function(portInfo)
                self:_RefreshBlockState(portInfo.isBlock)
            end
        })
        local wikiButton = self.view.buildingCommon.view.wikiButton
        if wikiButton ~= nil then
            wikiButton.onClick:RemoveAllListeners()
            wikiButton.onClick:AddListener(function()
                Notify(MessageConst.SHOW_WIKI_ENTRY, { buildingId = "sp_hub_1" })
            end)
        end
    end
    self:_RefreshSelectorLockState()
end
FacUnloaderCtrl._InitUnloadingSelectNode = HL.Method() << function(self)
    self.view.unloadingEmptyNode.onClick:AddListener(function()
        self:_ShowSelectPanel()
    end)
    self.view.unloadingEmptyNode.clickHintTextId = "virtual_mouse_fac_unloader_switch"
    local itemEmpty = string.isEmpty(self.m_selector.selectItemId)
    self.view.replaceButton.onClick:AddListener(function()
        self:_ShowSelectPanel()
    end)
    self.view.replaceButton.clickHintTextId = "virtual_mouse_fac_unloader_switch"
    self.view.replaceText.gameObject:SetActive(itemEmpty)
    self.view.replaceButton.gameObject:SetActive(not itemEmpty)
end
FacUnloaderCtrl._ShowSelectPanel = HL.Method() << function(self)
    if self.m_isSelectorLocked then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_FORBID_SELECT_ITEM)
        return
    end
    Notify(MessageConst.FAC_SHOW_UNLOADER_SELECT, {
        buildingInfo = self.m_uiInfo,
        selector = self.m_selector,
        subIndex = self.m_subIndex,
        selectCallback = function(itemId)
            self:_SelectItem(itemId)
        end,
        openCallback = function()
            self.view.canvasGroup.alpha = 0.3
        end,
        closeCallback = function()
            self.view.canvasGroup.alpha = 1
        end
    })
end
FacUnloaderCtrl._UpdateTransferItem = HL.Method() << function(self)
    local id = self.m_selector.selectItemId
    local itemExist = not string.isEmpty(id)
    self.view.unloadingItem.gameObject:SetActive(itemExist)
    self.view.unloadingEmptyNode.gameObject:SetActive(not itemExist)
    if itemExist then
        if id ~= self.view.unloadingItem.id then
            self.view.unloadingItem:InitItem({ id = id, count = 1 }, function()
                self:_ShowSelectPanel()
            end)
            self.view.unloadingItem.view.button.clickHintTextId = "virtual_mouse_fac_unloader_switch"
            local success, itemData = Tables.itemTable:TryGetValue(id)
            if success then
                local iconId = itemData.iconId
                local sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, iconId)
                if sprite ~= nil then
                    self.view.itemIcon.sprite = sprite
                end
            end
        end
        local depotCount = Utils.getDepotItemCount(id)
        local text = tostring(depotCount)
        local itemColor = depotCount <= 0 and self.view.config.COLOR_STORAGE_EMPTY or self.view.config.COLOR_STORAGE_NORMAL
        if FactoryUtils.isItemInfiniteInFactoryDepot(id) then
            text = Language.LUA_ITEM_INFINITE_COUNT
            itemColor = self.view.config.COLOR_STORAGE_NORMAL
        end
        self:_RefreshItemCount(text, itemColor)
    else
        self:_RefreshItemCount(INVALID_COUNT_TEXT, self.view.config.COLOR_STORAGE_NORMAL)
    end
    self.view.itemIcon.gameObject:SetActiveIfNecessary(itemExist)
    self.view.decoIcon.gameObject:SetActiveIfNecessary(not itemExist)
end
FacUnloaderCtrl._SelectItem = HL.Method(HL.String) << function(self, itemId)
    if itemId == self.m_selector.selectItemId then
        return
    end
    self.m_uiInfo.sender:Message_OpSetSelectTarget(Utils.getCurrentChapterId(), self.m_selector.componentId, itemId, function()
        if not UIManager:IsOpen(PANEL_ID) then
            return
        end
        self:_UpdateTransferItem()
        CS.Beyond.Gameplay.Conditions.OnFacChooseItemInUnloader.Trigger(itemId)
    end)
    local itemEmpty = string.isEmpty(itemId)
    self.view.replaceText.gameObject:SetActive(itemEmpty)
    self.view.replaceButton.gameObject:SetActive(not itemEmpty)
end
FacUnloaderCtrl._RefreshBlockState = HL.Method(HL.Boolean) << function(self, isBlock)
    local state = isBlock and GEnums.FacBuildingState.Blocked or GEnums.FacBuildingState.Normal
    self.view.buildingCommon:ChangeBuildingStateDisplay(state)
end
FacUnloaderCtrl._RefreshItemCount = HL.Method(HL.String, HL.Any) << function(self, countText, color)
    self.view.infoShadowNode.countText.text = countText
    self.view.infoNode.countText.text = countText
    self.view.infoNode.countText.color = color
end
FacUnloaderCtrl._RefreshSelectorLockState = HL.Method() << function(self)
    local node = FactoryUtils.getBuildingNodeHandler(self.m_uiInfo.nodeId)
    if node == nil then
        return
    end
    local pdp = node.predefinedParam
    if pdp == nil then
        return
    end
    local selector
    if self.m_isHUBPort then
        local hub = pdp.hub
        if hub ~= nil and hub.selectors ~= nil then
            for i = 0, hub.selectors.Count - 1 do
                local v = hub.selectors[i]
                if v.index == self.m_subIndex - 1 then
                    selector = v
                end
            end
        end
    else
        selector = pdp.selector
    end
    local locked = selector and selector.lockSelectedItemId or false
    self.view.selectLockNode.gameObject:SetActive(locked)
    self.m_isSelectorLocked = locked
end
HL.Commit(FacUnloaderCtrl)