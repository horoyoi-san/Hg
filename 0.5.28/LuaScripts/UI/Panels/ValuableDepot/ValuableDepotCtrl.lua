local ItemType2DepotConfig = { [GEnums.ItemValuableDepotType.SpecialItem] = { infoProcessFuncName = "processItemDefault", isUnlocked = true, sortOptions = { { name = Language.LUA_DEPOT_SORT_OPTION_DEFAULT, keys = { "sortId1", "sortId2", "rarity", "id" }, }, { name = Language.LUA_DEPOT_SORT_OPTION_RARITY, keys = { "rarity", "sortId1", "sortId2", "id" }, }, }, isNormalDestroy = true, infoStateName = "default", }, [GEnums.ItemValuableDepotType.CommercialItem] = { infoProcessFuncName = "processItemDefault", isUnlocked = true, sortOptions = { { name = Language.LUA_DEPOT_SORT_OPTION_DEFAULT, keys = { "sortId1", "sortId2", "rarity", "id" }, }, { name = Language.LUA_DEPOT_SORT_OPTION_RARITY, keys = { "rarity", "sortId1", "sortId2", "id" }, }, }, infoStateName = "default", }, [GEnums.ItemValuableDepotType.MissionItem] = { infoProcessFuncName = "processItemDefault", isUnlocked = true, sortOptions = { { name = Language.LUA_DEPOT_SORT_OPTION_DEFAULT, keys = { "newOrder", "sortId1", "sortId2", "id" }, } }, infoStateName = "default", }, [GEnums.ItemValuableDepotType.Weapon] = { infoProcessFuncName = "processWeapon", systemUnlockType = GEnums.UnlockSystemType.Weapon, sortOptions = UIConst.WEAPON_SORT_OPTION, contentFilterOptionFuncName = "generateConfig_DEPOT_WEAPON", extraDisplayInfoFuncName = "displayWeaponInfo", infoStateName = "weapon", }, [GEnums.ItemValuableDepotType.WeaponGem] = { infoProcessFuncName = "processWeaponGem", systemUnlockType = GEnums.UnlockSystemType.Weapon, sortOptions = UIConst.WEAPON_GEM_SORT_OPTION, contentFilterOptionFuncName = "generateConfig_DEPOT_GEM", extraDisplayInfoFuncName = "displayWeaponGemInfo", infoStateName = "weaponGem", }, [GEnums.ItemValuableDepotType.Equip] = { infoProcessFuncName = "processEquip", systemUnlockType = GEnums.UnlockSystemType.Equip, sortOptions = { { name = Language.LUA_DEPOT_SORT_OPTION_RARITY, keys = { "rarity", "minWearLv", "sortId1", "sortId2", "id" }, }, }, contentFilterOptionFuncName = "generateConfig_DEPOT_EQUIP", destroyFilterOptionFuncName = "generateConfig_DEPOT_EQUIP_DESTROY", isEquipDestroy = true, extraDisplayInfoFuncName = "displayEquipInfo", infoStateName = "equip", }, }
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ValuableDepot
ValuableDepotCtrl = HL.Class('ValuableDepotCtrl', uiCtrl.UICtrl)
ValuableDepotCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_VALUABLE_DEPOT_CHANGED] = 'OnValuableDepotChanged', [MessageConst.ON_ITEM_LOCKED_STATE_CHANGED] = 'OnItemLockedStateChanged', [MessageConst.ON_EQUIP_RECYCLE] = 'OnEquipRecycle', }
ValuableDepotCtrl.m_curTabIndex = HL.Field(HL.Number) << 1
ValuableDepotCtrl.m_curItemIndex = HL.Field(HL.Number) << 1
ValuableDepotCtrl.m_inDestroyMode = HL.Field(HL.Boolean) << false
ValuableDepotCtrl.m_tabCells = HL.Field(HL.Forward('UIListCache'))
ValuableDepotCtrl.m_tabsInfo = HL.Field(HL.Table)
ValuableDepotCtrl.m_curTabAllItemList = HL.Field(HL.Table)
ValuableDepotCtrl.m_curShowItemList = HL.Field(HL.Table)
ValuableDepotCtrl.m_curShowCount = HL.Field(HL.Number) << 0
ValuableDepotCtrl.m_curContentFilterConfigs = HL.Field(HL.Table)
ValuableDepotCtrl.m_curDestroyFilterConfigs = HL.Field(HL.Table)
ValuableDepotCtrl.m_getItemCell = HL.Field(HL.Function)
ValuableDepotCtrl.m_selectItemInfoWhenHide = HL.Field(HL.Table)
ValuableDepotCtrl.m_selectTabInfoWhenHide = HL.Field(HL.Table)
ValuableDepotCtrl.m_oriPaddingBottom = HL.Field(HL.Number) << 0
ValuableDepotCtrl.OnCreate = HL.Override(HL.Any) << function(self, itemId)
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.ValuableDepot)
    end)
    self:BindInputPlayerAction("common_open_valuable_depot", function()
        PhaseManager:PopPhase(PhaseId.ValuableDepot)
    end, self.view.btnClose.groupId)
    self.m_readItemIds = {}
    self.m_readItemInstIds = {}
    self.m_getItemCell = UIUtils.genCachedCellFunction(self.view.itemScrollList)
    self.view.itemScrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateCell(self.m_getItemCell(obj), LuaIndex(csIndex))
    end)
    self.view.itemScrollList.onSelectedCell:AddListener(function(obj, csIndex)
        self:_OnClickItem(LuaIndex(csIndex), nil, true)
    end)
    self.view.itemScrollList.getCurSelectedIndex = function()
        return CSIndex(self.m_curItemIndex)
    end
    self.m_oriPaddingBottom = self.view.itemScrollList:GetPadding().bottom
    self.view.itemInfoNode.wikiBtn.onClick:AddListener(function()
        self:_ShowWiki()
    end)
    self.view.bottomNode.btnGemRecast.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.GemRecast)
    end)
    self.m_tabCells = UIUtils.genCellCache(self.view.tabs.tabCell)
    self:_InitItemInfoNavi()
    self:_InitDepotConfigs()
    self:_InitDestroyNode()
    self.view.itemInfoNode.wikiBtn.clickHintTextId = "virtual_mouse_hint_show_wiki"
    if DeviceInfo.usingController then
        InputManagerInst:SetVirtualMouseIconVisible(false)
    end
    self:_RefreshTabsInfo(itemId)
    self.view.walletBarPlaceholder:InitWalletBarPlaceholder(JsonConst.VALUABLE_DEPOT_MONEY_IDS)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
ValuableDepotCtrl.OnAnimationInFinished = HL.Override() << function(self)
    self.view.itemScrollList:MoveVirtualMouseToSelected()
end
ValuableDepotCtrl.OnShow = HL.Override() << function(self)
    if self.m_selectItemInfoWhenHide and self.m_selectTabInfoWhenHide then
        self:_RecollectItemBundles(self.m_selectTabInfoWhenHide.type)
        self:_RefreshTabsInfo(self.m_selectItemInfoWhenHide.id, self.m_selectItemInfoWhenHide.instId)
    end
end
ValuableDepotCtrl.OnHide = HL.Override() << function(self)
    local curSelectItemInfo = self.m_curShowItemList[self.m_curItemIndex]
    if curSelectItemInfo then
        self.m_selectItemInfoWhenHide = curSelectItemInfo
    end
    local curSelectTabInfo = self.m_tabsInfo[self.m_curTabIndex]
    if curSelectTabInfo then
        self.m_selectTabInfoWhenHide = curSelectTabInfo
    end
    if self.m_inDestroyMode then
        self:_ToggleDestroyMode(false, true)
    end
