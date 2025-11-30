local phaseBase = require_ex('Phase/Core/PhaseBase')
local PHASE_ID = PhaseId.CharInfo
local OVERRIDE_CAMERA_PATH = "OverrideCameras/"
PhaseCharInfo = HL.Class('PhaseCharInfo', phaseBase.PhaseBase)
local PHASE_CHAR_INFO_GAME_OBJECT = "CharInfoChar"
local PHASE_CHAR_INFO_CAM_ATTACHMENT = "CharInfoCamAttachment"
local PAGE_TYPE_2_PANEL_ID = { [UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW] = { PanelId.CharInfo, }, [UIConst.CHAR_INFO_PAGE_TYPE.WEAPON] = { PanelId.CharInfo, PanelId.CharInfoWeapon, }, [UIConst.CHAR_INFO_PAGE_TYPE.EQUIP] = { PanelId.CharInfo, PanelId.CharInfoEquipSlot, PanelId.CharInfoEquip, }, [UIConst.CHAR_INFO_PAGE_TYPE.TALENT] = { PanelId.CharInfoTalentUpgrade, PanelId.CharInfoTalent, }, [UIConst.CHAR_INFO_PAGE_TYPE.PROFILE] = { PanelId.CharInfo, PanelId.CharInfoProfile, }, [UIConst.CHAR_INFO_PAGE_TYPE.UPGRADE] = { PanelId.CharUpgrade, }, [UIConst.CHAR_INFO_PAGE_TYPE.PROFILE_SHOW] = { PanelId.CharInfoProfileShow, }, [UIConst.CHAR_INFO_PAGE_TYPE.POTENTIAL] = { PanelId.CharInfo, PanelId.CharInfoPotential, } }
local PANEL_IN_SCENE = { [PanelId.CharInfoTalent] = true, }
local PAGE_CREATE_IN_ADVANCE = { [UIConst.CHAR_INFO_PAGE_TYPE.TALENT] = true, }
local CLOSE_WHEN_ANIMATION_OUT = { [PanelId.CharUpgrade] = true, [PanelId.CharUpgradeAttribute] = true, [PanelId.CharInfoFullAttribute] = true, [PanelId.CharInfoProfileShow] = true, [PanelId.CharInfoSkillUpgrade] = true, [PanelId.CharInfoEquipSlot] = true, [PanelId.CharInfoEquip] = true, [PanelId.CharInfoWeapon] = true, [PanelId.CharInfoPotential] = true, [PanelId.CharInfoProfile] = true, }
local PHASE_ITEMS = { "CharInfoChar", "CharInfoCamAttachment" }
local CAMERA_FORCE_FADE_TAB = { [UIConst.CHAR_INFO_PAGE_TYPE.WEAPON] = true, }
local CHARACTER_ANIMATOR_SKIP_IN_TAB = { [UIConst.CHAR_INFO_PAGE_TYPE.WEAPON] = true, [UIConst.CHAR_INFO_PAGE_TYPE.EQUIP] = true, [UIConst.CHAR_INFO_PAGE_TYPE.TALENT] = true, [UIConst.CHAR_INFO_PAGE_TYPE.PROFILE] = true, [UIConst.CHAR_INFO_PAGE_TYPE.UPGRADE] = true, [UIConst.CHAR_INFO_PAGE_TYPE.POTENTIAL] = true, }
local HIDE_GRID_PAGE_TYPE = { [UIConst.CHAR_INFO_PAGE_TYPE.UPGRADE] = true, [UIConst.CHAR_INFO_PAGE_TYPE.TALENT] = true, [UIConst.CHAR_INFO_PAGE_TYPE.PROFILE] = true, }
local PANEL_PRELOAD_ORDER = { PanelId.CharInfoEquip, PanelId.CharInfoWeapon, PanelId.CharInfoTalent, PanelId.WeaponExhibitUpgrade, PanelId.WeaponExhibitGem, }
PhaseCharInfo.s_messages = HL.StaticField(HL.Table) << { [MessageConst.P_CHAR_INFO_SELECT_CHAR_CHANGE] = { 'OnSelectCharChange' }, [MessageConst.P_CHAR_INFO_PAGE_CHANGE] = { 'OnPageChange' }, [MessageConst.P_CHAR_INFO_CLOSE_SHOW_CHAR] = { 'OnCharInfoShowCharClose' }, [MessageConst.P_CHAR_INFO_SHOW_ROTATE_CHAR] = { 'OnCharInfoShowRotateChar' }, [MessageConst.P_CHAR_INFO_SHOW_ZOOMING] = { 'OnCharInfoShowZooming' }, [MessageConst.P_CHAR_INFO_PROFILE_CLOSE] = { 'OnCharInfoProfileClose' }, [MessageConst.P_CHAR_INFO_EQUIP_SECOND_OPEN] = { 'OnCharInfoEquipSecondEnter' }, [MessageConst.P_CHAR_INFO_EQUIP_SECOND_CLOSE] = { 'OnCharInfoEquipSecondClose' }, [MessageConst.P_CHAR_INFO_WEAPON_SECOND_OPEN] = { 'OnCharInfoWeaponSecondEnter' }, [MessageConst.P_CHAR_INFO_WEAPON_SECOND_CLOSE] = { 'OnCharInfoWeaponSecondClose' }, [MessageConst.P_CHAR_INFO_PREVIEW_WEAPON] = { 'OnPreviewWeaponChange' }, [MessageConst.P_ON_COMMON_BACK_CLICKED] = { 'OnCommonBackClicked' }, [MessageConst.P_CHAR_INFO_BLEND_EXIT] = { '_BlendExitPhase' }, [MessageConst.CHAR_TALENT_FOCUS] = { 'OnCharTalentFocus', true }, [MessageConst.CHAR_TALENT_LEAVE_FOCUS] = { 'OnCharTalentLeaveFocus', true }, [MessageConst.PRE_LEVEL_START] = { 'OnPreLevelStart', false }, [MessageConst.ON_GEM_ATTACH] = { "OnGemAttach", true }, [MessageConst.ON_GEM_DETACH] = { 'OnGemDetach', true }, [MessageConst.ON_PUT_ON_WEAPON] = { 'OnPutOnWeapon', true }, [MessageConst.ON_WEAPON_REFINE] = { 'OnPutOnWeapon', true }, [MessageConst.ON_CHAR_LEVEL_UP] = { 'OnCharLevelUp', true }, [MessageConst.TOGGLE_CHAR_INFO_FOCUS_MODE] = { 'ToggleWeaponFocusMode', true }, [MessageConst.DEBUG_CHAR_INFO_SHOW_CHAR_SP] = { '_DebugShowCharSPMotion', true }, [MessageConst.ON_WEAPON_REFINE] = { 'OnWeaponRefine', true } }
do
    PhaseCharInfo.m_cachedPanels = HL.Field(HL.Table)
    PhaseCharInfo.m_charInfo = HL.Field(HL.Table)
    PhaseCharInfo.m_charInfoList = HL.Field(HL.Table)
    PhaseCharInfo.m_curPage = HL.Field(HL.Number) << UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW
    PhaseCharInfo.m_beforePage = HL.Field(HL.Number) << UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW
    PhaseCharInfo.m_skillTip = HL.Field(HL.Forward("PhasePanelItem"))
    PhaseCharInfo.m_charItem = HL.Field(HL.Forward("PhaseCharItem"))
    PhaseCharInfo.m_toggleUIKey = HL.Field(HL.Number) << -1
    PhaseCharInfo.m_isInit = HL.Field(HL.Boolean) << false
    PhaseCharInfo.m_templateId2DollyTrackPathGroup = HL.Field(HL.Table)
    PhaseCharInfo.m_templateId2LightGroup = HL.Field(HL.Table)
    PhaseCharInfo.m_templateId2LightFollowers = HL.Field(HL.Table)
    PhaseCharInfo.m_templateId2VolumeGroup = HL.Field(HL.Table)
    PhaseCharInfo.m_charVolumeTween = HL.Field(HL.Userdata)
    PhaseCharInfo.m_trackDollyTween = HL.Field(HL.Userdata)
    PhaseCharInfo.m_zoomCache = HL.Field(HL.Any)
    PhaseCharInfo.m_curPreviewWeaponInstId = HL.Field(HL.Number) << 0
    PhaseCharInfo.m_lookAtTickKey = HL.Field(HL.Number) << -1
    PhaseCharInfo.m_isBlendExit = HL.Field(HL.Boolean) << false
    PhaseCharInfo.m_lastCamAnimName = HL.Field(HL.String) << ""
    PhaseCharInfo.m_lookAtTween = HL.Field(HL.Userdata)
    PhaseCharInfo.m_uiEffectCor = HL.Field(HL.Thread)
    PhaseCharInfo.m_sceneEffectCor = HL.Field(HL.Thread)
    PhaseCharInfo.m_weaponDecoEffectCor = HL.Field(HL.Thread)
    PhaseCharInfo.m_blendTransitionCor = HL.Field(HL.Thread)
    PhaseCharInfo.m_spMotionCor = HL.Field(HL.Thread)
    PhaseCharInfo.m_spMotionUpdateKey = HL.Field(HL.Any)
    PhaseCharInfo.m_voiceCor = HL.Field(HL.Thread)
    PhaseCharInfo.m_charItemInitComplete = HL.Field(HL.Boolean) << false
    PhaseCharInfo.m_preloadCor = HL.Field(HL.Thread)
    PhaseCharInfo.m_hideCamCor = HL.Field(HL.Thread)
end
PhaseCharInfo._OnInit = HL.Override() << function(self)
    PhaseCharInfo.Super._OnInit(self)
    CS.HG.Rendering.ScriptBridge.HGRenderBridgeStatics.SetVFXPPPriorityFilterCinematic()
    CS.HG.Rendering.ScriptBridge.HGRenderBridgeStatics.SetSceneDarkEnabled(false)
