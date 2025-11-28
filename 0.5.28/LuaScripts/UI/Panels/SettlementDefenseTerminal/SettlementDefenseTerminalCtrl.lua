local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementDefenseTerminal
SettlementDefenseTerminalCtrl = HL.Class('SettlementDefenseTerminalCtrl', uiCtrl.UICtrl)
local MAX_DISPLAY_REWARD_COUNT = 3
local INITIAL_SELECTED_GROUP_INDEX = 1
local GROUP_ARROW_MAX_COUNT = 3
local NORMAL_ANIMATION_NAME = "defense_terminal_toggle_left"
local RAID_ANIMATION_NAME = "defense_terminal_toggle_right"
local ENEMY_DETAIL_TITLE_TEXT_ID = "ui_fac_settlement_defence_radar_title"
SettlementDefenseTerminalCtrl.m_groupCells = HL.Field(HL.Forward('UIListCache'))
SettlementDefenseTerminalCtrl.m_rewardCells = HL.Field(HL.Forward('UIListCache'))
SettlementDefenseTerminalCtrl.m_settlementId = HL.Field(HL.String) << ""
SettlementDefenseTerminalCtrl.m_selectedLevelId = HL.Field(HL.String) << ""
SettlementDefenseTerminalCtrl.m_groupDataList = HL.Field(HL.Userdata)
SettlementDefenseTerminalCtrl.m_selectedGroupIndex = HL.Field(HL.Number) << 0
SettlementDefenseTerminalCtrl.s_messages = HL.StaticField(HL.Table) << {}
SettlementDefenseTerminalCtrl.ShowTerminalPanel = HL.StaticMethod(HL.Any) << function(arg)
    PhaseManager:OpenPhase(PhaseId.SettlementDefenseTerminal, arg)
end
SettlementDefenseTerminalCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_groupCells = UIUtils.genCellCache(self.view.groupCell)
    self.m_rewardCells = UIUtils.genCellCache(self.view.rewardItemCell)
    self.view.confirmButton.onClick:AddListener(function()
        self:_OnConfirmButtonClicked()
    end)
    self.view.levelSwitchToggle.toggle.onValueChanged:AddListener(function(isOn)
        local isRaid = not isOn
        self:_RefreshLevelContent(isRaid)
        local animName = isRaid and RAID_ANIMATION_NAME or NORMAL_ANIMATION_NAME
        self.view.levelSwitchToggle.animationWrapper:PlayWithTween(animName)
    end)
    self.view.levelSwitchToggle.toggle.isOn = true
    self.view.closeButton.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.SettlementDefenseTerminal)
    end)
    if type(arg) == "table" then
        self.m_settlementId = unpack(arg)
    else
        self.m_settlementId = arg
    end
    self:_InitGroupList()
end
SettlementDefenseTerminalCtrl._OnConfirmButtonClicked = HL.Method() << function(self)
    PhaseManager:PopPhase(PhaseId.SettlementDefenseTerminal, function()
        GameInstance.player.towerDefenseSystem:EnterPreparingPhase(self.m_selectedLevelId)
    end)
end
SettlementDefenseTerminalCtrl._InitGroupList = HL.Method() << function(self)
    local groupDataList = GameInstance.player.towerDefenseSystem:GetDefenseGroupDataList(self.m_settlementId)
    if groupDataList == nil or groupDataList.Count == 0 then
        self.view.emptyNode.gameObject:SetActive(true)
        self.view.missionNode.gameObject:SetActive(false)
        return
    end
    self.m_groupDataList = groupDataList
    self.m_groupCells:Refresh(groupDataList.Count, function(cell, luaIndex)
        self:_RefreshGroupCell(cell, luaIndex)
        if luaIndex == groupDataList.Count and self.m_selectedGroupIndex <= 0 then
            self:_OnGroupSelected(luaIndex)
        end
    end)
    self.view.emptyNode.gameObject:SetActive(false)
    self.view.missionNode.gameObject:SetActive(true)
