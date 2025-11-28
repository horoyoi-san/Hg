local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Reading
local PHASE_ID = PhaseId.Reading
ReadingCtrl = HL.Class('ReadingCtrl', uiCtrl.UICtrl)
ReadingCtrl.s_messages = HL.StaticField(HL.Table) << {}
ReadingCtrl.m_tabCells = HL.Field(HL.Forward("UIListCache"))
ReadingCtrl.m_selectIndex = HL.Field(HL.Number) << -1
ReadingCtrl.m_readingData = HL.Field(HL.Userdata)
ReadingCtrl.m_readingDataList = HL.Field(HL.Table)
ReadingCtrl.OnOpenReadingPhase = HL.StaticMethod(HL.Table) << function(args)
    local readingId = unpack(args)
    PhaseManager:OpenPhase(PHASE_ID, { readingId = readingId })
end
ReadingCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnClose.onClick:RemoveAllListeners()
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PHASE_ID)
    end)
    self.m_tabCells = UIUtils.genCellCache(self.view.tabCell)
    local readingId = arg.readingId
    local res, data = Tables.prtsReading:TryGetValue(readingId)
    if res then
        self.m_readingData = data
    else
        logger.error("终端机id表中不存在: ", readingId)
    end
end
ReadingCtrl.OnShow = HL.Override() << function(self)
    self:RefreshReading()
end
ReadingCtrl.OnClose = HL.Override() << function(self)
    local oldData = self.m_readingDataList[self.m_selectIndex]
    if oldData then
        EventLogManagerInst:GameEvent_CloseNarrativeContent(oldData.contentId)
    end
end
ReadingCtrl._OnTabClick = HL.Method(HL.Number) << function(self, index)
    if self.m_selectIndex ~= index then
        local oldCell = self.m_tabCells:GetItem(self.m_selectIndex)
        if oldCell then
            ReadingCtrl.RefreshTabSelect(oldCell, false)
        end
        local newCell = self.m_tabCells:GetItem(index)
        if newCell then
            ReadingCtrl.RefreshTabSelect(newCell, true)
        end
        local uniqId = self.m_readingDataList[index].uniqId
        if not string.isEmpty(uniqId) then
            if not GameInstance.player.prts.prtsTerminalContentSet:Contains(uniqId) then
                GameInstance.player.prts:PRTSTerminalRead(uniqId)
            end
        end
        local oldData = self.m_readingDataList[self.m_selectIndex]
        if oldData then
            EventLogManagerInst:GameEvent_CloseNarrativeContent(oldData.contentId)
        end
        local newData = self.m_readingDataList[index]
        if newData then
            EventLogManagerInst:GameEvent_ReadNarrativeContent(newData.contentId)
        end
        self.m_selectIndex = index
        self:_RefreshContent()
    end
end
ReadingCtrl.RefreshTabSelect = HL.StaticMethod(HL.Table, HL.Boolean) << function(cell, select)
    cell.selected.gameObject:SetActive(select)
    cell.default.gameObject:SetActive(not select)
end
ReadingCtrl._RefreshContent = HL.Method() << function(self)
    local readingData = self.m_readingDataList[self.m_selectIndex]
    local contentId = readingData.contentId
    self.view.richContent:SetContentById(contentId)
end
ReadingCtrl.RefreshReading = HL.Method() << function(self)
    local list = {}
    for order, singleData in pairs(self.m_readingData.list) do
        table.insert(list, singleData)
    end
    table.sort(list, Utils.genSortFunction({ "order" }, true))
    self.m_readingDataList = list
    self:_OnTabClick(1)
    self.m_tabCells:Refresh(#self.m_readingDataList, function(cell, luaIndex)
        local select = luaIndex == self.m_selectIndex
        local data = self.m_readingDataList[luaIndex]
        ReadingCtrl.RefreshTabSelect(cell, select)
        local name = UIUtils.resolveTextCinematic(data.name)
        local subTitle = UIUtils.resolveTextCinematic(data.subtitle)
        cell.defaultTitle.text = name
        cell.selectedTitle.text = name
        cell.defaultTxt.text = subTitle
        cell.selectedTxt.text = subTitle
        cell.redDot:InitRedDot("PRTSReading", data.uniqId)
        cell.button.onClick:RemoveAllListeners()
        cell.button.onClick:AddListener(function()
            self:_OnTabClick(luaIndex)
        end)
    end)
end
HL.Commit(ReadingCtrl)