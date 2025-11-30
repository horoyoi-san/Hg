local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacHubCraft
FacHubCraftCtrl = HL.Class('FacHubCraftCtrl', uiCtrl.UICtrl)
FacHubCraftCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_HUB_CRAFT_SUCC] = 'OnHubCraftSucc', }
FacHubCraftCtrl.m_nodeId = HL.Field(HL.Any)
FacHubCraftCtrl.m_currSelectedIndex = HL.Field(HL.Number) << 1
FacHubCraftCtrl.m_readCraftIds = HL.Field(HL.Table)
FacHubCraftCtrl.m_lastNum = HL.Field(HL.Number) << 0
FacHubCraftCtrl.m_inMainRegion = HL.Field(HL.Boolean) << false
FacHubCraftCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_inMainRegion = Utils.isInFacMainRegion()
    arg = arg or {}
    local nodeId = arg.nodeId
    if not nodeId and self.m_inMainRegion then
        nodeId = FactoryUtils.getCurHubNodeId()
    end
    self.m_nodeId = nodeId
    self.view.closeBtn.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.FacHubCraft)
    end)
    self.view.confirmBtn.onClick:AddListener(function()
        self:_OnClickConfirm()
    end)
    self.view.outcomeWikiBtn.onClick:AddListener(function()
        self:_OnClickWiki()
    end)
    self.m_readCraftIds = {}
    self:_InitCraftList()
    if arg.craftId then
        self:_GoToCraft(arg.craftId)
    elseif arg.itemId then
        self:_GoToItem(arg.itemId)
    else
        self:_OnClickCraftCell(1)
    end
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.FAC_COMMON_UI_UPDATE_INTERVAL)
            self:_RefreshCount()
            self:_RefreshCraftListEnoughState()
        end
    end)
end
FacHubCraftCtrl.OnPhaseRefresh = HL.Override(HL.Opt(HL.Any)) << function(self, arg)
    if not arg then
        return
    end
    if arg.craftId then
        self:_GoToCraft(arg.craftId)
    elseif arg.itemId then
        self:_GoToItem(arg.itemId)
    end
end
FacHubCraftCtrl._GoToItem = HL.Method(HL.String) << function(self, itemId)
    local hasCraft, craftIds = Tables.FactoryItemAsHubCraftOutcomeTable:TryGetValue(itemId)
    if hasCraft then
        local facCore = GameInstance.player.remoteFactory.core
        for _, craftId in pairs(craftIds.list) do
            if facCore:IsFormulaVisible(craftId) then
                self:_GoToCraft(craftId)
                return
            end
        end
    end
    Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_HUB_CRAFT_ITEM_LOCKED)
end
FacHubCraftCtrl._GoToCraft = HL.Method(HL.String) << function(self, craftId)
    for k, tabInfo in ipairs(self.m_crafts) do
        if k > 1 then
            for kk, craftInfo in ipairs(tabInfo.list) do
                if craftInfo.id == craftId then
                    self.view.facCraftList.m_typeCells:Get(k).toggle.isOn = true
                    self:_OnClickCraftCell(kk)
                    self.view.facCraftList.craftList:ScrollToIndex(CSIndex(kk), true)
                    return
                end
            end
        end
    end
    Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_HUB_CRAFT_ITEM_LOCKED)
