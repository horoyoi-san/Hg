local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.DeathInfo
local PHASE_ID = PhaseId.DeathInfo
DeathInfoCtrl = HL.Class('DeathInfoCtrl', uiCtrl.UICtrl)
DeathInfoCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ALL_CHARACTER_REVIVE] = '_ExitPanel', [MessageConst.ON_DUNGEON_RESTART] = '_ExitPanel', [MessageConst.ON_LEAVE_DUNGEON] = '_ExitPanel', }
local REVIVE_AI_BARK = "bark_battle_defeat"
local NORMAL_REVIVE_BTN_TEXT_KEY = "ui_common_deathinfo_revive"
local DUNGEON_REVIVE_BTN_TEXT_KEY = "ui_dungeon_reward_popup_try_again"
DeathInfoCtrl.ShowDeathInfo = HL.StaticMethod(HL.Any) << function(args)
    if Utils.isInRacingDungeon() then
        return
    end
    if Utils.isInSettlementDefense() then
        return
    end
    CoroutineManager:StartCoroutine(function()
        coroutine.step()
        PhaseManager:OpenPhase(PHASE_ID, args, nil, true)
    end)
end
DeathInfoCtrl.m_countingCo = HL.Field(HL.Thread)
DeathInfoCtrl._FinishCountdownCoroutine = HL.Method() << function(self)
    if self.m_countingCo then
        self.m_countingCo = self:_ClearCoroutine(self.m_countingCo)
    end
end
DeathInfoCtrl._TryShowInDungeonMode = HL.Method(CS.Beyond.Gameplay.DeathInfo).Return(HL.Boolean) << function(self, deathInfo)
    if not deathInfo.dungeonId then
        self.view.exitDungeonBtn.gameObject:SetActive(false)
        self.view.reviveBtnText.text = I18nUtils.GetText(NORMAL_REVIVE_BTN_TEXT_KEY)
        return false
    end
    self.view.reviveBtnText.text = I18nUtils.GetText(DUNGEON_REVIVE_BTN_TEXT_KEY)
    self.view.exitDungeonBtn.gameObject:SetActive(true)
    self.view.exitDungeonBtn.onClick:AddListener(function()
        GameInstance.dungeonManager:LeaveDungeon()
    end)
    local dungeonData = Tables.GameMechanicTable[deathInfo.dungeonId]
    local dungeonCategory = nil
    local dungeonCategoryData = nil
    if dungeonData then
        dungeonCategory = dungeonData.gameCategory
    end
    if dungeonCategory then
        dungeonCategoryData = Tables.GameMechanicCategoryTable[dungeonCategory]
    end
    if dungeonCategoryData and dungeonCategoryData.canReChallengeAfterFail then
        self.view.retryBattleBtn.onClick:AddListener(function()
            GameInstance.dungeonManager:RestartCurDungeon()
        end)
    else
        self.view.retryBattleBtn.gameObject:SetActive(false)
    end
    self.m_countingCo = self:_StartCoroutine(function()
        while true do
            local cntTime = DateTimeUtils.GetCurrentTimestampBySeconds()
            local remainSeconds = math.floor(deathInfo.dungeonLeaveTimestamp - cntTime + 0.5)
            remainSeconds = math.max(remainSeconds, 0)
            self.view.countdownText.text = UIUtils.resolveTextStyle(remainSeconds .. Language.LUA_LEAVE_DUNGEON_TEXT)
            coroutine.wait(1)
            if remainSeconds <= 0 then
                break
            end
        end
    end)
    local _, tipGroupBean = Tables.dungeonDeathTips:TryGetValue(deathInfo.dungeonId)
    if not tipGroupBean then
        return false;
    end
    if not self:_TryRandomShowTwoTips(tipGroupBean.tipContents, -1) then
        return false
    end
    self.view.enemyTipsHeader.gameObject:SetActive(false)
    self.view.commonTipsHeader.gameObject:SetActive(true)
    return true
end
DeathInfoCtrl._TryShowInEnemyMode = HL.Method(CS.Beyond.Gameplay.DeathInfo).Return(HL.Boolean) << function(self, deathInfo)
    if not deathInfo.enemyId or deathInfo.enemyLv < 0 then
        return false
    end
    local _, tipGroupBean = Tables.enemyRelatedDeathTips:TryGetValue(deathInfo.enemyId)
    if not tipGroupBean then
        return false;
    end
    if not self:_TryRandomShowTwoTips(tipGroupBean.tipContents, -1) then
        return false
    end
    local enemyInfo = UIUtils.getEnemyInfoByIdAndLevel(deathInfo.enemyId, deathInfo.enemyLv)
    self.view.enemyTipsHeader.gameObject:SetActive(true)
    self.view.commonTipsHeader.gameObject:SetActive(false)
    self.view.enemyAvatar:LoadSprite(UIConst.UI_SPRITE_MONSTER_ICON_BIG, enemyInfo.templateId)
    self.view.enemyNameText.text = enemyInfo.name
    return true
