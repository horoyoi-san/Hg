local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.WikiEquipSuit
WikiEquipSuitCtrl = HL.Class('WikiEquipSuitCtrl', uiCtrl.UICtrl)
WikiEquipSuitCtrl.s_messages = HL.StaticField(HL.Table) << {}
WikiEquipSuitCtrl.m_wikiGroupShowDataList = HL.Field(HL.Table)
WikiEquipSuitCtrl.m_categoryType = HL.Field(HL.String) << ""
WikiEquipSuitCtrl.m_detailPanelId = HL.Field(HL.Number) << 0
WikiEquipSuitCtrl.m_args = HL.Field(HL.Table)
WikiEquipSuitCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_readWikiEntries = {}
    self.view.wikiVideoBgWidget:InitWikiVideoBg()
    self:Refresh(arg)
end
WikiEquipSuitCtrl.OnShow = HL.Override() << function(self)
    if self.m_phase and self.m_phase.m_currentWikiGroupArgs.wikiEntryShowData ~= self.m_args.wikiEntryShowData then
        self:Refresh(self.m_phase.m_currentWikiGroupArgs, true)
        self:_RefreshTop()
    end
end
WikiEquipSuitCtrl.OnHide = HL.Override() << function(self)
    self:_MarkWikiEntryRead()
end
WikiEquipSuitCtrl.OnClose = HL.Override() << function(self)
    self:_MarkWikiEntryRead()
end
WikiEquipSuitCtrl._OnPhaseItemBind = HL.Override() << function(self)
    self:_RefreshTop()
end
WikiEquipSuitCtrl.Refresh = HL.Method(HL.Table, HL.Opt(HL.Boolean)) << function(self, args, moveTabToSelected)
    self.m_args = args
    self.m_categoryType = args.categoryType
    self.m_detailPanelId = args.detailPanelId
    self.m_wikiGroupShowDataList = WikiUtils.getWikiGroupShowDataList(args.categoryType)
    self:_RefreshTab(moveTabToSelected)
end
WikiEquipSuitCtrl._RefreshTop = HL.Method() << function(self)
    local wikiTopArgs = { phase = self.m_phase, panelId = PANEL_ID, categoryType = self.m_categoryType, }
    self.view.top:InitWikiTop(wikiTopArgs)
