local panelConfig = require_ex("UI/Panels/PanelConfig")
local rootConfig = require_ex("UI/Panels/RootConfig")
UIManager = HL.Class('UIManager')
UIManager.ids = HL.Field(HL.Table)
UIManager.cfgs = HL.Field(HL.Table)
UIManager.m_names = HL.Field(HL.Table)
UIManager.persistentInputBindingKey = HL.Field(HL.Number) << -1
UIManager.m_panelConfigs = HL.Field(HL.Table)
UIManager.m_openedPanels = HL.Field(HL.Table)
UIManager.m_hidedPanels = HL.Field(HL.Table)
UIManager.m_selfMaintainOrderPanels = HL.Field(HL.Table)
UIManager.m_nextClearScreenKey = HL.Field(HL.Number) << 1
UIManager.m_clearedPanelReverseInfos = HL.Field(HL.Table)
UIManager.m_clearedPanelInfos = HL.Field(HL.Table)
UIManager.m_autoClearScreenKeys = HL.Field(HL.Table)
UIManager.m_orderManagers = HL.Field(HL.Table)
UIManager.m_panelOrderInterval = HL.Field(HL.Number) << 20
UIManager.m_panelOrderTypeInterval = HL.Field(HL.Number) << 1000
UIManager.m_curBlockKeyboardEventPanelOrder = HL.Field(HL.Number) << -1
UIManager.m_ignoreBlockOrderUpdate = HL.Field(HL.Boolean) << false
UIManager.m_resourceLoader = HL.Field(CS.Beyond.LuaResourceLoader)
UIManager.m_panel2Handle = HL.Field(HL.Table)
UIManager.uiCamera = HL.Field(Unity.Camera)
UIManager.uiCanvas = HL.Field(Unity.Canvas)
UIManager.uiCanvasRect = HL.Field(Unity.RectTransform)
UIManager.uiNode = HL.Field(HL.Table)
UIManager.uiRoot = HL.Field(Unity.RectTransform)
UIManager.uiInputBindingGroupMonoTarget = HL.Field(CS.Beyond.Input.InputBindingGroupMonoTarget)
UIManager.worldUIRoot = HL.Field(Unity.RectTransform)
UIManager.gyroscopeEffect = HL.Field(CS.Beyond.UI.UIGyroscopeEffect)
UIManager.worldUICanvas = HL.Field(Unity.Canvas)
UIManager.worldObjectRoot = HL.Field(Unity.Transform)
UIManager.m_disabledPanelRoot = HL.Field(Unity.Transform)
UIManager.commonTouchPanel = HL.Field(CS.Beyond.UI.UITouchPanel)
UIManager.m_blockInputKeys = HL.Field(HL.Table)
UIManager.m_mainCameraClosedByUI = HL.Field(HL.Boolean) << false
UIManager.m_showingFullScreenPanel = HL.Field(HL.Table)
UIManager.UIManager = HL.Constructor() << function(self)
    Register(MessageConst.BLOCK_LUA_UI_INPUT, function(arg)
        local shouldBlock, key = unpack(arg)
        self:_ToggleUIInputBinding(not shouldBlock, key)
    end, self)
    Register(MessageConst.CLOSE_UI_PANEL, function(arg)
        local panelName = unpack(arg)
        self:Close(PanelId[panelName])
    end, self)
    self.cfgs = {}
    self.m_panelConfigs = {}
    self.m_openedPanels = setmetatable({}, { __mode = "v" })
    self.m_hidedPanels = setmetatable({}, { __mode = "v" })
    self.m_selfMaintainOrderPanels = setmetatable({}, { __mode = "v" })
    self.m_clearedPanelReverseInfos = {}
    self.m_clearedPanelInfos = {}
    self.m_autoClearScreenKeys = {}
    self.m_orderManagers = {}
    self.m_panel2Handle = {}
    self.m_blockInputKeys = {}
    self.m_showingFullScreenPanel = {}
    self.m_blockObtainWaysJumpKeys = {}
    self.m_recentClosedPanelIds = {}
    self:InitPanelIds()
    self.persistentInputBindingKey = InputManagerInst:CreateGroup(-1)
    self.m_resourceLoader = CS.Beyond.LuaResourceLoader()
    self:_InitOrderManagers()
    local uiNodeAsset = self.m_resourceLoader:LoadGameObject(UIConst.UI_NODE_PREFAB_PATH)
    local uiNodeObj = CSUtils.CreateObject(uiNodeAsset)
    self.uiNode = Utils.bindLuaRef(uiNodeObj)
    self.uiNode.gameObject.name = UNITY_EDITOR and "+ UINode" or "UINode"
    GameObject.DontDestroyOnLoad(self.uiNode.gameObject)
    self.uiRoot = self.uiNode.uiRoot.transform
    self.uiInputBindingGroupMonoTarget = self.uiNode.transform:GetComponent("InputBindingGroupMonoTarget")
    self.uiCanvas = self.uiNode.uiRoot
    self.uiCanvasRect = self.uiCanvas:RectTransform()
    self.worldUICanvas = self.uiNode.worldUIRoot
    self.worldUIRoot = self.uiNode.worldUIRoot.transform
    self.gyroscopeEffect = self.uiNode.worldUIRoot.transform:GetComponent("UIGyroscopeEffect")
    self.m_disabledPanelRoot = self.uiNode.disabledUIRoot
    self.m_disabledPanelRoot.gameObject:SetActive(false)
    self.worldObjectRoot = GameObject("UICreatedWorldObjects").transform
    self.worldObjectRoot.position = Vector3.zero
    GameObject.DontDestroyOnLoad(self.worldObjectRoot.gameObject)
    local planeDistance = CS.Beyond.UI.UIConst.SCREEN_SPACE_CAMERA_PANEL_DISTANCE
    if self.uiCanvas.planeDistance ~= planeDistance then
        logger.error("UICanvas Panel Distance Wrong", self.uiCanvas.planeDistance, planeDistance)
        self.uiCanvas.planeDistance = planeDistance
    end
    self.uiCamera = self.uiNode.uiCamera:GetComponent("Camera")
    CameraManager:SetUpUICamera(self.uiCamera)
    addMetaIndex(self.cfgs, function(_, k)
        local id = self.ids[k]
        if id then
            return self.m_panelConfigs[id]
        end
    end)
