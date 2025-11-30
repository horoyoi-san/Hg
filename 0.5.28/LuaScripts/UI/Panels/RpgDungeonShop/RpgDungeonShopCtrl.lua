local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RpgDungeonShop
RpgDungeonShopCtrl = HL.Class('RpgDungeonShopCtrl', uiCtrl.UICtrl)
RpgDungeonShopCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_BUY_RPG_DUNGEON_EQUIP_SUCC] = 'OnBuyRpgDungeonEquipSucc', [MessageConst.ON_SELL_RPG_DUNGEON_EQUIP_SUCC] = 'OnSellRpgDungeonEquipSucc', }
RpgDungeonShopCtrl.m_isInShop = HL.Field(HL.Boolean) << false
RpgDungeonShopCtrl.m_onlyShowCanCraft = HL.Field(HL.Boolean) << false
RpgDungeonShopCtrl.m_shopItems = HL.Field(HL.Table)
RpgDungeonShopCtrl.m_itemBagItems = HL.Field(HL.Table)
RpgDungeonShopCtrl.m_curItems = HL.Field(HL.Table)
RpgDungeonShopCtrl.m_curItemIndex = HL.Field(HL.Number) << 1
RpgDungeonShopCtrl.m_curTabIndex = HL.Field(HL.Number) << 1
RpgDungeonShopCtrl.m_tabsInfo = HL.Field(HL.Table)
RpgDungeonShopCtrl.m_tabs = HL.Field(HL.Forward('UIListCache'))
RpgDungeonShopCtrl.m_costItems = HL.Field(HL.Forward('UIListCache'))
RpgDungeonShopCtrl.m_getCell = HL.Field(HL.Function)
RpgDungeonShopCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.RpgDungeonShop)
    end)
    self.view.confirmSellBtn.onClick:AddListener(function()
        self:_OnClickConfirmSell()
    end)
    self.view.confirmBuyBtn.onClick:AddListener(function()
        self:_OnClickConfirmBuy()
    end)
    if DeviceInfo.usingController then
        self.view.naviToCostItemBtn.onClick:AddListener(function()
            self.view.costItems:NaviToThisGroup()
        end)
        self:BindInputPlayerAction("common_cancel", function()
            InputManagerInst.controllerNaviManager:TryRemoveLayer(self.view.costItems)
        end, self.view.costItemNaviBindingGroup.groupId)
    end
    self.m_costItems = UIUtils.genCellCache(self.view.costItemCell)
    self.m_getCell = UIUtils.genCachedCellFunction(self.view.itemScrollList)
    self.view.itemScrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateCell(self.m_getCell(obj), LuaIndex(csIndex))
    end)
    self.view.shopToggle.onValueChanged:AddListener(function(isOn)
        self:_ChangeToShop(isOn, true)
    end)
    self.view.canCraftToggle.onValueChanged:AddListener(function(isOn)
        self:_ToggleCanCraft(isOn, true)
    end)
    self:_ChangeToShop(true)
    self:_ToggleCanCraft(false)
    self:_InitTabs()
    self.view.walletBarPlaceholder:InitWalletBarPlaceholder({ UIConst.RPG_DUNGEON_GOLD_ID })
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
RpgDungeonShopCtrl.OpenRpgDungeonShop = HL.StaticMethod() << function(self)
    PhaseManager:OpenPhase(PhaseId.RpgDungeonShop)
end
RpgDungeonShopCtrl._InitTabs = HL.Method() << function(self)
    self.m_tabsInfo = {}
    table.insert(self.m_tabsInfo, { name = Language.LUA_RPG_DUNGEON_TAB_ALL })
    for k = 1, UIConst.RPG_DUNGEON_TAB_COUNT do
        table.insert(self.m_tabsInfo, { name = Language["LUA_RPG_DUNGEON_TAB_" .. k], rarity = 3 + k, })
    end
    self.m_curItemIndex = 1
    self.m_tabs = UIUtils.genCellCache(self.view.tabCell)
    self.m_tabs:Refresh(#self.m_tabsInfo, function(cell, index)
        cell.text.text = self.m_tabsInfo[index].name
        cell.toggle.isOn = self.m_curItemIndex == index
        cell.toggle.onValueChanged:AddListener(function(isOn)
            if isOn then
                self:_OnClickTab(index)
            end
        end)
    end)
    self:_OnClickTab(self.m_curItemIndex)
