local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonFilter
CommonFilterCtrl = HL.Class('CommonFilterCtrl', uiCtrl.UICtrl)
CommonFilterCtrl.ShowCommonFilter = HL.StaticMethod(HL.Table) << function(args)
    self = UIManager:AutoOpen(PANEL_ID)
    self:_Init(args)
end
CommonFilterCtrl.s_messages = HL.StaticField(HL.Table) << {}
CommonFilterCtrl.m_getTagGroupCell = HL.Field(HL.Function)
CommonFilterCtrl.m_selectedTags = HL.Field(HL.Table)
CommonFilterCtrl.m_tagGroups = HL.Field(HL.Table)
CommonFilterCtrl.m_tags = HL.Field(HL.Table)
CommonFilterCtrl.m_args = HL.Field(HL.Table)
CommonFilterCtrl.m_isGroup = HL.Field(HL.Boolean) << false
CommonFilterCtrl.m_titlePaddingTop = HL.Field(HL.Number) << 0
CommonFilterCtrl.m_noTitlePaddingTop = HL.Field(HL.Number) << 0
CommonFilterCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeButton.onClick:AddListener(function()
        self:_CloseSelf()
    end)
    self.view.mask.onClick:AddListener(function()
        self:_CloseSelf()
    end)
    self.view.confirmBtn.onClick:AddListener(function()
        self:_OnClickConfirm()
    end)
    self.view.resetBtn.onClick:AddListener(function()
        self:_OnClickReset()
    end)
    self.m_titlePaddingTop = self.view.tagGroupCell.gridLayoutGroup.padding.top
    self.m_noTitlePaddingTop = self.m_titlePaddingTop - self.view.tagGroupCell.titleNode.transform.rect.height
    self.m_getTagGroupCell = UIUtils.genCachedCellFunction(self.view.scrollList)
    self.view.scrollList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateTagGroupCell(self.m_getTagGroupCell(obj), LuaIndex(csIndex))
    end)
end
CommonFilterCtrl._Init = HL.Method(HL.Table) << function(self, args)
    self.m_args = args
    self.m_tagGroups = args.tagGroups
    local groupCount = #self.m_tagGroups
    self.m_isGroup = groupCount > 1
    if args.selectedTags then
        self.m_selectedTags = lume.copy(args.selectedTags)
    else
        self.m_selectedTags = {}
    end
    self.view.scrollList:UpdateCount(groupCount)
    self:_UpdateResultCount()
end
CommonFilterCtrl._OnUpdateTagGroupCell = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    if not self.m_tagGroups then
        return
    end
    local tagGroupInfo = self.m_tagGroups[index]
    if self.m_isGroup then
        cell.titleText.text = tagGroupInfo.title
        cell.titleNode.gameObject:SetActive(true)
        cell.gridLayoutGroup.padding.top = self.m_titlePaddingTop
    else
        cell.titleNode.gameObject:SetActive(false)
        cell.gridLayoutGroup.padding.top = self.m_noTitlePaddingTop
    end
    if not cell.tagCells then
        cell.tagCells = UIUtils.genCellCache(cell.tagCell)
    end
    cell.tagCells:Refresh(#tagGroupInfo.tags, function(tagCell, tagIndex)
        local tagInfo = tagGroupInfo.tags[tagIndex]
        self:_UpdateTagCell(tagCell, tagInfo)
    end)
end
CommonFilterCtrl._UpdateTagCell = HL.Method(HL.Table, HL.Table) << function(self, cell, tagInfo)
    cell.name.text = tagInfo.name
    cell.toggle.onValueChanged:RemoveAllListeners()
    cell.toggle.isOn = lume.find(self.m_selectedTags, tagInfo) ~= nil
    cell.toggle.onValueChanged:AddListener(function(isOn)
        self:_OnClickTagCell(tagInfo, isOn)
    end)
end
CommonFilterCtrl._OnClickTagCell = HL.Method(HL.Table, HL.Boolean) << function(self, tagInfo, isOn)
    local index = lume.find(self.m_selectedTags, tagInfo)
    if isOn then
        if not index then
            table.insert(self.m_selectedTags, tagInfo)
        end
    else
        if index then
            table.remove(self.m_selectedTags, index)
        end
    end
    self:_UpdateResultCount()
end
CommonFilterCtrl._UpdateResultCount = HL.Method() << function(self)
    local getResultCount = self.m_args.getResultCount
    if not getResultCount or not next(self.m_selectedTags) then
        self.view.filterResultNode.gameObject:SetActive(false)
        return
    end
    self.view.filterResultNode.gameObject:SetActive(true)
    self.view.filterResultCount.text = getResultCount(self.m_selectedTags)
end
CommonFilterCtrl._OnClickConfirm = HL.Method() << function(self)
    local onConfirm = self.m_args.onConfirm
    local selectedTags = next(self.m_selectedTags) and self.m_selectedTags or nil
    self:_CloseSelf()
    onConfirm(selectedTags)
end
CommonFilterCtrl._OnClickReset = HL.Method() << function(self)
    self.m_selectedTags = {}
    self.view.scrollList:UpdateCount(#self.m_tagGroups)
    self:_UpdateResultCount()
end
CommonFilterCtrl._CloseSelf = HL.Method() << function(self)
    self.m_args = nil
    self.m_tags = nil
    self.m_tagGroups = nil
    self.m_selectedTags = nil
    self:PlayAnimationOutAndHide()
end
HL.Commit(CommonFilterCtrl)