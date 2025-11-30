local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.WikiGroup
WikiGroupCtrl = HL.Class('WikiGroupCtrl', uiCtrl.UICtrl)
WikiGroupCtrl.s_messages = HL.StaticField(HL.Table) << {}
WikiGroupCtrl.m_wikiGroupShowDataList = HL.Field(HL.Table)
WikiGroupCtrl.m_categoryType = HL.Field(HL.String) << ""
WikiGroupCtrl.m_detailPanelId = HL.Field(HL.Number) << 0
WikiGroupCtrl.m_args = HL.Field(HL.Table)
WikiGroupCtrl.m_activeScrollListCenter = HL.Field(HL.Any)
WikiGroupCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_readWikiEntries = {}
    self.view.wikiVideoBg:InitWikiVideoBg()
    self.m_activeScrollListCenter = self.view.itemScrollListCenter
    self:Refresh(arg)
end
WikiGroupCtrl.OnShow = HL.Override() << function(self)
    if self.m_phase and (self.m_phase.m_currentWikiGroupArgs.categoryType ~= self.m_args.categoryType or self.m_phase.m_currentWikiGroupArgs.wikiEntryShowData ~= self.m_args.wikiEntryShowData) then
        self:Refresh(self.m_phase.m_currentWikiGroupArgs, true)
        self:_RefreshTop()
    end
end
WikiGroupCtrl.OnHide = HL.Override() << function(self)
    self:_MarkWikiEntryRead()
end
WikiGroupCtrl.OnClose = HL.Override() << function(self)
    self:_MarkWikiEntryRead()
end
WikiGroupCtrl._OnPhaseItemBind = HL.Override() << function(self)
    self:_RefreshTop()
end
WikiGroupCtrl.Refresh = HL.Method(HL.Table, HL.Opt(HL.Boolean)) << function(self, args, moveTabToSelected)
    self.m_args = args
    self.m_detailPanelId = args.detailPanelId
    self:_SwitchCategoryType(args.categoryType)
    self.m_wikiGroupShowDataList = WikiUtils.getWikiGroupShowDataList(args.categoryType, nil, args.includeLocked)
    self:_RefreshTab(moveTabToSelected)
end
WikiGroupCtrl._SwitchCategoryType = HL.Method(HL.String) << function(self, categoryType)
    self.m_categoryType = categoryType
    if self.m_categoryType == WikiConst.EWikiCategoryType.Monster then
        self:_SwitchActiveScrollList(self.view.monsterScrollListCenter)
    else
        self:_SwitchActiveScrollList(self.view.itemScrollListCenter)
    end
end
WikiGroupCtrl._SwitchActiveScrollList = HL.Method(HL.Any) << function(self, scrollListToActivate)
    if self.m_activeScrollListCenter == scrollListToActivate then
        return
    end
    self.m_activeScrollListCenter.gameObject:SetActive(false)
    self.m_activeScrollListCenter = scrollListToActivate
    self.m_activeScrollListCenter.gameObject:SetActive(true)
end
WikiGroupCtrl._RefreshTop = HL.Method() << function(self)
    local wikiTopArgs = { phase = self.m_phase, panelId = PANEL_ID, categoryType = self.m_categoryType, }
    self.view.top:InitWikiTop(wikiTopArgs)
