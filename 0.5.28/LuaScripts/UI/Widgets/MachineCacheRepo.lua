local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
MachineCacheRepo = HL.Class('MachineCacheRepo', UIWidgetBase)
MachineCacheRepo.m_repository = HL.Field(CS.Beyond.Gameplay.RemoteFactory.FBUtil.Cache)
MachineCacheRepo.m_producerUIInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.BuildingUIInfo_Producer)
MachineCacheRepo.m_isInput = HL.Field(HL.Boolean) << false
MachineCacheRepo.m_luaIndex = HL.Field(HL.Number) << 1
MachineCacheRepo.m_forceWhiteNode = HL.Field(HL.Boolean) << false
MachineCacheRepo.m_onGetCraftOrder = HL.Field(HL.Function)
MachineCacheRepo.m_isMachineBlock = HL.Field(HL.Boolean) << false
MachineCacheRepo._OnFirstTimeInit = HL.Override() << function(self)
end
MachineCacheRepo.InitMachineCacheRepo = HL.Method(CS.Beyond.Gameplay.RemoteFactory.FBUtil.Cache, HL.Opt(CS.Beyond.Gameplay.RemoteFactory.BuildingUIInfo_Producer, HL.Boolean, HL.Number, HL.Boolean)) << function(self, repository, producerUIInfo, isInput, luaIndex, forceWhiteNode)
    if not repository then
        logger.error("repository is null")
        return
    end
    self:_FirstTimeInit()
    self.m_repository = repository
    self.m_isInput = isInput == true
    self.m_luaIndex = luaIndex or 1
    self.m_forceWhiteNode = forceWhiteNode == true
    self.view.repositoryContent:InitRepositoryContent(repository, nil, {
        showAllSlot = isInput,
        customOnUpdateCell = function(cell, info, cellLuaIndex)
            if info then
                self:_OnUpdateCell(cell, info, cellLuaIndex)
            end
        end,
        insertCustomListData = function(sortedList)
            self:_InsertListData(sortedList)
        end,
        disableAutoHighlightForDrop = true,
        typeLimitCount = Tables.factoryConst.machineCrafterBufferSlotCount,
        index = self.m_luaIndex,
    })
    self.view.repositoryContent:ToggleAcceptDrop(isInput == true)
    if producerUIInfo then
        self.m_producerUIInfo = producerUIInfo
        if producerUIInfo.onFormulaChanged then
            self.m_onGetCraftOrder = function()
                self:_OnCraftChanged()
            end
            producerUIInfo.onFormulaChanged:AddListener(self.m_onGetCraftOrder)
        end
        self:_OnCraftChanged()
    end
end
MachineCacheRepo.RefreshRepository = HL.Method() << function(self)
    self.view.repositoryContent:RefreshAll()
end
MachineCacheRepo.ToggleBlockState = HL.Method(HL.Boolean) << function(self, isBlock)
    self.m_isMachineBlock = isBlock
    self:RefreshRepository()
end
MachineCacheRepo.ToggleWirelessMode = HL.Method(HL.Boolean) << function(self, isOn)
    self.view.info.gameObject:SetActive(not isOn)
    self.view.wirelessInfo.gameObject:SetActive(isOn)
    self.view.wirelessMask.gameObject:SetActive(isOn)
end
MachineCacheRepo.FreshCacheState = HL.Method(HL.Int, HL.Number, HL.Number) << function(self, buildingState, timeRemain, percent)
    self.view.fillBG.fillAmount = percent
    local timeText = self.view.timeText
    timeText.text = UIUtils.getRemainingText(timeRemain)
    local timeTextColor = timeText.color
    local timeProgressColor = self.view.fillBG.color
    if buildingState == GEnums.FacBuildingState.Normal then
        timeTextColor.a = 1
        timeProgressColor.a = 1
        self.view.pauseMask.gameObject:SetActive(false)
        self.view.wirelessMask.gameObject:SetActive(true)
    else
        timeTextColor.a = 0.5
        timeProgressColor.a = 0.5
        self.view.pauseMask.gameObject:SetActive(true)
        self.view.wirelessMask.gameObject:SetActive(false)
    end
    timeText.color = timeTextColor
    self.view.fillBG.color = timeProgressColor
end
MachineCacheRepo._OnUpdateCell = HL.Method(HL.Any, HL.Opt(HL.Table, HL.Number)) << function(self, cell, info, cellLuaIndex)
    local craftId = self:_GetCraftId()
    local isInCraft = false
    local isItemExist = info and not string.isEmpty(info.id)
    if not string.isEmpty(craftId) then
        local craftData = Tables.factoryMachineCraftTable:GetValue(craftId)
        local list = self.m_isInput and craftData.ingredients or craftData.outcomes
        if self.m_luaIndex <= list.Count then
            local itemBundleGroup = (self.m_isInput and craftData.ingredients or craftData.outcomes)[CSIndex(self.m_luaIndex)]
            for _, bundle in pairs(itemBundleGroup.group) do
                if bundle.id == info.id then
                    isInCraft = true
                    break
                end
            end
        end
    end
    cell.view.bg.gameObject:SetActive(isItemExist)
    cell.view.item.view.normalBG.gameObject:SetActive(false)
    cell.view.blockNode.gameObject:SetActive(self.m_isMachineBlock)
    cell.view.item:UpdateCount(info.count, info.maxStackCount, true, false, "%s<color=#B1B1B1>/%s</color>")
