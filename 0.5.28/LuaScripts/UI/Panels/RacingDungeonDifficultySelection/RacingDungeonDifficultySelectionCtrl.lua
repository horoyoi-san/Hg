local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingDungeonDifficultySelection
RacingDungeonDifficultySelectionCtrl = HL.Class('RacingDungeonDifficultySelectionCtrl', uiCtrl.UICtrl)
RacingDungeonDifficultySelectionCtrl.m_difficultyList = HL.Field(HL.Table)
RacingDungeonDifficultySelectionCtrl.m_selectedDifficulty = HL.Field(HL.Number) << 0
RacingDungeonDifficultySelectionCtrl.m_maxLevel = HL.Field(HL.Number) << 0
RacingDungeonDifficultySelectionCtrl.m_dungeon = HL.Field(HL.String) << ''
RacingDungeonDifficultySelectionCtrl.m_racingDungeonSystem = HL.Field(HL.Any)
RacingDungeonDifficultySelectionCtrl.m_getCell = HL.Field(HL.Function)
RacingDungeonDifficultySelectionCtrl.m_activeScroll = HL.Field(HL.Boolean) << false
RacingDungeonDifficultySelectionCtrl.s_messages = HL.StaticField(HL.Table) << {}
RacingDungeonDifficultySelectionCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnUpNormal.onClick:AddListener(function()
        if self.m_selectedDifficulty > 0 then
            local oldIndex = self.m_selectedDifficulty
            self.m_selectedDifficulty = self.m_selectedDifficulty - 1
            local newIndex = self.m_selectedDifficulty
            self:_UpdateBtn()
            local oldCell = self.m_getCell(LuaIndex(oldIndex))
            local newCell = self.m_getCell(LuaIndex(newIndex))
            self:_UpdateCell(oldCell, (oldIndex))
            self:_UpdateCell(newCell, (newIndex))
            self.view.scrollView:ScrollToIndex(self.m_selectedDifficulty)
        end
    end)
    self.view.btnDownNormal.onClick:AddListener(function()
        if self.m_selectedDifficulty < #self.m_difficultyList - 1 then
            local oldIndex = self.m_selectedDifficulty
            self.m_selectedDifficulty = self.m_selectedDifficulty + 1
            local newIndex = self.m_selectedDifficulty
            self:_UpdateBtn()
            local oldCell = self.m_getCell(LuaIndex(oldIndex))
            local newCell = self.m_getCell(LuaIndex(newIndex))
            self:_UpdateCell(oldCell, (oldIndex))
            self:_UpdateCell(newCell, (newIndex))
            self.view.scrollView:ScrollToIndex(self.m_selectedDifficulty)
        end
    end)
    self.m_racingDungeonSystem = GameInstance.player.racingDungeonSystem
    self.view.btnBack.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.m_getCell = self.m_getCell or UIUtils.genCachedCellFunction(self.view.scrollView)
    self.view.scrollView.onUpdateCell:AddListener(function(gameObject, index)
        self:_UpdateCell((gameObject), index)
    end)
    self.view.scrollView.onGraduallyShowFinish:AddListener(function()
        self.m_activeScroll = false
    end)
    self.view.scrollView.onCenterIndexChanged:AddListener(function(oldIndex, newIndex)
        if self.m_selectedDifficulty ~= newIndex and not self.m_activeScroll then
            self.m_selectedDifficulty = newIndex
            self:_UpdateBtn()
            local oldCell = self.m_getCell(LuaIndex(oldIndex))
            local newCell = self.m_getCell(LuaIndex(newIndex))
            self:_UpdateCell(oldCell, oldIndex)
            self:_UpdateCell(newCell, newIndex)
            return
        end
    end)
    self.m_difficultyList = {}
    local t = Tables.racingDungeonTable
    for k, v in pairs(t) do
        self.m_dungeon = k
        self.m_maxLevel = self.m_racingDungeonSystem:GetRacingDungeonPassedLevel(k)
        self.m_maxLevel = self.m_maxLevel > 0 and self.m_maxLevel or 0
        for index, item in pairs(v.list) do
            table.insert(self.m_difficultyList, item)
        end
    end
    table.sort(self.m_difficultyList, function(a, b)
        return a.level > b.level
    end)
    self.m_activeScroll = true
    self.m_selectedDifficulty = #self.m_difficultyList - 1
    self.view.scrollView:UpdateCount(#self.m_difficultyList)
    self:_UpdateBtn()
    local height = self.view.scrollView.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)).rect.height
    self.view.scrollView:SetPaddingBottom(height / 2)
    self.view.scrollView:SetPaddingTop(height / 2)
    self.view.scrollView:ScrollToIndex(self.m_selectedDifficulty)
end
RacingDungeonDifficultySelectionCtrl._UpdateBtn = HL.Method() << function(self)
    self.view.btnUpNotClick.gameObject:SetActive(self.m_selectedDifficulty == 0)
    self.view.btnUpNormal.gameObject:SetActive(self.m_selectedDifficulty > 0)
    self.view.btnDownNotClick.gameObject:SetActive(self.m_selectedDifficulty == #self.m_difficultyList - 1)
    self.view.btnDownNormal.gameObject:SetActive(self.m_selectedDifficulty < #self.m_difficultyList - 1)
end
RacingDungeonDifficultySelectionCtrl._UpdateCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    if not cell then
        return
    end
    local rawIndex = index
    local index = LuaIndex(index)
    cell = self.m_getCell(cell)
    cell.gameObject.name = #self.m_difficultyList - index + 1
    local data = self.m_difficultyList[index]
    cell.selectNode.gameObject:SetActive(rawIndex == self.m_selectedDifficulty)
    cell.selectedState.gameObject:SetActive(false)
    cell.text.text = tostring(data.level)
    cell.titleTxt.text = UIUtils.resolveTextStyle(data.enemyDesc)
    cell.rewardDesc.text = UIUtils.resolveTextStyle(data.rewardDesc)
    cell.rewardIcon.gameObject:SetActive(not string.isEmpty(data.rewardDesc))
    cell.select.gameObject:SetActive(data.level <= self.m_maxLevel + 1)
    cell.toDeUnlocked.gameObject:SetActive(data.level > self.m_maxLevel + 1)
    cell.lockText.text = UIUtils.resolveTextStyle(string.format(Language.LUA_RACING_DUNGEON_LOCK_CONDITION, data.level - 1))
    if rawIndex == self.m_selectedDifficulty then
        self.view.fractionTxt.text = math.ceil(data.scoreRatio * 100)
        cell.selectNode.onClick:RemoveAllListeners()
        cell.selectNode.onClick:AddListener(function()
            UIManager:Open(PanelId.RacingDungeonUnit, { level = data.level, dungeon = self.m_dungeon })
            self.view.animationWrapper:SampleToInAnimationEnd()
        end)
        cell.gameObject:GetComponent(typeof(CS.Beyond.UI.UIAnimationWrapper)):Play("difficultyselection_obj_in2")
        AudioAdapter.PostEvent("Au_UI_Event_DifficultySelection")
        self.view.selectedState:Play("difficultyselection_obj_in")
    end
end
HL.Commit(RacingDungeonDifficultySelectionCtrl)