end
FacHubCraftCtrl.m_crafts = HL.Field(HL.Table)
FacHubCraftCtrl._InitCraftsData = HL.Method() << function(self)
    local crafts = {}
    local typeIndexMap = {}
    do
        local names = CS.System.Enum.GetNames(typeof(GEnums.CraftShowingType))
        local index = 1
        for k = 1, names.Length - 1 do
            local succ, data = Tables.factoryCraftShowingTypeTable:TryGetValue(k)
            if succ then
                crafts[index] = { name = data.name, icon = data.icon, type = data.type, priority = data.priority, list = {} }
                typeIndexMap[data.type] = index
                index = index + 1
            end
        end
    end
    for _, data in pairs(Tables.factoryHubCraftTable) do
        if FactoryUtils.isSpMachineFormulaUnlocked(data.id) then
            local index = typeIndexMap[data.showingType]
            if index then
                local info = { id = data.id, rarity = data.rarity, sortId = data.sortId, data = data, }
                table.insert(crafts[index].list, info)
            end
        end
    end
    local allItems = {}
    local allTypeInfo = { name = Language.LUA_FAC_ALL, icon = "icon_type_all", type = 0, priority = math.maxinteger, list = allItems, }
    self.m_crafts = { allTypeInfo }
    for k, v in ipairs(crafts) do
        if #v.list > 0 then
            table.insert(self.m_crafts, v)
        end
    end
    table.sort(self.m_crafts, Utils.genSortFunction({ "priority" }))
    for k = 2, #self.m_crafts do
        local typeInfo = self.m_crafts[k]
        for _, v in ipairs(typeInfo.list) do
            table.insert(allItems, v)
        end
    end
end
FacHubCraftCtrl._ReadFormulas = HL.Method() << function(self)
    if not next(self.m_readCraftIds) then
        return
    end
    local craftIds = {}
    for k, _ in pairs(self.m_readCraftIds) do
        table.insert(craftIds, k)
    end
    self.m_readCraftIds = {}
    GameInstance.player.remoteFactory.core:ReadFormula(craftIds)
end
FacHubCraftCtrl.OnClose = HL.Override() << function(self)
    self:_ReadFormulas()
end
FacHubCraftCtrl.m_getCraftCell = HL.Field(HL.Function)
FacHubCraftCtrl._InitCraftList = HL.Method() << function(self)
    local craftList = self.view.facCraftList.craftList
    if craftList == nil then
        return
    end
    self.m_getCraftCell = UIUtils.genCachedCellFunction(craftList)
    craftList.onUpdateCell:AddListener(function(object, csIndex)
        self:_OnUpdateCell(object, LuaIndex(csIndex))
    end)
    self:_InitCraftsData()
    self.view.facCraftList:InitFacCraftList(self.m_crafts, function()
        if next(self.view.facCraftList.curList) then
            self:_OnClickCraftCell(1)
        end
    end, function()
        if next(self.view.facCraftList.curList) then
            if string.isEmpty(self.m_curCraftId) then
                self:_OnClickCraftCell(1)
            end
        else
            self.m_curCraftId = ""
            self.m_currSelectedIndex = -1
            self:_RefreshCraftNode()
        end
    end)
end
FacHubCraftCtrl._OnUpdateCell = HL.Method(HL.Userdata, HL.Number) << function(self, object, index)
    local cell = self.m_getCraftCell(object)
    local info = self.view.facCraftList.curList[index]
    cell.gameObject.name = "Cell_" .. info.id
    cell.content.onClick:RemoveAllListeners()
    cell.content.onClick:AddListener(function()
        self:_OnClickCraftCell(index)
    end)
    local data = info.data
    local outcomeId = data.outcomes[0].id
    local outcomeData = Tables.itemTable:GetValue(outcomeId)
    cell.nameTxt.text = outcomeData.name
    cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, outcomeData.iconId)
    UIUtils.setItemRarityImage(cell.rarityIndicator, data.rarity)
    cell.redDot:InitRedDot("Formula", info.id)
    self.m_readCraftIds[info.id] = true
    self:_SetCraftCellActive(cell, info.id == self.m_curCraftId, true)
    self:_UpdateCraftCellEnoughState(cell, info.data)
end
FacHubCraftCtrl._SetCraftCellActive = HL.Method(HL.Table, HL.Boolean, HL.Opt(HL.Boolean)) << function(self, cell, active, noTween)
    if active then
        cell.redDot.gameObject:SetActiveIfNecessary(false)
    end
    if noTween then
        if active then
            cell.contentAnimationWrapper:SampleToInAnimationEnd()
        else
            cell.contentAnimationWrapper:SampleToOutAnimationEnd()
        end
    else
        if active then
            cell.contentAnimationWrapper:PlayInAnimation()
        else
            cell.contentAnimationWrapper:PlayOutAnimation()
        end
    end
