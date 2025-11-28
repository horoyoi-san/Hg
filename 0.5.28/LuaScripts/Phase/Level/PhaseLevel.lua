local battleOnlyPanels = { PanelId.BattleBottomScreenEffect, PanelId.BattleAction, PanelId.SquadIcon, PanelId.OutOfScreenTargets, PanelId.BattleBossInfo, PanelId.BattleComboSkill, PanelId.BattleComboSkillUse, PanelId.BattleDamageText, }
local factoryOnlyPanels = { PanelId.FacHudBottomMask, PanelId.FacMain, PanelId.FacMainLeft, PanelId.FacMainRight, }
local phaseBase = require_ex('Phase/Core/PhaseBase')
local PHASE_ID = PhaseId.Level
PhaseLevel = HL.Class('PhaseLevel', phaseBase.PhaseBase)
PhaseLevel.s_messages = HL.StaticField(HL.Table) << { [MessageConst.OPEN_LEVEL_PHASE] = { 'OnOpenLevelPhase', false }, [MessageConst.ON_SCENE_LOAD_START] = { 'onSceneLoadStart', true }, [MessageConst.UPDATE_GENERAL_TRACKER] = { 'UpdateGeneralTracker', true }, [MessageConst.ENTER_FACTORY_MODE] = { 'EnterFactoryMode', true }, [MessageConst.EXIT_FACTORY_MODE] = { 'ExitFactoryMode', true }, [MessageConst.ON_SQUAD_INFIGHT_CHANGED] = { 'OnSquadInfightChanged', true }, [MessageConst.FORCE_SET_FAC_MODE] = { 'ForceSetFacMode', true }, [MessageConst.ON_EXIT_TRAVEL_MODE] = { 'OnExitTravelMode', true }, [MessageConst.SET_PHASE_LEVEL_TRANSITION_RESERVE_PANELS] = { 'SetPhaseLevelTransitionReservePanels', true }, [MessageConst.RECOVER_PHASE_LEVEL] = { 'RecoverPhaseLevel', true }, [MessageConst.ON_OPEN_SUB_GAME_TRACKINGS] = { 'OnOpenSubGameTrackings', true }, [MessageConst.ON_CLOSE_SUB_GAME_TRACKINGS] = { 'OnCloseSubGameTrack', true }, [MessageConst.ON_OPEN_SCRIPT_CUSTOM_TASK_TRACKING] = { 'OnOpenLevelScriptCustomTask', true }, [MessageConst.ON_CLOSE_SCRIPT_CUSTOM_TASK_TRACKING] = { 'OnCloseLevelScriptCustomTask', true }, [MessageConst.ON_DEACTIVATE_COMMON_TASK_TRACK_HUD] = { 'OnDeactivateCommonTaskTrackHud', true }, [MessageConst.ON_ENTER_TOWER_DEFENSE_PREPARING_PHASE] = { 'OnEnterTowerDefensePreparingPhase', true }, [MessageConst.ON_LEAVE_TOWER_DEFENSE_PREPARING_PHASE] = { 'OnLeaveTowerDefensePreparingPhase', true }, [MessageConst.ON_ENTER_TOWER_DEFENSE_DEFENDING_PHASE] = { 'OnEnterTowerDefenseDefendingPhase', true }, [MessageConst.ON_TOWER_DEFENSE_TRANSIT_FINISHED] = { 'OnTowerDefenseDefendingTransitFinished', true }, [MessageConst.ON_LEAVE_TOWER_DEFENSE_DEFENDING_PHASE] = { 'OnLeaveTowerDefenseDefendingPhase', true }, [MessageConst.ON_TOWER_DEFENSE_LEVEL_REWARDS_FINISHED] = { 'OnTowerDefenseDefendingRewardsFinished', true }, [MessageConst.GAME_MODE_ENABLE] = { 'OnGameModeEnable', true }, [MessageConst.SET_FAC_TOP_VIEW_CUSTOM_RANGE] = { 'SetFacTopViewCustomRange', true }, [MessageConst.FAC_ON_MODIFY_CHAPTER_SCENE] = { 'ForceUpdateMainRegionInfo', true }, [MessageConst.ON_RESET_BLACKBOX] = { 'OnResetBlackbox', true }, [MessageConst.FORBID_SYSTEM_CHANGED] = { 'OnForbidSystemChanged', true }, }
PhaseLevel.OnOpenLevelPhase = HL.StaticMethod() << function()
    if not PhaseManager:IsOpen(PHASE_ID) then
        PhaseManager:OpenPhase(PHASE_ID)
    end
