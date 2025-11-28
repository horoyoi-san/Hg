local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.WikiGuide
WikiGuideCtrl = HL.Class('WikiGuideCtrl', uiCtrl.UICtrl)
WikiGuideCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.WIKI_SELECT_ENTRY] = '_OnWikiSelectEntry', }
local WIKI_GUIDE_ENTRY_CELL_PART_HEIGHT = { WIKI_GUIDE_ENTRY_BASE_HEIGHT = 100, WIKI_GUIDE_ENTRY_LOCK_TIP_HEIGHT = 37, WIKI_GUIDE_ENTRY_SPLIT_LINE_HEIGHT = 18, WIKI_GUIDE_ENTRY_SPACING_HEIGHT = 9 }
WikiGuideCtrl.m_typeTabCache = HL.Field(HL.Forward("UIListCache"))
WikiGuideCtrl.m_entryListCache = HL.Field(HL.Function)
WikiGuideCtrl.m_getMediaCell = HL.Field(HL.Function)
WikiGuideCtrl.m_pageIndexToggleCache = HL.Field(HL.Forward("UIListCache"))
WikiGuideCtrl.m_refBtnCache = HL.Field(HL.Forward("UIListCache"))
WikiGuideCtrl.m_latestUnlockCnt = HL.Field(HL.Number) << 0
WikiGuideCtrl.m_showingLatestUnlock = HL.Field(HL.Boolean) << false
WikiGuideCtrl.m_wikiGroupShowDataList = HL.Field(HL.Table)
WikiGuideCtrl.m_allGroupEntryList = HL.Field(HL.Table)
WikiGuideCtrl.m_entryListByGroup = HL.Field(HL.Table)
WikiGuideCtrl.m_showingEntryList = HL.Field(HL.Table)
WikiGuideCtrl.m_showingEntryCnt = HL.Field(HL.Number) << 0
WikiGuideCtrl.m_showingEntryData = HL.Field(HL.Table)
WikiGuideCtrl.m_selectedIndex = HL.Field(HL.Number) << 0
WikiGuideCtrl.m_toShowDetail = HL.Field(HL.Table)
WikiGuideCtrl.m_pagesByEntryId = HL.Field(HL.Table)
WikiGuideCtrl.m_showingPageList = HL.Field(HL.Table)
WikiGuideCtrl.m_isShowingLastPage = HL.Field(HL.Boolean) << false
WikiGuideCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.view.wikiVideoBgWidget:InitWikiVideoBg()
    self.m_typeTabCache = UIUtils.genCellCache(self.view.typeCellTemplate)
    local entryList = self.view.entryList
    self.m_entryListCache = UIUtils.genCachedCellFunction(entryList)
    entryList.onUpdateCell:AddListener(function(obj, csIndex)
        local cell = self.m_entryListCache(obj)
        self:SetEntryCellSelected(cell, LuaIndex(csIndex) == self.m_selectedIndex)
        cell.entryButton.onClick:RemoveAllListeners()
        cell.entryButton.onClick:AddListener(function()
            self:SetSelectedEntryIndex(LuaIndex(csIndex))
        end)
        cell.lockTipsNode.gameObject:SetActive(self.m_showingLatestUnlock and csIndex == 0)
        cell.cutOffRuleNode.gameObject:SetActive(self.m_showingLatestUnlock and csIndex + 1 == self.m_latestUnlockCnt)
        local desc = self.m_showingEntryList[LuaIndex(csIndex)].wikiEntryData.desc
        cell.titleNormalTxt.text = desc
        cell.titleSelectTxt.text = desc
        cell.redDot:InitRedDot("WikiGuideEntry", self.m_showingEntryList[LuaIndex(csIndex)].wikiEntryData.id)
    end)
    entryList.getCellSize = function(csIndex)
        local showLockTip = self.m_showingLatestUnlock and csIndex == 0
        local showSplitLine = self.m_showingLatestUnlock and csIndex + 1 == self.m_latestUnlockCnt
        local cellHeight = WIKI_GUIDE_ENTRY_CELL_PART_HEIGHT.WIKI_GUIDE_ENTRY_BASE_HEIGHT
        if showLockTip then
            cellHeight = cellHeight + WIKI_GUIDE_ENTRY_CELL_PART_HEIGHT.WIKI_GUIDE_ENTRY_LOCK_TIP_HEIGHT
            cellHeight = cellHeight + WIKI_GUIDE_ENTRY_CELL_PART_HEIGHT.WIKI_GUIDE_ENTRY_SPACING_HEIGHT
        end
        if showSplitLine then
            cellHeight = cellHeight + WIKI_GUIDE_ENTRY_CELL_PART_HEIGHT.WIKI_GUIDE_ENTRY_SPLIT_LINE_HEIGHT
            cellHeight = cellHeight + WIKI_GUIDE_ENTRY_CELL_PART_HEIGHT.WIKI_GUIDE_ENTRY_SPACING_HEIGHT
        end
        return cellHeight
    end
    local mediaList = self.view.guideMediaNode.mediaList
    self.m_getMediaCell = UIUtils.genCachedCellFunction(mediaList)
    mediaList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateMediaCell(obj, csIndex)
    end)
    mediaList.onCenterIndexChanged:AddListener(function(oldIndex, newIndex)
        self:_OnUpdateCurrentPageIndex(newIndex)
    end)
    self.m_pageIndexToggleCache = UIUtils.genCellCache(self.view.guideMediaNode.indexToggle)
    self.m_refBtnCache = UIUtils.genCellCache(self.view.wikiRefBtn)
    self.m_pagesByEntryId = {}
    for _, pageData in pairs(Tables.wikiTutorialPageTable) do
        local pageList = self.m_pagesByEntryId[pageData.tutorialId]
        if not pageList then
            pageList = {}
            self.m_pagesByEntryId[pageData.tutorialId] = pageList
        end
        pageList[pageData.order] = pageData
    end
    self.view.guideMediaNode.leftButton.onClick:AddListener(function()
        self:SwitchPage(self.view.guideMediaNode.mediaList.centerIndex - 1)
    end)
    self.view.guideMediaNode.rightButton.onClick:AddListener(function()
        if self.m_isShowingLastPage then
            self:SetSelectedEntryIndex(self.m_selectedIndex + 1, true)
            return
        end
        self:SwitchPage(self.view.guideMediaNode.mediaList.centerIndex + 1)
    end)
    self.m_selectedIndex = 0
    self.m_toShowDetail = args