end
ValuableDepotCtrl.OnClose = HL.Override() << function(self)
    self:_ReadCurShowingItems()
end
ValuableDepotCtrl._InitDepotConfigs = HL.Method() << function(self)
    for _, config in pairs(ItemType2DepotConfig) do
        if config.contentFilterOptionFuncName then
            config.contentFilterOptions = FilterUtils[config.contentFilterOptionFuncName]()
        end
        if config.destroyFilterOptionFuncName then
            config.destroyFilterOptions = FilterUtils[config.destroyFilterOptionFuncName]()
        end
    end
end
ValuableDepotCtrl._RefreshTabsInfo = HL.Method(HL.Opt(HL.String, HL.Any)) << function(self, itemId, instId)
    local tabInfos = {}
    for _, v in pairs(Tables.valuableDepot) do
        if not v.isHidden and self:_CheckIfTabUnlocked(v.type) then
            table.insert(tabInfos, { type = v.type, data = v, name = v.name, sortId = v.sortId, icon = v.icon, })
        end
    end
    table.sort(tabInfos, Utils.genSortFunction({ "sortId" }, true))
    self.m_tabsInfo = tabInfos
    if itemId then
        local vType = Utils.getItemValuableDepotType(itemId)
        for k, v in ipairs(tabInfos) do
            if v.type == vType then
                self.m_curTabIndex = k
                break
            end
        end
    end
    self.m_tabCells:Refresh(#tabInfos, function(cell, index)
        local info = tabInfos[index]
        cell.defaultIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_INVENTORY, info.icon)
        cell.selectedIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_INVENTORY, info.icon)
        cell.toggle.onValueChanged:RemoveAllListeners()
        cell.toggle.isOn = index == self.m_curTabIndex
        cell.toggle.onValueChanged:AddListener(function(isOn)
            if isOn then
                if self.m_curTabIndex == index then
                    return
                end
                self:_ReadCurShowingItems()
                self:_OnClickTab(index)
            end
        end)
        cell.gameObject.name = "Tab-" .. info.type:GetHashCode()
    end)
    self:_OnClickTab(self.m_curTabIndex, itemId, instId)
