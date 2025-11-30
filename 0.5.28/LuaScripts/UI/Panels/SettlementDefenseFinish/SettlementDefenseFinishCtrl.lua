local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementDefenseFinish
local PHASE_ID = PhaseId.SettlementDefenseFinish
SettlementDefenseFinishCtrl = HL.Class('SettlementDefenseFinishCtrl', uiCtrl.UICtrl)
local FINISH_SHOW_DELAY_TIME = 2
local ZERO_HP_TOLERANCE = 0.01
local COMPLETED_TEXT_ID = "ui_fac_settlement_defence_ending_successed"
local FAILED_TEXT_ID = "ui_fac_settlement_defence_ending_failed"
local RETREAT_TEXT_ID = "ui_fac_settlement_defence_ending_interrupted"
local NO_REWARD_STATE_NAME = "NoReward"
SettlementDefenseFinishCtrl.m_coreHpCells = HL.Field(HL.Forward("UIListCache"))
SettlementDefenseFinishCtrl.m_itemCells = HL.Field(HL.Forward("UIListCache"))
SettlementDefenseFinishCtrl.m_itemRewardsValid = HL.Field(HL.Boolean) << false
SettlementDefenseFinishCtrl.m_buildingRewardsValid = HL.Field(HL.Boolean) << false
SettlementDefenseFinishCtrl.m_isConfirmed = HL.Field(HL.Boolean) << false
SettlementDefenseFinishCtrl.s_cachedPhaseArgs = HL.StaticField(HL.Table)
SettlementDefenseFinishCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_LOADING_PANEL_CLOSED] = '_OnLoadingPanelClosed', }
SettlementDefenseFinishCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_coreHpCells = UIUtils.genCellCache(self.view.coreHpCell)
    self.m_itemCells = UIUtils.genCellCache(self.view.itemCell)
    self.m_isConfirmed = false
    self.view.confirmButton.onClick:AddListener(function()
        if self:IsPlayingAnimationIn() then
            return
        end
        if GameInstance.player.squadManager:IsCurSquadAllDead() and not self.m_isConfirmed then
            GameInstance.gameplayNetwork:SendRevive()
            self.m_isConfirmed = true
        end
        PhaseManager:PopPhase(PhaseId.SettlementDefenseFinish, function()
            SettlementDefenseFinishCtrl.s_cachedPhaseArgs = nil
            GameInstance.player.towerDefenseSystem.systemInDefense = false
            Notify(MessageConst.ON_TOWER_DEFENSE_LEVEL_REWARDS_FINISHED)
        end)
    end)
    local rewardPack = GameInstance.player.inventory:ConsumeLatestRewardPackOfType(CS.Beyond.GEnums.RewardSourceType.TD)
    local isPassed = args.finishType == CS.Beyond.Gameplay.Core.TowerDefenseGame.FinishType.Complete
    local isFirstPassed = rewardPack ~= nil and isPassed
    self:_RefreshColorAndText(args.tdId, args.finishType)
    self:_RefreshCoreHps(args.coreHpInfoList)
    self:_RefreshItemRewards(rewardPack)
    self:_RefreshBuildingRewards(args.tdId, isFirstPassed)
    self:_RefreshNoRewardsState(isPassed)
end
SettlementDefenseFinishCtrl.OnTowerDefenseLevelFinished = HL.StaticMethod(HL.Any) << function(args)
    if not Utils.isInSettlementDefenseDefending() then
        return
    end
    if SettlementDefenseFinishCtrl.s_cachedPhaseArgs ~= nil then
        return
    end
    local tdId, finishType = unpack(args)
    local coreHpInfoList = {}
    local towerDefenseGame = GameInstance.player.towerDefenseSystem.towerDefenseGame
    if towerDefenseGame ~= nil then
        local tdCoreAbilitySystems = towerDefenseGame.tdCoreAbilitySystems
        if tdCoreAbilitySystems ~= nil and tdCoreAbilitySystems.Count > 0 then
            for index = 0, tdCoreAbilitySystems.Count - 1 do
                local coreAbilitySystem = tdCoreAbilitySystems[index]
                if coreAbilitySystem ~= nil then
                    table.insert(coreHpInfoList, { hp = coreAbilitySystem.hp, maxHp = coreAbilitySystem.maxHp, })
                end
            end
        end
    end
    SettlementDefenseFinishCtrl.s_cachedPhaseArgs = { tdId = tdId, finishType = finishType, coreHpInfoList = coreHpInfoList, }
end
SettlementDefenseFinishCtrl.OnTowerDefenseLevelCleared = HL.StaticMethod() << function()
    PhaseManager:OpenPhase(PhaseId.SettlementDefenseFinish, SettlementDefenseFinishCtrl.s_cachedPhaseArgs)
end
SettlementDefenseFinishCtrl._OnLoadingPanelClosed = HL.Method() << function(self)
    if PhaseManager:IsOpen(PhaseId.SettlementDefenseFinish) then
        PhaseManager:ExitPhaseFast(PhaseId.SettlementDefenseFinish)
    end
