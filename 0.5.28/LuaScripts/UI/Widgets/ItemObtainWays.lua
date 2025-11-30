local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
ItemObtainWays = HL.Class('ItemObtainWays', UIWidgetBase)
ItemObtainWays.hasObtainWay = HL.Field(HL.Boolean) << false
ItemObtainWays.m_obtainCells = HL.Field(HL.Forward('UIListCache'))
ItemObtainWays.m_exitNaviBindingId = HL.Field(HL.Number) << -1
ItemObtainWays.m_itemTipsPosInfo = HL.Field(HL.Table)
ItemObtainWays._OnFirstTimeInit = HL.Override() << function(self)
    self.m_obtainCells = UIUtils.genCellCache(self.view.obtainCell)
    self.view.naviToObtainButton.onClick:AddListener(function()
        if InputManagerInst:IsBindingEnabled(self.m_exitNaviBindingId) then
            self:_ToggleNavi(false)
        else
            self:_ToggleNavi(true)
        end
    end)
    self.m_exitNaviBindingId = InputManagerInst:CreateBindingByActionId("item_tips_exit_obtain_ways", function()
        self:_ToggleNavi(false)
    end, self.view.inputBindingGroupMonoTarget.groupId)
    InputManagerInst:ToggleBinding(self.m_exitNaviBindingId, false)
end
ItemObtainWays._ToggleNavi = HL.Method(HL.Boolean) << function(self, active)
    if active then
        if self.hasObtainWay then
            local cell = self.m_obtainCells:Get(1)
            InputManagerInst.controllerNaviManager:SetTarget(cell.selectedTarget)
        else
            InputManagerInst.controllerNaviManager:SetTarget(self.view.emptyNode.button)
        end
    else
        InputManagerInst.controllerNaviManager:TryRemoveLayer(self.view.selectableNaviGroup)
    end
    InputManagerInst:ToggleBinding(self.m_exitNaviBindingId, active)
end
ItemObtainWays.InitItemObtainWays = HL.Method(HL.String, HL.Opt(HL.Number, HL.Table)) << function(self, itemId, instId, itemTipsPosInfo)
    self:_FirstTimeInit()
    self.m_itemTipsPosInfo = itemTipsPosInfo
    local itemCfg = Tables.itemTable:GetValue(itemId)
    local obtainInfoList = self:_GenerateObtainInfoList(itemId)
    self.hasObtainWay = next(obtainInfoList) ~= nil
    if self.hasObtainWay then
        self.view.gameObject:SetActive(true)
        self.view.emptyNode.gameObject:SetActive(false)
        self.m_obtainCells:Refresh(#obtainInfoList, function(cell, index)
            local obtainInfo = obtainInfoList[index]
            self:_RefreshObtainCell(cell, obtainInfo, index)
        end)
    else
        if string.isEmpty(itemCfg.noObtainWayHint) then
            self.view.gameObject:SetActive(false)
        else
            self.view.gameObject:SetActive(true)
            self.m_obtainCells:Refresh(0)
            self.view.emptyNode.gameObject:SetActive(true)
            self.view.emptyNode.nameTxt.text = UIUtils.resolveTextStyle(itemCfg.noObtainWayHint)
        end
    end
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.transform)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.emptyNode.nameTxt.transform)
end
ItemObtainWays._GenerateObtainInfoList = HL.Method(HL.String).Return(HL.Table) << function(self, itemId)
    local obtainInfoList = {}
    local itemCfg = Tables.itemTable:GetValue(itemId)
    if itemCfg.obtainWayIds then
        for k, obtainWayId in pairs(itemCfg.obtainWayIds) do
            local _, obtainWayCfg = Tables.systemJumpTable:TryGetValue(obtainWayId)
            if obtainWayCfg then
                local isUnlock = Utils.isSystemUnlocked(obtainWayCfg.bindSystem)
                if isUnlock then
                    local phaseId = PhaseId[obtainWayCfg.phaseId]
                    local phaseArgs
                    if not string.isEmpty(obtainWayCfg.phaseArgs) then
                        phaseArgs = Json.decode(obtainWayCfg.phaseArgs)
                    end
                    if not phaseId or PhaseManager:CheckCanOpenPhase(phaseId, phaseArgs) then
                        table.insert(obtainInfoList, { name = obtainWayCfg.desc, iconFolder = UIConst.UI_SPRITE_ITEM_TIPS, iconId = obtainWayCfg.iconId, phaseId = phaseId, phaseArgs = phaseArgs, sortId = -k / 1000, })
                    end
                end
            end
        end
    end
    local craftInfoList, canCraft = FactoryUtils.getItemCrafts(itemId)
    local hasFormula = next(craftInfoList) ~= nil
    if canCraft and hasFormula then
        self:_InsertCrafts(obtainInfoList, craftInfoList)
    end
    if self.view.config.ENABLE_DYNAMIC_SORT then
        table.sort(obtainInfoList, Utils.genSortFunction({ "sortId" }))
    end
    return obtainInfoList
