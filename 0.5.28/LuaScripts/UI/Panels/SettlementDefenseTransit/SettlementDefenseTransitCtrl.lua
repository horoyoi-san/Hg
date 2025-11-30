local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementDefenseTransit
SettlementDefenseTransitCtrl = HL.Class('SettlementDefenseTransitCtrl', uiCtrl.UICtrl)
SettlementDefenseTransitCtrl.m_time = HL.Field(HL.Number) << 0
SettlementDefenseTransitCtrl.m_timeUpdateTick = HL.Field(HL.Number) << -1
SettlementDefenseTransitCtrl.m_playFinished = HL.Field(HL.Boolean) << false
SettlementDefenseTransitCtrl.m_defendingReady = HL.Field(HL.Boolean) << false
SettlementDefenseTransitCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_TOWER_DEFENSE_DEFENDING_READY] = '_OnTowerDefenseDefendingReady', }
SettlementDefenseTransitCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_time = 0
    self.m_timeUpdateTick = LuaUpdate:Add("Tick", function(deltaTime)
        self.m_time = self.m_time + deltaTime
        if self.m_time >= self.view.config.MIN_PLAY_DURATION then
            self.m_playFinished = true
            self.m_defendingReady = GameInstance.player.towerDefenseSystem.towerDefenseGame.defendingReady
            self.m_timeUpdateTick = LuaUpdate:Remove(self.m_timeUpdateTick)
            self:_TryPopPhase()
        end
    end)
end
SettlementDefenseTransitCtrl.OnEnterTowerDefenseDefendingPhase = HL.StaticMethod() << function()
    PhaseManager:OpenPhaseFast(PhaseId.SettlementDefenseTransit)
end
SettlementDefenseTransitCtrl._OnTowerDefenseDefendingReady = HL.Method() << function(self)
    self.m_defendingReady = true
    self:_TryPopPhase()
end
SettlementDefenseTransitCtrl._TryPopPhase = HL.Method() << function(self)
    if not self.m_playFinished then
        return
    end
    if not self.m_defendingReady then
        return
    end
    PhaseManager:PopPhase(PhaseId.SettlementDefenseTransit, function()
        Notify(MessageConst.ON_TOWER_DEFENSE_TRANSIT_FINISHED)
    end)
end
HL.Commit(SettlementDefenseTransitCtrl)