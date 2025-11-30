local QuickBarItemType = FacConst.QuickBarItemType
local autoCalcOrderUICtrl = require_ex('UI/Panels/Base/AutoCalcOrderUICtrl')
local PANEL_ID = PanelId.FacQuickBar
FacQuickBarCtrl = HL.Class('FacQuickBarCtrl', autoCalcOrderUICtrl.AutoCalcOrderUICtrl)
FacQuickBarCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.HIDE_FAC_QUICK_BAR] = 'HideFacQuickBar', [MessageConst.PLAY_FAC_QUICK_BAR_OUT_ANIM] = 'PlayOutAnim', [MessageConst.ON_BLOCK_KEYBOARD_EVENT_PANEL_ORDER_CHANGED] = 'PanelOrderChanged', [MessageConst.ON_ITEM_COUNT_CHANGED] = 'OnItemCountChanged', [MessageConst.ON_SET_IN_SAFE_ZONE] = 'OnSetInSafeZone', [MessageConst.ON_QUICK_BAR_CHANGED] = 'OnQuickBarChanged', [MessageConst.ON_START_UI_DRAG] = 'OnOtherStartDragItem', [MessageConst.ON_END_UI_DRAG] = 'OnOtherEndDragItem', [MessageConst.FAC_ON_BELT_UNLOCKED] = 'OnBeltUnlocked', [MessageConst.ON_INPUT_DEVICE_TYPE_CHANGED] = '_OnInputDeviceTypeChanged', [MessageConst.FAC_MAIN_NAVIGATION_STATE_CHANGE] = '_OnFacNavigationStateChanged', [MessageConst.FAC_MAIN_NAVIGATION_STATE_CHANGE_QUICK_BAR] = '_OnFacMainNavigationStateQuickBarChanged', [MessageConst.NAVI_TO_FAC_QUICK_BAR] = 'NaviToFacQuickBar', [MessageConst.START_SET_BUILDING_ON_FAC_QUICK_BAR] = 'StartSetBuildingOnFacQuickBar', [MessageConst.QUICK_DROP_TO_FAC_QUICK_BAR] = '_OnQuickDropItemToQuickBar', [MessageConst.ON_NEW_SCOPE_INFO_RECEIVED] = '_OnNewScopeInfoReceived', }
FacQuickBarCtrl.m_typeCells = HL.Field(HL.Forward("UIListCache"))
FacQuickBarCtrl.m_itemCells = HL.Field(HL.Forward("UIListCache"))
FacQuickBarCtrl.maxItemCount = HL.Const(HL.Number) << 9
FacQuickBarCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_attachedPanels = {}
    self.m_itemCells = UIUtils.genCellCache(self.view.itemSlot)
    self.m_typeCells = UIUtils.genCellCache(self.view.typeTabCell)
    self.view.dropHint.gameObject:SetActive(false)
    self.view.mobileListToggle.onValueChanged:AddListener(function()
        self:_UpdateItemListForMobile()
    end)
    self:_InitBeltNode()
    self:_InitPipeNode()
    self:_InitQuickBarController()
    self.naviGroup.onDefaultNaviFailed:AddListener(function(dir)
        self:_OnDefaultNaviFailed(dir)
    end)
end
FacQuickBarCtrl.OnShow = HL.Override() << function(self)
    FacQuickBarCtrl.Super.OnShow(self)
end
FacQuickBarCtrl.OnHide = HL.Override() << function(self)
    FacQuickBarCtrl.Super.OnHide(self)
    self:_ResetQuickBarControllerDisplayMode()
end
FacQuickBarCtrl.OnClose = HL.Override() << function(self)
    FacQuickBarCtrl.Super.OnClose(self)
end
FacQuickBarCtrl._OnPanelInputBlocked = HL.Override(HL.Boolean) << function(self, isActive)
    if not isActive then
        self:_DeactivateQuickBarController()
    end
end
FacQuickBarCtrl._RefreshContent = HL.Method() << function(self)
    self:_InitDataInfo()
    self:_RefreshTypes()
    self:_InitQuickBarControllerDisplayMode()
