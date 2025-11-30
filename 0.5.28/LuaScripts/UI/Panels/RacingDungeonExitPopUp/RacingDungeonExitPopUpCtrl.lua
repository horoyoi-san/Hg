local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingDungeonExitPopUp
RacingDungeonExitPopUpCtrl = HL.Class('RacingDungeonExitPopUpCtrl', uiCtrl.UICtrl)
RacingDungeonExitPopUpCtrl.s_messages = HL.StaticField(HL.Table) << {}
RacingDungeonExitPopUpCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.cancelButton.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.view.confirmButton.onClick:AddListener(function()
        GameInstance.player.racingDungeonSystem:ReqSettle()
        self:PlayAnimationOutAndClose()
    end)
    local time = GameInstance.player.racingDungeonSystem.racingDungeonTime
    self.view.text1.text = string.format("%02d", math.floor(time / 60))
    self.view.text3.text = string.format("%02d", math.floor(time % 60))
    self.view.number.text = GameInstance.player.racingDungeonSystem.successCount
end
RacingDungeonExitPopUpCtrl.OnClose = HL.Override() << function(self)
end
HL.Commit(RacingDungeonExitPopUpCtrl)