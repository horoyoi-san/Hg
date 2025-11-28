local phaseBase = require_ex('Phase/Core/PhaseBase')
local PHASE_ID = PhaseId.Wiki
PhaseWiki = HL.Class('PhaseWiki', phaseBase.PhaseBase)
local WIKI_CATEGORY_TO_PANEL_CFG = { [WikiConst.EWikiCategoryType.Weapon] = { groupPanelId = PanelId.WikiGroup, detailPanelId = PanelId.WikiWeapon, includeLocked = true, }, [WikiConst.EWikiCategoryType.Equip] = { groupPanelId = PanelId.WikiEquipSuit, detailPanelId = PanelId.WikiEquip, }, [WikiConst.EWikiCategoryType.Item] = { groupPanelId = PanelId.WikiGroup, detailPanelId = PanelId.WikiItem, }, [WikiConst.EWikiCategoryType.Monster] = { groupPanelId = PanelId.WikiGroup, detailPanelId = PanelId.WikiMonster, }, [WikiConst.EWikiCategoryType.Building] = { groupPanelId = PanelId.WikiGroup, detailPanelId = PanelId.WikiBuilding, }, [WikiConst.EWikiCategoryType.Tutorial] = { groupPanelId = nil, detailPanelId = PanelId.WikiGuide, }, }
local SHOW_MODEL_FUNC = { [WikiConst.EWikiCategoryType.Weapon] = "_ShowWeaponModel", [WikiConst.EWikiCategoryType.Monster] = "_ShowMonsterModel", [WikiConst.EWikiCategoryType.Building] = "_ShowBuildingModel", }
local MODEL_ROOT_ANIM_NAME = { [WikiConst.EWikiCategoryType.Weapon] = "wiki_model_in_weapon", [WikiConst.EWikiCategoryType.Monster] = "wiki_model_in_monster", [WikiConst.EWikiCategoryType.Building] = "wiki_model_in_building" }
local SCENE_ITEM_NAME = "WikiModelShow"
local CAMERA_GROUP_NAME = "WikiCameraGroup"
local LIGHT_GROUP_NAME = "WikiLightGroup"
local WIKI_ENY_POSE_CONTROLLER_PATH = "Assets/Beyond/DynamicAssets/Gameplay/Prefabs/UIModels/WikiEnyPose/%s.overrideController"
PhaseWiki.s_messages = HL.StaticField(HL.Table) << { [MessageConst.SHOW_WIKI_ENTRY] = { 'OnShowWikiEntry', false }, }
PhaseWiki.OnShowWikiEntry = HL.StaticMethod(HL.Table) << function(args)
    local categoryId, wikiDetailArgs = PhaseWiki.ProcessArgs(args)
    if not string.isEmpty(categoryId) then
        PhaseManager:GoToPhase(PHASE_ID, { categoryType = categoryId, wikiDetailArgs = wikiDetailArgs })
    else
        local toastTxt = Language.LUA_WIKI_ENTRY_NOT_SUPPORT
        if not string.isEmpty(args.buildingId) then
            toastTxt = Language.LUA_WIKI_BUILDING_NOT_SUPPORT
        elseif not string.isEmpty(args.monsterId) then
            toastTxt = Language.LUA_WIKI_MONSTER_NOT_SUPPORT
        elseif not string.isEmpty(args.itemId) then
            toastTxt = Language.LUA_WIKI_ITEM_NOT_SUPPORT
        end
        Notify(MessageConst.SHOW_TOAST, toastTxt)
    end
end
PhaseWiki.m_isShowBackBtn = HL.Field(HL.Boolean) << false
PhaseWiki._OnInit = HL.Override() << function(self)
    PhaseWiki.Super._OnInit(self)
    self.m_activeModelGos = {}
    self.m_modelRequestIdLut = {}
    self.m_animatorControllerCache = {}
    self.m_isShowBackBtn = self.arg == nil
    self.arg = self.arg or {}
end
PhaseWiki._OnActivated = HL.Override() << function(self)
    self:SetupCamera()
end
PhaseWiki._OnDeActivated = HL.Override() << function(self)
    self:ResetCamera()
end
PhaseWiki._OnDestroy = HL.Override() << function(self)
    PhaseWiki.Super._OnDestroy(self)
    self:DestroyModel()
end
PhaseWiki._InitAllPhaseItems = HL.Override() << function(self)
    self:_InitSceneRoot()
    self:OpenCategoryByPhaseArgs()