end
WikiGuideCtrl.OnShow = HL.Override() << function(self)
    self:InitView()
end
WikiGuideCtrl.InitView = HL.Method() << function(self)
    self.m_wikiGroupShowDataList = WikiUtils.getWikiGroupShowDataList(WikiConst.EWikiCategoryType.Tutorial)
    self.m_allGroupEntryList = {}
    self.m_entryListByGroup = {}
    local latestUnlockMaxNum = Tables.globalConst.wikiLatestUnlockNum
    local latestUnlockEntryIds = GameInstance.player.wikiSystem:GetLatestUnlockedEntryIds()
    local realCnt = latestUnlockEntryIds.Count
    if realCnt > latestUnlockMaxNum then
        realCnt = latestUnlockMaxNum
    end
    self.m_latestUnlockCnt = realCnt
    local lut = {}
    for i = 1, realCnt do
        lut[latestUnlockEntryIds[CSIndex(i)]] = i
    end
    for _, groupData in pairs(self.m_wikiGroupShowDataList) do
        self.m_entryListByGroup[groupData.wikiGroupData.groupId] = groupData.wikiEntryShowDataList
        for _, entryData in pairs(groupData.wikiEntryShowDataList) do
            local luaIndex = lut[entryData.wikiEntryData.id]
            if luaIndex then
                self.m_allGroupEntryList[luaIndex] = entryData
            else
                table.insert(self.m_allGroupEntryList, entryData)
            end
        end
    end
    self.m_typeTabCache:Refresh(#self.m_wikiGroupShowDataList, function(cell, luaIndex)
        local groupData = self.m_wikiGroupShowDataList[luaIndex]
        cell.titleTxt.text = groupData.wikiGroupData.groupName
        cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_WIKI_GROUP, groupData.wikiGroupData.iconId)
        cell.offIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_WIKI_GROUP, groupData.wikiGroupData.iconId)
        cell.toggle.onValueChanged:RemoveAllListeners()
        cell.toggle.onValueChanged:AddListener(function(isOn)
            if isOn then
                self:SwitchToGroup(groupData.wikiGroupData.groupId)
            end
        end)
        cell.redDot:InitRedDot("WikiGroup", groupData.wikiGroupData.groupId)
    end)
    self.view.typeCellAll.titleTxt.text = Language.LUA_WIKI_TUTORIAL_ALL_TYPE
    self.view.typeCellAll.toggle.onValueChanged:RemoveAllListeners()
    self.view.typeCellAll.toggle.onValueChanged:AddListener(function(isOn)
        if isOn then
            self:SwitchToGroup()
        end
    end)
    self.view.typeCellAll.redDot:InitRedDot("WikiCategory", WikiConst.EWikiCategoryType.Tutorial)
    self:Refresh(self.m_toShowDetail)