end
FacQuickBarCtrl.m_typeInfos = HL.Field(HL.Table)
FacQuickBarCtrl._InitDataInfo = HL.Method() << function(self)
    local remoteFactoryCore = GameInstance.player.remoteFactory.core
    local currentScope = remoteFactoryCore:GetCurrentScopeInfo()
    if not currentScope then
        self.view.beltNode.gameObject:SetActive(false)
        self.view.pipeNode.gameObject:SetActive(false)
        self.view.decoLine.gameObject:SetActive(false)
        return
    end
    local typeInfos = {}
    local isInFacMainRegion = Utils.isInFacMainRegion()
    local isInSettlementDefenseDefending = Utils.isInSettlementDefenseDefending()
    local fcType = GEnums.FCQuickBarType.Inner
    local quickBarList = remoteFactoryCore.isTempQuickBarActive and remoteFactoryCore:GetCurrentTempQuickBar() or currentScope:GetQuickBar(fcType)
    local needShowBelt = self.m_arg.showBelt and not isInSettlementDefenseDefending and isInFacMainRegion and GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedBelt
    self.view.beltNode.gameObject:SetActive(needShowBelt)
    local needShowPipe = self.m_arg.showPipe and not isInSettlementDefenseDefending and FactoryUtils.canShowPipe()
    self.view.pipeNode.gameObject:SetActive(needShowPipe)
    self.view.decoLine.gameObject:SetActive(needShowBelt or needShowPipe)
    local typeData = Tables.factoryQuickBarTypeTable:GetValue("custom")
    local typeInfo = { data = typeData, priority = typeData.priority, fcType = fcType, items = {}, canDrop = true, }
    for _, id in pairs(quickBarList) do
        local info = { itemId = id, isCustomQuickBarItem = true, }
        if not string.isEmpty(id) then
            local buildingData = FactoryUtils.getItemBuildingData(id)
            if buildingData then
                info.type = QuickBarItemType.Building
                info.onlyShowOnMain = buildingData.onlyShowOnMain
            else
                info.type = QuickBarItemType.Logistic
                if FacConst.FLUID_LOGISTIC_ITEMS[id] then
                    info.onlyShowOnMain = false
                else
                    info.onlyShowOnMain = true
                end
            end
        end
        table.insert(typeInfo.items, info)
    end
    table.insert(typeInfos, typeInfo)
    table.sort(typeInfos, Utils.genSortFunction({ "priority" }))
    self.m_typeInfos = typeInfos
end
FacQuickBarCtrl.m_selectedTypeIndex = HL.Field(HL.Number) << 1
FacQuickBarCtrl._RefreshTypes = HL.Method() << function(self)
    if not self.m_typeInfos then
        return
    end
    local count = #self.m_typeInfos
    self.m_selectedTypeIndex = math.min(math.max(self.m_selectedTypeIndex, 1), count)
    self.m_typeCells:Refresh(count, function(cell, index)
        local info = self.m_typeInfos[index]
        local sprite = self:LoadSprite(info.data.icon)
        local name = info.data.name
        cell.default.icon.sprite = sprite
        cell.default.nameTxt.text = name
        cell.selected.icon.sprite = sprite
        cell.selected.nameTxt.text = name
        cell.toggle.onValueChanged:RemoveAllListeners()
        cell.toggle.isOn = index == self.m_selectedTypeIndex
        cell.toggle.onValueChanged:AddListener(function(isOn)
            if isOn then
                self:_OnClickType(index)
            end
        end)
        cell.gameObject.name = "TypeTabCell_" .. info.data.id
    end)
    self:_RefreshItemList()
end
FacQuickBarCtrl._OnClickType = HL.Method(HL.Number) << function(self, index)
    self.m_selectedTypeIndex = index
    self:_RefreshItemList()