end
PhaseWiki._OnRefresh = HL.Override() << function(self)
    PhaseWiki.Super._OnRefresh(self)
    self:OpenCategoryByPhaseArgs()
end
PhaseWiki._DoPhaseTransitionIn = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseWiki._DoPhaseTransitionOut = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseWiki._DoPhaseTransitionBehind = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    self.m_sceneRoot.view.gameObject:SetActive(false)
end
PhaseWiki._DoPhaseTransitionBackToTop = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    self.m_sceneRoot.view.gameObject:SetActive(true)
end
PhaseWiki.curSearchKeyword = HL.Field(HL.String) << ""
PhaseWiki.m_currentWikiGroupArgs = HL.Field(HL.Table)
PhaseWiki.m_currentWikiDetailArgs = HL.Field(HL.Table)
PhaseWiki.OpenCategoryByPhaseArgs = HL.Method() << function(self)
    local categoryType = self.arg.categoryType
    local wikiDetailArgs = self.arg.wikiDetailArgs
    if string.isEmpty(categoryType) then
        categoryType, wikiDetailArgs = PhaseWiki.ProcessArgs(self.arg)
    end
    self:OpenCategory(categoryType, wikiDetailArgs)
end
PhaseWiki.OpenCategory = HL.Method(HL.Any, HL.Opt(HL.Table)) << function(self, categoryId, args)
    self.m_currentWikiDetailArgs = args
    local panelCfg = WIKI_CATEGORY_TO_PANEL_CFG[categoryId]
    if panelCfg then
        local wikiGroupArgs = { categoryType = categoryId, detailPanelId = panelCfg.detailPanelId, includeLocked = panelCfg.includeLocked, }
        self.m_currentWikiGroupArgs = wikiGroupArgs
        if panelCfg.groupPanelId and not args then
            self:CreateOrShowPhasePanelItem(panelCfg.groupPanelId, wikiGroupArgs)
        else
            self:RemovePhasePanelItemById(PanelId.WikiGroup)
            for panelId, panelItem in pairs(self.m_panel2Item) do
                if panelId == PanelId.WikiSearch then
                    if panelItem.uiCtrl:IsShow(true) then
                        panelItem.uiCtrl:Hide()
                    end
                elseif panelId ~= panelCfg.detailPanelId and panelId ~= PanelId.Wiki then
                    self:RemovePhasePanelItem(panelItem)
                end
            end
            if UIManager:IsShow(panelCfg.detailPanelId) then
                self:_GetPanelPhaseItem(panelCfg.detailPanelId).uiCtrl:Refresh(args)
            else
                self:CreateOrShowPhasePanelItem(panelCfg.detailPanelId, args)
            end
        end
    else
        self.m_currentWikiGroupArgs = nil
        self:CreateOrShowPhasePanelItem(PanelId.Wiki)
    end
end
PhaseWiki.GetCategoryPanelCfg = HL.Method(HL.String).Return(HL.Table) << function(self, categoryId)
    return WIKI_CATEGORY_TO_PANEL_CFG[categoryId]
end
PhaseWiki.ProcessArgs = HL.StaticMethod(HL.Table).Return(HL.String, HL.Table) << function(args)
    if not args then
        return '', nil
    end
    local targetCategoryId, targetGroupId, targetEntryId
    if not string.isEmpty(args.wikiEntryId) then
        targetEntryId = args.wikiEntryId
    elseif not string.isEmpty(args.itemId) then
        targetEntryId = WikiUtils.getWikiEntryIdFromItemId(args.itemId)
    elseif not string.isEmpty(args.buildingId) then
        targetEntryId = WikiUtils.getWikiEntryIdFromItemId(FactoryUtils.getBuildingItemId(args.buildingId))
    elseif not string.isEmpty(args.monsterId) then
        targetEntryId = WikiUtils.getWikiEntryIdFromItemId(args.monsterId)
    end
    if string.isEmpty(targetEntryId) or GameInstance.player.wikiSystem:GetWikiEntryState(targetEntryId) == CS.Beyond.Gameplay.WikiSystem.EWikiEntryState.Locked then
        return '', nil
    end
    local _, wikiEntryData = Tables.wikiEntryDataTable:TryGetValue(targetEntryId)
    if wikiEntryData then
        targetEntryId = wikiEntryData.id
        targetGroupId = wikiEntryData.groupId
    end
    if targetGroupId then
        for wikiCategoryType, wikiGroupDataList in pairs(Tables.wikiGroupTable) do
            for _, wikiGroupData in pairs(wikiGroupDataList.list) do
                if wikiGroupData.groupId == targetGroupId then
                    targetCategoryId = wikiCategoryType
                    break
                end
            end
        end
    end
    if targetCategoryId then
        local panelCfg = WIKI_CATEGORY_TO_PANEL_CFG[targetCategoryId]
        if panelCfg then
            local wikiGroupShowDataList, wikiEntryShowData = WikiUtils.getWikiGroupShowDataList(targetCategoryId, targetEntryId, panelCfg.includeLocked)
            local wikiDetailArgs = { categoryType = targetCategoryId, wikiGroupShowDataList = wikiGroupShowDataList, wikiEntryShowData = wikiEntryShowData, }
            return targetCategoryId, wikiDetailArgs
        end
    end
    return '', nil
