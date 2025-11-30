local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.DungeonCharTimeHint
DungeonCharTimeHintCtrl = HL.Class('DungeonCharTimeHintCtrl', uiCtrl.UICtrl)
DungeonCharTimeHintCtrl.s_messages = HL.StaticField(HL.Table) << {}
DungeonCharTimeHintCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local leaveTimestamp = arg.leaveTimestamp
    local endFunc = arg.endFunc
    self:_StartCoroutine(function()
        local realLeaveTimestamp = leaveTimestamp
        while true do
            coroutine.step()
            local currentTS = CS.Beyond.DateTimeUtils.GetCurrentTimestampBySeconds()
            local leftTime = math.max(realLeaveTimestamp - currentTS, 0)
            self.view.timeTxt.text = string.format(Language["ui_dungeon_settlement_popup_countdown"], leftTime)
            if currentTS - realLeaveTimestamp >= 0 then
                break
            end
        end
        if endFunc then
            endFunc()
        end
    end)
end
HL.Commit(DungeonCharTimeHintCtrl)