end
WikiGuideCtrl.Refresh = HL.Method(HL.Table) << function(self, args)
    if args then
        self.m_showingEntryData = args.wikiEntryShowData
    else
        self.m_showingEntryData = self.m_allGroupEntryList[1]
    end
    self.view.typeCellAll.toggle:SetIsOnWithoutNotify(true)
    self:SwitchToGroup()
end
WikiGuideCtrl.SwitchToGroup = HL.Method(HL.Opt(HL.String)) << function(self, groupId)
    self.m_showingLatestUnlock = not groupId and self.m_latestUnlockCnt > 0
    local entryListToShow = groupId and self.m_entryListByGroup[groupId] or self.m_allGroupEntryList
    local selectIndex = 1
    if not groupId or self.m_showingEntryData.wikiGroupData.groupId == groupId then
        for index, entryData in pairs(entryListToShow) do
            if entryData.wikiEntryData.id == self.m_showingEntryData.wikiEntryData.id then
                selectIndex = index
                break
            end
        end
    end
    self:RefreshEntryList(entryListToShow, CSIndex(selectIndex))
    self:SetSelectedEntryIndex(selectIndex)
end
WikiGuideCtrl.RefreshEntryList = HL.Method(HL.Table, HL.Opt(HL.Number)) << function(self, targetList, selectCsIndex)
    self.m_showingEntryList = targetList
    self.m_showingEntryCnt = #targetList
    if selectCsIndex then
        self.view.entryList:UpdateCount(self.m_showingEntryCnt, selectCsIndex, true, false, false, CS.Beyond.UI.UIScrollList.ScrollAlignType.Top)
    else
        self.view.entryList:UpdateCount(self.m_showingEntryCnt, false, true)
    end
end
WikiGuideCtrl.SetSelectedEntryIndex = HL.Method(HL.Number, HL.Opt(HL.Boolean)) << function(self, luaIndex, scrollToEntry)
    if self.m_selectedIndex > 0 then
        self:SetEntryCellSelected(self.m_entryListCache(self.view.entryList:Get(CSIndex(self.m_selectedIndex))), false)
    end
    self.m_selectedIndex = luaIndex
    self:SetEntryCellSelected(self.m_entryListCache(self.view.entryList:Get(CSIndex(self.m_selectedIndex))), true)
    self:RefreshContent(self.m_showingEntryList[luaIndex])
    if scrollToEntry == true then
        self.view.entryList:ScrollToIndex(CSIndex(luaIndex))
    end
    local entryId = self.m_showingEntryList[luaIndex].wikiEntryData.id
    if WikiUtils.isWikiEntryUnread(entryId) then
        GameInstance.player.wikiSystem:MarkWikiEntryRead({ entryId })
    end