end
PhaseCharInfo.PrepareTransition = HL.Override(HL.Number, HL.Boolean, HL.Opt(HL.Number)) << function(self, transitionType, fastMode, anotherPhaseId)
    if transitionType == PhaseConst.EPhaseState.TransitionIn then
        UIManager:PreloadPanelAsset(PanelId.CharInfo)
        UIManager:PreloadPanelAsset(PanelId.CharInfoCursor)
        UIManager:PreloadPanelAsset(PanelId.CharInfoEmpty)
        self.m_hideCamCor = PhaseManager:_ClearCoroutine(self.m_hideCamCor)
    end
    if not fastMode and (transitionType == PhaseConst.EPhaseState.TransitionIn or transitionType == PhaseConst.EPhaseState.TransitionOut) then
        coroutine.waitCondition(function()
            return true
        end, coroutine.TailTick)
        if transitionType == PhaseConst.EPhaseState.TransitionOut then
            for i, phasePanelItem in pairs(self.m_panel2Item) do
                local wrapper = phasePanelItem.uiCtrl:GetAnimationWrapper()
                wrapper:ClearTween()
            end
        end
        Notify(MessageConst.PREPARE_BLOCK_GLITCH_TRANSITION)
    end
    if transitionType == PhaseConst.EPhaseState.TransitionBackToTop then
        self.m_hideCamCor = PhaseManager:_ClearCoroutine(self.m_hideCamCor)
        self:_ToggleSceneLight(true)
        if self.m_templateId2DollyTrackPathGroup and self.m_charInfo then
            local targetGroup = self.m_templateId2DollyTrackPathGroup[self.m_charInfo.templateId]
            targetGroup.go:SetActive(true)
        end
        self.m_charItem:GetAnimator().speed = 1
    end
end
PhaseCharInfo.OnPreLevelStart = HL.StaticMethod() << function()
    PhaseManager:TryCacheGOByName(PHASE_ID, PHASE_CHAR_INFO_GAME_OBJECT)
end
PhaseCharInfo._DoPhaseTransitionIn = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    UIManager:Open(PanelId.CharInfoEmpty)
    if not fastMode then
        Notify(MessageConst.SHOW_BLOCK_GLITCH_TRANSITION)
    end
end
PhaseCharInfo._DoPhaseTransitionBackToTop = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseCharInfo._DoPhaseTransitionBehind = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    self:_ClearAudioCor()
    if self.m_charItem then
        self.m_charItem:GetAnimator().speed = 0
    end
    self.m_hideCamCor = PhaseManager:_ClearCoroutine(self.m_hideCamCor)
    self.m_hideCamCor = PhaseManager:_StartCoroutine(function()
        coroutine.wait(1)
        self:_CloseAllCamGroup()
        self:_ToggleSceneLight(false)
        Utils.disableCameraDOF()
    end)
end
PhaseCharInfo._DoPhaseTransitionOut = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    if not fastMode then
        Notify(MessageConst.SHOW_BLOCK_GLITCH_TRANSITION)
    end
end
PhaseCharInfo._OnActivated = HL.Override() << function(self)
    UIManager:Hide(PanelId.Touch)
    local arg = self.arg or {}
    local initCharInfo = arg.initCharInfo or self.m_charInfo or CharInfoUtils.getLeaderCharInfo()
    local pageType = arg.pageType or self.m_curPage or UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW
    local extraArg = arg.extraArg or {}
    local forceSkipIn = arg.forceSkipIn
    if forceSkipIn then
        arg.forceSkipIn = nil
    end
    arg.phase = self
    self:_InitPhase(initCharInfo, pageType, forceSkipIn)
    self:_SetListCameraDOF()
    self:_ToggleSceneLight(true)
    if UIManager:IsOpen(PanelId.CharInfoEmpty) then
        UIManager:Show(PanelId.CharInfoEmpty)
    else
        UIManager:Open(PanelId.CharInfoEmpty)
    end
    if self.m_isBlendExit then
        self.m_isBlendExit = false
        self:_BlendBackPhase()
    end
    if extraArg.slotType then
        Notify(MessageConst.ON_SELECT_SLOT_CHANGE, extraArg.slotType)
    end
    self:_StartPreloadCor()
end
PhaseCharInfo._OnDeActivated = HL.Override() << function(self)
    self:_ToggleCamAttachment(false)
    self:_ClearAudioCor()
    if self.m_preloadCor then
        self.m_preloadCor = PhaseManager:_ClearCoroutine(self.m_preloadCor)
    end
    if self.m_spMotionUpdateKey then
        LuaUpdate:Remove(self.m_spMotionUpdateKey)
        self.m_spMotionUpdateKey = nil
    end
    Utils.disableCameraDOF()
    UIManager:Hide(PanelId.CharInfoCursor)
    UIManager:Hide(PanelId.CharInfoEmpty)
end
PhaseCharInfo.CreateCharInfoPanel = HL.Method(HL.Number, HL.Opt(HL.Table)) << function(self, panelId, arg)
    local initPanel = self:CreatePhasePanelItem(panelId, arg)
    self.m_panel2Item[panelId] = initPanel
end
PhaseCharInfo.CloseCharInfoPanel = HL.Method(HL.Number) << function(self, panelId)
    if not self.m_panel2Item[panelId] then
        return
    end
    self:RemovePhasePanelItemById(panelId)
end
PhaseCharInfo._ResetCam = HL.Method() << function(self)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    if not sceneObject then
        return
    end
    sceneObject.view.charInfoWeaponCam.gameObject:SetActive(false)
    sceneObject.view.charInfoProfileCam.gameObject:SetActive(false)
    sceneObject.view.charInfoTalentFocusCam.gameObject:SetActive(false)
    sceneObject.view.charInfoBlendCam.gameObject:SetActive(false)
    self:_ClearShowCam()
end
PhaseCharInfo._OnDestroy = HL.Override() << function(self)
    UIManager:Show(PanelId.Touch)
    if self.m_skillTip then
        self.m_skillTip.uiCtrl:ClearTips()
    end
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    self:_ResetCam()
    self:_CleanupLookAtIK()
    sceneObject.view.charInfoPotentialStar.gameObject:SetActive(false)
    UIManager:Close(PanelId.CharInfoCursor)
    UIManager:Close(PanelId.CharInfoEmpty)
    CS.HG.Rendering.ScriptBridge.HGRenderBridgeStatics.SetVFXPPPriorityFilterNormal()
    CS.HG.Rendering.ScriptBridge.HGRenderBridgeStatics.SetSceneDarkEnabled(true)
    CSUtils.ClearUIComponents(sceneObject.view.gameObject)
end
PhaseCharInfo._InitPanels = HL.Method(HL.Table, HL.Number) << function(self, initCharInfo, pageType)
    local initPanels = PAGE_TYPE_2_PANEL_ID[pageType]
    if initPanels then
        for _, panelId in ipairs(initPanels) do
            self:CreatePhasePanelItem(panelId, { initCharInfo = initCharInfo, pageType = pageType, phase = self, })
        end
    end
end
PhaseCharInfo._InitGo = HL.Method(HL.Table, HL.Number) << function(self, charInfo, tabType)
    for _, name in ipairs(PHASE_ITEMS) do
        self:CreatePhaseGOItem(name)
    end
    self.m_templateId2DollyTrackPathGroup = {}
    self.m_templateId2LightGroup = {}
    self.m_templateId2LightFollowers = {}
    self.m_templateId2VolumeGroup = {}
    self.m_charInfo = charInfo
    self.m_beforePage = tabType
    self.m_curPage = tabType
    self:_SetActivePotentialItems(self.m_curPage == UIConst.CHAR_INFO_PAGE_TYPE.POTENTIAL)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local weaponDecoNode = sceneObject.view.weaponDecoNode
    weaponDecoNode.gameObject:SetActive(false)
end
PhaseCharInfo._InitCharacter = HL.Method(HL.Table, HL.Number, HL.Opt(HL.Boolean)) << function(self, charInfo, pageType, forceSkipIn)
    local templateId = charInfo.templateId
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local curWeaponInstId = CharInfoUtils.getCharCurWeapon(self.m_charInfo.instId).weaponInstId
    self.m_curPreviewWeaponInstId = curWeaponInstId
    self:_RefreshCharModel(sceneObject, charInfo, pageType, forceSkipIn)
    self:_RefreshCamGroup(sceneObject, true, templateId, pageType)
    self:_RefreshAddonLight(sceneObject, true, templateId, pageType)
    self:_RefreshWeaponDeco({ pageType = pageType, })
    self:_RefreshVoiceTriggerVo(pageType)
    self:_TriggerCharBarkSwitch(pageType)
    if CharInfoUtils.getPlayerCharInfoByTemplateId(templateId, GEnums.CharType.Default) and RedDotManager:GetRedDotState("CharNew", templateId) then
        GameInstance.player.charBag:Send_RemoveCharNewTag(templateId)
    end
end
PhaseCharInfo._InitPhase = HL.Method(HL.Table, HL.Number, HL.Opt(HL.Boolean)) << function(self, initCharInfo, pageType, skipInAnim)
    if self.m_isInit then
        return
    end
    self.m_charInfoList = self:_GenerateCharInfoList(initCharInfo)
    self:_InitGo(initCharInfo, pageType)
    self:_InitPanels(initCharInfo, pageType)
    self:_InitCharacter(initCharInfo, pageType, skipInAnim)
    self:_ToggleCamAttachment(pageType == UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW)
    self.m_isInit = true
