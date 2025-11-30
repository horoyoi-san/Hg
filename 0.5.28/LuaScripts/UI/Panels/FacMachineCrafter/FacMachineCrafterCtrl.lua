local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacMachineCrafter
FacMachineCrafterCtrl = HL.Class('FacMachineCrafterCtrl', uiCtrl.UICtrl)
local SWITCH_LIQUID_MODE_POPUP_TITLE_TEXT_ID = "ui_fac_pipe_mode_close_info_title"
local SWITCH_LIQUID_MODE_POPUP_DESC_TEXT_ID = "ui_fac_pipe_mode_close_info_des"
local SWITCH_LIQUID_MODE_POPUP_TOGGLE_TEXT_ID = "ui_fac_pipe_mode_close_info_choose"
local SWITCH_LIQUID_MODE_POPUP_LOCAL_DATA_KEY = "hide_fac_machine_crafter_mode_switch_pop_up"
local START_CACHE_COUNT = 1
local MAX_CACHE_COUNT = 4
FacMachineCrafterCtrl.s_messages = HL.StaticField(HL.Table) << {}
FacMachineCrafterCtrl.m_nodeId = HL.Field(HL.Any)
FacMachineCrafterCtrl.m_uiInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.BuildingUIInfo_Producer)
FacMachineCrafterCtrl.m_onBuildingFormulaChanged = HL.Field(HL.Function)
FacMachineCrafterCtrl.m_cachesMap = HL.Field(HL.Table)
FacMachineCrafterCtrl.m_normalSlotList = HL.Field(HL.Table)
FacMachineCrafterCtrl.m_hideModeSwitchPopUp = HL.Field(HL.Boolean) << false
FacMachineCrafterCtrl.m_lastProgressFormulaId = HL.Field(HL.String) << ""
FacMachineCrafterCtrl.m_isInventoryLocked = HL.Field(HL.Boolean) << false
FacMachineCrafterCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_uiInfo = arg.uiInfo
    local nodeId = self.m_uiInfo.nodeId
    self.m_nodeId = nodeId
    self.m_cachesMap = {}
    self.view.inventoryArea:InitInventoryArea()
    self.m_isInventoryLocked = FactoryUtils.isBuildingInventoryLocked(nodeId)
    self.view.inventoryArea:LockInventoryArea(self.m_isInventoryLocked)
    self:_StartCoroutine(function()
        while true do
            coroutine.step()
            self.view.facProgressNode:UpdateProgress(self.m_uiInfo.producer.currentProgress)
            self:_UpdateGainButtonState()
        end
    end)
    self.view.formulaNode:InitFormulaNode(self.m_uiInfo)
    self.m_onBuildingFormulaChanged = function()
        self:_RefreshFormulaInfo()
    end
    self.m_uiInfo.onFormulaChanged:AddListener(self.m_onBuildingFormulaChanged)
    self:_RefreshFormulaInfo()
    self.view.buildingCommon:InitBuildingCommon(self.m_uiInfo, {
        onStateChanged = function(state)
            local isBlocked = state == GEnums.FacBuildingState.Blocked
            self.view.cacheArea:RefreshAreaBlockState(isBlocked)
            self.view.facProgressNode:SwitchAudioPlayingState(state == GEnums.FacBuildingState.Normal)
        end
    })
    self:_RefreshCrafterWidth()
    self.view.cachePipe:InitFacCachePipe(self.m_uiInfo, { needModeSwitch = true })
    self:_InitModeSwitchNode()
    self.view.cacheAreaCanvasGroup.alpha = 0
    self.view.cacheArea:InitFacCacheArea({
        buildingInfo = self.m_uiInfo,
        outChangedCallback = function(cacheItems)
            self:_RefreshCacheMap(cacheItems)
        end,
        onInitializeFinished = function()
            self.view.cacheAreaCanvasGroup.alpha = 1
            self:_InitCacheBelt()
        end,
    })
    self.view.gainBtn.onClick:AddListener(function()
        self.view.cacheArea:GainAreaOutItems()
    end)
    GameInstance.remoteFactoryManager:RegisterInterestedUnitId(nodeId)
    local NaviGroupSwitcher = require_ex("Common/Utils/UI/NaviGroupSwitcher").NaviGroupSwitcher
    self.m_naviGroupSwitcher = NaviGroupSwitcher(self.view.inputGroup.groupId, nil, true)
    local naviGroupInfos = {}
    table.insert(naviGroupInfos, { naviGroup = self.view.content, text = Language.LUA_INV_NAVI_SWITCH_TO_MACHINE, })
    self.view.inventoryArea:AddNaviGroupSwitchInfo(naviGroupInfos)
    self.m_naviGroupSwitcher:ChangeGroupInfos(naviGroupInfos)
    self.view.content:NaviToThisGroup()
    InputManagerInst:ChangeParent(true, self.view.buildingCommon.view.closeButton.groupId, self.view.contentInputBindingGroupMonoTarget.groupId)
