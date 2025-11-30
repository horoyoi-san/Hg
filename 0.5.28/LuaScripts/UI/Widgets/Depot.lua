local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
Depot = HL.Class('Depot', UIWidgetBase)
Depot.depotContent = HL.Field(HL.Forward("DepotContent"))
Depot.m_inInit = HL.Field(HL.Boolean) << false
Depot.m_inited = HL.Field(HL.Boolean) << false
Depot.m_curTypeIndex = HL.Field(HL.Number) << -1
Depot.m_itemShowingTypeInfos = HL.Field(HL.Table)
Depot.m_sortOptions = HL.Field(HL.Table)
Depot.m_nonValidShowTypes = HL.Field(HL.Table)
Depot.m_typeCells = HL.Field(HL.Forward('UIListCache'))
Depot.m_valuableDepotType = HL.Field(GEnums.ItemValuableDepotType)
Depot.m_onClickItemAction = HL.Field(HL.Function)
Depot.m_onToggleDestroyMode = HL.Field(HL.Function)
Depot.m_onChangeTypeFunction = HL.Field(HL.Function)
Depot.m_oriPaddingBottom = HL.Field(HL.Number) << 0
Depot._OnFirstTimeInit = HL.Override() << function(self)
    self.m_typeCells = UIUtils.genCellCache(self.view.typeCell)
    self.depotContent = self.view.depotContent
    local canDes = self.view.config.CAN_DESTROY
    self.view.destroyBtn.gameObject:SetActive(canDes)
    self.view.destroyNode.gameObject:SetActive(false)
    if canDes then
        self:_InitDestroyNode()
    end
    self.m_oriPaddingBottom = self.depotContent.view.itemList:GetPadding().bottom
    self.view.sortNode:InitSortNode(self.m_sortOptions, function(optData, isIncremental)
        self:_OnSortChanged(optData, isIncremental)
    end, nil, nil, true)
end
Depot.InitDepot = HL.Method(GEnums.ItemValuableDepotType, HL.Opt(HL.Function, HL.Table)) << function(self, valuableDepotType, onClickItemAction, otherArgs)
    self.m_sortOptions = otherArgs.sortOptions or UIConst.FAC_DEPOT_SORT_OPTIONS
    self:_FirstTimeInit()
    self.m_inInit = true
    otherArgs = otherArgs or {}
    self.m_nonValidShowTypes = otherArgs.nonValidShowTypes
    self.m_valuableDepotType = valuableDepotType
    self:_RefreshShowingType()
    local domainId = Utils.getCurDomainId()
    if otherArgs.domainId ~= nil then
        domainId = otherArgs.domainId
    end
    local succ, domainData = Tables.domainDataTable:TryGetValue(domainId)
    if succ then
        self.view.titleTxt.text = domainData.storageName
    else
        self.view.titleTxt.text = Language.LUA_BLACK_BOX_DEPOT_NAME
    end
    self.m_onClickItemAction = onClickItemAction
    self.m_onToggleDestroyMode = otherArgs.onToggleDestroyMode
    self.m_onChangeTypeFunction = otherArgs.onChangeTypeFunction
    otherArgs.showingTypes = self.m_itemShowingTypeInfos[self.m_curTypeIndex].types
    otherArgs.isIncremental = self.view.sortNode.isIncremental
    otherArgs.sortKeys = self.view.sortNode:GetCurSortKeys()
    otherArgs.beforeFindAndHighlightForDrop = function(id)
        local itemData = Tables.itemTable[id]
        local showingTypes = self.m_itemShowingTypeInfos[self.m_curTypeIndex].types
        if showingTypes and not lume.find(showingTypes, itemData.showingType) then
            for k, info in ipairs(self.m_itemShowingTypeInfos) do
                if info.types and lume.find(info.types, itemData.showingType) then
                    self.m_typeCells:Get(k).toggle.isOn = true
                    return
                end
            end
        end
    end
    local externalCustomOnUpdateCell = otherArgs.customOnUpdateCell
    otherArgs.customOnUpdateCell = function(cell, info, luaIndex)
        self:_CustomOnUpdateCell(cell, info)
        if externalCustomOnUpdateCell then
            externalCustomOnUpdateCell(cell, info, luaIndex)
        end
    end
    self.depotContent:InitDepotContent(valuableDepotType, function(itemId, cell)
        self:_OnClickItem(itemId, cell)
    end, otherArgs)
    self.m_inInit = false
    self.m_inited = true