end
FacQuickBarCtrl._RefreshItemList = HL.Method() << function(self)
    if self.m_selectedTypeIndex == 0 then
        self.m_itemCells:Refresh(0)
        return
    end
    local info = self.m_typeInfos[self.m_selectedTypeIndex]
    self.m_itemCells:Refresh(#info.items, function(cell, index)
        self:_UpdateCell(cell, index)
    end)
    self:_UpdateItemListForMobile()
end
FacQuickBarCtrl._UpdateCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local item = self.m_typeInfos[self.m_selectedTypeIndex].items[index]
    local itemId = item.itemId
    local isEmpty = string.isEmpty(itemId)
    local count
    if item.type == QuickBarItemType.Building then
        count = isEmpty and 0 or Utils.getItemCount(itemId)
    end
    cell:InitItemSlot({ id = itemId, count = count, }, function()
        self:_OnClickItem(index)
    end, nil, true)
    cell.item.view.button.onDoubleClick:RemoveAllListeners()
    cell.item.view.button.onDoubleClick:AddListener(function()
        if count == 0 then
            PhaseManager:OpenPhase(PhaseId.FacHubCraft, { itemId = itemId })
        end
    end)
    cell.item.view.button.onIsNaviTargetChanged = function(active)
        if active then
            self:_TryDisableHoverBindingOnEmptyItem(cell, index)
        end
    end
    self:_TryDisableHoverBindingOnEmptyItem(cell, index)
    local actionId = "fac_use_quick_item_" .. index
    cell.item.view.button.onClick:ChangeBindingPlayerAction(actionId)
    cell.gameObject.name = "Item_" .. (isEmpty and index or itemId)
    if not isEmpty then
        local data = Tables.itemTable:GetValue(itemId)
        if item.isCustomQuickBarItem then
            UIUtils.initUIDragHelper(cell.view.dragItem, {
                source = UIConst.UI_DRAG_DROP_SOURCE_TYPE.QuickBar,
                type = data.type,
                csIndex = CSIndex(index),
                itemId = itemId,
                onEndDrag = function(enterObj, enterDrop, eventData)
                    self:_OnQuickBarEndDrag(index, enterObj, enterDrop, eventData)
                end
            })
        else
            UIUtils.initUIDragHelper(cell.view.dragItem, {
                source = UIConst.UI_DRAG_DROP_SOURCE_TYPE.QuickBar,
                type = data.type,
                itemId = itemId,
                onEndDrag = function(enterObj, enterDrop, eventData)
                    self:_OnQuickBarEndDrag(index, enterObj, enterDrop, eventData)
                end
            })
        end
        if DeviceInfo.usingController then
            cell:InitPressDrag()
        else
            cell.item:OpenLongPressTips()
        end
    end
    if item.isCustomQuickBarItem then
        cell.view.dropItem.enabled = true
        UIUtils.initUIDropHelper(cell.view.dropItem, {
            acceptTypes = UIConst.FACTORY_QUICK_BAR_DROP_ACCEPT_INFO,
            onDropItem = function(eventData, dragHelper)
                self:_OnDropItem(index, dragHelper)
            end,
        })
    else
        cell.view.dropItem.enabled = false
    end
end
FacQuickBarCtrl._TryDisableHoverBindingOnEmptyItem = HL.Method(HL.Forward("ItemSlot"), HL.Number) << function(self, cell, index)
    local button = cell.item.view.button
    if not string.isEmpty(self.m_curSettingBuildingItemId) then
        InputManagerInst:SetBindingText(button.hoverConfirmBindingId, nil)
        return
    end
    local item = self.m_typeInfos[self.m_selectedTypeIndex].items[index]
    local itemId = item.itemId
    local isEmpty = string.isEmpty(itemId)
    local count
    if item.type == QuickBarItemType.Building then
        count = isEmpty and 0 or Utils.getItemCount(itemId)
    end
    if isEmpty or count == 0 then
        InputManagerInst:ToggleBinding(button.hoverConfirmBindingId, false)
        return
    end
    InputManagerInst:SetBindingText(button.hoverConfirmBindingId, Language.LUA_ITEM_ACTION_PLACE)
