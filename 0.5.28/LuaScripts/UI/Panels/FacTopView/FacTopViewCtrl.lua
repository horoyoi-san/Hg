local QuickBarItemType = FacConst.QuickBarItemType
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacTopView
FacTopViewCtrl = HL.Class('FacTopViewCtrl', uiCtrl.UICtrl)
FacTopViewCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_BUILD_MODE_CHANGE] = 'OnBuildModeChange', [MessageConst.ON_FAC_DESTROY_MODE_CHANGE] = 'OnFacDestroyModeChange', [MessageConst.ON_TOGGLE_QUICK_BAR_CONTROLLER] = 'OnToggleQuickBarController', [MessageConst.ON_ITEM_COUNT_CHANGED] = 'OnItemCountChanged', [MessageConst.ON_SYSTEM_UNLOCK] = 'UpdateEquipBtn', }
FacTopViewCtrl.m_onDrag = HL.Field(HL.Function)
FacTopViewCtrl.m_navigationGroupId = HL.Field(HL.Number) << -1
FacTopViewCtrl.m_typeCells = HL.Field(HL.Forward('UIListCache'))
FacTopViewCtrl.m_getItemCell = HL.Field(HL.Function)
FacTopViewCtrl.m_isCollapsed = HL.Field(HL.Boolean) << false
FacTopViewCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_onDrag = function(eventData)
        self:_OnDrag(eventData)
    end
    self.m_typeCells = UIUtils.genCellCache(self.view.typeCell)
    self.view.hideUIToggle.onValueChanged:AddListener(function(isOn)
        LuaSystemManager.facSystem:ToggleTopViewHideUIMode(isOn)
    end)
    self.view.delBtn.onClick:AddListener(function()
        Notify(MessageConst.FAC_ENTER_DESTROY_MODE)
    end)
    self.view.rotBtn.onClick:AddListener(function()
        LuaSystemManager.facSystem:RotateTopViewCam()
    end)
    self.view.openDeviceListBtn.onClick:AddListener(function()
        Notify(MessageConst.OPEN_FAC_BUILD_MODE_SELECT)
    end)
    self.view.collapseBtn.onClick:AddListener(function()
        self:_ToggleContent(false)
    end)
    self.view.expandBtn.onClick:AddListener(function()
        self:_ToggleContent(true)
    end)
    self.view.equipBtn.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.EquipProducer)
    end)
    self.view.beltNode.item:InitItem({ id = FacConst.BELT_ITEM_ID }, function()
        self:_OnClickBelt()
    end)
    self.view.beltNode.item:OpenLongPressTips()
    self.view.pipeNode.item:InitItem({ id = FacConst.PIPE_ITEM_ID }, function()
        self:_OnClickPipe()
    end)
    self.view.pipeNode.item:OpenLongPressTips()
    self.m_getItemCell = UIUtils.genCachedCellFunction(self.view.scrollList)
    self.view.scrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateCell(self.m_getItemCell(obj), LuaIndex(csIndex))
    end)
    self.m_navigationGroupId = InputManagerInst:CreateGroup(self.view.inputGroup.groupId)
    UIUtils.bindInputPlayerAction("common_navigation_4_dir_up", function()
        self:_MoveMouse(Vector2.up * self.view.config.MOVE_SPD_ON_CONTROLLER)
    end, self.m_navigationGroupId)
    UIUtils.bindInputPlayerAction("common_navigation_4_dir_down", function()
        self:_MoveMouse(Vector2.down * self.view.config.MOVE_SPD_ON_CONTROLLER)
    end, self.m_navigationGroupId)
    UIUtils.bindInputPlayerAction("common_navigation_4_dir_left", function()
        self:_MoveMouse(Vector2.left * self.view.config.MOVE_SPD_ON_CONTROLLER)
    end, self.m_navigationGroupId)
    UIUtils.bindInputPlayerAction("common_navigation_4_dir_right", function()
        self:_MoveMouse(Vector2.right * self.view.config.MOVE_SPD_ON_CONTROLLER)
    end, self.m_navigationGroupId)
    InputManagerInst:ToggleGroup(self.m_navigationGroupId, FactoryUtils.isInBuildMode())
    self.view.topViewToggle.isOn = LuaSystemManager.facSystem.inTopView
    self.view.topViewToggle.onValueChanged:AddListener(function(isOn)
        Notify(MessageConst.FAC_TOGGLE_TOP_VIEW, isOn)
    end)
    self:_ToggleContent(true, true)
