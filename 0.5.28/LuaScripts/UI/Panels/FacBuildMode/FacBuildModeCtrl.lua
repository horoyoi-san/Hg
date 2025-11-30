local disableCamMoveKey = "build"
local cameraShadedHintText = Language.LUA_FAC_BUILD_MODE_CAMERA_SHADED
local KeyHints = { newBuilding = { "fac_rotate_device", "fac_build_confirm", "fac_build_cancel", }, oldBuilding = { "fac_build_mode_delete", "fac_rotate_device", "fac_build_confirm", "fac_build_cancel", }, logistic = { "fac_rotate_device", "fac_build_confirm", "fac_build_cancel", }, beltStart = { "fac_build_confirm_belt_start", "fac_build_rotate_belt", "fac_build_cancel", }, beltEnd = { "fac_build_confirm_belt_end", "fac_build_rotate_belt", "fac_build_cancel", }, pipeStart = { "fac_build_confirm_belt_start", "fac_build_rotate_pipe", "fac_build_cancel", }, pipeEnd = { "fac_build_confirm_belt_end", "fac_build_rotate_pipe", "fac_build_cancel", }, }
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacBuildMode
FacBuildModeCtrl = HL.Class('FacBuildModeCtrl', uiCtrl.UICtrl)
FacBuildModeCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_INTERACT_CONVEYOR_LOCAL_CHECKING_FAILED] = 'OnInteractConveyorLocalCheckingFailed', [MessageConst.FAC_BUILD_EXIT_CUR_MODE] = 'ExitCurMode', [MessageConst.ON_SQUAD_INFIGHT_CHANGED] = 'OnSquadInfightChanged', [MessageConst.FAC_SET_ENABLE_CONFIRM_BUILD] = 'SetEnableConfirmBuild', [MessageConst.FAC_SET_ENABLE_EXIT_BUILD_MODE] = 'SetEnableExitBuildMode', [MessageConst.ON_PREPARE_NARRATIVE] = 'ExitCurModeForCS', [MessageConst.ON_SCENE_LOAD_START] = 'ExitCurModeForCS', [MessageConst.ALL_CHARACTER_DEAD] = 'ExitCurModeForCS', [MessageConst.ON_TELEPORT_SQUAD] = 'ExitCurModeForCS', [MessageConst.PLAY_CG] = 'ExitCurModeForCS', [MessageConst.ON_PLAY_CUTSCENE] = 'ExitCurModeForCS', [MessageConst.ON_DIALOG_START] = 'ExitCurModeForCS', [MessageConst.ON_IN_FAC_MAIN_REGION_CHANGE] = 'OnInFacMainRegionChange', [MessageConst.FAC_LOCK_BUILD_POS] = 'FacLockBuildPos', }
FacBuildModeCtrl.m_onClickScreen = HL.Field(HL.Function)
FacBuildModeCtrl.m_onPressScreen = HL.Field(HL.Function)
FacBuildModeCtrl.m_onReleaseScreen = HL.Field(HL.Function)
FacBuildModeCtrl.m_mode = HL.Field(HL.Number) << FacConst.FAC_BUILD_MODE.Normal
FacBuildModeCtrl.m_buildArgs = HL.Field(HL.Table)
FacBuildModeCtrl.m_itemData = HL.Field(HL.Userdata)
FacBuildModeCtrl.m_buildingNodeId = HL.Field(HL.Any)
FacBuildModeCtrl.m_buildingId = HL.Field(HL.String) << ""
FacBuildModeCtrl.m_beltId = HL.Field(HL.String) << ""
FacBuildModeCtrl.m_lastMousePos = HL.Field(HL.Userdata)
FacBuildModeCtrl.m_tickCor = HL.Field(HL.Thread)
FacBuildModeCtrl.m_sizeIndicator = HL.Field(HL.Table)
FacBuildModeCtrl.m_beltStartPreviewMark = HL.Field(HL.Table)
FacBuildModeCtrl.m_pipePreviewMark = HL.Field(HL.Table)
FacBuildModeCtrl.m_hideKey = HL.Field(HL.Number) << -1
FacBuildModeCtrl.m_powerPoleRange = HL.Field(HL.Table)
FacBuildModeCtrl.m_fluidSprayRange = HL.Field(HL.Table)
FacBuildModeCtrl.m_battleRange = HL.Field(HL.Table)
FacBuildModeCtrl.m_isDragging = HL.Field(HL.Boolean) << false
FacBuildModeCtrl.m_draggingOffset = HL.Field(Vector3)
FacBuildModeCtrl.m_camState = HL.Field(HL.Any)
FacBuildModeCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.exitButton.onClick:AddListener(function()
        self:ExitCurMode()
    end)
    self.view.confirmButton.onClick:AddListener(function()
        self:_OnClickConfirm()
    end)
    self.view.rotateButton.onClick:AddListener(function()
        self:_RotateUnit()
    end)
    self.view.delButton.onClick:AddListener(function()
        self:_DelBuilding()
    end)
    self.m_onClickScreen = function()
        self:_OnClickScreen()
    end
    self.m_onPressScreen = function()
        self:_OnPressScreen()
    end
    self.m_onReleaseScreen = function()
        self:_OnReleaseScreen()
    end
    self:BindInputPlayerAction("common_cancel", function()
        self:ExitCurMode()
    end)
    self:BindInputPlayerAction("fac_disable_mouse1_sprint", function()
    end)
    self:BindInputPlayerAction("fac_rotate_device", function()
        self:_RotateUnit()
    end)
    self:BindInputPlayerAction("fac_build_mode_delete", function()
        self:_DelBuilding()
    end)
    self.view.moveBuildingHint.gameObject:SetActive(false)
    do
        local prefab = self.loader:LoadGameObject(FacConst.BUILDING_SIZE_INDICATOR_PATH)
        local obj = self:_CreateWorldGameObject(prefab)
        self.m_sizeIndicator = Utils.wrapLuaNode(obj)
        obj.gameObject:SetActive(false)
    end
    do
        local prefab = self.loader:LoadGameObject(FacConst.BELT_START_PREVIEW_MARK_PREFAB_PATH)
        local obj = self:_CreateWorldGameObject(prefab)
        local mark = Utils.wrapLuaNode(obj)
        mark.gameObject:SetActive(false)
        mark.mesh.sharedMaterial = mark.mesh:GetInstantiatedMaterial()
        mark.mats = { mark.mesh.sharedMaterial }
        self.m_beltStartPreviewMark = mark
    end
    do
        local prefab = self.loader:LoadGameObject(FacConst.PIPE_PREVIEW_MARK_PREFAB_PATH)
        local obj = self:_CreateWorldGameObject(prefab)
        local mark = Utils.wrapLuaNode(obj)
        mark.gameObject:SetActive(false)
        mark.mesh1.sharedMaterial = mark.mesh1:GetInstantiatedMaterial()
        mark.mesh2.sharedMaterial = mark.mesh2:GetInstantiatedMaterial()
        mark.mesh3.sharedMaterial = mark.mesh3:GetInstantiatedMaterial()
        mark.mats = { mark.mesh1.sharedMaterial, mark.mesh2.sharedMaterial, mark.mesh3.sharedMaterial }
        self.m_pipePreviewMark = mark
    end
    do
        local prefab = self.loader:LoadGameObject(FacConst.POWER_POLE_RANGE_EFFECT)
        local obj = self:_CreateWorldGameObject(prefab)
        self.m_powerPoleRange = Utils.wrapLuaNode(obj)
        obj.gameObject:SetActive(false)
    end
    do
        local prefab = self.loader:LoadGameObject(FacConst.FLUID_SPRAY_RANGE_EFFECT)
        local obj = self:_CreateWorldGameObject(prefab)
        self.m_fluidSprayRange = Utils.wrapLuaNode(obj)
        obj.gameObject:SetActive(false)
    end
    do
        local prefab = self.loader:LoadGameObject(FacConst.BATTLE_BUILDING_RANGE_EFFECT)
        local obj = self:_CreateWorldGameObject(prefab)
        self.m_battleRange = Utils.wrapLuaNode(obj)
        obj.gameObject:SetActive(false)
    end
    self.view.hideToggle.toggle.onValueChanged:AddListener(function(isOn)
        self:_OnChangeHideToggle(isOn)
    end)
    self:_InitKeyHint()