end
FacHubCraftCtrl._OnClickCraftCell = HL.Method(HL.Number) << function(self, index)
    local oldIndex
    for k, v in ipairs(self.view.facCraftList.curList) do
        if v.id == self.m_curCraftId then
            oldIndex = k
            break
        end
    end
    if oldIndex == index then
        return
    end
    if oldIndex then
        local oldCell = self.m_getCraftCell(oldIndex)
        if oldCell then
            self:_SetCraftCellActive(oldCell, false)
        end
    end
    local cell = self.m_getCraftCell(index)
    if cell then
        self:_SetCraftCellActive(cell, true)
    end
    local info = self.view.facCraftList.curList[index]
    self.m_curCraftId = info.id
    self.m_currSelectedIndex = index
    self:_RefreshCraftNode()
    GameInstance.player.remoteFactory.core:ReadFormula({ info.id })
end
FacHubCraftCtrl._RefreshCraftListEnoughState = HL.Method() << function(self)
    local curList = self.view.facCraftList.curList
    for luaIndex, info in ipairs(curList) do
        local cell = self.m_getCraftCell(luaIndex)
        if cell then
            self:_UpdateCraftCellEnoughState(cell, info.data)
        end
    end
end
FacHubCraftCtrl._UpdateCraftCellEnoughState = HL.Method(HL.Table, HL.Userdata) << function(self, cell, data)
    local isEnough = true
    for _, itemBundle in pairs(data.ingredients) do
        local count = Utils.getItemCount(itemBundle.id, true, true)
        if count < itemBundle.count then
            isEnough = false
            break
        end
    end
    cell.canMakeTxt.text = isEnough and Language.LUA_FAC_HUB_CRAFT_CAN_MAKE or Language.LUA_FAC_HUB_CRAFT_CANT_MAKE
    cell.notEnoughNode.gameObject:SetActive(not isEnough)
end
FacHubCraftCtrl.m_curCraftId = HL.Field(HL.String) << ""
FacHubCraftCtrl._RefreshCraftNode = HL.Method() << function(self)
    local craftId = self.m_curCraftId
    if string.isEmpty(craftId) then
        self.view.centerNode:SetState("Empty")
        return
    end
    self.view.centerNode:SetState("Normal")
    local data = Tables.factoryHubCraftTable:GetValue(craftId)
    local outcome = data.outcomes[0]
    local outcomeItemData = Tables.itemTable[outcome.id]
    self.view.outcomeNameTxt.text = outcomeItemData.name
    self.view.outcomeDesc.text = outcomeItemData.desc
    UIUtils.setItemRarityImage(self.view.outcomeRarity1, outcomeItemData.rarity)
    UIUtils.setItemRarityImage(self.view.outcomeRarity2, outcomeItemData.rarity)
    self.view.outcomeItemIcon:LoadSprite(UIConst.UI_SPRITE_FAC_BUILDING_IMAGE, string.format("image_%s", FactoryUtils.getItemBuildingId(outcome.id)))
    for index = 1, FacConst.FAC_HUB_CRAFT_MAX_INCOME_NUM do
        local cell = self.view["incomeCell" .. index]
        if data.ingredients.length >= index then
            cell.emptyBG.gameObject:SetActive(false)
            cell.content.gameObject:SetActive(true)
            local itemBundle = data.ingredients[CSIndex(index)]
            cell.item:InitItem(itemBundle, true)
        else
            cell.emptyBG.gameObject:SetActive(true)
            cell.content.gameObject:SetActive(false)
        end
    end
    self:_RefreshCount()