end
UIManager.InitPanelIds = HL.Method() << function(self)
    self.ids = {}
    self.m_names = {}
    local nextId = 1
    for name, data in pairs(panelConfig.config) do
        local id = nextId
        nextId = nextId + 1
        self.ids[name] = id
        self.m_names[id] = name
    end
end
UIManager.InitPanelConfigs = HL.Method() << function(self)
    for name, data in pairs(panelConfig.config) do
        local id = self.ids[name]
        local cfg = { name = name, id = id }
        local modelPath = string.format(UIConst.UI_PANEL_MODEL_FILE_PATH, name, name)
        local modelExist = require_check(modelPath)
        if modelExist then
            cfg.modelClass = require_ex(modelPath)[name .. "Model"]
        else
            cfg.modelClass = require_ex("UI/Panels/Base/UIModel").UIModel
        end
        setmetatable(cfg, { __index = data })
        self.m_panelConfigs[id] = cfg
    end
    local backgroundMessage = require_ex(UIConst.UI_BACKGROUND_MESSAGE_PATH).BackgroundMessage
    for ctrlName, msgs in pairs(backgroundMessage.s_messages) do
        for msg, funcName in pairs(msgs) do
            if not MessageConst.isPhaseMsg(msg) then
                Register(msg, function(msgArg)
                    local id = self.ids[ctrlName]
                    local cfg = self.m_panelConfigs[id]
                    if not cfg.ctrlClass then
                        local path = string.format(UIConst.UI_PANEL_CTRL_FILE_PATH, ctrlName, ctrlName)
                        local ctrlClass = require_ex(path)[ctrlName .. "Ctrl"]
                        cfg.ctrlClass = ctrlClass
                    end
                    local ctrlClass = cfg.ctrlClass
                    if HL.TryGet(ctrlClass, "s_overrideMessages") then
                        ctrlClass.s_messages = ctrlClass.s_overrideMessages
                    else
                        ctrlClass.s_messages = ctrlClass.s_messages
                    end
                    if msgArg == nil then
                        ctrlClass[funcName]()
                    else
                        ctrlClass[funcName](msgArg)
                    end
                end, self)
            end
        end
    end
    self:_InitRoots()
end
UIManager.OpenInitPanels = HL.Method() << function(self)
    Input.multiTouchEnabled = true
    self:Open(self.ids.Touch)
    self:Open(self.ids.CommonDrag)
    self.commonTouchPanel = self.cfgs.Touch.ctrl.view.uiTouchPanel
    self:Open(self.ids.MouseIconHint)
    self:Open(self.ids.CommonTips)
    self:Open(self.ids.FullScreenSceneBlur)
    Notify(MessageConst.ON_OPEN_INIT_PANELS)
end
UIManager.Open = HL.Method(HL.Number, HL.Opt(HL.Any, HL.Table)).Return(HL.Opt(HL.Forward("UICtrl"))) << function(self, panelId, arg, callbacks)
    if self:IsOpen(panelId) then
        logger.error("Panel Already Opened", self.m_names[panelId])
        return
    end
    local cfg = self.m_panelConfigs[panelId]
    if not cfg then
        logger.error("No Panel Config", panelId)
        return
    end
    callbacks = callbacks or {}
    Notify(MessageConst.ON_BEFORE_UI_PANEL_OPEN, cfg.name)
    local asset, assetType = self:_LoadPanelAsset(panelId)
    local parent = self:_GetPanelParentTransform(cfg)
    local panelObj
    if UNITY_EDITOR then
        panelObj = CSUtils.CreateObject(asset, self.m_disabledPanelRoot)
        panelObj.gameObject:SetActive(false)
        panelObj.transform:SetParent(parent)
    else
        asset.gameObject:SetActive(false)
        panelObj = CSUtils.CreateObject(asset, parent)
    end
    panelObj.name = string.format("%sPanel", cfg.name)
    local uiCamera = self.uiCamera
    local view = { curPanelCfg = {} }
    if cfg.clearScreen then
        local exceptPanelIds = {}
        if cfg.clearScreen ~= true then
            for _, v in ipairs(cfg.clearScreen) do
                table.insert(exceptPanelIds, self.ids[v])
            end
        end
        self.m_autoClearScreenKeys[panelId] = self:ClearScreen(exceptPanelIds)
    end
    if cfg.blockObtainWaysJump then
        self:ToggleBlockObtainWaysJump(cfg.name, true)
    end
    local refs = panelObj:GetComponent("LuaReference")
    refs:BindToLua(view)
    view.panelCanvas = view.transform:GetComponent("Canvas")
    view.luaPanel = view.transform:GetComponent("LuaPanel")
    view.raycaster = view.transform:GetComponent("GraphicRaycaster")
    view.inputGroup = view.transform:GetComponent("InputBindingGroupMonoTarget")
    UIUtils.initLuaCustomConfig(view)
    view.rectTransform.localScale = Vector3.one
    view.rectTransform.pivot = Vector2.one / 2
    view.rectTransform.anchorMin = Vector2.zero
    view.rectTransform.anchorMax = Vector2.one
    view.rectTransform.offsetMin = Vector2.zero
    view.rectTransform.offsetMax = Vector2.zero
    view.rectTransform.anchoredPosition3D = Vector3.zero
    view.luaPanel.panelId = panelId
    view.luaPanel.panelName = cfg.name
    view.luaPanel.uiCamera = uiCamera
    view.luaPanel.panelDistance = self.uiCanvas.planeDistance
    if cfg.orderType then
        view.luaPanel.panelLevel = UIConst.PANEL_ORDER_TO_PANEL_LEVEL[cfg.orderType]
    end
    view.luaPanel.inited = true
    if not cfg.ctrlClass then
        local name = cfg.name
        local path = string.format(UIConst.UI_PANEL_CTRL_FILE_PATH, name, name)
        local ctrlClass = require_ex(path)[name .. "Ctrl"]
        if HL.TryGet(ctrlClass, "s_overrideMessages") then
            ctrlClass.s_messages = ctrlClass.s_overrideMessages
        else
            ctrlClass.s_messages = ctrlClass.s_messages
        end
        cfg.ctrlClass = ctrlClass
    end
    local ctrl = cfg.ctrlClass()
    ctrl.panelId = panelId
    ctrl.panelCfg = cfg
    ctrl.model = cfg.modelClass()
    ctrl.view = view
    ctrl.loader = CS.Beyond.LuaResourceLoader()
    ctrl.naviGroup = view.transform:GetComponent("UISelectableNaviGroup")
    ctrl.uiCamera = uiCamera
    ctrl.panelDistance = self.uiCanvas.planeDistance
    ctrl.isControllerPanel = assetType == UIConst.PANEL_ASSET_TYPES.Controller
    ctrl.isPCPanel = assetType == UIConst.PANEL_ASSET_TYPES.PC
    ctrl.isDefaultPanel = assetType == UIConst.PANEL_ASSET_TYPES.Default
    ctrl.m_updateKeys = {}
    cfg.ctrl = ctrl
    self.m_openedPanels[panelId] = ctrl
    Notify(MessageConst.ON_UI_PANEL_START_OPEN, cfg.name)
    view.luaPanel.onAnimationInFinished:AddListener(function()
        logger.info("OnAnimationInFinished", cfg.name)
        ctrl:OnAnimationInFinished()
        Notify(MessageConst.ON_UI_PANEL_OPENED, cfg.name)
        local needTrigger = view.luaPanel.animationWrapper == nil or view.luaPanel.animationWrapper.curState ~= CS.Beyond.UI.UIConst.AnimationState.Out
        if needTrigger then
            CS.Beyond.Gameplay.Conditions.OnUIPanelOpen.Trigger(cfg.name, true)
            if GameInstance.player then
                GameInstance.player.guide:OnUIPanelOpened(cfg.name)
            end
        end
        if callbacks.onAnimationInFinished then
            callbacks.onAnimationInFinished()
        end
        self:TryToggleMainCamera(cfg, true)
    end)
    if cfg.selfMaintainOrder then
        self.m_selfMaintainOrderPanels[panelId] = ctrl
    else
        self:_AutoSetPanelOrder(cfg, true)
    end
    panelObj.gameObject:SetActive(true)
    for msg, funcName in pairs(cfg.ctrlClass.s_messages) do
        if not MessageConst.isPhaseMsg(msg) then
            Register(msg, function(msgArg)
                if msgArg == nil then
                    ctrl[funcName](ctrl)
                else
                    ctrl[funcName](ctrl, msgArg)
                end
            end, ctrl)
        end
    end
    local succ, log = xpcall(function()
        ctrl.model:InitModel()
        ctrl:OnCreate(arg)
        ctrl:OnShow()
    end, debug.traceback)
    if not succ then
        logger.error(log)
    end
    ctrl.isFinishedCreation = true
    if cfg.selfMaintainOrder then
        self:CalcOtherSystemPropertyByPanelOrder()
    end
    self:_SendEventUISwitch(cfg, true)
    CS.Beyond.Gameplay.Conditions.OnUIPanelOpen.Trigger(cfg.name, false)
    return ctrl