end
PhaseWiki.m_sceneRoot = HL.Field(HL.Forward("PhaseGameObjectItem"))
PhaseWiki.m_cameraGroup = HL.Field(HL.Forward("PhaseGameObjectItem"))
PhaseWiki.m_currentCamera = HL.Field(HL.Table)
PhaseWiki.m_lightGroup = HL.Field(HL.Forward("PhaseGameObjectItem"))
PhaseWiki.m_categorySceneItem = HL.Field(HL.Table)
PhaseWiki._InitSceneRoot = HL.Method() << function(self)
    if self.m_sceneRoot == nil then
        self.m_sceneRoot = self:CreatePhaseGOItem(SCENE_ITEM_NAME)
        self.m_cameraGroup = self:CreatePhaseGOItem(CAMERA_GROUP_NAME, self.m_sceneRoot.view.sceneCamera)
        self.m_lightGroup = self:CreatePhaseGOItem(LIGHT_GROUP_NAME, self.m_sceneRoot.view.sceneLight)
        if UNITY_EDITOR then
            local additionLightGroup = self.m_lightGroup.go:AddComponent(typeof(CS.Beyond.DevTools.AdditionalLightGroup))
            additionLightGroup.savePath = "Assets/Beyond/DynamicAssets/Gameplay/Prefabs/Wiki/"
        end
        self.m_categorySceneItem = {}
        self.m_categorySceneItem[WikiConst.EWikiCategoryType.Weapon] = { camera = self.m_cameraGroup.view.weapon, light = self.m_lightGroup.view.weapon, }
        self.m_categorySceneItem[WikiConst.EWikiCategoryType.Building] = { camera = self.m_cameraGroup.view.building, light = self.m_lightGroup.view.building, }
        self.m_categorySceneItem[WikiConst.EWikiCategoryType.Monster] = { camera = self.m_cameraGroup.view.monster, light = self.m_lightGroup.view.monster, }
        for _, sceneItem in pairs(self.m_categorySceneItem) do
            sceneItem.camera.gameObject:SetActive(false)
            sceneItem.camera.gameObject:SetAllChildrenActiveIfNecessary(false)
            sceneItem.light.gameObject:SetActive(false)
        end
    end
end
PhaseWiki.m_modelRequestIdLut = HL.Field(HL.Table)
PhaseWiki.m_activeModelGos = HL.Field(HL.Table)
PhaseWiki.m_animatorControllerCache = HL.Field(HL.Table)
PhaseWiki.m_buildingRenderer = HL.Field(HL.Userdata)
PhaseWiki.m_buildingPhaseItem = HL.Field(HL.Forward("PhaseGameObjectItem"))
PhaseWiki.m_weaponDecoBundleList = HL.Field(HL.Table)
PhaseWiki.ShowModel = HL.Method(HL.Table, HL.Opt(HL.Table)) << function(self, wikiEntryShowData, extraArgs)
    self:ActiveCategorySceneItem(wikiEntryShowData.wikiCategoryType)
    self:ResetModelRotateRoot()
    local showFunc = SHOW_MODEL_FUNC[wikiEntryShowData.wikiCategoryType]
    if showFunc then
        self[showFunc](self, wikiEntryShowData, extraArgs)
    end
