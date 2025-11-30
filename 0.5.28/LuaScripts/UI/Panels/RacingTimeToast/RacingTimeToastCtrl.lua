local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingTimeToast
RacingTimeToastCtrl = HL.Class('RacingTimeToastCtrl', uiCtrl.UICtrl)
RacingTimeToastCtrl.m_racingDungeonSystem = HL.Field(HL.Any)
RacingTimeToastCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_RACING_DUNEGON_PAUSE] = 'OnPauseChange', }
RacingTimeToastCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_racingDungeonSystem = GameInstance.player.racingDungeonSystem
    self.view.time.text = UIUtils.getLeftTimeToSecondMS(self.m_racingDungeonSystem.racingDungeonTime)
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.COMMON_UI_TIME_UPDATE_INTERVAL)
            self.view.time.text = UIUtils.getLeftTimeToSecondMS(self.m_racingDungeonSystem.racingDungeonTime)
        end
    end)
    self:BindInputPlayerAction("common_esc_exit", function()
        UIManager:Open(PanelId.RacingDungeonExitPopUp)
    end)
    self:BindInputPlayerAction("common_dungeon_info", function()
        UIManager:Open(PanelId.RacingDungeonEntryPop)
    end)
    self:BindInputPlayerAction("fac_open_hub_panel", function()
        PhaseManager:OpenPhase(PhaseId.RacingDungeonEffect)
    end)
    AudioAdapter.PostEvent("Au_UI_Event_RacingDungeon_Timing")
end
RacingTimeToastCtrl.OnPauseChange = HL.Method(HL.Any) << function(self, pause)
    if type(pause) == "table" then
        pause = unpack(pause)
    end
    if pause then
        self.view.stop:Play("racingtimetoast_stop_in")
    else
        self.view.stop:Play("racingtimetoast_stop_out")
    end
end
HL.Commit(RacingTimeToastCtrl)