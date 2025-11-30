local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingDungeonUnit
RacingDungeonUnitCtrl = HL.Class('RacingDungeonUnitCtrl', uiCtrl.UICtrl)
RacingDungeonUnitCtrl.m_unitList = HL.Field(HL.Table)
RacingDungeonUnitCtrl.m_selectedUnit = HL.Field(HL.Number) << 0
RacingDungeonUnitCtrl.m_selectDungeon = HL.Field(HL.String) << ''
RacingDungeonUnitCtrl.m_selectLevel = HL.Field(HL.Number) << 0
RacingDungeonUnitCtrl.m_getCell = HL.Field(HL.Function)
RacingDungeonUnitCtrl.m_racingDungeonSystem = HL.Field(HL.Any)
RacingDungeonUnitCtrl.s_messages = HL.StaticField(HL.Table) << {}
RacingDungeonUnitCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnBack.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.m_racingDungeonSystem = GameInstance.player.racingDungeonSystem
    self:_SetParam(arg.dungeon, arg.level)
    self.m_getCell = self.m_getCell or UIUtils.genCachedCellFunction(self.view.scrollView)
    self.m_selectedUnit = 1
    self.view.scrollView.onUpdateCell:AddListener(function(gameObject, index)
        self:_UpdateCell((gameObject), index)
    end)
    self.m_unitList = {}
    local nowDungeonConfig = nil
    for k, v in pairs(Tables.racingDungeonTable) do
        for i, config in pairs(v.list) do
            if config.level == self.m_selectLevel then
                nowDungeonConfig = config
                break
            end
        end
    end
    local t = Tables.racingTacticsTable
    local maxLevel = self.m_racingDungeonSystem:GetRacingDungeonPassedLevel(self.m_selectDungeon)
    local bHavelock = false
    for j = 0, nowDungeonConfig.tacticsList.Count - 1 do
        for k, v in pairs(t) do
            if v.tacticsId == nowDungeonConfig.tacticsList[j] then
                table.insert(self.m_unitList, v)
            end
        end
    end
    self.m_selectedUnit = -1
    self.view.selectButton.gameObject:SetActive(false)
    self.view.selectButton.onClick:AddListener(function()
        if self.m_selectedUnit == -1 then
            return
        end
        local data = self.m_unitList[self.m_selectedUnit]
        PhaseManager:GoToPhase(PhaseId.CharFormation, { racingDungeonArg = { dungeonId = self.m_selectDungeon, level = self.m_selectLevel, tacticsId = data.tacticsId } })
    end)
    self.view.scrollView:UpdateCount(#self.m_unitList)
end
RacingDungeonUnitCtrl._SetParam = HL.Method(HL.String, HL.Number) << function(self, dungeon, level)
    self.m_selectDungeon = dungeon
    self.m_selectLevel = level
end
RacingDungeonUnitCtrl._UpdateCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local index = LuaIndex(index)
    cell = self.m_getCell(cell)
    if cell == nil then
        return
    end
    local data = self.m_unitList[index]
    local maxLevel = self.m_racingDungeonSystem:GetRacingDungeonPassedLevel(self.m_selectDungeon)
    cell.selectNode.gameObject:SetActive(true)
    cell.selectedState.gameObject:SetActive(index == self.m_selectedUnit)
    cell.teamTxt.text = data.name
    local t = Tables.racingDungeonTable
    local bUnlock = data.unlockLevel <= maxLevel
    cell.toDeUnlocked.gameObject:SetActive(not bUnlock)
    cell.injuryRate.text = UIUtils.resolveTextStyle(self.m_racingDungeonSystem:GetRacingTeamBuffDescription(data.tacticsId))
    cell.injuryRate.gameObject:SetActive(bUnlock)
    cell.lockText.text = string.format(Language.LUA_RACING_DUNGEON_LOCK_CONDITION, data.unlockLevel)
    cell.normalcy.gameObject:SetActive(bUnlock)
    cell.teamTxt.gameObject:SetActive(bUnlock)
    cell.decoText.text = index
    cell.normalcyIcon.sprite = self:LoadSprite("RacingDungeon", data.icon)
    cell.selectedIcon.sprite = self:LoadSprite("RacingDungeon", data.icon)
    cell.normalcy.onClick:RemoveAllListeners()
    cell.normalcy.onClick:AddListener(function()
        if self.m_selectedUnit == index then
            return
        end
        local oldIndex = self.m_selectedUnit
        local oldCell = self.m_getCell((oldIndex))
        local newIndex = index
        local newCell = self.m_getCell(((newIndex)))
        self.m_selectedUnit = index
        if oldIndex ~= -1 and oldCell ~= nil then
            self:_UpdateCell(oldCell, CSIndex(oldIndex))
        end
        if newCell ~= nil then
            self:_UpdateCell(newCell, CSIndex(newIndex))
        end
        self.view.selectButton.gameObject:SetActive(true)
    end)
end
HL.Commit(RacingDungeonUnitCtrl)