end
PhaseCharInfo._GenerateCharInfoList = HL.Method(HL.Table).Return(HL.Table) << function(self, initCharInfo)
    local charInfoList
    if initCharInfo.isSingleChar then
        charInfoList = CharInfoUtils.getSingleCharInfoList(initCharInfo.instId)
        local singleCharInfo = charInfoList[1]
        if singleCharInfo then
            singleCharInfo.isShowFixed = initCharInfo.isShowFixed
            singleCharInfo.isShowTrail = initCharInfo.isShowTrail
        end
    elseif initCharInfo.charInstIdList then
        charInfoList = CharInfoUtils.getCharInfoListByInstIdList(initCharInfo.charInstIdList)
    else
        local isFullLockedTeam, formationData = CharInfoUtils.IsFullLockedTeam()
        if isFullLockedTeam then
            charInfoList = {}
            for _, char in pairs(formationData.chars) do
                local charInfo = CharInfoUtils.getPlayerCharInfoByTemplateId(char.charId, char.isTrail and GEnums.CharType.Trial or GEnums.CharType.Default)
                if charInfo then
                    local templateId = charInfo.templateId
                    local charCfg = Tables.characterTable:GetValue(templateId)
                    local isShowFixed, isShowTrail = CharInfoUtils.getLockedFormationCharTipsShow(char)
                    local item = { instId = charInfo.instId, templateId = templateId, ownTime = charInfo.ownTime, level = charInfo.level, rarity = charCfg.rarity, slotIndex = Const.BATTLE_SQUAD_MAX_CHAR_NUM + 1, slotReverseIndex = -1, sortOrder = charCfg.sortOrder, isShowFixed = isShowFixed, isShowTrail = isShowTrail, }
                    table.insert(charInfoList, item)
                end
            end
        else
            charInfoList = CharInfoUtils.getCharInfoList()
            if formationData then
                for _, charFormationInfo in pairs(formationData.chars) do
                    local isShowFixed, isShowTrail = CharInfoUtils.getLockedFormationCharTipsShow(charFormationInfo)
                    for _, charInfo in pairs(charInfoList) do
                        if charInfo.templateId == charFormationInfo.charId and CharInfoUtils.checkIsCardInTrail(charInfo.instId) then
                            charInfo.isShowTrail = isShowTrail
                            charInfo.isShowFixed = isShowFixed
                        end
                    end
                end
            end
        end
    end
    return charInfoList
end
PhaseCharInfo.OnCommonBackClicked = HL.Method() << function(self)
    self.m_uiEffectCor = PhaseManager:_ClearCoroutine(self.m_uiEffectCor)
    self.m_sceneEffectCor = PhaseManager:_ClearCoroutine(self.m_sceneEffectCor)
    AudioAdapter.PostEvent("Au_UI_Menu_CharInfoPanel_Close")
    self:CloseSelf()
end
PhaseCharInfo._RefreshCharModel = HL.Method(HL.Userdata, HL.Table, HL.Number, HL.Opt(HL.Boolean)) << function(self, sceneObject, initCharInfo, mainControlTab, forceSkipIn)
    self:RemoveAllPhaseCharItems()
    local templateId = initCharInfo.templateId
    local data = { charInstId = initCharInfo.instId, charId = templateId, pos = Vector3.zero, }
    local shadowPlane = sceneObject.view.shadowPlane
    local shadowMat = shadowPlane.material
    local charDisplayData = CharInfoUtils.getCharDisplayData(templateId)
    local charHeight = charDisplayData.height
    local charHeightData = CharInfoUtils.getCharHeightData(charHeight)
    local shadowFadeConfig = charHeightData.charInfoShadowFadeConfig
    local skipIn = forceSkipIn == true or CHARACTER_ANIMATOR_SKIP_IN_TAB[mainControlTab]
    self.m_charItemInitComplete = false
    self:_RefreshCharModelAddon(sceneObject, initCharInfo)
    self:CreatePhaseCharItem(data, sceneObject.view.charContainer, function(phaseItem)
        self.m_charItemInitComplete = true
        self.m_charItem = phaseItem
        if shadowMat and shadowFadeConfig then
            shadowMat:SetFloat("_CircleFade", charHeightData.isShadowFadeInCharInfo and 1 or 0)
            shadowMat:SetFloat("_CircleFadeDistance", shadowFadeConfig.circleFadeDistance)
            shadowMat:SetFloat("_CircleFadeSmoothness", shadowFadeConfig.circleFadeSmoothness)
        end
        local fromStateIndex, toStateIndex = self:_GetControllerStateIndex(self.m_curPage, self.m_curPage)
        local weaponState = CS.Beyond.Gameplay.View.CharUIModelMono.WeaponState.HIDE
        phaseItem:ReloadWeapon()
        phaseItem:SwitchWeaponState(weaponState)
        if fromStateIndex and toStateIndex then
            self:_SwitchCharacterControllerState(phaseItem, fromStateIndex, toStateIndex, skipIn)
        end
        local animator = phaseItem:GetAnimator()
        animator:Update(0)
        local decoItems = phaseItem.uiModelMono.decoItems
        if decoItems then
            for _, deco in pairs(decoItems) do
                deco.animator:Update(0)
            end
        end
        local targetLightGroup = self.m_templateId2LightGroup[templateId]
        phaseItem.uiModelMono:InitLightFollower(targetLightGroup.go.transform)
        self:_PlayModelEffect(sceneObject, templateId)
    end)
end
PhaseCharInfo._RefreshCharModelAddon = HL.Method(HL.Userdata, HL.Table) << function(self, sceneObject, initCharInfo)
    local templateId = initCharInfo.templateId
    local charDisplayData = CharInfoUtils.getCharDisplayData(templateId)
    if not self.m_templateId2DollyTrackPathGroup[templateId] and not string.isEmpty(charDisplayData.charInfoCameraGroup) then
        local cameraGroup = self:CreatePhaseGOItem(charDisplayData.charInfoCameraGroup)
        if cameraGroup ~= nil then
            cameraGroup.go.transform:SetParent(sceneObject.view.charContainer)
            cameraGroup.go.transform.localPosition = Vector3.zero
            cameraGroup.go.transform.localEulerAngles = Vector3.zero
            if UNITY_EDITOR then
                local cinemachineWaypointGroup = cameraGroup.go:AddComponent(typeof(CS.Beyond.DevTools.CinemachineWaypointGroup))
                if cinemachineWaypointGroup then
                    cinemachineWaypointGroup:SyncWaypointChange()
                end
            end
            local extraCams = cameraGroup.view.extraCams
            extraCams.extra_cam_equip_second.gameObject:SetActive(false)
            extraCams.extra_cam_weapon_second.gameObject:SetActive(false)
            self.m_templateId2DollyTrackPathGroup[templateId] = cameraGroup
            cameraGroup.go:SetActive(false)
            local volumeGroup = cameraGroup.view.volumeModifiers
            if volumeGroup then
                self.m_templateId2VolumeGroup[templateId] = volumeGroup
            end
        end
    end
    if not self.m_templateId2LightGroup[templateId] and not string.isEmpty(charDisplayData.charInfoLightGroup) then
        local lightGroup = self:CreatePhaseGOItem(charDisplayData.charInfoLightGroup)
        if lightGroup ~= nil then
            if UNITY_EDITOR then
                local additionLightGroup = lightGroup.go:AddComponent(typeof(CS.Beyond.DevTools.AdditionalLightGroup))
            end
            lightGroup.go.transform:SetParent(sceneObject.view.charContainer)
            lightGroup.go.transform.localPosition = Vector3.zero
            lightGroup.go.transform.localEulerAngles = Vector3.zero
            self.m_templateId2LightGroup[templateId] = lightGroup
        end
    end
    self:_RefreshCamAttachment(templateId)
end
PhaseCharInfo._PlayModelEffect = HL.Method(HL.Any, HL.String) << function(self, sceneObject, charId)
    if string.isEmpty(charId) then
        return
    end
    local parent = sceneObject.view.singleEffects
    local charDisplayData = CharInfoUtils.getCharDisplayData(charId)
    if charDisplayData then
        local height = LuaIndex(charDisplayData.height:ToInt())
        parent = parent[string.format("effect%d", height)]
    end
    local effect = sceneObject.view.charEffect
    effect.transform:SetParent(parent)
    effect.transform.localPosition = Vector3.zero
    effect.transform.localEulerAngles = Vector3.zero
    effect.transform.localScale = Vector3.one
    effect.gameObject:SetActive(true)
    effect:Play()
end
PhaseCharInfo._RefreshCamAttachment = HL.Method(HL.String) << function(self, templateId)
    local pathGroup = self.m_templateId2DollyTrackPathGroup[templateId]
    local camPostfix = UIConst.CHAR_INFO_MAIN_CONTROL_PAGE_2_CAMERA_POSTFIX[UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW]
    local targetCam = pathGroup.view.cameraGroup["vcam_" .. camPostfix]
    local lookAtTarget = pathGroup.view.lookAtGroup["lookat_" .. camPostfix]
    local attachmentObj = self.m_gameObject2Item[PHASE_CHAR_INFO_CAM_ATTACHMENT]
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    attachmentObj.go.transform:SetParent(lookAtTarget.transform.parent)
    attachmentObj.go.transform.localPosition = lookAtTarget.transform.localPosition
    attachmentObj.go.transform.localEulerAngles = lookAtTarget.transform.localEulerAngles
    attachmentObj.go.transform.localRotation = targetCam.transform.localRotation
    attachmentObj.go.transform:SetParent(sceneObject.view.charContainer.transform)
    local sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_INFO, UIConst.UI_CHAR_INFO_CHAR_BG_PREFIX .. templateId)
    attachmentObj.view.charTexture.gameObject:SetActive(sprite ~= nil)
    if sprite then
        attachmentObj.view.charTexture.sprite = sprite
    end
end
PhaseCharInfo._ToggleCamAttachment = HL.Method(HL.Boolean) << function(self, isOn)
    local attachmentObj = self.m_gameObject2Item[PHASE_CHAR_INFO_CAM_ATTACHMENT]
    if attachmentObj then
        attachmentObj.go:SetActive(isOn)
    end