end
FacTopViewCtrl.OnShow = HL.Override() << function(self)
    self:_AddRegister()
    self:_RefreshTypes()
    self.view.hideUIToggle:SetIsOnWithoutNotify(LuaSystemManager.facSystem.isTopViewHideUIMode)
    self.view.mouseHoverHint.gameObject:SetActive(false)
    self:UpdateEquipBtn()
end
FacTopViewCtrl.OnHide = HL.Override() << function(self)
    self:_ClearRegister()
end
FacTopViewCtrl.OnClose = HL.Override() << function(self)
    self:_ClearRegister()
    if LuaSystemManager.facSystem.inTopView then
        Notify(MessageConst.FAC_TOGGLE_TOP_VIEW, false)
    end
end
FacTopViewCtrl.OnToggleFacTopView = HL.StaticMethod(HL.Boolean) << function(active)
    if active then
        local self = UIManager:AutoOpen(PANEL_ID)
        self:_OnToggleFacTopView(true)
    else
        local _, self = UIManager:IsOpen(PANEL_ID)
        if self then
            self:_OnToggleFacTopView(false)
        end
    end
end
FacTopViewCtrl._OnToggleFacTopView = HL.Method(HL.Boolean) << function(self, active)
    if active then
        self:_ClearScreen()
        UIManager:AutoOpen(PanelId.FacTopViewBuildingInfo)
        Notify(MessageConst.FAC_TOGGLE_TOP_VIEW_BUILDING_INFO, true)
    else
        if self.m_hideKey ~= -1 then
            self:Hide()
            self:_RecoverScreen()
            Notify(MessageConst.FAC_TOGGLE_TOP_VIEW_BUILDING_INFO, false)
        end
    end
    self.view.topViewToggle:SetIsOnWithoutNotify(active)
end
FacTopViewCtrl.OnFacDestroyModeChange = HL.Method(HL.Boolean) << function(self, inDestroyMode)
    InputManagerInst:ToggleGroup(self.m_navigationGroupId, inDestroyMode)
    self.view.main.gameObject:SetActive(not inDestroyMode)
    if not inDestroyMode then
        self:PlayAnimationIn()
    end
end
FacTopViewCtrl.OnBuildModeChange = HL.Method(HL.Number) << function(self, mode)
    local inBuild = mode ~= FacConst.FAC_BUILD_MODE.Normal
    InputManagerInst:ToggleGroup(self.m_navigationGroupId, inBuild)
    self.view.main.gameObject:SetActive(not inBuild)
    if not inBuild then
        self:PlayAnimationIn()
    end
end
FacTopViewCtrl.OnToggleQuickBarController = HL.Method(HL.Boolean) << function(self, active)
    self:ChangePanelCfg("virtualMouseMode", active and Types.EPanelMouseMode.ForceHide or Types.EPanelMouseMode.NeedShow)
end
FacTopViewCtrl.OnItemCountChanged = HL.Method(HL.Table) << function(self, args)
    if self:IsHide() then
        return
    end
    local itemId2DiffCount = unpack(args)
    local items = self.m_typeInfos[self.m_selectedTypeIndex].items
    self.view.scrollList:UpdateShowingCells(function(csIndex, obj)
        local info = items[LuaIndex(csIndex)]
        if itemId2DiffCount:ContainsKey(info.itemId) then
            local cell = self.m_getItemCell(obj)
            local count = Utils.getItemCount(info.itemId)
            cell.item:UpdateCount(count)
        end
    end)