end
SettlementDefenseTerminalCtrl._RefreshGroupCell = HL.Method(HL.Any, HL.Number) << function(self, cell, luaIndex)
    cell.normal.gameObject:SetActive(true)
    cell.selected.gameObject:SetActive(false)
    local groupData = self.m_groupDataList[CSIndex(luaIndex)]
    if groupData == nil then
        return
    end
    local groupId = groupData.groupId
    local success, groupTableData = Tables.towerDefenseGroupTable:TryGetValue(groupId)
    if not success then
        return
    end
    cell.button.onClick:AddListener(function()
        self:_OnGroupSelected(luaIndex)
    end)
    cell.gameObject.name = string.format("Group_%d", luaIndex)
    local onlyNormal = groupData.normalLevel ~= nil and groupData.raidLevel == nil
    local isCompleted = groupData.normalLevel.isCompleted
    local isAllCompleted = isCompleted
    if not onlyNormal then
        isAllCompleted = isAllCompleted and groupData.raidLevel.isCompleted
    end
    if self.m_selectedGroupIndex <= 0 and not isAllCompleted then
        self:_OnGroupSelected(luaIndex)
    end
    local cellNodeRefreshFunc = function(groupNode)
        groupNode.nameText.text = groupTableData.name
        groupNode.romanText.text = UIUtils.getRomanNumberText(luaIndex)
        groupNode.completedIcon.gameObject:SetActive(isCompleted)
        groupNode.iconNode.color = isAllCompleted and self.view.config.GROUP_ALL_COMPLETE_COLOR or self.view.config.GROUP_NORMAL_COLOR
        groupNode.completedIcon.color = (not onlyNormal and isAllCompleted) and self.view.config.GROUP_COMPLETED_ICON_RAID_COLOR or self.view.config.GROUP_COMPLETED_ICON_NORMAL_COLOR
    end
    cellNodeRefreshFunc(cell.normal)
    cellNodeRefreshFunc(cell.selected)
end
SettlementDefenseTerminalCtrl._OnGroupSelected = HL.Method(HL.Number) << function(self, luaIndex)
    if luaIndex == self.m_selectedGroupIndex then
        return
    end
    local cell = self.m_groupCells:GetItem(luaIndex)
    local lastCell = self.m_groupCells:GetItem(self.m_selectedGroupIndex)
    if cell == nil and lastCell == nil then
        return
    end
    if cell ~= nil then
        cell.normal.gameObject:SetActive(false)
        cell.selected.gameObject:SetActive(true)
    end
    if lastCell ~= nil then
        lastCell.normal.gameObject:SetActive(true)
        lastCell.selected.gameObject:SetActive(false)
    end
    self.m_selectedGroupIndex = luaIndex
    local groupData = self.m_groupDataList[CSIndex(self.m_selectedGroupIndex)]
    if groupData ~= nil then
        self.view.levelSwitchToggle.gameObject:SetActive(groupData.raidLevel ~= nil)
    end
    self:_RefreshLevelContent(false)
end
SettlementDefenseTerminalCtrl._RefreshLevelContent = HL.Method(HL.Boolean) << function(self, isRaid)
    local groupData = self.m_groupDataList[CSIndex(self.m_selectedGroupIndex)]
    if groupData == nil then
        return
    end
    local levelData = isRaid and groupData.raidLevel or groupData.normalLevel
    if levelData == nil then
        return
    end
    local levelId = levelData.levelId
    local levelSuccess, levelTableData = Tables.towerDefenseTable:TryGetValue(levelId)
    if not levelSuccess then
        return
    end
    local groupId = groupData.groupId
    local groupSuccess, groupTableData = Tables.towerDefenseGroupTable:TryGetValue(groupId)
    if groupSuccess then
        self.view.descText.text = UIUtils.resolveTextStyle(groupTableData.desc)
        if isRaid then
            self.view.extraDescText.text = UIUtils.resolveTextStyle(groupTableData.extraDesc)
            self.view.extraDescNode.gameObject:SetActive(true)
        else
            self.view.extraDescNode.gameObject:SetActive(false)
        end
    end
    local mapSuccess, mapTableData = Tables.towerDefenseMapTable:TryGetValue(self.m_settlementId)
    if mapSuccess then
        self:_RefreshMapContent(mapTableData.mapImage, levelTableData.detailImage)
    end
    self:_RefreshEnemyContent(levelTableData)
    self:_RefreshRewardContent(levelData, levelTableData)
    self.view.buttonLevelDeco.color = isRaid and self.view.config.BUTTON_LEVEL_DECO_RAID_COLOR or self.view.config.BUTTON_LEVEL_DECO_NORMAL_COLOR
    self.m_selectedLevelId = levelId