end
PhaseCharInfo.OnSelectCharChange = HL.Method(HL.Table) << function(self, charInfo)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local templateId = charInfo.templateId
    local curControlTab = self.m_curPage
    local curWeaponInstId = CharInfoUtils.getCharCurWeapon(charInfo.instId).weaponInstId
    self.m_curPreviewWeaponInstId = curWeaponInstId
    self.m_charInfo = charInfo
    self.m_lastCamAnimName = ""
    local isFastCam = true
    if CAMERA_FORCE_FADE_TAB[curControlTab] then
        isFastCam = false
    end
    self:_CleanupLookAtIK()
    self:_RefreshCharModel(sceneObject, charInfo, curControlTab)
    self:_RefreshCamGroup(sceneObject, isFastCam, templateId, self.m_curPage)
    self:_RefreshAddonLight(sceneObject, true, templateId, self.m_curPage, self.m_curPage)
    self:_RefreshVoiceTriggerVo(self.m_curPage)
    self:_TriggerCharBarkSwitch(self.m_curPage)
    self:_RefreshWeaponDeco({ pageType = self.m_curPage, })
    self:_RefreshShowCamTargetGroup()
end
PhaseCharInfo.OnPageChange = HL.Method(HL.Any) << function(self, arg)
    if not self.m_charItemInitComplete then
        logger.info(ELogChannel.GamePlay, "PhaseCharItemLoading, forbid page change")
        return
    end
    local pageType = arg.pageType
    local isFast = arg.isFast == true
    local extraArg = arg.extraArg
    local phaseItem = self.m_charItem
    local beforePage = self.m_curPage
    self.m_beforePage = beforePage
    self.m_curPage = pageType
    local showGlitch = arg.showGlitch
    if showGlitch then
        isFast = true
    end
    local isAnimatorFast = isFast
    local isCamFast = isFast
    local pauseAnimator = false
    if pageType == UIConst.CHAR_INFO_PAGE_TYPE.POTENTIAL or beforePage == UIConst.CHAR_INFO_PAGE_TYPE.POTENTIAL then
        isAnimatorFast = true
        isCamFast = true
    end
    if pageType == UIConst.CHAR_INFO_PAGE_TYPE.POTENTIAL then
        pauseAnimator = true
    end
    if self.m_trackDollyTween then
        self.m_trackDollyTween:Kill()
    end
    self.m_uiEffectCor = PhaseManager:_ClearCoroutine(self.m_uiEffectCor)
    self.m_uiEffectCor = PhaseManager:_StartCoroutine(function()
        local neededPanels = PAGE_TYPE_2_PANEL_ID[pageType]
        if PAGE_CREATE_IN_ADVANCE[pageType] then
            for _, panelId in ipairs(neededPanels) do
                self:_CreateCharInfoPanel(panelId, pageType, extraArg)
            end
        end
        local neededPanelsBefore = PAGE_TYPE_2_PANEL_ID[beforePage]
        for i, v in pairs(neededPanelsBefore) do
            self:_Trigger_OnPageChange(v, pageType)
        end
        local waitOutDuration = self:_CloseOrHidePanel(neededPanels)
        coroutine.wait(waitOutDuration)
        self:_ShowPanel(neededPanels, pageType, extraArg)
    end)
    self.m_sceneEffectCor = PhaseManager:_ClearCoroutine(self.m_sceneEffectCor)
    self.m_sceneEffectCor = PhaseManager:_StartCoroutine(function()
        local templateId = self.m_charInfo.templateId
        local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
        if showGlitch then
            Notify(MessageConst.PREPARE_BLOCK_GLITCH_TRANSITION)
            Notify(MessageConst.SHOW_BLOCK_GLITCH_TRANSITION)
            coroutine.wait(0.2)
        end
        if pageType == UIConst.CHAR_INFO_PAGE_TYPE.PROFILE_SHOW then
            self:_PlayModelEffect(sceneObject, templateId)
        end
        if pageType == UIConst.CHAR_INFO_PAGE_TYPE.POTENTIAL or beforePage == UIConst.CHAR_INFO_PAGE_TYPE.POTENTIAL then
            self:_PlayModelEffect(sceneObject, templateId)
            coroutine.wait(0.2)
        end
        self:_ResetCam()
        local fromStateIndex, toStateIndex = self:_GetControllerStateIndex(beforePage, pageType)
        if (toStateIndex ~= nil and fromStateIndex ~= nil) and (isAnimatorFast or (toStateIndex ~= fromStateIndex)) then
            if phaseItem then
                self:_SwitchCharacterControllerState(phaseItem, fromStateIndex, toStateIndex, isAnimatorFast)
            end
        end
        local animator = phaseItem:GetAnimator()
        if pauseAnimator then
            animator.speed = 0
        else
            animator.speed = 1
        end
        self:_RefreshCamGroup(sceneObject, isCamFast, templateId, pageType, beforePage)
        self:_RefreshAddonLight(sceneObject, isCamFast, templateId, pageType, beforePage)
        self:_RefreshVoiceTriggerVo(pageType)
        self:_ToggleCamAttachment(pageType == UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW)
        self:_ToggleChrSPMotionCor(pageType == UIConst.CHAR_INFO_PAGE_TYPE.PROFILE_SHOW)
        self:_ToggleTalentFloorEffect(pageType == UIConst.CHAR_INFO_PAGE_TYPE.TALENT)
        self:_RefreshWeaponDeco({ pageType = pageType, beforePage = beforePage })
        local isWeaponDecoOn = pageType == UIConst.CHAR_INFO_PAGE_TYPE.WEAPON
        self:_ToggleWeaponDeco(isWeaponDecoOn, beforePage)
        self:_RefreshGridDeco({ pageType = pageType, })
        self:_RefreshCharUpgradeDeco(pageType)
        self:_RefreshShowCamTargetGroup()
        self:_RefreshProfileShowCam({ pageType = pageType, onlyShow = pageType == UIConst.CHAR_INFO_PAGE_TYPE.PROFILE_SHOW })
        self:_SetActivePotentialItems(pageType == UIConst.CHAR_INFO_PAGE_TYPE.POTENTIAL)
    end)
end
PhaseCharInfo._CloseOrHidePanel = HL.Method(HL.Table).Return(HL.Number) << function(self, neededPanels)
    local waitOutDuration = 0.2
    for panelId, panelItem in pairs(self.m_panel2Item) do
        if panelItem.uiCtrl:IsShow() and (not lume.find(neededPanels, panelId)) then
            local outDuration = panelItem.uiCtrl:GetAnimationOutDuration()
            waitOutDuration = math.max(waitOutDuration, outDuration)
            if CLOSE_WHEN_ANIMATION_OUT[panelId] then
                panelItem.uiCtrl:PlayAnimationOutWithCallback(function()
                    self:CloseCharInfoPanel(panelId)
                end)
            else
                panelItem.uiCtrl:PlayAnimationOut(UIConst.PANEL_PLAY_ANIMATION_OUT_COMPLETE_ACTION_TYPE.Hide)
            end
        end
    end
    return waitOutDuration
end
PhaseCharInfo._ShowPanel = HL.Method(HL.Table, HL.Number, HL.Opt(HL.Table)) << function(self, neededPanels, pageType, extraArg)
    for _, panelId in ipairs(neededPanels) do
        if not self.m_panel2Item[panelId] then
            self:_CreateCharInfoPanel(panelId, pageType, extraArg)
        else
            local panelItem = self.m_panel2Item[panelId]
            if HL.TryGet(panelItem.uiCtrl, "PhaseCharInfoPanelShowFinal") then
                panelItem.uiCtrl:PhaseCharInfoPanelShowFinal({ initCharInfo = self.m_charInfo, pageType = pageType, phase = self, lastMainControlTab = self.m_beforePage, extraArg = extraArg, })
            else
                panelItem.uiCtrl:Show()
            end
        end
    end
end
PhaseCharInfo._CreateCharInfoPanel = HL.Method(HL.Number, HL.Number, HL.Opt(HL.Any)) << function(self, panelId, pageType, extraArg)
    if self.m_panel2Item[panelId] then
        return
    end
    local phasePanelItem = self:CreatePhasePanelItem(panelId, { initCharInfo = self.m_charInfo, pageType = pageType, phase = self, lastMainControlTab = self.m_beforePage, extraArg = extraArg, })
    if PANEL_IN_SCENE[panelId] == true then
        local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
        local panelRoot = sceneObject.view.panelRoot
        phasePanelItem.uiCtrl.view.transform:SetParent(panelRoot)
        phasePanelItem.uiCtrl.view.transform:Reset()
    end
end
PhaseCharInfo._GetControllerStateIndex = HL.Method(HL.Opt(HL.Number, HL.Number)).Return(HL.Opt(HL.Number, HL.Number)) << function(self, pageTypeBefore, pageTypeNow)
    if not pageTypeBefore or not pageTypeNow then
        return nil, nil
    end
    local fromStateIndex = UIConst.CHAR_INFO_PAGE_2_ANIMATOR_INDEX_DICT[pageTypeBefore] or -1
    local toStateIndex = UIConst.CHAR_INFO_PAGE_2_ANIMATOR_INDEX_DICT[pageTypeNow] or -1
    if pageTypeNow == UIConst.CHAR_INFO_PAGE_TYPE.POTENTIAL then
        toStateIndex = UIConst.PHASE_CHAR_ITEM_ANIMATOR_INDEX_DICT.EQUIP
    end
    return fromStateIndex, toStateIndex
end
PhaseCharInfo._ToggleTalentFloorEffect = HL.Method(HL.Boolean) << function(self, isOn)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    sceneObject.view.charFloorEffect:ClearTween()
    if isOn then
        sceneObject.view.charFloorEffect:PlayInAnimation()
    else
        sceneObject.view.charFloorEffect:PlayOutAnimation()
    end
