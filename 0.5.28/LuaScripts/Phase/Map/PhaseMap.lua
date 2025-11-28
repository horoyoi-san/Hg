local phaseBase = require_ex('Phase/Core/PhaseBase')
local MapSpaceshipNode = require_ex('UI/Widgets/MapSpaceshipNode')
local PHASE_ID = PhaseId.Map
local MarkType = GEnums.MarkType
PhaseMap = HL.Class('PhaseMap', phaseBase.PhaseBase)
local MAP_PANEL_ID = PanelId.Map
local DETAIL_PANEL_MAP = { [MarkType.TrackingMission] = PanelId.MapMarkDetailMission, [MarkType.DungeonPuzzle] = PanelId.MapMarkDetailDungeon, [MarkType.DungeonResource] = PanelId.MapMarkDetailDungeon, [MarkType.BossRush] = PanelId.MapMarkDetailDungeon, [MarkType.CampFire] = PanelId.MapMarkDetailCampFire, [MarkType.BlackBox] = PanelId.MapMarkDetailBlackBox, [MarkType.DoodadGroup] = PanelId.MapMarkDetailDoodadGroup, [MarkType.EnemySpawner] = PanelId.MapMarkDetailEnemySpawner, [MarkType.MinePointTeam] = PanelId.MapMarkDetailMinePointTeam, [MarkType.Recycler] = PanelId.MapMarkDetailRecycler, [MarkType.AvailableMission] = PanelId.MapMarkDetailAvailableMission, [MarkType.SSRoom] = PanelId.MapMarkDetailSSRoom, [MarkType.SSRoom] = PanelId.MapMarkDetailSSRoom, [MarkType.NpcSSShop] = PanelId.MapMarkDetailSSShop, [MarkType.NpcRacingDungeon] = PanelId.MapMarkDetailRacingDungeon, [MarkType.HUB] = PanelId.MapMarkDetailHub, [MarkType.Settlement] = PanelId.MapMarkDetailSettlement, [MarkType.NpcSSManualCollect] = PanelId.MapMarkDetailDefault, [MarkType.General] = PanelId.MapMarkDetailDefault, [MarkType.FixableRobot] = PanelId.MapMarkDetailDefault, [MarkType.NpcSSTrainingRoom] = PanelId.MapMarkDetailDefault, [MarkType.SSControlCenter] = PanelId.MapMarkDetailDefault, }
local FILTER_PANEL_ID = PanelId.MapMarkFilter
PhaseMap.m_mapPanel = HL.Field(HL.Forward("PhasePanelItem"))
PhaseMap.m_mapPanelShown = HL.Field(HL.Boolean) << false
PhaseMap.m_detailPanel = HL.Field(HL.Forward("PhasePanelItem"))
PhaseMap.m_detailPanelShown = HL.Field(HL.Boolean) << false
PhaseMap.m_detailPanelCloseCallback = HL.Field(HL.Function)
PhaseMap.m_filterPanel = HL.Field(HL.Forward("PhasePanelItem"))
PhaseMap.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_LOADING_PANEL_CLOSED] = { 'OnLoadingPanelClosed', false }, [MessageConst.SHOW_LEVEL_MAP_MARK_DETAIL] = { '_OnShowMarkDetail', true }, [MessageConst.HIDE_LEVEL_MAP_MARK_DETAIL] = { '_OnHideMarkDetail', true }, [MessageConst.SHOW_LEVEL_MAP_FILTER] = { '_OnShowFilter', true }, [MessageConst.HIDE_LEVEL_MAP_FILTER] = { '_OnHideFilter', true }, }
PhaseMap._OnInit = HL.Override() << function(self)
    PhaseMap.Super._OnInit(self)
end
PhaseMap._InitAllPhaseItems = HL.Override() << function(self)
    PhaseMap.Super._InitAllPhaseItems(self)
    self:_InitPhaseMapItems()
end
PhaseMap._InitPhaseMapItems = HL.Method() << function(self)
    self.m_mapPanelShown = true
    self.m_mapPanel = self:CreatePhasePanelItem(MAP_PANEL_ID, self.arg)
end
PhaseMap.PrepareTransition = HL.Override(HL.Number, HL.Boolean, HL.Opt(HL.Number)) << function(self, transitionType, fastMode, anotherPhaseId)
    if transitionType == PhaseConst.EPhaseState.TransitionIn then
        UIManager:PreloadPanelAsset(MAP_PANEL_ID)
    end
end
PhaseMap._DoPhaseTransitionIn = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseMap._DoPhaseTransitionOut = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseMap._DoPhaseTransitionBehind = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseMap._DoPhaseTransitionBackToTop = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseMap._OnActivated = HL.Override() << function(self)
end
PhaseMap._OnDeActivated = HL.Override() << function(self)
end
PhaseMap._OnDestroy = HL.Override() << function(self)
end
PhaseMap._OnRefresh = HL.Override() << function(self)
    if self.m_mapPanel == nil then
        return
    end
    self.m_mapPanel.uiCtrl:ResetMapStateToTargetLevel(self.arg)
end
PhaseMap.OnLoadingPanelClosed = HL.StaticMethod() << function()
    MapSpaceshipNode.ClearStaticFromData()
end
PhaseMap._OnShowMarkDetail = HL.Method(HL.Table) << function(self, args)
    if not self.m_mapPanelShown then
        return
    end
    local markInstId = args.markInstId
    local markSuccess, markData = GameInstance.player.mapManager:GetMarkInstRuntimeData(markInstId)
    if not markSuccess then
        return
    end
    local templateSuccess, templateData = Tables.mapMarkTempTable:TryGetValue(markData.templateId)
    if not templateSuccess then
        return
    end
    local panelId = DETAIL_PANEL_MAP[templateData.markType]
    if panelId == nil then
        panelId = PanelId.MapMarkDetailDefault
    end
    self.m_detailPanelCloseCallback = args.onClosedCallback
    if self.m_detailPanelShown then
        self:RemovePhasePanelItem(self.m_detailPanel)
    end
    self.m_detailPanel = self:CreatePhasePanelItem(panelId, { markInstId = markInstId })
    self.m_detailPanelShown = true
end
PhaseMap._OnHideMarkDetail = HL.Method() << function(self)
    if self.m_detailPanelCloseCallback ~= nil then
        self.m_detailPanelCloseCallback()
    end
    self.m_detailPanel.uiCtrl:PlayAnimationOutWithCallback(function()
        self.m_detailPanelShown = false
        self:RemovePhasePanelItem(self.m_detailPanel)
    end)
end
PhaseMap._OnShowFilter = HL.Method() << function(self)
    self.m_filterPanel = self:CreatePhasePanelItem(FILTER_PANEL_ID)
end
PhaseMap._OnHideFilter = HL.Method() << function(self)
    self.m_filterPanel.uiCtrl:PlayAnimationOutWithCallback(function()
        self:RemovePhasePanelItem(self.m_filterPanel)
    end)
end
HL.Commit(PhaseMap)