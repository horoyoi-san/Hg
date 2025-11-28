local LuaSystemBase = require_ex('LuaSystem/LuaSystemBase')
FacLuaSystem = HL.Class('FacLuaSystem', LuaSystemBase.LuaSystemBase)
FacLuaSystem.FacLuaSystem = HL.Constructor() << function(self)
    self:RegisterMessage(MessageConst.FAC_TOGGLE_TOP_VIEW, function(arg)
        local active = false
        if type(arg) == "table" then
            active = unpack(arg)
        else
            active = arg
        end
        self:ToggleTopView(active)
    end)
    self:RegisterMessage(MessageConst.ON_TELEPORT_TO, function(arg)
        if self.inTopView then
            self:ToggleTopView(false, true)
        end
    end)
    self:RegisterMessage(MessageConst.FORBID_SYSTEM_CHANGED, function(args)
        local type, active = unpack(args)
        if type == ForbidType.ForbidFactoryMode and active then
            if Utils.isInFactoryMode() then
                Notify(MessageConst.EXIT_FACTORY_MODE)
            end
        end
    end)
    self:RegisterMessage(MessageConst.ON_ENTER_FAC_MAIN_REGION, function(arg)
        CS.Beyond.Gameplay.Audio.AudioRemoteFactoryBridge.OnEnterFactoryMainRegionChanged(true, arg)
        self:StartCheckPowerNotEnoughAudio()
    end)
    self:RegisterMessage(MessageConst.ON_EXIT_FAC_MAIN_REGION, function(arg)
        CS.Beyond.Gameplay.Audio.AudioRemoteFactoryBridge.OnEnterFactoryMainRegionChanged(false, arg)
        self:StopCheckPowerNotEnoughAudio()
    end)
    self.batchSelectTargets = {}
end
FacLuaSystem.OnInit = HL.Override() << function(self)
end
FacLuaSystem.OnRelease = HL.Override() << function(self)
    if self.m_topViewCamCtrl then
        self.m_topViewCamCtrl.onZoom = nil
        CameraManager:RemoveCameraController(self.m_topViewCamCtrl)
        self.m_topViewCamCtrl = nil
    end
    if self.topViewCamTarget then
        GameObject.Destroy(self.topViewCamTarget.gameObject)
        self.topViewCamTarget = nil
    end
end
FacLuaSystem.inDestroyMode = HL.Field(HL.Boolean) << false
FacLuaSystem.inTopView = HL.Field(HL.Boolean) << false
FacLuaSystem.isTopViewHideUIMode = HL.Field(HL.Boolean) << false
FacLuaSystem.topViewCamTarget = HL.Field(Transform)
FacLuaSystem.m_topViewCamCtrl = HL.Field(CS.Beyond.Gameplay.View.FacTopViewCameraController)
FacLuaSystem.ToggleTopView = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, active, fastMode)
    if active and not Utils.isInFacMainRegion() then
        return
    end
    if active == self.inTopView then
        return
    end
    Notify(MessageConst.FAC_EXIT_DESTROY_MODE)
    Notify(MessageConst.FAC_BUILD_EXIT_CUR_MODE)
    self.inTopView = active
    if self.isTopViewHideUIMode then
        self:ToggleTopViewHideUIMode(false)
    end
    Notify(MessageConst.TOGGLE_FORBID_ATTACK, { "FacTopView", active })
    GameInstance.player.forbidSystem:SetForbid(ForbidType.DisableSwitchMode, "FacTopView", active)
    GameInstance.player.forbidSystem:SetForbid(ForbidType.ShowEmptySwitchModeBtn, "FacTopView", active)
    GameInstance.playerController:OnToggleFactoryTopView(active)
    GameInstance.remoteFactoryManager:ChangeTopViewState(active)
    CS.Beyond.NPC.NPCCrowdModuleManager.PauseModule(active)
    local _, panel = UIManager:IsOpen(PanelId.LevelCamera)
    local levelCamCtrl
    if panel then
        levelCamCtrl = panel.m_curFreeLookCamCtrl
    end
    if active then
        if not self.topViewCamTarget then
            self.topViewCamTarget = GameObject("TopViewCamTarget").transform
            GameObject.DontDestroyOnLoad(self.topViewCamTarget.gameObject)
        end
        local topViewCamCtrl = CameraManager:LoadPersistentController("FacTopViewCamera")
        topViewCamCtrl:SetTarget(self.topViewCamTarget)
        local mainCharRoot = GameInstance.playerController.mainCharacter.rootCom
        local duration = topViewCamCtrl:StartEnterTween(mainCharRoot.transform.position)
        if duration > 0 then
            Notify(MessageConst.SHOW_BLOCK_INPUT_PANEL, duration)
        end
        self.m_topViewCamCtrl = topViewCamCtrl
        self.m_topViewCamCtrl.onZoom = function(zoomPercent)
            Notify(MessageConst.ON_FAC_TOP_VIEW_CAM_ZOOM, zoomPercent)
        end
        CSFactoryUtil.ChangeFacEcsCullingSetting(120, 100)
        if fastMode then
            logger.error("进入俯瞰模式暂不支持瞬切")
        end
    else
        if self.m_topViewCamCtrl then
            self.m_topViewCamCtrl.onZoom = nil
            if not fastMode then
                Notify(MessageConst.PREPARE_BLOCK_GLITCH_TRANSITION)
            end
            if levelCamCtrl then
                levelCamCtrl.param:SetHorizontalAngle(self.m_topViewCamCtrl.transform.eulerAngles.y, false)
                levelCamCtrl.param:SetVerticalValue(0.5, false)
            end
            CameraManager:RemoveCameraController(self.m_topViewCamCtrl)
            self.m_topViewCamCtrl = nil
            if not fastMode then
                Notify(MessageConst.SHOW_BLOCK_GLITCH_TRANSITION)
            end
        end
        CSFactoryUtil.ResetFacEcsCullingSetting()
    end
    if active then
        UIManager:ClearScreenWithOutAnimation(function(clearScreenKey)
            self:_StartTimer(0.6, function()
                Notify(MessageConst.ON_TOGGLE_FAC_TOP_VIEW, true)
                UIManager:RecoverScreen(clearScreenKey)
            end)
        end)
    else
        Notify(MessageConst.ON_TOGGLE_FAC_TOP_VIEW, false)
    end
