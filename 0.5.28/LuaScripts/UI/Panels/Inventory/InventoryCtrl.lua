local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Inventory
InventoryCtrl = HL.Class('InventoryCtrl', uiCtrl.UICtrl)
InventoryCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_EXIT_FACTORY_MODE] = 'AutoCloseSelfOnInterrupt', [MessageConst.ON_ENTER_FACTORY_MODE] = 'AutoCloseSelfOnInterrupt', [MessageConst.ON_SQUAD_INFIGHT_CHANGED] = 'AutoCloseSelfOnInterrupt', [MessageConst.ON_TELEPORT_SQUAD] = 'AutoCloseSelfOnInterrupt', [MessageConst.DEAD_ZONE_ROLLBACK] = 'AutoCloseSelfOnInterrupt', [MessageConst.ALL_CHARACTER_DEAD] = 'AutoCloseSelfOnInterrupt', [MessageConst.ON_START_UI_DRAG] = 'OnOtherStartDragItem', [MessageConst.ON_END_UI_DRAG] = 'OnOtherEndDragItem', [MessageConst.ON_CHANGE_THROW_MODE] = 'OnChangeThrowMode', [MessageConst.ON_SYSTEM_UNLOCK] = "OnSystemUnlock", [MessageConst.ON_ITEM_BAG_ABANDON_IN_BAG_SUCC] = "OnItemBagAbandonInBagSucc", [MessageConst.ON_CHANGE_SPACESHIP_DOMAIN_ID] = 'OnChangeSpaceshipDomainId', [MessageConst.ON_ITEM_BAG_TOGGLE_ABANDON_DROP] = 'OnToggleAbandonDropValid', }
InventoryCtrl.m_shouldHidePanelsOnShow = HL.Field(HL.Boolean) << false
InventoryCtrl.m_depotInited = HL.Field(HL.Boolean) << false
InventoryCtrl.m_opened = HL.Field(HL.Boolean) << true
InventoryCtrl.m_isFocusingInventory = HL.Field(HL.Boolean) << true
InventoryCtrl.m_abandonItemDropHelper = HL.Field(HL.Forward('UIDropHelper'))
InventoryCtrl.m_naviGroupSwitcher = HL.Field(HL.Forward('NaviGroupSwitcher'))
InventoryCtrl.m_oriPaddingBottom = HL.Field(HL.Number) << 0
InventoryCtrl.m_abandonValid = HL.Field(HL.Boolean) << true
InventoryCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeButton.onClick:AddListener(function()
        self:_OnClickClose()
    end)
    self.view.manualCraftRedDot:InitRedDot("ManualCraftBtn")
    self.view.manualCraftBtn.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.ManualCraft)
    end)
    self.view.switchDepotBtn.onClick:AddListener(function()
        self:_OnClickSwitchDepot()
    end)
    self.view.sortButton.onClick:AddListener(function()
        self:_OnClickSortBtn()
    end)
    self.view.itemBag:InitItemBag(function(itemId, cell, csIndex)
        self:_OnClickItem(itemId, cell, csIndex)
    end, {
        canPlace = true,
        canSplit = true,
        canUse = true,
        canClear = true,
        customOnUpdateCell = function(cell, itemBundle, csIndex)
            self:_CustomOnUpdateItemBagCell(cell, itemBundle, csIndex)
        end,
    })
    self.m_oriPaddingBottom = self.view.itemBag.itemBagContent.view.itemList:GetPadding().bottom
    local NaviGroupSwitcher = require_ex("Common/Utils/UI/NaviGroupSwitcher").NaviGroupSwitcher
    self.m_naviGroupSwitcher = NaviGroupSwitcher(self.view.inputGroup.groupId, nil, true)
    self:_InitQuickStash()
    self:_InitDestroyNode()
    self.view.walletBarPlaceholder:InitWalletBarPlaceholder(JsonConst.INVENTORY_MONEY_IDS)
    self.m_abandonItemDropHelper = UIUtils.initUIDropHelper(self.view.abandonItemMask, {
        isAbandon = true,
        acceptTypes = UIConst.ABANDON_ITEM_DROP_ACCEPT_INFO,
        onDropItem = function(eventData, dragHelper)
            self:_OnAbandonItem(dragHelper)
        end,
    })
    self.view.abandonItemMask.gameObject:SetActive(false)
    self:BindInputPlayerAction("close_inventory", function()
        self:_OnClickClose()
    end)
end
InventoryCtrl.OnClose = HL.Override() << function(self)
    if self.m_isFocusingInventory then
        GameInstance.player.remoteFactory.core:Message_HSFB(Utils.getCurrentChapterId(), true, { 1 })
        self.m_isFocusingInventory = false
    end