end
PhaseLevel.m_updateKey = HL.Field(HL.Number) << -1
PhaseLevel.m_headLabelCtrl = HL.Field(HL.Forward("HeadLabelCtrl"))
PhaseLevel.m_missionTrackerPanel = HL.Field(HL.Forward("PhasePanelItem"))
PhaseLevel.m_generalTrackerPanel = HL.Field(HL.Forward("PhasePanelItem"))
PhaseLevel.m_loaded = HL.Field(HL.Boolean) << false
PhaseLevel._OnInit = HL.Override() << function(self)
    PhaseLevel.Super._OnInit(self)
    self:_InitInMainHudMessageList()
end
PhaseLevel.onSceneLoadStart = HL.Method(HL.Any) << function(self, arg)
end
PhaseLevel.LoadLevelPanels = HL.Method() << function(self)
    UIManager:Open(PanelId.LevelCamera)
    UIManager:Open(PanelId.MiniMap)
    UIManager:Open(PanelId.MainHud)
    UIManager:Open(PanelId.Joystick)
    UIManager:AutoOpen(PanelId.CommonItemToast)
    UIManager:Open(PanelId.SettlemenReportTips)
    UIManager:Open(PanelId.InteractOption)
    UIManager:Open(PanelId.FacBuildingInteract)
    UIManager:Open(PanelId.HeadBar)
    UIManager:Open(PanelId.BattleDamageText)
    UIManager:AutoOpen(PanelId.CommonNewToast)
    UIManager:Open(PanelId.GeneralAbility)
    UIManager:PreloadPanelAsset(PanelId.FacQuickBar)
    UIManager:PreloadPanelAsset(PanelId.FacMiniPowerHud)
    UIManager:PreloadPanelAsset(PanelId.WalletBar)
    UIManager:PreloadPanelAsset(PanelId.ControllerHint)
    if Utils.needMissionHud() then
        UIManager:Open(PanelId.MissionHud)
    end
    if Utils.isInRpgDungeon() then
        UIManager:Open(PanelId.RpgDungeonMainHud)
    end
    self.m_generalTrackerPanel = self:CreatePhasePanelItem(PanelId.GeneralTracker)
    self.m_headLabelCtrl = UIManager:AutoOpen(PanelId.HeadLabel)
    self:_UpdateFactoryMode(true)
    LuaSystemManager.loginCheckSystem:PerformLoginCheck()
    self:OnGameModeEnable({ GameInstance.mode.modeType, GameInstance.mode })
    self.m_loaded = true
end
local BlackBoxGuideNeedClosePanel = { PanelId.DungeonInfoPopup, PanelId.BlackBoxTargetAndReward, PanelId.CommonPopUp, PanelId.FacUnloaderSelect, }
PhaseLevel.RecoverPhaseLevel = HL.Method() << function(self)
    if PhaseManager:GetTopPhaseId() ~= PHASE_ID then
        PhaseManager:ExitPhaseFastTo(PhaseId.Level, true)
    end
    for _, panelId in pairs(BlackBoxGuideNeedClosePanel) do
        if UIManager:IsOpen(panelId) then
            UIManager:Close(panelId)
        end
    end
end
PhaseLevel.m_lastLevelIdNum = HL.Field(HL.Number) << -1
PhaseLevel.m_lastInFacMainRegion = HL.Field(HL.Boolean) << false
PhaseLevel.mainRegionPanelIndex = HL.Field(HL.Number) << -1
PhaseLevel.mainRegionLocalRect = HL.Field(CS.UnityEngine.Rect)
PhaseLevel.mainRegionLocalRectWithMovePadding = HL.Field(CS.UnityEngine.Rect)
PhaseLevel.customFacTopViewRangeInWorld = HL.Field(CS.UnityEngine.Rect)
PhaseLevel.SetFacTopViewCustomRange = HL.Method(HL.Table) << function(self, args)
    local customRangeRect = args[1]
    if customRangeRect.width == 0 or customRangeRect.height == 0 then
        self.customFacTopViewRangeInWorld = nil
        return
    end
    self.customFacTopViewRangeInWorld = customRangeRect
end
PhaseLevel.ForceUpdateMainRegionInfo = HL.Method() << function(self)
    logger.info("PhaseLevel.ForceUpdateMainRegionInfo")
    local inMainRegion, panelIndex = Utils.isInFacMainRegionAndGetIndex()
    self:_UpdateCurMainRegionInfo(panelIndex)
end
PhaseLevel.OnExitTravelMode = HL.Method() << function(self)
    local inMainRegion, panelIndex = Utils.isInFacMainRegionAndGetIndex()
    self:_UpdateCurMainRegionInfo(panelIndex)
    self:_TryAutoToggleFacMode(inMainRegion)
