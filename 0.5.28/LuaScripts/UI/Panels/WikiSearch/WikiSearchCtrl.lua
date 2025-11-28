local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.WikiSearch
WikiSearchCtrl = HL.Class('WikiSearchCtrl', uiCtrl.UICtrl)
local STATE_NAME = { SEARCH = "search", RESULT = "result", EMPTY = "empty", }
WikiSearchCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_CHECK_SENSITIVE_SUCCESS] = '_OnCheckSensitiveSuccess', }
WikiSearchCtrl.m_isShowingResult = HL.Field(HL.Boolean) << false
WikiSearchCtrl.m_checkSensitiveKeyword = HL.Field(HL.Any)
WikiSearchCtrl.m_inputFieldText = HL.Field(HL.String) << ""
WikiSearchCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_readWikiEntries = {}
    self.view.btnBack.onClick:AddListener(function()
        self:_ClearSearch(true)
        self:PlayAnimationOutAndHide()
    end)
    self.view.searchBtn.onClick:AddListener(function()
        self:_OnSearchBtnClicked()
    end)
    self.view.detailsBtn.onClick:AddListener(function()
        Notify(MessageConst.SHOW_WIKI_ENTRY, { wikiEntryId = self.m_curWikiEntryShowData.wikiEntryData.id })
    end)
    self.view.inputField.characterLimit = UIConst.INPUT_FIELD_NAME_CHARACTER_LIMIT
    self.view.inputField.onSubmit:AddListener(function(text)
        self:_OnSearchBtnClicked()
    end)
    self.view.inputField.onValueChanged:AddListener(function(text)
        if self.m_isSearchBtnClear then
            self:_SetSearchBtnClear(false)
        end
        self.m_inputFieldText = text
    end)
    self.view.inputField.onValidateInput = function(text, charIndex, addedChar)
        return self:_ValidateInput(addedChar)
    end
    self.view.inputField.onFocused:AddListener(function()
        self:_ShowHistory()
    end)
    self:_ClearSearch()
end
WikiSearchCtrl.OnShow = HL.Override() << function(self)
    if string.isEmpty(self.view.inputField.text) then
        self:_SetSearchBtnClear(false)
        self.view.inputField:ActivateInputField()
        self:_ShowHistory()
    end
end
WikiSearchCtrl._ValidateInput = HL.Method(HL.Number).Return(HL.Any) << function(self, addedChar)
    local tmpInput = self.m_inputFieldText .. utf8.char(addedChar)
    local length = I18nUtils.GetTextRealLength(tmpInput)
    if length > UIConst.INPUT_FIELD_NAME_CHARACTER_LIMIT then
        self.view.inputField.isLastKeyBackspace = true
        return ""
    else
        return addedChar
    end
end
WikiSearchCtrl._OnSearchBtnClicked = HL.Method() << function(self)
    if self.m_isSearchBtnClear then
        self:_ClearSearch()
        return
    end
    local keyword = string.trim(self.view.inputField.text)
    self.view.inputField.text = keyword
    if string.isEmpty(keyword) then
        self.view.inputField:ActivateInputField()
        return
    end
    self.m_checkSensitiveKeyword = keyword
    GameInstance.player.wikiSystem:CheckSensitive(keyword)
end
WikiSearchCtrl._OnCheckSensitiveSuccess = HL.Method() << function(self)
    if not self.m_checkSensitiveKeyword then
        return
    end
    local keyword = self.m_checkSensitiveKeyword
    self.m_checkSensitiveKeyword = nil
    self:_Search(keyword)
end
WikiSearchCtrl._Search = HL.Method(HL.String) << function(self, keyword)
    self.m_phase.curSearchKeyword = keyword
    Notify(MessageConst.ON_WIKI_SEARCH_KEYWORD_CHANGED, keyword)
    self.m_isShowingResult = true
    self:_SetSearchBtnClear(true)
    local resultItems, resultTutorials = self:_GetSearchResult(keyword)
    if #resultItems == 0 and #resultTutorials == 0 then
        self.view.emptyTxt.text = string.format(Language.LUA_WIKI_SEARCH_NOT_FOUND_FORMAT, keyword)
        self.view.stateCtrl:SetState(STATE_NAME.EMPTY)
        return
    end
    WikiUtils.addHistorySearchKeyword(keyword)
    self:_RefreshResult(resultItems, resultTutorials)