end
UIManager.PreloadPanelAsset = HL.Method(HL.Number) << function(self, panelId)
    self:_LoadPanelAsset(panelId, true)
end
UIManager.CheckPanelAssetHadLoaded = HL.Method(HL.Number).Return(HL.Boolean) << function(self, panelId)
    local assetInfo = self.m_panel2Handle[panelId]
    return assetInfo ~= nil
end
UIManager._LoadPanelAsset = HL.Method(HL.Number, HL.Opt(HL.Boolean)).Return(HL.Opt(GameObject, HL.Number)) << function(self, panelId, isPreload)
    logger.info("UIManager._LoadPanelAsset", panelId, isPreload)
    self:_UpdatePanelAssetLRU(panelId, true)
    local asset
    local assetType = UIConst.PANEL_ASSET_TYPES.Default
    local assetInfo = self.m_panel2Handle[panelId]
    if not assetInfo then
        local cfg = self.m_panelConfigs[panelId]
        local path
        if DeviceInfo.usingController then
            local ctPath = string.format(UIConst.UI_CONTROLLER_PANEL_PREFAB_PATH, cfg.folder, cfg.name)
            if ResourceManager.CheckExists(ctPath) then
                assetType = UIConst.PANEL_ASSET_TYPES.Controller
                path = ctPath
            end
        end
        if not path and DeviceInfo.isPCorConsole then
            local pcPath = string.format(UIConst.UI_PC_PANEL_PREFAB_PATH, cfg.folder, cfg.name)
            if ResourceManager.CheckExists(pcPath) then
                assetType = UIConst.PANEL_ASSET_TYPES.PC
                path = pcPath
            end
        end
        if not path then
            path = string.format(UIConst.UI_PANEL_PREFAB_PATH, cfg.folder, cfg.name)
        end
        if not isPreload then
            local assetKey
            asset, assetKey = self.m_resourceLoader:LoadGameObject(path)
            self.m_panel2Handle[panelId] = { assetKey, assetType }
        else
            local assetKey
            assetKey = self.m_resourceLoader:LoadGameObjectAsync(path, function(loadedAsset)
                if not assetKey then
                    logger.error("预加载面板时异步调用同步返回了", path)
                    return
                end
                if self.m_panel2Handle[panelId] then
                    self.m_resourceLoader:DisposeHandleByKey(assetKey)
                else
                    self.m_panel2Handle[panelId] = { assetKey, assetType }
                end
            end)
            return
        end
    else
        if isPreload then
            return
        end
        local assetKey = assetInfo[1]
        assetType = assetInfo[2]
        asset = self.m_resourceLoader:GetGameObjectByKey(assetKey)
    end
    return asset, assetType
end
UIManager.TryToggleMainCamera = HL.Method(HL.Table, HL.Boolean) << function(self, cfg, tryCloseCamera)
    if (not cfg) or (not cfg.hideCamera) then
        return
    end
    if tryCloseCamera then
        self.m_showingFullScreenPanel[cfg] = true
    else
        self.m_showingFullScreenPanel[cfg] = nil
    end
    local shouldClose = next(self.m_showingFullScreenPanel) ~= nil
    if shouldClose == self.m_mainCameraClosedByUI then
        return
    end
    if tryCloseCamera then
        CameraManager:AddMainCamCullingMaskConfig("UIManager", UIConst.LAYERS.Nothing)
    else
        CameraManager:RemoveMainCamCullingMaskConfig("UIManager")
    end
    self.m_mainCameraClosedByUI = tryCloseCamera
end
UIManager._CheckCanCloseCamera = HL.Method().Return(HL.Boolean) << function(self)
    for i, openedPanel in pairs(self.m_openedPanels) do
        if self:IsShow(openedPanel.panelId) and openedPanel.panelCfg.hideCamera then
            return true
        end
    end
    return false