end
PhaseLevel.m_enterFacMainRegionCamState = HL.Field(HL.Any)
PhaseLevel.m_waitInitFacMode = HL.Field(HL.Boolean) << true
PhaseLevel._UpdateFactoryMode = HL.Method(HL.Opt(HL.Boolean)) << function(self, isInit)
    local inMainRegion, panelIndex = Utils.isInFacMainRegionAndGetIndex()
    local curLevelIdNum = GameInstance.world.curLevelIdNum
    if isInit then
        self.m_waitInitFacMode = false
        self:_UpdateCurMainRegionInfo(panelIndex)
        local enterFactoryModeOnSceneLoaded = false
        local bData = GameInstance.world.curLevel.levelData.blackbox
        if bData then
            enterFactoryModeOnSceneLoaded = bData.basic.enterFactoryModeOnSceneLoaded
        end
        self:_ToggleFactoryMode(inMainRegion or enterFactoryModeOnSceneLoaded, true)
        self.m_lastLevelIdNum = curLevelIdNum
        self.m_lastInFacMainRegion = inMainRegion
        UIManager:AutoOpen(PanelId.FacMiniPowerHud)
        if inMainRegion then
            Notify(MessageConst.ON_ENTER_FAC_MAIN_REGION, panelIndex)
            Notify(MessageConst.ON_IN_FAC_MAIN_REGION_CHANGE, inMainRegion)
            GameAction.SetInSafeZone(0, true)
            self.m_enterFacMainRegionCamState = FactoryUtils.enterFacCamera(FacConst.MAIN_REGION_CAM_STATE)
        else
            Notify(MessageConst.ON_EXIT_FAC_MAIN_REGION)
            UIManager:Hide(PanelId.FacMiniPowerHud)
        end
        local otherPanels = GameInstance.world.inFactoryMode and battleOnlyPanels or factoryOnlyPanels
        for _, panelId in pairs(otherPanels) do
            UIManager:PreloadPanelAsset(panelId)
        end
        UIManager:PreloadPanelAsset(PanelId.FacMachineCrafter)
        return
    end
    if self.m_waitInitFacMode then
        return
    end
    self:_UpdatePlayerPosFacInfo()
    if self.m_lastInFacMainRegion ~= inMainRegion or self.mainRegionPanelIndex ~= panelIndex or self.m_lastLevelIdNum ~= curLevelIdNum then
        self.m_lastLevelIdNum = curLevelIdNum
        self.m_lastInFacMainRegion = inMainRegion
        self:_UpdateCurMainRegionInfo(panelIndex)
        if not GameInstance.world.gameMechManager.travelPoleBrain.inFastTravelMode and not Utils.isSwitchModeDisabled() then
            self:_TryAutoToggleFacMode(inMainRegion)
        end
        if inMainRegion then
            Notify(MessageConst.ON_ENTER_FAC_MAIN_REGION, panelIndex)
            if not self.m_enterFacMainRegionCamState then
                self.m_enterFacMainRegionCamState = FactoryUtils.enterFacCamera(FacConst.MAIN_REGION_CAM_STATE)
            end
        else
            Notify(MessageConst.ON_EXIT_FAC_MAIN_REGION)
            if self.m_enterFacMainRegionCamState then
                self.m_enterFacMainRegionCamState = FactoryUtils.exitFacCamera(self.m_enterFacMainRegionCamState)
            end
        end
        GameAction.SetInSafeZone(0, inMainRegion)
        Notify(MessageConst.ON_IN_FAC_MAIN_REGION_CHANGE, inMainRegion)
    end
end
PhaseLevel._UpdateCurMainRegionInfo = HL.Method(HL.Opt(HL.Number)) << function(self, panelIndex)
    if panelIndex and panelIndex >= 0 then
        self.mainRegionPanelIndex = panelIndex
        self.mainRegionLocalRect = GameInstance.remoteFactoryManager:GetMainRegionLocalRect(panelIndex, 0)
        local padding = Vector2(FacConst.FAC_TOP_VIEW_MOVE_PADDING, FacConst.FAC_TOP_VIEW_MOVE_PADDING)
        self.mainRegionLocalRectWithMovePadding = Unity.Rect(self.mainRegionLocalRect.min + padding, self.mainRegionLocalRect.size - padding * 2)
    else
        self.mainRegionPanelIndex = -1
        self.mainRegionLocalRect = nil
        self.mainRegionLocalRectWithMovePadding = nil
    end
end
PhaseLevel._TryAutoToggleFacMode = HL.Method(HL.Boolean) << function(self, inMainRegion)
    if inMainRegion then
        if FactoryUtils.canPlayerEnterFacMode() then
            if not GameInstance.world.inFactoryMode then
                self:_ToggleFactoryMode(true)
            end
        end
    else
        if GameInstance.world.inFactoryMode and not GameInstance.world.gameMechManager.linkWireBrain.isLinking and not FactoryUtils.isInBuildMode() then
            self:_ToggleFactoryMode(false)
        end
    end