end
FacHubCraftCtrl._RefreshCount = HL.Method() << function(self)
    if string.isEmpty(self.m_curCraftId) then
        return
    end
    local data = Tables.factoryHubCraftTable:GetValue(self.m_curCraftId)
    local maxMakeCount = math.maxinteger
    for index = 1, FacConst.FAC_HUB_CRAFT_MAX_INCOME_NUM do
        if data.ingredients.length >= index then
            local itemBundle = data.ingredients[CSIndex(index)]
            local count = Utils.getItemCount(itemBundle.id, true, true)
            maxMakeCount = math.min(maxMakeCount, math.floor(count / itemBundle.count))
        end
    end
    UIUtils.setItemStorageCountText(self.view.outcomeStorageNode, data.outcomes[0].id, 0, true)
    if self.m_inMainRegion then
        self.view.notInMainRegionHint.gameObject:SetActive(false)
        local isZero = maxMakeCount == 0
        self.view.confirmBtn.gameObject:SetActive(not isZero)
        self.view.notEnoughHint.gameObject:SetActive(isZero)
    else
        self.view.notInMainRegionHint.gameObject:SetActive(true)
        self.view.confirmBtn.gameObject:SetActive(false)
        self.view.notEnoughHint.gameObject:SetActive(false)
    end
    local numSelector = self.view.numberSelector
    numSelector:InitNumberSelector(numSelector.curNumber, math.min(maxMakeCount, 1), maxMakeCount, function()
        self:_OnCurCountChange()
    end)
end
FacHubCraftCtrl._OnCurCountChange = HL.Method() << function(self)
    local data = Tables.factoryHubCraftTable:GetValue(self.m_curCraftId)
    for index = 1, FacConst.FAC_HUB_CRAFT_MAX_INCOME_NUM do
        if data.ingredients.length >= index then
            local itemBundle = data.ingredients[CSIndex(index)]
            local count = Utils.getItemCount(itemBundle.id, true, true)
            local cell = self.view["incomeCell" .. index]
            local costCount = math.max(itemBundle.count, itemBundle.count * self.view.numberSelector.curNumber)
            local isEnough = count >= costCount
            cell.item:UpdateCountSimple(costCount, not isEnough)
            UIUtils.setItemStorageCountText(cell.storageNode, itemBundle.id, costCount, true)
        end
    end
end
FacHubCraftCtrl._OnClickConfirm = HL.Method() << function(self)
    local id = self.m_curCraftId
    local count = self.view.numberSelector.curNumber
    self.m_lastNum = count
    if string.isEmpty(id) or count == 0 then
        return
    end
    local data = Tables.factoryHubCraftTable:GetValue(id)
    for i = 1, data.ingredients.Count do
        local itemBundle = data.ingredients[CSIndex(i)]
        FactoryUtils.gameEventFactoryItemPush(self.m_nodeId, itemBundle.id, itemBundle.count * count, {})
    end
    GameInstance.player.facSpMachineSystem:StartHubCraft(self.m_nodeId, id, count)
end
FacHubCraftCtrl.OnHubCraftSucc = HL.Method() << function(self)
    local id = self.m_curCraftId
    local count = self.m_lastNum
    local info = {
        title = Language.LUA_FAC_WORKSHOP_REWARD_POP_TITLE,
        subTitle = Language.LUA_FAC_WORKSHOP_REWARD_POP_SUB_TITLE,
        onComplete = function()
            self:_RefreshCount()
            Notify(MessageConst.ON_FINISH_WORKSHOP_CRAFT, id)
        end,
    }
    local data = Tables.factoryHubCraftTable:GetValue(id)
    local outcome = data.outcomes[0]
    info.items = {}
    for _, v in pairs(data.outcomes) do
        table.insert(info.items, { id = v.id, count = v.count * count, })
    end
    Notify(MessageConst.SHOW_CRAFT_REWARDS, info)
end
FacHubCraftCtrl._OnClickWiki = HL.Method() << function(self)
    local id = self.m_curCraftId
    local data = Tables.factoryHubCraftTable:GetValue(id)
    local outcome = data.outcomes[0]
    Notify(MessageConst.SHOW_ITEM_TIPS, { transform = self.view.outcomeWikiBtn.transform, itemId = outcome.id, })
end
HL.Commit(FacHubCraftCtrl)