end
InventoryCtrl.OnHide = HL.Override() << function(self)
    if self.m_isFocusingInventory then
        GameInstance.player.remoteFactory.core:Message_HSFB(Utils.getCurrentChapterId(), true, { 1 })
        self.m_isFocusingInventory = false
    end
end
InventoryCtrl.OnShow = HL.Override() << function(self)
    self.m_opened = true
    local isManualCraftUnlock = Utils.isSystemUnlocked(GEnums.UnlockSystemType.ManualCraft)
    self.view.manualCraftBtn.gameObject:SetActive(isManualCraftUnlock)
    if Utils.isInFight() then
        self:PlayAnimationOutWithCallback(function()
            self.m_opened = false
            PhaseManager:ExitPhaseFast(PhaseId.Inventory)
        end)
        return
    end
    if Utils.isInSafeZone() then
        self.m_isFocusingInventory = true
        GameInstance.player.remoteFactory.core:Message_HSFB(Utils.getCurrentChapterId(), false, { 1 })
    end
    if Utils.isInRpgDungeon() then
        self.view.rpgDungeonEquipSlots.gameObject:SetActive(true)
        self.view.rpgDungeonEquipSlots:InitRpgDungeonEquipSlots()
    else
        self.view.rpgDungeonEquipSlots.gameObject:SetActive(false)
    end
    if Utils.isInBlackbox() then
        self.view.walletBarPlaceholder.gameObject:SetActiveIfNecessary(false)
    end
end
InventoryCtrl.OnAnimationInFinished = HL.Override() << function(self)
    if not string.isEmpty(self.m_targetItemId) then
        self:_GotoItem(self.m_targetItemId)
        self.m_targetItemId = ""
    else
    end
end
InventoryCtrl._NaviToPart = HL.Method(HL.Boolean, HL.Boolean) << function(self, toItemBag, toTop)
    if toItemBag then
        if toTop then
            self.view.itemBag.itemBagContent.view.itemList:SetTop()
        end
        local cell = self.view.itemBag.itemBagContent:GetCell(1)
        if cell then
            cell:SetAsNaviTarget()
        end
    else
        if toTop then
            self.view.depot.depotContent.view.itemList:SetTop()
        end
        self.view.depot:SetAsNaviTarget()
    end
end
InventoryCtrl.OpenInventoryPanel = HL.Method(HL.Opt(HL.String)) << function(self, itemId)
    if itemId then
        self.m_targetItemId = itemId
    end
    self:_Refresh()
    self:_ToggleDestroyMode(false, true)
    self.view.depot:ToggleDestroyMode(false, true)
end
InventoryCtrl._ChangeFacQuickBarNaviPartner = HL.Method(HL.Any, HL.Boolean) << function(self, facQuickBarNaviGroup, isAdd)
    local batNaviGroup = self.view.itemBag.itemBagContent.view.itemListSelectableNaviGroup
    local depotNaviGroup = self.view.depot.view.depotContent.view.itemListSelectableNaviGroup
    facQuickBarNaviGroup:TryChangeNaviPartnerOnUp(batNaviGroup, isAdd)
    facQuickBarNaviGroup:TryChangeNaviPartnerOnUp(depotNaviGroup, isAdd)
    batNaviGroup:TryChangeNaviPartnerOnDown(facQuickBarNaviGroup, isAdd)
    depotNaviGroup:TryChangeNaviPartnerOnDown(facQuickBarNaviGroup, isAdd)