end
FacBuildModeCtrl._Tick = HL.Method() << function(self)
    if self.m_lockBuildPos then
        return
    end
    local isBuilding = self.m_mode == FacConst.FAC_BUILD_MODE.Building
    local isBelt = self.m_mode == FacConst.FAC_BUILD_MODE.Belt
    local isLogistic = self.m_mode == FacConst.FAC_BUILD_MODE.Logistic
    local curMousePos = self:_GetCurPointerPressPos()
    local camRay = CameraManager.mainCamera:ScreenPointToRay(curMousePos)
    local _, worldPos = CSFactoryUtil.SampleLevelRegionPointWithRay(camRay)
    local customGridCenter = worldPos
    local usingDrag = self:_InDragMode()
    if self.m_isDragging then
        curMousePos = curMousePos + self.m_draggingOffset
    end
    local curMode
    if isBuilding or isLogistic then
        curMode = GameInstance.remoteFactoryManager.interact.currentBuildingMode
        if not usingDrag or self.m_isDragging then
            GameInstance.remoteFactoryManager:GridPositionTriggered(curMousePos, 4)
        elseif usingDrag then
            local buildingCenterPos = GameInstance.remoteFactoryManager.interact.currentBuildingMode:GetPreviewRenderInfo()
            local buildingScreenPos = CameraManager.mainCamera:WorldToScreenPoint(buildingCenterPos)
            buildingScreenPos.z = 0
            local newScreenPos = Vector3.zero
            newScreenPos.x = lume.clamp(buildingScreenPos.x, 250, Screen.width - 250)
            newScreenPos.y = lume.clamp(buildingScreenPos.y, 150, Screen.height - 200)
            if newScreenPos ~= buildingScreenPos then
                GameInstance.remoteFactoryManager:GridPositionTriggered(newScreenPos, 4)
                buildingCenterPos = GameInstance.remoteFactoryManager.interact.currentBuildingMode:GetPreviewRenderInfo()
            end
            customGridCenter = buildingCenterPos
        end
    elseif isBelt then
        curMode = GameInstance.remoteFactoryManager.interact.currentConveyorMode
        if usingDrag then
            if self.m_isDragging then
                GameInstance.remoteFactoryManager:GridPositionTriggered(curMousePos, 2)
            end
            self.view.confirmButton.gameObject:SetActive(true)
        else
            GameInstance.remoteFactoryManager:GridPositionTriggered(curMousePos, 4)
        end
        self:_UpdateBPStartPreviewMarkWithWorldPos(worldPos)
    end
    if curMode then
        curMode.useCustomGridCenter = LuaSystemManager.facSystem.inTopView
        if curMode.useCustomGridCenter then
            curMode.customGridCenter = customGridCenter
        end
    end
    self.m_lastMousePos = curMousePos
    self:_UpdateValidResult()
    self:_NotifyPowerPoleTravelHint()
end
FacBuildModeCtrl.OnShow = HL.Override() << function(self)
    self:_AddRegister()
    CS.HG.Rendering.ScriptBridge.TAAUControlBridge.taauFastConverge = true
    Notify(MessageConst.TOGGLE_FORBID_ATTACK, { "FacBuildModeCtrl", true })
    self:FacLockBuildPos({ false })
end
FacBuildModeCtrl.OnHide = HL.Override() << function(self)
    self:FacLockBuildPos({ false })
    self:_OnReleaseScreen()
    self:_ClearRegister()
    CS.HG.Rendering.ScriptBridge.TAAUControlBridge.taauFastConverge = true
    Notify(MessageConst.TOGGLE_FORBID_ATTACK, { "FacBuildModeCtrl", false })
end
FacBuildModeCtrl.OnClose = HL.Override() << function(self)
    self:_ClearRegister()
    Notify(MessageConst.TOGGLE_FORBID_ATTACK, { "FacBuildModeCtrl", false })
end
FacBuildModeCtrl.EnterBuildingMode = HL.StaticMethod(HL.Table) << function(args)
    if not FacBuildModeCtrl.CheckCanEnterAndShowToast() then
        return
    end
    FacBuildModeCtrl._BeforeEnterBuildMode()
    local self = FacBuildModeCtrl.AutoOpen(PANEL_ID, nil, true)
    self:_EnterBuildingMode(args)
end
FacBuildModeCtrl.EnterLogisticMode = HL.StaticMethod(HL.Table) << function(args)
    if not FacBuildModeCtrl.CheckCanEnterAndShowToast() then
        return
    end
    local itemId = args.itemId
    local logisticId = Tables.factoryItem2LogisticIdTable[itemId].logisticId
    local logisticData, isLiquid = FactoryUtils.getLogisticData(logisticId)
    if isLiquid and not FactoryUtils.isDomainSupportPipe() then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_DOMAIN_NOT_SUPPORT_PIPE)
        return
    end
    FacBuildModeCtrl._BeforeEnterBuildMode()
    local self = FacBuildModeCtrl.AutoOpen(PANEL_ID, nil, true)
    self:_EnterLogisticMode(args)
end
FacBuildModeCtrl.EnterBeltMode = HL.StaticMethod(HL.Table) << function(args)
    if not FacBuildModeCtrl.CheckCanEnterAndShowToast() then
        return
    end
    FacBuildModeCtrl._BeforeEnterBuildMode()
    local self = FacBuildModeCtrl.AutoOpen(PANEL_ID, nil, true)
    if lume.isarray(args) then
        args = { beltId = args[1] }
    end
    self:_EnterBeltMode(args)
end
FacBuildModeCtrl._BeforeEnterBuildMode = HL.StaticMethod() << function()
    Notify(MessageConst.HIDE_ITEM_TIPS)
    PhaseManager:ExitPhaseFastTo(PhaseId.Level)
end
FacBuildModeCtrl.OnSquadInfightChanged = HL.Method(HL.Opt(HL.Any)) << function(self)
    local inFight = Utils.isInFight()
    if inFight then
        self:ExitCurMode()
    end
