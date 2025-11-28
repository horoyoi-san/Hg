local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
InventoryArea = HL.Class('InventoryArea', UIWidgetBase)
InventoryArea.m_opening = HL.Field(HL.Boolean) << false
InventoryArea.m_dataInited = HL.Field(HL.Boolean) << false
InventoryArea.m_isItemBag = HL.Field(HL.Boolean) << true
InventoryArea.m_args = HL.Field(HL.Table)
InventoryArea.m_inSafeZone = HL.Field(HL.Boolean) << false
InventoryArea.m_cellValidStateCache = HL.Field(HL.Table)
InventoryArea.m_isDepotLocked = HL.Field(HL.Boolean) << false
InventoryArea._OnFirstTimeInit = HL.Override() << function(self)
    self.view.itemBagBtn.onClick:AddListener(function()
        self:_Show(true)
    end)
    self.view.depotBtn.onClick:AddListener(function()
        self:_Show(false)
    end)
    self.view.itemDropAreaBtn.onClick:AddListener(function()
        self:_Show(true)
    end)
    self.view.depotDropAreaBtn.onClick:AddListener(function()
        self:_Show(false)
    end)
    self:RegisterMessage(MessageConst.ON_START_UI_DRAG, function(dragHelper)
        if UIUtils.isTypeDropValid(dragHelper, UIConst.ITEM_BAG_DROP_ACCEPT_INFO) then
            if not self.m_opening then
                local dataInited = self.m_dataInited
                if not dataInited then
                    self.view.itemBag.view.itemBagContent:OnStartUiDrag(dragHelper)
                    self.view.depot.view.depotContent:OnStartUiDrag(dragHelper)
                end
            end
        end
    end)
    UIUtils.initUIDropHelper(self.view.itemDropArea, {
        acceptTypes = UIConst.ITEM_BAG_DROP_ACCEPT_INFO,
        onToggleHighlight = function(active)
            if active then
                self:_OnDropOnArea(true)
            end
        end,
    })
    UIUtils.initUIDropHelper(self.view.depotDropArea, {
        acceptTypes = UIConst.FACTORY_DEPOT_DROP_ACCEPT_INFO,
        onToggleHighlight = function(active)
            if active then
                self:_OnDropOnArea(false)
            end
        end,
    })
    self:_RegisterPlayAnimationOut()
end
InventoryArea.InitInventoryArea = HL.Method(HL.Opt(HL.Table)) << function(self, args)
    self:_FirstTimeInit()
    self.m_inSafeZone = Utils.isInSafeZone()
    self.m_cellValidStateCache = {}
    self.m_opening = false
    self.m_isItemBag = true
    self.m_args = args or {}
    self.view.content.gameObject:SetActiveIfNecessary(true)
    self:_Show(true, true)
    self:_InitDepotLockInBlackbox()
end
InventoryArea._Hide = HL.Method() << function(self)
    self.m_opening = false
    self.view.content.gameObject:SetActive(false)
    local uiCtrl = self:GetUICtrl()
    if uiCtrl.view.blockMask then
        uiCtrl.view.blockMask.gameObject:SetActive(false)
    end
end
InventoryArea._Show = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, isItemBag, forceUpdate)
    if not isItemBag and not self.m_inSafeZone then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_CANT_OPEN_FAC_DEPOT_IN_NON_SAFE_ZONE)
        return
    end
    if isItemBag == self.m_isItemBag and not forceUpdate then
        return
    end
    local fastMode = not self.m_opening
    self.m_opening = true
    self:_InitData()
    self:_SwitchTo(isItemBag, fastMode)
    if self.m_args.onStateChange then
        self.m_args.onStateChange(true)
    end
    self.view.content.gameObject:SetActive(true)
    local uiCtrl = self:GetUICtrl()
    if uiCtrl.view.blockMask then
        uiCtrl.view.blockMask.gameObject:SetActive(true)
    end
    self.view.itemBag.view.itemBagContent:ToggleCanQuickDrop(true)
    self.view.depot.view.depotContent:ToggleQuickAcceptDrop(true)
    self.m_isItemBag = isItemBag
end
InventoryArea._SwitchTo = HL.Method(HL.Boolean, HL.Boolean) << function(self, isItemBag, fastMode)
    local anim
    if self.m_inSafeZone then
        anim = isItemBag and "ui_storage_area_expand_down" or "ui_storage_area_expand_up"
    else
        anim = "ui_storage_area_expand_only_bag"
    end
    if fastMode then
        self.view.content:SampleClipAtPercent(anim, 1)
    else
        self.view.content:PlayWithTween(anim)
    end
    self.view.itemBag.itemBagContent.view.quickDropButton.enabled = isItemBag
    if self.m_inSafeZone then
        self.view.depot.depotContent.view.quickDropButton.enabled = not isItemBag
    end
    if isItemBag then
        if self.view.itemBag.view.forbiddenMask.gameObject.activeSelf then
            self.view.itemBag.view.forbiddenMask:PlayInAnimation()
        end
    else
        if self.view.depot.view.forbiddenMask.gameObject.activeSelf then
            self.view.depot.view.forbiddenMask:PlayInAnimation()
        end
    end
end
InventoryArea._TryDisableHoverBindingOnEmptyItem = HL.Method(HL.Forward("ItemSlot"), HL.Opt(HL.Userdata)) << function(self, cell, itemBundle)
    if not itemBundle or not itemBundle.count or itemBundle.count == 0 then
        InputManagerInst:ToggleBinding(cell.item.view.button.hoverConfirmBindingId, false)
        return
    end