end
PhaseCharInfo._ToggleChrSPMotionCor = HL.Method(HL.Boolean) << function(self, isOn)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local phaseItem = self.m_charItem
    local animator = phaseItem.go:GetComponent("Animator")
    local lastSPWaitTime = 0
    local lastTickSpLoopTime = -1
    local isLastFrameSP = false
    if self.m_spMotionUpdateKey then
        LuaUpdate:Remove(self.m_spMotionUpdateKey)
    end
    if isOn then
        self.m_spMotionUpdateKey = LuaUpdate:Add("LateTick", function(deltaTime)
            local isInRelaxIdle = animator:GetCurrentAnimatorStateInfo():IsName("RelaxIdle")
            if not isInRelaxIdle then
                isLastFrameSP = true
                return
            end
            if isLastFrameSP then
                isLastFrameSP = false
                lastSPWaitTime = 0
            end
            lastSPWaitTime = lastSPWaitTime + deltaTime
            if lastSPWaitTime < sceneObject.view.config.SP_MOTION_DURATION then
                return
            end
            local normalizedTime = animator:GetCurrentAnimatorStateInfo().normalizedTime
            local idleLoopTime = math.floor(normalizedTime)
            if (normalizedTime - idleLoopTime) < 0.9 then
                return
            end
            if lastTickSpLoopTime == idleLoopTime then
                return
            end
            lastTickSpLoopTime = idleLoopTime
            local fromIndex = UIConst.CHAR_INFO_PAGE_2_ANIMATOR_INDEX_DICT[self.m_curPage]
            local toIndex = lume.randomchoice(UIConst.PHASE_CHAR_ITEM_ANIMATOR_SP_INDEX)
            self:_SwitchCharacterControllerState(phaseItem, fromIndex, toIndex)
        end)
    end
end
PhaseCharInfo._DebugShowCharSPMotion = HL.Method(HL.Number) << function(self, toIndex)
    self:_SwitchCharacterControllerState(self.m_charItem, UIConst.PHASE_CHAR_ITEM_ANIMATOR_INDEX_DICT.PROFILE_SHOW, toIndex)
end
PhaseCharInfo._SwitchCharacterControllerState = HL.Method(HL.Any, HL.Number, HL.Number, HL.Opt(HL.Boolean)) << function(self, charItem, fromIndex, toIndex, skipIn)
    charItem:SetInteger(UIConst.PHASE_CHAR_ITEM_FROM_INDEX, fromIndex)
    charItem:SetInteger(UIConst.PHASE_CHAR_ITEM_TO_INDEX, toIndex)
    charItem:SetTrigger(UIConst.PHASE_CHAR_ITEM_ENABLE_SWITCH)
    if skipIn then
        charItem:SetTrigger(UIConst.PHASE_CHAR_ITEM_SKIP_PARAM_NAME)
    end
    if skipIn then
        local weaponState = CS.Beyond.Gameplay.View.CharUIModelMono.WeaponState.HIDE
        if UIConst.CHAR_INFO_ANIMATOR_INDEX_2_WEAPON_STATE[toIndex] then
            weaponState = UIConst.CHAR_INFO_ANIMATOR_INDEX_2_WEAPON_STATE[toIndex]
        end
        charItem:SwitchWeaponState(weaponState)
    end
    self:_HandleLookAtIK(charItem, toIndex, skipIn)
end
PhaseCharInfo._HandleLookAtIK = HL.Method(HL.Any, HL.Number, HL.Opt(HL.Boolean)) << function(self, charItem, toIndex, skipIn)
    local lookAtIKTarget = CameraManager.mainCamera.transform:Find("LookAtIkTarget")
    if lookAtIKTarget == nil then
        lookAtIKTarget = GameObject("LookAtIkTarget").transform
        lookAtIKTarget:SetParent(CameraManager.mainCamera.transform)
        lookAtIKTarget:Reset()
    end
    self:_CleanupLookAtIK()
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local lookAtIk = charItem.go:GetComponent("LookAtIK")
    lookAtIKTarget.localPosition = sceneObject.view.config.LOOK_AT_OFFSET
    lookAtIk.solver:SetLookAtWeight(0)
    lookAtIk.solver.target = lookAtIKTarget.transform
    if toIndex == UIConst.PHASE_CHAR_ITEM_ANIMATOR_INDEX_DICT.OVERVIEW then
        local animator = charItem.go:GetComponent("Animator")
        if skipIn == true then
            lookAtIk.solver:SetLookAtWeight(1)
        else
            self.m_lookAtTickKey = LuaUpdate:Add("LateTick", function(deltaTime)
                if not NotNull(animator) then
                    LuaUpdate:Remove(self.m_lookAtTickKey)
                    self.m_lookAtTickKey = -1
                    return
                end
                local state = animator:GetCurrentAnimatorStateInfo()
                if (not state:IsName("OverviewIdle")) and (state.normalizedTime > sceneObject.view.config.LOOK_AT_CROSS_FADE_STATE_NORMALIZED_TIME) then
                    self.m_lookAtTween = DOTween.To(function()
                        return lookAtIk.solver.IKPositionWeight
                    end, function(value)
                        lookAtIk.solver:SetLookAtWeight(value)
                    end, 1, sceneObject.view.config.LOOK_AT_TWEEN_DURATION)
                    LuaUpdate:Remove(self.m_lookAtTickKey)
                    self.m_lookAtTickKey = -1
                end
            end)
        end
    end
end
PhaseCharInfo._CleanupLookAtIK = HL.Method() << function(self)
    if self.m_lookAtTickKey > 0 then
        LuaUpdate:Remove(self.m_lookAtTickKey)
    end
    if self.m_lookAtTween ~= nil then
        self.m_lookAtTween:Kill()
    end
end
PhaseCharInfo._Trigger_OnPageChange = HL.Method(HL.Number, HL.Number) << function(self, panelId, pageType)
    local panelItem = self.m_panel2Item[panelId]
    if not panelItem then
        return
    end
    if HL.TryGet(panelItem.uiCtrl, "OnPageChange") then
        panelItem.uiCtrl:OnPageChange(pageType)
    end
    panelItem.uiCtrl:Show()
end
PhaseCharInfo._RefreshShowCamTargetGroup = HL.Method() << function(self)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local templateId = self.m_charInfo.templateId
    local pathGroup = self.m_templateId2DollyTrackPathGroup[templateId]
    local lookAtGroup = pathGroup.view.lookAtGroup
    if lookAtGroup then
        sceneObject.view.nearTarget.transform.position = lookAtGroup.lookat_show_near.position
        sceneObject.view.farTarget.transform.position = lookAtGroup.lookat_show_far.position
    end
    sceneObject.view.targetGroup:DoUpdate()
end
PhaseCharInfo.OnCharInfoShowRotateChar = HL.Method(HL.Number) << function(self, deltaAngle)
    self.m_charItem:RotateChar(deltaAngle)
end
PhaseCharInfo.OnCharInfoShowZooming = HL.Method(HL.Number) << function(self, delta)
    self.m_zoomCache = delta
end
PhaseCharInfo.OnCharInfoShowCharClose = HL.Method() << function(self)
    local charInfo = self.m_charInfo
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local templateId = charInfo.templateId
    self:RemovePhasePanelItemById(PanelId.CharInfoShow)
    UIManager:RecoverScreen(self.m_toggleUIKey)
    self.m_toggleUIKey = -1
    self:_RefreshCamGroup(sceneObject, false, templateId, self.m_curPage)
    self.m_charItem:ResetChar()
end
PhaseCharInfo._CloseAllCamGroup = HL.Method() << function(self)
    for i, disableGroup in pairs(self.m_templateId2DollyTrackPathGroup) do
        disableGroup.go:SetActive(false)
    end
end
PhaseCharInfo._ClearAudioCor = HL.Method() << function(self)
    self.m_voiceCor = PhaseManager:_ClearCoroutine(self.m_voiceCor)
end
PhaseCharInfo._RefreshCamGroup = HL.Method(HL.Userdata, HL.Boolean, HL.String, HL.Number, HL.Opt(HL.Number)) << function(self, sceneObject, isFast, charTemplateId, pageType, pageTypeBefore)
    self:_CloseAllCamGroup()
    local pathGroup = self.m_templateId2DollyTrackPathGroup[charTemplateId]
    sceneObject.view.cameraScene.gameObject:SetActive(pathGroup == nil)
    if pathGroup then
        local toCameraPostfix = UIConst.CHAR_INFO_MAIN_CONTROL_PAGE_2_CAMERA_POSTFIX[pageType]
        local fromCameraPostfix = pageTypeBefore and UIConst.CHAR_INFO_MAIN_CONTROL_PAGE_2_CAMERA_POSTFIX[pageTypeBefore]
        self:_SetCamWithTrack(isFast, pathGroup, toCameraPostfix, fromCameraPostfix)
    end
    local volumeGroup = self.m_templateId2VolumeGroup[charTemplateId]
    if volumeGroup then
        self:_SetOverrideVolume(isFast, sceneObject, volumeGroup, pageType, pageTypeBefore)
    end