end
FacLuaSystem.ToggleTopViewHideUIMode = HL.Method(HL.Boolean) << function(self, active)
    self.isTopViewHideUIMode = active
    Notify(MessageConst.ON_FAC_TOP_VIEW_HIDE_UI_MODE_CHANGE, active)
end
FacLuaSystem.canMoveCamTarget = HL.Field(HL.Boolean) << true
FacLuaSystem.MoveTopViewCamTarget = HL.Method(Vector2) << function(self, dir)
    if dir == Vector2.zero then
        return
    end
    if not self.canMoveCamTarget then
        return
    end
    local target = self.topViewCamTarget
    if not target then
        return
    end
    local settingSpeed = DataManager.gameplayCameraSetting.cameraSettingTopViewControlSpeedCurve:Evaluate(CS.Beyond.GameSetting.controllerCachedCameraTopViewSpeed)
    dir = dir * settingSpeed
    local camTrans = CameraManager.mainCamera.transform
    local realDir = dir.x * camTrans.right + dir.y * camTrans.up
    realDir.y = 0
    local zoomScale = 1 + (0.5 - self.m_topViewCamCtrl.curZoomPercent) * 0.8
    target.position = FactoryUtils.clampTopViewCamTargetPosition(target.position + realDir.normalized * dir.magnitude * zoomScale, target.position)
    Notify(MessageConst.ON_FAC_TOP_VIEW_CAM_TARGET_MOVED)
end
FacLuaSystem.RotateTopViewCam = HL.Method() << function(self)
    if not self.m_topViewCamCtrl then
        return
    end
    local angle = math.floor((self.topViewCamTarget.eulerAngles.y - 45) / 90) * 90
    self.topViewCamTarget:DORotate(Vector3(90, angle, 0), 0.5)
end
FacLuaSystem.GetTopViewCamZoomValue = HL.Method().Return(HL.Number) << function(self)
    if not self.m_topViewCamCtrl then
        return -1
    end
    return self.m_topViewCamCtrl.curZoom
end
FacLuaSystem.inBatchSelectMode = HL.Field(HL.Boolean) << false
FacLuaSystem.inDragSelectBatchMode = HL.Field(HL.Boolean) << false
FacLuaSystem.batchSelectTargets = HL.Field(HL.Table)
FacLuaSystem.interactPanelCtrl = HL.Field(HL.Forward('FacBuildingInteractCtrl'))
FacLuaSystem.m_checkPowerNotEnoughAudioTimerId = HL.Field(HL.Number) << -1
FacLuaSystem.StartCheckPowerNotEnoughAudio = HL.Method() << function(self)
    self.m_checkPowerNotEnoughAudioTimerId = self:_StartTimer(Tables.factoryConst.checkPowerNotEnoughAudioDelay, function()
        local powerInfo = FactoryUtils.getCurRegionPowerInfo()
        if powerInfo ~= nil then
            local powerCost = powerInfo.powerCost
            local powerGen = powerInfo.powerGen
            if powerCost > powerGen then
                CS.Beyond.Gameplay.Audio.AudioRemoteFactoryAnnouncement.Announcement("au_fac_announcement_low_power")
            end
        end
    end)
end
FacLuaSystem.StopCheckPowerNotEnoughAudio = HL.Method() << function(self)
    self.m_checkPowerNotEnoughAudioTimerId = self:_ClearTimer(self.m_checkPowerNotEnoughAudioTimerId)
end
HL.Commit(FacLuaSystem)
return FacLuaSystem