end
WikiGuideCtrl.SetEntryCellSelected = HL.Method(HL.Table, HL.Boolean) << function(self, cell, selected)
    if not cell then
        return
    end
    cell.selectNode.gameObject:SetActive(selected)
    cell.normalNode.gameObject:SetActive(not selected)
end
WikiGuideCtrl.RefreshContent = HL.Method(HL.Table) << function(self, entryShowData)
    self.m_showingEntryData = entryShowData
    self:RefreshTop()
    local entryId = self.m_showingEntryData.wikiEntryData.id
    self.m_showingPageList = self.m_pagesByEntryId[entryId]
    local pageCnt = #self.m_showingPageList
    self.m_pageIndexToggleCache:Refresh(pageCnt, function(cell, luaIndex)
        cell.toggle.onValueChanged:RemoveAllListeners()
        cell.toggle.onValueChanged:AddListener(function(isOn)
            if isOn then
                self:SwitchPage(CSIndex(luaIndex))
            end
        end)
    end)
    self.view.guideMediaNode.mediaList:UpdateCount(pageCnt, true)
    self:_OnUpdateCurrentPageIndex(0)
end
WikiGuideCtrl.SwitchPage = HL.Method(HL.Number) << function(self, pageCsIndex)
    local mediaNode = self.view.guideMediaNode
    mediaNode.mediaList:ScrollToIndex(pageCsIndex)
end
WikiGuideCtrl._OnUpdateMediaCell = HL.Method(GameObject, HL.Number) << function(self, obj, csIndex)
    local pageData = self.m_showingPageList[LuaIndex(csIndex)]
    local cell = self.m_getMediaCell(obj)
    cell:InitWikiGuideMediaCell(pageData.id)
end
WikiGuideCtrl._OnUpdateCurrentPageIndex = HL.Method(HL.Number) << function(self, csIndex)
    if csIndex < 0 then
        return
    end
    local pageData = self.m_showingPageList[LuaIndex(csIndex)]
    local mediaNode = self.view.guideMediaNode
    mediaNode.titleTxt.text = pageData.title
    mediaNode.contentTxt.text = InputManager.ParseTextActionId(UIUtils.resolveTextStyle(pageData.content))
    local unlockedTips = {}
    local wikiSystem = GameInstance.player.wikiSystem
    for _, wikiEntryId in pairs(pageData.refWikiEntryIds) do
        if wikiSystem:GetWikiEntryState(wikiEntryId) ~= CS.Beyond.Gameplay.WikiSystem.EWikiEntryState.Locked then
            table.insert(unlockedTips, wikiEntryId)
        end
    end
    local refBtnCnt = #unlockedTips
    self.m_refBtnCache:Refresh(refBtnCnt, function(cell, refBtnLuaIndex)
        cell:InitWikiRefBtn(unlockedTips[refBtnLuaIndex])
    end)
    self.view.wikiRefTitle.gameObject:SetActive(refBtnCnt ~= 0)
    self.m_pageIndexToggleCache:GetItem(LuaIndex(csIndex)).toggle:SetIsOnWithoutNotify(true)
    self.m_isShowingLastPage = csIndex + 1 == #self.m_showingPageList
    mediaNode.leftButton.interactable = csIndex > 0
    mediaNode.rightButton.interactable = not (self.m_isShowingLastPage and self.m_selectedIndex >= self.m_showingEntryCnt)
end
WikiGuideCtrl._OnPhaseItemBind = HL.Override() << function(self)
    self:RefreshTop()
end
WikiGuideCtrl.RefreshTop = HL.Method() << function(self)
    if not self.m_phase then
        return
    end
    local wikiTopArgs = { phase = self.m_phase, panelId = PANEL_ID, categoryType = self.m_showingEntryData.wikiCategoryType, wikiEntryShowData = self.m_showingEntryData }
    self.view.top:InitWikiTop(wikiTopArgs)
end
HL.Commit(WikiGuideCtrl)