end
FacMachineCrafterCtrl.m_naviGroupSwitcher = HL.Field(HL.Forward('NaviGroupSwitcher'))
FacMachineCrafterCtrl.OnClose = HL.Override() << function(self)
    self.m_uiInfo.onFormulaChanged:RemoveListener(self.m_onBuildingFormulaChanged)
    GameInstance.remoteFactoryManager:UnregisterInterestedUnitId(self.m_nodeId)
end
FacMachineCrafterCtrl._InitCacheBelt = HL.Method() << function(self)
    self.view.cacheBeltCanvasGroup.alpha = 0
    self.view.cacheBelt:InitFacCacheBelt(self.m_uiInfo, {
        noGroup = false,
        inEndSlotGroupGetter = function()
            return self.view.cacheArea:GetAreaInRepositoryNormalSlotGroup()
        end,
        outEndSlotGroupGetter = function()
            return self.view.cacheArea:GetAreaOutRepositoryNormalSlotGroup()
        end,
        onInitializeFinished = function()
            self.view.cacheBeltCanvasGroup.alpha = 1
        end
    })
end
FacMachineCrafterCtrl._InitModeSwitchNode = HL.Method() << function(self)
    self.view.modeNode.gameObject:SetActive(false)
    local nodePredefinedParam = self.m_uiInfo.nodeHandler.predefinedParam
    local needModeNode = false
    if nodePredefinedParam ~= nil and nodePredefinedParam.producer ~= nil then
        needModeNode = nodePredefinedParam.producer.enableModeSwitch
    else
        local domainHasMode = FactoryUtils.isDomainSupportPipe()
        local buildingHasMode = FactoryUtils.checkBuildingHasMode(self.m_uiInfo.nodeHandler.templateId, FacConst.FAC_FORMULA_MODE_MAP.LIQUID)
        local buildingModeUnlocked = GameInstance.player.remoteFactory.core:IsBuildingModeUnlocked(FacConst.FAC_FORMULA_MODE_MAP.LIQUID, self.m_uiInfo.nodeHandler.templateId)
        needModeNode = domainHasMode and buildingHasMode and buildingModeUnlocked
    end
    if not needModeNode then
        return
    end
    self.view.modeNode.gameObject:SetActive(true)
    self.view.modeNode.button.onClick:AddListener(function()
        self:_OnModeSwitchButtonClicked()
    end)
    local formulaMan = self.m_uiInfo.formulaMan
    if formulaMan ~= nil then
        self:_RefreshModeNodeDisplayState(formulaMan.currentMode == FacConst.FAC_FORMULA_MODE_MAP.NORMAL)
    end
end
FacMachineCrafterCtrl._GetMachineFormulaId = HL.Method().Return(HL.String) << function(self)
    local lockFormulaId = FactoryUtils.getMachineCraftLockFormulaId(self.m_uiInfo.nodeId)
    if not string.isEmpty(lockFormulaId) then
        return lockFormulaId
    end
    if not string.isEmpty(self.m_uiInfo.formulaId) then
        return self.m_uiInfo.formulaId
    end
    return self.m_uiInfo.lastFormulaId