end
Depot._RefreshShowingType = HL.Method() << function(self)
    self.m_curTypeIndex = 1
    self.m_itemShowingTypeInfos = { { name = Language.LUA_FAC_ALL, icon = "icon_item_type_all", } }
    local showingTypes = UIConst.FACTORY_DEPOT_SHOWING_TYPES
    for _, v in ipairs(showingTypes) do
        if not self.m_nonValidShowTypes or not lume.find(self.m_nonValidShowTypes, v) then
            local data = Tables.itemShowingTypeTable:GetValue(v:ToInt())
            table.insert(self.m_itemShowingTypeInfos, { name = data.name, icon = data.icon, types = { data.type }, })
        end
    end
    self.view.typesNode.gameObject:SetActive(false)
    self.m_typeCells:Refresh(#self.m_itemShowingTypeInfos, function(cell, index)
        local info = self.m_itemShowingTypeInfos[index]
        local sprite = self:LoadSprite(UIConst.UI_SPRITE_INVENTORY, info.icon)
        cell.dimIcon.sprite = sprite
        cell.lightIcon.sprite = sprite
        if cell.name then
            cell.name.text = info.name
        end
        local isSelected = index == self.m_curTypeIndex
        cell.decoLine.gameObject:SetActive(not (isSelected or index == 1 or index == (self.m_curTypeIndex + 1)))
        self:_RefreshTypeCellSelectedState(cell, isSelected)
        cell.toggle.onValueChanged:RemoveAllListeners()
        cell.toggle.isOn = isSelected
        cell.toggle.onValueChanged:AddListener(function(isOn)
            if isOn and self.m_curTypeIndex ~= index then
                self.depotContent:ReadCurShowingItems()
                self:_OnClickShowingType(index)
            end
        end)
        cell.gameObject.name = "TypeCell_" .. index
    end)
    self.view.typesNode.gameObject:SetActive(true)
    self:_RefreshShowingTypeTitle()
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.typesNode.transform)
end
Depot._OnClickShowingType = HL.Method(HL.Number) << function(self, index)
    self.m_curTypeIndex = index
    local showingTypes = self.m_itemShowingTypeInfos[index].types
    self.depotContent:ChangeShowingType(showingTypes)
    if self.m_onChangeTypeFunction ~= nil then
        self.m_onChangeTypeFunction()
    end
    if InputManagerInst.controllerNaviManager:IsTopLayer(self.depotContent.view.itemListSelectableNaviGroup) then
        self:SetAsNaviTarget()
    end
    self.m_typeCells:Update(function(cell, k)
        cell.decoLine.gameObject:SetActive(not (k == self.m_curTypeIndex or k == 1 or k == (self.m_curTypeIndex + 1)))
        self:_RefreshTypeCellSelectedState(cell, k == index)
    end)
    self:_RefreshShowingTypeTitle()
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.typesNode.transform)
end
Depot.SetAsNaviTarget = HL.Method() << function(self)
    local cell = self.depotContent:GetCell(1)
    if cell then
        cell:SetAsNaviTarget()
    end
end
Depot._RefreshTypeCellSelectedState = HL.Method(HL.Any, HL.Boolean) << function(self, cell, isSelected)
    if cell == nil then
        return
    end
    cell.dimIcon.gameObject:SetActive(not isSelected)
    cell.lightNode.gameObject:SetActive(isSelected)
end
Depot._RefreshShowingTypeTitle = HL.Method() << function(self, index)
    local info = self.m_itemShowingTypeInfos[self.m_curTypeIndex]
    if info == nil then
        return
    end
    self.view.typeTitle.text = info.name
end
Depot._OnSortChanged = HL.Method(HL.Table, HL.Boolean) << function(self, optData, isIncremental)
    if self.m_inInit then
        return
    end
    self.depotContent.isIncremental = isIncremental
    if optData.reverseKeys and not isIncremental then
        self.depotContent.sortKeys = optData.reverseKeys
    else
        self.depotContent.sortKeys = optData.keys
    end
    self.depotContent:OnSortChanged()
end
Depot._OnClickItem = HL.Method(HL.String, HL.Opt(HL.Forward("ItemSlot"))) << function(self, itemId, cell)
    if self.m_onClickItemAction then
        self.m_onClickItemAction(itemId, cell)
        return
    end
    if string.isEmpty(itemId) then
        return
    end
    cell.item:Read()
    if not self.m_inDestroyMode then
        if DeviceInfo.usingController then
            cell.item:ShowActionMenu()
        else
            cell.item.canPlace = true
            cell.item:ShowTips()
        end
        return
    end
    local count = self.depotContent:GetItemCount(itemId)
    if count == 0 then
        cell.item:ShowTips()
        return
    end
    local showTips = not self.m_destroyInfo[itemId]
    self:_ClickItemInDestroyMode(itemId)
    if showTips then
        local posInfo = { tipsPosType = UIConst.UI_TIPS_POS_TYPE.RightTop, tipsPosTransform = self.view.transform, safeArea = self.view.destroyNode.numberSelector.rectTransform, isSideTips = true, }
        cell.item.canPlace = false
        cell.item:ShowTips(posInfo, function()
            if self.m_curSelectedItemIdInDesMode == itemId then
                self.view.destroyNode.selectorNode:PlayOutAnimation()
                self.m_curSelectedItemIdInDesMode = ""
            end
        end)
    else
        if DeviceInfo.usingController then
            Notify(MessageConst.HIDE_ITEM_TIPS)
        end
    end