end
PhaseWiki._ShowWeaponModel = HL.Method(HL.Table, HL.Opt(HL.Table)) << function(self, wikiEntryShowData, extraArgs)
    self:DestroyModel()
    local hasValue
    local weaponBasicData
    hasValue, weaponBasicData = Tables.weaponBasicTable:TryGetValue(wikiEntryShowData.wikiEntryData.refItemId)
    if hasValue then
        local isMax = extraArgs.isWeaponRefinedMax == true
        local playInAim = extraArgs.playInAnim == true
        local modelPath
        hasValue, modelPath = CS.Beyond.Gameplay.WeaponUtil.TryGetWeaponModelByTemplateId(weaponBasicData.weaponId, isMax)
        local wikiWeaponData
        hasValue, wikiWeaponData = DataManager.wikiModelConfig.weaponDataDict:TryGetValue(weaponBasicData.weaponType)
        if hasValue then
            local spawnDataList = wikiWeaponData.spawnDataList
            for i = 1, spawnDataList.Length do
                local spawnData = spawnDataList[CSIndex(i)]
                self:_LoadModelAsync(modelPath, function(goInfo)
                    local go = goInfo.gameObject
                    go.transform.localPosition = spawnData.position
                    go.transform.localEulerAngles = spawnData.rotation
                    go.transform.localScale = spawnData.scale
                    if isMax and #weaponBasicData.weaponSkillList >= 3 then
                        local decoEffectData
                        local hasValue
                        hasValue, decoEffectData = DataManager.weaponDecoEffectConfig.weaponDecoEffectDict:TryGetValue(weaponBasicData.weaponId)
                        if hasValue then
                            local decoDataList = {}
                            table.insert(decoDataList, decoEffectData.gemDeco)
                            table.insert(decoDataList, decoEffectData.gemMaxDeco)
                            self.m_weaponDecoBundleList = self.m_weaponDecoBundleList or {}
                            local weaponDecoBundle = CS.Beyond.Gameplay.WeaponUtil.SetWeaponDecoEffect(go.transform, decoDataList)
                            table.insert(self.m_weaponDecoBundleList, weaponDecoBundle)
                        end
                    end
                    if playInAim then
                        self:PlayModelRootInAnim(WikiConst.EWikiCategoryType.Weapon)
                    end
                end)
            end
        end
    end
end
PhaseWiki._ShowBuildingModel = HL.Method(HL.Table, HL.Opt(HL.Table)) << function(self, wikiEntryShowData, extraArgs)
    local rendererTemplateId
    local _, factoryBuildingItemData = Tables.factoryBuildingItemTable:TryGetValue(wikiEntryShowData.wikiEntryData.refItemId)
    if factoryBuildingItemData then
        rendererTemplateId = factoryBuildingItemData.buildingId
    else
        local _, factoryLogisticItemData = Tables.factoryItem2LogisticIdTable:TryGetValue(wikiEntryShowData.wikiEntryData.refItemId)
        if factoryLogisticItemData then
            rendererTemplateId = factoryLogisticItemData.logisticId
        end
    end
    if rendererTemplateId then
        local model = self.m_sceneRoot.view.buildingECSModel
        local spawnData
        _, spawnData = DataManager.wikiModelConfig.buildingDataDict:TryGetValue(rendererTemplateId)
        if not spawnData then
            spawnData = DataManager.wikiModelConfig.defaultBuildingSpawnData
        end
        model.transform.localPosition = spawnData.position
        model.transform.localEulerAngles = spawnData.rotation
        self:_SetCameraParams(self.m_currentCamera.vcam_entry, spawnData.cameraDistance)
        self:_SetCameraParams(self.m_currentCamera.vcam_show, spawnData.cameraDistance * 0.8)
        if extraArgs and extraArgs.playInAnim then
            self:PlayModelRootInAnim(WikiConst.EWikiCategoryType.Building)
        end
        self:_ActivateBlackboxEffect(false)
        model.gameObject:SetActiveIfNecessary(true)
        model:ChangeTemplate(rendererTemplateId, true, true)
        model:Cutoff(true, 0, 1)
    end