end
WikiSearchCtrl._ClearSearch = HL.Method(HL.Opt(HL.Boolean)) << function(self, isClosed)
    if self.m_phase then
        self.m_phase.curSearchKeyword = ""
    end
    self.view.inputField.text = ""
    Notify(MessageConst.ON_WIKI_SEARCH_KEYWORD_CHANGED, "")
    if isClosed == true then
        return
    end
    self:_SetSearchBtnClear(false)
    self.view.inputField:ActivateInputField()
    self:_ShowHistory()
end
WikiSearchCtrl._ShowHistory = HL.Method() << function(self)
    self.view.stateCtrl:SetState(STATE_NAME.SEARCH)
    self.m_isShowingResult = false
    self:_RefreshHistory()
    self:_MarkWikiEntryRead()
end
WikiSearchCtrl.m_isSearchBtnClear = HL.Field(HL.Boolean) << false
WikiSearchCtrl._SetSearchBtnClear = HL.Method(HL.Boolean) << function(self, isClear)
    self.m_isSearchBtnClear = isClear
    self.view.searchBtnTxt.text = isClear and Language.ui_wiki_common_search_clear or Language.ui_wiki_common_search
end
WikiSearchCtrl._GetSearchResult = HL.Method(HL.String).Return(HL.Table, HL.Table) << function(self, keyword)
    local resultItems = {}
    local resultTutorials = {}
    local hasValue
    for categoryId, _ in pairs(Tables.wikiCategoryTable) do
        local categoryResult = {}
        local wikiGroupDataList = Tables.wikiGroupTable[categoryId]
        for _, wikiGroupData in pairs(wikiGroupDataList.list) do
            local _, wikiEntryList = Tables.wikiEntryTable:TryGetValue(wikiGroupData.groupId)
            if wikiEntryList then
                for _, wikiEntryId in pairs(wikiEntryList.list) do
                    if GameInstance.player.wikiSystem:GetWikiEntryState(wikiEntryId) ~= CS.Beyond.Gameplay.WikiSystem.EWikiEntryState.Locked then
                        local _, wikiEntryData = Tables.wikiEntryDataTable:TryGetValue(wikiEntryId)
                        local entryDesc
                        if not string.isEmpty(wikiEntryData.refItemId) then
                            local itemData
                            hasValue, itemData = Tables.itemTable:TryGetValue(wikiEntryData.refItemId)
                            if hasValue then
                                entryDesc = itemData.name
                            end
                        elseif not string.isEmpty(wikiEntryData.refMonsterTemplateId) then
                            local enemyDisplayInfoData
                            hasValue, enemyDisplayInfoData = Tables.enemyTemplateDisplayInfoTable:TryGetValue(wikiEntryData.refMonsterTemplateId)
                            if hasValue then
                                entryDesc = enemyDisplayInfoData.name
                            end
                        else
                            entryDesc = wikiEntryData.desc
                        end
                        if entryDesc and string.find(string.lower(entryDesc), string.lower(keyword), 1, true) then
                            table.insert(categoryResult, { wikiCategoryType = categoryId, wikiGroupData = wikiGroupData, wikiEntryData = wikiEntryData, })
                        end
                    end
                end
            end
        end
        if #categoryResult > 0 then
            local result = categoryId == WikiConst.EWikiCategoryType.Tutorial and resultTutorials or resultItems
            table.insert(result, { categoryId = categoryId, categoryResult = categoryResult, })
        end
    end
    return resultItems, resultTutorials