end
FacQuickBarCtrl._OnClickItem = HL.Method(HL.Number, HL.Opt(Vector2)) << function(self, index, mousePosition)
    if string.isEmpty(self.m_curSettingBuildingItemId) then
        self:_BuildItem(index, mousePosition)
    else
        self:_SetBuildingOnFacQuickBar(index)
    end
end
FacQuickBarCtrl._BuildItem = HL.Method(HL.Number, HL.Opt(Vector2)) << function(self, index, mousePosition)
    local item = self.m_typeInfos[self.m_selectedTypeIndex].items[index]
    if item == nil or string.isEmpty(item.itemId) then
        return
    end
    local isBuilding = item.type == QuickBarItemType.Building
    if item.onlyShowOnMain then
        if item.type ~= GEnums.FacBuildingType.Hub:GetHashCode() and not Utils.isInFacMainRegion() then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_CANT_BUILD_IN_NOT_MAIN_REGION)
            return
        end
    end
    if isBuilding then
        local itemId = item.itemId
        local count, backpackCount = Utils.getItemCount(itemId)
        local cell = self.m_itemCells:GetItem(index)
        if count > 0 then
            local args = { itemId = itemId, initMousePos = mousePosition, fromDepot = backpackCount == 0, }
            Notify(MessageConst.FAC_ENTER_BUILDING_MODE, args)
            return
        else
            Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_QUICK_BAR_COUNT_ZERO)
            return
        end
    else
        if item.type == QuickBarItemType.Belt then
            Notify(MessageConst.FAC_ENTER_BELT_MODE, { beltId = item.id })
        elseif item.type == QuickBarItemType.Logistic then
            Notify(MessageConst.FAC_ENTER_LOGISTIC_MODE, { itemId = item.itemId })
        end
    end
end
FacQuickBarCtrl._CanDrop = HL.Method().Return(HL.Boolean) << function(self)
    return self.m_typeInfos[self.m_selectedTypeIndex].canDrop == true
end
FacQuickBarCtrl.OnOtherStartDragItem = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if not self:IsShow() then
        return
    end
    if not self:_CanDrop() then
        return
    end
    if UIUtils.isTypeDropValid(dragHelper, UIConst.FACTORY_QUICK_BAR_DROP_ACCEPT_INFO) then
        self.view.dropHint.gameObject:SetActive(true)
        self.view.dropHint.transform:SetAsLastSibling()
    else
        self.view.cantDropHint.gameObject:SetActive(true)
        self.view.cantDropHint.transform:SetAsLastSibling()
    end
    self.view.beltNode.notDropHint.gameObject:SetActive(true)
    self.view.pipeNode.notDropHint.gameObject:SetActive(true)
end
FacQuickBarCtrl.OnOtherEndDragItem = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if not self:IsShow() then
        return
    end
    if not self:_CanDrop() then
        return
    end
    if UIUtils.isTypeDropValid(dragHelper, UIConst.FACTORY_QUICK_BAR_DROP_ACCEPT_INFO) then
        self.view.dropHint.gameObject:SetActive(false)
    else
        self.view.cantDropHint.gameObject:SetActive(false)
    end
    self.view.beltNode.notDropHint.gameObject:SetActive(false)
    self.view.pipeNode.notDropHint.gameObject:SetActive(false)
end
FacQuickBarCtrl._OnDropItem = HL.Method(HL.Number, HL.Forward('UIDragHelper')) << function(self, index, dragHelper)
    local csIndex = CSIndex(index)
    local source = dragHelper.source
    local fcType = self.m_typeInfos[self.m_selectedTypeIndex].fcType
    local remoteFactoryCore = GameInstance.player.remoteFactory.core
    if source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.QuickBar then
        local fromCSIndex = dragHelper.info.csIndex
        if remoteFactoryCore.isTempQuickBarActive then
            remoteFactoryCore:SwitchTempQuickBarItem(fromCSIndex, csIndex)
        else
            GameInstance.player.remoteFactory:SendMoveQuickBar(Utils.getCurrentScope(), fcType, 0, fromCSIndex, csIndex)
        end
    else
        local itemId = dragHelper:GetId()
        if remoteFactoryCore.isTempQuickBarActive then
            remoteFactoryCore:MoveItemToTempQuickBar(itemId, csIndex)
        else
            GameInstance.player.remoteFactory:SendSetQuickBar(Utils.getCurrentScope(), fcType, 0, csIndex, itemId)
        end
    end
    AudioAdapter.PostEvent("au_ui_common_put_down")