end
ValuableDepotCtrl._OnClickTab = HL.Method(HL.Number, HL.Opt(HL.String, HL.Any)) << function(self, index, itemId, instId)
    local info = self.m_tabsInfo[index]
    self.m_curTabIndex = index
    self.m_curContentFilterConfigs = {}
    self.m_curDestroyFilterConfigs = {}
    local depotConfig = ItemType2DepotConfig[info.type]
    self.view.bottomNode.sortNode:InitSortNode(depotConfig.sortOptions, function(optData, isIncremental)
        self:_ApplySort(optData, isIncremental)
        self:_SetSelectedIndex()
        self:_RefreshItemList(true)
    end, 0, nil, true)
    self.view.bottomNode.filterBtn:InitFilterBtn({
        tagGroups = depotConfig.contentFilterOptions,
        selectedTags = self.m_curContentFilterConfigs,
        onConfirm = function(tags)
            self.m_curContentFilterConfigs = tags
            self.m_curItemIndex = 1
            self:_ApplyFilter()
            self:_ApplySort(self.view.bottomNode.sortNode:GetCurSortData(), self.view.bottomNode.sortNode.isIncremental)
            self:_SetSelectedIndex()
            self:_RefreshItemList(true)
        end,
        getResultCount = function(tags)
            return self:_GetContentFilterResultCount(tags)
        end,
    })
    self.view.bottomNode.filterBtn.gameObject:SetActive(depotConfig.contentFilterOptions and next(depotConfig.contentFilterOptions) ~= nil)
    self.view.bottomNode.btnGemRecast.gameObject:SetActive(info.type == GEnums.ItemValuableDepotType.WeaponGem)
    self.view.bottomNode.desEquipBtn.gameObject:SetActive(depotConfig.isEquipDestroy)
    self.view.bottomNode.destroyBtn.gameObject:SetActive(depotConfig.isNormalDestroy)
    self:_RecollectItemBundles(info.type)
    self.view.tabTitleTxt.text = info.name
    self.view.capacityTxt.text = string.format(Language.LUA_DEPOT_CAPACITY, #self.m_curTabAllItemList, info.data.gridLimit)
    if self.m_inDestroyMode then
        self.m_curItemIndex = -1
    else
        self:_SetSelectedIndex(itemId, instId)
    end
    self:_RefreshItemList(true, true)
end
ValuableDepotCtrl._RecollectItemBundles = HL.Method(HL.Any) << function(self, itemType)
    local allItems = self:_GetAllItemBundlesInDepot(itemType)
    self.m_curTabAllItemList = allItems
    self:_ApplyFilter()
    self:_ApplySort(self.view.bottomNode.sortNode:GetCurSortData(), self.view.bottomNode.sortNode.isIncremental)
end
ValuableDepotCtrl._SetSelectedIndex = HL.Method(HL.Opt(HL.Any, HL.Any)) << function(self, itemId, instId)
    if itemId then
        for k, v in ipairs(self.m_curShowItemList) do
            if v.id == itemId and (not instId or v.instId == instId) then
                self.m_curItemIndex = k
                break
            end
        end
    else
        if InputManagerInst.virtualMouseIconVisible then
            self.m_curItemIndex = -1
        else
            self.m_curItemIndex = math.min(1, self.m_curShowCount)
        end
    end
end
ValuableDepotCtrl._GetAllItemBundlesInDepot = HL.Method(HL.Opt(HL.Userdata, HL.Table)).Return(HL.Table) << function(self, depotType, rst)
    rst = rst or {}
    local depot = GameInstance.player.inventory.valuableDepots[depotType]:GetOrFallback(Utils.getCurrentScope())
    local depotConfig = ItemType2DepotConfig[depotType]
    local infoProcessFunc = FilterUtils[depotConfig.infoProcessFuncName]
    for id, bundle in pairs(depot.normalItems) do
        local info = infoProcessFunc(id)
        if info then
            info.count = bundle.count
            table.insert(rst, info)
        end
    end
    for instId, bundle in pairs(depot.instItems) do
        local info = infoProcessFunc(bundle.id, instId)
        if info then
            info.count = bundle.count
            table.insert(rst, info)
        end
    end
    return rst
end
ValuableDepotCtrl._ApplySort = HL.Method(HL.Table, HL.Boolean) << function(self, option, isIncremental)
    local curSelectItemInfo = self.m_curShowItemList[self.m_curItemIndex]
    table.sort(self.m_curTabAllItemList, Utils.genSortFunction(option.keys, isIncremental))
    table.sort(self.m_curShowItemList, Utils.genSortFunction(option.keys, isIncremental))
    for k, v in ipairs(self.m_curShowItemList) do
        if v == curSelectItemInfo then
            self.m_curItemIndex = k
            break
        end
    end
end
ValuableDepotCtrl._ApplyFilter = HL.Method() << function(self)
    local curTabAllItemList = self.m_curTabAllItemList
    local curFilterConfigs = self.m_curContentFilterConfigs
    if (not curFilterConfigs) or (not next(curFilterConfigs)) then
        self.m_curShowItemList = curTabAllItemList
        self.m_curShowCount = #curTabAllItemList
        return
    end
    local filteredItemList = {}
    for _, itemInfo in pairs(curTabAllItemList) do
        if FilterUtils.checkIfPassFilter(itemInfo, curFilterConfigs) then
            table.insert(filteredItemList, itemInfo)
        end
    end
    self.m_curShowItemList = filteredItemList
    self.m_curShowCount = #filteredItemList
end
ValuableDepotCtrl._GetContentFilterResultCount = HL.Method(HL.Table).Return(HL.Number) << function(self, tags)
    if not tags or not next(tags) then
        return
    end
    local count = 0
    for itemIndex, itemInfo in pairs(self.m_curTabAllItemList) do
        if FilterUtils.checkIfPassFilter(itemInfo, tags) then
            count = count + 1
        end
    end
    return count
end
ValuableDepotCtrl._RefreshItemList = HL.Method(HL.Opt(HL.Boolean, HL.Boolean)) << function(self, noRead, setTop)
    logger.info("_RefreshItemList")
    local count = #self.m_curShowItemList
    local isEmpty = count == 0
    self.view.itemScrollList:UpdateCount(count, setTop == true)
    self.view.emptyNode.gameObject:SetActive(isEmpty)
    self.view.itemScrollList.gameObject:SetActive(not isEmpty)
    self.view.itemInfoNode.gameObject:SetActive(not isEmpty)
    if isEmpty then
        self.view.itemInfoNode.animation:SampleToOutAnimationEnd()
    else
        self.view.itemInfoNode.animation:SampleToInAnimationEnd()
    end
    if not isEmpty then
        if self.m_inDestroyMode then
            self:_OnClickItem(-1)
        else
            self:_OnClickItem(self.m_curItemIndex, noRead)
        end
    end
end
ValuableDepotCtrl._OnUpdateCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local info = self.m_curShowItemList[index]
    local isEquip = info.data.type == GEnums.ItemType.Equip
    cell:InitItem(info, function()
        self:_OnClickItem(index)
    end)
    cell.view.button.onHoverChange:AddListener(function(active)
        if InputManagerInst.virtualMouseIconVisible then
            if active then
                self:_OnClickItem(index, nil, true)
            elseif self.m_curItemIndex == index then
                self:_OnClickItem(-1, nil, true)
            end
        end
    end)
    cell:SetSelected(index == self.m_curItemIndex)
    cell.view.imageCharMask.gameObject:SetActive(isEquip)
    if isEquip then
        local equipDepot = GameInstance.player.inventory.valuableDepots[GEnums.ItemValuableDepotType.Equip]:GetOrFallback(Utils.getCurrentScope())
        local equipInstDict = equipDepot.instItems
        local _, equipInst = equipInstDict:TryGetValue(info.instId)
        local equippedCardInstId = equipInst.instData.equippedCharServerId
        local isEquipped = equippedCardInstId and equippedCardInstId > 0
        cell.view.count.gameObject:SetActive(false)
        cell.view.imageCharMask.gameObject:SetActive(isEquipped)
        if isEquipped then
            local charEntityInfo = CharInfoUtils.getPlayerCharInfoByInstId(equippedCardInstId)
            local charTemplateId = charEntityInfo.templateId
            local spriteName = UIConst.UI_CHAR_HEAD_PREFIX .. charTemplateId
            cell.view.imageChar.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD, spriteName)
        end
    end
    local isWeapon = info.data.type == GEnums.ItemType.Weapon
    if isWeapon then
        local weaponDepot = GameInstance.player.inventory.valuableDepots[GEnums.ItemValuableDepotType.Weapon]:GetOrFallback(Utils.getCurrentScope())
        local weaponInstDict = weaponDepot.instItems
        local _, weaponInst = weaponInstDict:TryGetValue(info.instId)
        local equippedCardInstId = weaponInst.instData.equippedCharServerId
        local isEquipped = equippedCardInstId and equippedCardInstId > 0
        cell.view.count.gameObject:SetActive(false)
        cell.view.imageCharMask.gameObject:SetActive(isEquipped)
        if isEquipped then
            local charEntityInfo = CharInfoUtils.getPlayerCharInfoByInstId(equippedCardInstId)
            local charTemplateId = charEntityInfo.templateId
            local spriteName = UIConst.UI_CHAR_HEAD_PREFIX .. charTemplateId
            cell.view.imageChar.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD, spriteName)
        end
    end
    cell.gameObject.name = "Item-" .. info.id
    cell:UpdateRedDot()
    self:_UpdateItemBlockMask(cell, info)
    if cell.redDot.curIsActive then
        if info.instId then
            self.m_readItemInstIds[info.instId] = true
        else
            self.m_readItemIds[info.id] = true
        end
    end
    if not self.m_inDestroyMode then
        cell.view.multiSelectMark.gameObject:SetActive(false)
        cell.view.redMultiSelectMark.gameObject:SetActive(false)
        return
    end
    self:_UpdateItemCellDestroySelectPart(index, cell)
end
ValuableDepotCtrl._OnClickItem = HL.Method(HL.Number, HL.Opt(HL.Boolean, HL.Boolean)) << function(self, index, noRead, justNavi)
    if not noRead then
        self:_ReadItem(self.m_curItemIndex)
    end
    local cell = self.m_getItemCell(self.m_curItemIndex)
    if cell then
        cell:SetSelected(false)
    end
    local isSame = self.m_curItemIndex == index
    self.m_curItemIndex = index
    if index > 0 then
        cell = self.m_getItemCell(self.m_curItemIndex)
        if cell then
            cell:SetSelected(true)
        end
        if self.m_inDestroyMode then
            self:_ClickItemInDestroyMode(index, justNavi)
        end
    end
    self:_RefreshItemInfo(isSame)
    if index <= 0 then
        return
    end
    if not noRead then
        self:_ReadItem(index)
    end
    if DeviceInfo.usingController and not justNavi and isSame then
        if not self.m_inDestroyMode and not noRead then
            self:_ToggleItemInfoNavi(true)
        end
    end
end
ValuableDepotCtrl._AutoFillDestroyList = HL.Method(HL.Number) << function(self, tabIndex)
    self.m_destroyInfo[tabIndex] = {}
    self.m_destroyCount = 0
    local curFilterConfigs = self.m_curDestroyFilterConfigs
    if not curFilterConfigs or not next(curFilterConfigs) then
        return
    end
    local showItemList = self.m_curShowItemList
    local inventory = GameInstance.player.inventory
    local scope = Utils.getCurrentScope()
    local isLack = false
    for itemIndex, itemInfo in pairs(showItemList) do
        if self.m_destroyCount >= UIConst.DEPOT_DESTROY_MAX_COUNT then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_DEPOT_DES_AUTO_FILL_REACH_MAX)
            if isLack then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_DEPOT_DES_AUTO_FILL_HAS_LACK)
            end
            return
        end
        if FilterUtils.checkIfPassFilter(itemInfo, curFilterConfigs) then
            if not inventory:CanDestroyItem(scope, itemInfo.id) or inventory:IsEquipped(scope, itemInfo.id, itemInfo.instId) or inventory:IsItemLocked(scope, itemInfo.id, itemInfo.instId) then
                isLack = true
            else
                self:_MarkItemDestroy(itemIndex)
            end
        end
    end
    if isLack then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_DEPOT_DES_AUTO_FILL_HAS_LACK)
    end