end
WikiSearchCtrl.m_groupItemsCache = HL.Field(HL.Forward("UIListCache"))
WikiSearchCtrl.m_groupTutorialsCache = HL.Field(HL.Forward("UIListCache"))
WikiSearchCtrl._RefreshResult = HL.Method(HL.Table, HL.Table) << function(self, resultItems, resultTutorials)
    self:_MarkWikiEntryRead()
    self.view.stateCtrl:SetState(STATE_NAME.RESULT)
    local contentPosition = self.view.scrollContent.localPosition
    contentPosition.y = 0
    self.view.scrollContent.localPosition = contentPosition
    local isFirstSelected = nil
    if not self.m_groupItemsCache then
        self.m_groupItemsCache = UIUtils.genCellCache(self.view.wikiSearchGroupItems)
    end
    self.m_groupItemsCache:Refresh(#resultItems, function(cell, luaIndex)
        isFirstSelected = true
        local wikiSearchResult = resultItems[luaIndex]
        cell:InitWikiSearchGroupItems(wikiSearchResult, function(itemCell, entryShowData)
            self:_SetItemSelected(itemCell, entryShowData)
        end, self.m_readWikiEntries, luaIndex == 1)
    end)
    if not self.m_groupTutorialsCache then
        self.m_groupTutorialsCache = UIUtils.genCellCache(self.view.wikiSearchGroupTutorials)
    end
    self.m_groupTutorialsCache:Refresh(#resultTutorials, function(cell, luaIndex)
        local wikiSearchResult = resultTutorials[luaIndex]
        cell:InitWikiSearchGroupTutorials(wikiSearchResult, function(itemCell, entryShowData)
            self:_SetItemSelected(itemCell, entryShowData)
        end, not isFirstSelected and luaIndex == 1)
    end)
end
WikiSearchCtrl.m_selectedItem = HL.Field(HL.Userdata)
WikiSearchCtrl._SetItemSelected = HL.Method(HL.Userdata, HL.Table) << function(self, itemCell, entryShowData)
    if self.m_selectedItem then
        self.m_selectedItem:SetSelected(false)
    end
    if itemCell then
        itemCell:SetSelected(true)
        self.m_selectedItem = itemCell
    end
    local entryId = entryShowData.wikiEntryData.id
    if WikiUtils.isWikiEntryUnread(entryId) then
        GameInstance.player.wikiSystem:MarkWikiEntryRead({ entryId })
    end
    self:_RefreshDetails(entryShowData)
end
WikiSearchCtrl.m_curWikiEntryShowData = HL.Field(HL.Table)
WikiSearchCtrl._RefreshDetails = HL.Method(HL.Table) << function(self, wikiEntryShowData)
    self.m_curWikiEntryShowData = wikiEntryShowData
    self.view.wikiItemInfo:InitWikiItemInfo({ wikiEntryShowData = wikiEntryShowData, itemImg = self.view.itemImg, wikiGuideMediaCell = self.view.wikiGuideMediaCell, hideDetailBtn = true, })
end
WikiSearchCtrl.m_historyCache = HL.Field(HL.Forward("UIListCache"))
WikiSearchCtrl._RefreshHistory = HL.Method() << function(self)
    local historyKeywords = WikiUtils.getHistorySearchKeywords()
    local hasHistory = historyKeywords and #historyKeywords > 0
    self.view.historyNode.gameObject:SetActive(hasHistory)
    if not hasHistory then
        return
    end
    if not self.m_historyCache then
        self.m_historyCache = UIUtils.genCellCache(self.view.historyCell)
    end
    self.m_historyCache:Refresh(#historyKeywords, function(cell, luaIndex)
        local keyword = historyKeywords[luaIndex]
        cell.nameTxt.text = keyword
        cell.btn.onClick:RemoveAllListeners()
        cell.btn.onClick:AddListener(function()
            self.view.inputField.text = keyword
            self:_Search(keyword)
        end)
    end)
end
WikiSearchCtrl.m_readWikiEntries = HL.Field(HL.Table)
WikiSearchCtrl._MarkWikiEntryRead = HL.Method() << function(self)
    if self.m_readWikiEntries then
        local entryIdList = {}
        for entryId, _ in pairs(self.m_readWikiEntries) do
            table.insert(entryIdList, entryId)
        end
        GameInstance.player.wikiSystem:MarkWikiEntryRead(entryIdList)
        self.m_readWikiEntries = {}
    end
end
HL.Commit(WikiSearchCtrl)