end
FacQuickBarCtrl.OnQuickBarChanged = HL.Method() << function(self)
    self:_InitDataInfo()
    self:_RefreshTypes()
end
FacQuickBarCtrl._OnQuickBarEndDrag = HL.Method(HL.Number, HL.Opt(HL.Userdata, HL.Forward('UIDropHelper'), HL.Any)) << function(self, index, enterObj, enterDrop, eventData)
    if enterDrop then
        return
    end
    if enterObj ~= UIManager.commonTouchPanel.gameObject then
        return
    end
    self:_OnClickItem(index, eventData.position)
end
FacQuickBarCtrl.m_arg = HL.Field(HL.Table)
FacQuickBarCtrl.ShowFacQuickBar = HL.StaticMethod(HL.Table) << function(arg)
    local self = FacQuickBarCtrl.AutoOpen(PANEL_ID, nil, true)
    self.m_arg = arg
    self:_AttachToPanel(arg)
end
FacQuickBarCtrl.HideFacQuickBar = HL.Method(HL.Number) << function(self, panelId)
    InputManagerInst.controllerNaviManager:TryRemoveLayer(self.naviGroup)
    self:_CustomHide(panelId)
end
FacQuickBarCtrl.CustomSetPanelOrder = HL.Override(HL.Opt(HL.Number, HL.Table)) << function(self, maxOrder, args)
    self.m_curArgs = args
    self:SetSortingOrder(maxOrder, false)
    self:UpdateInputGroupState()
    self:_RefreshContent()
end
FacQuickBarCtrl.OnSetInSafeZone = HL.Method(HL.Opt(HL.Any)) << function(self, args)
    if self:IsHide() then
        return
    end
    self:_InitDataInfo()
    self:_RefreshItemList()
end
FacQuickBarCtrl.OnItemCountChanged = HL.Method(HL.Table) << function(self, args)
    if not self.m_typeInfos then
        return
    end
    if self:IsHide() then
        return
    end
    local itemId2DiffCount = unpack(args)
    local items = self.m_typeInfos[self.m_selectedTypeIndex].items
    for k, v in ipairs(items) do
        if itemId2DiffCount:ContainsKey(v.itemId) then
            local cell = self.m_itemCells:GetItem(k)
            local count = Utils.getItemCount(v.itemId)
            cell.item:UpdateCount(count)
        end
    end
end
FacQuickBarCtrl._OnQuickDropItemToQuickBar = HL.Method(HL.Any) << function(self, itemId)
    if type(itemId) == "table" then
        itemId = unpack(itemId)
    end
    local info = self.m_typeInfos[self.m_selectedTypeIndex]
    local fcType = info.fcType
    local targetIndex
    for index, barItemData in ipairs(info.items) do
        local barItemId = barItemData.itemId
        if barItemId == itemId then
            return
        end
        if targetIndex == nil and string.isEmpty(barItemId) then
            targetIndex = index
        end
    end
    if targetIndex == nil then
        return
    end
    local success, itemData = Tables.itemTable:TryGetValue(itemId)
    if not success then
        return
    end
    local findType = false
    for _, type in ipairs(UIConst.FACTORY_QUICK_BAR_DROP_ACCEPT_INFO.types) do
        if type == itemData.type then
            findType = true
            break
        end
    end
    if not findType then
        return
    end
    local remoteFactoryCore = GameInstance.player.remoteFactory.core
    local csIndex = CSIndex(targetIndex)
    if remoteFactoryCore.isTempQuickBarActive then
        remoteFactoryCore:MoveItemToTempQuickBar(itemId, csIndex)
    else
        GameInstance.player.remoteFactory:SendSetQuickBar(Utils.getCurrentScope(), fcType, 0, csIndex, itemId)
    end
