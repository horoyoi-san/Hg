local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.PRTSStoryCollGallery
local PHASE_ID = PhaseId.PRTSStoryCollGallery
PRTSStoryCollGalleryCtrl = HL.Class('PRTSStoryCollGalleryCtrl', uiCtrl.UICtrl)
PRTSStoryCollGalleryCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_UNLOCK_PRTS] = '_OnUnlockStoryColl', [MessageConst.ON_READ_PRTS] = '_OnStoryCollReadStateChange', }
PRTSStoryCollGalleryCtrl.m_genTabCells = HL.Field(HL.Forward("UIListCache"))
PRTSStoryCollGalleryCtrl.m_getItemCellFunc = HL.Field(HL.Function)
PRTSStoryCollGalleryCtrl.m_getFirstLvItemFunc = HL.Field(HL.Function)
PRTSStoryCollGalleryCtrl.m_pageType = HL.Field(HL.String) << ""
PRTSStoryCollGalleryCtrl.m_isOnlyShowUnread = HL.Field(HL.Boolean) << false
PRTSStoryCollGalleryCtrl.m_curTabIndex = HL.Field(HL.Number) << 1
PRTSStoryCollGalleryCtrl.m_info = HL.Field(HL.Table)
PRTSStoryCollGalleryCtrl.m_needClearRedDotSet = HL.Field(HL.Table)
PRTSStoryCollGalleryCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:_InitUI()
    self:_InitData(arg)
    self:_UpdateData()
    self:_RefreshAllUI()
end
PRTSStoryCollGalleryCtrl.OnClose = HL.Override() << function(self)
    if not next(self.m_needClearRedDotSet) then
        return
    end
    for id, _ in pairs(self.m_needClearRedDotSet) do
        local cfg = Utils.tryGetTableCfg(Tables.prtsFirstLv, id)
        if cfg then
            for _, itemId in pairs(cfg.itemIds) do
                GameInstance.player.prts:MarkRead(itemId)
            end
        end
    end
end
PRTSStoryCollGalleryCtrl._OnUnlockStoryColl = HL.Method(HL.Table) << function(self, args)
    local itemId = unpack(args)
    local cfg = Utils.tryGetTableCfg(Tables.prtsAllItem, itemId)
    if cfg and cfg.type == self.m_pageType then
        self:_UpdateData()
        self:_RefreshAllUI()
    end
end
PRTSStoryCollGalleryCtrl._OnStoryCollReadStateChange = HL.Method(HL.Table) << function(self, args)
    local itemId = unpack(args)
    local itemCfg = Utils.tryGetTableCfg(Tables.prtsAllItem, itemId)
    if itemCfg and itemCfg.type == self.m_pageType then
        local firstLvCfg = Utils.tryGetTableCfg(Tables.prtsFirstLv, itemCfg.firstLvId)
        local curCategoryInfo = self.m_info.categoryInfos[self.m_curTabIndex]
        if firstLvCfg and firstLvCfg.categoryId == curCategoryInfo.id then
            PRTSStoryCollGalleryCtrl._UpdateCategoryInfo(curCategoryInfo)
            self:_RefreshUnreadTog()
            self:_RefreshItemList(false)
        end
    end
end
PRTSStoryCollGalleryCtrl._InitData = HL.Method(HL.Any) << function(self, arg)
    if (arg == nil or string.isEmpty(arg.pageType)) then
        logger.error("[PRTSStoryCollGalleryCtrl:_InitData()] arg or arg.pageType is nil!")
        return
    end
    self.m_pageType = arg.pageType
    self.m_isOnlyShowUnread = false
    self.m_curTabIndex = 1
    self.m_needClearRedDotSet = {}
end
PRTSStoryCollGalleryCtrl._UpdateData = HL.Method() << function(self)
    local pageType = self.m_pageType
    local categoryDataDict = GameInstance.player.prts:GetStoryCollCategoryData(pageType)
    if not categoryDataDict then
        logger.error("[PRTSStoryCollGalleryCtrl:_UpdateData()] pageType对应的Cfg不存在！ pageType = " .. pageType)
        return
    end
    local cfg = Utils.tryGetTableCfg(Tables.prtsPage, pageType)
    if not cfg then
        return
    end
    self.m_info = { title = cfg.name, iconPath = cfg.icon, categoryInfos = PRTSStoryCollGalleryCtrl._CreateCategoryInfos(categoryDataDict), }