end
FacBuildModeCtrl.CheckCanEnterAndShowToast = HL.StaticMethod().Return(HL.Boolean) << function()
    local level = PhaseManager.m_openedPhaseSet[PhaseId.Level]
    if not level then
        return false
    end
    local csCheckResult = GameInstance.remoteFactoryManager:CheckEnterInteractMode()
    if csCheckResult == CS.Beyond.Gameplay.RemoteFactory.EnterInteractModeCheckResult.InvalidLevel then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_CANT_ENTER_BUILD_MODE_WHEN_NO_FAC_REGION)
        return false
    end
    if level.isPlayerOutOfRangeManual then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_CANT_ENTER_BUILD_MODE_WHEN_OUT_OF_RANGE_MANUAL)
        return false
    end
    if GameInstance.world.battle.isSquadInFight and not Utils.isInSettlementDefenseDefending() then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_CANT_ENTER_BUILD_MODE_WHEN_FIGHT)
        return false
    end
    return true
end
FacBuildModeCtrl.m_needCloseMiniPower = HL.Field(HL.Boolean) << false
FacBuildModeCtrl._AddRegister = HL.Method() << function(self)
    local touchPanel = UIManager.commonTouchPanel
    touchPanel.onClick:AddListener(self.m_onClickScreen)
    touchPanel.onPress:AddListener(self.m_onPressScreen)
    touchPanel.onRelease:AddListener(self.m_onReleaseScreen)
    self:_Tick()
    self.m_tickCor = self:_StartCoroutine(function()
        while true do
            coroutine.step()
            self:_Tick()
        end
    end)
    if self.m_hideKey == -1 then
        self.m_hideKey = UIManager:ClearScreen({ PANEL_ID, PanelId.MainHud, PanelId.FacHudBottomMask, PanelId.Joystick, PanelId.LevelCamera, PanelId.FacPowerPoleLinkingLabel, PanelId.FacPowerPoleTravelHint, PanelId.HeadLabel, PanelId.FacMiniPowerHud, PanelId.FacTopView, PanelId.Radio, PanelId.FacTopViewBuildingInfo, })
    end
end
FacBuildModeCtrl._ClearRegister = HL.Method() << function(self)
    self.m_hideKey = UIManager:RecoverScreen(self.m_hideKey)
    self.m_tickCor = self:_ClearCoroutine(self.m_tickCor)
    local touchPanel = UIManager.commonTouchPanel
    touchPanel.onClick:RemoveListener(self.m_onClickScreen)
    touchPanel.onPress:RemoveListener(self.m_onPressScreen)
    touchPanel.onRelease:RemoveListener(self.m_onReleaseScreen)
end
FacBuildModeCtrl._OnClickScreen = HL.Method() << function(self)
    if not self.m_enableConfirmBuild then
        return
    end
    if DeviceInfo.usingTouch and not (LuaSystemManager.facSystem.inTopView and self.m_mode == FacConst.FAC_BUILD_MODE.Belt) then
        return
    end
    self:_OnClickConfirm()
end
FacBuildModeCtrl._OnClickConfirm = HL.Method() << function(self)
    if self.m_mode == FacConst.FAC_BUILD_MODE.Building then
        self:_ConfirmBuilding()
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Logistic then
        self:_ConfirmLogistic()
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Belt then
        GameInstance.remoteFactoryManager:GridPositionTriggered(self:_GetCurPointerPressPos(), 0)
        AudioAdapter.PostEvent("au_ui_fac_btn_belt_build_click")
    end
end
FacBuildModeCtrl._OnPressScreen = HL.Method() << function(self)
    if self.m_mode == FacConst.FAC_BUILD_MODE.Normal then
        return
    end
    if not LuaSystemManager.facSystem.inTopView or not DeviceInfo.usingTouch then
        return
    end
    local curMousePos = self:_GetCurPointerPressPos()
    local camRay = CameraManager.mainCamera:ScreenPointToRay(curMousePos)
    local _, worldPos = CSFactoryUtil.SampleLevelRegionPointWithRay(camRay)
    local buildingRadius
    if self.m_mode == FacConst.FAC_BUILD_MODE.Building then
        local buildingData = Tables.factoryBuildingTable:GetValue(self.m_buildingId)
        local width = buildingData.range.width
        local depth = buildingData.range.depth
        buildingRadius = math.sqrt(width * width + depth * depth) / 2
    else
        buildingRadius = 1
    end
    local buildingCenterPos
    if self.m_mode == FacConst.FAC_BUILD_MODE.Building or self.m_mode == FacConst.FAC_BUILD_MODE.Logistic then
        buildingCenterPos = GameInstance.remoteFactoryManager.interact.currentBuildingMode:GetPreviewRenderInfo()
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Belt then
        buildingCenterPos = GameInstance.remoteFactoryManager.interact.currentConveyorMode:GetDragHandlingPoint(worldPos)
    end
    if not buildingCenterPos then
        return
    end
    if (buildingCenterPos - worldPos).sqrMagnitude > buildingRadius * buildingRadius then
        return
    end
    self.m_isDragging = true
    GameInstance.remoteFactoryManager:GridPositionTriggered(curMousePos, 1)
    if self.m_mode == FacConst.FAC_BUILD_MODE.Building or self.m_mode == FacConst.FAC_BUILD_MODE.Logistic then
        local centerScreenPos = CameraManager.mainCamera:WorldToScreenPoint(buildingCenterPos)
        centerScreenPos.z = 0
        self.m_draggingOffset = centerScreenPos - curMousePos
    else
        self.m_draggingOffset = Vector3.zero
    end
    if self.m_mode ~= FacConst.FAC_BUILD_MODE.Belt then
        LuaSystemManager.facSystem.canMoveCamTarget = false
    end
end
FacBuildModeCtrl._OnReleaseScreen = HL.Method() << function(self)
    if self.m_isDragging then
        local curMousePos = self:_GetCurPointerPressPos()
        GameInstance.remoteFactoryManager:GridPositionTriggered(curMousePos, 3)
        self.m_isDragging = false
        self.m_draggingOffset = nil
        if self.m_mode ~= FacConst.FAC_BUILD_MODE.Belt then
            LuaSystemManager.facSystem.canMoveCamTarget = true
        end
    end
end
FacBuildModeCtrl.m_keyHintCells = HL.Field(HL.Forward('UIListCache'))
FacBuildModeCtrl._InitKeyHint = HL.Method() << function(self)
    self.m_keyHintCells = UIUtils.genCellCache(self.view.keyHintCell)
end
FacBuildModeCtrl._RefreshKeyHint = HL.Method(HL.Opt(HL.Table)) << function(self, keyHint)
    if not keyHint then
        self.m_keyHintCells:Refresh(0)
        return
    end
    local count = #keyHint
    local preActionIds, preActionIdCount
    if LuaSystemManager.facSystem.inTopView then
        preActionIds = FacConst.FAC_TOP_VIEW_BASIC_ACTION_IDS
        preActionIdCount = #preActionIds
        count = count + preActionIdCount
    end
    self.m_keyHintCells:Refresh(count, function(cell, index)
        local actionId
        if preActionIds then
            actionId = preActionIds[index] or keyHint[index - preActionIdCount]
        else
            actionId = keyHint[index]
        end
        cell.actionKeyHint:SetActionId(actionId)
        cell.gameObject.name = "KeyHint-" .. actionId
    end)