end
ValuableDepotCtrl._GetAutoFillDestroyResultCount = HL.Method(HL.Table).Return(HL.Number) << function(self, tags)
    if not tags or not next(tags) then
        return
    end
    local count = 0
    for itemIndex, itemInfo in pairs(self.m_curShowItemList) do
        if FilterUtils.checkIfPassFilter(itemInfo, tags) then
            count = count + 1
        end
    end
    return count
end
ValuableDepotCtrl._RefreshItemInfo = HL.Method(HL.Boolean) << function(self, noAnimation)
    local node = self.view.itemInfoNode
    if self.m_curItemIndex < 0 then
        if noAnimation then
            node.animation:SampleToOutAnimationEnd()
            node.content.gameObject:SetActive(false)
            node.emptyNode.gameObject:SetActive(true)
        else
            node.animation:PlayOutAnimation(function()
                node.content.gameObject:SetActive(false)
                node.emptyNode.gameObject:SetActive(true)
            end)
        end
        return
    elseif self.m_curItemIndex == 0 then
        node.animation:SampleToOutAnimationEnd()
        node.content.gameObject:SetActive(false)
        node.emptyNode.gameObject:SetActive(true)
        return
    end
    node.content.gameObject:SetActive(true)
    node.emptyNode.gameObject:SetActive(false)
    if not noAnimation then
        node.animation:SampleToOutAnimationEnd()
        node.animation:PlayInAnimation()
    end
    local info = self.m_curShowItemList[self.m_curItemIndex]
    UIUtils.displayItemBasicInfos(node, self.loader, info.id, info.instId)
    node.itemDescNode:InitItemDescNode(info.id)
    self.view.itemInfoNode.wikiBtn.gameObject:SetActive(WikiUtils.canShowWikiEntry(info.id))
    local depotConfig = ItemType2DepotConfig[self.m_tabsInfo[self.m_curTabIndex].type]
    node.stateCtrl:SetState(depotConfig.infoStateName)
    if depotConfig.extraDisplayInfoFuncName then
        UIUtils[depotConfig.extraDisplayInfoFuncName](node, self.loader, info.id, info.instId)
    end
    local canJump, jumpFunction = self:_CheckIfCanJump(info.id, info.data.type, info.instId or 0)
    self.view.itemInfoNode.jumpBtn.gameObject:SetActive(canJump)
    self.view.itemInfoNode.jumpBtn.onClick:RemoveAllListeners()
    self.view.itemInfoNode.jumpBtn.onClick:AddListener(function()
        jumpFunction(self, info.id, info.instId or 0)
    end)
    node.itemObtainWays:InitItemObtainWays(info.id, info.instId)
    self.view.itemInfoNode.lockToggle:InitLockToggle(info.id, info.instId or 0)
    self.view.itemInfoNode.detailScroll:ScrollTo(Vector2(0, 0), false)
    local canUse, useFunc = self:_CheckIfCanUse(info.id)
    self.view.itemInfoNode.useBtn.gameObject:SetActive(canUse)
    self.view.itemInfoNode.useBtn.onClick:RemoveAllListeners()
    self.view.itemInfoNode.useBtn.onClick:AddListener(function()
        useFunc(self, info.id)
    end)
end
ValuableDepotCtrl._CheckIfTabUnlocked = HL.Method(HL.Userdata).Return(HL.Boolean) << function(self, itemType)
    local depotConfig = ItemType2DepotConfig[itemType]
    if depotConfig.isUnlocked ~= nil then
        return depotConfig.isUnlocked
    end
    if depotConfig.systemUnlockType then
        return Utils.isSystemUnlocked(depotConfig.systemUnlockType)
    end
    return false
end
ValuableDepotCtrl.OnValuableDepotChanged = HL.Method(HL.Table) << function(self, args)
    local depotType = unpack(args)
    if depotType ~= self.m_tabsInfo[self.m_curTabIndex].type then
        return
    end
    self:_OnClickTab(self.m_curTabIndex)
end
ValuableDepotCtrl._ShowWiki = HL.Method() << function(self)
    local itemInfo = self.m_curShowItemList[self.m_curItemIndex]
    if itemInfo and itemInfo.id then
        Notify(MessageConst.SHOW_WIKI_ENTRY, { itemId = itemInfo.id })
    end
end
ValuableDepotCtrl.m_destroyCount = HL.Field(HL.Number) << 0
ValuableDepotCtrl.m_destroyInfo = HL.Field(HL.Table)
ValuableDepotCtrl.m_getExpandItemCell = HL.Field(HL.Function)
ValuableDepotCtrl.m_destroyExpandItemList = HL.Field(HL.Table)
ValuableDepotCtrl.m_destroyCountItemRealId = HL.Field(HL.String) << ""
ValuableDepotCtrl._InitDestroyNode = HL.Method() << function(self)
    self.view.bottomNode.destroyBtn.onClick:AddListener(function()
        self:_ToggleDestroyMode(true, false)
    end)
    self.view.bottomNode.desEquipBtn.onClick:AddListener(function()
        self:_ToggleDestroyMode(true, false)
    end)
    local node = self.view.destroyNode
    self.view.animation:SampleToOutAnimationEnd()
    self.view.destroyNode.hintTxtNode.gameObject:SetActive(true)
    node.backBtn.onClick:AddListener(function()
        self:_ToggleDestroyMode(false, false)
    end)
    node.normalRightNode.confirmBtn.onClick:AddListener(function()
        self:_ConfirmDestroy()
    end)
    node.equipRightNode.confirmBtn.onClick:AddListener(function()
        self:_ConfirmDestroy()
    end)
    node.expandToggle.isOn = false
    node.expandToggle.onValueChanged:AddListener(function(isOn)
        self:_ToggleDestroySelectExpand(isOn)
    end)
    node.closeExpandBtn.onClick:AddListener(function()
        node.expandToggle.isOn = false
    end)
    self.m_getExpandItemCell = UIUtils.genCachedCellFunction(node.selectScrollList)
    node.selectScrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateExpandCell(self.m_getExpandItemCell(obj), LuaIndex(csIndex))
    end)
    self.m_destroyInfo = {}
end
ValuableDepotCtrl._UpdateItemBlockMask = HL.Method(HL.Any, HL.Table) << function(self, cell, info)
    local showMask = false
    local inventory = GameInstance.player.inventory
    if self.m_inDestroyMode then
        if info.instId then
            showMask = not inventory:CanDestroyItem(Utils.getCurrentScope(), info.id, info.instId)
        else
            showMask = not inventory:CanDestroyItem(Utils.getCurrentScope(), info.id)
        end
        local desInfo = self.m_destroyInfo[self.m_curTabIndex][info.realId]
        cell.view.button.clickHintTextId = desInfo and "virtual_mouse_hint_unselect" or "virtual_mouse_hint_select"
    else
        cell.view.button.clickHintTextId = "virtual_mouse_hint_view"
    end
    cell.view.blockMask.gameObject:SetActiveIfNecessary(showMask)
