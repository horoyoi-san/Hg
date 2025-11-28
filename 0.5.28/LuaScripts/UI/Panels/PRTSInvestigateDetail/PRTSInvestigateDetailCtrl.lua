local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.PRTSInvestigateDetail
local PHASE_ID = PhaseId.PRTSInvestigateDetail
PRTSInvestigateDetailCtrl = HL.Class('PRTSInvestigateDetailCtrl', uiCtrl.UICtrl)
PRTSInvestigateDetailCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_INVESTIGATE_FINISHED] = '_OnInvestigateFinished', [MessageConst.ON_UNLOCK_PRTS] = '_OnUnlockStoryColl', [MessageConst.PRTS_CHANGE_INVESTIGATE_GALLERY_NOTE_VISIBLE] = '_OnChangeShownState', [MessageConst.ON_READ_PRTS_NOTE_BATCH] = '_OnNoteStateChange', [MessageConst.ON_UNREAD_PRTS_NOTE_BATCH] = '_OnNoteStateChange', }
PRTSInvestigateDetailCtrl.m_getCategoryCellFunc = HL.Field(HL.Function)
PRTSInvestigateDetailCtrl.m_genRewardCells = HL.Field(HL.Forward("UIListCache"))
PRTSInvestigateDetailCtrl.m_genNotFoundCells = HL.Field(HL.Forward("UIListCache"))
PRTSInvestigateDetailCtrl.m_investId = HL.Field(HL.String) << ""
PRTSInvestigateDetailCtrl.m_info = HL.Field(HL.Table)
PRTSInvestigateDetailCtrl.m_isNoteShown = HL.Field(HL.Boolean) << false
PRTSInvestigateDetailCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:_InitUI()
    self:_InitData(arg)
    self:_UpdateData()
    self:_RefreshAllUI()
end
PRTSInvestigateDetailCtrl._OnChangeShownState = HL.Method(HL.Boolean) << function(self, isShow)
    self:_RefreshUINoteShowState(isShow)
end
PRTSInvestigateDetailCtrl._OnUnlockStoryColl = HL.Method(HL.Table) << function(self, args)
    local collId = unpack(args)
    local investId = self.m_investId
    local hasCfg, investCfg = Tables.prtsInvestigate:TryGetValue(investId)
    if not hasCfg then
        logger.error("[prts Investigate Table] missing cfg, id = " .. investId)
        return
    end
    if lume.find(investCfg.collectionIdList, collId) then
        self:_UpdateData()
        self:_RefreshAllUI()
    end
end
PRTSInvestigateDetailCtrl._OnNoteStateChange = HL.Method() << function(self)
    self:_UpdateData()
    self:_RefreshAllUI()
end
PRTSInvestigateDetailCtrl._OnInvestigateFinished = HL.Method(HL.Table) << function(self, args)
    local investId = unpack(args)
    if self.m_investId == investId then
        self:_UpdateData()
        self:_RefreshAllUI()
        PhaseManager:OpenPhase(PhaseId.PRTSInvestigateReport, { investId = self.m_info.investId, storyCollId = self.m_info.unlockPrts, showSubmitAni = true, })
    end
end
PRTSInvestigateDetailCtrl.ShowSelf = HL.StaticMethod(HL.Any) << function(args)
    local id = unpack(args)
    PhaseManager:OpenPhase(PhaseId.PRTSInvestigateDetail, { id = id })
end
PRTSInvestigateDetailCtrl._InitData = HL.Method(HL.Any) << function(self, arg)
    if (arg == nil or string.isEmpty(arg.id)) then
        logger.error("[PRTSInvestigateDetailCtrl:_InitData] arg or arg.id is nil!")
        return
    end
    self.m_investId = arg.id