end
local defaultNoEventOrderTypes = { [Types.EPanelOrderTypes.Hud] = true, [Types.EPanelOrderTypes.LowerHud] = true, [Types.EPanelOrderTypes.BottomScreenEffect] = true, [Types.EPanelOrderTypes.TopScreenEffect] = true, [Types.EPanelOrderTypes.Toast] = true, [Types.EPanelOrderTypes.Debug] = true, }
UIManager._SendEventUISwitch = HL.Method(HL.Table, HL.Boolean) << function(self, cfg, isEnter)
    if cfg.sendUISwitchEvent == false or (defaultNoEventOrderTypes[cfg.orderType] and not cfg.sendUISwitchEvent) then
        return
    end
    EventLogManagerInst:GameEvent_UISwitch(cfg.name, isEnter)
end
UIManager.AutoOpen = HL.Method(HL.Number, HL.Opt(HL.Any, HL.Boolean, HL.Function)).Return(HL.Opt(HL.Forward("UICtrl"))) << function(self, panelId, arg, forceShow, onShowCallback)
    local isOpen, ctrl = self:IsOpen(panelId)
    if not isOpen then
        return self:Open(panelId, arg)
    else
        if forceShow or self:IsHide(panelId) then
            self:Show(panelId)
        end
        if onShowCallback then
            onShowCallback(ctrl)
        end
        return ctrl
    end
end
UIManager.IsOpen = HL.Method(HL.Number).Return(HL.Boolean, HL.Opt(HL.Forward("UICtrl"))) << function(self, panelId)
    local ctrl = self.m_openedPanels[panelId]
    return ctrl ~= nil, ctrl
end
UIManager.Close = HL.Method(HL.Number) << function(self, panelId)
    if not self:IsOpen(panelId) then
        return
    end
    local cfg = self.m_panelConfigs[panelId]
    local ctrl = cfg.ctrl
    local clearScreenKey = self.m_autoClearScreenKeys[panelId]
    self.m_autoClearScreenKeys[panelId] = nil
    MessageManager:UnregisterAll(ctrl)
    local succ, log = xpcall(function()
        ctrl:OnClose()
        ctrl:Clear()
        ctrl.model:OnClose()
    end, debug.traceback)
    if not succ then
        logger.error(log)
    end
    local gameObject = ctrl.view.gameObject
    local loader = ctrl.loader
    CSUtils.ClearUIComponents(gameObject)
    ctrl.view.luaPanel.onAnimationInFinished:RemoveAllListeners()
    GameObject.DestroyImmediate(gameObject)
    cfg.ctrl = nil
    self.m_openedPanels[panelId] = nil
    self.m_hidedPanels[panelId] = nil
    if ENABLE_LUA_LEAK_CHECK then
        LuaObjectMemoryLeakChecker:AddDetectLuaObject(ctrl)
    end
    loader:DisposeAllHandles()
    if not cfg.isResidentPanel then
        self:_UpdatePanelAssetLRU(panelId, false)
    end
    local hideByOthers = self.m_clearedPanelReverseInfos[panelId]
    if hideByOthers then
        for k, _ in pairs(hideByOthers) do
            local panels = self.m_clearedPanelInfos[k]
            if panels then
                panels[panelId] = nil
            end
        end
        self.m_clearedPanelReverseInfos[panelId] = nil
    end
    if cfg.selfMaintainOrder then
        self.m_selfMaintainOrderPanels[panelId] = nil
    else
        self:_RemoveFromOrderStack(panelId)
    end
    if clearScreenKey then
        self:RecoverScreen(clearScreenKey)
    end
    self:CalcOtherSystemPropertyByPanelOrder()
    if cfg.blockObtainWaysJump then
        self:ToggleBlockObtainWaysJump(cfg.name, false)
    end
    Notify(MessageConst.ON_UI_PANEL_CLOSED, cfg.name)
    CS.Beyond.Gameplay.Conditions.OnUIPanelClose.Trigger(cfg.name)
    self:_SendEventUISwitch(cfg, false)
    self:TryToggleMainCamera(cfg, false)
end
UIManager.Show = HL.Method(HL.Number) << function(self, panelId)
    if not self:IsOpen(panelId) then
        logger.error("Panel Not Open", panelId, self.m_names[panelId])
        return
    end
    if not self.m_hidedPanels[panelId] then
        return
    end
    local hideByOthers = self.m_clearedPanelReverseInfos[panelId] ~= nil
    self.m_hidedPanels[panelId] = nil
    if not hideByOthers then
        self:_InternalShow(panelId)
    end
end
UIManager._InternalShow = HL.Method(HL.Number) << function(self, panelId)
    local ctrl = self.m_openedPanels[panelId]
    ctrl.view.gameObject:SetActive(true)
    self:CalcOtherSystemPropertyByPanelOrder()
    if ctrl.panelCfg.blockObtainWaysJump then
        self:ToggleBlockObtainWaysJump(ctrl.panelCfg.name, true)
    end
    ctrl.view.luaPanel:RecoverAllInput()
    ctrl:SetGameObjectVisible(true)
    ctrl:OnShow()
    Notify(MessageConst.ON_UI_PANEL_SHOW, ctrl.panelCfg.name)
    self:_SendEventUISwitch(ctrl.panelCfg, true)
    CS.Beyond.Gameplay.Conditions.OnUIPanelOpen.Trigger(ctrl.panelCfg.name, false)
end
UIManager.IsShow = HL.Method(HL.Number, HL.Opt(HL.Boolean)).Return(HL.Boolean) << function(self, panelId, ignoreClear)
    return self:IsOpen(panelId) and not self.m_hidedPanels[panelId] and (ignoreClear or not self.m_clearedPanelReverseInfos[panelId])
end
UIManager.Hide = HL.Method(HL.Number) << function(self, panelId)
    if not self:IsOpen(panelId) then
        return
    end
    if self.m_hidedPanels[panelId] then
        return
    end
    self.m_hidedPanels[panelId] = true
    if not self.m_clearedPanelReverseInfos[panelId] then
        self:_InternalHide(panelId)
    end
end
UIManager.HideWithKey = HL.Method(HL.Number, HL.String) << function(self, panelId, key)
    if not self:IsOpen(panelId) then
        return
    end
    local isShow = self:IsShow(panelId)
    local clearedPanelIds = self.m_clearedPanelInfos[key]
    if not clearedPanelIds then
        clearedPanelIds = {}
        self.m_clearedPanelInfos[key] = clearedPanelIds
    end
    local clearedByOthers = self.m_clearedPanelReverseInfos[panelId]
    if not clearedByOthers then
        clearedByOthers = {}
        self.m_clearedPanelReverseInfos[panelId] = clearedByOthers
    end
    clearedPanelIds[panelId] = true
    clearedByOthers[key] = true
    if isShow then
        self:_InternalHide(panelId)
    end