end
PhaseLevel._ToggleFactoryMode = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, toFactoryMode, noToast)
    Notify(MessageConst.FAC_EXIT_DESTROY_MODE, true)
    if toFactoryMode then
        local inFight = Utils.isInFight()
        if inFight then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_SWITCH_MODE_FAIL_WHEN_FIGHT)
            return
        end
        if Utils.isInThrowMode() then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_SWITCH_MODE_FAIL_WHEN_THROW)
            return
        end
    end
    local hidePanels = toFactoryMode and battleOnlyPanels or factoryOnlyPanels
    for _, panelId in pairs(hidePanels) do
        UIManager:Hide(panelId)
    end
    GameInstance.world.inFactoryMode = toFactoryMode
    if not toFactoryMode then
        Notify(MessageConst.ON_EXIT_FACTORY_MODE)
    end
    local showPanels = toFactoryMode and factoryOnlyPanels or battleOnlyPanels
    for _, panelId in pairs(showPanels) do
        UIManager:AutoOpen(panelId)
    end
    if toFactoryMode then
        Notify(MessageConst.ON_ENTER_FACTORY_MODE)
    end
    Notify(MessageConst.ON_FAC_MODE_CHANGE, toFactoryMode)
    if not noToast then
        AudioAdapter.PostEvent(toFactoryMode and "au_ui_fac_mode_on" or "au_ui_fac_mode_off")
    end
    EventLogManagerInst:SetGameEventCommonData_CFactoryMode(toFactoryMode)
    EventLogManagerInst:GameEvent_FactoryModeSwitch(toFactoryMode)
    CS.Beyond.Gameplay.Conditions.CheckIsInFactoryMode.Trigger(toFactoryMode)
end
PhaseLevel.EnterFactoryMode = HL.Method() << function(self)
    self:_ToggleFactoryMode(true)
end
PhaseLevel.ExitFactoryMode = HL.Method() << function(self)
    self:_ToggleFactoryMode(false)
end
PhaseLevel.ForceSetFacMode = HL.Method(HL.Table) << function(self, arg)
    local toFacMode = unpack(arg)
    if GameInstance.world.inFactoryMode == toFacMode then
        return
    end
    self:_ToggleFactoryMode(toFacMode)
end
PhaseLevel.OnSquadInfightChanged = HL.Method(HL.Opt(HL.Any)) << function(self)
    local inFight = Utils.isInFight()
    if not inFight then
        return
    end
    if GameInstance.world.inFactoryMode then
        self:_ToggleFactoryMode(false)
    end
end
PhaseLevel.isPlayerOutOfRangeManual = HL.Field(HL.Boolean) << false
PhaseLevel._UpdatePlayerPosFacInfo = HL.Method() << function(self)
    local succ, outOfRangeManual = GameInstance.remoteFactoryManager:TrySampleCurrentSceneGridStatusWithPlayerPosition()
    if succ then
        if outOfRangeManual ~= self.isPlayerOutOfRangeManual then
            self.isPlayerOutOfRangeManual = outOfRangeManual
            local disableSwitchMode = GameInstance.player.forbidSystem:IsForbidden(ForbidType.DisableSwitchMode)
            if outOfRangeManual and not disableSwitchMode then
                if FactoryUtils.isInBuildMode() then
                    Notify(MessageConst.FAC_BUILD_EXIT_CUR_MODE, true)
                end
                self:_ToggleFactoryMode(false, true)
            end
            Notify(MessageConst.FAC_ON_PLAYER_POS_INFO_CHANGED)
        end
    end
end
PhaseLevel._AddRegisters = HL.Method() << function(self)
    self.m_updateKey = LuaUpdate:Add("Tick", function()
        self:_Update()
    end, true)
end
PhaseLevel._ClearRegisters = HL.Method() << function(self)
    self.m_updateKey = LuaUpdate:Remove(self.m_updateKey)
end
PhaseLevel._Update = HL.Method() << function(self)
    self:_UpdateFactoryMode()
end
PhaseLevel.UpdateGeneralTracker = HL.Method() << function(self)
    local result = {}
    local trackerDataList = GameInstance.world.entityMarkStateManager:GetCurrentGeneralTrackingTargets()
    for i = 0, trackerDataList.Count - 1 do
        local item = trackerDataList[i]
        local data = {}
        local logicId = item.entityLogicId
        data.worldPos = item.position
        if logicId ~= nil then
            local iconPos = self.m_headLabelCtrl:GetEntityLabelIconPos(logicId)
            if iconPos ~= nil then
                data.worldPos = iconPos
            end
        end
        table.insert(result, data)
    end
    self.m_generalTrackerPanel.uiCtrl:UpdateEntityHeadPointDict(result)