end
PhaseCharInfo._RefreshAddonLight = HL.Method(HL.Userdata, HL.Boolean, HL.String, HL.Number, HL.Opt(HL.Number)) << function(self, sceneObject, isFast, charTemplateId, pageType, pageTypeBefore)
    local newLightPostfix = pageType and UIConst.CHAR_INFO_MAIN_CONTROL_PAGE_2_CAMERA_POSTFIX[pageType]
    local lastLightPostfix = pageTypeBefore and UIConst.CHAR_INFO_MAIN_CONTROL_PAGE_2_CAMERA_POSTFIX[pageTypeBefore]
    for _, lightGroup in pairs(self.m_templateId2LightGroup) do
        lightGroup.go:SetActive(false)
    end
    local targetLightGroup = self.m_templateId2LightGroup[charTemplateId]
    if not targetLightGroup then
        return
    end
    for _, lightIndex in pairs(UIConst.CHAR_INFO_MAIN_CONTROL_PAGE_2_CAMERA_POSTFIX) do
        local lightName = string.format("light_%s", lightIndex)
        local light = targetLightGroup.view[lightName]
        if light then
            light.gameObject:SetActive(false)
        end
    end
    targetLightGroup.go:SetActive(true)
    local newLight
    local lastLight
    local tweenDuration = isFast and 0 or 1
    local newLightName = pageType and string.format("light_%s", newLightPostfix) or ""
    local lastLightName = pageTypeBefore and string.format("light_%s", lastLightPostfix) or ""
    newLight = targetLightGroup.view[newLightName]
    lastLight = targetLightGroup.view[lastLightName]
    if lastLight then
        lastLight.gameObject:SetActive(true)
        lastLight:TweenLightGroupAlpha(1, 0, tweenDuration)
    end
    if newLight then
        newLight.gameObject:SetActive(true)
        newLight:TweenLightGroupAlpha(0, 1, tweenDuration)
    end
end
PhaseCharInfo._SetOverrideVolume = HL.Method(HL.Boolean, HL.Userdata, HL.Table, HL.Number, HL.Opt(HL.Number)) << function(self, isInit, sceneObject, volumeGroup, tabType, tabTypeBefore)
    local overrideVolume = sceneObject.view.charOverrideVolume
    if not overrideVolume then
        return
    end
    local toVolumePostfix = UIConst.CHAR_INFO_MAIN_CONTROL_PAGE_2_CAMERA_POSTFIX[tabType]
    local fromVolumePostfix = UIConst.CHAR_INFO_MAIN_CONTROL_PAGE_2_CAMERA_POSTFIX[tabTypeBefore]
    if toVolumePostfix == fromVolumePostfix then
        return
    end
    local toVolumeModifierName = string.format("volume_%s", toVolumePostfix)
    local toVolumeModifier = volumeGroup[toVolumeModifierName]
    if toVolumeModifier then
        local tweenDuration = isInit and 0 or toVolumeModifier.tweenDuration
        local tween = toVolumeModifier:GetMainLightBiasTween(overrideVolume, tweenDuration)
        if self.m_charVolumeTween then
            self.m_charVolumeTween:Kill()
        end
        self.m_charVolumeTween = tween
        tween:Play()
    end
end
PhaseCharInfo._GetTargetVCam = HL.Method(HL.String, HL.Number).Return(HL.Userdata) << function(self, charTemplateId, pageType)
    local pathGroup = self.m_templateId2DollyTrackPathGroup[charTemplateId]
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    sceneObject.view.cameraScene.gameObject:SetActive(pathGroup == nil)
    local targetVCam
    local toCameraPostfix = UIConst.CHAR_INFO_MAIN_CONTROL_PAGE_2_CAMERA_POSTFIX[pageType]
    for _, camPostfix in pairs(UIConst.PHASE_CHAR_ITEM_CAMERA_POSTFIX_DICT) do
        local cam = pathGroup.view.cameraGroup["vcam_" .. camPostfix]
        if cam then
            local isTargetCam = toCameraPostfix == camPostfix
            if isTargetCam then
                targetVCam = cam
            end
        end
    end
    return targetVCam
end
PhaseCharInfo._GetLookAtTarget = HL.Method(HL.String, HL.Number).Return(HL.Userdata) << function(self, charTemplateId, pageType)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local targetVCam = self:_GetTargetVCam(charTemplateId, pageType)
    if targetVCam.transform:Find("CharInfoLookAtTarget") then
        return targetVCam.transform:Find("CharInfoLookAtTarget").gameObject
    end
    local lookAtTarget = GameObject("CharInfoLookAtTarget")
    lookAtTarget.transform.parent = targetVCam.transform
    lookAtTarget.transform:Reset()
    lookAtTarget.transform.localPosition = sceneObject.view.config.LOOK_AT_OFFSET
    return lookAtTarget
end
PhaseCharInfo._SetCamWithTrack = HL.Method(HL.Boolean, HL.Userdata, HL.String, HL.Opt(HL.String)) << function(self, isFast, pathGroup, toCameraPostfix, fromCameraPostfix)
    pathGroup.go:SetActive(true)
    local targetVCam
    if not toCameraPostfix then
        return
    end
    for _, camPostfix in pairs(UIConst.PHASE_CHAR_ITEM_CAMERA_POSTFIX_DICT) do
        local cam = pathGroup.view.cameraGroup["vcam_" .. camPostfix]
        if cam then
            local isTargetCam = toCameraPostfix == camPostfix
            cam.gameObject:SetActive(isTargetCam)
            if isTargetCam then
                targetVCam = cam
            end
        end
    end
    if not targetVCam then
        return
    end
    local dollyPathName = string.format("%s_%s", fromCameraPostfix, toCameraPostfix)
    local dollyPathTransform = pathGroup.view.paths[dollyPathName]
    if not dollyPathTransform then
        return
    end
    if self.m_trackDollyTween then
        self.m_trackDollyTween:Kill()
    end
    if self.m_lastCamAnimName ~= nil and not string.isEmpty(self.m_lastCamAnimName) then
        pathGroup.view.animation:SeekToPercent(self.m_lastCamAnimName, 1)
    end
    local useCustomAnim = pathGroup.view.config:HasValue(string.format("CUSTOM_ANIM_%s_%s", fromCameraPostfix, toCameraPostfix))
    if useCustomAnim then
        local customAnimName = pathGroup.view.config[string.format("CUSTOM_ANIM_%s_%s", fromCameraPostfix, toCameraPostfix)]
        self.m_lastCamAnimName = customAnimName
        if isFast then
            pathGroup.view.animation:SeekToPercent(customAnimName, 1)
        else
            pathGroup.view.animation:Play(customAnimName)
        end
        return
    end
    local addonAnim = pathGroup.view.config:HasValue(string.format("ADDON_ANIM_%s_%s", fromCameraPostfix, toCameraPostfix))
    if addonAnim then
        local addonAnimName = pathGroup.view.config[string.format("ADDON_ANIM_%s_%s", fromCameraPostfix, toCameraPostfix)]
        self.m_lastCamAnimName = addonAnimName
        if isFast then
            pathGroup.view.animation:SeekToPercent(addonAnimName, 1)
        else
            pathGroup.view.animation:Play(addonAnimName)
        end
    end
    local trackedDolly = targetVCam:GetCinemachineComponent(CS.Cinemachine.CinemachineCore.Stage.Body)
    if trackedDolly then
        trackedDolly.m_PathPosition = 1
        if isFast then
            CameraManager:SetNextBlendOverride(0, CS.Cinemachine.CinemachineBlendDefinition.Style.Cut)
            return
        end
        if not fromCameraPostfix then
            return
        end
        local dollyTrackPath = dollyPathTransform.gameObject:GetComponent("CinemachineSmoothPath")
        pathGroup.go:SetActive(true)
        trackedDolly.m_Path = dollyTrackPath
        trackedDolly.m_PathPosition = 0
    end
    local tweenSpeed = pathGroup.view.config.CAMERA_SPEED
    if pathGroup.view.config:HasValue(string.format("SPEED_%s", dollyPathName)) then
        tweenSpeed = pathGroup.view.config[string.format("SPEED_%s", dollyPathName)]
    end
    local tween = CSUtils.TweenTo(0, 1, tweenSpeed, function(x)
        if NotNull(trackedDolly) then
            trackedDolly.m_PathPosition = x
        end
    end)
    self.m_trackDollyTween = tween
    self.m_trackDollyTween:Play()
end
PhaseCharInfo._ToggleSceneLight = HL.Method(HL.Boolean) << function(self, isOn)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    sceneObject.view.light.gameObject:SetActive(isOn)
end
PhaseCharInfo._SetListCameraDOF = HL.Method() << function(self)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local listDOFParams = Utils.stringJsonToTable(sceneObject.view.config.LIST_DOF_PARAM)
    local data = CS.HG.Rendering.Runtime.HGDepthOfFieldData(listDOFParams.type, listDOFParams.nearFocusStart, listDOFParams.nearFocusEnd, listDOFParams.nearRadius, listDOFParams.farFocusStart, listDOFParams.farFocusEnd, listDOFParams.farRadius)
    Utils.enableCameraDOF(data)
end
PhaseCharInfo.OnCharTalentFocus = HL.Method(HL.Boolean) << function(self, isFast)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local pathGroup = self.m_templateId2DollyTrackPathGroup[self.m_charInfo.templateId]
    self:_SetCamWithTrack(isFast, pathGroup, UIConst.PHASE_CHAR_ITEM_CAMERA_POSTFIX_DICT.TALENT_FOCUS, UIConst.PHASE_CHAR_ITEM_CAMERA_POSTFIX_DICT.TALENT)
end
PhaseCharInfo.OnCharTalentLeaveFocus = HL.Method(HL.Boolean) << function(self, isFast)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local pathGroup = self.m_templateId2DollyTrackPathGroup[self.m_charInfo.templateId]
    self:_SetCamWithTrack(isFast, pathGroup, UIConst.PHASE_CHAR_ITEM_CAMERA_POSTFIX_DICT.TALENT, UIConst.PHASE_CHAR_ITEM_CAMERA_POSTFIX_DICT.TALENT_FOCUS)