end
FacTopViewCtrl.m_hideKey = HL.Field(HL.Number) << -1
FacTopViewCtrl._ClearScreen = HL.Method() << function(self)
    if self.m_hideKey ~= -1 then
        return
    end
    local exceptedPanels = { PANEL_ID, PanelId.MainHud, PanelId.FacMain, PanelId.LevelCamera, PanelId.FacMiniPowerHud, PanelId.FacHudBottomMask, PanelId.FacBuildMode, PanelId.FacDestroyMode, PanelId.FacBuildingInteract, PanelId.CommonItemToast, PanelId.CommonNewToast, PanelId.CommonHudToast, PanelId.GeneralTracker, PanelId.Radio, PanelId.MiniMap, PanelId.MissionHud, PanelId.CommonTaskTrackHud, PanelId.BlackBoxDiffBtn, PanelId.FacTopViewBuildingInfo, }
    if not DeviceInfo.usingTouch then
        table.insert(exceptedPanels, PanelId.Joystick)
    end
    self.m_hideKey = UIManager:ClearScreen(exceptedPanels)
end
FacTopViewCtrl._RecoverScreen = HL.Method() << function(self)
    self.m_hideKey = UIManager:RecoverScreen(self.m_hideKey)
end
FacTopViewCtrl._AddRegister = HL.Method() << function(self)
    local touchPanel = UIManager.commonTouchPanel
    touchPanel.onDrag:AddListener(self.m_onDrag)
    self.m_updateKey = LuaUpdate:Remove(self.m_updateKey)
    self.m_updateKey = LuaUpdate:Add("Tick", function()
        self:_Update()
    end)
end
FacTopViewCtrl._ClearRegister = HL.Method() << function(self)
    local touchPanel = UIManager.commonTouchPanel
    touchPanel.onDrag:RemoveListener(self.m_onDrag)
    self.m_updateKey = LuaUpdate:Remove(self.m_updateKey)
end
FacTopViewCtrl._OnDrag = HL.Method(HL.Userdata) << function(self, eventData)
    if InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.Mouse1) then
        return
    end
    if LuaSystemManager.facSystem.inDragSelectBatchMode and not InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.Mouse2) then
        return
    end
    if DeviceInfo.usingKeyboard then
        local isOpen, ctrl = UIManager:IsOpen(PanelId.FacBuildMode)
        if isOpen then
            if ctrl.m_buildingNodeId and not InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.Mouse2) then
                return
            end
        end
    end
    self:_Move(eventData.delta * -self.view.config.MOVE_SPD_ON_DRAG)
end
FacTopViewCtrl._Move = HL.Method(Vector2) << function(self, dir)
    LuaSystemManager.facSystem:MoveTopViewCamTarget(dir)
end
FacTopViewCtrl._MoveMouse = HL.Method(Vector2) << function(self, dir)
    local cam = CameraManager.mainCamera
    local curMousePos = InputManager.mousePosition
    local camRay = cam:ScreenPointToRay(curMousePos)
    local _, worldPos = CSFactoryUtil.SampleLevelRegionPointWithRay(camRay)
    local camTrans = cam.transform
    local realDir = dir.x * camTrans.right + dir.y * camTrans.up
    realDir.y = 0
    worldPos = worldPos + realDir.normalized * dir.magnitude
    local targetScreenPos = cam:WorldToScreenPoint(worldPos)
    InputManager.SetMousePos(targetScreenPos:XY())
end
FacTopViewCtrl.m_updateKey = HL.Field(HL.Number) << -1
FacTopViewCtrl._Update = HL.Method() << function(self)
    if IsNull(self.view.transform) then
        return
    end
    if InputManagerInst.usingVirtualMouse and self.view.inputGroup.groupEnabled then
        local dir = InputManagerInst:GetGamepadStickValue(false, true)
        if dir ~= Vector2.zero then
            self:_Move(dir * 20 * Time.deltaTime)
            InputManager.SetMousePos(Vector2(Screen.width, Screen.height) / 2, false)
        end
    end
    if DeviceInfo.usingKeyboard or DeviceInfo.usingController then
        self:_UpdateKeyHintStates()
    end
