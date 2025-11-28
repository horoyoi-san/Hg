local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingDungeonEntry
local PHASE_ID = PhaseId.RacingDungeonEntry
RacingDungeonEntryCtrl = HL.Class('RacingDungeonEntryCtrl', uiCtrl.UICtrl)
RacingDungeonEntryCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_RACING_DUNGEON_GET_WEEKLY_REWARD] = 'OnUpdate', [MessageConst.ON_RACING_DUNGEON_GET_ACHIEVE_REWARD] = 'OnUpdate', }
RacingDungeonEntryCtrl.m_haveHide = HL.Field(HL.Boolean) << false
RacingDungeonEntryCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.challengeButton.onClick:AddListener(function()
        UIManager:Open(PanelId.RacingDungeonWeeklyReward)
    end)
    local dungeon = nil
    local t = Tables.racingDungeonTable
    for k, v in pairs(t) do
        dungeon = k
    end
    self.view.rewardButton.onClick:AddListener(function()
        UIManager:Open(PanelId.RacingDungeonAchieveReward, { dungeon = dungeon })
        self.view.animationWrapper:SampleToInAnimationEnd()
    end)
    self.view.btnClose.onClick:AddListener(function()
        local isOpen, phase = PhaseManager:IsOpen(PhaseId.Dialog)
        if isOpen then
            self:Notify(MessageConst.DIALOG_CLOSE_UI, { PANEL_ID, PHASE_ID, 1 })
        else
            PhaseManager:PopPhase(PHASE_ID)
        end
    end)
    self.view.startButton.onClick:AddListener(function()
        UIManager:Open(PanelId.RacingDungeonDifficultySelection)
        self.view.animationWrapper:SampleToInAnimationEnd()
    end)
    self.view.btnDetails.onClick:AddListener(function()
        UIManager:Open(PanelId.RacingDungeonEntryPop)
    end)
    GameInstance.player.racingDungeonSystem:ReqRacingDungeonRewardInfo()
end
RacingDungeonEntryCtrl.OnUpdate = HL.Method(HL.Any) << function(self, arg)
    self:OnShow()
end
RacingDungeonEntryCtrl.OnShow = HL.Override() << function(self)
    self.view.challengeReddot.gameObject:SetActive(RedDotManager:GetRedDotState("RacingWeeklyEntry"))
    self.view.rewardReddot.gameObject:SetActive(RedDotManager:GetRedDotState("RacingDungeonAchieveEntry"))
    if self.m_haveHide then
        self.view.animationWrapper:SampleToInAnimationEnd()
    end
end
RacingDungeonEntryCtrl.OnHide = HL.Override() << function(self)
    self.m_haveHide = true
end
RacingDungeonEntryCtrl.OnClose = HL.Override() << function(self)
    local achievePanel = UIManager:IsOpen(PanelId.RacingDungeonAchieveReward)
    if achievePanel then
        UIManager:Close(PanelId.RacingDungeonAchieveReward)
    end
    local weeklyPanel = UIManager:IsOpen(PanelId.RacingDungeonWeeklyReward)
    if weeklyPanel then
        UIManager:Close(PanelId.RacingDungeonWeeklyReward)
    end
    local difficultyPanel = UIManager:IsOpen(PanelId.RacingDungeonDifficultySelection)
    if difficultyPanel then
        UIManager:Close(PanelId.RacingDungeonDifficultySelection)
    end
end
HL.Commit(RacingDungeonEntryCtrl)