end
FacMachineCrafterCtrl._RefreshFormulaInfo = HL.Method() << function(self)
    local id = self:_GetMachineFormulaId()
    local isFormulaMissing = string.isEmpty(id)
    if isFormulaMissing then
        self.view.formulaNode:RefreshDisplayFormula()
        self.view.facProgressNode:InitFacProgressNode(-1, -1)
        self.view.facProgressNode:SwitchAudioPlayingState(false)
        self.m_lastProgressFormulaId = id
        return
    end
    if id == self.m_lastProgressFormulaId then
        return
    end
    local craftInfo = FactoryUtils.parseMachineCraftData(id)
    local craftData = Tables.factoryMachineCraftTable:GetValue(id)
    local time = FactoryUtils.getCraftNeedTime(craftData)
    self.view.formulaNode:RefreshDisplayFormula(craftInfo)
    local skillBroad = self.m_uiInfo.skillBoard
    local colorStr = ""
    if skillBroad then
        if skillBroad.speedDeltaScale > 0 then
            colorStr = UIConst.FAC_BUILDING_BUFF_COLOR_STR
        elseif skillBroad.speedDeltaScale < 0 then
            colorStr = UIConst.FAC_BUILDING_DEBUFF_COLOR_STR
        end
    end
    self.view.facProgressNode:InitFacProgressNode(time, craftData.totalProgress * FacConst.CRAFT_PROGRESS_MULTIPLIER, colorStr, function()
        self.view.cacheArea:PlayArrowAnimation("facmac_decoarrow_loop")
        AudioAdapter.PostEvent("au_ui_fac_yield")
    end, function()
        self:_PlayProgressFinishedAnimation()
    end)
    self.m_lastProgressFormulaId = id
    self.view.facProgressNode:SwitchAudioPlayingState(not string.isEmpty(self.m_uiInfo.formulaId))
end
FacMachineCrafterCtrl._RefreshCrafterWidth = HL.Method() << function(self)
    local isWide = self.view.buildingCommon.bgRatio > 1
    local cfg = self.view.config
    self.view.cacheBelt.view.inBeltGroup.anchoredPosition = Vector2(isWide and cfg.WIDE_IN_BELT_POS_X or cfg.NORMAL_IN_BELT_POS_X, self.view.cacheBelt.view.inBeltGroup.anchoredPosition.y)
    self.view.cacheBelt.view.outBeltGroup.anchoredPosition = Vector2(isWide and cfg.WIDE_OUT_BELT_POS_X or cfg.NORMAL_OUT_BELT_POS_X, self.view.cacheBelt.view.inBeltGroup.anchoredPosition.y)
    local inWidth = isWide and cfg.WIDE_IN_LINE_WIDTH or cfg.NORMAL_IN_LINE_WIDTH
    local outWidth = isWide and cfg.WIDE_OUT_LINE_WIDTH or cfg.NORMAL_OUT_LINE_WIDTH
    self.view.cacheArea.view.inRepositoryList.repository1.view.slotCell.view.itemSlot.view.facLineCell:ChangeLineWidth(inWidth)
    self.view.cacheArea.view.inRepositoryList.repository2.view.slotCell.view.itemSlot.view.facLineCell:ChangeLineWidth(inWidth)
    self.view.cacheArea.view.outRepositoryList.repository1.view.slotCell.view.itemSlot.view.facLineCell:ChangeLineWidth(outWidth)
    self.view.cacheArea.view.outRepositoryList.repository2.view.slotCell.view.itemSlot.view.facLineCell:ChangeLineWidth(outWidth)
end
FacMachineCrafterCtrl._RefreshCacheMap = HL.Method(HL.Userdata) << function(self, cache)
    if cache == nil then
        return
    end
    local componentId = cache.componentId
    if self.m_cachesMap[componentId] == nil then
        self.m_cachesMap[componentId] = cache
    end