end
FacTopViewCtrl.m_typeInfos = HL.Field(HL.Table)
FacTopViewCtrl.m_selectedTypeIndex = HL.Field(HL.Number) << 1
FacTopViewCtrl._InitInfos = HL.Method() << function(self)
    local typeInfos = {}
    self.view.beltNode.gameObject:SetActive(GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedBelt)
    self.view.pipeNode.gameObject:SetActive(FactoryUtils.canShowPipe())
    do
        local fcType = GEnums.FCQuickBarType.Inner
        local currentScope = GameInstance.player.remoteFactory.core:GetCurrentScopeInfo()
        local quickBarList = currentScope:GetQuickBar(fcType)
        local typeData = Tables.factoryQuickBarTypeTable:GetValue("custom")
        local typeInfo = { data = typeData, priority = typeData.priority, items = {}, }
        for _, id in pairs(quickBarList) do
            local info = { itemId = id, isCustomQuickBarItem = true, }
            if not string.isEmpty(id) then
                local buildingData = FactoryUtils.getItemBuildingData(id)
                if buildingData then
                    info.type = QuickBarItemType.Building
                else
                    info.type = QuickBarItemType.Logistic
                end
            end
            table.insert(typeInfo.items, info)
        end
        table.insert(typeInfos, typeInfo)
    end
    local inventory = GameInstance.player.inventory
    local tInfosDic = {}
    for id, data in pairs(Tables.factoryBuildingTable) do
        local typeId = data.quickBarType
        if not string.isEmpty(typeId) then
            local itemData = FactoryUtils.getBuildingItemData(id)
            if inventory:IsItemFound(itemData.id) then
                local tInfo = tInfosDic[typeId]
                if not tInfo then
                    local typeData = Tables.factoryQuickBarTypeTable:GetValue(typeId)
                    tInfo = { data = typeData, priority = typeData.priority, items = {}, }
                    tInfosDic[typeId] = tInfo
                end
                if tInfo then
                    local info = { id = id, itemId = itemData.id, rarity = itemData.rarity, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2, type = QuickBarItemType.Building, }
                    table.insert(tInfo.items, info)
                end
            end
        end
    end
    for _, info in pairs(tInfosDic) do
        table.sort(info.items, Utils.genSortFunction({ "rarity", "sortId1", "sortId2" }, true))
        table.insert(typeInfos, info)
    end
    local logisticInfos = self:_GetLogisticInfos()
    if logisticInfos then
        table.insert(typeInfos, self:_GetLogisticInfos())
    end
    table.sort(typeInfos, Utils.genSortFunction({ "priority" }))
    self.m_typeInfos = typeInfos