end
WikiGroupCtrl.m_getTabCell = HL.Field(HL.Function)
WikiGroupCtrl.m_selectedIndex = HL.Field(HL.Number) << 0
WikiGroupCtrl._RefreshTab = HL.Method(HL.Opt(HL.Boolean)) << function(self, moveTabToSelected)
    if self.m_getTabCell == nil then
        self.m_getTabCell = UIUtils.genCachedCellFunction(self.view.scrollListLeft)
        self.view.scrollListLeft.onUpdateCell:AddListener(function(object, csIndex)
            local tabCell = self.m_getTabCell(object)
            local wikiGroupShowData = self.m_wikiGroupShowDataList[LuaIndex(csIndex)]
            tabCell.txtTitleNormal.text = wikiGroupShowData.wikiGroupData.groupName
            tabCell.txtTitleSelected.text = wikiGroupShowData.wikiGroupData.groupName
            local groupSprite = self:LoadSprite(UIConst.UI_SPRITE_WIKI_GROUP, wikiGroupShowData.wikiGroupData.iconId)
            tabCell.normalIconImg.sprite = groupSprite
            tabCell.selectIconImg.sprite = groupSprite
            self:_SetTabCellSelected(tabCell, self.m_selectedIndex == LuaIndex(csIndex))
            tabCell.btn.onClick:RemoveAllListeners()
            tabCell.btn.onClick:AddListener(function()
                self:_SetSelectedIndex(LuaIndex(csIndex))
            end)
            tabCell.redDot:InitRedDot("WikiGroup", wikiGroupShowData.wikiGroupData.groupId)
        end)
    end
    self.view.scrollListLeft:UpdateCount(#self.m_wikiGroupShowDataList)
    local selectedIndex = 1
    if self.m_args.wikiEntryShowData then
        for i, groupShowData in ipairs(self.m_wikiGroupShowDataList) do
            if self.m_args.wikiEntryShowData.wikiGroupData.groupId == groupShowData.wikiGroupData.groupId then
                selectedIndex = i
                break
            end
        end
    end
    if moveTabToSelected then
        self.view.scrollListLeft:ScrollToIndex(CSIndex(selectedIndex), false)
    end
    self:_SetSelectedIndex(selectedIndex)
end
WikiGroupCtrl._SetSelectedIndex = HL.Method(HL.Number) << function(self, selectedIndex)
    self:_SetTabCellSelected(self.m_getTabCell(self.view.scrollListLeft:Get(CSIndex(self.m_selectedIndex))), false)
    self.m_selectedIndex = selectedIndex
    self:_SetTabCellSelected(self.m_getTabCell(self.view.scrollListLeft:Get(CSIndex(selectedIndex))), true)
    local wikiGroupShowData = self.m_wikiGroupShowDataList[selectedIndex]
    self:_RefreshScrollListCenter(wikiGroupShowData)
end
WikiGroupCtrl._SetTabCellSelected = HL.Method(HL.Table, HL.Boolean) << function(self, cell, isSelected)
    if not cell then
        return
    end
    cell.normalNode.gameObject:SetActive(not isSelected)
    cell.selectNode.gameObject:SetActive(isSelected)
end
WikiGroupCtrl.m_getItemCell = HL.Field(HL.Function)
WikiGroupCtrl.m_getMonsterCell = HL.Field(HL.Function)
WikiGroupCtrl.m_wikiEntryShowDataList = HL.Field(HL.Table)
WikiGroupCtrl.m_ignoreScrollListAnim = HL.Field(HL.Boolean) << false
WikiGroupCtrl._RefreshScrollListCenter = HL.Method(HL.Table) << function(self, wikiGroupShowData)
    self:_MarkWikiEntryRead()
    self.m_wikiEntryShowDataList = wikiGroupShowData.wikiEntryShowDataList
    self:_BindCellFunction()
    self.m_activeScrollListCenter:UpdateCount(#self.m_wikiEntryShowDataList, false, false, false, self.m_ignoreScrollListAnim)
    self.m_ignoreScrollListAnim = false
end
WikiGroupCtrl._BindCellFunction = HL.Method() << function(self)
    if self.m_categoryType == WikiConst.EWikiCategoryType.Monster then
        if self.m_getMonsterCell then
            return
        end
        self.m_getMonsterCell = UIUtils.genCachedCellFunction(self.view.monsterScrollListCenter)
        self.view.monsterScrollListCenter.onUpdateCell:AddListener(function(object, csIndex)
            local monsterCell = self.m_getMonsterCell(object)
            local wikiEntryShowData = self.m_wikiEntryShowDataList[LuaIndex(csIndex)]
            monsterCell:InitMonster(wikiEntryShowData.wikiEntryData.refMonsterTemplateId, function()
                self:_MarkWikiEntryRead()
                local args = { categoryType = self.m_categoryType, wikiEntryShowData = wikiEntryShowData, wikiGroupShowDataList = self.m_wikiGroupShowDataList }
                self.m_phase:CreatePhasePanelItem(self.m_detailPanelId, args)
                self.m_ignoreScrollListAnim = true
            end)
            local entryId = wikiEntryShowData.wikiEntryData.id
            monsterCell.redDot.view.content.gameObject:SetActive(WikiUtils.isWikiEntryUnread(entryId))
            if WikiUtils.isWikiEntryUnread(entryId) then
                self.m_readWikiEntries[entryId] = true
            end
        end)
    else
        if self.m_getItemCell then
            return
        end
        self.m_getItemCell = UIUtils.genCachedCellFunction(self.view.itemScrollListCenter)
        self.view.itemScrollListCenter.onUpdateCell:AddListener(function(object, csIndex)
            local itemCell = self.m_getItemCell(object)
            local wikiEntryShowData = self.m_wikiEntryShowDataList[LuaIndex(csIndex)]
            itemCell:InitItem({ id = wikiEntryShowData.wikiEntryData.refItemId }, function()
                self:_MarkWikiEntryRead()
                local args = { categoryType = self.m_categoryType, wikiEntryShowData = wikiEntryShowData, wikiGroupShowDataList = self.m_wikiGroupShowDataList }
                self.m_phase:CreatePhasePanelItem(self.m_detailPanelId, args)
                self.m_ignoreScrollListAnim = true
            end)
            itemCell.view.potentialStar.gameObject:SetActive(false)
            local entryId = wikiEntryShowData.wikiEntryData.id
            itemCell.redDot.view.content.gameObject:SetActive(WikiUtils.isWikiEntryUnread(entryId))
            if itemCell.view.lockedNode then
                itemCell.view.lockedNode.gameObject:SetActive(not wikiEntryShowData.isUnlocked)
            end
            if WikiUtils.isWikiEntryUnread(entryId) then
                self.m_readWikiEntries[entryId] = true
            end
        end)
    end
end
WikiGroupCtrl.m_readWikiEntries = HL.Field(HL.Table)
WikiGroupCtrl._MarkWikiEntryRead = HL.Method() << function(self)
    if self.m_readWikiEntries then
        local entryIdList = {}
        for entryId, _ in pairs(self.m_readWikiEntries) do
            table.insert(entryIdList, entryId)
        end
        GameInstance.player.wikiSystem:MarkWikiEntryRead(entryIdList)
        self.m_readWikiEntries = {}
    end
end
HL.Commit(WikiGroupCtrl)