end
PRTSInvestigateDetailCtrl._UpdateData = HL.Method() << function(self)
    local investId = self.m_investId
    local hasCfg, investCfg = Tables.prtsInvestigate:TryGetValue(investId)
    if not hasCfg then
        logger.error("[prts Investigate Table] missing cfg, id = " .. investId)
        return
    end
    self.m_info = { investId = investId, unlockPrts = investCfg.unlockPrts, title = investCfg.name, desc = investCfg.desc, curCount = GameInstance.player.prts:GetStoryCollUnlockCount(investId), targetCount = #investCfg.collectionIdList, isRewarded = GameInstance.player.prts:IsInvestigateFinished(investId), rewardList = investCfg.rewardItemList, categoryInfoBundles = PRTSInvestigateDetailCtrl._GetCategoryInfoBundles(investCfg.categoryDataList), }
end
PRTSInvestigateDetailCtrl._GetCategoryInfoBundles = HL.StaticMethod(HL.Any).Return(HL.Table) << function(categoryDataList)
    local infoBundleList = {}
    for _, data in pairs(categoryDataList) do
        local infoBundle = { title = data.name, index = data.index, collInfos = PRTSInvestigateDetailCtrl._GetCategoryCollInfos(data.collectionIdList), noteInfos = PRTSInvestigateDetailCtrl._GetCategoryNoteInfos(data.noteIdList), showNote = false, isPlayNoteAni = false, }
        if #infoBundle.collInfos > 0 then
            table.insert(infoBundleList, infoBundle)
        end
    end
    table.sort(infoBundleList, Utils.genSortFunction({ "index" }, true))
    return infoBundleList
end
PRTSInvestigateDetailCtrl._GetCategoryCollInfos = HL.StaticMethod(HL.Any).Return(HL.Table) << function(collIds)
    local infos = {}
    for _, id in pairs(collIds) do
        local collCfg = Utils.tryGetTableCfg(Tables.prtsAllItem, id)
        local isUnlock = GameInstance.player.prts:IsPrtsUnlocked(id)
        if collCfg and isUnlock then
            local firstLvCfg = Utils.tryGetTableCfg(Tables.prtsFirstLv, collCfg.firstLvId)
            if firstLvCfg then
                local info = { collId = id, name = collCfg.name, imgPath = firstLvCfg.icon, }
                table.insert(infos, info)
            end
        end
    end
    return infos
end
PRTSInvestigateDetailCtrl._GetCategoryNoteInfos = HL.StaticMethod(HL.Any).Return(HL.Table) << function(noteIds)
    local infos = {}
    for index, id in pairs(noteIds) do
        local noteCfg = Utils.tryGetTableCfg(Tables.prtsNote, id)
        local isNoteUnlock = GameInstance.player.prts:IsNoteUnlock(id)
        if noteCfg and isNoteUnlock then
            local info = { noteId = id, index = index, desc = noteCfg.desc }
            table.insert(infos, info)
        end
    end
    return infos
end
PRTSInvestigateDetailCtrl._InitUI = HL.Method() << function(self)
    local viewRef = self.view
    viewRef.closeNoteBtn.onClick:AddListener(function()
        self:_SetNoteHasRead()
        self:_RefreshUINoteShowState(false)
    end)
    viewRef.closeBtn.onClick:AddListener(function()
        self:_SetCollHasRead()
        PhaseManager:PopPhase(PhaseId.PRTSInvestigateDetail)
    end)
    viewRef.getRewardBtn.onClick:AddListener(function()
        GameInstance.player.prts:SendFinishInvestigate(self.m_info.investId)
    end)
    viewRef.gotoReportBtn.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.PRTSInvestigateReport, { investId = self.m_info.investId, storyCollId = self.m_info.unlockPrts, })
    end)
    viewRef.notFoundBtn.onClick:AddListener(function()
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_PRTS_INVESTIGATE_NOT_FOUND_COLL_TOAST)
    end)
    self.m_genRewardCells = UIUtils.genCellCache(self.view.rewardCell)
    self.m_genNotFoundCells = UIUtils.genCellCache(self.view.notFoundCell)
    self.m_getCategoryCellFunc = UIUtils.genCachedCellFunction(self.view.categoryList)
    viewRef.categoryList.onUpdateCell:AddListener(function(obj, csIndex)
        local cell = self.m_getCategoryCellFunc(obj)
        self:_OnRefreshCategoryCell(cell, LuaIndex(csIndex))
    end)