end
FacTopViewCtrl._GetLogisticInfos = HL.Method().Return(HL.Opt(HL.Table)) << function(self)
    local typeData = Tables.factoryQuickBarTypeTable:GetValue("logistic")
    local typeInfo = { data = typeData, priority = typeData.priority, items = {}, }
    if GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedBelt then
        for id, data in pairs(Tables.factoryGridBeltTable) do
            if id ~= FacConst.BELT_ID then
                local item = { id = id, itemId = data.beltData.itemId, type = QuickBarItemType.Belt, data = data.beltData, conveySpeed = 1000000 / data.beltData.msPerRound, }
                table.insert(typeInfo.items, item)
            end
        end
    end
    if GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedBridge then
        for id, data in pairs(Tables.factoryGridConnecterTable) do
            local item = { id = id, itemId = data.gridUnitData.itemId, type = QuickBarItemType.Logistic, data = data.gridUnitData, conveySpeed = 1000000 / data.gridUnitData.msPerRound, }
            table.insert(typeInfo.items, item)
        end
    end
    for id, data in pairs(Tables.factoryGridRouterTable) do
        local unlockType = FacConst.LOGISTIC_UNLOCK_SYSTEM_MAP[id]
        local unlocked = false
        if unlockType == GEnums.UnlockSystemType.FacMerger then
            unlocked = GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedConverger
        elseif unlockType == GEnums.UnlockSystemType.FacSplitter then
            unlocked = GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedSplitter
        end
        if unlocked then
            local item = { id = id, itemId = data.gridUnitData.itemId, type = QuickBarItemType.Logistic, data = data.gridUnitData, conveySpeed = 1000000 / data.gridUnitData.msPerRound, }
            table.insert(typeInfo.items, item)
        end
    end
    if FactoryUtils.isDomainSupportPipe() then
        if GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedPipe then
            for id, data in pairs(Tables.factoryLiquidPipeTable) do
                if id ~= FacConst.PIPE_ID then
                    local item = { id = id, itemId = data.pipeData.itemId, type = QuickBarItemType.Belt, data = data.pipeData, conveySpeed = 1000000 / data.pipeData.msPerRound, }
                    table.insert(typeInfo.items, item)
                end
            end
        end
        if GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedPipeConnector then
            for id, data in pairs(Tables.factoryLiquidConnectorTable) do
                local item = { id = id, liquidUnitId = id, itemId = data.liquidUnitData.itemId, type = QuickBarItemType.Logistic, data = data.liquidUnitData, conveySpeed = 1000000 / data.liquidUnitData.msPerRound, }
                table.insert(typeInfo.items, item)
            end
        end
        for id, data in pairs(Tables.factoryLiquidRouterTable) do
            local unlockType = FacConst.LOGISTIC_UNLOCK_SYSTEM_MAP[id]
            local unlocked = false
            if unlockType == GEnums.UnlockSystemType.FacPipeConverger then
                unlocked = GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedPipeConverger
            elseif unlockType == GEnums.UnlockSystemType.FacPipeSplitter then
                unlocked = GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedPipeSplitter
            end
            if unlocked then
                local item = { id = id, liquidUnitId = id, itemId = data.liquidUnitData.itemId, type = QuickBarItemType.Logistic, data = data.liquidUnitData, conveySpeed = 1000000 / data.liquidUnitData.msPerRound, }
                table.insert(typeInfo.items, item)
            end
        end
    end
    if #typeInfo.items > 0 then
        for _, v in ipairs(typeInfo.items) do
            local itemData = Tables.itemTable[v.itemId]
            v.rarity = itemData.rarity
            v.sortId1 = itemData.sortId1
            v.sortId2 = itemData.sortId2
        end
        table.sort(typeInfo.items, Utils.genSortFunction({ "rarity", "sortId1", "sortId2" }, true))
        return typeInfo
    end
end
FacTopViewCtrl._RefreshTypes = HL.Method() << function(self)
    self:_InitInfos()
    local count = #self.m_typeInfos
    self.m_selectedTypeIndex = math.min(math.max(self.m_selectedTypeIndex, 1), count)
    self.m_typeCells:Refresh(count, function(cell, index)
        local info = self.m_typeInfos[index]
        cell.icon.sprite = self:LoadSprite(info.data.icon)
        cell.iconShadow.sprite = self:LoadSprite(string.format("%s_shadow", info.data.icon))
        cell.text.text = info.data.name
        cell.gameObject.name = "TypeTabCell_" .. info.data.id
        cell.toggle.onValueChanged:RemoveAllListeners()
        cell.toggle.isOn = index == self.m_selectedTypeIndex
        cell.toggle.onValueChanged:AddListener(function(isOn)
            if isOn then
                self:_OnClickType(index)
            end
        end)
    end)
    self:_OnClickType(self.m_selectedTypeIndex)
end
FacTopViewCtrl._OnClickType = HL.Method(HL.Number) << function(self, index)
    self.m_selectedTypeIndex = index
    self:_RefreshItemList()
    self.view.scrollList:SetSelectedIndex(0, true, true)
    if self.m_isCollapsed then
        self:_ToggleContent(true)
    end
    local count = self.m_typeCells:GetCount()
    self.m_typeCells:Update(function(cell, tabIndex)
        cell.rightLine.gameObject:SetActive((tabIndex < index - 1) or (tabIndex > index and tabIndex ~= count))
    end)