end
PhaseWiki._ShowMonsterModel = HL.Method(HL.Table, HL.Opt(HL.Table)) << function(self, wikiEntryShowData, extraArgs)
    self:DestroyModel()
    local hasValue
    local monsterTemplateId = wikiEntryShowData.wikiEntryData.refMonsterTemplateId
    local monsterTemplateData = nil
    hasValue, monsterTemplateData = DataManager:TryGetEntityTemplate(Const.ObjectType.Enemy, monsterTemplateId)
    if not hasValue then
        return
    end
    local modelCompData = monsterTemplateData:FindComponentData(typeof(CS.Beyond.Gameplay.View.ModelComponentData))
    if not modelCompData then
        return
    end
    local modelId = modelCompData.modelId
    if not modelId or string.isEmpty(modelId) then
        return
    end
    local modelData = nil
    hasValue, modelData = DataManager.modelData:TryGetValue(modelId)
    if not modelData or not modelData.path or string.isEmpty(modelData.path) then
        return
    end
    local playInAim = false
    if extraArgs then
        playInAim = extraArgs.playInAnim == true
    end
    self:_LoadModelAsync(modelData.path, function(enemyModelGoInfo)
        local enemyModelGo = enemyModelGoInfo.gameObject
        local animator = enemyModelGoInfo.animator
        local wikiMonsterSpawnData = nil
        _, wikiMonsterSpawnData = DataManager.wikiModelConfig.monsterDataDict:TryGetValue(monsterTemplateId)
        if not wikiMonsterSpawnData then
            wikiMonsterSpawnData = DataManager.wikiModelConfig.defaultMonsterSpawnData
        end
        enemyModelGo.transform.localPosition = wikiMonsterSpawnData.position
        enemyModelGo.transform.localEulerAngles = wikiMonsterSpawnData.rotation
        enemyModelGo.transform.localScale = wikiMonsterSpawnData.scale
        if animator then
            local animatorCtrlAsset = self.m_animatorControllerCache[monsterTemplateId]
            if not animatorCtrlAsset then
                animatorCtrlAsset = self.m_resourceLoader:LoadAnimatorController(string.format(WIKI_ENY_POSE_CONTROLLER_PATH, monsterTemplateId))
                self.m_animatorControllerCache[monsterTemplateId] = animatorCtrlAsset
            end
            if animatorCtrlAsset then
                animator.runtimeAnimatorController = animatorCtrlAsset
            end
        end
        if playInAim then
            self:PlayModelRootInAnim(WikiConst.EWikiCategoryType.Monster)
        end
    end)
end
PhaseWiki._LoadModelAsync = HL.Method(HL.String, HL.Function) << function(self, modelPath, callback)
    local modelManager = GameInstance.modelManager
    local m_modelRequestId = modelManager:LoadAsync(modelPath, function(path, activeModelGo)
        self.m_modelRequestIdLut[path] = nil
        if activeModelGo and callback then
            local activeModelInfo = { gameObject = activeModelGo }
            local success, animator = activeModelGo:TryGetComponent(typeof(CS.UnityEngine.Animator))
            if success then
                activeModelInfo.animator = animator
                activeModelInfo.animatorController = animator.runtimeAnimatorController
            end
            table.insert(self.m_activeModelGos, activeModelInfo)
            activeModelGo.transform:SetParent(self.m_sceneRoot.view.modelRoot)
            callback(activeModelInfo)
        end
    end)
    self.m_modelRequestIdLut[modelPath] = m_modelRequestId
end
PhaseWiki._SetCameraParams = HL.Method(HL.Userdata, HL.Number) << function(self, vcam, cameraDistance)
    local vcamTransform = vcam.transform
    local cameraPosition = vcamTransform.localPosition
    cameraPosition.z = cameraDistance
    vcamTransform.localPosition = cameraPosition
end
PhaseWiki.DestroyModel = HL.Method() << function(self)
    if self.m_weaponDecoBundleList then
        for _, bundle in ipairs(self.m_weaponDecoBundleList) do
            bundle:Dispose()
        end
        self.m_weaponDecoBundleList = nil
    end
    local modelManager = GameInstance.modelManager
    for path, requestId in pairs(self.m_modelRequestIdLut) do
        modelManager:Cancel(requestId)
        self.m_modelRequestIdLut[path] = nil
    end
    for index, activeModelInfo in pairs(self.m_activeModelGos) do
        local activeModel = activeModelInfo.gameObject
        local animator = activeModelInfo.animator
        if animator then
            animator.runtimeAnimatorController = activeModelInfo.animatorController
        end
        activeModel.transform.localScale = Vector3.one
        modelManager:Unload(activeModel)
        self.m_activeModelGos[index] = nil
    end
    if IsNull(self.m_sceneRoot.view.gameObject) then
        return
    end
    self.m_sceneRoot.view.buildingECSModel:Cutoff(false)
    self.m_sceneRoot.view.buildingECSModel.gameObject:SetActiveIfNecessary(false)
    self:_ActivateBlackboxEffect(true)
    local modelRoot = self.m_sceneRoot.view.modelRoot
    for i = 0, modelRoot.childCount - 1 do
        local model = modelRoot:GetChild(i).gameObject
        model:SetActive(false)
        GameObject.Destroy(model)
    end
