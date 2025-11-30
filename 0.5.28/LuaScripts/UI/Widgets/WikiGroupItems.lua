local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
WikiGroupItems = HL.Class('WikiGroupItems', UIWidgetBase)
WikiGroupItems._OnFirstTimeInit = HL.Override() << function(self)
end
WikiGroupItems.InitWikiGroupItems = HL.Method(HL.Table, HL.Number, HL.Number, HL.Function, HL.Function, HL.Table).Return(HL.Userdata) << function(self, wikiGroupShowData, startIndex, endIndex, onGetSelectedEntryShowData, onItemClicked, readWikiEntries)
    self:_FirstTimeInit()
    local isTitle = startIndex == 0 and endIndex == 0
    local isMonster = wikiGroupShowData.wikiCategoryType == WikiConst.EWikiCategoryType.Monster
    self.view.titleNode.gameObject:SetActive(isTitle)
    self.view.itemNode.gameObject:SetActive(not isTitle and not isMonster)
    self.view.monsterNode.gameObject:SetActive(not isTitle and isMonster)
    if isTitle then
        self.view.titleTxt.text = wikiGroupShowData.wikiGroupData.groupName
        if wikiGroupShowData.wikiCategoryType == WikiConst.EWikiCategoryType.Equip then
            self.view.iconImg.gameObject:SetActive(false)
        else
            self.view.iconImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_WIKI_GROUP, wikiGroupShowData.wikiGroupData.iconId)
        end
        return nil
    end
    local selectedCell = nil
    local selectedEntryShowData = onGetSelectedEntryShowData and onGetSelectedEntryShowData()
    local itemCount = endIndex - startIndex + 1
    local rootNode
    local initFuncName
    local getInitParamFunc
    if isMonster then
        rootNode = self.view.monsterNode
        initFuncName = "InitMonster"
        getInitParamFunc = function(wikiEntryShowData)
            return wikiEntryShowData.wikiEntryData.refMonsterTemplateId
        end
    else
        rootNode = self.view.itemNode
        initFuncName = "InitItem"
        getInitParamFunc = function(wikiEntryShowData)
            return { id = wikiEntryShowData.wikiEntryData.refItemId }
        end
    end
    CSUtils.UIContainerResize(rootNode, itemCount)
    for i = 1, itemCount do
        local cell = Utils.wrapLuaNode(rootNode:GetChild(i - 1))
        local wikiEntryShowData = wikiGroupShowData.wikiEntryShowDataList[startIndex + i - 1]
        cell[initFuncName](cell, getInitParamFunc(wikiEntryShowData), function()
            onItemClicked(cell, wikiEntryShowData)
        end)
        if cell.view.lockedNode then
            cell.view.lockedNode.gameObject:SetActive(not wikiEntryShowData.isUnlocked)
        end
        if cell.view.potentialStar then
            cell.view.potentialStar.gameObject:SetActive(false)
        end
        if selectedEntryShowData and wikiEntryShowData.wikiEntryData.id == selectedEntryShowData.wikiEntryData.id then
            cell:SetSelected(true)
            selectedCell = cell;
        end
        local entryId = wikiEntryShowData.wikiEntryData.id
        cell.redDot:InitRedDot("WikiEntry", entryId)
        if WikiUtils.isWikiEntryUnread(entryId) then
            readWikiEntries[entryId] = true
        end
    end
    return selectedCell
end
HL.Commit(WikiGroupItems)
return WikiGroupItems