end
FacTopViewCtrl._RefreshItemList = HL.Method() << function(self)
    local tInfo = self.m_typeInfos[self.m_selectedTypeIndex]
    self.view.scrollList:UpdateCount(tInfo and #tInfo.items or 0)
end
FacTopViewCtrl._OnUpdateCell = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local tInfo = self.m_typeInfos[self.m_selectedTypeIndex]
    local info = tInfo.items[index]
    local itemId = info.itemId
    local isEmpty = string.isEmpty(itemId)
    cell.gameObject.name = "Item_" .. (isEmpty and index or itemId)
    cell.button.onClick:RemoveAllListeners()
    cell.button.onLongPress:RemoveAllListeners()
    cell.dragItem.enabled = not isEmpty
    cell.dragItem:ClearEvents()
    cell.content.gameObject:SetActive(not isEmpty)
    cell.emptyNode.gameObject:SetActive(isEmpty)
    if info.isCustomQuickBarItem then
        local actionId = "fac_use_quick_item_" .. index
        cell.button.onClick:ChangeBindingPlayerAction(actionId)
    else
        cell.button.onClick:StopUseBinding()
    end
    cell.button.onDoubleClick:RemoveAllListeners()
    if isEmpty then
        cell.button.onClick:RemoveAllListeners()
        cell.button.onLongPress:RemoveAllListeners()
        return
    end
    local count
    if info.type == QuickBarItemType.Building then
        count = isEmpty and 0 or Utils.getItemCount(itemId)
    end
    cell.item:InitItem({ id = itemId, count = count })
    cell.typeIcon.sprite = self:LoadSprite(tInfo.data.icon)
    cell.button.onClick:AddListener(function()
        if not isEmpty then
            self:_OnClickItemCell(index)
        end
    end)
    cell.button.onLongPress:AddListener(function()
        if not isEmpty then
            cell.item:ShowTips()
        end
    end)
    cell.button.onDoubleClick:AddListener(function()
        if Utils.getItemCount(itemId) == 0 then
            PhaseManager:OpenPhase(PhaseId.FacHubCraft, { itemId = itemId })
        end
    end)
    local itemData = Tables.itemTable:GetValue(itemId)
    cell.name.text = itemData.name
    UIUtils.initUIDragHelper(cell.dragItem, {
        source = UIConst.UI_DRAG_DROP_SOURCE_TYPE.QuickBar,
        type = itemData.type,
        itemId = itemId,
        onEndDrag = function(enterObj, enterDrop, eventData)
            self:_OnQuickBarEndDrag(index, enterObj, enterDrop, eventData)
        end
    })
    cell.dragItem.onUpdateDragObject:AddListener(function(dragObj)
        local dragItem = UIWidgetManager:Wrap(dragObj)
        dragItem:InitItem({ id = itemId })
    end)
end
FacTopViewCtrl._OnQuickBarEndDrag = HL.Method(HL.Number, HL.Opt(HL.Userdata, HL.Forward('UIDropHelper'), HL.Any)) << function(self, index, enterObj, enterDrop, eventData)
    if not eventData then
        return
    end
    if enterDrop then
        return
    end
    if enterObj ~= UIManager.commonTouchPanel.gameObject then
        return
    end
    self:_OnClickItemCell(index, eventData.position)
end
FacTopViewCtrl._ToggleContent = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, active, fastMode)
    self.m_isCollapsed = not active
    if active then
        local typeCell = self.m_typeCells:Get(self.m_selectedTypeIndex)
        if typeCell then
            typeCell.toggle:SetIsOnWithoutNotify(true)
        end
    else
        self.view.dummyTypeCellForToggleOff.isOn = true
    end
    local ani = self.view.bottomNode
    if fastMode then
        if active then
            ani:SampleToInAnimationEnd()
        else
            ani:SampleToOutAnimationEnd()
        end
        return
    end
    if active then
        ani:PlayInAnimation()
    else
        ani:PlayOutAnimation()
    end