end
DeathInfoCtrl._TryRandomShowTwoTips = HL.Method(HL.Userdata, HL.Number).Return(HL.Boolean) << function(self, tipGroup, indexOffset)
    if not tipGroup or #tipGroup == 0 then
        return false
    end
    local tipIndex1 = math.random(#tipGroup)
    self.view.tipText01.text = UIUtils.resolveTextStyle(tipGroup[tipIndex1 + indexOffset])
    if #tipGroup == 1 then
        return true
    end
    self.view.tipNode02.gameObject:SetActive(true)
    local tipIndex2 = math.random(#tipGroup - 1)
    if tipIndex2 >= tipIndex1 then
        tipIndex2 = tipIndex2 + 1
    end
    self.view.tipText02.text = UIUtils.resolveTextStyle(tipGroup[tipIndex2 + indexOffset])
    return true
end
DeathInfoCtrl._TryGetRandomTrainingTip = HL.Method(HL.String).Return(HL.String) << function(self, trainingType)
    local trainingTipGroupWrapper = Tables.trainingDeathTips[trainingType]
    if not trainingTipGroupWrapper then
        return nil
    end
    local tipGroup = trainingTipGroupWrapper.tipContents
    if not tipGroup or #tipGroup == 0 then
        return nil
    end
    local tipIndex = CSIndex(math.random(#tipGroup))
    return tipGroup[tipIndex]
end
DeathInfoCtrl._TryShowTrainingTip = HL.Method(HL.Userdata, HL.Userdata, HL.Userdata).Return(HL.Boolean) << function(self, trainingStd, trainingTypeInfo, deathInfo)
    local trainingType = trainingTypeInfo.trainingType
    if not trainingStd[trainingType] or trainingStd[trainingType] <= 0 then
        return false
    end
    local trainingStdOfType = trainingStd[trainingType]
    if not trainingStdOfType or trainingStdOfType <= 0 then
        return false
    end
    local degree = deathInfo[trainingType] / trainingStdOfType
    if degree >= trainingTypeInfo.trainingThresholdFactor then
        return false
    end
    local candidateTip = self:_TryGetRandomTrainingTip(trainingType)
    if not candidateTip then
        return false
    end
    self.view.trainingTips.gameObject:SetActive(true)
    self.view.trainingTipText.text = UIUtils.resolveTextStyle(candidateTip)
    self.view.trainingProgressBarLabel.text = trainingTypeInfo.progressBarLabel
    self.view.trainingProgress.fillAmount = degree
    return true
end
DeathInfoCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    GameInstance.player.guide:OnOpenDeathInfoPanel()
    local deathInfo = unpack(arg)
    self.view.tipNode02.gameObject:SetActive(false)
    if not deathInfo.dungeonId then
        self.view.retryBattleBtn.onClick:AddListener(function()
            GameInstance.gameplayNetwork:SendRevive()
        end)
    end
    self.view.trainingTips.gameObject:SetActive(false)
    local _, trainingStd = Tables.recommendTraining:TryGetValue(deathInfo.enemyLv)
    if trainingStd then
        local checkTypeInOrder = {}
        for _, trainingTypeInfo in pairs(Cfg.Tables.trainingTypeInfoTable) do
            checkTypeInOrder[trainingTypeInfo.priority] = trainingTypeInfo
        end
        for priority = 1, #checkTypeInOrder do
            if self:_TryShowTrainingTip(trainingStd, checkTypeInOrder[priority], deathInfo) then
                break
            end
        end
    end
    if self:_TryShowInDungeonMode(deathInfo) then
        return
    end
    if self:_TryShowInEnemyMode(deathInfo) then
        return
    end
    self:_TryRandomShowTwoTips(Tables.commonDeathTips, 0)
    self.view.enemyTipsHeader.gameObject:SetActive(false)
    self.view.commonTipsHeader.gameObject:SetActive(true)
end
DeathInfoCtrl._ExitPanel = HL.Method(HL.Opt(HL.Any)) << function(self, args)
    if PhaseManager:IsOpen(PHASE_ID) then
        PhaseManager:ExitPhaseFast(PHASE_ID)
        GameAction.PostAIBarkEvent(REVIVE_AI_BARK)
    end
end
DeathInfoCtrl.OnClose = HL.Override() << function(self)
    self:_FinishCountdownCoroutine()
end
HL.Commit(DeathInfoCtrl)