local QuickBarItemType = FacConst.QuickBarItemType
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacBuildModeSelect
FacBuildModeSelectCtrl = HL.Class('FacBuildModeSelectCtrl', uiCtrl.UICtrl)
FacBuildModeSelectCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_ITEM_COUNT_CHANGED] = 'OnItemCountChanged', [MessageConst.ON_BUILD_MODE_CHANGE] = 'OnBuildModeChange', }
FacBuildModeSelectCtrl.s_lastSelectInfo = HL.StaticField(HL.Table)
FacBuildModeSelectCtrl.m_getCell = HL.Field(HL.Function)
FacBuildModeSelectCtrl.m_tabCells = HL.Field(HL.Forward('UIListCache'))
FacBuildModeSelectCtrl.m_getTabCell = HL.Field(HL.Function)
FacBuildModeSelectCtrl.m_typeInfos = HL.Field(HL.Table)
FacBuildModeSelectCtrl.m_selectedTypeIndex = HL.Field(HL.Number) << 1
FacBuildModeSelectCtrl.m_hidePanelKey = HL.Field(HL.Number) << -1
FacBuildModeSelectCtrl.m_isEntered = HL.Field(HL.Boolean) << false
FacBuildModeSelectCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeBtn.onClick:AddListener(function()
        self:_ExitSelect()
    end)
    self:BindInputPlayerAction("fac_open_devices_list", function()
        self:_ExitSelect()
    end)
    self.view.confirmBtn.onClick:AddListener(function()
        self:_OnClickConfirm()
    end)
    self.view.buildBtn.onClick:AddListener(function()
        self:_GoToBuild()
    end)
    self.m_getCell = UIUtils.genCachedCellFunction(self.view.scrollList)
    self.view.scrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateCell(self.m_getCell(obj), LuaIndex(csIndex))
    end)
    self.view.scrollList.onSelectedCell:AddListener(function(obj, csIndex)
        self:_OnClickItem(LuaIndex(csIndex))
    end)
    self.view.scrollList.onCellSelectedChanged:AddListener(function(obj, csIndex, isSelected)
        local cell = self.m_getCell(obj)
        if cell then
            cell.item:SetSelected(isSelected)
            local item = self.m_typeInfos[self.m_selectedTypeIndex].items[LuaIndex(csIndex)]
            local isBuilding = item.type == QuickBarItemType.Building
            local isEmpty = cell.item.count == 0 and isBuilding
            cell.item.view.button.clickHintTextId = (isSelected and not isEmpty) and "virtual_mouse_hint_build" or ""
        end
    end)
    self.m_getTabCell = UIUtils.genCachedCellFunction(self.view.tabScrollList)
    self.view.tabScrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateTypeCell(self.m_getTabCell(obj), LuaIndex(csIndex))
    end)
    self.view.tabScrollList.onCellSelectedChanged:AddListener(function(obj, csIndex, isSelected)
        local cell = self.m_getTabCell(obj)
        if cell ~= nil then
            cell.default.gameObject:SetActive(not isSelected)
            cell.selected.gameObject:SetActive(isSelected)
            cell.animationWrapper:PlayWithTween(isSelected and "facbuildmodeselect_tab_in" or "facbuildmodeselect_tab_out")
        end
    end)
    if UNITY_EDITOR or DEVELOPMENT_BUILD then
        self:BindInputEvent(CS.Beyond.Input.KeyboardKeyCode.A, function()
            local msg = CS.Proto.CS_GM_COMMAND()
            local item = self.m_typeInfos[self.m_selectedTypeIndex].items[LuaIndex(self.view.scrollList.curSelectedIndex)]
            msg.Command = "AddItemToItemBagSystem " .. item.itemId .. " 50"
            CS.Beyond.Network.NetBus.instance.defaultSender:Send(msg)
            Notify(MessageConst.SHOW_TOAST, "DEBUG: 已添加道具50个")
        end)
    end
    self.view.facQuickBarPlaceholder:InitFacQuickBarPlaceHolder()
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
FacBuildModeSelectCtrl.OpenFacBuildModeSelect = HL.StaticMethod() << function()
    UIManager:ClearScreenWithOutAnimation(function(key)
        local self = UIManager:AutoOpen(PANEL_ID)
        self.m_hidePanelKey = key
        self:_EnterSelect()
    end, { PANEL_ID, PanelId.FacQuickBar, PanelId.FacHudBottomMask })