end
FacBuildModeCtrl._ClearArgs = HL.Method() << function(self)
    self.m_buildArgs = nil
    self.m_itemData = nil
    self.m_buildingNodeId = nil
    self.m_buildingId = ""
    self.m_beltId = ""
    self.m_lastMousePos = nil
    self:_SetCamState()
end
FacBuildModeCtrl.OnInFacMainRegionChange = HL.Method(HL.Boolean) << function(self, inMainRegion)
    if inMainRegion then
        return
    end
    if self.m_mode == FacConst.FAC_BUILD_MODE.Building then
        if FactoryUtils.canPlaceBuildingOnCurRegion(self.m_buildingId) then
            return
        end
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Logistic then
        local logisticData, isLiquid = FactoryUtils.getLogisticData(self.m_buildingId)
        if isLiquid then
            return
        end
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Belt then
        if self:_IsPipe() then
            return
        end
    end
    self:ExitCurMode()
end
FacBuildModeCtrl.ExitCurModeForCS = HL.Method(HL.Opt(HL.Any)) << function(self)
    self:ExitCurMode(true)
end
FacBuildModeCtrl.ExitCurMode = HL.Method(HL.Opt(HL.Boolean)) << function(self, skipAnim)
    if not self.m_enableExitBuildMode then
        return
    end
    if self.m_mode == FacConst.FAC_BUILD_MODE.Normal then
        return
    end
    if self.m_mode == FacConst.FAC_BUILD_MODE.Building then
        self:_CancelBuilding(skipAnim)
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Logistic then
        self:_CancelLogistic(skipAnim)
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Belt then
        self:_ExitBeltMode(skipAnim)
    end
    AudioAdapter.PostEvent("au_sfx_ui_fac_buiding_off")
end
FacBuildModeCtrl.m_curBuildIsValid = HL.Field(HL.Boolean) << true
FacBuildModeCtrl._GetBuildingCheckResultHint = HL.Method(HL.Userdata).Return(HL.Boolean, HL.Opt(HL.String)) << function(self, checkResult)
    local valid, hint = checkResult.success, nil
    if not valid then
        if checkResult.busLimited then
            hint = Language.LUA_FAC_BUILD_MODE_ROAD_ATTACH
        elseif checkResult.mainRegionLimited then
            hint = Language.LUA_FAC_BUILD_MODE_MAIN_REGION_LIMITED
        elseif checkResult.cropAreaLimited then
            hint = Language.LUA_FAC_BUILD_MODE_ON_CROP_AREA_ONLY
        elseif checkResult.cropCntLimited then
            hint = Language.LUA_FAC_BUILD_MODE_ON_CROP_COUNT_LIMITED
        elseif checkResult.bandwidthLimited then
            hint = Language.LUA_FAC_BUILD_MODE_ON_BANDWIDTH_MAX
        elseif checkResult.travelPoleCountLimited then
            hint = Language.LUA_FAC_BUILD_MODE_ON_TRAVEL_POLE_COUNT_MAX
        elseif checkResult.battleCountLimited then
            hint = Language.LUA_FAC_BUILD_MODE_ON_BATTLE_COUNT_MAX
        elseif checkResult.mineLimited then
            hint = Language.LUA_FAC_BUILD_MODE_ON_MINE_ONLY
        elseif checkResult.mineTypeLimited then
            hint = Language.LUA_FAC_BUILD_MODE_ON_WRONG_MINE_TYPE
        elseif checkResult.buildableWaterLimited then
            hint = Language.LUA_FAC_BUILD_MODE_IN_WATER_LIMITED
        elseif checkResult.buildableLimited then
            hint = Language.LUA_FAC_BUILD_MODE_IN_BUILDABLE_RANGE_BUT_HAS_INVALID_GRID
        elseif checkResult.crossDivisionBoundary then
            hint = Language.LUA_FAC_BUILD_MODE_CROSS_DIVISION_BOUNDARY
        elseif checkResult.overlayNodes and checkResult.overlayNodes.Count > 0 then
            hint = Language.LUA_FAC_BUILD_MODE_BUILDING_OVERLAP
        elseif checkResult.outRanged then
            hint = Language.LUA_FAC_BUILD_MODE_OUT_OF_RANGE
        elseif checkResult.outOfHeight then
            hint = Language.LUA_FAC_BUILD_MODE_HEIGHT_OVER_TOOMUCH
        elseif checkResult.groundTooUneven then
            hint = Language.LUA_FAC_BUILD_MODE_GROUND_TOO_UNEVEN
        elseif checkResult.collideWithMap then
            hint = Language.LUA_FAC_BUILD_MODE_SPACE_HEIGHT_NOT_ENOUGH
        elseif checkResult.blockedByInter then
            hint = Language.LUA_FAC_BUILD_MODE_BLOCK_BY_DYNAMIC_ENTITY
        elseif checkResult.blockedByErosion then
            hint = Language.LUA_FAC_BUILD_MODE_BLOCK_WITH_EROSION
        elseif checkResult.domainModeLimited then
            hint = Language.LUA_FAC_BUILD_MODE_DOMAIN_MODE_NOT_MATCHED
        elseif checkResult.pumpReachLiquidLimited then
            hint = Language.LUA_FAC_BUILD_MODE_PUMP_MUST_REACH_LIQUID
        elseif checkResult.dumpReachLiquidLimited then
            hint = Language.LUA_FAC_BUILD_MODE_DUMP_MUST_REACH_LIQUID
        elseif checkResult.noSoilForWaterSpray then
            hint = Language.LUA_FAC_BUILD_MODE_NO_SOIL_IN_SPRAY
        elseif checkResult.moveAcrossScene then
            hint = Language.LUA_FAC_BUILD_MODE_MOVE_ACROSS_SCENE
        elseif checkResult.minDistanceLimitNodes and checkResult.minDistanceLimitNodes.Count > 0 then
            hint = Language.LUA_FAC_BUILD_MODE_MIN_DISTANCE_LIMIT
        elseif checkResult.medicRangeOverlap then
            hint = Language.LUA_FAC_BUILD_MODE_MEDIC_RANGE_OVERLAP
        elseif checkResult.overlayMineIndex and checkResult.overlayMineIndex.Count > 0 then
            hint = Language.LUA_FAC_BUILD_MODE_MINE_OVERLAP
        else
            hint = Language.LUA_FAC_BUILD_MODE_OTHERS
        end
    end
    return valid, hint
