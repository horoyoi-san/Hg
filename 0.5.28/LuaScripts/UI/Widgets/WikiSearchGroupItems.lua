local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
WikiSearchGroupItems = HL.Class('WikiSearchGroupItems', UIWidgetBase)
WikiSearchGroupItems.m_itemCache = HL.Field(HL.Forward("UIListCache"))
WikiSearchGroupItems.m_monsterCache = HL.Field(HL.Forward("UIListCache"))
WikiSearchGroupItems._OnFirstTimeInit = HL.Override() << function(self)
    self.m_itemCache = UIUtils.genCellCache(self.view.itemBigBlack)
    self.m_monsterCache = UIUtils.genCellCache(self.view.monsterBigBlack)
end
WikiSearchGroupItems.InitWikiSearchGroupItems = HL.Method(HL.Table, HL.Function, HL.Table, HL.Opt(HL.Boolean)) << function(self, wikiSearchResult, onItemClicked, readWikiEntries, isFirstClicked)
    self:_FirstTimeInit()
    self.view.titleTxt.text = Tables.wikiCategoryTable[wikiSearchResult.categoryId].categoryName
    local refreshFunc = function(cell, luaIndex)
        local entryShowData = wikiSearchResult.categoryResult[luaIndex]
        if wikiSearchResult.categoryId == WikiConst.EWikiCategoryType.Monster then
            cell:InitMonster(entryShowData.wikiEntryData.refMonsterTemplateId, function()
                if onItemClicked then
                    onItemClicked(cell, entryShowData)
                end
            end)
        else
            cell:InitItem({ id = entryShowData.wikiEntryData.refItemId }, function()
                if onItemClicked then
                    onItemClicked(cell, entryShowData)
                end
            end)
            if cell.view.potentialStar then
                cell.view.potentialStar.gameObject:SetActive(false)
            end
            cell.view.levelNode.gameObject:SetActive(false)
        end
        local entryId = entryShowData.wikiEntryData.id
        cell.redDot:InitRedDot("WikiEntry", entryId)
        if WikiUtils.isWikiEntryUnread(entryId) then
            readWikiEntries[entryId] = true
        end
        if isFirstClicked and luaIndex == 1 then
            if onItemClicked then
                onItemClicked(cell, entryShowData)
            end
        end
    end
    if wikiSearchResult.categoryId == WikiConst.EWikiCategoryType.Monster then
        self.m_itemCache:Refresh(0)
        self.m_monsterCache:Refresh(#wikiSearchResult.categoryResult, refreshFunc)
    else
        self.m_monsterCache:Refresh(0)
        self.m_itemCache:Refresh(#wikiSearchResult.categoryResult, refreshFunc)
    end
end
HL.Commit(WikiSearchGroupItems)
return WikiSearchGroupItems