end
SettlementDefenseFinishCtrl._RefreshColorAndText = HL.Method(HL.String, CS.Beyond.Gameplay.Core.TowerDefenseGame.FinishType) << function(self, tdId, finishType)
    local completedColor, failedColor = self.view.config.COMPLETED_COLOR, self.view.config.FAILED_COLOR
    local isPassed = finishType == CS.Beyond.Gameplay.Core.TowerDefenseGame.FinishType.Complete
    local currentColor = isPassed and completedColor or failedColor
    self.view.titleBg.color = currentColor
    local textId
    if isPassed then
        textId = COMPLETED_TEXT_ID
    else
        textId = finishType == CS.Beyond.Gameplay.Core.TowerDefenseGame.FinishType.Quit and RETREAT_TEXT_ID or FAILED_TEXT_ID
    end
    if textId ~= nil then
        self.view.descText.text = Language[textId]
    end
    local tdSuccess, tdData = Tables.towerDefenseTable:TryGetValue(tdId)
    if tdSuccess then
        local tdGroupSuccess, tdGroupData = Tables.towerDefenseGroupTable:TryGetValue(tdData.tdGroup)
        if tdGroupSuccess then
            self.view.nameText.text = tdGroupData.name
        end
    end
    local textColor = isPassed and self.view.config.COMPLETED_TEXT_COLOR or self.view.config.FAILED_TEXT_COLOR
    self.view.descText.color = textColor
    local btnColor = isPassed and self.view.config.COMPLETED_BTN_COLOR or self.view.config.FAILED_BTN_COLOR
    self.view.buttonCanvasGroup.color = btnColor
end
SettlementDefenseFinishCtrl._RefreshCoreHps = HL.Method(HL.Table) << function(self, coreHpInfoList)
    if coreHpInfoList == nil then
        return
    end
    self.m_coreHpCells:Refresh(#coreHpInfoList, function(cell, index)
        local hpInfo = coreHpInfoList[index]
        local amount = hpInfo.hp / hpInfo.maxHp
        cell.indexText.text = string.format("%d", index)
        cell.hpSlider.value = amount
        cell.hpText.text = string.format("%d%%", math.floor(amount * 100))
        if hpInfo.hp - 0.0 <= ZERO_HP_TOLERANCE then
            cell.zeroDeco.gameObject:SetActive(true)
        end
    end)
end
SettlementDefenseFinishCtrl._RefreshItemRewards = HL.Method(HL.Userdata) << function(self, rewardPack)
    self.view.rewardListNode.gameObject:SetActive(false)
    self.view.emptyItemReward.gameObject:SetActive(true)
    self.m_itemRewardsValid = false
    if rewardPack == nil then
        return
    end
    local rewardItems = rewardPack.itemBundleList
    local rewardItemDataList = UIUtils.convertRewardItemBundlesToDataList(rewardItems, false)
    self.m_itemCells:Refresh(rewardItems.Count, function(cell, luaIndex)
        local itemData = rewardItemDataList[luaIndex]
        cell:InitItem({ id = itemData.id, count = itemData.count, }, true)
        cell.gameObject.name = itemData.id
    end)
    self.view.rewardListNode.gameObject:SetActive(true)
    self.view.emptyItemReward.gameObject:SetActive(false)
    self.m_itemRewardsValid = true
end
SettlementDefenseFinishCtrl._RefreshBuildingRewards = HL.Method(HL.String, HL.Boolean) << function(self, tdId, isFirstPassed)
    self.view.buildingRewardContent.gameObject:SetActive(false)
    self.view.emptyBuildingReward.gameObject:SetActive(true)
    self.m_buildingRewardsValid = false
    if not isFirstPassed then
        return
    end
    local tdSuccess, tdData = Tables.towerDefenseTable:TryGetValue(tdId)
    if not tdSuccess then
        return
    end
    if tdData.rewardBandwidth <= 0 and tdData.rewardBattleBuildingLimit <= 0 then
        return
    end
    local sceneHandler = FactoryUtils.getCurSceneHandler()
    if sceneHandler == nil then
        return
    end
    local bandwidth = sceneHandler:GetSettlementBandwidth(tdData.settlementId)
    if tdData.rewardBandwidth > 0 then
        self.view.bandwidthCurrCount.text = string.format("%d", bandwidth.max - tdData.rewardBandwidth)
        self.view.bandwidthRewardCount.text = string.format("%d", bandwidth.max)
        self.view.bandwidthNode.gameObject:SetActive(true)
    else
        self.view.bandwidthNode.gameObject:SetActive(false)
    end
    if tdData.rewardBattleBuildingLimit > 0 then
        self.view.battleBuildingCurrCount.text = string.format("%d", bandwidth.battleMax - tdData.rewardBattleBuildingLimit)
        self.view.battleBuildingRewardCount.text = string.format("%d", bandwidth.battleMax)
        self.view.battleBuildingNode.gameObject:SetActive(true)
    else
        self.view.battleBuildingNode.gameObject:SetActive(false)
    end
    self.view.buildingRewardContent.gameObject:SetActive(true)
    self.view.emptyBuildingReward.gameObject:SetActive(false)
    self.m_buildingRewardsValid = true
end
SettlementDefenseFinishCtrl._RefreshNoRewardsState = HL.Method(HL.Boolean) << function(self, isPassed)
    if not isPassed then
        return
    end
    if self.m_itemRewardsValid then
        return
    end
    if self.m_buildingRewardsValid then
        return
    end
    self.view.mainController:SetState(NO_REWARD_STATE_NAME)
end
HL.Commit(SettlementDefenseFinishCtrl)