end
FacQuickBarCtrl._OnNewScopeInfoReceived = HL.Method(HL.Any) << function(self, scopeName)
    self:_RefreshContent()
end
FacQuickBarCtrl.OnBeltUnlocked = HL.Method() << function(self)
    if self:IsShow() then
        self:_InitDataInfo()
        self:_RefreshTypes()
    end
end
FacQuickBarCtrl._InitBeltNode = HL.Method() << function(self)
    self.view.beltNode.notDropHint.gameObject:SetActive(false)
    self.view.beltNode.item:InitItem({ id = FacConst.BELT_ITEM_ID }, function()
        self:_OnClickBelt()
    end)
    self.view.beltNode.item:OpenLongPressTips()
end
FacQuickBarCtrl._OnClickBelt = HL.Method() << function(self)
    Notify(MessageConst.FAC_ENTER_BELT_MODE, { beltId = FacConst.BELT_ID })
end
FacQuickBarCtrl.OnPipeUnlocked = HL.Method() << function(self)
end
FacQuickBarCtrl._InitPipeNode = HL.Method() << function(self)
    self.view.pipeNode.notDropHint.gameObject:SetActive(false)
    self.view.pipeNode.item:InitItem({ id = FacConst.PIPE_ITEM_ID }, function()
        self:_OnClickPipe()
    end)
    self.view.pipeNode.item:OpenLongPressTips()
end
FacQuickBarCtrl._OnClickPipe = HL.Method() << function(self)
    Notify(MessageConst.FAC_ENTER_BELT_MODE, { beltId = FacConst.PIPE_ID })
end
FacQuickBarCtrl.m_selectedItemIndex = HL.Field(HL.Number) << 1
FacQuickBarCtrl.m_controllerBindingGroupId = HL.Field(HL.Number) << 1
FacQuickBarCtrl._InitQuickBarController = HL.Method() << function(self)
    self.m_controllerBindingGroupId = InputManagerInst:CreateGroup(self.view.inputGroup.groupId)
    UIUtils.bindInputPlayerAction("fac_switch_previous_quick_item", function()
        self:_SwitchQuickBarControllerSelectedItem(self.m_selectedItemIndex - 1)
    end, self.m_controllerBindingGroupId)
    UIUtils.bindInputPlayerAction("fac_switch_next_quick_item", function()
        self:_SwitchQuickBarControllerSelectedItem(self.m_selectedItemIndex + 1)
    end, self.m_controllerBindingGroupId)
    UIUtils.bindInputPlayerAction("fac_use_selected_quick_item", function()
        self:_UseQuickBarSelectedItem()
    end, self.m_controllerBindingGroupId)
    InputManagerInst:ToggleGroup(self.m_controllerBindingGroupId, false)
end
FacQuickBarCtrl._InitQuickBarControllerDisplayMode = HL.Method() << function(self)
    self.view.animator:SetBool("IsInitialized", true)
    local deviceType = DeviceInfo.inputType
    self:_RefreshQuickBarControllerDisplayMode(deviceType)
    self.view.controllerKeyHint.gameObject:SetActiveIfNecessary(self.m_arg.useController)
end
FacQuickBarCtrl._ResetQuickBarControllerDisplayMode = HL.Method() << function(self)
    self.view.animator:SetBool("IsInitialized", false)
    local deviceType = DeviceInfo.inputType
    if deviceType == DeviceInfo.InputType.Controller then
        self:_DeactivateQuickBarController()
    end
end
FacQuickBarCtrl._OnInputDeviceTypeChanged = HL.Method(HL.Table) << function(self, arg)
    local type = unpack(arg)
    if not type then
        return
    end
    self:_RefreshQuickBarControllerDisplayMode(type)