end
InventoryCtrl._Refresh = HL.Method() << function(self)
    local naviGroupInfos = {}
    table.insert(naviGroupInfos, { naviGroup = self.view.itemBag.itemBagContent.view.itemListSelectableNaviGroup, text = Language.LUA_INV_NAVI_SWITCH_TO_ITEM_BAG, })
    local inSafeZone = Utils.isInSafeZone()
    if inSafeZone then
        self.view.depot.gameObject:SetActive(true)
        self.view.fullBG.gameObject:SetActive(true)
        self.view.halfBG.gameObject:SetActive(false)
        if not self.m_depotInited then
            self:_InitDepot()
            self.m_depotInited = true
        else
            if string.isEmpty(self.m_targetItemId) then
                self.view.depot.depotContent.view.itemList:SetTop()
            end
        end
        self.view.depot.view.depotContent:StartUpdate()
        table.insert(naviGroupInfos, { naviGroup = self.view.depot.depotContent.view.itemListSelectableNaviGroup, text = Language.LUA_INV_NAVI_SWITCH_TO_DEPOT, })
        self.view.blockDepotManualInOutNode.gameObject:SetActive(Utils.isDepotManualInOutLocked())
    else
        self.view.depot.gameObject:SetActive(false)
        self.view.fullBG.gameObject:SetActive(false)
        self.view.halfBG.gameObject:SetActive(true)
    end
    if Utils.isInSpaceShip() then
        local depotInChapter = GameInstance.player.inventory.factoryDepot:GetOrFallback(Utils.getCurrentScope())
        self.view.switchDepotBtn.gameObject:SetActive(depotInChapter.Count > 1)
    else
        self.view.switchDepotBtn.gameObject:SetActive(false)
    end
    self.view.itemBag.itemBagContent:StartUpdate()
    if string.isEmpty(self.m_targetItemId) then
        self.view.itemBag.itemBagContent.view.itemList:SetTop()
    end
    self:_RefreshQuickStash()
    local showFacQuickBar = Utils.isSystemUnlocked(GEnums.UnlockSystemType.FacMode)
    if Utils.isInRpgDungeon() then
        showFacQuickBar = false
    end
    self.view.facQuickBarPlaceHolder.gameObject:SetActive(showFacQuickBar)
    if showFacQuickBar then
        self.view.facQuickBarPlaceHolder:InitFacQuickBarPlaceHolder()
        local facQuickBarNaviGroup = self.view.facQuickBarPlaceHolder:GetNaviGroup()
        table.insert(naviGroupInfos, { naviGroup = facQuickBarNaviGroup, text = Language.LUA_NAVI_SWITCH_TO_FAC_QUICK_BAR, })
        self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId, self.view.facQuickBarPlaceHolder:GetInputBindingGroupId() })
        self:_ChangeFacQuickBarNaviPartner(facQuickBarNaviGroup, true)
    else
        self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
    end
    self.m_naviGroupSwitcher:ChangeGroupInfos(naviGroupInfos)
    self:_NaviToPart(true, true)
end
InventoryCtrl._InitDepot = HL.Method() << function(self)
    self.view.depot:InitDepot(GEnums.ItemValuableDepotType.Factory, nil, {
        canPlace = true,
        canSplit = false,
        canClear = true,
        onToggleDestroyMode = function(active)
            self.m_naviGroupSwitcher:ToggleActive(not active)
        end,
        customOnUpdateCell = function(cell, itemBundle, luaIndex)
            if itemBundle.count and itemBundle.count > 0 then
                cell.item:AddHoverBinding("common_quick_drop", function()
                    cell:QuickDrop()
                end)
            end
            cell.item.canSetQuickBar = true
        end,
    })
end
InventoryCtrl._OnClickClose = HL.Method() << function(self)
    if not self.m_opened then
        return
    end
    self.m_opened = false
    PhaseManager:PopPhase(PhaseId.Inventory)
end
InventoryCtrl.ResetOnClose = HL.Method() << function(self)
    self:_ToggleDestroyMode(false, true)
    self.view.depot:ToggleDestroyMode(false, true)
    InputManagerInst.controllerNaviManager:TryRemoveLayer(self.naviGroup)
    local facQuickBarNaviGroup = self.view.facQuickBarPlaceHolder:GetNaviGroup()
    if facQuickBarNaviGroup then
        self:_ChangeFacQuickBarNaviPartner(facQuickBarNaviGroup, true)
    end
    self:Hide()
    self.view.itemBag.itemBagContent:ReadCurShowingItems()
    self.view.depot.view.depotContent:ReadCurShowingItems()
    self.view.itemBag.itemBagContent:StopUpdate(true)
    self.view.depot.view.depotContent:StopUpdate(true)
end
InventoryCtrl.AutoCloseSelfOnInterrupt = HL.Method(HL.Opt(HL.Any)) << function(self)
    if not self:IsShow(true) then
        return
    end
    self:_OnClickClose()
end
InventoryCtrl._OnDropItem = HL.Method(HL.Userdata, HL.Forward('UIDragHelper')) << function(self, eventData, dragHelper)
    local depotContent = self.view.depot.view.depotContent
    if depotContent.dropHelper:Accept(dragHelper) then
        depotContent.dropHelper.uiDropItem.onDropEvent:Invoke(eventData)
        return
    end
end
InventoryCtrl._OnClickItem = HL.Method(HL.String, HL.Any, HL.Number) << function(self, itemId, cell, csIndex)
    cell.item:Read()
    if not self.m_inDestroyMode then
        if DeviceInfo.usingController then
            cell.item:ShowActionMenu()
        else
            cell.item.canPlace = true
            cell.item.canSplit = true
            cell.item.canUse = true
            cell.item:ShowTips()
        end
        return
    end
    local showTips = not self.m_destroyInfo[csIndex]
    self:_OnClickItemInDestroyMode(csIndex)
    if showTips then
        local posInfo = { tipsPosType = UIConst.UI_TIPS_POS_TYPE.LeftTop, tipsPosTransform = self.view.itemBag.transform, isSideTips = true, }
        cell.item.canPlace = false
        cell.item.canSplit = false
        cell.item.canUse = false
        cell.item:ShowTips(posInfo, function()
            if self.m_showingDestroyItemCSIndex == csIndex then
                self.m_showingDestroyItemCSIndex = -1
            end
        end)
    else
        if DeviceInfo.usingController then
            Notify(MessageConst.HIDE_ITEM_TIPS)
        end
    end
