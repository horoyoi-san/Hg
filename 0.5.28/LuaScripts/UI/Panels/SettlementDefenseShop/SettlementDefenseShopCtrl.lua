local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementDefenseShop
local PHASE_ID = PhaseId.SettlementDefenseShop
SettlementDefenseShopCtrl = HL.Class('SettlementDefenseShopCtrl', uiCtrl.UICtrl)
local MIN_NUMBER_SELECTOR_NUMBER = 1
local INITIAL_NUMBER_SELECTOR_NUMBER = 1
local INITIAL_SHOP_ITEM_LIST_SELECTED_INDEX = 1
SettlementDefenseShopCtrl.m_selectedIndex = HL.Field(HL.Number) << -1
SettlementDefenseShopCtrl.m_goldItemId = HL.Field(HL.String) << ""
SettlementDefenseShopCtrl.m_goldItemCount = HL.Field(HL.Number) << -1
SettlementDefenseShopCtrl.m_selectorNumber = HL.Field(HL.Number) << -1
SettlementDefenseShopCtrl.m_buildingConsume = HL.Field(HL.Number) << -1
SettlementDefenseShopCtrl.m_getShopItemFunction = HL.Field(HL.Function)
SettlementDefenseShopCtrl.m_shopBuildingDataList = HL.Field(HL.Table)
SettlementDefenseShopCtrl.m_shopItemDataList = HL.Field(HL.Table)
SettlementDefenseShopCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_ITEM_COUNT_CHANGED] = '_OnItemCountChanged', [MessageConst.ON_WALLET_CHANGED] = '_OnWalletChanged', [MessageConst.ON_LEAVE_TOWER_DEFENSE_DEFENDING_PHASE] = '_OnLeaveTowerDefenseDefendingPhase', }
SettlementDefenseShopCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:_InitDefenseShop()
end
SettlementDefenseShopCtrl._InitDefenseShop = HL.Method() << function(self)
    self:_InitShopStaticData()
    self:_InitShopCommonWidget()
    self:_InitShopGold()
    self:_InitShopItemList()
    self:_InitShopBuilding()
end
SettlementDefenseShopCtrl._InitShopStaticData = HL.Method() << function(self)
    self.m_shopBuildingDataList = {}
    local tempList = {}
    local techTreeSystem = GameInstance.player.facTechTreeSystem
    for buildingId, shopData in pairs(Tables.towerDefenseShopTable) do
        local needTechId = shopData.needTechId
        if string.isEmpty(needTechId) or not techTreeSystem:NodeIsLocked(needTechId) then
            local itemId = FactoryUtils.getBuildingItemId(buildingId)
            local success, itemData = Tables.itemTable:TryGetValue(itemId)
            if success then
                table.insert(tempList, { buildingData = { buildingId = buildingId, itemId = itemId, cost = shopData.money, name = itemData.name, desc = itemData.desc, sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_BUILDING_IMAGE, string.format("image_%s", buildingId)) }, rarity = itemData.rarity, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2, })
            end
        end
    end
    table.sort(tempList, Utils.genSortFunction({ "rarity", "sortId1", "sortId2" }, true))
    for _, tempData in ipairs(tempList) do
        table.insert(self.m_shopBuildingDataList, tempData.buildingData)
    end
    self.m_goldItemId = Tables.globalConst.tdGoldItemId
end
SettlementDefenseShopCtrl._OnLeaveTowerDefenseDefendingPhase = HL.Method() << function(self)
    PhaseManager:PopPhase(PHASE_ID)
end
SettlementDefenseShopCtrl._InitShopItemList = HL.Method() << function(self)
    self.m_getShopItemFunction = UIUtils.genCachedCellFunction(self.view.shopItemList)
    self.view.shopItemList.onUpdateCell:AddListener(function(object, csIndex)
        self:_RefreshShopItemCell(object, LuaIndex(csIndex))
    end)
    self.view.shopItemList.onSelectedCell:AddListener(function(obj, csIndex)
        self:_OnShopItemCellClicked(obj, LuaIndex(csIndex))
    end)
    self.m_shopItemDataList = {}
    for _, buildingData in ipairs(self.m_shopBuildingDataList) do
        local itemId = buildingData.itemId
        local success, itemData = Tables.itemTable:TryGetValue(itemId)
        if success then
            table.insert(self.m_shopItemDataList, { id = itemId, type = itemData.type, })
        end
    end
    self:_UpdateShopItemDataList()
    self:_RefreshAllShopItemCells()
    self.view.shopItemList:SetSelectedIndex(CSIndex(INITIAL_SHOP_ITEM_LIST_SELECTED_INDEX), true, true)