end
RpgDungeonShopCtrl._OnClickTab = HL.Method(HL.Number, HL.Opt(HL.String)) << function(self, index, gotoItemId)
    self.m_curTabIndex = index
    self.m_tabs:Get(index).toggle:SetIsOnWithoutNotify(true)
    self:_UpdateCurItems(gotoItemId)
    if gotoItemId then
        local cell = self.m_getCell(self.m_curItemIndex)
        if cell then
            InputManagerInst.controllerNaviManager:SetTarget(cell.view.button)
        end
    else
        self.view.itemScrollList:SetTop()
        local firstCell = self.m_getCell(1)
        if firstCell then
            InputManagerInst.controllerNaviManager:SetTarget(firstCell.view.button)
        else
            self.view.itemScrollListSelectableNaviGroup:NaviToThisGroup()
        end
    end
end
RpgDungeonShopCtrl.OnAnimationInFinished = HL.Override() << function(self)
    local firstCell = self.m_getCell(1)
    if firstCell then
        InputManagerInst.controllerNaviManager:SetTarget(firstCell.view.button)
    else
        self.view.itemScrollListSelectableNaviGroup:NaviToThisGroup()
    end
end
RpgDungeonShopCtrl._InitShopData = HL.Method() << function(self)
    local dungeonId = GameInstance.dungeonManager.curDungeonId
    local data = Tables.rpgDungeonTable[dungeonId]
    self.m_shopItems = {}
    for _, id in pairs(data.equipMallList) do
        table.insert(self.m_shopItems, self:_GetItemInfo(id))
    end
    table.sort(self.m_shopItems, Utils.genSortFunction(UIConst.COMMON_ITEM_SORT_KEYS))
end
RpgDungeonShopCtrl._InitItemBagData = HL.Method() << function(self)
    self.m_itemBagItems = {}
    for _, v in pairs(GameInstance.player.inventory.itemBag:GetOrFallback(Utils.getCurrentScope()).slots) do
        if v.instId > 0 then
            local itemData = Tables.itemTable[v.id]
            if itemData.type == GEnums.ItemType.RPGDgEquip then
                local info = self:_GetItemInfo(v.id)
                info.instId = v.instId
                table.insert(self.m_itemBagItems, info)
            end
        end
    end
    table.sort(self.m_itemBagItems, Utils.genSortFunction(UIConst.COMMON_ITEM_SORT_KEYS))
end
RpgDungeonShopCtrl._GetItemInfo = HL.Method(HL.String).Return(HL.Table) << function(self, id)
    local itemData = Tables.itemTable[id]
    local equipData = Tables.rpgDungeonEquipTable[id]
    local info = { id = id, itemData = itemData, equipData = equipData, instId = 0, }
    setmetatable(info, { __index = itemData })
    return info
end
RpgDungeonShopCtrl._OnUpdateCell = HL.Method(HL.Forward('Item'), HL.Number) << function(self, item, index)
    local info = self.m_curItems[index]
    item:InitItem({ id = info.id }, function()
        self:_OnSelectItem(index)
    end)
    if self.m_isInShop then
        item.view.equippedNode.gameObject:SetActive(false)
    else
        item.view.equippedNode.gameObject:SetActive(GameInstance.player.rpgDungeonSystem:IsEquipped(info.instId))
    end
    UIUtils.changeAlpha(item.view.icon, (self.m_isInShop and not self:_CanBuyItem(info.id)) and 0.5 or 1)
    item:SetSelected(index == self.m_curItemIndex)