end
UIManager.ShowWithKey = HL.Method(HL.Number, HL.String) << function(self, panelId, key)
    if not self:IsOpen(panelId) or self:IsShow(panelId) then
        return
    end
    local clearedPanelIds = self.m_clearedPanelInfos[key]
    if not clearedPanelIds then
        return
    end
    clearedPanelIds[panelId] = nil
    if not next(clearedPanelIds) then
        self.m_clearedPanelInfos[key] = nil
    end
    local clearedByOthers = self.m_clearedPanelReverseInfos[panelId]
    if clearedByOthers then
        clearedByOthers[key] = nil
        if not next(clearedByOthers) then
            self.m_clearedPanelReverseInfos[panelId] = nil
        end
    end
    if self:IsShow(panelId) then
        self:_InternalShow(panelId)
    end
end
UIManager._InternalHide = HL.Method(HL.Number) << function(self, panelId)
    local ctrl = self.m_openedPanels[panelId]
    local cfg = ctrl.panelCfg
    ctrl:OnHide()
    Notify(MessageConst.ON_UI_PANEL_HIDE, ctrl.panelCfg.name)
    ctrl:SetGameObjectVisible(false)
    ctrl.view.gameObject:SetActive(false)
    self:CalcOtherSystemPropertyByPanelOrder()
    if cfg.blockObtainWaysJump then
        self:ToggleBlockObtainWaysJump(cfg.name, false)
    end
    self:_SendEventUISwitch(ctrl.panelCfg, false)
    self:TryToggleMainCamera(cfg, false)
    CS.Beyond.Gameplay.Conditions.OnUIPanelClose.Trigger(cfg.name)
end
UIManager.IsHide = HL.Method(HL.Number).Return(HL.Boolean) << function(self, panelId)
    return self:IsOpen(panelId) and not self:IsShow(panelId)
end
UIManager.ClearScreen = HL.Method(HL.Opt(HL.Table)).Return(HL.Opt(HL.Number)) << function(self, exceptPanelIds)
    if self.m_inClearScreen then
        logger.error("清屏中，不能额外操作")
        return
    end
    local clearScreenKey, panelIds = self:_GetClearScreenTargets(exceptPanelIds)
    self.m_ignoreBlockOrderUpdate = true
    for _, id in ipairs(panelIds) do
        self:_InternalHide(id)
    end
    self.m_ignoreBlockOrderUpdate = false
    self:CalcOtherSystemPropertyByPanelOrder()
    logger.info("UIManager.ClearScreen", clearScreenKey)
    return clearScreenKey
end
UIManager._GetClearScreenTargets = HL.Method(HL.Opt(HL.Table)).Return(HL.Number, HL.Table) << function(self, exceptPanelIds)
    local clearedPanels = {}
    local clearScreenKey = self.m_nextClearScreenKey
    self.m_nextClearScreenKey = self.m_nextClearScreenKey + 1
    self.m_clearedPanelInfos[clearScreenKey] = clearedPanels
    local panelIds = {}
    for id, ctrl in pairs(self.m_openedPanels) do
        if not exceptPanelIds or not lume.find(exceptPanelIds, id) then
            if ctrl:GetCurPanelCfg("clearedPanel") then
                local isShowing = self:IsShow(id)
                clearedPanels[id] = true
                local clearedByOthers = self.m_clearedPanelReverseInfos[id]
                if not clearedByOthers then
                    clearedByOthers = {}
                    self.m_clearedPanelReverseInfos[id] = clearedByOthers
                end
                clearedByOthers[clearScreenKey] = true
                if isShowing then
                    table.insert(panelIds, id)
                end
            end
        end
    end
    return clearScreenKey, panelIds
end
UIManager.m_inClearScreen = HL.Field(HL.Boolean) << false
UIManager.m_curClearScreenKey = HL.Field(HL.Number) << -1
UIManager.ClearScreenWithOutAnimation = HL.Method(HL.Function, HL.Opt(HL.Table)) << function(self, callback, exceptPanelIds)
    if self.m_inClearScreen then
        logger.error("清屏中，不能额外操作")
        callback()
        return
    end
    self.m_inClearScreen = true
    local clearScreenKey, panelIds = self:_GetClearScreenTargets(exceptPanelIds)
    self.m_curClearScreenKey = clearScreenKey
    logger.info("UIManager.ClearScreenWithOutAnimation", clearScreenKey)
    self.m_ignoreBlockOrderUpdate = true
    local count = #panelIds
    if count == 0 then
        TimerManager:StartTimer(0, function()
            self.m_ignoreBlockOrderUpdate = false
            self:CalcOtherSystemPropertyByPanelOrder()
            self.m_inClearScreen = false
            self.m_curClearScreenKey = -1
            callback(clearScreenKey)
        end, true, self)
        return
    end
    for _, v in ipairs(panelIds) do
        local panelId = v
        local uiCtrl = self.m_openedPanels[panelId]
        if uiCtrl ~= nil then
            uiCtrl:PlayAnimationOutWithCallback(function()
                self:_InternalHide(panelId)
            end)
        end
    end
    CoroutineManager:StartCoroutine(function()
        while true do
            coroutine.step()
            local allDone = true
            for _, v in ipairs(panelIds) do
                local panelId = v
                local ctrl = self.m_openedPanels[panelId]
                if ctrl ~= nil and ctrl.view.gameObject.activeSelf then
                    allDone = false
                    break
                end
            end
            if allDone then
                self.m_ignoreBlockOrderUpdate = false
                self:CalcOtherSystemPropertyByPanelOrder()
                self.m_inClearScreen = false
                self.m_curClearScreenKey = -1
                callback(clearScreenKey)
                break
            end
        end
    end, self)