end
PhaseLevel._OnActivated = HL.Override() << function(self)
    self:_AddRegisters()
    GameInstance.world.ppEffectLoader:Resume()
    self:_OnInMainHudStateChanged(true)
end
PhaseLevel._OnDeActivated = HL.Override() << function(self)
    self:_ClearRegisters()
    GameInstance.world.ppEffectLoader:Pause()
    if GameInstance.world.inMainHud then
        self:_OnInMainHudStateChanged(false)
    end
end
PhaseLevel._OnDestroy = HL.Override() << function(self)
    if self.m_hidePanelKey > 0 then
        self.m_hidePanelKey = UIManager:RecoverScreen(self.m_hidePanelKey)
    end
    self:_ClearRegisters()
    self:_ClearInMainHudMessageList()
    if self.m_enterFacMainRegionCamState then
        self.m_enterFacMainRegionCamState = FactoryUtils.exitFacCamera(self.m_enterFacMainRegionCamState)
    end
    Notify(MessageConst.FORCE_CLEAR_SPACESHIP_ROOM_CAM)
end
PhaseLevel._DoPhaseTransitionIn = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    self:LoadLevelPanels()
    logger.info("ON_PHASE_LEVEL_ON_TOP")
    Notify(MessageConst.ON_PHASE_LEVEL_ON_TOP)
    CS.Beyond.Gameplay.Conditions.OnEnterMainHud.Trigger()
end
PhaseLevel.m_hidePanelKey = HL.Field(HL.Number) << -1
PhaseLevel._DoPhaseTransitionBackToTop = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    self.m_hidePanelKey = UIManager:RecoverScreen(self.m_hidePanelKey)
    logger.info("ON_PHASE_LEVEL_ON_TOP")
    Notify(MessageConst.ON_PHASE_LEVEL_ON_TOP)
    CS.Beyond.Gameplay.Conditions.OnEnterMainHud.Trigger()
    GameInstance.remoteFactoryManager:ForceCullingExecute()
end
PhaseLevel.m_transitionReservePanelIds = HL.Field(HL.Table)
PhaseLevel.SetPhaseLevelTransitionReservePanels = HL.Method(HL.Table) << function(self, ids)
    self.m_transitionReservePanelIds = ids
end
PhaseLevel._DoPhaseTransitionBehind = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    local usingBT = UIUtils.usingBlockTransition()
    if args.anotherPhaseId == PhaseId.CharInfo or args.anotherPhaseId == PhaseId.CharFormation then
    elseif fastMode or usingBT then
        self.m_hidePanelKey = UIManager:ClearScreen(self.m_transitionReservePanelIds)
    else
        self.m_inTransition = true
        UIManager:ClearScreenWithOutAnimation(function(key)
            self.m_hidePanelKey = key
            if self.m_completeOnDestroy and self.m_hidePanelKey > 0 then
                self.m_hidePanelKey = UIManager:RecoverScreen(self.m_hidePanelKey)
            end
            self.m_inTransition = false
        end, self.m_transitionReservePanelIds)
    end
    self.m_transitionReservePanelIds = nil
    self:_OnInMainHudStateChanged(false)
    logger.info("ON_PHASE_LEVEL_NOT_ON_TOP")
    Notify(MessageConst.ON_PHASE_LEVEL_NOT_ON_TOP)
end
PhaseLevel._DoPhaseTransitionOut = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    self:_OnInMainHudStateChanged(false)
    logger.info("ON_PHASE_LEVEL_NOT_ON_TOP")
    Notify(MessageConst.ON_PHASE_LEVEL_NOT_ON_TOP)
end
PhaseLevel.OnOpenSubGameTrackings = HL.Method(HL.Any) << function(self, args)
    local doAction = function()
        local opened, missionHudCtrl = UIManager:IsOpen(PanelId.MissionHud)
        if opened then
            if UIManager:IsShow(PanelId.MissionHud) then
                CoroutineManager:ClearAllCoroutine(missionHudCtrl)
                missionHudCtrl:PlayAnimationOut()
            else
                missionHudCtrl:Close()
            end
        end
        local subGameId = unpack(args)
        local trackHudCtrl = UIManager:AutoOpen(PanelId.CommonTaskTrackHud)
        trackHudCtrl:InitSubGameTrack(subGameId)
        trackHudCtrl:PlayAnimationIn()
    end
    local subGameId = unpack(args)
    local success, subGameData = DataManager.subGameInstDataTable:TryGetValue(subGameId)
    local gameMechanicData = Tables.gameMechanicTable[subGameId]
    if success then
        if subGameData.modeType == GEnums.GameModeType.WorldChallenge and gameMechanicData.gameCategory == "world_energy_point_small" then
            LuaSystemManager.commonTaskTrackSystem:AddRequest("ForceClearTrackHud", function()
                doAction()
            end)
        else
            LuaSystemManager.commonTaskTrackSystem:AddRequest("TrackHud", function()
                doAction()
            end)
        end
    end