end
FacBuildModeCtrl._UpdateValidResult = HL.Method() << function(self)
    if self.m_mode == FacConst.FAC_BUILD_MODE.Normal then
        return
    end
    local valid, hint = false, nil
    if self.m_mode == FacConst.FAC_BUILD_MODE.Building or self.m_mode == FacConst.FAC_BUILD_MODE.Logistic then
        local rst = GameInstance.remoteFactoryManager.interact.currentBuildingMode.addBuildingCheckResult
        valid, hint = self:_GetBuildingCheckResultHint(rst)
        if valid then
            local pos, rot = GameInstance.remoteFactoryManager.interact.currentBuildingMode:GetPreviewRenderInfo()
            CS.Beyond.Gameplay.Conditions.OnFacPrepareBuildingEnterArea.Trigger(self.m_buildingId, pos, rot.y)
        end
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Belt then
        local rst = GameInstance.remoteFactoryManager.interact.currentConveyorMode.checkResult
        local isPipe = GameInstance.remoteFactoryManager.interact.currentConveyorMode.usePipePreview
        valid = rst.success
        if not valid then
            if rst.mainRegionLimited then
                hint = Language.LUA_FAC_BUILD_MODE_MAIN_REGION_LIMITED
            elseif rst.buildableLimited then
                hint = Language.LUA_FAC_BUILD_MODE_IN_BUILDABLE_RANGE_BUT_HAS_INVALID_GRID
            elseif rst.hasSelfOverlay then
                hint = Language.LUA_FAC_BUILD_MODE_BELT_SELF_OVERLAP
            elseif rst.pipeAngleLimited then
                hint = Language.LUA_FAC_BUILD_MODE_PIPE_ANGLE_LIMITED
            elseif rst.overlayNodes and rst.overlayNodes.Count > 0 then
                hint = Language.LUA_FAC_BUILD_MODE_BUILDING_OVERLAP
            elseif rst.directionConflictLogisticUnits and rst.directionConflictLogisticUnits.Count > 0 then
                hint = isPipe and Language.LUA_FAC_BUILD_MODE_DIRECTION_CONFLICT_LOGISTIC_UNIT_PIPE or Language.LUA_FAC_BUILD_MODE_DIRECTION_CONFLICT_LOGISTIC_UNIT_BELT
            elseif rst.overLengthLimit then
                hint = isPipe and Language.LUA_FAC_BUILD_MODE_PIPE_OVER_LENGTH_LIMIT or Language.LUA_FAC_BUILD_MODE_BELT_OVER_LENGTH_LIMIT
            elseif rst.shapeInvalid then
                hint = isPipe and Language.LUA_FAC_BUILD_MODE_PIPE_SHAPE_INVALID or Language.LUA_FAC_BUILD_MODE_BELT_SHAPE_INVALID
            elseif rst.pipeStartModeLimited then
                hint = Language.LUA_FAC_BUILD_MODE_START_NODE_PIPE_MODE_LIMITED
            elseif rst.pipeEndModeLimited then
                hint = Language.LUA_FAC_BUILD_MODE_END_NODE_PIPE_MODE_LIMITED
            elseif rst.pipeStartPortLimited then
                hint = Language.LUA_FAC_BUILD_MODE_START_NODE_PIPE_PORT_LIMITED
            elseif rst.pipeEndPortLimited then
                hint = Language.LUA_FAC_BUILD_MODE_END_NODE_PIPE_PORT_LIMITED
            elseif rst.overlayMineIndex and rst.overlayMineIndex.Count > 0 then
                hint = Language.LUA_FAC_BUILD_MODE_MINE_OVERLAP
            else
                hint = Language.LUA_FAC_BUILD_MODE_OTHERS
            end
        else
            valid, hint = self:_GetBuildingCheckResultHint(GameInstance.remoteFactoryManager.interact.currentConveyorMode.additionalBuildingCheckResult)
        end
    end
    self.view.errorHint.gameObject:SetActiveIfNecessary(not valid)
    if hint then
        self.view.errorHintText.text = hint
    end
    self.m_curBuildIsValid = valid
    if self.m_mode == FacConst.FAC_BUILD_MODE.Building or self.m_mode == FacConst.FAC_BUILD_MODE.Belt or self.m_mode == FacConst.FAC_BUILD_MODE.Logistic then
        GameInstance.remoteFactoryManager:SetPreviewBuildingState(valid)
    end
end
FacBuildModeCtrl._UpdateCommonNodesOnEnterMode = HL.Method() << function(self)
    local isBelt = self.m_mode == FacConst.FAC_BUILD_MODE.Belt
    local isPipe = self:_IsPipe()
    local usingDrag = self:_InDragMode()
    self.view.actionHint.gameObject:SetActive(isBelt and usingDrag)
    self.view.actionHintTxt.text = isPipe and Language.LUA_FAC_BUILD_MODE_DRAW_PIPE_HINT or Language.LUA_FAC_BUILD_MODE_DRAW_BELT_HINT
    self.view.confirmButton.gameObject:SetActive(not isBelt or not usingDrag)
    self.view.rotateButton.gameObject:SetActive(not isBelt)
    self.view.delButton.gameObject:SetActive(self:_CanDelBuilding())
    local showHideToggle = LuaSystemManager.facSystem.inTopView and self.m_mode == FacConst.FAC_BUILD_MODE.Belt and FactoryUtils.canShowPipe()
    self.view.hideToggle.gameObject:SetActive(showHideToggle)
    self.view.hideToggle.toggle:SetIsOnWithoutNotify(showHideToggle)
    self:_OnChangeHideToggle(showHideToggle)
    self.view.hideToggle.beltIcon.gameObject:SetActive(isPipe)
    self.view.hideToggle.pipeIcon.gameObject:SetActive(not isPipe)
end
FacBuildModeCtrl._SetCamState = HL.Method(HL.Opt(HL.String)) << function(self, camStateName)
    if LuaSystemManager.facSystem.inTopView then
        return
    end
    if not camStateName then
        if self.m_camState then
            self.m_camState = FactoryUtils.exitFacCamera(self.m_camState)
        end
        return
    end
    if self.m_camState then
        logger.error("self.m_camState Not Null", self.m_camState)
        return
    end
    self.m_camState = FactoryUtils.enterFacCamera(camStateName)
end
FacBuildModeCtrl._IsPipe = HL.Method().Return(HL.Boolean) << function(self)
    return self.m_beltId == FacConst.PIPE_ID
end
FacBuildModeCtrl._OnChangeHideToggle = HL.Method(HL.Boolean) << function(self, isOn)
    if isOn then
        if self:_IsPipe() then
            FactoryUtils.startBeltFigureRenderer()
        else
            FactoryUtils.startPipeFigureRenderer()
        end
    else
        FactoryUtils.stopLogisticFigureRenderer()
    end