end
RpgDungeonShopCtrl._OnSelectItem = HL.Method(HL.Number) << function(self, index)
    local oldCell = self.m_getCell(self.m_curItemIndex)
    if oldCell then
        oldCell:SetSelected(false)
    end
    self.m_curItemIndex = index
    local newCell = self.m_getCell(self.m_curItemIndex)
    if newCell then
        newCell:SetSelected(true)
    end
    local info = self.m_curItems[index]
    self.view.curItem:InitItem({ id = info.id })
    self.view.nameTxt.text = info.name
    self.view.descTxt.text = info.desc
    local equipData = info.equipData
    if self.m_isInShop then
        self.view.priceTxt.text = equipData.price
        local costCount = equipData.buyItemList.Count
        if costCount > 0 then
            self.view.costItems.gameObject:SetActive(true)
            self.m_costItems:Refresh(costCount, function(cell, k)
                local id = equipData.buyItemList[CSIndex(k)]
                local count = equipData.buyItemNumList[CSIndex(k)]
                local costItemEquipData = Tables.rpgDungeonEquipTable[id]
                local canJump = costItemEquipData.buyItemList.Count > 0
                if DeviceInfo.usingController and canJump then
                    cell.item:InitItem({ id = id, count = count }, function()
                        self:_JumpToItem(id)
                    end)
                else
                    cell.item:InitItem({ id = id, count = count }, true)
                end
                cell.jumpBtn.onClick:RemoveAllListeners()
                if canJump then
                    cell.jumpBtn.gameObject:SetActive(true)
                    cell.jumpBtn.onClick:AddListener(function()
                        self:_JumpToItem(id)
                    end)
                else
                    cell.jumpBtn.gameObject:SetActive(false)
                end
                local ownCount = Utils.getItemCount(id)
                local numStr = string.format("%s: %d", Language.LUA_SAFE_AREA_ITEM_COUNT_LABEL, ownCount)
                cell.numTxt.text = UIUtils.setCountColor(numStr, ownCount < count)
            end)
        else
            self.view.costItems.gameObject:SetActive(false)
        end
    else
        self.view.sellPriceTxt.text = equipData.sellingPrice
        self.view.costItems.gameObject:SetActive(false)
    end
end
RpgDungeonShopCtrl._ChangeToShop = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, isOn, needRefreshList)
    self.m_isInShop = isOn
    self.view.shopToggle:SetIsOnWithoutNotify(isOn)
    self.view.priceTxt.gameObject:SetActive(isOn)
    self.view.canCraftToggle.gameObject:SetActive(isOn)
    self.view.sellPriceNode.gameObject:SetActive(not isOn)
    self.view.buyTabNameTxt.gameObject:SetActive(isOn)
    self.view.sellTabNameTxt.gameObject:SetActive(not isOn)
    self.view.confirmBuyBtn.gameObject:SetActive(isOn)
    self.view.confirmSellBtn.gameObject:SetActive(not isOn)
    if isOn then
        self:_InitShopData()
    else
        self:_InitItemBagData()
    end
    if needRefreshList then
        self:_OnClickTab(1)
    end
end
RpgDungeonShopCtrl._ToggleCanCraft = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, isOn, needRefreshList)
    self.view.canCraftToggle:SetIsOnWithoutNotify(isOn)
    self.m_onlyShowCanCraft = isOn
    if needRefreshList then
        self:_UpdateCurItems()
    end
end
RpgDungeonShopCtrl._CanBuyItem = HL.Method(HL.String).Return(HL.Boolean) << function(self, id)
    local equipData = Tables.rpgDungeonEquipTable[id]
    if equipData.price > Utils.getItemCount(UIConst.RPG_DUNGEON_GOLD_ID) then
        return false
    end
    for k, v in pairs(equipData.buyItemList) do
        local count = equipData.buyItemNumList[k]
        if Utils.getItemCount(v) < count then
            return false
        end
    end
    return true