end
PhaseWiki.RotateModel = HL.Method(HL.Number) << function(self, deltaX)
    local rotateRoot = self.m_sceneRoot.view.modelRotateRoot.transform
    rotateRoot:Rotate(rotateRoot.up, -deltaX)
end
PhaseWiki.ResetModelRotateRoot = HL.Method() << function(self)
    self.m_sceneRoot.view.modelRotateRoot.transform.localPosition = Vector3.zero
    self:ResetModelRotation()
end
PhaseWiki.ResetModelRotation = HL.Method() << function(self)
    self.m_sceneRoot.view.modelRotateRoot.transform.localEulerAngles = Vector3.zero
end
PhaseWiki.PlayModelRootInAnim = HL.Method(HL.String) << function(self, modelType)
    local animWrapper = modelType == WikiConst.EWikiCategoryType.Building and self.m_sceneRoot.view.buildingModelAnimWrapper or self.m_sceneRoot.view.modelRootAnimWrapper
    animWrapper:Play(MODEL_ROOT_ANIM_NAME[modelType])
end
PhaseWiki.ActiveEntryVirtualCamera = HL.Method(HL.Boolean) << function(self, active)
    if self.m_currentCamera then
        self.m_currentCamera.vcam_entry.gameObject:SetActive(active)
    end
end
PhaseWiki.ActiveShowVirtualCamera = HL.Method(HL.Boolean) << function(self, active)
    if self.m_currentCamera then
        self.m_currentCamera.vcam_show.gameObject:SetActive(active)
    end
end
PhaseWiki.ActiveCategorySceneItem = HL.Method(HL.String) << function(self, categoryType)
    for id, sceneItem in pairs(self.m_categorySceneItem) do
        local isActivated = id == categoryType
        sceneItem.camera.gameObject:SetActive(isActivated)
        sceneItem.light.gameObject:SetActive(isActivated)
    end
    self.m_currentCamera = self.m_categorySceneItem[categoryType].camera
end
PhaseWiki.m_antialiasing = HL.Field(HL.Userdata)
PhaseWiki.m_clearColorMode = HL.Field(HL.Userdata)
PhaseWiki.m_clearColor = HL.Field(HL.Userdata)
PhaseWiki.SetupCamera = HL.Method() << function(self)
    self.m_antialiasing = CameraManager.mainCamAdditionalData.antialiasing
    CameraManager.mainCamAdditionalData.antialiasing = CS.HG.Rendering.Runtime.HGAdditionalCameraData.AntialiasingMode.None
    self.m_clearColorMode = CameraManager.mainCamAdditionalData.clearColorMode
    CameraManager.mainCamAdditionalData.clearColorMode = CS.HG.Rendering.Runtime.HGAdditionalCameraData.ClearColorMode.Color
    self.m_clearColor = CameraManager.mainCamAdditionalData.backgroundColorHDR
    CameraManager.mainCamAdditionalData.backgroundColorHDR = Color.white
end
PhaseWiki.ResetCamera = HL.Method() << function(self)
    CameraManager.mainCamAdditionalData.antialiasing = self.m_antialiasing
    CameraManager.mainCamAdditionalData.clearColorMode = self.m_clearColorMode
    CameraManager.mainCamAdditionalData.backgroundColorHDR = self.m_clearColor
end
PhaseWiki.m_blackBoxEffectActive = HL.Field(HL.Any)
PhaseWiki._ActivateBlackboxEffect = HL.Method(HL.Boolean) << function(self, active)
    if not Utils.isInBlackbox() then
        return
    end
    if not GameInstance.remoteFactoryManager.blackboxIntroEffectController then
        return
    end
    if not GameInstance.remoteFactoryManager.blackboxIntroEffectController.effect.ActivateVFXPPBlackBox then
        return
    end
    if active == self.m_blackBoxEffectActive then
        return
    end
    self.m_blackBoxEffectActive = active
    GameInstance.remoteFactoryManager.blackboxIntroEffectController.effect:ActivateVFXPPBlackBox(active)
end
HL.Commit(PhaseWiki)