end
PhaseCharInfo._BlendExitPhase = HL.Method(HL.Table) << function(self, arg)
    local curActiveCam = CameraManager.curVirtualCam
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local blendCamera = sceneObject.view.charInfoBlendCam
    blendCamera.transform.position = curActiveCam.State.RawPosition + sceneObject.view.config.BLEND_CAM_DELTA_POS
    blendCamera.transform.rotation = curActiveCam.State.RawOrientation
    self.m_blendTransitionCor = PhaseManager:_ClearCoroutine(self.m_blendTransitionCor)
    self.m_blendTransitionCor = PhaseManager:_StartCoroutine(function()
        blendCamera.gameObject:SetActive(true)
        coroutine.wait(sceneObject.view.config.BLEND_BLACK_SCREEN_WAIT_TIME)
        local maskData = CS.Beyond.Gameplay.UICommonMaskData()
        maskData.fadeInTime = sceneObject.view.config.BLEND_BLACK_SCREEN_TIME
        maskData.fadeBeforeTime = 0
        maskData.fadeOutTime = sceneObject.view.config.BLEND_BLACK_SCREEN_TIME
        maskData.fadeInCallback = function()
            if arg.finishCallback then
                arg.finishCallback()
            end
            blendCamera.gameObject:SetActive(false)
        end
        if BEYOND_DEBUG or BEYOND_DEBUG_COMMAND then
            maskData.extraData = CS.Beyond.Gameplay.CommonMaskExtraData()
            maskData.extraData.desc = "CharInfo"
        end
        GameAction.ShowBlackScreen(maskData)
    end)
    self.m_isBlendExit = true
end
PhaseCharInfo._BlendBackPhase = HL.Method() << function(self)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local blendCamera = sceneObject.view.charInfoBlendCam
    blendCamera.gameObject:SetActive(true)
    self.m_blendTransitionCor = PhaseManager:_ClearCoroutine(self.m_blendTransitionCor)
    self.m_blendTransitionCor = PhaseManager:_StartCoroutine(function()
        coroutine.wait(0.1)
        blendCamera.gameObject:SetActive(false)
    end)
end
PhaseCharInfo.m_profileShow = HL.Field(HL.Forward("PhasePanelItem"))
PhaseCharInfo.m_updateKey = HL.Field(HL.Number) << -1
PhaseCharInfo.m_updateTime = HL.Field(HL.Number) << 0
PhaseCharInfo.m_targetWeight = HL.Field(HL.Number) << 1
PhaseCharInfo.m_showCamController = HL.Field(CS.Beyond.Gameplay.View.CustomFreeLookCameraController)
PhaseCharInfo._RefreshProfileShowCam = HL.Method(HL.Table) << function(self, arg)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local pageType = arg.pageType
    sceneObject.view.charInfoShowCam.gameObject:SetActive(pageType == UIConst.CHAR_INFO_PAGE_TYPE.PROFILE_SHOW)
    if pageType == UIConst.CHAR_INFO_PAGE_TYPE.PROFILE then
        local pathGroup = self.m_templateId2DollyTrackPathGroup[self.m_charInfo.templateId]
        local cam = pathGroup.view.cameraGroup["vcam_" .. UIConst.PHASE_CHAR_ITEM_CAMERA_POSTFIX_DICT.DOCUMENT]
        local desPosition = cam.transform.position + sceneObject.view.config.PROFILE_CAM_DELTA_POS
        local desRot = cam.transform.eulerAngles + sceneObject.view.config.PROFILE_CAM_DELTA_ROT
        local desFov = cam.m_Lens.FieldOfView
        sceneObject.view.charInfoProfileCam.transform.position = desPosition
        sceneObject.view.charInfoProfileCam.transform.eulerAngles = desRot
        sceneObject.view.charInfoProfileCam.m_Lens.FieldOfView = desFov
    elseif pageType == UIConst.CHAR_INFO_PAGE_TYPE.PROFILE_SHOW then
        if not self.m_showCamController then
            self.m_showCamController = CameraManager:CreateOrGetTemporaryController(sceneObject.view.charInfoShowCam)
        end
        self.m_showCamController:SetTarget(sceneObject.view.targetGroup.transform)
        self.m_showCamController:SetCameraHorizontalAngle(180, false)
        self.m_showCamController:ForceFlush()
        if self.m_updateKey < 0 then
            self.m_updateKey = LuaUpdate:Add("LateTick", function(deltaTime)
                if self.m_zoomCache then
                    CameraManager:Zoom(self.m_zoomCache, false)
                end
                self.m_zoomCache = nil
                self:_UpdateTargetWeight(deltaTime)
            end)
        end
    end
end
PhaseCharInfo._UpdateTargetWeight = HL.Method(HL.Opt(HL.Number, HL.Number)) << function(self, deltaTime, weight)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local nearTarget = sceneObject.view.targetGroup.m_Targets[0]
    local farTarget = sceneObject.view.targetGroup.m_Targets[1]
    if weight == nil then
        local minZoom = self.m_showCamController.minZoom
        local maxZoom = self.m_showCamController.maxZoom
        local curZoom = self.m_showCamController.freeLookVirtualCamera:GetCurZoomScale(deltaTime)
        local amount = (curZoom - minZoom) / (maxZoom - minZoom)
        local targetWeight = sceneObject.view.config.TARGET_GROUP_WEIGHT_CURVE:Evaluate(amount)
        weight = targetWeight
    end
    nearTarget.weight = weight
    farTarget.weight = 1 - weight
    sceneObject.view.targetGroup.m_Targets[0] = nearTarget
    sceneObject.view.targetGroup.m_Targets[1] = farTarget
    sceneObject.view.targetGroup:DoUpdate()
    self.m_showCamController:ForceFlush()
end
PhaseCharInfo.OnCharInfoProfileClose = HL.Method() << function(self)
    self:_ClearShowCam()
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    self.m_charItem:ResetChar()
    sceneObject.view.charInfoProfileCam.gameObject:SetActive(false)
    self:_PlayModelEffect(sceneObject, self.m_charItem.charId)
end
PhaseCharInfo._ClearShowCam = HL.Method() << function(self)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    if self.m_showCamController then
        CameraManager:RemoveCameraController(self.m_showCamController)
        sceneObject.view.charInfoShowCam.gameObject:SetActive(false)
        self.m_showCamController = nil
    end
    LuaUpdate:Remove(self.m_updateKey)
    self.m_updateKey = -1
    self.m_zoomCache = nil
end
PhaseCharInfo.OnCharInfoEquipSecondEnter = HL.Method() << function(self)
    local trackPathGroup = self.m_templateId2DollyTrackPathGroup[self.m_charInfo.templateId]
    local extraCams = trackPathGroup.view.extraCams
    extraCams.extra_cam_equip_second.gameObject:SetActive(true)
    local panel = self:_GetPanelPhaseItem(PanelId.CharInfoEquipSlot).uiCtrl
    panel:SetState(UIConst.CHAR_INFO_EQUIP_STATE.Detail)
end
PhaseCharInfo.OnCharInfoEquipSecondClose = HL.Method() << function(self)
    local trackPathGroup = self.m_templateId2DollyTrackPathGroup[self.m_charInfo.templateId]
    local extraCams = trackPathGroup.view.extraCams
    extraCams.extra_cam_equip_second.gameObject:SetActive(false)
    local panel = self:_GetPanelPhaseItem(PanelId.CharInfoEquipSlot).uiCtrl
    panel:SetState(UIConst.CHAR_INFO_EQUIP_STATE.Normal)
end
PhaseCharInfo.OnCharInfoWeaponSecondEnter = HL.Method() << function(self)
    local trackPathGroup = self.m_templateId2DollyTrackPathGroup[self.m_charInfo.templateId]
    local extraCams = trackPathGroup.view.extraCams
    extraCams.extra_cam_weapon_second.gameObject:SetActive(true)
end
PhaseCharInfo.OnCharInfoWeaponSecondClose = HL.Method() << function(self)
    local trackPathGroup = self.m_templateId2DollyTrackPathGroup[self.m_charInfo.templateId]
    local extraCams = trackPathGroup.view.extraCams
    extraCams.extra_cam_weapon_second.gameObject:SetActive(false)
end
PhaseCharInfo.OnPreviewWeaponChange = HL.Method(HL.Number) << function(self, weaponInstId)
    if self.m_curPreviewWeaponInstId == weaponInstId then
        return
    end
    self.m_curPreviewWeaponInstId = weaponInstId
    self:ReloadPreviewWeapon()
end
PhaseCharInfo.ReloadPreviewWeapon = HL.Method() << function(self)
    local phaseItem = self.m_charItem
    local weaponState = CS.Beyond.Gameplay.View.CharUIModelMono.WeaponState.HIDE
    phaseItem:LoadTargetWeapon(self.m_curPreviewWeaponInstId)
    phaseItem:SwitchWeaponState(weaponState, true)
end
PhaseCharInfo.OnGemAttach = HL.Method(HL.Table) << function(self, arg)
    local phaseItem = self.m_charItem
    local weaponState = CS.Beyond.Gameplay.View.CharUIModelMono.WeaponState.HIDE
    phaseItem:ReloadWeaponDecoEffect(self.m_curPreviewWeaponInstId)
    phaseItem:SwitchWeaponState(weaponState, true)
end
PhaseCharInfo.OnGemDetach = HL.Method(HL.Table) << function(self, arg)
    local phaseItem = self.m_charItem
    local weaponState = CS.Beyond.Gameplay.View.CharUIModelMono.WeaponState.HIDE
    local detachWeaponInstId = unpack(arg)
    if detachWeaponInstId ~= self.m_curPreviewWeaponInstId then
        return
    end
    phaseItem:ReloadWeaponDecoEffect(self.m_curPreviewWeaponInstId)
    phaseItem:SwitchWeaponState(weaponState, true)
end
PhaseCharInfo.OnWeaponRefine = HL.Method(HL.Table) << function(self, args)
    local weaponInstId, refineLv = unpack(args)
    if weaponInstId == self.m_curPreviewWeaponInstId then
        local weaponInst = CharInfoUtils.getWeaponByInstId(weaponInstId)
        local maxRefineLv = CS.Beyond.Gameplay.WeaponUtil.GetWeaponMaxRefineLv(weaponInst.templateId)
        if maxRefineLv == refineLv then
            self:ReloadPreviewWeapon()
        end
    end