end
InventoryCtrl._OnClickSortBtn = HL.Method() << function(self)
    GameInstance.player.inventory:SortItemBag(Utils.getCurrentScope())
end
InventoryCtrl.m_quickStashSettingInfo = HL.Field(HL.Table)
InventoryCtrl.m_quickStashNaviBindingGroupId = HL.Field(HL.Number) << -1
InventoryCtrl.m_quickStashCells = HL.Field(HL.Forward('UIListCache'))
InventoryCtrl._InitQuickStash = HL.Method() << function(self)
    local quickStashNode = self.view.quickStashNode
    quickStashNode.settingCell.gameObject:SetActive(false)
    quickStashNode.confirmBtn.onClick:AddListener(function()
        self:_QuickStash()
    end)
    quickStashNode.settingBtn.onClick:AddListener(function()
        if DeviceInfo.usingController then
            Notify(MessageConst.SHOW_SORT_POP_OUT, {
                selectOptions = self.m_quickStashSettingInfo,
                onSelectToggle = function(index, isOn)
                    self:_ToggleQuickStashSettingCell(index, isOn)
                end,
                onSelectConfirm = function(_)
                    self:_QuickStash()
                end,
            })
            return
        end
        self:_ToggleQuickStashSetting(not self.view.quickStashNode.settingList.gameObject.activeSelf)
    end)
    quickStashNode.closeBtn.onClick:AddListener(function()
        self:_ToggleQuickStashSetting(false)
    end)
    quickStashNode.autoCloseArea.onTriggerAutoClose:AddListener(function()
        if DeviceInfo.usingController then
            return
        end
        self:_ToggleQuickStashSetting(false)
    end)
    self.m_quickStashNaviBindingGroupId = InputManagerInst:CreateGroup(quickStashNode.inputBindingGroupMonoTarget.groupId)
    InputManagerInst:CreateBindingByActionId("common_navigation_up", function()
        self:_QuickStashNavigateSelected(-1)
    end, self.m_quickStashNaviBindingGroupId)
    InputManagerInst:CreateBindingByActionId("common_navigation_down", function()
        self:_QuickStashNavigateSelected(1)
    end, self.m_quickStashNaviBindingGroupId)
    InputManagerInst:CreateBindingByActionId("common_select", function()
        self:_QuickStashToggleNaviSelected()
    end, self.m_quickStashNaviBindingGroupId)
    InputManagerInst:CreateBindingByActionId("inv_quick_stash_confirm", function()
        self:_QuickStash()
        AudioAdapter.PostEvent("au_ui_g_click")
    end, self.m_quickStashNaviBindingGroupId)
    self.m_quickStashSettingInfo = { { name = Language.LUA_INVENTORY_QUICK_STASH_TYPE_ORE, showingType = GEnums.ItemShowingType.Ore, defaultIsOn = true, }, { name = Language.LUA_INVENTORY_QUICK_STASH_TYPE_PLANT, showingType = GEnums.ItemShowingType.Plant, defaultIsOn = true, }, { name = Language.LUA_INVENTORY_QUICK_STASH_TYPE_PRODUCT, showingType = GEnums.ItemShowingType.Product, defaultIsOn = true, }, { name = Language.LUA_INVENTORY_QUICK_STASH_TYPE_DOODAD, showingType = GEnums.ItemShowingType.Doodad, defaultIsOn = true, }, { name = Language.LUA_INVENTORY_QUICK_STASH_TYPE_NURTURANCE, showingType = GEnums.ItemShowingType.Nurturance, defaultIsOn = true, }, { name = Language.LUA_INVENTORY_QUICK_STASH_TYPE_USABLE, showingType = GEnums.ItemShowingType.Usable, defaultIsOn = false, }, { name = Language.LUA_INVENTORY_QUICK_STASH_TYPE_PRODUCER, showingType = GEnums.ItemShowingType.Producer, defaultIsOn = false, }, }
    for index, info in ipairs(self.m_quickStashSettingInfo) do
        local keyName = "Inventory.QuickStash.Tab." .. index
        self.m_quickStashSettingInfo[index].isOn = Unity.PlayerPrefs.GetInt(keyName, info.defaultIsOn and 1 or 0) == 1
    end
    self.m_quickStashCells = UIUtils.genCellCache(quickStashNode.settingCell)
    self.m_quickStashCells:Refresh(#self.m_quickStashSettingInfo, function(cell, index)
        local info = self.m_quickStashSettingInfo[index]
        cell.toggle.isOn = info.isOn
        cell.toggle.onValueChanged:RemoveAllListeners()
        cell.toggle.onValueChanged:AddListener(function(isOn)
            self:_ToggleQuickStashSettingCell(index, isOn)
        end)
        cell.topLineImg.enabled = index ~= 1
        cell.selectName.text = info.name
        cell.notSelectName.text = info.name
        cell.gameObject.name = "Cell_" .. index
    end)
    self:_ToggleQuickStashSetting(false, true)
