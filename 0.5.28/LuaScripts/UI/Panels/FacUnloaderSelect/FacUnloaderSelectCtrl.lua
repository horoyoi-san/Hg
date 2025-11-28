local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacUnloaderSelect
FacUnloaderSelectCtrl = HL.Class('FacUnloaderSelectCtrl', uiCtrl.UICtrl)
FacUnloaderSelectCtrl.m_buildingInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.BuildingUIInfo)
FacUnloaderSelectCtrl.m_subIndex = HL.Field(HL.Number) << 1
FacUnloaderSelectCtrl.m_selector = HL.Field(CS.Beyond.Gameplay.RemoteFactory.FBUtil.Selector)
FacUnloaderSelectCtrl.m_selectCallback = HL.Field(HL.Function)
FacUnloaderSelectCtrl.m_closeCallback = HL.Field(HL.Function)
FacUnloaderSelectCtrl.s_messages = HL.StaticField(HL.Table) << {}
FacUnloaderSelectCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    if arg == nil then
        return
    end
    self.m_buildingInfo = arg.buildingInfo
    self.m_subIndex = arg.subIndex
    self.m_selector = arg.selector
    self.m_selectCallback = arg.selectCallback
    self.m_closeCallback = arg.closeCallback
    self.view.closeBtn.onClick:AddListener(function()
        self:PlayAnimationOut(UIConst.PANEL_PLAY_ANIMATION_OUT_COMPLETE_ACTION_TYPE.Close)
    end)
    self:_InitUnloaderSelect()
    self:_InitController()
    if arg.openCallback ~= nil then
        arg.openCallback()
    end
end
FacUnloaderSelectCtrl.OnClose = HL.Override() << function(self)
    if self.m_closeCallback ~= nil then
        self.m_closeCallback()
    end
end
FacUnloaderSelectCtrl.ShowUnloaderSelect = HL.StaticMethod(HL.Table) << function(args)
    if args == nil then
        return
    end
    UIManager:AutoOpen(PANEL_ID, { buildingInfo = args.buildingInfo, selector = args.selector, subIndex = args.subIndex, selectCallback = args.selectCallback, openCallback = args.openCallback, closeCallback = args.closeCallback, })
    UIManager:SetTopOrder(PANEL_ID)
end
FacUnloaderSelectCtrl._InitUnloaderSelect = HL.Method() << function(self)
    local playerInBlackbox = ScopeUtil.IsPlayerInBlackbox()
    self.view.depot:InitDepot(GEnums.ItemValuableDepotType.Factory, function(itemId)
        self:_OnSelectItem(itemId)
    end, {
        showHistory = not playerInBlackbox,
        showEmptyChoice = true,
        disableDrag = true,
        nonValidShowTypes = { GEnums.ItemShowingType.Producer },
        sortOptions = { { name = Language.LUA_FAC_DEPOT_DEFAULT_SORT_NAME, keys = { "sortId1Neg", "sortId2", "rarity", "id" }, reverseKeys = { "sortId1", "sortId2", "rarity", "id" }, }, { name = Language.LUA_FAC_DEPOT_RARITY_SORT_NAME, keys = { "sortId1Neg", "rarity", "sortId2", "id" }, reverseKeys = { "sortId1", "rarity", "sortId2", "id" }, }, },
        customItemInfoListPreProcess = function(depotContent, allItemInfoList, depot)
            local contentItems = GameInstance.player.inventory.blackboxLevelDataContentItems
            if contentItems == nil then
                return
            end
            for _, id in pairs(contentItems) do
                local itemData = Tables.itemTable:GetValue(id)
                local facFound, facItemData = Tables.factoryItemTable:TryGetValue(id)
                local valid = true
                valid = GameInstance.player.inventory:IsPlaceInBag(itemData.type)
                if facFound then
                    valid = valid and facItemData ~= nil
                end
                if valid then
                    if not depot.normalItems:ContainsKey(id) then
                        local info = depotContent:_CreateItemInfo(id, 0)
                        table.insert(allItemInfoList, info)
                    end
                end
            end
        end,
        customItemInfoListPostProcess = function(allItemInfoList)
            if allItemInfoList == nil or next(allItemInfoList) == nil then
                return {}
            end
            local result = {}
            for _, info in ipairs(allItemInfoList) do
                local id = info.id
                local facSuccess, facItemData = Tables.factoryItemTable:TryGetValue(id)
                if facSuccess and facItemData.showInUnloader then
                    table.insert(result, info)
                end
            end
            return result
        end,
        customOnUpdateCell = function(cell, info, luaIndex)
            cell.item.redDot:Stop()
            if info then
                cell.item.view.button.clickHintTextId = "virtual_mouse_hint_select"
                cell.item.view.toggle.gameObject:SetActive(info.id == self.m_selector.selectItemId)
            end
        end,
    })
    local pdp = self.m_buildingInfo.nodeHandler.predefinedParam
    if pdp then
        local needBlock
        if self.m_subIndex and self.m_subIndex > 0 then
            if pdp.hub then
                local matched
                for i = 0, pdp.hub.selectors.Count - 1 do
                    local cur = pdp.hub.selectors[i]
                    if cur.index + 1 == self.m_subIndex then
                        matched = cur
                        break
                    end
                end
                if matched and matched.lockSelectedItemId then
                    needBlock = true
                end
            end
        else
            if pdp.selector and pdp.selector.lockSelectedItemId then
                needBlock = true
            end
        end
        if needBlock then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_FACTORY_BUILDING_SELECTOR_CHANGE_ITEM_ID_NOT_ALLOWED)
            return
        end
    end
end
FacUnloaderSelectCtrl._InitController = HL.Method() << function(self)
    if not DeviceInfo.usingController then
        return
    end
    local id = self.m_selector.selectItemId
    local content = self.view.depot.depotContent
    if string.isEmpty(id) then
        content.view.itemList:SetSelectedIndex(0, true, true, true)
    else
        content.view.itemList:SetSelectedIndex(CSIndex(content:GetItemIndex(id)), true, true, true)
    end
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
FacUnloaderSelectCtrl._OnSelectItem = HL.Method(HL.String) << function(self, itemId)
    if self.m_selectCallback ~= nil then
        self.m_selectCallback(itemId)
    end
    self:PlayAnimationOut(UIConst.PANEL_PLAY_ANIMATION_OUT_COMPLETE_ACTION_TYPE.Close)
end
HL.Commit(FacUnloaderSelectCtrl)