end
ItemObtainWays._InsertCrafts = HL.Method(HL.Table, HL.Table) << function(self, obtainInfoList, craftInfoList)
    local manuSortId, sortId, curOpenedBuildingId
    if self.view.config.ENABLE_DYNAMIC_SORT then
        local topPhaseId = PhaseManager:GetTopPhaseId()
        if topPhaseId == PhaseId.PhaseFacMachine then
            curOpenedBuildingId = FactoryUtils.getCurOpenedBuildingId()
            sortId = 1
        else
            local inFac = Utils.isInFacMainRegion()
            manuSortId = inFac and 1 or -1
            sortId = inFac and 100 or -100
        end
    end
    local craftsByBuilding = {}
    local manualCrafts = {}
    for _, info in pairs(craftInfoList) do
        local buildingId = info.buildingId
        if not buildingId then
            table.insert(manualCrafts, info)
        else
            if not craftsByBuilding[buildingId] then
                craftsByBuilding[buildingId] = {}
            end
            table.insert(craftsByBuilding[buildingId], info)
        end
    end
    if next(manualCrafts) then
        for _, data in pairs(manualCrafts) do
            local info = { name = Language.LUA_OBTAIN_WAYS_MANUAL_CRAFT_NAME, crafts = manualCrafts, iconFolder = UIConst.UI_SPRITE_ITEM_TIPS, iconId = UIConst.UI_MANUALCRAFT_ICON_ID, phaseId = PhaseId.ManualCraft, phaseArgs = { jumpId = data.craftId }, sortId = manuSortId, }
            table.insert(obtainInfoList, info)
        end
    end
    for buildingId, crafts in pairs(craftsByBuilding) do
        local buildingData = Tables.factoryBuildingTable:GetValue(buildingId)
        local groupInfo = { buildingId = buildingId, name = buildingData.name, iconFolder = UIConst.UI_SPRITE_FAC_BUILDING_PANEL_ICON, iconId = buildingData.iconOnPanel, }
        if sortId then
            if curOpenedBuildingId == buildingId then
                groupInfo.sortId = 1000
            else
                groupInfo.sortId = sortId
            end
        end
        if buildingData.type == GEnums.FacBuildingType.Hub or buildingData.type == GEnums.FacBuildingType.SubHub then
            groupInfo.name = Language.ITEM_OBTAIN_WAY_HUB_CRAFT
            groupInfo.phaseId = PhaseId.FacHubCraft
            groupInfo.phaseArgs = { craftId = crafts[1].craftId }
        end
        for _, info in pairs(crafts) do
            if buildingData.type ~= GEnums.FacBuildingType.Miner then
                if not groupInfo.crafts then
                    groupInfo.crafts = {}
                end
                table.insert(groupInfo.crafts, info)
            end
        end
        table.insert(obtainInfoList, groupInfo)
    end
