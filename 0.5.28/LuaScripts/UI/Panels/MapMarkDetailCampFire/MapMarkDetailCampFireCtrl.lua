local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.MapMarkDetailCampFire
MapMarkDetailCampFireCtrl = HL.Class('MapMarkDetailCampFireCtrl', uiCtrl.UICtrl)
MapMarkDetailCampFireCtrl.s_messages = HL.StaticField(HL.Table) << {}
MapMarkDetailCampFireCtrl.m_sceneId = HL.Field(HL.String) << ""
MapMarkDetailCampFireCtrl.m_logicIdGlobal = HL.Field(HL.Any)
MapMarkDetailCampFireCtrl.m_markInstId = HL.Field(HL.Any)
MapMarkDetailCampFireCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_markInstId = args.markInstId
    local getRuntimeDataSuccess, markRuntimeData = GameInstance.player.mapManager:GetMarkInstRuntimeData(self.m_markInstId)
    if getRuntimeDataSuccess == false then
        logger.LogError("地图详情页获取实例数据失败" .. self.m_instId)
        return
    end
    self.m_sceneId = markRuntimeData.detail.levelId
    self.m_logicIdGlobal = markRuntimeData.detail.logicIdGlobal
    local forbidMapTp = GameInstance.playerController.forbidMapTeleport
    local isActive = markRuntimeData.isActive
    local commonArgs = {}
    commonArgs.markInstId = self.m_markInstId
    if not isActive then
        self.view.inactiveTips.gameObject:SetActive(true)
        commonArgs.bigBtnActive = true
    else
        if not forbidMapTp then
            commonArgs.bigBtnActive = true
            commonArgs.bigBtnText = Language["ui_mapmarkdetail_button_teleport"]
            commonArgs.bigBtnIconName = UIConst.MAP_DETAIL_BTN_ICON_NAME.TELEPORT
            commonArgs.bigBtnCallback = function()
                self:_Teleport()
            end
        else
            self.view.forbidTeleportTips.gameObject:SetActive(true)
        end
    end
    self.view.detailCommon:InitMapMarkDetailCommon(commonArgs)
end
MapMarkDetailCampFireCtrl._Teleport = HL.Method() << function(self)
    Utils.teleportToEntityWithCallback(self.m_sceneId, self.m_logicIdGlobal, function()
        GameAction.SaveCheckpointToCampfire(self.m_logicIdGlobal)
        GameInstance.gameplayNetwork:RestAtCampfire()
    end)
end
HL.Commit(MapMarkDetailCampFireCtrl)