end
WikiEquipSuitCtrl.m_getTabCell = HL.Field(HL.Function)
WikiEquipSuitCtrl.m_selectedIndex = HL.Field(HL.Number) << 0
WikiEquipSuitCtrl._RefreshTab = HL.Method(HL.Opt(HL.Boolean)) << function(self, moveTabToSelected)
    if self.m_getTabCell == nil then
        self.m_getTabCell = UIUtils.genCachedCellFunction(self.view.scrollListLeft)
        self.view.scrollListLeft.onUpdateCell:AddListener(function(object, csIndex)
            local tabCell = self.m_getTabCell(object)
            local wikiGroupShowData = self.m_wikiGroupShowDataList[LuaIndex(csIndex)]
            tabCell.titleNormalTxt.text = wikiGroupShowData.wikiGroupData.groupName
            tabCell.titleSelectTxt.text = wikiGroupShowData.wikiGroupData.groupName
            local hasSuit, suitDataList = Tables.equipSuitTable:TryGetValue(wikiGroupShowData.wikiGroupData.groupId)
            local tabSprite
            if hasSuit then
                local suitData = suitDataList.list[0]
                tabSprite = self:LoadSprite(UIConst.UI_SPRITE_EQUIPMENT_LOGO_BIG, suitData.suitLogoName)
            else
                local _, domainData = Tables.domainDataTable:TryGetValue(wikiGroupShowData.wikiGroupData.groupId)
                if domainData then
                    tabSprite = self:LoadSprite(UIConst.UI_SPRITE_SETTLEMENT, domainData.domainIcon)
                end
            end
            if tabSprite then
                tabCell.normalIconImg.sprite = tabSprite
                tabCell.selectIconImg.sprite = tabSprite
            end
            tabCell.normalIconImg.gameObject:SetActive(tabSprite ~= nil)
            tabCell.selectIconImg.gameObject:SetActive(tabSprite ~= nil)
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
        self.view.scrollListLeft:ScrollToIndex(CSIndex(selectedIndex), true, CS.Beyond.UI.UIScrollList.ScrollAlignType.Top)
    end
    self:_SetSelectedIndex(selectedIndex)
end
WikiEquipSuitCtrl._SetSelectedIndex = HL.Method(HL.Number) << function(self, selectedIndex)
    self:_SetTabCellSelected(self.m_getTabCell(self.view.scrollListLeft:Get(CSIndex(self.m_selectedIndex))), false)
    self.m_selectedIndex = selectedIndex
    self:_SetTabCellSelected(self.m_getTabCell(self.view.scrollListLeft:Get(CSIndex(selectedIndex))), true)
    local wikiGroupShowData = self.m_wikiGroupShowDataList[selectedIndex]
    self:_RefreshRight(wikiGroupShowData)
end
WikiEquipSuitCtrl._SetTabCellSelected = HL.Method(HL.Table, HL.Boolean) << function(self, cell, isSelected)
    if not cell then
        return
    end
    cell.normalNode.gameObject:SetActive(not isSelected)
    cell.selectNode.gameObject:SetActive(isSelected)
end
WikiEquipSuitCtrl.m_getSuitEffectCell = HL.Field(HL.Function)
WikiEquipSuitCtrl.m_getItemCell = HL.Field(HL.Function)
WikiEquipSuitCtrl.m_wikiEntryShowDataList = HL.Field(HL.Table)
WikiEquipSuitCtrl.m_suitData = HL.Field(HL.Userdata)
WikiEquipSuitCtrl._RefreshRight = HL.Method(HL.Table) << function(self, wikiGroupShowData)
    local hasSuit, suitDataList = Tables.equipSuitTable:TryGetValue(wikiGroupShowData.wikiGroupData.groupId)
    if hasSuit then
        self.m_suitData = suitDataList.list[0]
    end
    self.view.skillEffectNode.gameObject:SetActive(hasSuit)
    local suitEffectCount = hasSuit and 1 or 0
    if not self.m_getSuitEffectCell then
        self.m_getSuitEffectCell = UIUtils.genCachedCellFunction(self.view.scrollListSkillEffect)
        self.view.scrollListSkillEffect.onUpdateCell:AddListener(function(object, csIndex)
            local cell = self.m_getSuitEffectCell(object)
            cell.DescTxt.text = CharInfoUtils.getSkillDesc(self.m_suitData.skillID, self.m_suitData.skillLv)
        end)
    end
    self.view.scrollListSkillEffect:UpdateCount(suitEffectCount)
    self.m_wikiEntryShowDataList = wikiGroupShowData.wikiEntryShowDataList
    if not self.m_getItemCell then
        self.m_getItemCell = UIUtils.genCachedCellFunction(self.view.scrollListWeapon)
        self.view.scrollListWeapon.onUpdateCell:AddListener(function(object, csIndex)
            local itemCell = self.m_getItemCell(object)
            local wikiEntryShowData = self.m_wikiEntryShowDataList[LuaIndex(csIndex)]
            itemCell:InitItem({ id = wikiEntryShowData.wikiEntryData.refItemId }, function()
                local args = { categoryType = self.m_categoryType, wikiEntryShowData = wikiEntryShowData, wikiGroupShowDataList = self.m_wikiGroupShowDataList }
                self.m_phase:CreatePhasePanelItem(self.m_detailPanelId, args)
            end)
            local entryId = wikiEntryShowData.wikiEntryData.id
            itemCell.redDot:InitRedDot("WikiEntry", entryId)
            if WikiUtils.isWikiEntryUnread(entryId) then
                self.m_readWikiEntries[entryId] = true
            end
        end)
    end
    self:_MarkWikiEntryRead()
    self.view.scrollListWeapon:UpdateCount(#self.m_wikiEntryShowDataList)
end
WikiEquipSuitCtrl.m_readWikiEntries = HL.Field(HL.Table)
WikiEquipSuitCtrl._MarkWikiEntryRead = HL.Method() << function(self)
    if self.m_readWikiEntries then
        local entryIdList = {}
        for entryId, _ in pairs(self.m_readWikiEntries) do
            table.insert(entryIdList, entryId)
        end
        GameInstance.player.wikiSystem:MarkWikiEntryRead(entryIdList)
        self.m_readWikiEntries = {}
    end
end
HL.Commit(WikiEquipSuitCtrl)