end
PhaseLevel.OnCloseSubGameTrack = HL.Method() << function(self)
    LuaSystemManager.commonTaskTrackSystem:AddRequest("TrackHud", function()
        local trackOpened, trackHudCtrl = UIManager:IsOpen(PanelId.CommonTaskTrackHud)
        if trackOpened then
            trackHudCtrl:StopSubGameTrack()
        else
            self:OnDeactivateCommonTaskTrackHud()
        end
    end)
end
PhaseLevel.OnOpenLevelScriptCustomTask = HL.Method() << function(self)
    local doAction = function()
        local opened, missionHudCtrl = UIManager:IsOpen(PanelId.MissionHud)
        if opened then
            if UIManager:IsShow(PanelId.MissionHud) then
                missionHudCtrl:PlayAnimationOut()
            else
                missionHudCtrl:Close()
            end
        end
        local trackHudCtrl = UIManager:AutoOpen(PanelId.CommonTaskTrackHud)
        trackHudCtrl:InitCustomTaskTrack()
        trackHudCtrl:PlayAnimationIn()
    end
    if GameInstance.mode.modeType == GEnums.GameModeType.WorldChallenge then
        local gameMechanicData = Tables.gameMechanicTable[GameInstance.mode.curSubGameId]
        if gameMechanicData.gameCategory == "world_energy_point_small" then
            LuaSystemManager.commonTaskTrackSystem:AddRequest("ForceClearTrackHud", function()
                doAction()
            end)
        end
    else
        LuaSystemManager.commonTaskTrackSystem:AddRequest("TrackHud", function()
            doAction()
        end)
    end
end
PhaseLevel.OnCloseLevelScriptCustomTask = HL.Method() << function(self)
    LuaSystemManager.commonTaskTrackSystem:AddRequest("TrackHud", function()
        local trackOpened, trackHudCtrl = UIManager:IsOpen(PanelId.CommonTaskTrackHud)
        if trackOpened then
            trackHudCtrl:StopCustomTaskTrack()
        end
    end)
end
PhaseLevel.OnDeactivateCommonTaskTrackHud = HL.Method() << function(self)
    local tryActivateMissionHud = function()
        if Utils.needMissionHud() then
            local ctrl = UIManager:AutoOpen(PanelId.MissionHud)
            ctrl:PlayAnimationIn()
        end
    end
    local opened, commonTaskTrackCtrl = UIManager:IsOpen(PanelId.CommonTaskTrackHud)
    if opened then
        if UIManager:IsShow(PanelId.CommonTaskTrackHud) then
            commonTaskTrackCtrl:PlayAnimationOut()
            tryActivateMissionHud()
        else
            commonTaskTrackCtrl:Close()
            tryActivateMissionHud()
        end
    else
        tryActivateMissionHud()
    end
end
local defenseExpectedPanels = { PanelId.MainHud, PanelId.Joystick, PanelId.LevelCamera, PanelId.FacHudBottomMask, PanelId.FacBuildMode, PanelId.FacDestroyMode, PanelId.FacBuildingInteract, PanelId.CommonItemToast, PanelId.CommonNewToast, PanelId.CommonHudToast, PanelId.Radio, PanelId.CommonTaskTrackHud, PanelId.FacTopViewBuildingInfo, PanelId.InteractOption, PanelId.GuideLimited, PanelId.AIBark, PanelId.SettlementDefenseTransit, PanelId.MissionHud, PanelId.HeadBar, }
local defenseFinishExpectedPanels = { PanelId.Joystick, PanelId.LevelCamera, PanelId.CommonTaskTrackHud, }
local DEFENSE_TASK_TRACK_HUD_OFFSET = Vector2(0, -120)
local DEFENSE_CLEAR_DELAY_TIMER = 1.5
PhaseLevel.m_defensePrepareCtrl = HL.Field(HL.Forward("SettlementDefensePrepareHudCtrl"))
PhaseLevel.m_defenseInGamePanelItem = HL.Field(HL.Forward("PhasePanelItem"))
PhaseLevel.m_defenseTrackerPanelItem = HL.Field(HL.Forward("PhasePanelItem"))
PhaseLevel.m_defenseMiniMapPanelItem = HL.Field(HL.Forward("PhasePanelItem"))
PhaseLevel.m_defenseInGameClearScreenKey = HL.Field(HL.Number) << -1
PhaseLevel.m_defenseFinishClearScreenKey = HL.Field(HL.Number) << -1
PhaseLevel.m_defenseClearTimer = HL.Field(HL.Number) << -1
PhaseLevel.OnEnterTowerDefensePreparingPhase = HL.Method() << function(self)
    self.m_defensePrepareCtrl = UIManager:AutoOpen(PanelId.SettlementDefensePrepareHud)
