local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacTechPointGainedToast
FacTechPointGainedToastCtrl = HL.Class('FacTechPointGainedToastCtrl', uiCtrl.UICtrl)
FacTechPointGainedToastCtrl.m_toastTimerId = HL.Field(HL.Number) << -1
FacTechPointGainedToastCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.INTERRUPT_MAIN_HUD_TOAST] = 'InterruptMainHudToast', }
FacTechPointGainedToastCtrl.OnFacTechPointGained = HL.StaticMethod() << function(arg)
    local delayTime = 3
    TimerManager:StartTimer(delayTime, function()
        local ctrl = UIManager:AutoOpen(PANEL_ID)
        ctrl:StartToast(arg)
    end)
end
FacTechPointGainedToastCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
end
FacTechPointGainedToastCtrl.StartToast = HL.Method(HL.Any) << function(self, arg)
    local dungeonSeriesId = unpack(arg)
    local dungeonSeriesCfg = Tables.dungeonSeriesTable[dungeonSeriesId]
    local dungeonId = dungeonSeriesCfg.includeDungeonIds[0]
    local dungeonCfg = Tables.dungeonTable[dungeonId]
    local activateRewardId = dungeonSeriesCfg.activateRewardId
    local rewardCfg = Tables.rewardTable[activateRewardId]
    local costPointItemId = rewardCfg.itemBundles[0].id
    local costItemCfg = Tables.itemTable[costPointItemId]
    local gainedCount = rewardCfg.itemBundles[0].count
    local activateText = string.format(Language.LUA_BLACKBOX_ACTIVE_TOAST_FORMAT, dungeonCfg.dungeonName)
    local pointName = costItemCfg.name
    local ownCostPoint = Utils.getItemCount(costPointItemId)
    self.view.activateTxt.text = UIUtils.resolveTextStyle(activateText)
    self.view.pointNameTxt.text = pointName
    self.view.increasePointsTxt.text = string.format(Language.LUA_FAC_TECH_POINT_GAINED_NUMBER_FORMAT, gainedCount)
    self.view.previewPointTxt.text = ownCostPoint - gainedCount
    self.view.curPointTxt.text = ownCostPoint
    local wrapper = self:GetAnimationWrapper()
    wrapper:Play("factechpoint_gained", function()
        self:PlayAnimationOut()
    end)
    AudioAdapter.PostEvent("Au_UI_Toast_FacTechPointGainedToastPanel_Open")
end
FacTechPointGainedToastCtrl.InterruptMainHudToast = HL.Method() << function(self)
end
HL.Commit(FacTechPointGainedToastCtrl)