end
ValuableDepotCtrl._ToggleDestroyMode = HL.Method(HL.Boolean, HL.Boolean) << function(self, active, noAnimation)
    local node = self.view.destroyNode
    local infos = self.m_tabsInfo[self.m_curTabIndex]
    local depotConfig = ItemType2DepotConfig[infos.type]
    if active then
        node.quickInputBtn.onClick:RemoveAllListeners()
        if depotConfig.destroyFilterOptions then
            node.quickInputBtn.gameObject:SetActive(true)
            node.quickInputBtn.onClick:AddListener(function()
                Notify(MessageConst.SHOW_COMMON_FILTER, {
                    tagGroups = depotConfig.destroyFilterOptions,
                    selectedTags = self.m_curDestroyFilterConfigs,
                    onConfirm = function(tags)
                        self.m_curDestroyFilterConfigs = tags
                        self:_AutoFillDestroyList(self.m_curTabIndex)
                        self:_RefreshItemList(true)
                        self:_UpdateDestroySelectTotalCount()
                    end,
                    getResultCount = function(tags)
                        return self:_GetAutoFillDestroyResultCount(tags)
                    end,
                })
            end)
        else
            node.quickInputBtn.gameObject:SetActive(false)
        end
        if depotConfig.isNormalDestroy then
            node.simpleStateController:SetState("Normal")
            node.rightNode = node.normalRightNode
        elseif depotConfig.isEquipDestroy then
            node.simpleStateController:SetState("Equip")
            node.rightNode = node.equipRightNode
        end
        if noAnimation then
            self.view.animation:SampleToInAnimationEnd()
        else
            self.view.animation:PlayInAnimation()
        end
    else
        if noAnimation then
            self.view.animation:SampleToOutAnimationEnd()
        else
            self.view.animation:PlayOutAnimation()
        end
    end
    self.m_tabCells:Update(function(cell, index)
        cell.toggle.interactable = not active
        cell.canvasGroup.alpha = (not active or index == self.m_curTabIndex) and 1 or 0.3
    end)
    self.m_inDestroyMode = active
    if not active then
        local desInfos = self.m_destroyInfo[self.m_curTabIndex]
        self.m_destroyInfo = {}
        for realId, info in pairs(desInfos) do
            local k, v = self:_GetIndexFromRealId(realId)
            if k then
                self:_UpdateItemCellDestroySelectPart(k)
            end
        end
        if self.m_curItemIndex <= 0 then
            self:_OnClickItem(math.min(1, self.m_curShowCount))
        end
        self.view.walletBarPlaceholder.gameObject:SetActive(true)
        node.backBtn.gameObject:SetActive(true)
    else
        self.m_destroyInfo = {}
        for k = 1, #self.m_tabsInfo do
            self.m_destroyInfo[k] = {}
        end
        self.m_destroyCount = 0
        self:_UpdateDestroySelectTotalCount(true)
        self:_OnClickItem(-1)
    end
    for k = 1, self.view.itemScrollList.count do
        local cell = self.m_getItemCell(k)
        if cell then
            local info = self.m_curShowItemList[k]
            self:_UpdateItemBlockMask(cell, info)
        end
    end
    self:_ToggleDestroySelectExpand(false, true)
    self.view.itemScrollList:SetPaddingBottom(active and self.m_oriPaddingBottom + 100 or self.m_oriPaddingBottom)
end
ValuableDepotCtrl._ClickItemInDestroyMode = HL.Method(HL.Number, HL.Opt(HL.Boolean)) << function(self, index, fromNavigation)
    local node = self.view.destroyNode
    local itemInfo = self.m_curShowItemList[index]
    local realId = itemInfo.realId
    if self.m_destroyInfo[self.m_curTabIndex][realId] then
        if not fromNavigation then
            self.m_destroyInfo[self.m_curTabIndex][realId] = nil
            self.m_destroyCount = self.m_destroyCount - 1
            self:_UpdateItemCellDestroySelectPart(index)
            self:_SetDestroyCountTarget("")
        else
            self:_SetDestroyCountTarget(realId)
        end
    else
        if not fromNavigation then
            local inventory = GameInstance.player.inventory
            local scope = Utils.getCurrentScope()
            if not inventory:CanDestroyItem(scope, itemInfo.id) then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_CANT_DESTROY_BECAUSE_TYPE)
                self:_SetDestroyCountTarget("")
            elseif inventory:IsEquipped(scope, itemInfo.id, itemInfo.instId) then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_CANT_DESTROY_BECAUSE_USING)
                self:_SetDestroyCountTarget("")
            elseif inventory:IsItemLocked(scope, itemInfo.id, itemInfo.instId) then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_CANT_DESTROY_BECAUSE_LOCK)
                self:_SetDestroyCountTarget("")
            elseif self.m_destroyCount >= UIConst.DEPOT_DESTROY_MAX_COUNT then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_CANT_DESTROY_BECAUSE_SELECTED_MAX)
                self:_SetDestroyCountTarget("")
            else
                self.m_destroyInfo[self.m_curTabIndex][realId] = { realId = itemInfo.realId, id = itemInfo.id, instId = itemInfo.instId, count = itemInfo.count, selectCount = itemInfo.count, }
                self.m_destroyCount = self.m_destroyCount + 1
                self:_UpdateItemCellDestroySelectPart(index)
                self:_UpdateItemCountInExpandList(realId)
                self:_SetDestroyCountTarget(realId)
            end
        else
            self:_SetDestroyCountTarget("")
        end
    end
    if not fromNavigation then
        self:_UpdateDestroySelectTotalCount()
    end
end
ValuableDepotCtrl._MarkItemDestroy = HL.Method(HL.Number) << function(self, index)
    local node = self.view.destroyNode
    local itemInfo = self.m_curShowItemList[index]
    local realId = itemInfo.realId
    local inventory = GameInstance.player.inventory
    local scope = Utils.getCurrentScope()
    if not inventory:CanDestroyItem(scope, itemInfo.id) then
        return
    end
    if inventory:IsEquipped(scope, itemInfo.id, itemInfo.instId) then
        return
    end
    if inventory:IsItemLocked(scope, itemInfo.id, itemInfo.instId) then
        return
    end
    if self.m_destroyCount >= UIConst.DEPOT_DESTROY_MAX_COUNT then
        return
    end
    self.m_destroyInfo[self.m_curTabIndex][realId] = { realId = itemInfo.realId, id = itemInfo.id, instId = itemInfo.instId, count = itemInfo.count, selectCount = itemInfo.count, }
    self.m_destroyCount = self.m_destroyCount + 1
end
ValuableDepotCtrl._SetDestroyCountTarget = HL.Method(HL.String) << function(self, realId)
    local desInfo
    local index = self:_GetIndexFromRealId(realId)
    if index then
        desInfo = self.m_destroyInfo[self.m_curTabIndex][realId]
    else
        for _, infos in ipairs(self.m_destroyInfo) do
            for k, v in pairs(infos) do
                if k == realId then
                    desInfo = v
                    break
                end
            end
            if desInfo then
                break
            end
        end
    end
    if not desInfo then
        realId = ""
    end
    local oldIsEmpty = string.isEmpty(self.m_destroyCountItemRealId)
    local newIsEmpty = string.isEmpty(realId)
    self.m_destroyCountItemRealId = realId
    local node = self.view.destroyNode
    if newIsEmpty then
        node.numberSelector.gameObject:SetActive(false)
        return
    end
    if desInfo.instId then
        node.numberSelector.gameObject:SetActive(false)
    else
        node.numberSelector.gameObject:SetActive(true)
        node.numberSelector:InitNumberSelector(desInfo.selectCount, 1, desInfo.count, function(newCount)
            self:_OnChangeItemDestroyCount(realId, newCount)
        end)
    end