end
FacMachineCrafterCtrl._UpdateGainButtonState = HL.Method() << function(self)
    local findItem = false
    for i = START_CACHE_COUNT, MAX_CACHE_COUNT do
        local cache = self.m_uiInfo:GetCache(i, false, false)
        if cache and cache.operationItemsInfo.Count > 0 then
            findItem = true
            break
        end
    end
    self.view.gainBtn.interactable = findItem and not self.m_isInventoryLocked
end
FacMachineCrafterCtrl._PlayProgressFinishedAnimation = HL.Method() << function(self)
    local normalSlotList = self.view.cacheArea:GetAreaInRepositoryNormalSlotGroup()
    local liquidSlotList = self.view.cacheArea:GetAreaInRepositoryFluidSlotGroup()
    if normalSlotList ~= nil then
        for _, slotGroup in ipairs(normalSlotList) do
            for _, slot in ipairs(slotGroup) do
                slot:PlaySlotAnimation("itemslot_arrow_loop")
            end
        end
    end
    if liquidSlotList ~= nil then
        for _, slotGroup in ipairs(liquidSlotList) do
            for _, slot in ipairs(slotGroup) do
                slot:PlaySlotAnimation("liquidslot_arrow_loop")
            end
        end
    end
end
FacMachineCrafterCtrl._OnModeSwitchButtonClicked = HL.Method() << function(self)
    local currentMode = self.m_uiInfo.formulaMan.currentMode
    if currentMode == FacConst.FAC_FORMULA_MODE_MAP.NORMAL then
        self:_SwitchMode(FacConst.FAC_FORMULA_MODE_MAP.LIQUID)
    else
        local hidePopUp = ClientDataManagerInst:GetBool(SWITCH_LIQUID_MODE_POPUP_LOCAL_DATA_KEY, false)
        if hidePopUp then
            self:_SwitchMode(FacConst.FAC_FORMULA_MODE_MAP.NORMAL)
        else
            Notify(MessageConst.SHOW_POP_UP, {
                content = Language[SWITCH_LIQUID_MODE_POPUP_TITLE_TEXT_ID],
                subContent = string.format(UIConst.COLOR_STRING_FORMAT, UIConst.COUNT_RED_COLOR_STR, Language[SWITCH_LIQUID_MODE_POPUP_DESC_TEXT_ID]),
                onConfirm = function()
                    self:_SwitchMode(FacConst.FAC_FORMULA_MODE_MAP.NORMAL)
                end,
                toggle = {
                    onValueChanged = function(isOn)
                        self.m_hideModeSwitchPopUp = isOn
                    end,
                    toggleText = Language[SWITCH_LIQUID_MODE_POPUP_TOGGLE_TEXT_ID],
                    isOn = false,
                }
            })
        end
    end
end
FacMachineCrafterCtrl._SwitchMode = HL.Method(HL.String) << function(self, targetMode)
    GameInstance.player.remoteFactory.core:Message_OpChangeProducerMode(Utils.getCurrentChapterId(), self.m_nodeId, targetMode, function(message, result)
        self.m_uiInfo:Update()
        self.m_uiInfo:ClearProducerLastValidFormulaId()
        self.view.cacheArea:RefreshCacheArea()
        self.view.cacheBelt:RefreshCacheBelt()
        self.view.cachePipe:RefreshCachePipe()
        self.view.formulaNode:RefreshRedDot()
        self:_RefreshModeNodeDisplayState(self.m_uiInfo.formulaMan.currentMode == FacConst.FAC_FORMULA_MODE_MAP.NORMAL)
        if self.m_hideModeSwitchPopUp then
            ClientDataManagerInst:SetBool(SWITCH_LIQUID_MODE_POPUP_LOCAL_DATA_KEY, true, false)
            self.m_hideModeSwitchPopUp = false
        end
    end)
end
FacMachineCrafterCtrl._RefreshModeNodeDisplayState = HL.Method(HL.Boolean) << function(self, inNormalNode)
    self.view.modeNode.on.gameObject:SetActive(inNormalNode)
    self.view.modeNode.off.gameObject:SetActive(not inNormalNode)
end
HL.Commit(FacMachineCrafterCtrl)