end
Depot.m_inDestroyMode = HL.Field(HL.Boolean) << false
Depot.m_destroyInfo = HL.Field(HL.Table)
Depot.m_curSelectedItemIdInDesMode = HL.Field(HL.String) << ""
Depot._InitDestroyNode = HL.Method() << function(self)
    self.view.destroyBtn.onClick:AddListener(function()
        self:ToggleDestroyMode(true, false)
    end)
    local node = self.view.destroyNode
    node.gameObject:SetActive(false)
    node.backBtn.onClick:AddListener(function()
        self:ToggleDestroyMode(false, false)
    end)
    node.confirmBtn.onClick:AddListener(function()
        self:_ConfirmDestroy()
    end)
    self.m_destroyInfo = {}
    self:ToggleDestroyMode(false, true)
end
Depot.ToggleDestroyMode = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, active, noAnimation)
    if not self.m_inited then
        return
    end
    local node = self.view.destroyNode
    local rootAni = self.view.content
    if active then
        if noAnimation then
            rootAni:SampleToInAnimationEnd()
        else
            rootAni:PlayInAnimation()
        end
    else
        if noAnimation then
            rootAni:SampleToOutAnimationEnd()
        else
            rootAni:PlayOutAnimation()
        end
    end
    self.depotContent.view.itemListSelectableNaviGroup.enablePartner = not active
    self.depotContent.view.itemList:SetPaddingBottom(active and self.m_oriPaddingBottom + 100 or self.m_oriPaddingBottom)
    self.m_typeCells:Update(function(cell, _)
        if active then
            cell.animation:PlayOutAnimation()
        else
            cell.animation:PlayInAnimation()
        end
    end)
    self.m_inDestroyMode = active
    local panelId = self:GetPanelId()
    if not active then
        local info = self.m_destroyInfo
        self.m_destroyInfo = {}
        self.m_curSelectedItemIdInDesMode = ""
        if info then
            for itemId, _ in pairs(info) do
                self:_UpdateItemDestroySelect(itemId)
            end
        end
        Notify(MessageConst.CLOSE_CONTROLLER_SMALL_MENU, panelId)
    else
        self.m_destroyInfo = {}
        self.m_curSelectedItemIdInDesMode = ""
        self.view.destroyNode.selectorNode:SampleToOutAnimationEnd()
        self.view.destroyNode.confirmBtn.gameObject:SetActive(false)
        Notify(MessageConst.SHOW_AS_CONTROLLER_SMALL_MENU, { panelId = panelId, isGroup = true, id = self.view.inputBindingGroupMonoTarget.groupId, hintPlaceholder = self.view.destroyNode.controllerHintPlaceholder, rectTransform = node.transform, noHighlight = true, })
    end
    local content = self.depotContent
    content.view.itemList:UpdateShowingCells(function(csIndex, obj)
        local cell = content.m_getCell(obj)
        local info = content.m_itemInfoList[LuaIndex(csIndex)]
        if info then
            self:_UpdateItemBlockMask(cell, info)
        end
    end)
    if self.m_onToggleDestroyMode then
        self.m_onToggleDestroyMode(active)
    end
end
Depot._UpdateItemBlockMask = HL.Method(HL.Any, HL.Table) << function(self, cell, info)
    cell.view.dragItem.disableDrag = self.m_inDestroyMode
    local showMask = false
    local id = info.id
    local button = cell.item.view.button
    if self.m_inDestroyMode then
        local inventory = GameInstance.player.inventory
        if not string.isEmpty(id) then
            showMask = not inventory:CanDestroyItem(Utils.getCurrentScope(), id) or FactoryUtils.isItemInfiniteInFactoryDepot(id)
        end
        button.clickHintTextId = self.m_destroyInfo[id] and "virtual_mouse_hint_unselect" or "virtual_mouse_hint_select"
        button.longPressHintTextId = nil
    else
        button.clickHintTextId = DeviceInfo.usingController and "key_hint_item_open_action_menu" or "virtual_mouse_hint_item_tips"
        button.longPressHintTextId = "virtual_mouse_hint_drag"
        cell.view.destroySelectNode.gameObject:SetActive(false)
    end
    InputManagerInst:SetBindingText(button.hoverConfirmBindingId, Language[button.clickHintTextId])
    cell.view.blockMask.gameObject:SetActiveIfNecessary(showMask)
