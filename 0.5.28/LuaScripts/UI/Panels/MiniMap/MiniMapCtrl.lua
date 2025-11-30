local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.MiniMap
MiniMapCtrl = HL.Class('MiniMapCtrl', uiCtrl.UICtrl)
MiniMapCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.MIN_MAP_SHOW] = 'ShowMiniMap', [MessageConst.ON_TOGGLE_FAC_TOP_VIEW] = 'UpdateShouldShowEmpty', [MessageConst.ON_SYSTEM_UNLOCK] = 'OnSystemUnlock', [MessageConst.ON_TOGGLE_PHASE_FORBID] = 'UpdateShouldShowEmpty', }
MiniMapCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.bg.onClick:AddListener(function()
        MapUtils.openMap()
    end)
    local mapManager = GameInstance.player.mapManager
    mapManager:UpdateAllFacMarkVisibleState()
    mapManager:UpdateAllFacMarkLineData()
    self:UpdateShouldShowEmpty()
    self.view.levelMapController:InitLevelMapController(MapConst.LEVEL_MAP_CONTROLLER_MODE.FOLLOW_CHARACTER)
end
MiniMapCtrl.OnClose = HL.Override() << function(self)
end
MiniMapCtrl.OnShow = HL.Override() << function(self)
    self:UpdateShouldShowEmpty()
end
MiniMapCtrl.OnSystemUnlock = HL.Method(HL.Table) << function(self, arg)
    self:UpdateShouldShowEmpty()
end
MiniMapCtrl.ShowMiniMap = HL.Method(HL.Table) << function(self, args)
    local isShow = unpack(args)
    self:_RefreshMiniMapShownState(isShow)
end
MiniMapCtrl._RefreshMiniMapShownState = HL.Method(HL.Boolean) << function(self, isShow)
    local isMapUnlocked = Utils.isSystemUnlocked(GEnums.UnlockSystemType.Map)
    self.view.main.gameObject:SetActiveIfNecessary(isMapUnlocked and isShow)
end
MiniMapCtrl.UpdateShouldShowEmpty = HL.Method(HL.Opt(HL.Any)) << function(self, arg)
    local showEmpty = not Utils.isSystemUnlocked(GEnums.UnlockSystemType.Map) or LuaSystemManager.facSystem.inTopView or UIUtils.inDungeon() or PhaseManager:IsPhaseForbidden(PhaseId.Map)
    self.view.contentRoot.gameObject:SetActive(not showEmpty)
    self.view.emptyRoot.gameObject:SetActive(showEmpty)
end
HL.Commit(MiniMapCtrl)