end
InventoryCtrl.m_quickStashCurNaviIndex = HL.Field(HL.Number) << -1
InventoryCtrl._QuickStashNavigateSelected = HL.Method(HL.Number) << function(self, offset)
    self.m_quickStashCurNaviIndex = lume.clamp(self.m_quickStashCurNaviIndex + offset, 1, #self.m_quickStashSettingInfo)
    self:_RefreshQuickStashNaviSelected()
    AudioAdapter.PostEvent("au_ui_g_select")
end
InventoryCtrl._QuickStashToggleNaviSelected = HL.Method() << function(self)
    local cell = self.m_quickStashCells:Get(self.m_quickStashCurNaviIndex)
    cell.toggle.isOn = not cell.toggle.isOn
    cell.toggle:OnSelect(nil)
    cell.toggle:PlayAudio()
end
InventoryCtrl._RefreshQuickStashNaviSelected = HL.Method() << function(self)
    self.m_quickStashCells:Update(function(cell, index)
        cell.controllerSelectedHintNode.gameObject:SetActive(index == self.m_quickStashCurNaviIndex)
    end)
end
InventoryCtrl._RefreshQuickStash = HL.Method() << function(self)
    local canQuickStash = Utils.isInSafeZone()
    self.view.quickStashNode.gameObject:SetActive(canQuickStash)
end
InventoryCtrl._QuickStash = HL.Method() << function(self)
    if not DeviceInfo.usingController then
        self:_ToggleQuickStashSetting(false)
    end
    if Utils.isDepotManualInOutLocked() then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_DEPOT_MANUAL_IN_OUT_LOCKED)
        return
    end
    local stashItemIndexList = {}
    local validTypes = {}
    local typeList = {}
    for _, info in ipairs(self.m_quickStashSettingInfo) do
        if info.isOn then
            local showingType = info.showingType
            if not info.extraCheckFunc then
                validTypes[showingType] = true
            else
                if not validTypes[showingType] then
                    validTypes[showingType] = { info.extraCheckFunc }
                else
                    table.insert(validTypes[showingType], info.extraCheckFunc)
                end
            end
            table.insert(typeList, tostring(info.showingType))
        end
    end
    for index, itemBundle in pairs(GameInstance.player.inventory.itemBag:GetOrFallback(Utils.getCurrentScope()).slots) do
        local id = itemBundle.id
        if not string.isEmpty(id) then
            local itemData = Tables.itemTable:GetValue(id)
            local valid = validTypes[itemData.showingType]
            if valid then
                if valid == true then
                    table.insert(stashItemIndexList, index)
                else
                    for _, func in ipairs(valid) do
                        if func(id) then
                            table.insert(stashItemIndexList, index)
                            break
                        end
                    end
                end
            end
        end
    end
    if #stashItemIndexList == 0 then
        return
    end
    self.view.itemBag.itemBagContent:ReadCurShowingItems()
    self.view.depot.depotContent:ReadCurShowingItems()
    GameInstance.player.inventory:ItemBagMoveToFactoryDepot(Utils.getCurrentScope(), Utils.getCurrentChapterId(), stashItemIndexList)
    EventLogManagerInst:GameEvent_BagBatchManage(typeList)
end
InventoryCtrl._ToggleQuickStashSettingCell = HL.Method(HL.Number, HL.Opt(HL.Boolean)) << function(self, index, active)
    local info = self.m_quickStashSettingInfo[index]
    if active == nil then
        active = not info.isOn
    end
    info.isOn = active
    local keyName = "Inventory.QuickStash.Tab." .. index
    Unity.PlayerPrefs.SetInt(keyName, active and 1 or 0)