end
InventoryArea._InitData = HL.Method() << function(self)
    if self.m_dataInited then
        return
    end
    self.view.itemBag:InitItemBag(function(itemId, cell, csIndex)
        self:_OnClickItem(itemId, cell, csIndex)
    end, {
        canSplit = true,
        canClear = true,
        customOnUpdateCell = function(cell, itemBundle, csIndex)
            self:_RefreshItemSlotCellValidState(cell, itemBundle)
            if self.m_args.customOnUpdateCell ~= nil then
                self.m_args.customOnUpdateCell(cell, itemBundle)
            end
            cell.item.view.button.onIsNaviTargetChanged = function(active)
                if active then
                    self:_TryDisableHoverBindingOnEmptyItem(cell, itemBundle)
                end
            end
            self:_TryDisableHoverBindingOnEmptyItem(cell, itemBundle)
            InputManagerInst:SetBindingText(cell.item.view.button.hoverConfirmBindingId, Language["key_hint_item_open_action_menu"])
            if itemBundle and itemBundle.count and itemBundle.count > 0 then
                cell.item:AddHoverBinding("common_quick_drop", function()
                    cell:QuickDrop()
                end)
            end
        end,
    })
    if self.m_inSafeZone then
        self.view.depot:InitDepot(GEnums.ItemValuableDepotType.Factory, function(itemId, cell)
            self:_OnClickItem(itemId, cell)
        end, {
            canClear = true,
            customOnUpdateCell = function(cell, itemBundle, luaIndex)
                self:_RefreshItemSlotCellValidState(cell, itemBundle)
                if self.m_args.customOnUpdateCell ~= nil then
                    self.m_args.customOnUpdateCell(cell, itemBundle)
                end
                if itemBundle.count and itemBundle.count > 0 then
                    cell.item:AddHoverBinding("common_quick_drop", function()
                        cell:QuickDrop()
                    end)
                end
            end,
        })
    end
    self.m_dataInited = true
end
InventoryArea._OnValueChanged = HL.Method(HL.Boolean) << function(self, isOn)
    if isOn == self.m_opening then
        return
    end
    if isOn then
        self:_Show(self.m_isItemBag)
    else
        self:_Hide()
    end
end
InventoryArea._OnDropOnArea = HL.Method(HL.Boolean) << function(self, isItemBag)
    if isItemBag ~= self.m_isItemBag then
        self:_Show(isItemBag)
    end
end
InventoryArea._OnDestroy = HL.Override() << function(self)
    if not self.m_dataInited then
        return
    end
    self.view.itemBag.itemBagContent:ReadCurShowingItems()
    if self.m_inSafeZone then
        self.view.depot.depotContent:ReadCurShowingItems()
    end
end
InventoryArea.PlayAnimationOut = HL.Override() << function(self)
    self:_Hide()
end
InventoryArea.AddNaviGroupSwitchInfo = HL.Method(HL.Table) << function(self, naviGroupInfos)
    table.insert(naviGroupInfos, {
        naviGroup = self.view.itemBag.itemBagContent.view.itemListSelectableNaviGroup,
        text = Language.LUA_INV_NAVI_SWITCH_TO_ITEM_BAG,
        beforeSwitch = function()
            self:_Show(true)
        end
    })
    if self.m_inSafeZone then
        table.insert(naviGroupInfos, {
            naviGroup = self.view.depot.depotContent.view.itemListSelectableNaviGroup,
            text = Language.LUA_INV_NAVI_SWITCH_TO_DEPOT,
            beforeSwitch = function()
                self:_Show(false)
            end
        })
    end
end
InventoryArea._OnClickItem = HL.Method(HL.String, HL.Forward('ItemSlot'), HL.Opt(HL.Number)) << function(self, itemId, cell, csIndex)
    cell.item:Read()
    if DeviceInfo.usingController then
        cell.item:ShowActionMenu()
    else
        cell.item:ShowTips()
    end
end
InventoryArea._RefreshItemSlotCellValidState = HL.Method(HL.Userdata, HL.Any) << function(self, cell, itemBundle)
    if itemBundle == nil then
        return
    end
    local itemId = itemBundle.id
    local isEmpty = string.isEmpty(itemId)
    if isEmpty then
        cell.view.forbiddenMask.gameObject:SetActive(false)
        cell.view.dragItem.enabled = false
        cell.view.dropItem.enabled = true
        return
    end
    if self.m_cellValidStateCache[itemId] == nil then
        local success, factoryItemData = Tables.factoryItemTable:TryGetValue(itemId)
        if not success then
            return
        end
        self.m_cellValidStateCache[itemId] = factoryItemData.buildingBufferStackLimit > 0
    end
    local isValid = self.m_cellValidStateCache[itemId]
    cell.view.forbiddenMask.gameObject:SetActive(not isValid)
    cell.view.dragItem.enabled = isValid
    cell.view.dropItem.enabled = isValid
end
InventoryArea._InitDepotLockInBlackbox = HL.Method() << function(self)
    local isLocked = Utils.isInBlackbox() and Utils.isDepotManualInOutLocked()
    self.view.depot.view.forbiddenMask.gameObject:SetActiveIfNecessary(isLocked)
    self.view.depot.view.depotContent:ToggleAcceptDrop(not isLocked)
    self.m_isDepotLocked = isLocked
end
InventoryArea.LockInventoryArea = HL.Method(HL.Boolean) << function(self, isLocked)
    local isDepotLocked = isLocked or self.m_isDepotLocked
    self.view.itemBag.view.forbiddenMask.gameObject:SetActiveIfNecessary(isLocked)
    self.view.depot.view.forbiddenMask.gameObject:SetActiveIfNecessary(isDepotLocked)
    self.view.itemBag.view.itemBagContent:ToggleCanDrop(not isLocked)
    self.view.depot.view.depotContent:ToggleAcceptDrop(not isDepotLocked)
end
HL.Commit(InventoryArea)
return InventoryArea