end
RpgDungeonShopCtrl._UpdateCurItems = HL.Method(HL.Opt(HL.String)) << function(self, gotoItemId)
    local allItems = self.m_isInShop and self.m_shopItems or self.m_itemBagItems
    local rarity = self.m_tabsInfo[self.m_curTabIndex].rarity
    local items = {}
    for _, v in ipairs(allItems) do
        if not rarity or v.rarity == rarity then
            if self.m_isInShop and self.m_onlyShowCanCraft then
                local canBuy = self:_CanBuyItem(v.id)
                v.canBuyPriority = canBuy and 1 or 0
            end
            table.insert(items, v)
            if gotoItemId == v.id then
                self.m_curItemIndex = #items
            end
        end
    end
    if self.m_isInShop and self.m_onlyShowCanCraft then
        table.sort(items, Utils.genSortFunction(lume.concat({ "canBuyPriority" }, UIConst.COMMON_ITEM_SORT_KEYS)))
    end
    self.m_curItems = items
    local count = #items
    self.m_curItemIndex = math.min(math.max(self.m_curItemIndex, 1), count)
    self.view.itemScrollList:UpdateCount(count)
    local isEmpty = count == 0
    self.view.leftEmptyNode.gameObject:SetActive(isEmpty)
    self.view.contentEmptyNode.gameObject:SetActive(isEmpty)
    self.view.rightNode.gameObject:SetActive(not isEmpty)
    self.view.centerNode.gameObject:SetActive(not isEmpty)
    self.view.confirmNode.gameObject:SetActive(not isEmpty)
    if not isEmpty then
        if gotoItemId then
            self.view.itemScrollList:ScrollToIndex(CSIndex(self.m_curItemIndex), true)
        end
        self:_OnSelectItem(self.m_curItemIndex)
    end
end
RpgDungeonShopCtrl._OnClickConfirmSell = HL.Method() << function(self)
    local info = self.m_curItems[self.m_curItemIndex]
    local sys = GameInstance.player.rpgDungeonSystem
    if sys:IsEquipped(info.instId) then
        Notify(MessageConst.SHOW_POP_UP, {
            content = Language.LUA_RPG_DUNGEON_SELL_EQUIPPED_HINT,
            onConfirm = function()
                sys:SellItem(info.instId)
            end,
        })
    else
        sys:SellItem(info.instId)
    end
end
RpgDungeonShopCtrl._OnClickConfirmBuy = HL.Method() << function(self)
    local info = self.m_curItems[self.m_curItemIndex]
    local sys = GameInstance.player.rpgDungeonSystem
    sys:BuyItem(info.id)
end
RpgDungeonShopCtrl._JumpToItem = HL.Method(HL.String) << function(self, id)
    InputManagerInst.controllerNaviManager:TryRemoveLayer(self.view.costItems)
    self:_OnClickTab(1, id)
end
RpgDungeonShopCtrl.OnBuyRpgDungeonEquipSucc = HL.Method(HL.Table) << function(self, arg)
    local itemId, instId = unpack(arg)
    Notify(MessageConst.SHOW_SYSTEM_REWARDS, {
        title = Language.LUA_RPG_DUNGEON_BUY_ITEM_SUCC_TITLE,
        items = { { id = itemId, count = 1 } },
        onComplete = function()
            self:_UpdateCurItems()
        end
    })
end
RpgDungeonShopCtrl.OnSellRpgDungeonEquipSucc = HL.Method(HL.Table) << function(self, arg)
    self:_InitItemBagData()
    self:_UpdateCurItems()
    Notify(MessageConst.SHOW_TOAST, Language.LUA_RPG_DUNGEON_SELL_ITEM_SUCC)
end
HL.Commit(RpgDungeonShopCtrl)