end
PRTSInvestigateDetailCtrl._RefreshAllUI = HL.Method() << function(self)
    local info = self.m_info
    if not info then
        return
    end
    local viewRef = self.view
    local isComplete = (not info.isRewarded) and (info.curCount >= info.targetCount)
    viewRef.titleTxt.text = info.title
    viewRef.descTxt.text = info.desc
    viewRef.progressTxt.text = info.curCount .. '/' .. info.targetCount
    self.m_genRewardCells:Refresh(#info.rewardList, function(cell, luaIndex)
        self:_OnRefreshRewardCell(cell, luaIndex)
    end)
    if info.isRewarded then
        viewRef.investState:SetState("Rewarded")
    elseif isComplete then
        viewRef.investState:SetState("Complete")
    else
        viewRef.investState:SetState("Normal")
    end
    if info.curCount < info.targetCount then
        local count = info.targetCount - info.curCount
        viewRef.notFoundCountTxt.text = count
        if count > viewRef.config.MAX_NOT_FOUND_CELL_COUNT then
            count = viewRef.config.MAX_NOT_FOUND_CELL_COUNT
            viewRef.notFoundListState:SetState("ShowMax")
        else
            viewRef.notFoundListState:SetState("ShowNormal")
        end
        self.m_genNotFoundCells:Refresh(count)
    else
        viewRef.notFoundListState:SetState("Hide")
    end
    viewRef.categoryList:UpdateCount(#self.m_info.categoryInfoBundles, true)
end
PRTSInvestigateDetailCtrl._OnRefreshRewardCell = HL.Method(HL.Any, HL.Number) << function(self, cell, luaIndex)
    local info = self.m_info.rewardList[CSIndex(luaIndex)]
    cell:InitItem(info, true)
    cell.view.rewardedCover.gameObject:SetActiveIfNecessary(self.m_info.isRewarded)
end
PRTSInvestigateDetailCtrl._OnRefreshCategoryCell = HL.Method(HL.Any, HL.Number) << function(self, cell, luaIndex)
    local infoBundle = self.m_info.categoryInfoBundles[luaIndex]
    cell:InitPRTSInvestigateCategoryCell(infoBundle)
    infoBundle.isPlayNoteAni = false
end
PRTSInvestigateDetailCtrl._RefreshUINoteShowState = HL.Method(HL.Boolean) << function(self, isShow)
    self.m_isNoteShown = isShow
    if (self.m_isNoteShown) then
        self.view.noteState:SetState("ShowNoteState")
    else
        self.view.noteState:SetState("HideNoteState")
    end
    for _, infoBundle in pairs(self.m_info.categoryInfoBundles) do
        infoBundle.showNote = isShow
        infoBundle.isPlayNoteAni = true
    end
end
PRTSInvestigateDetailCtrl._SetNoteHasRead = HL.Method() << function(self)
    local readNoteList = {}
    for _, infoBundle in pairs(self.m_info.categoryInfoBundles) do
        for _, noteInfo in pairs(infoBundle.noteInfos) do
            if noteInfo.hasRead then
                table.insert(readNoteList, noteInfo.noteId)
            end
        end
    end
    GameInstance.player.prts:SendReadNoteList(readNoteList)
end
PRTSInvestigateDetailCtrl._SetCollHasRead = HL.Method() << function(self)
    for _, infoBundle in pairs(self.m_info.categoryInfoBundles) do
        for _, collInfo in pairs(infoBundle.collInfos) do
            if collInfo.hasRead then
                GameInstance.player.prts:MarkRead(collInfo.collId)
            end
        end
    end
end
HL.Commit(PRTSInvestigateDetailCtrl)