end
UIManager.RecoverScreen = HL.Method(HL.Number).Return(HL.Opt(HL.Number)) << function(self, clearScreenKey)
    if self.m_inClearScreen then
        logger.error("清屏中，不能额外操作，时序有一点问题")
        if clearScreenKey == self.m_curClearScreenKey then
            return
        end
    end
    local clearedPanels = self.m_clearedPanelInfos[clearScreenKey]
    if not clearedPanels then
        return -1
    end
    self.m_clearedPanelInfos[clearScreenKey] = nil
    self.m_ignoreBlockOrderUpdate = true
    for id, _ in pairs(clearedPanels) do
        local clearedByOthers = self.m_clearedPanelReverseInfos[id]
        if clearedByOthers then
            clearedByOthers[clearScreenKey] = nil
            if not next(clearedByOthers) then
                self.m_clearedPanelReverseInfos[id] = nil
            end
            if self:IsShow(id) then
                self:_InternalShow(id)
            end
        end
    end
    self.m_ignoreBlockOrderUpdate = false
    self:CalcOtherSystemPropertyByPanelOrder()
    logger.info("UIManager.RecoverScreen", clearScreenKey)
    return -1
end
UIManager._InitOrderManagers = HL.Method() << function(self)
    local stackClass = require_ex("Common/Utils/DataStructure/Stack")
    for _, v in pairs(Types.EPanelOrderTypes) do
        local manager = {}
        manager.stack = stackClass()
        manager.initOrder = v * self.m_panelOrderTypeInterval
        manager.maxOrder = manager.initOrder + self.m_panelOrderTypeInterval - self.m_panelOrderInterval
        manager.nextPanelOrder = manager.initOrder
        self.m_orderManagers[v] = manager
    end
end
UIManager._AutoSetPanelOrder = HL.Method(HL.Table, HL.Boolean) << function(self, cfg, isInit)
    isInit = isInit == true
    local orderType = cfg.orderType
    local manager = self.m_orderManagers[orderType]
    if not manager then
        logger.error("No Order Manager", orderType, inspect(cfg))
        return
    end
    local stack = manager.stack
    local recalculated = false
    if manager.nextPanelOrder > manager.maxOrder then
        logger.warn("动态面板层级超出区间，开始重新计算层级", orderType, manager.nextPanelOrder, manager.maxOrder)
        recalculated = true
        manager.nextPanelOrder = manager.initOrder
        if stack:Count() > 0 then
            for i = stack:BottomIndex(), stack:TopIndex() do
                local id = stack:Get(i)
                self.m_openedPanels[id]:SetSortingOrder(manager.nextPanelOrder, isInit)
                manager.nextPanelOrder = manager.nextPanelOrder + self.m_panelOrderInterval
            end
        end
    end
    if manager.nextPanelOrder > manager.maxOrder then
        logger.error("动态面板层级超出区间", orderType, manager.nextPanelOrder, manager.maxOrder, inspect(stack))
    end
    cfg.ctrl:SetSortingOrder(manager.nextPanelOrder, isInit)
    manager.nextPanelOrder = manager.nextPanelOrder + self.m_panelOrderInterval
    stack:Push(cfg.id)
    self:CalcOtherSystemPropertyByPanelOrder()
    if recalculated then
        Notify(MessageConst.ON_PANEL_ORDER_RECALCULATED)
    end
end
UIManager._RemoveFromOrderStack = HL.Method(HL.Number) << function(self, panelId)
    local cfg = self.m_panelConfigs[panelId]
    if cfg.selfMaintainOrder then
        return
    end
    local manager = self.m_orderManagers[cfg.orderType]
    local stack = manager.stack
    if stack:Peek() == panelId then
        manager.nextPanelOrder = manager.nextPanelOrder - self.m_panelOrderInterval
    end
    stack:Delete(panelId)
end
UIManager.SetTopOrder = HL.Method(HL.Number) << function(self, panelId)
    if not self:IsOpen(panelId) then
        logger.error("Panel Not Open", panelId)
        return
    end
    local cfg = self.m_panelConfigs[panelId]
    if cfg.selfMaintainOrder then
        logger.error("Panel is selfMaintainOrder, can't SetTopOrder")
    end
    self:_RemoveFromOrderStack(panelId)
    self:_AutoSetPanelOrder(cfg, false)
end
UIManager.CalcOtherSystemPropertyByPanelOrder = HL.Method() << function(self)
    if self.m_ignoreBlockOrderUpdate then
        return
    end
    self.m_curBlockKeyboardEventPanelOrder = self:_FindTopPanelProperty(function(cfg, ctrl)
        if ctrl:GetBlockKeyboardEvent() then
            return ctrl:GetSortingOrder()
        end
    end) or -1
    for _, type in pairs(Types.EPanelOrderTypes) do
        local manager = self.m_orderManagers[type]
        local stack = manager.stack
        if stack:Count() > 0 then
            local topIndex, bottomIndex = stack:TopIndex(), stack:BottomIndex()
            for i = bottomIndex, topIndex do
                local id = stack:Get(i)
                local ctrl = self.m_openedPanels[id]
                ctrl:UpdateInputGroupState()
            end
        end
    end
    for _, ctrl in pairs(self.m_selfMaintainOrderPanels) do
        ctrl:UpdateInputGroupState()
    end
    local multiTouchType = self:_FindTopPanelProperty(function(cfg, ctrl)
        local t = ctrl:GetMultiTouchType()
        if t and t ~= Types.EPanelMultiTouchTypes.Both then
            return t
        end
    end) or Types.EPanelMultiTouchTypes.Enable
    if multiTouchType ~= Types.EPanelMultiTouchTypes.Both then
        local enable = multiTouchType == Types.EPanelMultiTouchTypes.Enable
        if Input.multiTouchEnabled ~= enable then
            Input.multiTouchEnabled = enable
        end
    end
    local cursorCfgName = DeviceInfo.usingController and "virtualMouseMode" or "realMouseMode"
    local cursorMode = self:_FindTopPanelProperty(function(cfg, ctrl)
        local mode = ctrl:GetCurPanelCfg(cursorCfgName)
        if mode ~= Types.EPanelMouseMode.NotNeedShow then
            return mode
        end
    end) or Types.EPanelMouseMode.NotNeedShow
    InputManagerInst:ToggleCursorInHideCursorMode("blocked", cursorMode == Types.EPanelMouseMode.NeedShow)
    self:_ToggleAutoShowCursor(cursorMode == Types.EPanelMouseMode.AutoShow)
    if InputManagerInst.virtualMouse then
        if cursorMode == Types.EPanelMouseMode.NotNeedShow then
            InputManagerInst.virtualMouse.keepMousePosOnEnable = false
        elseif cursorMode == Types.EPanelMouseMode.ForceHide then
            InputManagerInst.virtualMouse.keepMousePosOnEnable = true
        end
    end
    local gyroscopeEffectType = self:_FindTopPanelProperty(function(cfg, ctrl)
        local t = ctrl:GetCurPanelCfg("gyroscopeEffect")
        if t and t ~= Types.EPanelGyroscopeEffect.Both then
            return t
        end
    end) or Types.EPanelGyroscopeEffect.Enable
    if gyroscopeEffectType ~= Types.EPanelGyroscopeEffect.Both then
        local enable = gyroscopeEffectType == Types.EPanelGyroscopeEffect.Enable
        self.gyroscopeEffect.enableDetect = enable
    end
    Notify(MessageConst.ON_BLOCK_KEYBOARD_EVENT_PANEL_ORDER_CHANGED)