end
PRTSStoryCollGalleryCtrl._CreateCategoryInfos = HL.StaticMethod(HL.Any).Return(HL.Table) << function(categoryDataDict)
    local infos = {}
    for id, firstLvIds in pairs(categoryDataDict) do
        local categoryCfg = Utils.tryGetTableCfg(Tables.prtsCategory, id)
        if categoryCfg then
            local info = PRTSStoryCollGalleryCtrl._CreateCategoryInfo(categoryCfg, firstLvIds)
            if info.curCollectCount > 0 then
                table.insert(infos, info)
            end
        end
    end
    table.sort(infos, Utils.genSortFunction("index", true))
    return infos
end
PRTSStoryCollGalleryCtrl._CreateCategoryInfo = HL.StaticMethod(HL.Any, HL.Any).Return(HL.Table) << function(categoryCfg, firstLvIds)
    local info = { id = categoryCfg.categoryId, title = categoryCfg.name, index = categoryCfg.order, curCollectCount = 0, itemInfos = {}, unreadItemInfos = {}, firstLvIds = firstLvIds, }
    PRTSStoryCollGalleryCtrl._UpdateCategoryInfo(info)
    return info
end
PRTSStoryCollGalleryCtrl._UpdateCategoryInfo = HL.StaticMethod(HL.Table) << function(categoryInfo)
    categoryInfo.curCollectCount = 0
    categoryInfo.itemInfos = {}
    categoryInfo.unreadItemInfos = {}
    for _, id in pairs(categoryInfo.firstLvIds) do
        if GameInstance.player.prts:IsFirstLvUnlock(id) then
            local info = PRTSStoryCollGalleryCtrl._CreateFirstLvInfo(id)
            if info then
                categoryInfo.curCollectCount = categoryInfo.curCollectCount + info.curCount
                table.insert(categoryInfo.itemInfos, info)
                if info.hasUnread then
                    table.insert(categoryInfo.unreadItemInfos, info)
                end
            end
        end
    end
end
PRTSStoryCollGalleryCtrl._CreateFirstLvInfo = HL.StaticMethod(HL.String).Return(HL.Table) << function(firstLvId)
    local cfg = Utils.tryGetTableCfg(Tables.prtsFirstLv, firstLvId)
    if not cfg then
        return nil
    end
    local info = { firstLvId = firstLvId, name = cfg.name, iconPath = cfg.icon, curCount = GameInstance.player.prts:GetUnlockCountByFirstLvId(firstLvId), maxCount = #cfg.itemIds, hasUnread = GameInstance.player.prts:HasUnreadByFirstLvId(firstLvId), }
    return info
end
PRTSStoryCollGalleryCtrl._InitUI = HL.Method() << function(self)
    local viewRef = self.view
    viewRef.closeBtn.onClick:RemoveAllListeners()
    viewRef.closeBtn.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.PRTSStoryCollGallery)
    end)
    viewRef.unreadTog.onValueChanged:RemoveAllListeners()
    viewRef.unreadTog.isOn = self.m_isOnlyShowUnread
    viewRef.unreadTog.onValueChanged:AddListener(function(isOn)
        self:_OnClickUnreadTog(isOn)
    end)
    self.m_genTabCells = UIUtils.genCellCache(viewRef.tabCell)
    self.m_getItemCellFunc = UIUtils.genCachedCellFunction(viewRef.itemList)
    viewRef.itemList.onUpdateCell:AddListener(function(obj, csIndex)
        local cell = self.m_getItemCellFunc(obj)
        self:_OnRefreshFirstLvItemCell(cell, LuaIndex(csIndex))
    end)
end
PRTSStoryCollGalleryCtrl._RefreshAllUI = HL.Method() << function(self)
    local viewRef = self.view
    viewRef.titleTxt.text = self.m_info.title
    viewRef.iconImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_PRTS, self.m_info.iconPath)
    self:_RefreshTabList()
    self:_RefreshUnreadTog()
    self:_RefreshItemList(true)
end
PRTSStoryCollGalleryCtrl._RefreshUnreadTog = HL.Method() << function(self)
    if self.m_curTabIndex > 0 and self.m_curTabIndex <= #self.m_info.categoryInfos then
        local categoryInfo = self.m_info.categoryInfos[self.m_curTabIndex]
        local unreadCount = #categoryInfo.unreadItemInfos
        if unreadCount > 0 then
            self.view.unreadTog.isOn = self.m_isOnlyShowUnread
            self.view.unreadCountTxt.text = string.format(Language.LUA_PRTS_UNREAD_COUNT_FORMAT, unreadCount)
            self.view.unreadTogState:SetState("Show")
            return
        end
    end
    self.m_isOnlyShowUnread = false
    self.view.unreadTog.isOn = false
    self.view.unreadTogState:SetState("Hide")