end
SettlementDefenseShopCtrl._OnItemCountChanged = HL.Method(HL.Any) << function(self, args)
    self:_UpdateShopItemDataList()
    self:_RefreshAllShopItemCells()
    self:_RefreshBuildingItemCount()
end
SettlementDefenseShopCtrl._UpdateShopItemDataList = HL.Method() << function(self)
    for _, itemData in ipairs(self.m_shopItemDataList) do
        local itemId = itemData.id
        local itemCount = Utils.getItemCount(itemId, false)
        itemData.count = itemCount
    end
end
SettlementDefenseShopCtrl._RefreshAllShopItemCells = HL.Method() << function(self)
    self.view.shopItemList:UpdateCount(#self.m_shopItemDataList)
end
SettlementDefenseShopCtrl._RefreshShopItemCell = HL.Method(HL.Userdata, HL.Number) << function(self, object, index)
    local itemCell = self.m_getShopItemFunction(object)
    local itemData = self.m_shopItemDataList[index]
    if itemCell == nil or itemData == nil then
        return
    end
    local csIndex = CSIndex(index)
    itemCell:InitItemSlot(itemData, function()
        self.view.shopItemList:SetSelectedIndex(csIndex)
    end)
    itemCell.view.dropItem.enabled = false
    local buildingData = self.m_shopBuildingDataList[index]
    if buildingData ~= nil then
        itemCell.item.view.costText.text = string.format("%d", buildingData.cost)
    end
    UIUtils.initUIDragHelper(itemCell.view.dragItem, { source = UIConst.UI_DRAG_DROP_SOURCE_TYPE.SettlementDefenseShop, csIndex = csIndex, type = itemData.type, itemId = itemData.id, count = itemData.count, })
    itemCell.gameObject.name = "Item_" .. itemData.id
    if index == self.m_selectedIndex then
        itemCell.item:SetSelected(true)
    end
end
SettlementDefenseShopCtrl._OnShopItemCellClicked = HL.Method(HL.Userdata, HL.Number) << function(self, cell, index)
    local lastCell = self.m_getShopItemFunction(self.m_selectedIndex)
    self.m_selectedIndex = index
    local currCell = self.m_getShopItemFunction(cell)
    if lastCell ~= nil then
        lastCell.view.item:SetSelected(false)
    end
    if currCell ~= nil then
        currCell.view.item:SetSelected(true)
    end
    self:_UpdateBuildingConsume()
    self:_RefreshNumberSelector(true)
    self:_RefreshBuildingDisplayContent()
    self:_RefreshConfirmButtonState()
end
SettlementDefenseShopCtrl._InitShopGold = HL.Method() << function(self)
    self.view.walletBarPlaceholder:InitWalletBarPlaceholder({ self.m_goldItemId })
    self:_UpdateGoldItemCount()
end
SettlementDefenseShopCtrl._OnWalletChanged = HL.Method(HL.Any) << function(self, args)
    self:_UpdateGoldItemCount()
    self:_RefreshBuildingConsume()
    self:_RefreshNumberSelector(false)
    self:_RefreshConfirmButtonState()
end
SettlementDefenseShopCtrl._UpdateGoldItemCount = HL.Method() << function(self)
    self.m_goldItemCount = Utils.getItemCount(self.m_goldItemId, false)
end
SettlementDefenseShopCtrl._GetIsGoldItemEnough = HL.Method().Return(HL.Boolean) << function(self)
    return self.m_goldItemCount > 0 and self.m_goldItemCount >= self.m_buildingConsume
end
SettlementDefenseShopCtrl._InitShopBuilding = HL.Method() << function(self)
    self:_UpdateBuildingConsume()
    self:_RefreshBuildingDisplayContent()
    self:_RefreshBuildingItemCount()
    self:_RefreshBuildingConsume()
end
SettlementDefenseShopCtrl._UpdateBuildingConsume = HL.Method() << function(self)
    local buildingData = self.m_shopBuildingDataList[self.m_selectedIndex]
    if buildingData == nil then
        return
    end
    self.m_buildingConsume = buildingData.cost * self.m_selectorNumber
end
SettlementDefenseShopCtrl._RefreshBuildingDisplayContent = HL.Method() << function(self)
    local buildingData = self.m_shopBuildingDataList[self.m_selectedIndex]
    if buildingData == nil then
        return
    end
    local buildingInfoNode = self.view.buildingInfoNode
    local buildingSprite = buildingData.sprite
    if buildingSprite ~= nil then
        buildingInfoNode.buildingImage.sprite = buildingSprite
    end
    buildingInfoNode.nameText.text = buildingData.name
    buildingInfoNode.descText.text = buildingData.desc
    self:_RefreshBuildingItemCount()
    self:_RefreshBuildingConsume()
end
SettlementDefenseShopCtrl._RefreshBuildingItemCount = HL.Method() << function(self)
    local itemData = self.m_shopItemDataList[self.m_selectedIndex]
    if itemData == nil then
        return
    end
    self.view.buildingInfoNode.itemCountText.text = string.format("%d", itemData.count)
    local color = itemData.count > 0 and self.view.config.VALID_TEXT_COLOR or self.view.config.INVALID_TEXT_COLOR
    self.view.buildingInfoNode.itemCountText.color = color
end
SettlementDefenseShopCtrl._RefreshBuildingConsume = HL.Method() << function(self)
    local buildingData = self.m_shopBuildingDataList[self.m_selectedIndex]
    if buildingData == nil then
        return
    end
    self.view.buildingInfoNode.consumeText.text = string.format("%d", self.m_buildingConsume)
    local color = self:_GetIsGoldItemEnough() and self.view.config.VALID_TEXT_COLOR or self.view.config.INVALID_TEXT_COLOR
    self.view.buildingInfoNode.consumeText.color = color
end
SettlementDefenseShopCtrl._InitShopCommonWidget = HL.Method() << function(self)
    self:_InitCloseButton()
    self:_InitNumberSelector()
    self:_InitConfirmButton()
    self:_InitFacQuickBar()
end
SettlementDefenseShopCtrl._InitCloseButton = HL.Method() << function(self)
    self.view.closeButton.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.SettlementDefenseShop)
    end)
    self:BindInputPlayerAction("close_inventory", function()
        PhaseManager:PopPhase(PHASE_ID)
    end)
