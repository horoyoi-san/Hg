local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ItemSelect
ItemSelectCtrl = HL.Class('ItemSelectCtrl', uiCtrl.UICtrl)
ItemSelectCtrl.m_sortOptions = HL.Field(HL.Table)
ItemSelectCtrl.items = HL.Field(HL.Table)
ItemSelectCtrl.getItemCell = HL.Field(HL.Function)
ItemSelectCtrl.m_currentSelectedItemIndex = HL.Field(HL.Number) << 1
ItemSelectCtrl.m_onClickItem = HL.Field(HL.Function)
ItemSelectCtrl.m_selectedItems = HL.Field(HL.Table)
ItemSelectCtrl.m_onUnlockItem = HL.Field(HL.Function)
ItemSelectCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.HIDE_ITEM_SELECT_PANEL] = 'HideItemSelect', [MessageConst.ON_ITEM_LOCKED_STATE_CHANGED] = '_OnItemLockedStateChanged', }
ItemSelectCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:_InitItemSelect()
end
ItemSelectCtrl.OnClose = HL.Override() << function(self)
end
ItemSelectCtrl.ShowItemSelect = HL.StaticMethod(HL.Table) << function(args)
    local self = ItemSelectCtrl.AutoOpen(PANEL_ID, nil, true)
    self:_RefreshItemSelect(unpack(args))
end
ItemSelectCtrl.HideItemSelect = HL.Method() << function(self)
    if self:IsShow() then
        self:Close()
    end
end
ItemSelectCtrl._InitItemSelect = HL.Method() << function(self)
    self.getItemCell = UIUtils.genCachedCellFunction(self.view.itemList)
    self.view.itemList.onUpdateCell:AddListener(function(object, csIndex)
        self:_OnUpdateItemList(object, LuaIndex(csIndex))
    end)
    self.view.itemList.onSelectedCell:AddListener(function(object, csIndex)
        self.m_currentSelectedItemIndex = LuaIndex(csIndex)
    end)
    self.view.itemList.getCurSelectedIndex = function()
        return CSIndex(self.m_currentSelectedItemIndex)
    end
    self.view.mask.onClick:AddListener(function()
        self:HideItemSelect()
    end)
    self.m_sortOptions = { { name = Language.LUA_FAC_CRAFT_SORT_1, keys = { "notSelected", "order", "sortId1", "sortId2", "id", "instId" }, }, { name = Language.LUA_FAC_CRAFT_SORT_2, keys = { "notSelected", "order", "rarity", "sortId1", "sortId2", "id", "instId" }, }, }