end
ValuableDepotCtrl._GetIndexFromRealId = HL.Method(HL.String).Return(HL.Opt(HL.Number, HL.Table)) << function(self, realId)
    for k, v in ipairs(self.m_curShowItemList) do
        if v.realId == realId then
            return k, v
        end
    end
end
ValuableDepotCtrl._UpdateItemCellDestroySelectPart = HL.Method(HL.Opt(HL.Number, HL.Userdata, HL.Table)) << function(self, index, cell, desExpandInfo)
    if not cell then
        cell = self.m_getItemCell(index)
        if not cell then
            return
        end
    end
    local desInfo, itemInfo
    if index then
        itemInfo = self.m_curShowItemList[index]
        desInfo = self.m_inDestroyMode and self.m_destroyInfo[self.m_curTabIndex][itemInfo.realId]
    elseif desExpandInfo then
        desInfo = self.m_destroyInfo[desExpandInfo.tabIndex][desExpandInfo.realId]
    end
    if desInfo then
        if itemInfo then
            cell.view.count.text = string.format("<color=#%s>%s</color>/%s", UIConst.COUNT_RED_COLOR_STR, UIUtils.getNumString(desInfo.selectCount), UIUtils.getNumString(itemInfo.count))
        else
            cell.view.count.text = string.format(UIConst.COLOR_STRING_FORMAT, UIConst.COUNT_RED_COLOR_STR, UIUtils.getNumString(desInfo.selectCount))
        end
        if not desExpandInfo then
            cell.view.button.clickHintTextId = "virtual_mouse_hint_unselect"
        end
    else
        cell:UpdateCount(itemInfo.count)
        if not desExpandInfo then
            cell.view.button.clickHintTextId = "virtual_mouse_hint_select"
        end
    end
    if itemInfo then
        local depotConfig = ItemType2DepotConfig[self.m_tabsInfo[self.m_curTabIndex].type]
        local mark = depotConfig.isEquipDestroy and cell.view.multiSelectMark or cell.view.redMultiSelectMark
        if desInfo then
            mark.gameObject:SetActive(true)
        else
            mark.gameObject:SetActive(false)
        end
    end
end
ValuableDepotCtrl._OnChangeItemDestroyCount = HL.Method(HL.String, HL.Number) << function(self, realId, newCount)
    for _, infos in ipairs(self.m_destroyInfo) do
        for k, v in pairs(infos) do
            if k == realId then
                v.selectCount = newCount
            end
        end
    end
    local index = self:_GetIndexFromRealId(realId)
    if index then
        self:_UpdateItemCellDestroySelectPart(index)
    end
    self:_UpdateItemCountInExpandList(realId)
end
ValuableDepotCtrl._UpdateItemCountInExpandList = HL.Method(HL.String) << function(self, realId)
    if not self.view.destroyNode.expandToggle.isOn then
        return
    end
    for k, v in ipairs(self.m_destroyExpandItemList) do
        if v.realId == realId then
            local expandCell = self.m_getExpandItemCell(k)
            if expandCell then
                self:_UpdateItemCellDestroySelectPart(nil, expandCell, v)
            end
            return
        end
    end
end
ValuableDepotCtrl._UpdateDestroySelectTotalCount = HL.Method(HL.Opt(HL.Boolean)) << function(self, isInit)
    local node = self.view.destroyNode
    node.selectCountTxt.text = string.format(Language.LUA_DEPOT_DESTROY_COUNT, self.m_destroyCount, UIConst.DEPOT_DESTROY_MAX_COUNT)
    local showBtn = self.m_destroyCount > 0
    local rightNode = node.rightNode
    if not rightNode.animationWrapper then
        rightNode.confirmBtn.gameObject:SetActive(showBtn)
        rightNode.disabledBtn.gameObject:SetActive(not showBtn)
    else
        rightNode.disabledBtn.gameObject:SetActive(not showBtn)
        if isInit then
            rightNode.previewNode.gameObject:SetActive(showBtn)
            rightNode.confirmBtn.gameObject:SetActive(showBtn)
        elseif showBtn ~= rightNode.previewNode.gameObject.activeSelf then
            rightNode.previewNode.gameObject:SetActive(true)
            rightNode.confirmBtn.gameObject:SetActive(true)
            if showBtn then
                rightNode.animationWrapper:PlayInAnimation(function()
                    rightNode.previewNode.gameObject:SetActive(showBtn)
                    rightNode.confirmBtn.gameObject:SetActive(showBtn)
                end)
            else
                rightNode.animationWrapper:PlayOutAnimation(function()
                    rightNode.previewNode.gameObject:SetActive(showBtn)
                    rightNode.confirmBtn.gameObject:SetActive(showBtn)
                end)
            end
        end
        if showBtn then
            local count = self:_GetDesEquipReturnItemCount()
            rightNode.previewItem:InitItem({ id = Tables.globalConst.equipRecycleItem, count = count, }, true)
        end
    end
end
ValuableDepotCtrl._GetDesEquipReturnItemCount = HL.Method().Return(HL.Number) << function(self)
    local count = 0
    local returnItemId = Tables.globalConst.equipRecycleItem
    local ratio = Tables.globalConst.equipRecycleRatio
    for tabIndex, infos in pairs(self.m_destroyInfo) do
        for _, info in pairs(infos) do
            local formulaId = Tables.equipFormulaReverseTable[info.id]
            local formulaData = Tables.equipFormulaTable[formulaId]
            for k = 0, formulaData.costItemId.Count - 1 do
                if formulaData.costItemId[k] == returnItemId then
                    count = count + math.floor(formulaData.costItemNum[k] * ratio)
                    break
                end
            end
        end
    end
    return count
end
ValuableDepotCtrl._ToggleDestroySelectExpand = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, active, fastMode)
    self.view.walletBarPlaceholder.gameObject:SetActive(not active)
    local node = self.view.destroyNode
    local info = self.m_tabsInfo[self.m_curTabIndex]
    local depotConfig = ItemType2DepotConfig[info.type]
    self.view.inputGroup.enabled = not active
    InputManagerInst:IgnoreBindingGroupParent(node.inputBindingGroupMonoTarget.groupId, active)
    node.backBtn.gameObject:SetActive(not active)
    node.hintTxtNode.gameObject:SetActive(not active)
    node.quickInputBtn.gameObject:SetActive(depotConfig.destroyFilterOptions and not active)
    if active then
        node.selectInfoNode.gameObject:SetActive(true)
    elseif fastMode then
        node.selectInfoNode.gameObject:SetActive(false)
    else
        node.selectInfoNode:PlayOutAnimation(function()
            node.selectInfoNode.gameObject:SetActive(false)
        end)
    end
    if not active and self.m_inDestroyMode then
        self.m_destroyExpandItemList = {}
        self:_SetDestroyCountTarget(info and info.realId or "")
        return
    end
    self:_RefreshDestroySelectExpandList()
