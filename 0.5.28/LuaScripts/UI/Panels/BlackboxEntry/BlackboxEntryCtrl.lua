local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.BlackboxEntry
BlackboxEntryCtrl = HL.Class('BlackboxEntryCtrl', uiCtrl.UICtrl)
BlackboxEntryCtrl.m_rewardCellCache = HL.Field(HL.Forward("UIListCache"))
BlackboxEntryCtrl.m_mainGoalCellCache = HL.Field(HL.Forward("UIListCache"))
BlackboxEntryCtrl.m_extraGoalCellCache = HL.Field(HL.Forward("UIListCache"))
BlackboxEntryCtrl.m_preDependencyCellCache = HL.Field(HL.Forward("UIListCache"))
BlackboxEntryCtrl.m_preDependenciesListFoldOut = HL.Field(HL.Boolean) << false
BlackboxEntryCtrl.m_packageId = HL.Field(HL.String) << ""
BlackboxEntryCtrl.m_allBlackboxInfos = HL.Field(HL.Table)
BlackboxEntryCtrl.m_curBlackboxInfos = HL.Field(HL.Table)
BlackboxEntryCtrl.m_curSelectCell = HL.Field(HL.Any)
BlackboxEntryCtrl.m_curSelectedBlackboxId = HL.Field(HL.String) << ""
BlackboxEntryCtrl.m_genBlackboxCellFunc = HL.Field(HL.Function)
BlackboxEntryCtrl.m_cachedSelectedTags = HL.Field(HL.Table)
BlackboxEntryCtrl.m_filterArgs = HL.Field(HL.Table)
BlackboxEntryCtrl.s_messages = HL.StaticField(HL.Table) << {}
BlackboxEntryCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnClose.onClick:AddListener(function()
        self:_OnBtnCloseClick()
    end)
    self.view.btnEnter.onClick:AddListener(function()
        self:_OnBtnEnterClick()
    end)
    self.view.btnMap.onClick:AddListener(function()
        self:_OnBtnMapClick()
    end)
    self.view.btnCaptionContent.onClick:AddListener(function()
        self:_OnBtnCaptionContentClick()
    end)
    self.view.btnRewardDetails.onClick:AddListener(function()
        UIManager:AutoOpen(PanelId.DungeonRewardPopUp, { dungeonId = self.m_curSelectedBlackboxId })
    end)
    self.view.filterBtn.onClick:AddListener(function()
        self:_OnBtnFilterClick()
    end)
    self.view.blackboxScrollList.onUpdateCell:AddListener(function(gameObject, csIndex)
        self:_UpdateBlackboxCell(gameObject, csIndex)
    end)
    self.m_packageId = arg.packageId
    self.m_curSelectedBlackboxId = arg.blackboxId or ""
    self.m_rewardCellCache = UIUtils.genCellCache(self.view.rewardCell)
    self.m_mainGoalCellCache = UIUtils.genCellCache(self.view.mainGoalCell)
    self.m_extraGoalCellCache = UIUtils.genCellCache(self.view.extraGoalCell)
    self.m_preDependencyCellCache = UIUtils.genCellCache(self.view.facTechTreeOptionCell)
    self.m_genBlackboxCellFunc = UIUtils.genCachedCellFunction(self.view.blackboxScrollList)
    self:_Init()
end
BlackboxEntryCtrl._OnBtnCloseClick = HL.Method() << function(self)
    PhaseManager:PopPhase(PhaseId.BlackboxEntry)