end
Depot._ClickItemInDestroyMode = HL.Method(HL.String) << function(self, itemId)
    if self.m_destroyInfo[itemId] then
        self.m_destroyInfo[itemId] = nil
        self:_UpdateItemDestroySelect(itemId)
        if not string.isEmpty(self.m_curSelectedItemIdInDesMode) then
            self.view.destroyNode.selectorNode:PlayOutAnimation()
            self.m_curSelectedItemIdInDesMode = ""
        end
    else
        local inventory = GameInstance.player.inventory
        if inventory:CanDestroyItem(Utils.getCurrentScope(), itemId) then
            local count = self.depotContent:GetItemCount(itemId)
            self.m_destroyInfo[itemId] = count
            self:_UpdateItemDestroySelect(itemId)
            self.view.destroyNode.numberSelector:InitNumberSelector(count, 1, count, function(newCount)
                self:_OnChangeItemDestroyCount(itemId, newCount)
            end)
            if string.isEmpty(self.m_curSelectedItemIdInDesMode) then
                self.view.destroyNode.selectorNode:PlayInAnimation()
            end
            self.m_curSelectedItemIdInDesMode = itemId
        else
            if not string.isEmpty(self.m_curSelectedItemIdInDesMode) then
                self.view.destroyNode.selectorNode:PlayOutAnimation()
                self.m_curSelectedItemIdInDesMode = ""
            end
            Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_CANT_DESTROY_BECAUSE_TYPE)
        end
    end
    self.view.destroyNode.confirmBtn.gameObject:SetActive(next(self.m_destroyInfo) ~= nil)
end
Depot._UpdateItemDestroySelect = HL.Method(HL.String, HL.Opt(HL.Forward("ItemSlot"))) << function(self, itemId, cell)
    local index = self.depotContent:GetItemIndex(itemId)
    if not cell then
        cell = self.depotContent:GetCell(index)
        if not cell then
            return
        end
    end
    local totalCount = self.depotContent:GetItemCount(itemId)
    local selectCount = self.m_destroyInfo[itemId]
    if selectCount then
        cell.view.destroySelectNode.gameObject:SetActive(true)
        cell.item.view.count.text = string.format(UIConst.COLOR_STRING_FORMAT, UIConst.COUNT_RED_COLOR_STR, UIUtils.getNumString(selectCount))
        cell.item.view.button.clickHintTextId = "virtual_mouse_hint_unselect"
    else
        cell.view.destroySelectNode.gameObject:SetActive(false)
        cell.item:UpdateCount(totalCount)
        cell.item.view.button.clickHintTextId = "virtual_mouse_hint_select"
    end
end
Depot._OnChangeItemDestroyCount = HL.Method(HL.String, HL.Number) << function(self, itemId, newCount)
    self.m_destroyInfo[itemId] = newCount
    self:_UpdateItemDestroySelect(itemId)
end
Depot._CustomOnUpdateCell = HL.Method(HL.Forward("ItemSlot"), HL.Table) << function(self, cell, info)
    cell.item.view.button.onIsNaviTargetChanged = function(active)
        if active then
            self:_TryDisableHoverBindingOnEmptyItem(cell, info)
        end
    end
    self:_TryDisableHoverBindingOnEmptyItem(cell, info)
    if self.view.config.CAN_DESTROY then
        cell.item.canDestroy = true
        if cell.item.actionMenuArgs then
            cell.item.actionMenuArgs.extraButtons = { self.view.destroyBtn }
        end
    end
    self:_UpdateItemBlockMask(cell, info)
    if not self.m_inDestroyMode then
        return
    end
    self:_UpdateItemDestroySelect(info.id, cell)
end
Depot._TryDisableHoverBindingOnEmptyItem = HL.Method(HL.Forward("ItemSlot"), HL.Opt(HL.Any)) << function(self, cell, itemBundle)
    if not itemBundle or not itemBundle.count or itemBundle.count == 0 then
        InputManagerInst:ToggleBinding(cell.item.view.button.hoverConfirmBindingId, false)
        return
    end
end
Depot._ConfirmDestroy = HL.Method() << function(self)
    local items = {}
    for id, count in pairs(self.m_destroyInfo) do
        table.insert(items, { id = id, count = count, })
    end
    table.sort(items, Utils.genSortFunction({ "id" }, true))
    Notify(MessageConst.SHOW_POP_UP, {
        content = Language.LUA_DESTROY_ITEM_CONFIRM_TEXT,
        warningContent = Language.LUA_DESTROY_ITEM_CONFIRM_WARNING_TEXT,
        items = items,
        onConfirm = function()
            GameInstance.player.inventory:DestroyInFactoryDepot(Utils.getCurrentScope(), Utils.getCurrentChapterId(), self.m_destroyInfo)
            self:ToggleDestroyMode(false, false)
        end,
    })
end
HL.Commit(Depot)
return Depot