end
PhaseLevel.OnLeaveTowerDefensePreparingPhase = HL.Method(HL.Any) << function(self, args)
    local onLeavingArea, startLeave = unpack(args)
    self.m_defensePrepareCtrl:CloseDefensePrepareHud(onLeavingArea, startLeave)
    self.m_defensePrepareCtrl = nil
end
PhaseLevel.OnEnterTowerDefenseDefendingPhase = HL.Method() << function(self)
    self.m_defenseInGameClearScreenKey = UIManager:ClearScreen(lume.concat(defenseExpectedPanels, battleOnlyPanels))
    GameInstance.player.towerDefenseSystem.systemInDefense = true
    local isOpen, taskTrackHudCtrl = UIManager:IsOpen(PanelId.CommonTaskTrackHud)
    if isOpen then
        taskTrackHudCtrl:AddPositionOffset(DEFENSE_TASK_TRACK_HUD_OFFSET)
    end
end
PhaseLevel.OnTowerDefenseDefendingTransitFinished = HL.Method() << function(self)
    self.m_defenseInGamePanelItem = self:CreatePhasePanelItem(PanelId.SettlementDefenseInGameHud)
    self.m_defenseTrackerPanelItem = self:CreatePhasePanelItem(PanelId.SettlementDefenseTracker)
    self.m_defenseMiniMapPanelItem = self:CreatePhasePanelItem(PanelId.SettlementDefenseMiniMap)
end
PhaseLevel.OnLeaveTowerDefenseDefendingPhase = HL.Method() << function(self)
    local waitCloseItemList = { self.m_defenseInGamePanelItem, self.m_defenseTrackerPanelItem, self.m_defenseMiniMapPanelItem, }
    if PhaseManager:GetTopPhaseId() ~= PHASE_ID then
        PhaseManager:ExitPhaseFastTo(PHASE_ID)
    end
    self.m_defenseFinishClearScreenKey = UIManager:ClearScreen(defenseFinishExpectedPanels)
    local waitCount = #waitCloseItemList
    for _, item in ipairs(waitCloseItemList) do
        item.uiCtrl:PlayAnimationOutWithCallback(function()
            self:RemovePhasePanelItem(item)
            waitCount = waitCount - 1
            if waitCount == 0 then
                if PhaseManager:GetTopPhaseId() ~= PHASE_ID then
                    PhaseManager:ExitPhaseFastTo(PHASE_ID)
                end
                self.m_defenseClearTimer = TimerManager:StartTimer(DEFENSE_CLEAR_DELAY_TIMER, function()
                    TimerManager:ClearTimer(self.m_defenseClearTimer)
                    Notify(MessageConst.ON_TOWER_DEFENSE_LEVEL_HUD_CLEARED)
                end)
            end
        end)
    end
    local isOpen, taskTrackHudCtrl = UIManager:IsOpen(PanelId.CommonTaskTrackHud)
    if isOpen then
        taskTrackHudCtrl:ClearPositionOffset()
    end
end
PhaseLevel.OnTowerDefenseDefendingRewardsFinished = HL.Method() << function(self)
    self.m_defenseInGameClearScreenKey = UIManager:RecoverScreen(self.m_defenseInGameClearScreenKey)
    self.m_defenseFinishClearScreenKey = UIManager:RecoverScreen(self.m_defenseFinishClearScreenKey)
end
local GameModeHideUIKey = "GameMode"
PhaseLevel.OnGameModeEnable = HL.Method(HL.Table) << function(self, args)
    logger.info("PhaseLevel.OnGameModeEnable", args)
    local modeType, mode = unpack(args)
    if mode.hideSquadIcon then
        UIManager:HideWithKey(PanelId.SquadIcon, GameModeHideUIKey)
    else
        UIManager:ShowWithKey(PanelId.SquadIcon, GameModeHideUIKey)
    end
    if mode.forbidAttack then
        UIManager:HideWithKey(PanelId.BattleAction, GameModeHideUIKey)
    else
        UIManager:ShowWithKey(PanelId.BattleAction, GameModeHideUIKey)
    end
    Notify(MessageConst.TOGGLE_FORBID_ATTACK, { GameModeHideUIKey, mode.forbidAttack })
    if mode.hideMissionHud then
        UIManager:HideWithKey(PanelId.MissionHud, GameModeHideUIKey)
    else
        UIManager:ShowWithKey(PanelId.MissionHud, GameModeHideUIKey)
    end
    Notify(MessageConst.TOGGLE_FORBID_SPRINT, { GameModeHideUIKey, mode.forbidSprint })