end
SettlementDefenseTerminalCtrl._RefreshEnemyContent = HL.Method(HL.Userdata) << function(self, levelTableData)
    self.view.enemyDetailBtn.onClick:RemoveAllListeners()
    self.view.enemyDetailBtn.onClick:AddListener(function()
        UIManager:AutoOpen(PanelId.CommonEnemyPopup, { title = Language[ENEMY_DETAIL_TITLE_TEXT_ID], enemyIds = levelTableData.enemyIds, enemyLevels = levelTableData.enemyLevels })
    end)
end
SettlementDefenseTerminalCtrl._RefreshRewardContent = HL.Method(HL.Userdata, HL.Userdata) << function(self, levelData, levelTableData)
    if levelData == nil or levelTableData == nil then
        return
    end
    self.view.rewardDetailButton.onClick:RemoveAllListeners()
    self.view.rewardDetailButton.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.SettlementDefenseRewardsInfo, { isCompleted = levelData.isCompleted, firstRewardId = levelTableData.rewardId, bandwidthReward = levelTableData.rewardBandwidth, battleLimitReward = levelTableData.rewardBattleBuildingLimit })
    end)
    local rewardId = levelTableData.rewardId
    local rewardSuccess, rewardData = Tables.rewardTable:TryGetValue(rewardId)
    if rewardSuccess then
        local rewardItems = rewardData.itemBundles
        local rewardItemDataList = UIUtils.convertRewardItemBundlesToDataList(rewardItems, false)
        self.m_rewardCells:Refresh(MAX_DISPLAY_REWARD_COUNT, function(cell, luaIndex)
            if luaIndex <= #rewardItemDataList then
                local itemData = rewardItemDataList[luaIndex]
                cell:InitItem({ id = itemData.id, count = itemData.count, }, true)
                cell.gameObject.name = itemData.id
                cell.gameObject:SetActive(true)
                cell.view.rewardedCover.gameObject:SetActive(levelData.isCompleted)
            else
                cell.gameObject:SetActive(false)
            end
        end)
    end
    if levelTableData.rewardBandwidth > 0 or levelTableData.rewardBattleBuildingLimit > 0 then
        if levelTableData.rewardBandwidth > 0 then
            self.view.rewardBandwidthCount.text = string.format("+%d", levelTableData.rewardBandwidth)
            self.view.rewardBandwidthCount.gameObject:SetActive(not levelData.isCompleted)
            self.view.rewardedBandwidthIcon.gameObject:SetActive(levelData.isCompleted)
            self.view.bandwidthNode.gameObject:SetActive(true)
        else
            self.view.bandwidthNode.gameObject:SetActive(false)
        end
        if levelTableData.rewardBattleBuildingLimit > 0 then
            self.view.rewardBattleBuildingCount.text = string.format("+%d", levelTableData.rewardBattleBuildingLimit)
            self.view.rewardBattleBuildingCount.gameObject:SetActive(not levelData.isCompleted)
            self.view.rewardedBattleBuildingIcon.gameObject:SetActive(levelData.isCompleted)
            self.view.battleBuildingNode.gameObject:SetActive(true)
        else
            self.view.battleBuildingNode.gameObject:SetActive(false)
        end
        self.view.buildingContent.gameObject:SetActive(true)
    else
        self.view.buildingContent.gameObject:SetActive(false)
    end
end
SettlementDefenseTerminalCtrl._RefreshMapContent = HL.Method(HL.String, HL.String) << function(self, mapImage, detailImage)
    if not string.isEmpty(mapImage) then
        local mapSprite = self:LoadSprite(UIConst.UI_SPRITE_SETTLEMENT_DEFENSE_MAP, mapImage)
        if mapSprite ~= nil then
            self.view.mapImage.sprite = mapSprite
        end
    end
    if not string.isEmpty(detailImage) then
        local detailSprite = self:LoadSprite(UIConst.UI_SPRITE_SETTLEMENT_DEFENSE_DETAIL, detailImage)
        if detailSprite ~= nil then
            self.view.detailImage.sprite = detailSprite
        end
    end
end
HL.Commit(SettlementDefenseTerminalCtrl)