end
UIManager.CurBlockKeyboardEventPanelOrder = HL.Method().Return(HL.Number) << function(self)
    return self.m_curBlockKeyboardEventPanelOrder
end
UIManager.GetPanelOrder = HL.Method(HL.Number).Return(HL.Opt(HL.Number)) << function(self, panelId)
    local ctrl = self.m_openedPanels[panelId]
    if not ctrl then
        return
    end
    return ctrl:GetSortingOrder()
end
UIManager._FindTopPanelProperty = HL.Method(HL.Function).Return(HL.Opt(HL.Any)) << function(self, checkFunc)
    local topPanelOrder, result = -1, nil
    for type = Types.MaxPanelOrderType, 1, -1 do
        local manager = self.m_orderManagers[type]
        local stack = manager.stack
        if stack:Count() > 0 then
            local topIndex, bottomIndex = stack:TopIndex(), stack:BottomIndex()
            for i = topIndex, bottomIndex, -1 do
                local id = stack:Get(i)
                if self:IsShow(id) then
                    local cfg = self.m_panelConfigs[id]
                    local ctrl = cfg.ctrl
                    local value = checkFunc(cfg, ctrl)
                    if value ~= nil then
                        topPanelOrder = ctrl:GetSortingOrder()
                        result = value
                        break
                    end
                end
            end
        end
        if result then
            break
        end
    end
    for id, ctrl in pairs(self.m_selfMaintainOrderPanels) do
        if self:IsShow(id) then
            local cfg = self.m_panelConfigs[id]
            local value = checkFunc(cfg, ctrl)
            local order = ctrl:GetSortingOrder()
            if value ~= nil and order > topPanelOrder then
                topPanelOrder = order
                result = value
            end
        end
    end
    return result
end
UIManager.m_isClosingAll = HL.Field(HL.Boolean) << false
UIManager._CloseAllUI = HL.Method(HL.Boolean) << function(self, isChangeScene)
    self.m_isClosingAll = true
    for k, v in pairs(self.m_panelConfigs) do
        if (not isChangeScene or v.closeWhenChangeScene) and self:IsOpen(k) then
            local succ, log = xpcall(self.Close, debug.traceback, self, k)
            if not succ then
                logger.error("_CloseAllUI Fail", v.name, log)
            end
        end
    end
    self.m_isClosingAll = false
    self:ReleaseCachedPanelAsset()
end
UIManager.SetUICameraFOV = HL.Method(HL.Number) << function(self, fov)
    if self.uiCamera then
        self.uiCamera.fieldOfView = fov
        local scaleHelper = self.worldUIRoot:GetComponent("UICanvasScaleHelper")
        scaleHelper:TryUpdateCanvasFitMode()
    end
end
UIManager.GetUICameraFOV = HL.Method().Return(HL.Number) << function(self)
    if self.uiCamera then
        return self.uiCamera.fieldOfView
    else
        return -1
    end
end
UIManager.m_rootInfos = HL.Field(HL.Table)
UIManager.m_panel2RootDic = HL.Field(HL.Table)
UIManager._InitRoots = HL.Method() << function(self)
    self.m_rootInfos = {}
    self.m_panel2RootDic = {}
    for name, cfg in pairs(rootConfig.config) do
        local info = { name = name, cfg = cfg, }
        local assetPath = string.format(UIConst.UI_ROOT_PREFAB_PATH, cfg.folder, name)
        local asset = self.m_resourceLoader:LoadGameObject(assetPath)
        local rootObj = CSUtils.CreateObject(asset, self.uiRoot)
        rootObj.name = string.format("%sRoot", name)
        info.gameObject = rootObj
        info.transform = rootObj.transform
        info.luaUIRoot = rootObj:GetComponent("LuaUIRoot")
        info.rectTransform = rootObj:GetComponent("RectTransform")
        info.rectTransform.localScale = Vector3.one
        info.rectTransform.pivot = Vector2.one / 2
        info.rectTransform.anchorMin = Vector2.zero
        info.rectTransform.anchorMax = Vector2.one
        info.rectTransform.offsetMin = Vector2.zero
        info.rectTransform.offsetMax = Vector2.zero
        self.m_rootInfos[name] = info
        for panelName, _ in pairs(info.luaUIRoot.nodeDic.data) do
            if self.m_panel2RootDic[panelName] then
                logger.error("面板已经被其他Root使用", panelName, self.m_panel2RootDic[panelName].name)
            else
                self.m_panel2RootDic[panelName] = info
            end
        end
    end
end
UIManager._GetPanelParentTransform = HL.Method(HL.Table).Return(Transform) << function(self, panelCfg)
    if panelCfg.isWorldUI then
        return self.worldUIRoot
    end
    local name = panelCfg.name
    local rootInfo = self.m_panel2RootDic[name]
    if rootInfo then
        return rootInfo.luaUIRoot.nodeDic:get_Item(name).transform
    end
    return self.uiRoot
end
UIManager.Dispose = HL.Method() << function(self)
    TimerManager:ClearAllTimer(self)
    self:_CloseAllUI(false)
    InputManagerInst:DeleteGroup(self.persistentInputBindingKey)
    if self.uiNode ~= nil then
        GameObject.DestroyImmediate(self.uiNode.gameObject)
        self.uiNode = nil
    end
    if self.worldObjectRoot ~= nil then
        GameObject.DestroyImmediate(self.worldObjectRoot.gameObject)
        self.worldObjectRoot = nil
    end
    self.m_resourceLoader:DisposeAllHandles()
end
UIManager._ToggleUIInputBinding = HL.Method(HL.Boolean, HL.String) << function(self, active, key)
    if active then
        self.m_blockInputKeys[key] = nil
    else
        self.m_blockInputKeys[key] = true
    end
    active = next(self.m_blockInputKeys) == nil
    InputManagerInst:ToggleGroup(self.uiInputBindingGroupMonoTarget.groupId, active)