end
FacQuickBarCtrl._RefreshQuickBarControllerDisplayMode = HL.Method(HL.Any) << function(self, type)
    self.view.animator:SetBool("IsController", type == DeviceInfo.InputType.Controller and self.m_arg.useController)
end
FacQuickBarCtrl._OnFacNavigationStateChanged = HL.Method(HL.Boolean) << function(self, active)
    if not self:IsShow() then
        return
    end
    if active then
        self:_ActivateQuickBarController()
    else
        self:_DeactivateQuickBarController()
    end
end
FacQuickBarCtrl._ActivateQuickBarController = HL.Method() << function(self)
    self.view.beltNode.item.view.button.onClick:ChangeBindingPlayerAction("")
    self.view.beltNode.keyHint:SetActionId("")
    self.view.controllerKeyHint:SetActionId("fac_switch_previous_quick_item")
    self.view.animator:SetBool("IsControllerActive", true)
    self:_UpdateQuickBarControllerSelectedItem(true)
    Notify(MessageConst.ON_TOGGLE_QUICK_BAR_CONTROLLER, true)
end
FacQuickBarCtrl._DeactivateQuickBarController = HL.Method() << function(self)
    self.view.controllerKeyHint:SetActionId("fac_activate_quick_area")
    self.view.animator:SetBool("IsControllerActive", false)
    self:_UpdateQuickBarControllerSelectedItem(false)
    self.view.beltNode.keyHint:SetActionId("fac_use_quick_item_conveyer_belt")
    self.view.beltNode.item.view.button.onClick:ChangeBindingPlayerAction("fac_use_quick_item_conveyer_belt")
    Notify(MessageConst.ON_TOGGLE_QUICK_BAR_CONTROLLER, false)
end
FacQuickBarCtrl._SwitchQuickBarControllerSelectedItem = HL.Method(HL.Number) << function(self, selectedIndex)
    self:_UpdateQuickBarControllerSelectedItem(false)
    local isInFacMainRegion = Utils.isInFacMainRegion()
    local maxCount = isInFacMainRegion and FacQuickBarCtrl.maxItemCount or FacQuickBarCtrl.maxItemCount - 1
    self.m_selectedItemIndex = (selectedIndex + maxCount - 1) % maxCount + 1
    AudioManager.PostEvent("au_ui_hover_item")
    self:_UpdateQuickBarControllerSelectedItem(true)
end
FacQuickBarCtrl._UpdateQuickBarControllerSelectedItem = HL.Method(HL.Boolean) << function(self, active)
    local isInFacMainRegion = Utils.isInFacMainRegion()
    if not isInFacMainRegion and self.m_selectedItemIndex == FacQuickBarCtrl.maxItemCount then
        self.m_selectedItemIndex = self.m_selectedItemIndex - 1
    end
    local selectedItemSlotCell
    local isBelt = self.m_selectedItemIndex == FacQuickBarCtrl.maxItemCount
    if isBelt then
        selectedItemSlotCell = self.view.beltNode
    else
        selectedItemSlotCell = self.m_itemCells:GetItem(self.m_selectedItemIndex)
    end
    if selectedItemSlotCell == nil then
        return
    end
    local selectedItemCell = selectedItemSlotCell.item
    if selectedItemCell == nil then
        return
    end
    selectedItemSlotCell.item:SetSelected(active)
    if active then
        if isBelt then
            selectedItemSlotCell.keyHint:SetActionId("fac_use_selected_quick_item")
        else
            if not string.isEmpty(selectedItemCell.id) then
                local item = self.m_typeInfos[self.m_selectedTypeIndex].items[self.m_selectedItemIndex]
                local isLogistic = item.type == QuickBarItemType.Logistic
                if selectedItemCell.count > 0 or isLogistic then
                    selectedItemSlotCell.view.keyHint:SetActionId("fac_use_selected_quick_item")
                end
            end
        end
    else
        if isBelt then
            selectedItemSlotCell.keyHint:SetActionId("")
        else
            selectedItemSlotCell.view.keyHint:SetActionId("")
        end
    end