end
SettlementDefenseShopCtrl._InitNumberSelector = HL.Method() << function(self)
    self.view.numberSelector:InitNumberSelector(INITIAL_NUMBER_SELECTOR_NUMBER, MIN_NUMBER_SELECTOR_NUMBER, MIN_NUMBER_SELECTOR_NUMBER, function(number)
        self:_OnNumberSelectorNumberChanged(number)
    end)
end
SettlementDefenseShopCtrl._RefreshNumberSelector = HL.Method(HL.Boolean) << function(self, needInitNumber)
    local buildingData = self.m_shopBuildingDataList[self.m_selectedIndex]
    if buildingData == nil then
        return
    end
    local cost = buildingData.cost
    local maxNumber = math.max(MIN_NUMBER_SELECTOR_NUMBER, math.floor(self.m_goldItemCount / cost))
    local number = needInitNumber and INITIAL_NUMBER_SELECTOR_NUMBER or self.m_selectorNumber
    self.view.numberSelector:RefreshNumber(number, MIN_NUMBER_SELECTOR_NUMBER, maxNumber)
end
SettlementDefenseShopCtrl._OnNumberSelectorNumberChanged = HL.Method(HL.Number) << function(self, number)
    self.m_selectorNumber = number
    self:_UpdateBuildingConsume()
    self:_RefreshBuildingConsume()
    self:_RefreshConfirmButtonState()
end
SettlementDefenseShopCtrl._InitConfirmButton = HL.Method() << function(self)
    self.view.confirmButton.onClick:AddListener(function()
        self:_OnConfirmButtonClicked()
    end)
end
SettlementDefenseShopCtrl._RefreshConfirmButtonState = HL.Method() << function(self)
    local isValid = self:_GetIsGoldItemEnough()
    self.view.confirmButton.gameObject:SetActive(isValid)
    self.view.invalidConfirmNode.gameObject:SetActive(not isValid)
end
SettlementDefenseShopCtrl._OnConfirmButtonClicked = HL.Method() << function(self)
    local buildingData = self.m_shopBuildingDataList[self.m_selectedIndex]
    if buildingData == nil then
        return
    end
    GameInstance.player.towerDefenseSystem:BuyDefenseBuilding(buildingData.buildingId, self.m_selectorNumber)
end
SettlementDefenseShopCtrl._InitFacQuickBar = HL.Method() << function(self)
    self.view.facQuickBarPlaceHolder:InitFacQuickBarPlaceHolder()
end
HL.Commit(SettlementDefenseShopCtrl)