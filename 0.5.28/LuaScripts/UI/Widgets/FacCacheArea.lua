local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
FacCacheArea = HL.Class('FacCacheArea', UIWidgetBase)
FacCacheArea.m_onInitializeFinished = HL.Field(HL.Function)
FacCacheArea._OnFirstTimeInit = HL.Override() << function(self)
end
FacCacheArea._OnDestroy = HL.Override() << function(self)
    self:_ClearBuildingInfo()
end
FacCacheArea.InitFacCacheArea = HL.Method(HL.Table) << function(self, areaData)
    self:_FirstTimeInit()
    if areaData == nil then
        return
    end
    self.m_buildingInfo = areaData.buildingInfo
    self.m_inRepositoryChangedCallback = areaData.inChangedCallback or function()
    end
    self.m_outRepositoryChangedCallback = areaData.outChangedCallback or function()
    end
    self.m_onInitializeFinished = areaData.onInitializeFinished or function()
    end
    self.m_inRepositoryList = {}
    self.m_outRepositoryList = {}
    self:_InitBuildingInfo()
    self:_InitAreaRepositoryList(true)
    if self.m_onInitializeFinished ~= nil then
        self.m_onInitializeFinished()
    end
end
FacCacheArea.m_buildingInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.BuildingUIInfo_Producer)
FacCacheArea._InitBuildingInfo = HL.Method() << function(self)
    local buildingInfo = self.m_buildingInfo
    if buildingInfo == nil then
        return
    end
    self.m_onFormulaChanged = function(formulaId)
        self:_OnFormulaChanged(formulaId, buildingInfo.lastFormulaId)
    end
    buildingInfo.onFormulaChanged:AddListener(self.m_onFormulaChanged)
end
FacCacheArea._ClearBuildingInfo = HL.Method() << function(self)
    if self.m_buildingInfo == nil then
        return
    end
    self.m_buildingInfo.onFormulaChanged:RemoveListener(self.m_onFormulaChanged)
end
FacCacheArea.m_inRepositoryList = HL.Field(HL.Table)
FacCacheArea.m_outRepositoryList = HL.Field(HL.Table)
FacCacheArea.m_inRepositoryChangedCallback = HL.Field(HL.Function)
FacCacheArea.m_outRepositoryChangedCallback = HL.Field(HL.Function)
FacCacheArea._InitAreaRepositoryList = HL.Method(HL.Opt(HL.Boolean)) << function(self, needDelayInit)
    local layoutData = FactoryUtils.getMachineCraftCacheLayoutData(self.m_buildingInfo.nodeId)
    if layoutData == nil then
        return
    end
    local viewRepoList = { self.view.inRepositoryList.repository1, self.view.inRepositoryList.repository2, self.view.outRepositoryList.repository1, self.view.outRepositoryList.repository2, }
    for _, repo in ipairs(viewRepoList) do
        repo.gameObject:SetActive(false)
    end
    self.m_inRepositoryList = {}
    self.m_outRepositoryList = {}
    local normalInitRepoList = { { cache = layoutData.normalIncomeCaches, isIn = true, }, { cache = layoutData.normalOutcomeCaches, isIn = false, }, }
    local fluidInitRepoList = { { cache = layoutData.fluidIncomeCaches, isIn = true, }, { cache = layoutData.fluidOutcomeCaches, isIn = false, }, }
    if needDelayInit then
        coroutine.step()
    end
    for _, initInfo in ipairs(normalInitRepoList) do
        self:_InitAreaRepositoryListByCaches(initInfo.cache, initInfo.isIn, false)
    end
    for _, initInfo in ipairs(fluidInitRepoList) do
        self:_InitAreaRepositoryListByCaches(initInfo.cache, initInfo.isIn, true)
    end