end
MachineCacheRepo._InsertListData = HL.Method(HL.Table) << function(self, sortedList)
    local craftId = self:_GetCraftId()
    if string.isEmpty(craftId) then
        return
    end
    local craftData = Tables.factoryMachineCraftTable:GetValue(craftId)
    local list = self.m_isInput and craftData.ingredients or craftData.outcomes
    if self.m_luaIndex > list.Count then
        return
    end
    local itemBundleGroup = list[CSIndex(self.m_luaIndex)]
    for _, bundle in pairs(itemBundleGroup.group) do
        local id = bundle.id
        if self.m_repository:GetCount(id) == 0 then
            table.insert(sortedList, { id = id, count = 0, })
        end
    end
end
MachineCacheRepo._OnCraftChanged = HL.Method() << function(self)
    local craftId = self:_GetCraftId()
    local lines = self.view.lines
    local repoCount, itemCount
    if string.isEmpty(craftId) then
        repoCount = self.m_producerUIInfo[self.m_isInput and "cacheInCount" or "cacheOutCount"]
        itemCount = 1
    else
        local craftData = Tables.factoryMachineCraftTable:GetValue(craftId)
        local list = self.m_isInput and craftData.ingredients or craftData.outcomes
        local bundleGroup = list[CSIndex(self.m_luaIndex)]
        repoCount = list.Count
        itemCount = bundleGroup.group.Count
    end
    if repoCount == 1 and itemCount == 1 then
        lines.straight.gameObject:SetActive(true)
        self:_ChangeLineColor(lines.straight)
    else
        lines.straight.gameObject:SetActive(false)
    end
    if repoCount == 1 and itemCount > 1 then
        lines.merge.gameObject:SetActive(true)
        self:_ChangeLineColor(lines.merge)
    else
        lines.merge.gameObject:SetActive(false)
    end
    if repoCount > 1 and self.m_luaIndex == 1 then
        lines.first.gameObject:SetActive(true)
        self:_ChangeLineColor(lines.first)
    else
        lines.first.gameObject:SetActive(false)
    end
    if repoCount > 1 and self.m_luaIndex > 1 then
        lines.second.gameObject:SetActive(true)
        self:_ChangeLineColor(lines.second)
    else
        lines.second.gameObject:SetActive(false)
    end
end
MachineCacheRepo._ChangeLineColor = HL.Method(HL.Table) << function(self, node)
    local color = self:_GetLineColor()
    if node.arrowFrom then
        node.arrowFrom.color = color
    end
    if node.arrowTo then
        node.arrowTo.color = color
    end
    if node.arrowTo1 then
        node.arrowTo1.color = color
    end
    if node.arrowTo2 then
        node.arrowTo2.color = color
    end
    self.view.portIcon.color = color
    self.view.connectPortIcon.color = color
end
MachineCacheRepo._GetLineColor = HL.Method().Return(HL.Any) << function(self)
    if self.m_forceWhiteNode then
        return self.view.config.OUTCOME_COLOR_WHITE
    end
    local colorKey
    if self.m_isInput then
        colorKey = "INCOME_COLOR_" .. self.m_luaIndex
    else
        colorKey = "OUTCOME_COLOR_" .. self.m_luaIndex
    end
    return self.view.config[colorKey]
end
MachineCacheRepo._GetCraftId = HL.Method().Return(HL.Opt(HL.String)) << function(self)
    return self.m_producerUIInfo and self.m_producerUIInfo.lastFormulaId
end
MachineCacheRepo._OnDestroy = HL.Override() << function(self)
    if self.m_onGetCraftOrder then
        self.m_producerUIInfo.onFormulaChanged:RemoveListener(self.m_onGetCraftOrder)
    end
end
MachineCacheRepo.QuickMoveContent = HL.Method(HL.Number) << function(self, delay)
    local core = GameInstance.player.remoteFactory.core
    local componentId = self.m_repository.componentId
    local ids = {}
    for id, _ in pairs(self.m_repository.items) do
        table.insert(ids, id)
    end
    self:_StartCoroutine(function()
        coroutine.wait(delay)
        for _, id in pairs(ids) do
            core:Message_OpMoveItemCacheToBag(Utils.getCurrentChapterId(), componentId, id)
            coroutine.wait(0.15)
        end
    end)
end
HL.Commit(MachineCacheRepo)
return MachineCacheRepo