end
BlackboxEntryCtrl._Init = HL.Method() << function(self)
    local packageCfg = Tables.facSTTGroupTable[self.m_packageId]
    local costPointItemCfg = Tables.itemTable[packageCfg.costPointType]
    local blackboxIds = packageCfg.blackboxIds
    local dungeonCfg = Tables.dungeonTable[blackboxIds[1]]
    local dungeonSeriesCfg = Tables.dungeonSeriesTable[dungeonCfg.dungeonSeriesId]
    self.view.seriesNameTxt.text = dungeonSeriesCfg.name
    self.view.rewardDescTxt.text = string.format(Language.LUA_BLACKBOX_COMPLETE_REWARD_FORMAT, costPointItemCfg.name)
    FactoryUtils.updateFacTechTreeTechPointNode(self.view.resourceNode, self.m_packageId)
    self.m_filterArgs = FactoryUtils.genFilterBlackboxArgs(self.m_packageId, function(selectedTags)
        self:_OnFilterConfirm(selectedTags)
    end)
    self.m_allBlackboxInfos = FactoryUtils.getBlackboxInfoTbl(blackboxIds)
    self.m_curBlackboxInfos = self.m_allBlackboxInfos
    self.m_curSelectedBlackboxId = string.isEmpty(self.m_curSelectedBlackboxId) and self.m_curBlackboxInfos[1].blackboxId or self.m_curSelectedBlackboxId
    self.view.blackboxScrollList:UpdateCount(#self.m_curBlackboxInfos)
    self.view.blackboxScrollList:ScrollToIndex(CSIndex(self:_FindLuaIndexInBlackboxInfos(self.m_curSelectedBlackboxId)))
    self:_ReadBlackbox(self.m_curSelectedBlackboxId)
    self:_RefreshDetails()
    self:_RefreshPreDependencies()
    self:_PreDependenciesFoldOut(false)
end
BlackboxEntryCtrl._RefreshDetails = HL.Method() << function(self)
    local gameMechanicData = Tables.gameMechanicTable[self.m_curSelectedBlackboxId]
    local dungeonData = Tables.dungeonTable[self.m_curSelectedBlackboxId]
    local isUnlock = DungeonUtils.isDungeonUnlock(self.m_curSelectedBlackboxId)
    local isActive = GameInstance.dungeonManager:IsDungeonActive(self.m_curSelectedBlackboxId)
    self.view.detailsContent.gameObject:SetActiveIfNecessary(isActive and isUnlock)
    self.view.locked.gameObject:SetActiveIfNecessary(isActive and not isUnlock)
    self.view.notActivated.gameObject:SetActiveIfNecessary(not isActive)
    self.view.btnEnter.gameObject:SetActiveIfNecessary(isActive and isUnlock)
    self.view.btnMap.gameObject:SetActiveIfNecessary(not isActive)
    self.view.titleTxt.text = isActive and dungeonData.dungeonName or Language.LUA_FAC_TECH_TREE_BLACK_BOX_TBD
    self.view.positionTxt.text = DungeonUtils.getEntryLocation(dungeonData.levelId, false)
    self.view.positionNode.gameObject:SetActiveIfNecessary(not isActive)
    if not isUnlock then
        local conditionId = gameMechanicData.conditionIds[0]
        local conditionData = Tables.gameMechanicConditionTable[conditionId]
        self.view.unlockTxt.text = UIUtils.resolveTextStyle(conditionData.desc)
    else
        local dungeonMgr = GameInstance.dungeonManager
        self.view.descTxt.text = UIUtils.resolveTextStyle(dungeonData.dungeonDesc)
        self.view.featureTxt.text = UIUtils.resolveTextStyle(dungeonData.featureDesc)
        local mainRewardGained = dungeonMgr:IsDungeonRewardGained(self.m_curSelectedBlackboxId)
        local extraRewardGained = dungeonMgr:IsDungeonExtraRewardGained(self.m_curSelectedBlackboxId)
        local mainGoalTxt = DungeonUtils.getListByStr(dungeonData.mainGoalDesc)
        self.m_mainGoalCellCache:Refresh(#mainGoalTxt, function(cell, index)
            self:_UpdateGoalCell(cell, mainGoalTxt[index], mainRewardGained)
        end)
        self.view.mainTaskNode.gameObject:SetActiveIfNecessary(#mainGoalTxt > 0)
        self.view.mainUndone.gameObject:SetActiveIfNecessary(not mainRewardGained)
        self.view.mainDone.gameObject:SetActiveIfNecessary(mainRewardGained)
        local extraGoalTxt = DungeonUtils.getListByStr(dungeonData.extraGoalDesc)
        self.m_extraGoalCellCache:Refresh(#extraGoalTxt, function(cell, index)
            self:_UpdateGoalCell(cell, extraGoalTxt[index], extraRewardGained)
        end)
        self.view.extraTaskNode.gameObject:SetActiveIfNecessary(#extraGoalTxt > 0)
        self.view.extraUndone.gameObject:SetActiveIfNecessary(not extraRewardGained)
        self.view.extraDone.gameObject:SetActiveIfNecessary(extraRewardGained)
        local rewardItemBundles = {}
        local rewardId = gameMechanicData.firstPassRewardId
        local findReward, mainRewardData = Tables.rewardTable:TryGetValue(rewardId)
        if findReward then
            for _, itemBundle in pairs(mainRewardData.itemBundles) do
                table.insert(rewardItemBundles, { id = itemBundle.id, count = itemBundle.count, done = mainRewardGained and 1 or 0, isMain = 1 })
            end
        end
        local extraRewardId = gameMechanicData.extraRewardId
        local findExtraReward, extraRewardData = Tables.rewardTable:TryGetValue(extraRewardId)
        if findExtraReward then
            for _, itemBundle in pairs(extraRewardData.itemBundles) do
                table.insert(rewardItemBundles, { id = itemBundle.id, count = itemBundle.count, done = extraRewardGained and 1 or 0, isMain = 0 })
            end
        end
        table.sort(rewardItemBundles, Utils.genSortFunction({ "done", "isMain" }))
        local maxRewardDisplayNum = 3
        local displayRewardNum = math.min(#rewardItemBundles, maxRewardDisplayNum)
        self.m_rewardCellCache:Refresh(displayRewardNum, function(rewardCell, luaIdx)
            local bundle = rewardItemBundles[luaIdx]
            rewardCell.item:InitItem(bundle, true)
            rewardCell.getNode.gameObject:SetActive(bundle.done == 1)
            rewardCell.extraTag.gameObject:SetActive(bundle.isMain == 0)
        end)
    end
end
BlackboxEntryCtrl._RefreshPreDependencies = HL.Method() << function(self)
    local dungeonData = Tables.dungeonTable[self.m_curSelectedBlackboxId]
    local preDependencies = FactoryUtils.getBlackboxInfoTbl(dungeonData.preDependencies)
    local hasPreDependencies = #preDependencies > 0
    if hasPreDependencies then
        self.m_preDependencyCellCache:Refresh(#preDependencies, function(cell, luaIndex)
            self:_OnUpdatePreDependencyCell(cell, preDependencies[luaIndex])
        end)
        self.view.captionContentRedDot:InitRedDot("BlackboxPreDependencies", dungeonData.preDependencies)
    end
    local isUnlock = DungeonUtils.isDungeonUnlock(self.m_curSelectedBlackboxId)
    local isActive = GameInstance.dungeonManager:IsDungeonActive(self.m_curSelectedBlackboxId)
    self.view.preDependenciesNode.gameObject:SetActiveIfNecessary(hasPreDependencies and isUnlock and isActive)
end
BlackboxEntryCtrl._OnUpdatePreDependencyCell = HL.Method(HL.Any, HL.Table) << function(self, cell, info)
    cell:InitBlackboxSelectionCell(info, function()
        self:_OnPreDependencyCellClick(info.blackboxId)
    end, true)
end
BlackboxEntryCtrl._FindLuaIndexInBlackboxInfos = HL.Method(HL.String).Return(HL.Opt(HL.Number)) << function(self, blackboxId)
    local luaIndex
    for index, blackboxInfo in ipairs(self.m_curBlackboxInfos) do
        if blackboxInfo.blackboxId == blackboxId then
            luaIndex = index
        end
    end
    return luaIndex
end
BlackboxEntryCtrl._OnPreDependencyCellClick = HL.Method(HL.String) << function(self, blackboxId)
    local luaIndex = self:_FindLuaIndexInBlackboxInfos(blackboxId)
    self.m_curSelectedBlackboxId = blackboxId
    if luaIndex == nil then
        self.m_curBlackboxInfos = self.m_allBlackboxInfos
        self.view.blackboxScrollList:UpdateCount(#self.m_curBlackboxInfos)
        self.view.hasFilter.gameObject:SetActiveIfNecessary(false)
        luaIndex = findIndex(self.m_allBlackboxInfos)
        self.view.blackboxScrollList:ScrollToIndex(CSIndex(luaIndex))
    else
        self.m_curSelectCell:SetSelected(false)
        local csIndex = CSIndex(luaIndex)
        local go = self.view.blackboxScrollList:Get(csIndex)
        if go then
            local cell = Utils.wrapLuaNode(go)
            self.m_curSelectCell = cell
            cell:SetSelected(true)
        end
        self.view.blackboxScrollList:ScrollToIndex(csIndex)
    end
    self:_RefreshDetails()
    self:_RefreshPreDependencies()
    self:_PreDependenciesFoldOut(false)
end
BlackboxEntryCtrl._OnBtnEnterClick = HL.Method() << function(self)
    if Utils.isCurSquadAllDead() then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_GAME_MODE_FORBID_FACTORY_WATCH)
        return
    end
    local dungeonData = Tables.dungeonTable[self.m_curSelectedBlackboxId]
    local dungeonMgr = GameInstance.dungeonManager
    local needConfirm = false
    for _, preDependency in pairs(dungeonData.preDependencies) do
        if not dungeonMgr:IsDungeonPassed(preDependency) then
            needConfirm = true
            break
        end
    end
    if needConfirm then
        local content = Language.LUA_BLACKBOX_START_CONFIRM_DESC .. "\n" .. Language.LUA_BLACKBOX_START_SUB_CONFIRM_DESC
        self:Notify(MessageConst.SHOW_POP_UP, {
            content = content,
            onConfirm = function()
                dungeonMgr:EnterDungeon(self.m_curSelectedBlackboxId)
            end,
        })
    else
        dungeonMgr:EnterDungeon(self.m_curSelectedBlackboxId)
    end
end
BlackboxEntryCtrl._OnBtnMapClick = HL.Method() << function(self)
    local dungeonCfg = Tables.dungeonTable[self.m_curSelectedBlackboxId]
    local _, instId = GameInstance.player.mapManager:GetMapMarkInstId(GEnums.MarkType.BlackBox, dungeonCfg.dungeonSeriesId)
    MapUtils.openMap(instId)
end
BlackboxEntryCtrl._OnBtnCaptionContentClick = HL.Method() << function(self)
    self:_PreDependenciesFoldOut(not self.m_preDependenciesListFoldOut)
end
BlackboxEntryCtrl._PreDependenciesFoldOut = HL.Method(HL.Boolean) << function(self, foldOut)
    self.m_preDependenciesListFoldOut = foldOut
    self.view.preDependencies.gameObject:SetActiveIfNecessary(foldOut)
    self.view.arrow.localScale = Vector3(1, foldOut and 1 or -1, 1)
end
BlackboxEntryCtrl._UpdateGoalCell = HL.Method(HL.Any, HL.String, HL.Boolean) << function(self, cell, text, done)
    done = false
    cell.descTxt.text = UIUtils.resolveTextStyle(text)
    cell.done.gameObject:SetActiveIfNecessary(done)
    cell.undone.gameObject:SetActiveIfNecessary(not done)
end
BlackboxEntryCtrl._UpdateBlackboxCell = HL.Method(GameObject, HL.Number) << function(self, gameObject, csIndex)
    local cell = self.m_genBlackboxCellFunc(gameObject)
    local luaIndex = LuaIndex(csIndex)
    local blackboxInfo = self.m_curBlackboxInfos[luaIndex]
    cell:InitBlackboxSelectionCell(blackboxInfo, function()
        self:_OnBlackboxCellClick(cell, luaIndex)
    end, false)
    cell:SetSelected(self.m_curSelectedBlackboxId == blackboxInfo.blackboxId, true)
    if self.m_curSelectedBlackboxId == blackboxInfo.blackboxId then
        self.m_curSelectCell = cell
    end
end
BlackboxEntryCtrl._OnBlackboxCellClick = HL.Method(HL.Any, HL.Number) << function(self, cell, luaIndex)
    local blackboxInfo = self.m_curBlackboxInfos[luaIndex]
    if self.m_curSelectedBlackboxId == blackboxInfo.blackboxId then
        return
    end
    local preCell = self.m_curSelectCell
    self.m_curSelectCell = cell
    self.m_curSelectedBlackboxId = blackboxInfo.blackboxId
    preCell:SetSelected(false)
    cell:SetSelected(true)
    self:_ReadBlackbox(blackboxInfo.blackboxId)
    self:_RefreshDetails()
    self:_RefreshPreDependencies()
    self:_PreDependenciesFoldOut(false)
    local wrapper = self:GetAnimationWrapper()
    wrapper:ClearTween()
    wrapper:Play("blackboxentry_change")
end
BlackboxEntryCtrl._OnBtnFilterClick = HL.Method() << function(self)
    self.m_filterArgs.selectedTags = self.m_cachedSelectedTags
    self:Notify(MessageConst.SHOW_COMMON_FILTER, self.m_filterArgs)
end
BlackboxEntryCtrl._OnFilterConfirm = HL.Method(HL.Table) << function(self, selectedTags)
    selectedTags = selectedTags or {}
    self.m_cachedSelectedTags = selectedTags
    local ids = FactoryUtils.getFilterBlackboxIds(self.m_packageId, selectedTags)
    self.m_curBlackboxInfos = FactoryUtils.getBlackboxInfoTbl(ids)
    local hasFilterResult = #ids > 0
    self.view.blackboxScrollList.gameObject:SetActiveIfNecessary(hasFilterResult)
    self.view.filterResultEmpty.gameObject:SetActiveIfNecessary(not hasFilterResult)
    self.view.hasFilter.gameObject:SetActiveIfNecessary(#selectedTags > 0)
    if hasFilterResult then
        self.view.blackboxScrollList:UpdateCount(#self.m_curBlackboxInfos)
    end
end
BlackboxEntryCtrl._ReadBlackbox = HL.Method(HL.String) << function(self, blackboxId)
    local dungeonMgr = GameInstance.dungeonManager
    if not dungeonMgr:IsDungeonActive(blackboxId) then
        return
    end
    if dungeonMgr:IsBlackboxRead(blackboxId) then
        return
    end
    dungeonMgr:ReadBlackbox(blackboxId)
end
HL.Commit(BlackboxEntryCtrl)