end
ItemSelectCtrl._RefreshItemSelect = HL.Method(HL.Table, HL.Table, HL.Function, HL.Opt(HL.String, HL.Function)) << function(self, itemIds, selectedItems, onClickItem, title, onUnlockItem)
    self.m_onClickItem = onClickItem
    self.m_selectedItems = selectedItems
    self.m_onUnlockItem = onUnlockItem
    if title then
        self.view.titleTxt.text = title
    else
        self.view.titleTxt.text = Language.LUA_SELECT_ITEM_LIST_TITLE
    end
    local items = {}
    for i = 1, #itemIds do
        local itemId = itemIds[i]
        local itemData = Tables.itemTable:GetValue(itemId)
        local typeData = Tables.itemTypeTable:GetValue(itemData.type:GetHashCode())
        if typeData.storageSpace == GEnums.ItemStorageSpace.ValuableDepot then
            local depot = GameInstance.player.inventory.valuableDepots[typeData.valuableTabType]:GetOrFallback(Utils.getCurrentScope())
            for instId, itemBundle in pairs(depot.instItems) do
                if itemBundle.id == itemId and not GameInstance.player.inventory:IsEquipped(Utils.getCurrentScope(), itemId, instId) and typeData.valuableTabType ~= GEnums.ItemValuableDepotType.Weapon then
                    local itemData = Tables.itemTable:GetValue(itemId)
                    local isLocked = GameInstance.player.inventory:IsItemLocked(Utils.getCurrentScope(), itemId, instId)
                    local order = 0
                    if isLocked then
                        order = 1
                    end
                    local notSelected = 1
                    if self.m_selectedItems then
                        for i = 1, #self.m_selectedItems do
                            if itemBundle.instId == self.m_selectedItems[i].instId then
                                notSelected = 0
                            end
                        end
                    end
                    table.insert(items, { id = itemId, count = 1, instId = instId, order = order, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2, rarity = itemData.rarity, isLocked = isLocked, notSelected = notSelected, })
                end
            end
        end
    end
    self.items = items
    self.view.emptyNode.gameObject:SetActiveIfNecessary(#items <= 0)
    self.view.itemList:UpdateCount(#self.items)
    self.view.sortNode:InitSortNode(self.m_sortOptions, function(optData, isIncremental)
        self:_OnSortChanged(optData, isIncremental)
    end, nil, true)
    self.view.sortNode:SortCurData()
    self:_InitItemSelectController()
end
ItemSelectCtrl._OnItemLockedStateChanged = HL.Method(HL.Table) << function(self, arg)
    local itemId, instId, isLock = unpack(arg)
    for i = 1, #self.items do
        local cell = self.getItemCell(i)
        if cell then
            if self.items[i].instId == instId then
                if isLock then
                    cell.view.toggle.gameObject:SetActiveIfNecessary(false)
                end
                if isLock then
                    cell:SetIconTransparent(UIConst.ITEM_MISSING_TRANSPARENCY)
                else
                    cell:SetIconTransparent(UIConst.ITEM_EXIST_TRANSPARENCY)
                end
            end
        end
    end
    if isLock and self.m_onUnlockItem then
        self.m_onUnlockItem(itemId, instId)
    end
end
ItemSelectCtrl._OnUpdateItemList = HL.Method(HL.Userdata, HL.Number) << function(self, object, index)
    local cell = self.getItemCell(object)
    local itemBundle = self.items[index]
    if self.m_selectedItems then
        local find = false
        for i = 1, #self.m_selectedItems do
            if itemBundle.instId == self.m_selectedItems[i].instId then
                find = true
            end
        end
        cell.view.toggle.gameObject:SetActiveIfNecessary(find)
    else
        cell.view.toggle.gameObject:SetActiveIfNecessary(false)
    end
    if itemBundle.isLocked then
        cell:SetIconTransparent(UIConst.ITEM_MISSING_TRANSPARENCY)
    else
        cell:SetIconTransparent(UIConst.ITEM_EXIST_TRANSPARENCY)
    end
    cell:InitItem(self.items[index], function()
        self:_OnClickItem(object, index)
    end)
    self:_RefreshItemVirtualMouseHintText(cell)
end
ItemSelectCtrl._OnClickItem = HL.Method(HL.Userdata, HL.Number) << function(self, object, index)
    local cell = self.getItemCell(object)
    local posInfo = { tipsPosType = UIConst.UI_TIPS_POS_TYPE.RightTop, tipsPosTransform = self.view.tipsPos.transform, }
    cell:ShowTips(posInfo, function()
    end)
    local itemBundle = self.items[index]
    if self.m_onClickItem then
        self.m_onClickItem(itemBundle, cell)
    end
    self:_RefreshItemVirtualMouseHintText(cell)
end
ItemSelectCtrl._OnSortChanged = HL.Method(HL.Table, HL.Boolean) << function(self, optData, isIncremental)
    self:_SortData(optData.keys, isIncremental)
    self.view.itemList:UpdateCount(#self.items)
end
ItemSelectCtrl._SortData = HL.Method(HL.Table, HL.Boolean) << function(self, keys, isIncremental)
    table.sort(self.items, Utils.genSortFunctionWithIgnore(keys, isIncremental, { "notSelected" }))
end
ItemSelectCtrl._InitItemSelectController = HL.Method() << function(self)
    if not DeviceInfo.usingController then
        return
    end
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
    self:BindInputPlayerAction("common_cancel", function()
        self:HideItemSelect()
    end)
    self.view.itemList:SetSelectedIndex(0)
    InputManagerInst:MoveVirtualMouseTo(self.view.mouseInitialRect, self.uiCamera)
end
ItemSelectCtrl._RefreshItemVirtualMouseHintText = HL.Method(HL.Userdata) << function(self, itemCell)
    if itemCell == nil then
        return
    end
    local toggleActive = itemCell.view.toggle.gameObject.activeSelf
    itemCell.view.button.clickHintTextId = toggleActive and "virtual_mouse_hint_unselect" or "virtual_mouse_hint_select"
end
HL.Commit(ItemSelectCtrl)