end
FacBuildModeCtrl._EnterBuildingMode = HL.Method(HL.Table) << function(self, args)
    if self.m_mode == FacConst.FAC_BUILD_MODE.Building then
        if self.m_buildArgs.onExit then
            self.m_buildArgs.onExit()
        end
        self:_SetCamState()
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Logistic then
        self:_ExitLogisticMode()
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Belt then
        self:_ExitBeltMode()
    end
    self.m_isDragging = false
    self.m_buildArgs = args
    local buildingId, itemData
    local nodeId = args.nodeId
    local mousePos
    if args.initMousePos then
        mousePos = Vector3(args.initMousePos.x, args.initMousePos.y, 0)
    else
        mousePos = self:_InDragMode() and Vector3(Screen.width / 2, Screen.height / 2, 0) or self:_GetCurPointerPressPos()
    end
    local camRay = CameraManager.mainCamera:ScreenPointToRay(mousePos)
    local _, initWorldPos = CSFactoryUtil.SampleLevelRegionPointWithRay(camRay)
    local initGridPos = GameInstance.remoteFactoryManager.visual:WorldToVoxel(initWorldPos)
    initGridPos = Unity.Vector3Int(math.floor(initGridPos.x), math.floor(initGridPos.y), math.floor(initGridPos.z))
    if nodeId then
        self.m_buildingNodeId = nodeId
        local node = FactoryUtils.getBuildingNodeHandler(nodeId)
        buildingId = node.templateId
        itemData = FactoryUtils.getBuildingItemData(buildingId)
        self:_RefreshKeyHint(KeyHints.oldBuilding)
        GameInstance.remoteFactoryManager.interact:SwitchToBuildingModeAsMove(nodeId, initGridPos, node.transform.direction.y / 90)
        local oriBuildingCpt = FactoryUtils
        self.view.moveBuildingHint.gameObject:SetActive(true)
    else
        self.m_buildingNodeId = nil
        local itemId = args.itemId
        itemData = Tables.itemTable[itemId]
        local buildingItemData = Tables.factoryBuildingItemTable[itemId]
        buildingId = buildingItemData.buildingId
        self:_RefreshKeyHint(KeyHints.newBuilding)
        local initDir = math.floor(((CameraManager.mainCamera.transform.eulerAngles.y + 45) % 360) / 90) % 4
        GameInstance.remoteFactoryManager.interact:SwitchToBuildingMode(buildingId, initGridPos, initDir)
        self.view.moveBuildingHint.gameObject:SetActive(false)
    end
    self.m_buildingId = buildingId
    self.m_itemData = itemData
    self:_UpdateValidResult()
    self.m_mode = FacConst.FAC_BUILD_MODE.Building
    self:_UpdateBuildingFollowerState(true)
    local bData = Tables.factoryBuildingTable[self.m_buildingId]
    self:_SetCamState(bData.buildCamState)
    Notify(MessageConst.ON_BUILD_MODE_CHANGE, self.m_mode)
    Notify(MessageConst.ON_ENTER_BUILDING_MODE, itemData.id)
    self:_NotifyPowerPoleTravelHint()
    self:_UpdateCommonNodesOnEnterMode()
    self:_Tick()
end
FacBuildModeCtrl._ExitBuildingMode = HL.Method(HL.Opt(HL.Boolean)) << function(self, skipAnim)
    self.m_mode = FacConst.FAC_BUILD_MODE.Normal
    self.m_sizeIndicator.gameObject:SetActiveIfNecessary(false)
    self.m_powerPoleRange.gameObject:SetActive(false)
    self.m_fluidSprayRange.gameObject:SetActive(false)
    self.m_battleRange.gameObject:SetActive(false)
    self.view.errorHint.gameObject:SetActiveIfNecessary(false)
    local onExit = self.m_buildArgs.onExit
    local nodeId = self.m_buildingNodeId
    self:_ClearArgs()
    if not string.isEmpty(nodeId) then
        self.view.moveBuildingHint.gameObject:SetActive(false)
        self.view.moveBuildingHint.targetTransform = nil
    end
    GameInstance.remoteFactoryManager.interact:ExitCurrentMode()
    local exitAct = function()
        self:Hide()
        if onExit then
            onExit()
        end
        Notify(MessageConst.ON_EXIT_BUILDING_MODE)
        Notify(MessageConst.ON_BUILD_MODE_CHANGE, self.m_mode)
    end
    if not skipAnim then
        self:PlayAnimationOutWithCallback(exitAct)
    else
        exitAct()
    end
end
FacBuildModeCtrl._NotifyPowerPoleTravelHint = HL.Method() << function(self)
    if self.m_mode ~= FacConst.FAC_BUILD_MODE.Building then
        return
    end
    local pos, rot = GameInstance.remoteFactoryManager.interact.currentBuildingMode:GetPreviewRenderInfo()
    if not self.m_buildingNodeId then
        Notify(MessageConst.ON_BUILD_POWER_POLE_TRAVEL_HINT, { buildingTypeId = self.m_buildingId, position = pos })
    else
        Notify(MessageConst.ON_MOVE_POWER_POLE_TRAVEL_HINT, { buildingTypeId = self.m_buildingId, position = pos, nodeId = self.m_buildingNodeId, })
    end
end
FacBuildModeCtrl._ConfirmBuilding = HL.Method() << function(self)
    self:_Tick()
    if not self.m_curBuildIsValid then
        Notify(MessageConst.SHOW_TOAST, self.view.errorHintText.text)
        return
    end
    local buildingItemId = self.m_itemData.id
    local mousePos = self:_GetCurPointerPressPos()
    GameInstance.remoteFactoryManager:GridPositionTriggered(mousePos, 0)
    local isNewBuilding = self.m_buildingNodeId == nil
    self:_ExitBuildingMode()
    if isNewBuilding then
        Notify(MessageConst.FAC_PLACE_BUILD_SUCC, buildingItemId)
    else
        AudioAdapter.PostEvent("au_ui_fac_building_move_set")
    end
end
FacBuildModeCtrl._CancelBuilding = HL.Method(HL.Opt(HL.Boolean)) << function(self, skipAnim)
    local onCancel = self.m_buildArgs.onCancel
    if onCancel then
        onCancel()
    end
    self:_ExitBuildingMode(skipAnim)
end
FacBuildModeCtrl._DelBuilding = HL.Method() << function(self)
    if not self:_CanDelBuilding() then
        return
    end
    GameInstance.player.remoteFactory.core:Message_OpDismantle(Utils.getCurrentChapterId(), self.m_buildingNodeId, function()
        self:_ExitBuildingMode()
    end)
end
FacBuildModeCtrl._CanDelBuilding = HL.Method().Return(HL.Boolean) << function(self)
    if self.m_mode ~= FacConst.FAC_BUILD_MODE.Building then
        return false
    end
    if self.m_buildingId == FacConst.HUB_DATA_ID then
        return false
    end
    local nodeId = self.m_buildingNodeId
    if not nodeId then
        return false
    end
    return FactoryUtils.canDelBuilding(self.m_buildingNodeId)
end
FacBuildModeCtrl._RotateUnit = HL.Method() << function(self)
    GameInstance.remoteFactoryManager.interact:InputKeyRotation(true)
    self:_UpdateBuildingFollowerState(false)
    AudioAdapter.PostEvent("au_ui_building_turn")