end
FacBuildModeSelectCtrl._EnterSelect = HL.Method() << function(self)
    self.m_isEntered = true
    self:_RefreshTypes()
    self:ChangePanelCfg("clearedPanel", true)
end
FacBuildModeSelectCtrl._ExitSelect = HL.Method() << function(self)
    self:PlayAnimationOutWithCallback(function()
        self:ChangePanelCfg("clearedPanel", false)
        self.m_isEntered = false
        self.m_hidePanelKey = UIManager:RecoverScreen(self.m_hidePanelKey)
        self:Hide()
    end)
end
FacBuildModeSelectCtrl.OnHide = HL.Override() << function(self)
    self:_SaveSelectInfo()
end
FacBuildModeSelectCtrl.OnClose = HL.Override() << function(self)
    self:_SaveSelectInfo()
    self.m_hidePanelKey = UIManager:RecoverScreen(self.m_hidePanelKey)
end
FacBuildModeSelectCtrl._SaveSelectInfo = HL.Method() << function(self)
    local curTab = self.m_typeInfos[self.m_selectedTypeIndex]
    local tabId = curTab.data.id
    local item = curTab.items[LuaIndex(self.view.scrollList.curSelectedIndex)]
    local id = item.itemId
    FacBuildModeSelectCtrl.s_lastSelectInfo = { tabId, id }
end
FacBuildModeSelectCtrl.OnBuildModeChange = HL.Method(HL.Opt(HL.Any)) << function(self)
    if self.m_isEntered then
        self:_ExitSelect()
    end
