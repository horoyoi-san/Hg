local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.AdventureRacingDungeon
AdventureRacingDungeonCtrl = HL.Class('AdventureRacingDungeonCtrl', uiCtrl.UICtrl)
AdventureRacingDungeonCtrl.s_messages = HL.StaticField(HL.Table) << {}
AdventureRacingDungeonCtrl.m_genRewardCells = HL.Field(HL.Forward("UIListCache"))
AdventureRacingDungeonCtrl.m_rewardInfos = HL.Field(HL.Table)
AdventureRacingDungeonCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_genRewardCells = UIUtils.genCellCache(self.view.rewardCell)
    self.view.gotoBtn.onClick:RemoveAllListeners()
    self.view.gotoBtn.onClick:AddListener(AdventureRacingDungeonCtrl.GoToRacingDungeonEntry)
    self:_Init()
end
AdventureRacingDungeonCtrl._Init = HL.Method() << function(self)
    local dungeonId
    local maxScore
    local racingBPTable = Tables.racingBattlePassTable
    for k, v in pairs(racingBPTable) do
        dungeonId = k
        local maxCount = #v.list
        maxScore = v.list[maxCount].exp
    end
    local curScore = GameInstance.player.racingDungeonSystem:GetWeeklyExp(dungeonId)
    local list = Tables.globalConst.adventureRacingDugeonRewards
    self.m_rewardInfos = {}
    for _, rewardId in pairs(list) do
        table.insert(self.m_rewardInfos, { id = rewardId })
    end
    self:_RefreshUITimeTxt()
    self:_RefreshUIScoreTxt(curScore, maxScore)
    self:_InitUIRewardList()
end
AdventureRacingDungeonCtrl._RefreshUITimeTxt = HL.Method() << function(self)
    local targetTime = Utils.getNextWeeklyServerRefreshTime()
    self.view.timeTxt:InitCountDownText(targetTime, function()
        self:_RefreshUITimeTxt()
    end, function(leftTime)
        return string.format(Language.LUA_ADVENTURE_RACING_DUNGEON_COUNT_DOWN_FORMAT, UIUtils.getLeftTime(leftTime))
    end)
end
AdventureRacingDungeonCtrl._RefreshUIScoreTxt = HL.Method(HL.Number, HL.Number) << function(self, curScore, maxScore)
    self.view.curScoreTxt.text = curScore
    self.view.maxScoreTxt.text = string.format(Language.LUA_ADVENTURE_RACING_DUNGEON_MAX_SCORE_FORMAT, maxScore)
end
AdventureRacingDungeonCtrl._InitUIRewardList = HL.Method() << function(self)
    local count = #self.m_rewardInfos
    self.m_genRewardCells:Refresh(count, function(cell, luaIndex)
        self:_RefreshUIRewardList(cell, luaIndex)
    end)
end
AdventureRacingDungeonCtrl._RefreshUIRewardList = HL.Method(HL.Userdata, HL.Number) << function(self, cell, luaIndex)
    local info = self.m_rewardInfos[luaIndex]
    cell:InitItem(info, true)
    cell.view.rewardedCover.gameObject:SetActive(false)
end
AdventureRacingDungeonCtrl.GoToRacingDungeonEntry = HL.StaticMethod() << function()
    PhaseManager:OpenPhase(PhaseId.RacingDungeonEntry)
end
HL.Commit(AdventureRacingDungeonCtrl)