end
FacBuildModeCtrl._UpdateBuildingFollowerState = HL.Method(HL.Boolean) << function(self, isInit)
    if self.m_mode ~= FacConst.FAC_BUILD_MODE.Building then
        return
    end
    local data = Tables.factoryBuildingTable:GetValue(self.m_buildingId)
    self.m_sizeIndicator.gameObject:SetActiveIfNecessary(true)
    self.m_sizeIndicator.followerObject.getTargetPosInfo = function(pos, rot)
        pos, rot = GameInstance.remoteFactoryManager.interact.currentBuildingMode:GetPreviewRenderInfo()
        return pos, rot
    end
    local scale = Vector3(data.range.width, data.modelHeight, data.range.depth)
    local reverseScale = Vector3(1 / scale.x, 1 / scale.y, 1 / scale.z)
    self.m_sizeIndicator.transform.localScale = scale
    self.m_sizeIndicator.transform:DoActionOnChildren(function(childTrans)
        childTrans.localScale = reverseScale
    end)
    if isInit and data.type == GEnums.FacBuildingType.PowerDiffuser then
        local poleData = Tables.factoryPowerPoleTable[self.m_buildingId]
        local extSizeW = poleData.rangeExtend.x
        local extSizeH = poleData.rangeExtend.z
        if extSizeW > 0 or extSizeH > 0 then
            self.m_powerPoleRange.gameObject:SetActive(true)
            self.m_powerPoleRange.followerObject.getTargetPosInfo = function(pos, rot)
                pos, rot = GameInstance.remoteFactoryManager.interact.currentBuildingMode:GetPreviewRenderInfo()
                return pos, rot
            end
        end
    end
    if isInit and data.type == GEnums.FacBuildingType.FluidSpray then
        local fluidSprayData = Tables.factoryFluidSprayTable[self.m_buildingId]
        local localCenterPosX = fluidSprayData.squirterOffset.x + fluidSprayData.squirterRange.x * 0.5 - data.range.width * 0.5
        local localCenterPosY = fluidSprayData.squirterOffset.y
        local localCenterPosZ = fluidSprayData.squirterOffset.z + fluidSprayData.squirterRange.z * 0.5 - data.range.depth * 0.5
        self.m_fluidSprayRange.gameObject:SetActive(true)
        self.m_fluidSprayRange.followerObject.getTargetPosInfo = function(pos, rot)
            pos, rot = GameInstance.remoteFactoryManager.interact.currentBuildingMode:GetPreviewRenderInfo()
            local q = Quaternion.Euler(rot.x, rot.y, rot.z)
            local m = Unity.Matrix4x4.TRS(pos, q, Vector3.one)
            pos = m:MultiplyPoint3x4(Vector3(localCenterPosX, localCenterPosY, localCenterPosZ))
            return pos, rot
        end
    end
    if isInit and data.type == GEnums.FacBuildingType.Battle then
        local battleData = Tables.factoryBattleTable[self.m_buildingId]
        local range = battleData.attackRange
        if range > 0 then
            self.m_battleRange.gameObject:SetActive(true)
            self.m_battleRange.transform.localScale = Vector3(range / 8, 1, range / 8)
            self.m_battleRange.followerObject.getTargetPosInfo = function(pos, rot)
                pos, rot = GameInstance.remoteFactoryManager.interact.currentBuildingMode:GetPreviewRenderInfo()
                return pos, rot
            end
        end
    end
end
FacBuildModeCtrl._EnterLogisticMode = HL.Method(HL.Table) << function(self, args)
    if self.m_mode == FacConst.FAC_BUILD_MODE.Building then
        self:_ExitBuildingMode()
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Logistic then
        if self.m_buildArgs.onExit then
            self.m_buildArgs.onExit()
        end
        self:_SetCamState()
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Belt then
        self:_ExitBeltMode()
    end
    self.m_isDragging = false
    self.m_buildArgs = args
    local itemId = args.itemId
    local itemData = Tables.itemTable[itemId]
    local logisticId = Tables.factoryItem2LogisticIdTable[itemId].logisticId
    local mousePos
    if args.initMousePos then
        mousePos = Vector3(args.initMousePos.x, args.initMousePos.y, 0)
    else
        mousePos = self:_InDragMode() and Vector3(Screen.width / 2, Screen.height / 2, 0) or self:_GetCurPointerPressPos()
    end
    local camRay = CameraManager.mainCamera:ScreenPointToRay(mousePos)
    local _, initWorldPos = CSFactoryUtil.SampleLevelRegionPointWithRay(camRay)
    local initGridPos = GameInstance.remoteFactoryManager.visual:WorldToVoxel(initWorldPos)
    initGridPos = Unity.Vector3Int(lume.round(initGridPos.x), lume.round(initGridPos.y), lume.round(initGridPos.z))
    GameInstance.remoteFactoryManager.interact:SwitchToBuildingMode(logisticId, initGridPos, 0)
    self:_RefreshKeyHint(KeyHints.logistic)
    self.m_buildingId = logisticId
    self.m_itemData = itemData
    self:_UpdateValidResult()
    local logisticData = FactoryUtils.getLogisticData(logisticId)
    self:_SetCamState(logisticData.buildCamState)
    self.m_mode = FacConst.FAC_BUILD_MODE.Logistic
    Notify(MessageConst.ON_BUILD_MODE_CHANGE, self.m_mode)
    Notify(MessageConst.ON_ENTER_LOGISTIC_MODE, itemData.id)
    self:_UpdateCommonNodesOnEnterMode()
end
FacBuildModeCtrl._ExitLogisticMode = HL.Method(HL.Opt(HL.Boolean)) << function(self, skipAnim)
    self.m_mode = FacConst.FAC_BUILD_MODE.Normal
    local onExit = self.m_buildArgs.onExit
    self:_ClearArgs()
    GameInstance.remoteFactoryManager.interact:ExitCurrentMode()
    local exitAct = function()
        self:Hide()
        if onExit then
            onExit()
        end
        Notify(MessageConst.ON_EXIT_LOGISTIC_MODE)
        Notify(MessageConst.ON_BUILD_MODE_CHANGE, self.m_mode)
    end
    if not skipAnim then
        self:PlayAnimationOutWithCallback(exitAct)
    else
        exitAct()
    end
end
FacBuildModeCtrl._ConfirmLogistic = HL.Method() << function(self)
    self:_Tick()
    if not self.m_curBuildIsValid then
        Notify(MessageConst.SHOW_TOAST, self.view.errorHintText.text)
        return
    end
    local mousePos = self:_GetCurPointerPressPos()
    GameInstance.remoteFactoryManager:GridPositionTriggered(mousePos, 0)
    self:_ExitLogisticMode()
end
FacBuildModeCtrl._CancelLogistic = HL.Method(HL.Opt(HL.Boolean)) << function(self, skipAnim)
    local onCancel = self.m_buildArgs.onCancel
    if onCancel then
        onCancel()
    end
    self:_ExitLogisticMode(skipAnim)
end
FacBuildModeCtrl._EnterBeltMode = HL.Method(HL.Table) << function(self, args)
    if self.m_mode == FacConst.FAC_BUILD_MODE.Belt then
        if self.m_buildArgs.onExit then
            self.m_buildArgs.onExit()
        end
        self:_SetCamState()
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Logistic then
        self:_ExitLogisticMode()
    elseif self.m_mode == FacConst.FAC_BUILD_MODE.Building then
        self:_ExitBuildingMode()
    end
    self.m_isDragging = false
    self.m_mode = FacConst.FAC_BUILD_MODE.Belt
    self.m_buildArgs = args
    self.m_beltId = args.beltId
    local isPipe = self:_IsPipe()
    if DeviceInfo.usingTouch and LuaSystemManager.facSystem.inTopView then
        GameInstance.remoteFactoryManager:SetupConveyorInteractMode(CS.Beyond.Gameplay.RemoteFactory.ConveyorInteractMode.TraceDrag)
    else
        GameInstance.remoteFactoryManager:SetupConveyorInteractMode(CS.Beyond.Gameplay.RemoteFactory.ConveyorInteractMode.Precise)
    end
    GameInstance.remoteFactoryManager.interact:SwitchToConveyorMode(self.m_beltId)
    self:_RefreshKeyHint(isPipe and KeyHints.pipeStart or KeyHints.beltStart)
    local mark = isPipe and self.m_pipePreviewMark or self.m_beltStartPreviewMark
    mark.gameObject:SetActive(true)
    self:_UpdateBPStartPreviewMark(self:_GetCurPointerPressPos(), true)
    self:_UpdateValidResult()
    Notify(MessageConst.ON_BUILD_MODE_CHANGE, self.m_mode)
    Notify(MessageConst.ON_ENTER_BELT_MODE)
    self:_UpdateCommonNodesOnEnterMode()
    if isPipe then
        local data = Tables.factoryLiquidPipeTable[self.m_beltId].pipeData
        self:_SetCamState(data.buildCamState)
    else
        local data = Tables.factoryGridBeltTable[self.m_beltId].beltData
        self:_SetCamState(data.buildCamState)
    end
    if DeviceInfo.usingTouch then
        LuaSystemManager.facSystem.canMoveCamTarget = false
    end