end
InventoryCtrl._ToggleQuickStashSetting = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, active, noAnimation)
    local quickStashNode = self.view.quickStashNode
    quickStashNode.autoCloseArea.enabled = active
    if quickStashNode.settingList.gameObject.activeSelf == active then
        return
    end
    quickStashNode.settingList.transform:DOKill()
    if noAnimation then
        quickStashNode.settingList.gameObject:SetActive(active)
    else
        quickStashNode.settingList.gameObject:SetActive(true)
        if active then
            quickStashNode.settingList:PlayInAnimation()
        else
            quickStashNode.settingList:PlayOutAnimation(function()
                quickStashNode.settingList.gameObject:SetActive(false)
            end)
        end
    end
    quickStashNode.closeBtn.gameObject:SetActive(active)
    quickStashNode.confirmBtnIcon.gameObject:SetActive((not active) or (not DeviceInfo.usingController))
    if active and DeviceInfo.usingController then
        InputManagerInst:ToggleGroup(self.m_quickStashNaviBindingGroupId, true)
        self.m_quickStashCurNaviIndex = 1
        Notify(MessageConst.SHOW_AS_CONTROLLER_SMALL_MENU, { panelId = PANEL_ID, isGroup = true, id = quickStashNode.inputBindingGroupMonoTarget.groupId, hintPlaceholder = self.view.controllerHintPlaceholder, rectTransform = quickStashNode.settingList.transform, })
    else
        InputManagerInst:ToggleGroup(self.m_quickStashNaviBindingGroupId, false)
        self.m_quickStashCurNaviIndex = -1
        Notify(MessageConst.CLOSE_CONTROLLER_SMALL_MENU, PANEL_ID)
    end
    self:_RefreshQuickStashNaviSelected()
    AudioAdapter.PostEvent(active and "au_ui_menu_sequence_open" or "au_ui_menu_sequence_close")
end
InventoryCtrl.m_inDestroyMode = HL.Field(HL.Boolean) << false
InventoryCtrl.m_showingDestroyItemCSIndex = HL.Field(HL.Number) << -1
InventoryCtrl.m_destroyInfo = HL.Field(HL.Table)
InventoryCtrl._InitDestroyNode = HL.Method() << function(self)
    self.view.destroyBtn.onClick:AddListener(function()
        self:_ToggleDestroyMode(true)
    end)
    local node = self.view.destroyNode
    node.gameObject:SetActive(false)
    node.backBtn.onClick:AddListener(function()
        self:_ToggleDestroyMode(false)
    end)
    node.confirmBtn.onClick:AddListener(function()
        self:_ConfirmDestroy()
    end)
    self.m_destroyInfo = {}
    self:_ToggleDestroyMode(false, true)
end
InventoryCtrl._UpdateItemBlockMask = HL.Method(HL.Any, HL.Number) << function(self, cell, csIndex)
    cell.view.dragItem.disableDrag = self.m_inDestroyMode
    local button = cell.item.view.button
    local showMask = false
    if self.m_inDestroyMode then
        local inventory = GameInstance.player.inventory
        local itemBundle = inventory.itemBag:GetOrFallback(Utils.getCurrentScope()).slots[csIndex]
        if not string.isEmpty(itemBundle.id) then
            showMask = not inventory:CanDestroyItem(Utils.getCurrentScope(), itemBundle.id)
        end
        button.clickHintTextId = self.m_destroyInfo[csIndex] and "virtual_mouse_hint_unselect" or "virtual_mouse_hint_select"
        button.longPressHintTextId = nil
    else
        button.clickHintTextId = DeviceInfo.usingController and "key_hint_item_open_action_menu" or "virtual_mouse_hint_item_tips"
        button.longPressHintTextId = "virtual_mouse_hint_drag"
        cell.item.view.destroySelectNode.gameObject:SetActive(false)
    end
    InputManagerInst:SetBindingText(button.hoverConfirmBindingId, Language[button.clickHintTextId])
    cell.view.blockMask.gameObject:SetActiveIfNecessary(showMask)
end
InventoryCtrl._ToggleDestroyMode = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, active, noAnimation)
    self.view.closeButton.gameObject:SetActive(not active)
    if noAnimation then
        if active then
            self.view.itemBagNode:SampleToInAnimationEnd()
        else
            self.view.itemBagNode:SampleToOutAnimationEnd()
        end
        self.view.itemBagButtons.gameObject:SetActive(not active)
        self.view.destroyNode.gameObject:SetActive(active)
    else
        if active then
            self.view.itemBagNode:PlayInAnimation()
        else
            self.view.itemBagNode:PlayOutAnimation()
        end
        AudioAdapter.PostEvent(active and "au_ui_menu_destroy_open" or "au_ui_menu_destroy_close")
    end
    self.view.itemBag.itemBagContent.view.itemListSelectableNaviGroup.enablePartner = not active
    self.view.itemBag.itemBagContent.view.itemList:SetPaddingBottom(active and self.m_oriPaddingBottom + 100 or self.m_oriPaddingBottom)
    if active then
        self.m_destroyInfo = {}
        self.m_showingDestroyItemCSIndex = -1
        self.view.destroyNode.confirmBtn.gameObject:SetActive(false)
        Notify(MessageConst.SHOW_AS_CONTROLLER_SMALL_MENU, { panelId = PANEL_ID, isGroup = true, id = self.view.itemBagNodeInputBindingGroupMonoTarget.groupId, hintPlaceholder = self.view.destroyNode.controllerHintPlaceholder, rectTransform = self.view.destroyNode.transform, noHighlight = true, })
    else
        local info = self.m_destroyInfo
        self.m_destroyInfo = {}
        for csIndex, _ in pairs(info) do
            self:_UpdateItemDestroySelect(csIndex)
        end
        Notify(MessageConst.CLOSE_CONTROLLER_SMALL_MENU, PANEL_ID)
    end
    self.m_inDestroyMode = active
    for k = 1, GameInstance.player.inventory.itemBag:GetOrFallback(Utils.getCurrentScope()).slotCount do
        local cell = self.view.itemBag.itemBagContent:GetCell(k)
        if cell then
            self:_UpdateItemBlockMask(cell, CSIndex(k))
        end
    end
    self.m_naviGroupSwitcher:ToggleActive(not active)