end
FacCacheArea._InitAreaRepositoryListByCaches = HL.Method(HL.Table, HL.Boolean, HL.Boolean) << function(self, caches, isIn, isFluid)
    local repoList = isIn and self.m_inRepositoryList or self.m_outRepositoryList
    local viewRepoList = isIn and self.view.inRepositoryList or self.view.outRepositoryList
    local lockFormulaId = FactoryUtils.getMachineCraftLockFormulaId(self.m_buildingInfo.nodeId)
    for cacheIndex, cache in ipairs(caches) do
        local viewRepoName = string.format("repository%d", #repoList + 1)
        local repo = viewRepoList[viewRepoName]
        if repo ~= nil then
            repo:InitFacCacheRepository({ cache = self.m_buildingInfo:GetCache(cacheIndex, isIn, isFluid), isInCache = isIn, isFluidCache = isFluid, cacheIndex = cacheIndex, slotCount = cache.slotCount, formulaId = self.m_buildingInfo.formulaId, lastFormulaId = self.m_buildingInfo.lastFormulaId, lockFormulaId = lockFormulaId, cacheChangedCallback = isIn and self.m_inRepositoryChangedCallback or self.m_outRepositoryChangedCallback, producerInfo = self.m_buildingInfo, })
            repo.gameObject:SetActive(true)
            table.insert(repoList, repo)
        end
    end
end
FacCacheArea._GetAreaRepositoryItemCount = HL.Method(HL.Table, HL.Boolean).Return(HL.Number) << function(self, crafts, isIn)
    if crafts == nil then
        return 0
    end
    local result = 0
    for _, craftInfo in pairs(crafts) do
        local itemInfoList = isIn and craftInfo.incomes or craftInfo.outcomes
        if itemInfoList ~= nil then
            local count = 0
            for _, itemInfo in pairs(itemInfoList) do
                if itemInfo ~= nil and not string.isEmpty(itemInfo.id) then
                    count = count + 1
                end
            end
            if count > result then
                result = count
            end
            if result > 0 and result ~= count then
                logger.error("FacCacheArea: 当前机器配方格式不一致")
                break
            end
        end
    end
    return result
end
FacCacheArea._GetAreaRepositorySlotGroup = HL.Method(HL.Boolean, HL.Table).Return(HL.Table) << function(self, isFluid, repoList)
    local slotGroup = {}
    if repoList == nil then
        return slotGroup
    end
    for _, repo in ipairs(repoList) do
        if isFluid == repo:GetIsFluidCache() then
            table.insert(slotGroup, repo:GetRepositorySlotList())
        end
    end
    return slotGroup
end
FacCacheArea.m_onFormulaChanged = HL.Field(HL.Function)
FacCacheArea._OnFormulaChanged = HL.Method(HL.String, HL.String) << function(self, formulaId, lastFormulaId)
    for _, repo in pairs(self.m_inRepositoryList) do
        repo:UpdateRepositoryFormula(formulaId, lastFormulaId)
    end
    for _, repo in pairs(self.m_outRepositoryList) do
        repo:UpdateRepositoryFormula(formulaId, lastFormulaId)
    end
end
FacCacheArea.RefreshCacheArea = HL.Method() << function(self)
    self:_InitAreaRepositoryList()
end
FacCacheArea.RefreshAreaBlockState = HL.Method(HL.Boolean) << function(self, isBlocked)
    self.view.blockNode.gameObject:SetActive(isBlocked)
end
FacCacheArea.GainAreaOutItems = HL.Method() << function(self)
    local core = GameInstance.player.remoteFactory.core
    core:Message_OpMoveAllCacheOutItemToBag(Utils.getCurrentChapterId(), self.m_buildingInfo.nodeId)
end
FacCacheArea.GetAreaInRepositoryNormalSlotGroup = HL.Method().Return(HL.Table) << function(self)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.inRepositoryList.rectTransform)
    return self:_GetAreaRepositorySlotGroup(false, self.m_inRepositoryList)
end
FacCacheArea.GetAreaOutRepositoryNormalSlotGroup = HL.Method().Return(HL.Table) << function(self)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.outRepositoryList.rectTransform)
    return self:_GetAreaRepositorySlotGroup(false, self.m_outRepositoryList)
end
FacCacheArea.GetAreaInRepositoryFluidSlotGroup = HL.Method().Return(HL.Table) << function(self)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.inRepositoryList.rectTransform)
    return self:_GetAreaRepositorySlotGroup(true, self.m_inRepositoryList)
end
FacCacheArea.PlayArrowAnimation = HL.Method(HL.String, HL.Opt(HL.Function)) << function(self, animationName, callback)
    self.view.decoArrowAnimation:PlayWithTween(animationName, callback)
end
FacCacheArea.DropItemToArea = HL.Method(HL.Table) << function(self, dragHelper)
    for _, repo in ipairs(self.m_inRepositoryList) do
        if repo:TryDropItemToRepository(dragHelper) == true then
            return
        end
    end
end
HL.Commit(FacCacheArea)
return FacCacheArea