end
FacTopViewCtrl._OnClickItemCell = HL.Method(HL.Number, HL.Opt(Vector2)) << function(self, index, mousePosition)
    local info = self.m_typeInfos[self.m_selectedTypeIndex].items[index]
    if info.type == QuickBarItemType.Building then
        local itemId = info.itemId
        local count, backpackCount = Utils.getItemCount(itemId)
        if count == 0 then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_QUICK_BAR_COUNT_ZERO)
            return
        end
        Notify(MessageConst.FAC_ENTER_BUILDING_MODE, { itemId = itemId, initMousePos = mousePosition, fromDepot = backpackCount == 0, })
    elseif info.type == QuickBarItemType.Belt then
        Notify(MessageConst.FAC_ENTER_BELT_MODE, { beltId = info.id, initMousePos = mousePosition, })
    elseif info.type == QuickBarItemType.Logistic then
        Notify(MessageConst.FAC_ENTER_LOGISTIC_MODE, { itemId = info.itemId, initMousePos = mousePosition, })
    end
end
FacTopViewCtrl._OnClickPipe = HL.Method() << function(self)
    Notify(MessageConst.FAC_ENTER_BELT_MODE, { beltId = FacConst.PIPE_ID })
end
FacTopViewCtrl._OnClickBelt = HL.Method() << function(self)
    Notify(MessageConst.FAC_ENTER_BELT_MODE, { beltId = FacConst.BELT_ID })
end
local MouseHints = { building = { normal = Language.FAC_TOP_VIEW_MOUSE_HOVER_HINT_BUILDING, des = Language.FAC_TOP_VIEW_MOUSE_HOVER_HINT_BUILDING_DES, }, belt = { normal = Language.FAC_TOP_VIEW_MOUSE_HOVER_HINT_LOGISTIC, des = Language.FAC_TOP_VIEW_MOUSE_HOVER_HINT_BELT_DES, }, logistic = { normal = Language.FAC_TOP_VIEW_MOUSE_HOVER_HINT_LOGISTIC, des = Language.FAC_TOP_VIEW_MOUSE_HOVER_HINT_BUILDING_DES, }, pipe = { normal = Language.FAC_TOP_VIEW_MOUSE_HOVER_HINT_LOGISTIC, des = Language.FAC_TOP_VIEW_MOUSE_HOVER_HINT_BUILDING_DES, }, }
FacTopViewCtrl.m_lastKeyHintContent = HL.Field(HL.Any)
FacTopViewCtrl._UpdateKeyHintStates = HL.Method() << function(self)
    local ctrl = LuaSystemManager.facSystem.interactPanelCtrl
    local content
    if UIManager.commonTouchPanel.isPointerEntered then
        if ctrl.m_interactFacNodeId then
            if ctrl.m_interactFacNodeIdIsBuilding then
                content = MouseHints.building
            else
                content = MouseHints.logistic
            end
        elseif ctrl.m_interactLogisticPos then
            content = MouseHints.belt
        elseif ctrl.m_interactPipeNodeId then
            content = MouseHints.pipe
        end
        if content then
            content = LuaSystemManager.facSystem.inDestroyMode and content.des or content.normal
        end
    end
    if content ~= self.m_lastKeyHintContent then
        self.m_lastKeyHintContent = content
        if content then
            self.view.mouseHoverHint.gameObject:SetActiveIfNecessary(true)
            self.view.mouseHoverHint.text.text = content
        else
            self.view.mouseHoverHint.gameObject:SetActiveIfNecessary(false)
        end
    end
end
FacTopViewCtrl.UpdateEquipBtn = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    self.view.equipBtn.gameObject:SetActive(PhaseManager:CheckCanOpenPhase(PhaseId.EquipProducer))
end
HL.Commit(FacTopViewCtrl)