end
InventoryCtrl._OnClickItemInDestroyMode = HL.Method(HL.Number) << function(self, csIndex)
    if self.m_destroyInfo[csIndex] then
        self.m_destroyInfo[csIndex] = nil
        self:_UpdateItemDestroySelect(csIndex)
        if self.m_showingDestroyItemCSIndex >= 0 then
            self.m_showingDestroyItemCSIndex = -1
        end
    else
        local inventory = GameInstance.player.inventory
        local itemBundle = inventory.itemBag:GetOrFallback(Utils.getCurrentScope()).slots[csIndex]
        if inventory:CanDestroyItem(Utils.getCurrentScope(), itemBundle.id) then
            self.m_destroyInfo[csIndex] = itemBundle.count
            self:_UpdateItemDestroySelect(csIndex)
            if self.m_showingDestroyItemCSIndex < 0 then
            end
            self.m_showingDestroyItemCSIndex = csIndex
        else
            Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_CANT_DROP_BECAUSE_TYPE)
            if self.m_showingDestroyItemCSIndex >= 0 then
                self.m_showingDestroyItemCSIndex = -1
            end
        end
    end
    self.view.destroyNode.confirmBtn.gameObject:SetActive(next(self.m_destroyInfo) ~= nil)
end
InventoryCtrl._UpdateItemDestroySelect = HL.Method(HL.Number, HL.Opt(HL.Any)) << function(self, csIndex, cell)
    if not cell then
        cell = self.view.itemBag.itemBagContent:GetCell(LuaIndex(csIndex))
        if not cell then
            return
        end
    end
    local itemBundle = GameInstance.player.inventory.itemBag:GetOrFallback(Utils.getCurrentScope()).slots[csIndex]
    local selectCount = self.m_destroyInfo[csIndex]
    if selectCount then
        cell.item.view.destroySelectNode.gameObject:SetActive(true)
        cell.item.view.button.clickHintTextId = "virtual_mouse_hint_unselect"
    else
        cell.item.view.destroySelectNode.gameObject:SetActive(false)
        cell.item.view.button.clickHintTextId = "virtual_mouse_hint_select"
    end
end
InventoryCtrl._OnChangeItemDestroyCount = HL.Method(HL.Number, HL.Number) << function(self, csIndex, newCount)
    self.m_destroyInfo[csIndex] = newCount
    self:_UpdateItemDestroySelect(csIndex)
end
InventoryCtrl._CustomOnUpdateItemBagCell = HL.Method(HL.Forward("ItemSlot"), HL.Opt(HL.Userdata, HL.Number)) << function(self, cell, itemBundle, csIndex)
    cell.item.view.button.onIsNaviTargetChanged = function(active)
        if active then
            self:_TryDisableHoverBindingOnEmptyItem(cell, itemBundle)
        end
    end
    self:_TryDisableHoverBindingOnEmptyItem(cell, itemBundle)
    cell.item.canDestroy = true
    cell.item.canSetQuickBar = true
    if cell.item.actionMenuArgs then
        cell.item.actionMenuArgs.extraButtons = { self.view.sortButton, self.view.destroyBtn }
    end
    if not itemBundle then
        cell.item.view.destroySelectNode.gameObject:SetActive(false)
        return
    end
    self:_UpdateItemBlockMask(cell, csIndex)
    if not self.m_inDestroyMode then
        if itemBundle.count and itemBundle.count > 0 then
            cell.item:AddHoverBinding("common_quick_drop", function()
                cell:QuickDrop()
            end)
        end
        return
    end
    self:_UpdateItemDestroySelect(csIndex, cell)