end
PRTSStoryCollGalleryCtrl._RefreshTabList = HL.Method() << function(self)
    self.m_genTabCells:Refresh(#self.m_info.categoryInfos, function(cell, luaIndex)
        self:_OnRefreshTabCell(cell, luaIndex)
    end)
end
PRTSStoryCollGalleryCtrl._RefreshItemList = HL.Method(HL.Boolean) << function(self, setTop)
    if self.m_curTabIndex > 0 and self.m_curTabIndex <= #self.m_info.categoryInfos then
        local categoryInfo = self.m_info.categoryInfos[self.m_curTabIndex]
        if self.m_isOnlyShowUnread then
            self.view.itemList:UpdateCount(#categoryInfo.unreadItemInfos, setTop)
        else
            self.view.itemList:UpdateCount(#categoryInfo.itemInfos, setTop)
        end
    else
        self.view.itemList:UpdateCount(0, setTop)
    end
end
PRTSStoryCollGalleryCtrl._OnRefreshTabCell = HL.Method(HL.Table, HL.Number) << function(self, cell, luaIndex)
    local categoryInfo = self.m_info.categoryInfos[luaIndex]
    cell.titleTxt.text = categoryInfo.title
    cell.curCountTxt.text = categoryInfo.curCollectCount
    cell.titleTxt2.text = categoryInfo.title
    cell.curCountTxt2.text = categoryInfo.curCollectCount
    cell.toggle.isOn = luaIndex == self.m_curTabIndex
    cell.toggle.onValueChanged:RemoveAllListeners()
    cell.toggle.onValueChanged:AddListener(function(isOn)
        if isOn and self.m_curTabIndex ~= luaIndex then
            self:_OnClickTabTog(luaIndex)
        end
    end)
    cell.redDot:InitRedDot("PRTSStoryCollCategory", categoryInfo.id)
end
PRTSStoryCollGalleryCtrl._OnRefreshFirstLvItemCell = HL.Method(HL.Table, HL.Number) << function(self, cell, luaIndex)
    local categoryInfo = self.m_info.categoryInfos[self.m_curTabIndex]
    local itemInfo
    if self.m_isOnlyShowUnread then
        itemInfo = categoryInfo.unreadItemInfos[luaIndex]
    else
        itemInfo = categoryInfo.itemInfos[luaIndex]
    end
    cell.nameTxt.text = itemInfo.name
    local realIconPath = Utils.getImgGenderDiffPath(itemInfo.iconPath)
    cell.iconImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_PRTS_ICON, realIconPath)
    if itemInfo.maxCount <= 1 then
        cell.countNode.gameObject:SetActiveIfNecessary(false)
    else
        cell.countNode.gameObject:SetActiveIfNecessary(true)
        cell.countTxt.text = itemInfo.curCount .. '/' .. itemInfo.maxCount
    end
    cell.gotoBtn.onClick:RemoveAllListeners()
    cell.gotoBtn.onClick:AddListener(function()
        self:_OnClickGotoBtn(luaIndex)
    end)
    cell.redDot:InitRedDot("PRTSFirstLv", itemInfo.firstLvId)
    if itemInfo.hasUnread then
        self.m_needClearRedDotSet[itemInfo.firstLvId] = 1
    end
end
PRTSStoryCollGalleryCtrl._OnClickGotoBtn = HL.Method(HL.Number) << function(self, luaIndex)
    local categoryInfo = self.m_info.categoryInfos[self.m_curTabIndex]
    local itemInfos
    if self.m_isOnlyShowUnread then
        itemInfos = categoryInfo.unreadItemInfos
    else
        itemInfos = categoryInfo.itemInfos
    end
    local ids = {}
    for _, info in pairs(itemInfos) do
        table.insert(ids, info.firstLvId)
    end
    PhaseManager:OpenPhase(PhaseId.PRTSStoryCollDetail, { isFirstLvId = true, idList = ids, initShowIndex = luaIndex, showGotoBtn = true, }, nil, true)
end
PRTSStoryCollGalleryCtrl._OnClickUnreadTog = HL.Method(HL.Boolean) << function(self, isOn)
    if self.m_isOnlyShowUnread == isOn then
        return
    end
    self.m_isOnlyShowUnread = isOn
    self:_RefreshUnreadTog()
    self:_RefreshItemList(true)
end
PRTSStoryCollGalleryCtrl._OnClickTabTog = HL.Method(HL.Number) << function(self, luaIndex)
    self.m_isOnlyShowUnread = false
    self.m_curTabIndex = luaIndex
    self:_RefreshUnreadTog()
    self:_RefreshItemList(true)
end
HL.Commit(PRTSStoryCollGalleryCtrl)