end
PhaseCharInfo.OnPutOnWeapon = HL.Method(HL.Table) << function(self, arg)
    self:_RefreshWeaponDeco({ pageType = UIConst.CHAR_INFO_PAGE_TYPE.WEAPON })
end
PhaseCharInfo.OnCharLevelUp = HL.Method(HL.Table) << function(self, arg)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    UIUtils.PlayAnimationAndToggleActive(sceneObject.view.charUpgradeEffect, true)
    sceneObject.view.charUpgradeEffect:PlayInAnimation()
end
PhaseCharInfo.ToggleWeaponFocusMode = HL.Method(HL.Boolean) << function(self, isOn)
    if self.m_curPage ~= UIConst.CHAR_INFO_PAGE_TYPE.WEAPON then
        return
    end
    self:_ToggleWeaponDeco(not isOn)
end
PhaseCharInfo._RefreshCharUpgradeDeco = HL.Method(HL.Number) << function(self, pageType)
    local isInUpgrade = pageType == UIConst.CHAR_INFO_PAGE_TYPE.UPGRADE
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    UIUtils.PlayAnimationAndToggleActive(sceneObject.view.charUpgradeDeco, isInUpgrade)
end
PhaseCharInfo._RefreshGridDeco = HL.Method(HL.Opt(HL.Table)) << function(self, arg)
    local pageType = arg.pageType
    local isOn = HIDE_GRID_PAGE_TYPE[pageType] == nil
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    UIUtils.PlayAnimationAndToggleActive(sceneObject.view.gridDeco, isOn)
end
PhaseCharInfo._RefreshWeaponDeco = HL.Method(HL.Opt(HL.Table)) << function(self, arg)
    local weaponInstId = arg.weaponInstId
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local weaponDecoNode = sceneObject.view.weaponDecoNode
    local weaponInfo
    local itemCfg, weaponTypeInt
    if not weaponInstId then
        weaponInfo = CharInfoUtils.getCharCurWeapon(self.m_charInfo.instId)
        itemCfg = weaponInfo.itemCfg
        local weaponCfg = weaponInfo.weaponCfg
        weaponTypeInt = weaponCfg.weaponType:ToInt()
    else
        weaponInfo = CharInfoUtils.getWeaponInstInfo(weaponInstId)
        itemCfg = weaponInfo.itemCfg
        local weaponCfg = weaponInfo.weaponCfg
        weaponTypeInt = weaponCfg.weaponType:ToInt()
    end
    weaponDecoNode.weaponName.text = itemCfg.name
    UIUtils.setItemRarityImage(weaponDecoNode.rarityColor, itemCfg.rarity)
    local spriteName = UIConst.WEAPON_EXHIBIT_WEAPON_TYPE_ICON_PREFIX .. weaponTypeInt
    local sprite = self:LoadSprite(UIConst.UI_SPRITE_WEAPON_EXHIBIT, spriteName)
    weaponDecoNode.typeIcon.sprite = sprite
    weaponDecoNode.potentialStar:InitWeaponPotentialStar(weaponInfo.weaponInst.refineLv)
    weaponDecoNode.starGroup:InitStarGroup(itemCfg.rarity)
end
PhaseCharInfo._ToggleWeaponDeco = HL.Method(HL.Boolean, HL.Opt(HL.Number)) << function(self, isOn, beforePage)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local weaponDecoNode = sceneObject.view.weaponDecoNode
    self.m_weaponDecoEffectCor = PhaseManager:_ClearCoroutine(self.m_weaponDecoEffectCor)
    if isOn then
        if beforePage and beforePage == UIConst.CHAR_INFO_PAGE_TYPE.EQUIP then
            self.m_weaponDecoEffectCor = PhaseManager:_StartCoroutine(function()
                coroutine.wait(0.5)
                UIUtils.PlayAnimationAndToggleActive(weaponDecoNode.animationWrapper, true)
            end)
        else
            UIUtils.PlayAnimationAndToggleActive(weaponDecoNode.animationWrapper, true)
        end
    else
        UIUtils.PlayAnimationAndToggleActive(weaponDecoNode.animationWrapper, false)
    end
end
PhaseCharInfo._StartPreloadCor = HL.Method() << function(self)
    if self.m_preloadCor then
        return
    end
    self.m_preloadCor = PhaseManager:_StartCoroutine(function()
        for i, panelId in ipairs(PANEL_PRELOAD_ORDER) do
            if UIManager:CheckPanelAssetHadLoaded(panelId) then
                logger.info(string.format("CharInfo->Panel[%s] already preloaded, skip", panelId))
            else
                logger.info(string.format("CharInfo->Preload panel [%s]", panelId))
                UIManager:PreloadPanelAsset(panelId)
                coroutine.wait(0.5)
            end
        end
    end)
end
PhaseCharInfo._RefreshVoiceTriggerVo = HL.Method(HL.Number) << function(self, pageType)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local charInfo = self.m_charInfo
    if pageType == UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW then
        self.m_voiceCor = PhaseManager:_ClearCoroutine(self.m_voiceCor)
        self.m_voiceCor = PhaseManager:_StartCoroutine(function()
            coroutine.wait(sceneObject.view.config.VOICE_IDLE_TRIGGER_DURATION)
            Utils.triggerVoice("chrbark_idle", charInfo.templateId)
        end)
    else
        self.m_voiceCor = PhaseManager:_ClearCoroutine(self.m_voiceCor)
    end
end
PhaseCharInfo._TriggerCharBarkSwitch = HL.Method(HL.Number) << function(self, pageType)
    local charInfo = self.m_charInfo
    if pageType == UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW then
        Utils.stopDefaultChannelVoice()
        Utils.triggerVoice("chrbark_switch", charInfo.templateId)
    end
end
PhaseCharInfo.RefreshPotentialStar = HL.Method(HL.Number, HL.Number, HL.Opt(HL.Boolean)) << function(self, potentialLevel, maxPotentialLevel, isLvUp)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local starNode = sceneObject.view.charInfoPotentialStar
    local potentialDecoNode = starNode.charInfoPotentialDeco
    potentialDecoNode.level.text = tostring(potentialLevel)
    potentialDecoNode.maxLevel.text = potentialLevel == maxPotentialLevel and "/MAX" or string.format("/%d", maxPotentialLevel)
    for i = 1, maxPotentialLevel do
        local curStar = starNode[string.format("curStar%02d", i)]
        if curStar then
            if i <= potentialLevel then
                if i == potentialLevel and isLvUp then
                    curStar:PlayInAnimation()
                else
                    curStar:SampleToInAnimationEnd()
                end
            else
                curStar:SampleToInAnimationBegin()
            end
        end
        local nextStart = starNode[string.format("nextStar%02d", i)]
        if nextStart then
            if i == potentialLevel + 1 and isLvUp then
                nextStart.gameObject:SetActive(true)
            elseif i == potentialLevel and isLvUp and nextStart.gameObject.activeSelf then
                nextStart:PlayOutAnimation(function()
                    nextStart.gameObject:SetActive(false)
                end)
            else
                nextStart.gameObject:SetActive(false)
            end
        end
    end
end
PhaseCharInfo.SetActivePotentialNextStar = HL.Method(HL.Number, HL.Boolean, HL.Boolean) << function(self, level, active, ignoreAnim)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local starNode = sceneObject.view.charInfoPotentialStar
    local nextStar = starNode[string.format("nextStar%02d", level)]
    if not nextStar then
        return
    end
    if active then
        nextStar.gameObject:SetActive(true)
        nextStar:PlayInAnimation()
    else
        if ignoreAnim then
            nextStar.gameObject:SetActive(false)
        else
            nextStar:PlayOutAnimation()
        end
    end
end
PhaseCharInfo.RefreshPotentialCharImg = HL.Method(HL.String, HL.Opt(HL.Boolean)) << function(self, templateId, playAnim)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    local starNode = sceneObject.view.charInfoPotentialStar
    local sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_INFO, UIConst.UI_CHAR_INFO_CHAR_BG_PREFIX .. templateId)
    starNode.charTexture.gameObject:SetActive(sprite ~= nil)
    if sprite then
        starNode.charTexture.sprite = sprite
    end
    if playAnim then
        starNode.animWrapper:Play("charinfo_potential_star_bg")
    end
end
PhaseCharInfo._SetActivePotentialItems = HL.Method(HL.Boolean) << function(self, active)
    local sceneObject = self.m_gameObject2Item[PHASE_CHAR_INFO_GAME_OBJECT]
    sceneObject.view.charInfoPotentialStar.gameObject:SetActive(active)
    if active then
        AudioAdapter.PostEvent("Au_UI_Event_CharPotentialAnim")
        self:RefreshPotentialCharImg(self.m_charInfo.templateId)
        local csCharInfo = CharInfoUtils.getPlayerCharInfoByInstId(self.m_charInfo.instId)
        if csCharInfo then
            self:RefreshPotentialStar(csCharInfo.potentialLevel, UIConst.CHAR_MAX_POTENTIAL)
        end
    end
end
PhaseCharInfo.ShowCharExpandList = HL.Method(HL.Table) << function(self, args)
    self:CreateOrShowPhasePanelItem(PanelId.CharExpandList, args)
    UIManager:SetTopOrder(PanelId.CharExpandList)
end
PhaseCharInfo.HideCharExpandList = HL.Method() << function(self)
    local panelItem = self:_GetPanelPhaseItem(PanelId.CharExpandList)
    if panelItem then
        panelItem.uiCtrl:PlayAnimationOutAndHide()
    end
end
PhaseCharInfo.RefreshCharExpandList = HL.Method(HL.Table, HL.Table) << function(self, charInfo, charInfoList)
    local panelItem = self:_GetPanelPhaseItem(PanelId.CharExpandList)
    if panelItem then
        panelItem.uiCtrl:RefreshCharExpandList(charInfo, charInfoList, true)
    end
end
HL.Commit(PhaseCharInfo)