end
InventoryCtrl._TryDisableHoverBindingOnEmptyItem = HL.Method(HL.Forward("ItemSlot"), HL.Opt(HL.Userdata)) << function(self, cell, itemBundle)
    if not itemBundle or not itemBundle.count or itemBundle.count == 0 then
        InputManagerInst:ToggleBinding(cell.item.view.button.hoverConfirmBindingId, false)
        return
    end
end
InventoryCtrl._ConfirmDestroy = HL.Method() << function(self)
    Notify(MessageConst.HIDE_ITEM_TIPS)
    local inventory = GameInstance.player.inventory
    local items = {}
    for csIndex, _ in pairs(self.m_destroyInfo) do
        table.insert(items, csIndex)
    end
    inventory:AbandonItemInItemBag(Utils.getCurrentScope(), items)
end
InventoryCtrl._OnAbandonItem = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if not self.m_abandonValid then
        return
    end
    local inventory = GameInstance.player.inventory
    local itemId = dragHelper:GetId()
    if not inventory:CanDestroyItem(Utils.getCurrentScope(), itemId) then
        return
    end
    inventory:AbandonItemInItemBag(Utils.getCurrentScope(), { dragHelper.info.csIndex })
end
InventoryCtrl.OnItemBagAbandonInBagSucc = HL.Method() << function(self)
    if self.m_inDestroyMode then
        self:_ToggleDestroyMode(false)
    end
    Notify(MessageConst.SHOW_TOAST, Language.LUA_ABANDON_ITEM_IN_BAG_SUCC)
    AudioAdapter.PostEvent("Au_UI_Event_Inventory_Destory_Success")
end
InventoryCtrl.OnToggleAbandonDropValid = HL.Method(HL.Any) << function(self, args)
    self.m_abandonValid = unpack(args)
end
InventoryCtrl.OnOtherStartDragItem = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if self:IsHide() then
        return
    end
    if not DeviceInfo.usingController then
        self.view.itemBagButtons.alpha = self.view.config.DRAGGING_BUTTON_ALPHA
        self.view.depot.view.bottomNode.alpha = self.view.config.DRAGGING_BUTTON_ALPHA
    end
    if UIUtils.isTypeDropValid(dragHelper, UIConst.ABANDON_ITEM_DROP_ACCEPT_INFO) then
        self.view.abandonItemMask.gameObject:SetActive(true)
    end
end
InventoryCtrl.OnOtherEndDragItem = HL.Method(HL.Forward('UIDragHelper')) << function(self, dragHelper)
    if self:IsHide() then
        return
    end
    if not DeviceInfo.usingController then
        self.view.itemBagButtons.alpha = 1
        self.view.depot.view.bottomNode.alpha = 1
    end
    self.view.abandonItemMask.gameObject:SetActive(false)
end
InventoryCtrl.OnChangeThrowMode = HL.Method(HL.Table) << function(self, args)
    local data = unpack(args)
    local inThrowMode = data.valid
    if inThrowMode then
        self:_OnClickClose()
    end
end
InventoryCtrl.OnSystemUnlock = HL.Method(HL.Table) << function(self, arg)
    local systemIndex = unpack(arg)
    if systemIndex == GEnums.UnlockSystemType.ManualCraft then
        self.view.manualCraftBtn.gameObject:SetActive(true)
    end
end
InventoryCtrl.m_targetItemId = HL.Field(HL.String) << ''
InventoryCtrl._GotoItem = HL.Method(HL.String) << function(self, itemId)
    local index = GameInstance.player.inventory.itemBag:GetOrFallback(Utils.getCurrentScope()):GetFirstSlotIndex(itemId)
    if index >= 0 then
        local content = self.view.itemBag.itemBagContent
        local scrollList = content.view.itemList
        scrollList:SkipGraduallyShow()
        scrollList:ScrollToIndex(index, true)
        local cell = content.m_getCell(LuaIndex(index))
        if cell then
            self:_OnClickItem(itemId, cell, index)
        end
        return
    end
    local content = self.view.depot.depotContent
    if not content or not content.gameObject.activeInHierarchy then
        return
    end
    local scrollList = content.view.itemList
    local luaIndex = content:GetItemIndex(itemId)
    if luaIndex then
        scrollList:SkipGraduallyShow()
        scrollList:ScrollToIndex(CSIndex(luaIndex), true)
        local cell = content.m_getCell(luaIndex)
        if cell then
            content:_OnClickItem(luaIndex)
        end
    end
end
InventoryCtrl._OnClickSwitchDepot = HL.Method() << function(self)
    PhaseManager:OpenPhase(PhaseId.FacDepotSwitching)
end
InventoryCtrl.OnChangeSpaceshipDomainId = HL.Method(HL.Any) << function(self, _)
    self:_InitDepot()
end
HL.Commit(InventoryCtrl)