local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.AdventureBook
local PHASE_ID = PhaseId.AdventureBook
AdventureBookCtrl = HL.Class('AdventureBookCtrl', uiCtrl.UICtrl)
AdventureBookCtrl.m_genTabCells = HL.Field(HL.Forward("UIListCache"))
AdventureBookCtrl.m_tabInfos = HL.Field(HL.Table)
AdventureBookCtrl.m_curTabIndex = HL.Field(HL.Number) << -1
AdventureBookCtrl.m_createArg = HL.Field(HL.Table)
AdventureBookCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_CHANGE_ADVENTURE_BOOK_TAB] = 'ChangeTab', }
AdventureBookCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_genTabCells = UIUtils.genCellCache(self.view.tabs.tabCell)
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PHASE_ID)
    end)
    self:BindInputPlayerAction("common_open_adventure_book", function()
        PhaseManager:PopPhase(PHASE_ID)
    end)
    self.m_createArg = arg
    self:_InitTabs()
end
AdventureBookCtrl.ChangeTab = HL.Method(HL.Any) << function(self, arg)
    local panelId = PanelId[arg.panelId]
    self.m_curTabIndex = self:_GetCurTabIndexByPanelId(panelId)
    local cell = self.m_genTabCells:Get(self.m_curTabIndex)
    cell.toggle.isOn = true
    self:_OnTabClick(self.m_curTabIndex, true)
    if arg.dungeonTab and panelId == PanelId.AdventureDungeon then
        Notify(MessageConst.ON_CHANGE_ADVENTURE_DUNGEON_TAB, arg.dungeonTab)
    end
end
AdventureBookCtrl._OnPhaseItemBind = HL.Override() << function(self)
    if self.m_createArg then
        self:ChangeTab(self.m_createArg)
        self.m_createArg = nil
    else
        self:_OnTabClick(self.m_curTabIndex, true)
    end
end
AdventureBookCtrl._InitTabs = HL.Method() << function(self)
    self:_InitTabInfos()
    self.m_curTabIndex = 1
    self.m_genTabCells:Refresh(#self.m_tabInfos, function(cell, luaIndex)
        local info = self.m_tabInfos[luaIndex]
        cell.gameObject.name = "AdventureBookTab_" .. luaIndex
        cell.defaultIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ADVENTURE, info.icon)
        cell.selectedIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ADVENTURE, info.icon)
        cell.selectedNameTxt.text = info.tabName
        cell.defaultNameTxt.text = info.tabName
        if not string.isEmpty(info.redDot) then
            if info.redDotArg then
                cell.redDot:InitRedDot(info.redDot, info.redDotArg)
            else
                cell.redDot:InitRedDot(info.redDot)
            end
        end
        cell.toggle.isOn = luaIndex == self.m_curTabIndex
        cell.toggle.onValueChanged:RemoveAllListeners()
        cell.toggle.onValueChanged:AddListener(function(isOn)
            if isOn then
                self:_OnTabClick(luaIndex)
            end
        end)
    end)
end
AdventureBookCtrl._InitTabInfos = HL.Method() << function(self)
    self.m_tabInfos = { { icon = "icon_adventure_book", titleName = Language.ui_AdventureStagePanel_title, tabName = Language.ui_AdventurePanel_title_adventurebook, panelId = PanelId.AdventureStage, redDot = "AdventureBookTabStage", }, { icon = "icon_adventure_daily", titleName = Language.ui_AdventureDailyPanel_title, tabName = Language.ui_AdventurePanel_title_daily, panelId = PanelId.AdventureDaily, redDot = "AdventureBookTabDaily", }, }
    if (Utils.isSystemUnlocked(GEnums.UnlockSystemType.BattleTraining)) then
        table.insert(self.m_tabInfos, { icon = "icon_adventure_training", titleName = Language.ui_AdventureTrainingPanel_title, tabName = Language.ui_AdventurePanel_title_training, panelId = PanelId.AdventureTraining, })
    end
    if (Utils.isSystemUnlocked(GEnums.UnlockSystemType.Dungeon)) then
        table.insert(self.m_tabInfos, { icon = "icon_adventure_dungeon", titleName = Language.ui_AdventureDungeonPanel_title, tabName = Language.ui_AdventurePanel_title_dungeon, panelId = PanelId.AdventureDungeon, redDot = "AdventureBookTabDungeon", })
    end
    if (Utils.isSystemUnlocked(GEnums.UnlockSystemType.FacTechTree)) then
        local canShow = false
        for _, cfg in pairs(Tables.domainDataTable) do
            if not GameInstance.player.facTechTreeSystem:PackageIsLocked(cfg.facTechPackageId) and not GameInstance.player.facTechTreeSystem:PackageIsHidden(cfg.facTechPackageId) then
                canShow = true
                break
            end
        end
        if canShow then
            table.insert(self.m_tabInfos, { icon = "icon_adventure_blackbox", titleName = Language.ui_AdventureBlackboxPanel_title, tabName = Language.ui_AdventurePanel_title_blackbox, panelId = PanelId.AdventureBlackbox, })
        end
    end
    if (Utils.isSystemUnlocked(GEnums.UnlockSystemType.RacingDungeon)) then
        table.insert(self.m_tabInfos, { icon = "icon_adventure_racingdungeon", titleName = Language.ui_AdventureRacingPanel_title, tabName = Language.ui_AdventurePanel_title_racing, panelId = PanelId.AdventureRacingDungeon, })
    end
end
AdventureBookCtrl._GetCurTabIndexByPanelId = HL.Method(HL.Number).Return(HL.Number) << function(self, panelId)
    local index = 1
    for _, info in pairs(self.m_tabInfos) do
        if info.panelId == panelId then
            return index
        end
        index = index + 1
    end
    return 1
end
AdventureBookCtrl._OnTabClick = HL.Method(HL.Number, HL.Opt(HL.Boolean)) << function(self, luaIndex, isInit)
    if self.m_curTabIndex == luaIndex and not isInit then
        return
    end
    self.m_curTabIndex = luaIndex
    local curTabInfo = self.m_tabInfos[luaIndex]
    self.view.titleTxt.text = curTabInfo.titleName
    self.m_phase:OnTabChange({ panelId = curTabInfo.panelId })
end
HL.Commit(AdventureBookCtrl)