end
FacBuildModeSelectCtrl._InitTypeInfo = HL.Method() << function(self)
    local typeInfos = {}
    local isInMainRegion = Utils.isInFacMainRegion()
    local allItems = {}
    local allTypeInfo = { data = { id = "all", name = Language.LUA_FAC_ALL, icon = "Factory/WorkshopCraftTypeIcon/icon_type_all", }, priority = math.maxinteger, items = allItems, }
    table.insert(typeInfos, allTypeInfo)
    do
        local typeData = Tables.factoryQuickBarTypeTable:GetValue("logistic")
        local typeInfo = { data = typeData, priority = typeData.priority, items = {}, redDot = "FacBuildModeMenuLogisticTab", }
        if isInMainRegion then
            if GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedBelt then
                for id, data in pairs(Tables.factoryGridBeltTable) do
                    local item = { id = id, itemId = data.beltData.itemId, type = QuickBarItemType.Belt, data = data.beltData, conveySpeed = 1000000 / data.beltData.msPerRound, }
                    table.insert(typeInfo.items, item)
                end
            end
            if GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedBridge then
                for id, data in pairs(Tables.factoryGridConnecterTable) do
                    local item = { id = id, itemId = data.gridUnitData.itemId, type = QuickBarItemType.Logistic, data = data.gridUnitData, conveySpeed = 1000000 / data.gridUnitData.msPerRound, hasRedDot = true, }
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
                    local item = { id = id, itemId = data.gridUnitData.itemId, type = QuickBarItemType.Logistic, data = data.gridUnitData, conveySpeed = 1000000 / data.gridUnitData.msPerRound, hasRedDot = true, }
                    table.insert(typeInfo.items, item)
                end
            end
        end
        if FactoryUtils.isDomainSupportPipe() then
            if GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedPipe then
                for id, data in pairs(Tables.factoryLiquidPipeTable) do
                    local item = { id = id, itemId = data.pipeData.itemId, type = QuickBarItemType.Belt, data = data.pipeData, conveySpeed = 1000000 / data.pipeData.msPerRound, hasRedDot = false, }
                    table.insert(typeInfo.items, item)
                end
            end
            if GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedPipeConnector then
                for id, data in pairs(Tables.factoryLiquidConnectorTable) do
                    local item = { id = id, liquidUnitId = data.liquidUnitData.itemId, itemId = data.liquidUnitData.itemId, type = QuickBarItemType.Logistic, data = data.liquidUnitData, conveySpeed = 1000000 / data.liquidUnitData.msPerRound, hasRedDot = false, }
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
                    local item = { id = id, liquidUnitId = data.liquidUnitData.itemId, itemId = data.liquidUnitData.itemId, type = QuickBarItemType.Logistic, data = data.liquidUnitData, conveySpeed = 1000000 / data.liquidUnitData.msPerRound, hasRedDot = false, }
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
            table.insert(typeInfos, typeInfo)
        end
    end
    do
        local inventory = GameInstance.player.inventory
        local infos = {}
        for id, data in pairs(Tables.factoryBuildingTable) do
            local typeId = data.quickBarType
            if not string.isEmpty(typeId) and (not data.onlyShowOnMain or isInMainRegion) then
                local itemData = FactoryUtils.getBuildingItemData(id)
                if inventory:IsItemFound(itemData.id) then
                    local info = infos[typeId]
                    if not info then
                        local typeData = Tables.factoryQuickBarTypeTable:GetValue(typeId)
                        info = { data = typeData, priority = typeData.priority, items = {}, }
                        infos[typeId] = info
                    end
                    if info then
                        local item = { id = id, itemId = itemData.id, rarity = itemData.rarity, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2, type = QuickBarItemType.Building, }
                        table.insert(info.items, item)
                    end
                end
            end
        end
        for _, info in pairs(infos) do
            table.sort(info.items, Utils.genSortFunction({ "rarity", "sortId1", "sortId2" }, true))
            table.insert(typeInfos, info)
        end
    end
    table.sort(typeInfos, Utils.genSortFunction({ "priority" }))
    for k = 2, #typeInfos do
        local typeInfo = typeInfos[k]
        for _, v in ipairs(typeInfo.items) do
            table.insert(allItems, v)
        end
    end
    self.m_typeInfos = typeInfos
end
FacBuildModeSelectCtrl._RefreshTypes = HL.Method() << function(self)
    self:_InitTypeInfo()
    local count = #self.m_typeInfos
    self.m_selectedTypeIndex = math.min(math.max(self.m_selectedTypeIndex, 1), count)
    if FacBuildModeSelectCtrl.s_lastSelectInfo then
        local tabId = FacBuildModeSelectCtrl.s_lastSelectInfo[1]
        for k, v in ipairs(self.m_typeInfos) do
            if v.data.id == tabId then
                self.m_selectedTypeIndex = k
                break
            end
        end
    end
    self.view.tabScrollList:UpdateCount(count)
    self:_OnClickType(self.m_selectedTypeIndex)
end
FacBuildModeSelectCtrl._OnUpdateTypeCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local info = self.m_typeInfos[index]
    local sprite = self:LoadSprite(info.data.icon)
    local name = info.data.name
    cell.default.icon.sprite = sprite
    cell.selected.icon.sprite = sprite
    cell.selected.nameTxt.text = name
    cell.default.gameObject:SetActive(self.m_selectedTypeIndex ~= index)
    cell.selected.gameObject:SetActive(self.m_selectedTypeIndex == index)
    cell.button.onClick:RemoveAllListeners()
    cell.button.onClick:AddListener(function()
        self:_OnClickType(index)
    end)
    cell.gameObject.name = "TypeTabCell_" .. info.data.id
    if not Utils.isInBlackbox() and info.redDot then
        cell.redDot:InitRedDot(info.redDot)
        cell.redDot.gameObject:SetActive(true)
    else
        cell.redDot:Stop()
        cell.redDot.gameObject:SetActive(false)
    end