end
UIManager.m_autoShowCursorCor = HL.Field(HL.Thread)
UIManager._ToggleAutoShowCursor = HL.Method(HL.Boolean) << function(self, active)
    if not active then
        if self.m_autoShowCursorCor then
            logger.info("UIManager._ToggleAutoShowCursor AutoShowCursor", false)
            InputManagerInst:ToggleCursorInHideCursorMode("AutoShowCursor", false)
            CoroutineManager:ClearCoroutine(self.m_autoShowCursorCor)
            self.m_autoShowCursorCor = nil
        end
        return
    end
    if self.m_autoShowCursorCor then
        return
    end
    local nextHideTime
    self.m_autoShowCursorCor = CoroutineManager:StartCoroutine(function()
        while true do
            coroutine.step()
            local needShow = Input.anyKeyDown
            if needShow then
                logger.info("UIManager._ToggleAutoShowCursor AutoShowCursor", true)
                InputManagerInst:ToggleCursorInHideCursorMode("AutoShowCursor", true)
                nextHideTime = Time.unscaledTime + 5
            else
                if nextHideTime and Time.unscaledTime >= nextHideTime then
                    logger.info("UIManager._ToggleAutoShowCursor AutoShowCursor", false)
                    InputManagerInst:ToggleCursorInHideCursorMode("AutoShowCursor", false)
                    nextHideTime = nil
                end
            end
        end
    end, self)
end
UIManager.m_blockObtainWaysJumpKeys = HL.Field(HL.Table)
UIManager.ToggleBlockObtainWaysJump = HL.Method(HL.String, HL.Boolean) << function(self, name, shouldBlock)
    if shouldBlock then
        self.m_blockObtainWaysJumpKeys[name] = true
    else
        self.m_blockObtainWaysJumpKeys[name] = nil
    end
end
UIManager.ShouldBlockObtainWaysJump = HL.Method().Return(HL.Boolean) << function(self)
    return next(self.m_blockObtainWaysJumpKeys) ~= nil
end
UIManager.GetOpenedPanels = HL.Method().Return(HL.Number) << function(self)
    local count = 0
    for _, __ in pairs(self.m_openedPanels) do
        count = count + 1
    end
    return count
end
UIManager.GetHidedPanels = HL.Method().Return(HL.Number) << function(self)
    local count = 0
    for _, __ in pairs(self.m_hidedPanels) do
        count = count + 1
    end
    return count
end
UIManager.IsInFullScreenUI = HL.Method().Return(HL.Boolean) << function(self)
    for id, ctrl in pairs(self.m_openedPanels) do
        if self:IsShow(id) then
            if ctrl:GetCurPanelCfg("hideCamera") then
                return true
            end
        end
    end
    return false
end
UIManager.Dump = HL.Method().Return(HL.String) << function(self)
    return self:GetCurPanelDebugInfo()
end
UIManager.GetCurPanelDebugInfo = HL.Method().Return(HL.String) << function(self)
    local infos = {}
    for type = Types.MaxPanelOrderType, 1, -1 do
        local manager = self.m_orderManagers[type]
        local stack = manager.stack
        if stack:Count() > 0 then
            table.insert(infos, "----------------Layer " .. type .. "----------------")
            local topIndex, bottomIndex = stack:TopIndex(), stack:BottomIndex()
            for i = topIndex, bottomIndex, -1 do
                local id = stack:Get(i)
                local cfg = self.m_panelConfigs[id]
                local ctrl = cfg.ctrl
                table.insert(infos, string.format("%d\t%s\t%d\t%s", id, self:IsShow(id), ctrl:GetSortingOrder(), cfg.name))
            end
        end
    end
    return table.concat(infos, "\n")
end
UIManager.m_recentClosedPanelIds = HL.Field(HL.Table)
UIManager.m_panelAssetLRUCapacity = HL.Field(HL.Number) << 5
UIManager._UpdatePanelAssetLRU = HL.Method(HL.Number, HL.Boolean) << function(self, panelId, isOpen)
    if self.m_isClosingAll then
        return
    end
    if isOpen then
        self:_RemoveFromPanelAssetLRU(panelId)
        return
    end
    local count = #self.m_recentClosedPanelIds
    if self.m_recentClosedPanelIds[count] == panelId then
        return
    end
    local index
    for k, v in ipairs(self.m_recentClosedPanelIds) do
        if v == panelId then
            index = k
            break
        end
    end
    if not index then
        if count >= self.m_panelAssetLRUCapacity then
            local removedCount = count - self.m_panelAssetLRUCapacity + 1
            for k = 1, count do
                if k <= removedCount then
                    local removedPanelId = self.m_recentClosedPanelIds[k]
                    local assetInfo = self.m_panel2Handle[removedPanelId]
                    if assetInfo then
                        self.m_panel2Handle[removedPanelId] = nil
                        self.m_resourceLoader:DisposeHandleByKey(assetInfo[1])
                        logger.info("UIManager._UpdatePanelAssetLRU DisposeHandleByKey", removedPanelId, self.m_names[removedPanelId])
                    end
                end
                self.m_recentClosedPanelIds[k] = self.m_recentClosedPanelIds[k + removedCount]
            end
        end
        table.insert(self.m_recentClosedPanelIds, panelId)
    else
        for k = index, count - 1 do
            self.m_recentClosedPanelIds[k] = self.m_recentClosedPanelIds[k + 1]
        end
        self.m_recentClosedPanelIds[count] = panelId
    end
end
UIManager.ReleaseCachedPanelAsset = HL.Method() << function(self)
    for panelId, assetInfo in pairs(self.m_panel2Handle) do
        if not self:IsOpen(panelId) then
            self.m_panel2Handle[panelId] = nil
            local assetKey = assetInfo[1]
            self.m_resourceLoader:DisposeHandleByKey(assetKey)
        end
    end
    self.m_recentClosedPanelIds = {}
end
UIManager._RemoveFromPanelAssetLRU = HL.Method(HL.Number) << function(self, panelId)
    local index
    for k, v in ipairs(self.m_recentClosedPanelIds) do
        if v == panelId then
            index = k
            break
        end
    end
    if index then
        table.remove(self.m_recentClosedPanelIds, index)
    end
end
HL.Commit(UIManager)
return UIManager