end
ValuableDepotCtrl._RefreshDestroySelectExpandList = HL.Method(HL.Opt(HL.Boolean)) << function(self, skipAnim)
    local node = self.view.destroyNode
    self.m_destroyExpandItemList = {}
    for tabIndex, infos in ipairs(self.m_destroyInfo) do
        local needFindIndex = tabIndex == self.m_curTabIndex
        for realId, _ in pairs(infos) do
            if needFindIndex then
                local k, v = self:_GetIndexFromRealId(realId)
                if k then
                    table.insert(self.m_destroyExpandItemList, { tabIndex = tabIndex, index = k, realId = realId, })
                end
            else
                table.insert(self.m_destroyExpandItemList, { tabIndex = tabIndex, realId = realId, })
            end
        end
    end
    table.sort(self.m_destroyExpandItemList, Utils.genSortFunction({ "index" }, true))
    node.selectScrollList:UpdateCount(#self.m_destroyExpandItemList, false, false, false, skipAnim == true)
    self:_SetDestroyCountTarget("")
end
ValuableDepotCtrl._OnUpdateExpandCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local info = self.m_destroyExpandItemList[index]
    local realId = info.realId
    local desInfo = self.m_destroyInfo[info.tabIndex][info.realId]
    cell:InitItem(desInfo, function()
        self:_SetDestroyCountTarget(realId)
        cell:ShowTips({ safeArea = self.view.destroyNode.numberSelector.rectTransform, padding = { bottom = self.view.destroyNode.bottomNode.transform.rect.size.y + 20 }, isSideTips = true, }, function()
            if self.m_destroyCountItemRealId == realId then
                self:_SetDestroyCountTarget("")
            end
        end)
    end)
    cell.view.deleteBtn.onClick:RemoveAllListeners()
    cell.view.deleteBtn.onClick:AddListener(function()
        self:_OnClickExpandItemDelBtn(index)
    end)
    self:_UpdateItemCellDestroySelectPart(nil, cell, info)
    cell.view.button.clickHintTextId = "virtual_mouse_hint_item_tips"
    cell.view.deleteBtn.gameObject:SetActive(true)
end
ValuableDepotCtrl._OnClickExpandItemDelBtn = HL.Method(HL.Number) << function(self, index)
    local info = self.m_destroyExpandItemList[index]
    if info.index then
        self:_ClickItemInDestroyMode(info.index)
    else
        self.m_destroyInfo[info.tabIndex][info.realId] = nil
        self.m_destroyCount = self.m_destroyCount - 1
        self:_UpdateDestroySelectTotalCount()
        self:_SetDestroyCountTarget("")
    end
    self:_RefreshDestroySelectExpandList(true)
    if info.index == self.m_curItemIndex then
        self:_OnClickItem(-1)
    end
end
ValuableDepotCtrl.OnEquipRecycle = HL.Method(HL.Table) << function(self, arg)
    Notify(MessageConst.SHOW_TOAST, Language.LUA_EQUIP_RECYCLE_SUCC)
end
ValuableDepotCtrl._ConfirmDestroy = HL.Method() << function(self)
    local items = {}
    local itemDelInfo = {}
    local instDelInfo = {}
    for tabIndex, infos in pairs(self.m_destroyInfo) do
        itemDelInfo[tabIndex] = {}
        instDelInfo[tabIndex] = {}
        for _, info in pairs(infos) do
            if info.instId and info.instId > 0 then
                table.insert(instDelInfo[tabIndex], info.instId)
            else
                itemDelInfo[tabIndex][info.id] = info.selectCount
            end
            table.insert(items, { id = info.id, count = info.selectCount, instId = info.instId, })
        end
    end
    table.sort(items, Utils.genSortFunction({ "id" }, true))
    local depotConfig = ItemType2DepotConfig[self.m_tabsInfo[self.m_curTabIndex].type]
    if depotConfig.isEquipDestroy then
        local count = self:_GetDesEquipReturnItemCount()
        local id = Tables.globalConst.equipRecycleItem
        UIManager:Open(PanelId.DesEquipPopUp, {
            items = items,
            returnItemId = id,
            returnItemCount = count,
            onConfirm = function()
                GameInstance.player.inventory:RecycleEquip(instDelInfo[self.m_curTabIndex])
                self:_ToggleDestroyMode(false, false)
            end,
        })
    else
        Notify(MessageConst.SHOW_POP_UP, {
            content = Language.LUA_DESTROY_ITEM_CONFIRM_TEXT,
            warningContent = Language.LUA_DESTROY_ITEM_CONFIRM_WARNING_TEXT,
            items = items,
            onConfirm = function()
                for tabIndex, tabInfo in ipairs(self.m_tabsInfo) do
                    local itemInfos = itemDelInfo[tabIndex]
                    local instIds = instDelInfo[tabIndex]
                    if next(itemInfos) or next(instIds) then
                        GameInstance.player.inventory:DestroyInDepot(Utils.getCurrentScope(), tabInfo.type, itemInfos, instIds)
                    end
                end
                self:_ToggleDestroyMode(false, false)
            end,
        })
    end
end
ValuableDepotCtrl.OnItemLockedStateChanged = HL.Method(HL.Table) << function(self, args)
    if not self.m_inDestroyMode then
        return
    end
    local id, instId, isLocked = unpack(args)
    local itemInfo = self.m_curShowItemList[self.m_curItemIndex]
    if itemInfo and itemInfo.id == id and itemInfo.instId == instId then
        local cell = self.m_getItemCell(self.m_curItemIndex)
        if cell then
            self:_UpdateItemBlockMask(cell, itemInfo)
        end
        self:_ClickItemInDestroyMode(self.m_curItemIndex)
    end
end
ValuableDepotCtrl._JumpToWeaponGem = HL.Method(HL.String, HL.Number) << function(self, gemTemplateId, gemInstId)
    local gemInst = CharInfoUtils.getGemByInstId(gemInstId)
    if not gemInst then
        return
    end
    local attachedWeaponInstId = gemInst.weaponInstId
    if not attachedWeaponInstId then
        return
    end
    local weaponInst = CharInfoUtils.getWeaponByInstId(attachedWeaponInstId)
    if not weaponInst then
        return
    end
    local fadeTimeBoth = UIConst.CHAR_INFO_TRANSITION_BLACK_SCREEN_DURATION
    local dynamicFadeData = UIUtils.genDynamicBlackScreenMaskData("ValuableDepot->WeaponInfo", fadeTimeBoth, fadeTimeBoth, function()
        self.view.itemScrollList:UpdateCount(0)
        CharInfoUtils.openWeaponInfoBestWay({ weaponTemplateId = weaponInst.templateId, weaponInstId = weaponInst.instId, pageType = UIConst.WEAPON_EXHIBIT_PAGE_TYPE.GEM })
    end)
    GameAction.ShowBlackScreen(dynamicFadeData)
end
ValuableDepotCtrl._JumpToWeapon = HL.Method(HL.String, HL.Number) << function(self, weaponTemplateId, weaponInstId)
    local fadeTimeBoth = UIConst.CHAR_INFO_TRANSITION_BLACK_SCREEN_DURATION
    local dynamicFadeData = UIUtils.genDynamicBlackScreenMaskData("ValuableDepot->WeaponInfo", fadeTimeBoth, fadeTimeBoth, function()
        CharInfoUtils.openWeaponInfoBestWay({ weaponTemplateId = weaponTemplateId, weaponInstId = weaponInstId, })
        self.view.itemScrollList:UpdateCount(0)
    end)
    GameAction.ShowBlackScreen(dynamicFadeData)
end
ValuableDepotCtrl._CheckIfCanJump = HL.Method(HL.String, HL.Userdata, HL.Opt(HL.Number)).Return(HL.Boolean, HL.Opt(HL.Function)) << function(self, itemId, itemType, instId)
    if not instId or instId <= 0 then
        return false
    end
    local isWeapon = itemType == GEnums.ItemType.Weapon
    if isWeapon then
        return true, self._JumpToWeapon
    end
    local isWeaponGem = itemType == GEnums.ItemType.WeaponGem
    if not isWeaponGem then
        return false
    end
    local gemInst = CharInfoUtils.getGemByInstId(instId)
    if not gemInst then
        return false
    end
    local weaponInstId = gemInst.weaponInstId
    if not weaponInstId or weaponInstId <= 0 then
        return false
    end
    return true, self._JumpToWeaponGem
end
ValuableDepotCtrl._CheckIfCanUse = HL.Method(HL.String).Return(HL.Boolean, HL.Opt(HL.Function)) << function(self, itemId)
    if itemId == Tables.dungeonConst.recoverApItemId then
        local useFunc = function()
            UIManager:Open(PanelId.StaminaPopUp, itemId)
        end
        return true, useFunc
    end
    local _, itemData = Tables.itemTable:TryGetValue(itemId)
    if itemData.type == GEnums.ItemType.ItemCase then
        local useFunc = function()
            PhaseManager:OpenPhase(PhaseId.UsableItemChest, { itemId = itemId })
        end
        return true, useFunc
    end
    return false
end
ValuableDepotCtrl._UpdateDecoIcons = HL.Method(HL.Opt(HL.String)) << function(self, id)
    if not id or string.isEmpty(id) then
        return
    end
    local data = Tables.itemTable:GetValue(id)
    self.view.icon.sprite = self:LoadSprite(self.view.config.USE_BIG_ICON and UIConst.UI_SPRITE_ITEM_BIG or UIConst.UI_SPRITE_ITEM, data.iconId)
end
ValuableDepotCtrl._ReadItem = HL.Method(HL.Number) << function(self, index)
    if index <= 0 then
        return
    end
    local info = self.m_curShowItemList[index]
    if info.instId then
        GameInstance.player.inventory:ReadNewItem(info.id, info.instId)
    else
        GameInstance.player.inventory:ReadNewItem(info.id)
    end
end
ValuableDepotCtrl.m_readItemIds = HL.Field(HL.Table)
ValuableDepotCtrl.m_readItemInstIds = HL.Field(HL.Table)
ValuableDepotCtrl._ReadCurShowingItems = HL.Method() << function(self)
    local tabInfo = self.m_tabsInfo[self.m_curTabIndex]
    if not tabInfo then
        return
    end
    if not next(self.m_readItemIds) and not next(self.m_readItemInstIds) then
        return
    end
    local itemIds = {}
    for k, _ in pairs(self.m_readItemIds) do
        table.insert(itemIds, k)
    end
    self.m_readItemIds = {}
    local instIds = {}
    for k, _ in pairs(self.m_readItemInstIds) do
        table.insert(instIds, k)
    end
    self.m_readItemInstIds = {}
    GameInstance.player.inventory:ReadNewItems(itemIds, tabInfo.type, instIds)
end
ValuableDepotCtrl.m_itemInfoNaviGroupId = HL.Field(HL.Number) << -1
ValuableDepotCtrl._InitItemInfoNavi = HL.Method() << function(self)
    local node = self.view.itemInfoNode
    self.m_itemInfoNaviGroupId = InputManagerInst:CreateGroup(node.contentInputBindingGroupMonoTarget.groupId)
    UIUtils.bindInputPlayerAction("common_navigation_4_dir_up", function()
        self:_NavigateItemInfo(-1)
    end, self.m_itemInfoNaviGroupId)
    UIUtils.bindInputPlayerAction("common_navigation_4_dir_down", function()
        self:_NavigateItemInfo(1)
    end, self.m_itemInfoNaviGroupId)
    UIUtils.bindInputPlayerAction("common_navigation_4_dir_left", function()
        self:_ToggleItemInfoNavi(false)
    end, self.m_itemInfoNaviGroupId)
    UIUtils.bindInputPlayerAction("common_navigation_4_dir_right", function()
        self:_NavigateItemInfo(0)
    end, self.m_itemInfoNaviGroupId)
    InputManagerInst:CreateBindingByActionId("common_cancel", function()
        self:_ToggleItemInfoNavi(false)
    end, self.m_itemInfoNaviGroupId)
    InputManagerInst:ToggleGroup(self.m_itemInfoNaviGroupId, false)
end
ValuableDepotCtrl._ToggleItemInfoNavi = HL.Method(HL.Boolean) << function(self, active)
    local node = self.view.itemInfoNode
    InputManagerInst:ToggleGroup(self.m_itemInfoNaviGroupId, active)
    if active then
        Notify(MessageConst.SHOW_AS_CONTROLLER_SMALL_MENU, {
            panelId = PANEL_ID,
            isGroup = true,
            id = node.contentInputBindingGroupMonoTarget.groupId,
            hintPlaceholder = self.view.controllerHintPlaceholder,
            rectTransform = node.naviHighlightRect,
            useVirtualMouse = true,
            canClickClose = true,
            onClose = function()
                self:_ToggleItemInfoNavi(false)
            end
        })
        InputManagerInst:MoveVirtualMouseTo(node.naviHighlightRect, self.uiCamera, false)
        self:_InitItemInfoNaviList()
    else
        Notify(MessageConst.CLOSE_CONTROLLER_SMALL_MENU, PANEL_ID)
        self.view.itemScrollList:MoveVirtualMouseToSelected(false)
    end
end
ValuableDepotCtrl.m_itemInfoNaviInfos = HL.Field(HL.Table)
ValuableDepotCtrl.m_itemInfoNaviIndex = HL.Field(HL.Number) << -1
ValuableDepotCtrl._InitItemInfoNaviList = HL.Method() << function(self)
    local node = self.view.itemInfoNode
    self.m_itemInfoNaviInfos = {}
    if node.wikiBtn.gameObject.activeInHierarchy then
        table.insert(self.m_itemInfoNaviInfos, { node.wikiBtn.transform })
    end
    if node.lockToggle.gameObject.activeInHierarchy then
        table.insert(self.m_itemInfoNaviInfos, { node.lockToggle.transform })
    end
    node.itemObtainWays.m_obtainCells:Update(function(cell, index)
        if cell.normalNode.button.enabled then
            table.insert(self.m_itemInfoNaviInfos, { cell.normalNode.button.transform, true })
        end
    end)
    self:_NavigateItemInfoTo(1)
end
ValuableDepotCtrl._NavigateItemInfo = HL.Method(HL.Number) << function(self, offset)
    logger.info("_NavigateItemInfo", offset)
    self:_NavigateItemInfoTo(lume.clamp(self.m_itemInfoNaviIndex + offset, 1, #self.m_itemInfoNaviInfos))
end
ValuableDepotCtrl._NavigateItemInfoTo = HL.Method(HL.Number) << function(self, index)
    self.m_itemInfoNaviIndex = index
    local target = self.m_itemInfoNaviInfos[index]
    if not target then
        return
    end
    local targetTrans, isInScrollList = unpack(target)
    if isInScrollList then
        local node = self.view.itemInfoNode
        local contentHeight = node.detailScroll.content.rect.height
        local listHeight = node.detailScroll.transform.rect.height
        if contentHeight > listHeight then
            node.detailScroll:ScrollTo(Vector2(0, contentHeight - listHeight), true)
        end
    end
    InputManagerInst:MoveVirtualMouseTo(targetTrans, self.uiCamera)
end
HL.Commit(ValuableDepotCtrl)