end
local jumpBlockWhiteMap = { [PhaseId.CommonMoneyExchange] = true, }
ItemObtainWays._RefreshObtainCell = HL.Method(HL.Any, HL.Table, HL.Number) << function(self, cell, info, index)
    cell.selectedTarget = cell.normalNode.button
    cell.normalNode.nameTxt.text = info.name
    local iconId = info.iconId
    local iconFolder = info.iconFolder
    cell.normalNode.icon.gameObject:SetActive(iconId ~= nil and iconFolder ~= nil)
    if iconId ~= nil and iconFolder ~= nil then
        cell.normalNode.icon.sprite = self:LoadSprite(info.iconFolder, info.iconId)
    end
    self:_UpdateCraftCell(cell, info)
    cell.normalNode.button.onClick:RemoveAllListeners()
    if info.phaseId or not string.isEmpty(info.buildingId) then
        cell.normalNode.animationNode:PlayInAnimation()
        cell.normalNode.button.enabled = true
        cell.normalNode.button.onClick:AddListener(function()
            if UIManager:ShouldBlockObtainWaysJump() and not jumpBlockWhiteMap[info.phaseId] then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_OBTAIN_WAYS_JUMP_BLOCKED)
                return
            end
            Notify(MessageConst.HIDE_ITEM_TIPS)
            if info.phaseId then
                PhaseManager:GoToPhase(info.phaseId, info.phaseArgs)
            else
                Notify(MessageConst.SHOW_WIKI_ENTRY, { buildingId = info.buildingId })
            end
        end)
    else
        cell.normalNode.button.enabled = false
        cell.normalNode.animationNode:PlayOutAnimation()
    end
    LayoutRebuilder.ForceRebuildLayoutImmediate(cell.transform)
    cell.gameObject.name = "ObtainWay-" .. index
end
ItemObtainWays._UpdateCraftCell = HL.Method(HL.Table, HL.Table) << function(self, cell, info)
    if not cell.craftCells then
        cell.craftCells = UIUtils.genCellCache(cell.craftCell)
    end
    if not info.crafts then
        cell.craftCells:Refresh(0)
        return
    end
    local craftCount = #info.crafts
    cell.craftCells:Refresh(craftCount, function(craftCell, craftIndex)
        local craftInfo = info.crafts[craftIndex]
        if not craftCell.itemCells then
            craftCell.itemCells = UIUtils.genCellCache(craftCell.itemCell)
        end
        local incomeCount = craftInfo.incomes and #craftInfo.incomes or 0
        local outcomeCount = craftInfo.outcomes and #craftInfo.outcomes or 0
        craftCell.itemCells:Refresh(incomeCount + outcomeCount, function(itemCell, itemIndex)
            local bundle
            if itemIndex <= incomeCount then
                bundle = craftInfo.incomes[itemIndex]
            else
                bundle = craftInfo.outcomes[itemIndex - incomeCount]
            end
            if self.view.config.IS_SIMPLE_ITEM then
                itemCell:InitItemSimple(bundle.id, bundle.count)
            else
                itemCell:InitItem(bundle, self.view.config.IS_ITEM_SHOW_TIPS)
                if self.m_itemTipsPosInfo then
                    itemCell:SetExtraInfo(self.m_itemTipsPosInfo)
                end
            end
            itemCell.transform:SetSiblingIndex(itemIndex)
            itemCell.gameObject.name = "Item-" .. bundle.id
        end)
        craftCell.arrow.transform:SetSiblingIndex(incomeCount + 1)
        craftCell.line.gameObject:SetActive(craftIndex ~= craftCount)
        craftCell.mask.gameObject:SetActive(craftIndex == 1)
        craftCell.gameObject.name = "Craft-" .. craftInfo.craftId
        if craftCell.pinBtn then
            local showPin = not string.isEmpty(craftInfo.craftId) and Tables.factoryMachineCraftTable:ContainsKey(craftInfo.craftId)
            craftCell.pinBtn.gameObject:SetActive(showPin)
            if showPin then
                craftCell.pinBtn:InitPinBtn(craftInfo.craftId, GEnums.FCPinPosition.Formula:GetHashCode())
            end
        end
        if craftCell.add then
            if not craftCell.addCells then
                craftCell.addCells = UIUtils.genCellCache(craftCell.add)
            end
            craftCell.addCells:Refresh(incomeCount + outcomeCount - 2, function(addCell, addCellIndex)
                local siblingIndex = 0
                if addCellIndex <= incomeCount - 1 then
                    siblingIndex = addCellIndex * 2
                else
                    siblingIndex = (addCellIndex + 1) * 2
                end
                addCell.transform:SetSiblingIndex(siblingIndex)
            end)
        end
        if self.view.config.IS_SHOW_CRAFT_TIME then
            if craftInfo.time then
                craftCell.time.text = string.format("%.1fs", craftInfo.time)
                craftCell.time.gameObject:SetActive(true)
            else
                craftCell.time.gameObject:SetActive(false)
            end
        else
            craftCell.time.gameObject:SetActive(false)
        end
    end)
end
HL.Commit(ItemObtainWays)
return ItemObtainWays