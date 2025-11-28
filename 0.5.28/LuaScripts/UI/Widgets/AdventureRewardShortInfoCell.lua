local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
AdventureRewardShortInfoCell = HL.Class('AdventureRewardShortInfoCell', UIWidgetBase)
AdventureRewardShortInfoCell.m_rewardInfo = HL.Field(HL.Table)
AdventureRewardShortInfoCell.m_luaIndex = HL.Field(HL.Number) << -1
AdventureRewardShortInfoCell.m_onClickFunc = HL.Field(HL.Function)
AdventureRewardShortInfoCell._OnFirstTimeInit = HL.Override() << function(self)
    self:RegisterMessage(MessageConst.ON_ADVENTURE_REWARD_RECEIVE, function()
        self:_UpdateInfo()
    end)
    self.view.button.onClick:AddListener(function()
        if self.m_onClickFunc then
            self.m_onClickFunc(self.m_luaIndex)
        end
    end)
end
AdventureRewardShortInfoCell.InitAdventureRewardShortInfoCell = HL.Method(HL.Table, HL.Number, HL.Function) << function(self, info, luaIndex, onClickFunction)
    self:_FirstTimeInit()
    self.m_rewardInfo = info
    self.m_luaIndex = luaIndex
    self.m_onClickFunc = onClickFunction
    self.view.levelTxtRcv.text = info.level
    self.view.levelTxtUrcv.text = info.level
    self.view.levelTxtUr.text = info.level
    self:_UpdateInfo()
end
AdventureRewardShortInfoCell._UpdateInfo = HL.Method() << function(self)
    local adventure = GameInstance.player.adventure
    local reach = adventure.adventureLevelData.lv >= self.m_rewardInfo.level
    local receive = adventure:IsAdventureLevelRewardReceived(self.m_rewardInfo.level)
    self.view.received.gameObject:SetActiveIfNecessary(receive)
    self.view.unreceived.gameObject:SetActiveIfNecessary(reach and not receive)
    self.view.unreached.gameObject:SetActiveIfNecessary(not reach)
end
HL.Commit(AdventureRewardShortInfoCell)
return AdventureRewardShortInfoCell