end
PhaseLevel.OnForbidSystemChanged = HL.Method(HL.Table) << function(self, args)
    local forbidType, isForbidden = unpack(args)
    if forbidType == ForbidType.HideSquadIcon then
        if isForbidden then
            UIManager:HideWithKey(PanelId.SquadIcon, GameModeHideUIKey)
        else
            UIManager:ShowWithKey(PanelId.SquadIcon, GameModeHideUIKey)
        end
    end
end
PhaseLevel.m_inMainHudMessageConfig = HL.Field(HL.Table)
PhaseLevel.m_inMainHudMessageDataList = HL.Field(HL.Table)
PhaseLevel.m_outMainHudCount = HL.Field(HL.Number) << 0
PhaseLevel._InitInMainHudMessageList = HL.Method() << function(self)
    self.m_inMainHudMessageConfig = { { inMessage = MessageConst.ON_LOADING_PANEL_CLOSED, outMessage = MessageConst.ON_LOADING_PANEL_OPENED, }, { inMessage = MessageConst.ON_TELEPORT_LOADING_PANEL_CLOSED, outMessage = MessageConst.ON_TELEPORT_LOADING_PANEL_OPENED, }, { inMessage = MessageConst.ON_BLACK_SCREEN_OUT, outMessage = MessageConst.ON_BLACK_SCREEN_IN, }, { inMessage = MessageConst.ON_EXIT_BLOCKED_REWARD_POP_UP_PANEL, outMessage = MessageConst.ON_ENTER_BLOCKED_REWARD_POP_UP_PANEL, }, { inMessage = MessageConst.ON_DUNGEON_SETTLEMENT_CLOSED, outMessage = MessageConst.ON_DUNGEON_SETTLEMENT_OPENED, }, { inMessage = MessageConst.ON_SNS_FORCE_DIALOG_END, outMessage = MessageConst.ON_SNS_FORCE_DIALOG_START, }, }
    self.m_inMainHudMessageDataList = {}
    self.m_outMainHudCount = 0
    for index, configInfo in ipairs(self.m_inMainHudMessageConfig) do
        local inKey = MessageManager:Register(configInfo.inMessage, function()
            self:_OnInMainHudMessageNotified(index, true)
        end, self)
        local outKey = MessageManager:Register(configInfo.outMessage, function()
            self:_OnInMainHudMessageNotified(index, false)
        end, self)
        self.m_inMainHudMessageDataList[index] = { inKey = inKey, outKey = outKey, isNotified = false, }
    end
end
PhaseLevel._ClearInMainHudMessageList = HL.Method() << function(self)
    for _, info in ipairs(self.m_inMainHudMessageDataList) do
        MessageManager:Unregister(info.inKey)
        MessageManager:Unregister(info.outKey)
    end
    self.m_inMainHudMessageConfig = {}
    self.m_inMainHudMessageDataList = {}
    self.m_outMainHudCount = 0
end
PhaseLevel._OnInMainHudMessageNotified = HL.Method(HL.Number, HL.Boolean) << function(self, index, isIn)
    local data = self.m_inMainHudMessageDataList[index]
    if data == nil then
        return
    end
    if data.isNotified and not isIn then
        return
    end
    if not data.isNotified and isIn then
        return
    end
    data.isNotified = not isIn
    self:_OnInMainHudStateChanged(isIn)
    logger.info("当前有其他行为导致是否处于MainHud状态发生改变, 来源", index, " 是否进入", isIn)
end
PhaseLevel._OnInMainHudStateChanged = HL.Method(HL.Boolean) << function(self, isIn)
    self.m_outMainHudCount = isIn and self.m_outMainHudCount - 1 or self.m_outMainHudCount + 1
    self.m_outMainHudCount = lume.clamp(self.m_outMainHudCount, 0, #self.m_inMainHudMessageConfig + 1)
    GameInstance.world.inMainHud = self.m_outMainHudCount <= 0
end
PhaseLevel.OnResetBlackbox = HL.Method() << function(self)
    if FactoryUtils.isInTopView() then
        LuaSystemManager.facSystem:ToggleTopView(false, true)
    end
    self:_UpdateFactoryMode(true)
end
HL.Commit(PhaseLevel)