end
FacBuildModeCtrl._ExitBeltMode = HL.Method(HL.Opt(HL.Boolean)) << function(self, skipAnim)
    self.m_mode = FacConst.FAC_BUILD_MODE.Normal
    local mark = self:_IsPipe() and self.m_pipePreviewMark or self.m_beltStartPreviewMark
    mark.transform:DOKill()
    mark.gameObject:SetActive(false)
    self.view.errorHint.gameObject:SetActiveIfNecessary(false)
    local onExit = self.m_buildArgs.onExit
    self:_ClearArgs()
    GameInstance.remoteFactoryManager.interact:ExitCurrentMode()
    FactoryUtils.stopLogisticFigureRenderer()
    local exitAct = function()
        self:Hide()
        if onExit then
            onExit()
        end
        Notify(MessageConst.ON_EXIT_BELT_MODE)
        Notify(MessageConst.ON_BUILD_MODE_CHANGE, self.m_mode)
    end
    if not skipAnim then
        self:PlayAnimationOutWithCallback(exitAct)
    else
        exitAct()
    end
    if DeviceInfo.usingTouch then
        LuaSystemManager.facSystem.canMoveCamTarget = true
    end
end
FacBuildModeCtrl.m_bpStartPreviewMarkLastPos = HL.Field(HL.Userdata)
FacBuildModeCtrl.m_bpStartPreviewMarkLastColor = HL.Field(Color)
FacBuildModeCtrl._UpdateBPStartPreviewMark = HL.Method(Vector3, HL.Opt(HL.Boolean)) << function(self, curMousePos, isInit)
    local camRay = CameraManager.mainCamera:ScreenPointToRay(curMousePos)
    local _, worldPos = CSFactoryUtil.SampleLevelRegionPointWithRay(camRay)
    self:_UpdateBPStartPreviewMarkWithWorldPos(worldPos, isInit)
end
FacBuildModeCtrl._UpdateBPStartPreviewMarkWithWorldPos = HL.Method(Vector3, HL.Opt(HL.Boolean)) << function(self, worldPos, isInit)
    local visual = GameInstance.remoteFactoryManager.visual
    local beltPos = visual:WorldToBeltGrid(worldPos)
    local roundedWorldPos = visual:BeltGridToWorld(Vector2(lume.round(beltPos.x), lume.round(beltPos.y)))
    roundedWorldPos.y = worldPos.y
    local isPipe = self:_IsPipe()
    local mark = isPipe and self.m_pipePreviewMark or self.m_beltStartPreviewMark
    local trans = mark.transform
    if isInit then
        trans.position = roundedWorldPos
        self.m_bpStartPreviewMarkLastPos = nil
    else
        if not self.m_bpStartPreviewMarkLastPos or (roundedWorldPos - self.m_bpStartPreviewMarkLastPos).sqrMagnitude >= 0.01 then
            trans.position = roundedWorldPos
            self.m_bpStartPreviewMarkLastPos = roundedWorldPos
            AudioAdapter.PostEvent("au_ui_belt_move")
        end
    end
    local color
    if self.m_curBuildIsValid then
        local foundTarget, targetNodeId, templateId = CSFactoryUtil.GetBuildingAtPos(roundedWorldPos, true)
        local hasStart = GameInstance.remoteFactoryManager.interact.currentConveyorMode.hasStart
        if not foundTarget then
            if hasStart then
                color = mark.config.VALID_COLOR
            else
                color = mark.config.NORMAL_COLOR
            end
        else
            local isBuilding, buildingData = Tables.factoryBuildingTable:TryGetValue(templateId)
            if isBuilding then
                local ports = hasStart and buildingData.inputPorts or buildingData.outputPorts
                local hasPort
                if ports then
                    for _, v in pairs(ports) do
                        if v.isPipe == isPipe then
                            hasPort = true
                            break
                        end
                    end
                end
                if hasPort then
                    if isPipe then
                        if buildingData.type == GEnums.FacBuildingType.MachineCrafter then
                            if CSFactoryUtil.IsNodeInLiquidMode(targetNodeId) then
                                color = mark.config.VALID_COLOR
                            else
                                color = mark.config.INVALID_COLOR
                            end
                        else
                            color = mark.config.VALID_COLOR
                        end
                    else
                        color = mark.config.VALID_COLOR
                    end
                else
                    color = mark.config.INVALID_COLOR
                end
            else
                local logisticData, isLiquid = FactoryUtils.getLogisticData(templateId)
                if logisticData and isLiquid == isPipe then
                    color = mark.config.VALID_COLOR
                else
                    color = mark.config.INVALID_COLOR
                end
            end
        end
    else
        color = mark.config.INVALID_COLOR
    end
    if isInit or color ~= self.m_bpStartPreviewMarkLastColor then
        self.m_bpStartPreviewMarkLastColor = color
        for _, mat in ipairs(mark.mats) do
            mat:SetColor("_TintColor", color)
        end
    end
end
FacBuildModeCtrl.OnInteractConveyorLocalCheckingFailed = HL.Method(HL.Table) << function(self, args)
    self:_UpdateValidResult()
    if not self.m_curBuildIsValid then
        Notify(MessageConst.SHOW_TOAST, self.view.errorHintText.text)
    end
end
FacBuildModeCtrl._GetCurPointerPressPos = HL.Method().Return(Vector3) << function(self)
    if not InputManager.cursorVisible or (DeviceInfo.usingTouch and not LuaSystemManager.facSystem.inTopView) then
        return Vector3(Screen.width / 2, Screen.height / 2, 0)
    end
    return InputManager.mousePosition
end
FacBuildModeCtrl._InDragMode = HL.Method().Return(HL.Boolean) << function(self)
    return DeviceInfo.usingTouch and LuaSystemManager.facSystem.inTopView
end
FacBuildModeCtrl.m_enableConfirmBuild = HL.Field(HL.Boolean) << true
FacBuildModeCtrl.SetEnableConfirmBuild = HL.Method(HL.Table) << function(self, args)
    local enable = unpack(args)
    self.m_enableConfirmBuild = enable
end
FacBuildModeCtrl.m_enableExitBuildMode = HL.Field(HL.Boolean) << true
FacBuildModeCtrl.SetEnableExitBuildMode = HL.Method(HL.Table) << function(self, args)
    local enable = unpack(args)
    self.m_enableExitBuildMode = enable
end
FacBuildModeCtrl.m_lockBuildPos = HL.Field(HL.Boolean) << false
FacBuildModeCtrl.FacLockBuildPos = HL.Method(HL.Table) << function(self, arg)
    local isLock = unpack(arg)
    self.m_lockBuildPos = isLock
end
HL.Commit(FacBuildModeCtrl)