end
FacBuildModeSelectCtrl._OnClickType = HL.Method(HL.Number) << function(self, index)
    self.m_selectedTypeIndex = index
    self.view.tabText.text = self.m_typeInfos[index].data.name
    self.view.tabScrollList:SetSelectedIndex(CSIndex(self.m_selectedTypeIndex), true, true)
    self:_RefreshItemList()
    local targetIndex = 0
    if FacBuildModeSelectCtrl.s_lastSelectInfo then
        local info = self.m_typeInfos[self.m_selectedTypeIndex]
        local targetId = FacBuildModeSelectCtrl.s_lastSelectInfo[2]
        for k, v in ipairs(info.items) do
            if v.itemId == targetId then
                targetIndex = CSIndex(k)
                break
            end
        end
    end
    self.view.scrollList:SetSelectedIndex(targetIndex, true, true)
end
FacBuildModeSelectCtrl._RefreshItemList = HL.Method() << function(self)
    local info = self.m_typeInfos[self.m_selectedTypeIndex]
    self.view.scrollList:UpdateCount(info and #info.items or 0)
end
FacBuildModeSelectCtrl._OnUpdateCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local item = self.m_typeInfos[self.m_selectedTypeIndex].items[index]
    local itemId = item.itemId
    local count
    local isBuilding = item.type == QuickBarItemType.Building
    if isBuilding then
        count = Utils.getItemCount(itemId)
    end
    cell:InitItemSlot({ id = itemId, count = count, }, function()
        self.view.scrollList:SetSelectedIndex(CSIndex(index))
    end)
    cell.item.view.button.longPressHintTextId = nil
    cell.gameObject.name = "CELL_" .. itemId
    local isSelected = index == LuaIndex(self.view.scrollList.curSelectedIndex)
    local isEmpty = count == 0 and isBuilding
    cell.item:SetSelected(isSelected)
    cell.item.view.button.clickHintTextId = (isSelected and not isEmpty) and "virtual_mouse_hint_build" or ""
    if not Utils.isInBlackbox() and item.hasRedDot then
        cell.item.redDot:InitRedDot("FacBuildModeMenuItem", item.id)
        cell.item.redDot.gameObject:SetActive(true)
    else
        cell.item.redDot:Stop()
        cell.item.redDot.gameObject:SetActive(false)
    end
    local canDrag = item.type ~= QuickBarItemType.Belt
    cell.view.dragItem.enabled = canDrag
    if canDrag then
        local data = Tables.itemTable:GetValue(itemId)
        UIUtils.initUIDragHelper(cell.view.dragItem, { source = UIConst.UI_DRAG_DROP_SOURCE_TYPE.BuildModeSelect, type = data.type, itemId = itemId, })
        cell:InitPressDrag()
        cell.item.view.button.longPressHintTextId = "virtual_mouse_hint_drag"
    end
end
FacBuildModeSelectCtrl._TryUpdateCellByItemId = HL.Method(HL.String) << function(self, targetItemId)
    local info = self.m_typeInfos[self.m_selectedTypeIndex]
    if info ~= nil and #info.items > 0 then
        for index, item in ipairs(info.items) do
            local itemId = item.itemId
            if itemId == targetItemId then
                self:_OnUpdateCell(self.m_getCell(index), index)
                break
            end
        end
    end
end
FacBuildModeSelectCtrl._OnClickItem = HL.Method(HL.Number) << function(self, index)
    self:_RefreshSelectedInfo()
    self.view.infoAnimationWrapper:PlayWithTween("facbuildmodinfonode_in")
end
FacBuildModeSelectCtrl._RefreshSelectedInfo = HL.Method() << function(self)
    local item = self.m_typeInfos[self.m_selectedTypeIndex].items[LuaIndex(self.view.scrollList.curSelectedIndex)]
    if item == nil then
        return
    end
    local id = item.itemId
    local data = Tables.itemTable[id]
    local image = self:LoadSprite(UIConst.UI_SPRITE_FAC_BUILDING_IMAGE, string.format("image_%s", item.id))
    if image ~= nil then
        self.view.icon.sprite = image
    end
    UIUtils.setItemRarityImage(self.view.rarityLight, data.rarity)
    UIUtils.setItemRarityImage(self.view.rarityIcon, data.rarity)
    self.view.nameTxt.text = data.name
    self.view.descTxt.text = data.desc
    self.view.bgText.text = data.name
    local hasTag, tagIds = UIUtils.tryGetTagList(id, data.type)
    self.view.tagTxt.gameObject:SetActive(hasTag)
    if hasTag then
        local tagId = tagIds[0]
        local tagData = Tables.factoryIngredientTagTable:GetValue(tagId)
        self.view.tagTxt.text = tagData.tagLabel
    end
    local isBuilding = item.type == QuickBarItemType.Building
    self.view.countNode.gameObject:SetActive(isBuilding)
    self.view.powerNode.gameObject:SetActive(isBuilding)
    if isBuilding then
        local bagCount = Utils.getBagItemCount(id)
        local depotCount = Utils.getDepotItemCount(id, Utils.getCurrentScope(), Utils.getCurDomainId())
        self.view.bagNode.countTxt.text = UIUtils.setCountColor(bagCount, bagCount == 0)
        self.view.depotNode.countTxt.text = UIUtils.setCountColor(depotCount, depotCount == 0)
        local buildingData = FactoryUtils.getItemBuildingData(id)
        self.view.powerTxt.text = buildingData.powerConsume
    end
    if self:IsShow() then
        self.view.buildBtn.gameObject:SetActive(isBuilding and PhaseManager:CheckCanOpenPhase(PhaseId.FacHubCraft))
    end
    if item.hasRedDot then
        Unity.PlayerPrefs.SetInt("FacBuildModeMenuItem" .. item.id, 1)
        RedDotManager:TriggerUpdate("FacBuildModeMenuItem")
    end
end
FacBuildModeSelectCtrl._OnClickConfirm = HL.Method() << function(self)
    local item = self.m_typeInfos[self.m_selectedTypeIndex].items[LuaIndex(self.view.scrollList.curSelectedIndex)]
    if item.type == QuickBarItemType.Building then
        local itemId = item.itemId
        local count, backpackCount = Utils.getItemCount(itemId)
        if count == 0 then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_QUICK_BAR_COUNT_ZERO_NO_JUMP)
            return
        end
        Notify(MessageConst.FAC_ENTER_BUILDING_MODE, { itemId = itemId, fromDepot = backpackCount == 0, })
    elseif item.type == QuickBarItemType.Belt then
        Notify(MessageConst.FAC_ENTER_BELT_MODE, { beltId = item.id })
    elseif item.type == QuickBarItemType.Logistic then
        Notify(MessageConst.FAC_ENTER_LOGISTIC_MODE, { itemId = item.itemId })
    end
    self:_ExitSelect()
end
FacBuildModeSelectCtrl.OnItemCountChanged = HL.Method(HL.Table) << function(self, args)
    if not self.m_isEntered then
        return
    end
    local itemId2DiffCount = unpack(args)
    local item = self.m_typeInfos[self.m_selectedTypeIndex].items[LuaIndex(self.view.scrollList.curSelectedIndex)]
    if itemId2DiffCount:TryGetValue(item.itemId) then
        self:_RefreshSelectedInfo()
        self:_TryUpdateCellByItemId(item.itemId)
    end
end
FacBuildModeSelectCtrl._GoToBuild = HL.Method() << function(self)
    local item = self.m_typeInfos[self.m_selectedTypeIndex].items[LuaIndex(self.view.scrollList.curSelectedIndex)]
    PhaseManager:OpenPhase(PhaseId.FacHubCraft, { itemId = item.itemId })
end
HL.Commit(FacBuildModeSelectCtrl)