end
FacQuickBarCtrl._UseQuickBarSelectedItem = HL.Method() << function(self)
    if self.m_selectedItemIndex == FacQuickBarCtrl.maxItemCount then
        self:_OnClickBelt()
    else
        self:_OnClickItem(self.m_selectedItemIndex)
    end
end
FacQuickBarCtrl._OnFacMainNavigationStateQuickBarChanged = HL.Method(HL.Boolean) << function(self, isActive)
    self:_UpdateQuickBarControllerSelectedItem(isActive)
    InputManagerInst:ToggleGroup(self.m_controllerBindingGroupId, isActive)
end
FacQuickBarCtrl.NaviToFacQuickBar = HL.Method() << function(self)
    if not self:IsShow() then
        return
    end
    local cell = self.m_itemCells:Get(1)
    cell:SetAsNaviTarget()
end
FacQuickBarCtrl._OnDefaultNaviFailed = HL.Method(CS.UnityEngine.UI.NaviDirection) << function(self, dir)
    if not string.isEmpty(self.m_curSettingBuildingItemId) then
        return
    end
    if dir == Unity.UI.NaviDirection.Up then
        InputManagerInst.controllerNaviManager:TryRemoveLayer(self.naviGroup)
    end
end
FacQuickBarCtrl.m_setBuildingBindingGroupId = HL.Field(HL.Number) << -1
FacQuickBarCtrl.m_curSettingBuildingItemId = HL.Field(HL.String) << ''
FacQuickBarCtrl.StartSetBuildingOnFacQuickBar = HL.Method(HL.Table) << function(self, args)
    local itemId = args.itemId
    self.m_curSettingBuildingItemId = itemId
    self.view.setBuildingHint.gameObject:SetActive(true)
    if self.m_setBuildingBindingGroupId < 0 then
        self.m_setBuildingBindingGroupId = InputManagerInst:CreateGroup(self.view.inputGroup.groupId)
        self:BindInputPlayerAction("common_cancel", function()
            self:_ExitSetBuilding()
        end, self.m_setBuildingBindingGroupId)
    end
    InputManagerInst:ToggleGroup(self.m_setBuildingBindingGroupId, true)
    local curInfo = self.m_typeInfos[self.m_selectedTypeIndex]
    for k, v in ipairs(curInfo.items) do
        if v.itemId == itemId then
            local cell = self.m_itemCells:Get(k)
            cell:SetAsNaviTarget()
            return
        end
    end
    local cell = self.m_itemCells:Get(1)
    cell:SetAsNaviTarget()
end
FacQuickBarCtrl._SetBuildingOnFacQuickBar = HL.Method(HL.Number) << function(self, index)
    local fcType = self.m_typeInfos[self.m_selectedTypeIndex].fcType
    GameInstance.player.remoteFactory:SendSetQuickBar(Utils.getCurrentScope(), fcType, 0, CSIndex(index), self.m_curSettingBuildingItemId)
    self:_ExitSetBuilding()
end
FacQuickBarCtrl._ExitSetBuilding = HL.Method() << function(self)
    self.m_curSettingBuildingItemId = ""
    InputManagerInst.controllerNaviManager:TryRemoveLayer(self.naviGroup)
    InputManagerInst:ToggleGroup(self.m_setBuildingBindingGroupId, false)
    self.view.setBuildingHint.gameObject:SetActive(false)
end
FacQuickBarCtrl._UpdateItemListForMobile = HL.Method() << function(self)
    if not DeviceInfo.usingTouch then
        return
    end
    local isFirst = self.view.mobileListToggle.isOn
    local count = self.m_itemCells:GetCount()
    for k = 1, count do
        local cell = self.m_itemCells:Get(k)
        cell.gameObject:SetActive(isFirst == (k <= count / 2))
    end
end
HL.Commit(FacQuickBarCtrl)