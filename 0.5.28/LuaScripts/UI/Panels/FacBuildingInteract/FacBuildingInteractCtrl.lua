local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local uQuaternion = CS.Unity.Mathematics.quaternion
local uMath = CS.Unity.Mathematics.math
local PANEL_ID = PanelId.FacBuildingInteract
FacBuildingInteractCtrl = HL.Class('FacBuildingInteractCtrl', uiCtrl.UICtrl)
local logisticInteractSampleOffsets = { { 1, 0 }, { 0, 0 }, { 1, 1 }, { 1, -1 }, { 2, 0 }, { 2, 1 }, { 2, -1 }, { 3, 0 }, { 3, 1 }, { 3, -1 }, }
local INVALID_INTERACT_BUILDING_LIST = { ["log_pipe_repeater_1"] = true, }
local INTERACT_SOURCE_ID_BELT = "LogisticBelt"
local INTERACT_SOURCE_ID_DELETE_BELT = "DeleteAllBelt"
local INTERACT_SOURCE_ID_PIPE = "LogisticPipe"
local INTERACT_ICON_COMMON = "btn_common_exchange_icon"
local INTERACT_ICON_DELETE = "btn_del_building_icon"
local INTERACT_ICON_EQUIP_PRODUCE = "btn_equip_produce_icon"
local INTERACT_ICON_DELETE_ALL = "btn_del_all_building_icon"
FacBuildingInteractCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_BUILD_MODE_CHANGE] = 'OnBuildModeChange', [MessageConst.ON_FAC_DESTROY_MODE_CHANGE] = 'OnFacDestroyModeChange', [MessageConst.FAC_UPDATE_INTERACT_OPTION] = 'UpdateInteractOption', [MessageConst.ON_TOGGLE_FAC_TOP_VIEW] = 'OnToggleFacTopView', [MessageConst.FAC_ON_NODE_REMOVED] = 'OnBuildingRemoved', [MessageConst.ON_FAC_TOP_VIEW_CAM_TARGET_MOVED] = 'OnFacTopViewCamTargetMoved', }
FacBuildingInteractCtrl.m_buildingInteractHighlightEffect = HL.Field(HL.Table)
FacBuildingInteractCtrl.m_subBuildingInteractHighlightEffect = HL.Field(HL.Table)
FacBuildingInteractCtrl.m_logisticInteractHighlightEffect = HL.Field(HL.Table)
FacBuildingInteractCtrl.m_pipeInteractHighlightEffect = HL.Field(HL.Table)
FacBuildingInteractCtrl.m_hoverInteractHighlightEffect = HL.Field(HL.Table)
FacBuildingInteractCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_onClickScreen = function(eventData)
        self:_OnClickScreen(eventData)
    end
    self.m_onRightClickScreen = function(eventData)
        self:_OnRightClickScreen(eventData)
    end
    self.m_onLongPressScreen = function(eventData)
        self:_OnLongPressScreen(eventData)
    end
    self.m_onDragScreen = function(eventData)
        self:_OnDragScreen(eventData)
    end
    self.m_onDragScreenBegin = function(pos)
        self:_OnDragScreenBegin(pos)
    end
    self.m_onDragScreenEnd = function(pos)
        self:_OnDragScreenEnd(pos)
    end
    self.m_onPressScreen = function(eventData)
        self:_OnPressScreen(eventData)
    end
    self.m_onReleaseScreen = function(eventData)
        self:_OnReleaseScreen(eventData)
    end
    self.view.batchToggle.onValueChanged:AddListener(function(isOn)
        self:_OnChangeDragBatchToggle(isOn)
    end)
    self.view.reverseToggle.onValueChanged:AddListener(function(isOn)
        self:_OnChangeReverseToggle(isOn)
    end)
    do
        local prefab = self.loader:LoadGameObject(FacConst.BUILDING_INTERACT_NORMAL_INDICATOR_PATH)
        self.m_buildingInteractHighlightEffect = Utils.wrapLuaNode(self:_CreateWorldGameObject(prefab))
        self.m_buildingInteractHighlightEffect.gameObject.name = "BuildingInteractHighlightEffect"
        self.m_buildingInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
        self.m_subBuildingInteractHighlightEffect = Utils.wrapLuaNode(self:_CreateWorldGameObject(prefab))
        self.m_subBuildingInteractHighlightEffect.gameObject.name = "SubBuildingInteractHighlightEffect"
        self.m_subBuildingInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
        self.m_logisticInteractHighlightEffect = Utils.wrapLuaNode(self:_CreateWorldGameObject(prefab))
        self.m_logisticInteractHighlightEffect.gameObject.name = "LogisticInteractHighlightEffect"
        self.m_logisticInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
    end
    do
        local prefab = self.loader:LoadGameObject(FacConst.BUILDING_INTERACT_HOVER_INDICATOR_PATH)
        self.m_hoverInteractHighlightEffect = Utils.wrapLuaNode(self:_CreateWorldGameObject(prefab))
        self.m_hoverInteractHighlightEffect.gameObject.name = "HoverInteractHighlightEffect"
        self.m_hoverInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
    end
    do
        local prefab = self.loader:LoadGameObject(FacConst.BUILDING_INTERACT_PIPE_INDICATOR_PATH)
        self.m_pipeInteractHighlightEffect = Utils.wrapLuaNode(self:_CreateWorldGameObject(prefab))
        self.m_pipeInteractHighlightEffect.gameObject.name = "PipeInteractHighlightEffect"
        self.m_pipeInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
    end
    LuaSystemManager.facSystem.interactPanelCtrl = self
    self:_InitFakeInteractOption()
    self.view.batchNode.gameObject:SetActive(false)
    self.view.longPressHint.gameObject:SetActive(false)
end
FacBuildingInteractCtrl.OnShow = HL.Override() << function(self)
    self:_AddRegister()
    if not LuaSystemManager.facSystem.inTopView then
        self:_UpdateInteractTarget(false, true)
    end
end
FacBuildingInteractCtrl.OnHide = HL.Override() << function(self)
    self:_ClearRegister()
end
FacBuildingInteractCtrl.OnClose = HL.Override() << function(self)
    self:_RemoveInteractOption()
    self:_ClearRegister()
end
FacBuildingInteractCtrl.m_hoverGridRectInt = HL.Field(CS.UnityEngine.RectInt)
FacBuildingInteractCtrl._TailTick = HL.Method() << function(self)
    if DeviceInfo.usingTouch and LuaSystemManager.facSystem.inTopView then
        return
    end
    self:_UpdateInteractTarget(LuaSystemManager.facSystem.inTopView)
    if LuaSystemManager.facSystem.inBatchSelectMode then
        local screenPos = InputManager.mousePosition
        local _, worldPos = CSFactoryUtil.SampleLevelRegionPointWithRay(CameraManager.mainCamera:ScreenPointToRay(screenPos))
        CSFactoryUtil.SetHoverGrid(CS.UnityEngine.Vector2Int(math.floor(worldPos.x), math.floor(worldPos.z)))
        local curScreenWorldRect = CSFactoryUtil.GetCurScreenWorldRect()
        local posXMin = math.floor(curScreenWorldRect.xMin)
        local posZMin = math.floor(curScreenWorldRect.yMin)
        local posXMax = math.ceil(curScreenWorldRect.xMax)
        local posZMax = math.ceil(curScreenWorldRect.yMax)
        local width = posXMax - posXMin
        local height = posZMax - posZMin
        local rectInt = CS.UnityEngine.RectInt(posXMin, posZMin, width, height)
        if not (self.m_hoverGridRectInt and self.m_hoverGridRectInt:Equals(rectInt)) then
            CSFactoryUtil.SetSelectGrids(rectInt)
            self.m_hoverGridRectInt = rectInt
        end
    end
end
FacBuildingInteractCtrl.OnToggleFacTopView = HL.Method(HL.Boolean) << function(self, active)
    self:_RemoveInteractOption()
    self.m_hoverInteractHighlightEffect.gameObject:SetActive(false)
    self.m_buildingInteractHighlightEffect.gameObject:SetActive(false)
    self.m_logisticInteractHighlightEffect.gameObject:SetActive(false)
    self.m_pipeInteractHighlightEffect.gameObject:SetActive(false)
    self.m_subBuildingInteractHighlightEffect.gameObject:SetActive(false)
end
FacBuildingInteractCtrl.UpdateInteractOption = HL.Method(HL.Opt(HL.Boolean)) << function(self, force)
    if force or self:IsShow() then
        self:_UpdateInteractTarget()
    end
end
FacBuildingInteractCtrl.m_tailTickId = HL.Field(HL.Number) << -1
FacBuildingInteractCtrl.m_slowlyUpdateCor = HL.Field(HL.Thread)
FacBuildingInteractCtrl._AddRegister = HL.Method() << function(self)
    local touchPanel = UIManager.commonTouchPanel
    touchPanel.onClick:AddListener(self.m_onClickScreen)
    touchPanel.onRightClick:AddListener(self.m_onRightClickScreen)
    touchPanel.onLongPress:AddListener(self.m_onLongPressScreen)
    touchPanel.onDrag:AddListener(self.m_onDragScreen)
    touchPanel.onDragBegin:AddListener(self.m_onDragScreenBegin)
    touchPanel.onDragEnd:AddListener(self.m_onDragScreenEnd)
    touchPanel.onPress:AddListener(self.m_onPressScreen)
    touchPanel.onRelease:AddListener(self.m_onReleaseScreen)
    self.m_tailTickId = LuaUpdate:Add("TailTick", function()
        self:_TailTick()
    end, true)
    self.m_slowlyUpdateCor = self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.FAC_COMMON_UI_UPDATE_INTERVAL)
            self:_SlowlyUpdate()
        end
    end)
end
FacBuildingInteractCtrl._ClearRegister = HL.Method() << function(self)
    local touchPanel = UIManager.commonTouchPanel
    touchPanel.onClick:RemoveListener(self.m_onClickScreen)
    touchPanel.onRightClick:RemoveListener(self.m_onRightClickScreen)
    touchPanel.onLongPress:RemoveListener(self.m_onLongPressScreen)
    touchPanel.onDrag:RemoveListener(self.m_onDragScreen)
    touchPanel.onDragBegin:RemoveListener(self.m_onDragScreenBegin)
    touchPanel.onDragEnd:RemoveListener(self.m_onDragScreenEnd)
    touchPanel.onPress:RemoveListener(self.m_onPressScreen)
    touchPanel.onRelease:RemoveListener(self.m_onReleaseScreen)
    self.m_tailTickId = LuaUpdate:Remove(self.m_tailTickId)
    self:_StopPressHint()
    self.m_slowlyUpdateCor = self:_ClearCoroutine(self.m_slowlyUpdateCor)
end
FacBuildingInteractCtrl.m_onClickScreen = HL.Field(HL.Function)
FacBuildingInteractCtrl._OnClickScreen = HL.Method(HL.Userdata) << function(self, eventData)
    if not LuaSystemManager.facSystem.inTopView then
        return
    end
    if FactoryUtils.isInBuildMode() then
        return
    end
    if LuaSystemManager.facSystem.inDestroyMode then
        if LuaSystemManager.facSystem.inBatchSelectMode then
            self:_ClickScreenInDestroyBatchMode()
        else
            self:_UpdateInteractTarget(true, true)
            self:_UpdateFakeInteractOption()
            if not DeviceInfo.usingTouch then
                self:_OnClickFakeInteractOption()
            end
        end
    else
        if DeviceInfo.usingTouch then
            self:_UpdateInteractTarget(false, true)
            self:_UpdateFakeInteractOption()
        else
            self:_UpdateInteractTarget(true, true)
            self:_UpdateFakeInteractOption()
            self:_OnClickFakeInteractOption()
        end
    end
end
FacBuildingInteractCtrl._ClickScreenInDestroyBatchMode = HL.Method() << function(self)
    self:_UpdateInteractTarget(true, true)
    local nodeId = self.m_interactFacNodeId or self.m_interactPipeNodeId
    local unitIndex
    if not nodeId and self.m_interactLogisticPos then
        local chapterInfo = FactoryUtils.getCurChapterInfo()
        local succ, beltNodeId
        succ, beltNodeId, unitIndex = GameInstance.remoteFactoryManager:TrySampleConveyor(self.m_interactLogisticPos)
        nodeId = beltNodeId
        if not InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.LeftControl) then
            unitIndex = nil
        end
    end
    if nodeId then
        if not unitIndex then
            local isAdd = LuaSystemManager.facSystem.batchSelectTargets[nodeId] ~= true
            self:_SelectBatchTarget(nodeId, isAdd, nil, true)
        else
            local indexList = LuaSystemManager.facSystem.batchSelectTargets[nodeId]
            if not indexList then
                self:_SelectBatchTarget(nodeId, true, unitIndex, true)
            else
                local isAdd
                if indexList == true then
                    isAdd = false
                else
                    isAdd = indexList[unitIndex] == nil
                end
                self:_SelectBatchTarget(nodeId, isAdd, unitIndex, true)
            end
        end
    end
end
FacBuildingInteractCtrl.m_onRightClickScreen = HL.Field(HL.Function)
FacBuildingInteractCtrl._OnRightClickScreen = HL.Method(HL.Userdata) << function(self, eventData)
    if not LuaSystemManager.facSystem.inTopView then
        return
    end
end
FacBuildingInteractCtrl.m_onLongPressScreen = HL.Field(HL.Function)
FacBuildingInteractCtrl._OnLongPressScreen = HL.Method(HL.Userdata) << function(self, eventData)
    if not LuaSystemManager.facSystem.inTopView then
        return
    end
    if FactoryUtils.isInBuildMode() or LuaSystemManager.facSystem.inDestroyMode then
        return
    end
    local nodeId = self.m_interactFacNodeId
    if not nodeId or not self.m_interactFacNodeIdIsBuilding then
        return
    end
    if FactoryUtils.canMoveBuilding(nodeId, true) then
        Notify(MessageConst.FAC_ENTER_BUILDING_MODE, { nodeId = nodeId })
    end
end
FacBuildingInteractCtrl.m_onDragScreen = HL.Field(HL.Function)
FacBuildingInteractCtrl._OnDragScreen = HL.Method(HL.Userdata) << function(self, eventData)
    if LuaSystemManager.facSystem.inDragSelectBatchMode then
        if not InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.Mouse2) then
            self:_OnDragInBathMode(eventData)
        end
    end
end
FacBuildingInteractCtrl.m_onDragScreenBegin = HL.Field(HL.Function)
FacBuildingInteractCtrl._OnDragScreenBegin = HL.Method(Vector2) << function(self, pos)
    if LuaSystemManager.facSystem.inDragSelectBatchMode then
        if not InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.Mouse2) then
            self:_OnDragBeginInBathMode(pos)
        end
    end
    self:_StopPressHint()
end
FacBuildingInteractCtrl.m_onDragScreenEnd = HL.Field(HL.Function)
FacBuildingInteractCtrl._OnDragScreenEnd = HL.Method(Vector2) << function(self, pos)
    if LuaSystemManager.facSystem.inDragSelectBatchMode then
        self:_OnDragEndInBathMode(pos)
    end
end
local pressHintDelay = 0.2
local pressDuration = 0.5
FacBuildingInteractCtrl.m_onPressScreen = HL.Field(HL.Function)
FacBuildingInteractCtrl._OnPressScreen = HL.Method(HL.Userdata) << function(self, eventData)
    if FactoryUtils.isInBuildMode() then
        return
    end
    if LuaSystemManager.facSystem.inDestroyMode then
        return
    end
    if not LuaSystemManager.facSystem.inTopView then
        return
    end
    if DeviceInfo.usingTouch then
        return
    end
    self:_StopPressHint()
    if not self.m_interactFacNodeId or not self.m_interactFacNodeIdIsBuilding then
        return
    end
    if not FactoryUtils.canMoveBuilding(self.m_interactFacNodeId) then
        return
    end
    self.m_pressHintCor = self:_StartCoroutine(function()
        local startTime = Time.time
        coroutine.wait(pressHintDelay)
        local hint = self.view.longPressHint
        hint.gameObject:SetActive(true)
        local ratio = self.view.transform.rect.width / Screen.width
        hint.transform.anchoredPosition = (InputManager.mousePosition * ratio):XY()
        hint.image.fillAmount = 0
        hint.image:DOFillAmount(1, pressDuration - pressHintDelay):OnComplete(function()
            self:_StopPressHint()
        end)
    end)
end
FacBuildingInteractCtrl.m_onReleaseScreen = HL.Field(HL.Function)
FacBuildingInteractCtrl._OnReleaseScreen = HL.Method(HL.Userdata) << function(self, eventData)
    if FactoryUtils.isInBuildMode() then
        return
    end
    self:_StopPressHint()
end
FacBuildingInteractCtrl._StopPressHint = HL.Method() << function(self)
    self.m_pressHintCor = self:_ClearCoroutine(self.m_pressHintCor)
    self.view.longPressHint.gameObject:SetActive(false)
    self.view.longPressHint.image:DOKill()
end
FacBuildingInteractCtrl.m_pressHintCor = HL.Field(HL.Thread)
FacBuildingInteractCtrl.OnBuildModeChange = HL.Method(HL.Number) << function(self, mode)
    if mode ~= FacConst.FAC_BUILD_MODE.Normal then
        self:_RemoveInteractOption()
    end
    CSFactoryUtil.ClearSelectGrids()
    CSFactoryUtil.ClearHoverGrid()
    self.m_hoverGridRectInt = nil
end
FacBuildingInteractCtrl.OnFacDestroyModeChange = HL.Method(HL.Boolean) << function(self, inDestroyMode)
    self:_ClearBeltHoverHint()
    self:_RemoveInteractOption()
    self:_UpdateInteractTarget(LuaSystemManager.facSystem.inTopView, true)
    self:_ResetBatch(inDestroyMode)
    if inDestroyMode and LuaSystemManager.facSystem.inTopView then
        self.view.batchNode.gameObject:SetActive(true)
        self:_ChangeBatchMode(true)
    else
        self.view.batchNode.gameObject:SetActive(false)
        self:_ChangeBatchMode(false)
    end
    CSFactoryUtil.ClearSelectGrids()
    CSFactoryUtil.ClearHoverGrid()
    self.m_hoverGridRectInt = nil
end
FacBuildingInteractCtrl.OnBuildingRemoved = HL.Method(HL.Table) << function(self, arg)
    self:_RemoveInteractOption()
    if LuaSystemManager.facSystem.inBatchSelectMode then
        self:_ClearAllBatchTargets()
    end
end
FacBuildingInteractCtrl._OnInteractFactory = HL.Method(HL.Table) << function(self, option)
    local buildingNodeId = option.buildingNodeId
    if not string.isEmpty(buildingNodeId) then
        if LuaSystemManager.facSystem.inDestroyMode then
            if Utils.isInSettlementDefenseDefending() then
                if GameInstance.player.towerDefenseSystem.towerDefenseGame:IsPreBattleBuilding(buildingNodeId) then
                    Notify(MessageConst.SHOW_TOAST, Language.LUA_FORBID_DESTROY_PRE_BATTLE_BUILDING)
                    return
                end
            end
            FactoryUtils.delBuilding(buildingNodeId, nil, true)
            return
        end
        local curChapter = FactoryUtils.getCurChapterInfo()
        local node = curChapter:GetNode(buildingNodeId)
        local preventOpen = false
        if node and node.nodeType == GEnums.FCNodeType.SubHub:GetHashCode() then
            if not node.power.inPower then
                preventOpen = true
                Notify(MessageConst.SHOW_TOAST, Language.lang_int_jumpmachine_toast)
            end
        end
        if not preventOpen then
            if not option.subBuildingIndex then
                self:_OpenBuildingPanel(buildingNodeId)
            else
                self:_OpenBuildingPanel(buildingNodeId, { subIndex = option.subBuildingIndex }, "unloader_1")
            end
        end
    end
    local nodeId = option.nodeId
    if nodeId then
        if LuaSystemManager.facSystem.inDestroyMode then
            local core = GameInstance.player.remoteFactory.core
            if option.isAll or not option.unitIndex then
                if FactoryUtils.canDelBuilding(option.nodeId, true) then
                    core:Message_OpDismantle(Utils.getCurrentChapterId(), option.nodeId)
                end
            else
                local sceneName = GameInstance.remoteFactoryManager.currentSceneName
                GameInstance.remoteFactoryManager:DismantleUnitFromConveyor(Utils.getCurrentChapterId(), option.nodeId, option.unitIndex)
            end
            AudioAdapter.PostEvent("au_int_belt_remove_short")
        else
            local nodeHandler = FactoryUtils.getBuildingNodeHandler(nodeId)
            if nodeHandler ~= nil and not INVALID_INTERACT_BUILDING_LIST[nodeHandler.templateId] then
                Notify(MessageConst.FAC_OPEN_LOGISTIC_PANEL, { nodeId = option.nodeId, index = option.unitIndex })
            end
        end
    end
end
FacBuildingInteractCtrl._OpenBuildingPanel = HL.Method(HL.Opt(HL.Any, HL.Table, HL.String)).Return(HL.Opt(HL.Number)) << function(self, nodeId, customArg, buildingId)
    Notify(MessageConst.FAC_OPEN_BUILDING_PANEL, { nodeId = nodeId, customArg = customArg, panelBuildingDataId = buildingId, })
end
FacBuildingInteractCtrl._RemoveInteractOption = HL.Method() << function(self)
    self.m_interactFacNodeId = nil
    self.m_selectedInteractFacNodeId = nil
    self.m_buildingUseDefaultOption = nil
    self.m_interactSubBuildingIndex = -1
    if self.m_interactLogisticPos then
        self:_ToggleBeltHoverHint(self.m_interactLogisticPos, false)
        self.m_interactLogisticPos = nil
    end
    self.m_selectedInteractSubBuildingIndex = -1
    self.m_selectedInteractLogisticPos = nil
    self.m_selectedInteractPipeNodeId = nil
    self.m_interactPipeNodeId = nil
    self.m_hoverInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
    self.m_buildingInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
    self.m_logisticInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
    self.m_pipeInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
    self.m_subBuildingInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
    self.view.listNode.gameObject:SetActiveIfNecessary(false)
    self.view.hoverInfoTextNode.gameObject:SetActiveIfNecessary(false)
    Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = "MainBuilding", })
    Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = "EquipProducer", })
    Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = "SubBuilding", })
    Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = INTERACT_SOURCE_ID_BELT, })
    Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = INTERACT_SOURCE_ID_DELETE_BELT, })
    Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = INTERACT_SOURCE_ID_PIPE, })
    GameInstance.world.interactiveFacWrapperManager:OnFacBuildingInteractOptionRemoveAll()
end
FacBuildingInteractCtrl._SetEffect = HL.Method(HL.Table, CS.UnityEngine.Vector3, HL.Number, HL.Opt(CS.UnityEngine.Vector3, CS.UnityEngine.Vector3)) << function(self, effect, pos, offsetY, rot, scale)
    pos.y = pos.y + offsetY
    effect.transform.position = pos
    effect.transform.eulerAngles = rot or Vector3.zero
    scale = scale or Vector3.one
    effect.transform.localScale = scale
    for k = 1, 4 do
        effect["corner" .. k].transform.localScale = Vector3(1 / scale.x, 1, 1 / scale.z)
    end
    if effect.gameObject.activeSelf then
        return
    end
    effect.gameObject:SetActive(true)
    for k = 1, 4 do
        effect["effect" .. k]:Update(0)
    end
end
FacBuildingInteractCtrl._SetBoxEffect = HL.Method(HL.Table, CS.UnityEngine.Vector3, HL.Opt(CS.UnityEngine.Vector3, HL.String)) << function(self, effect, pos, rot, buildingId)
    local scale, reverseScale
    if buildingId then
        local data = Tables.factoryBuildingTable:GetValue(buildingId)
        scale = Vector3(data.range.width + 0.3, data.modelHeight, data.range.depth + 0.3)
        reverseScale = Vector3(1 / scale.x, 1 / scale.y, 1 / scale.z)
    else
        scale = Vector3.one
        reverseScale = Vector3.one
    end
    effect.transform.position = pos
    effect.transform.eulerAngles = rot or Vector3.zero
    effect.transform.localScale = scale
    for k = 1, 8 do
        effect["corner" .. k].transform.localScale = reverseScale
    end
    if effect.gameObject.activeSelf then
        return
    end
    effect.gameObject:SetActive(true)
    for k = 1, 8 do
        effect["effect" .. k]:Update(0)
    end
end
FacBuildingInteractCtrl._GetGridUnitFromWorldPos = HL.Method(Vector2, HL.Number).Return(HL.Table) << function(self, worldPos, sampleType)
    local gridPos = Unity.Vector2Int(lume.round(worldPos.x), lume.round(worldPos.y))
    local success, nodeId, unitIndex, unitTemplateId, unitEntity
    if sampleType == FacConst.FAC_SAMPLE_TYPE.Belt then
        success, nodeId, unitIndex, unitTemplateId, unitEntity = GameInstance.remoteFactoryManager:TrySampleConveyor(gridPos)
    elseif sampleType == FacConst.FAC_SAMPLE_TYPE.Pipe then
        success, nodeId, unitIndex, unitTemplateId, unitEntity = GameInstance.remoteFactoryManager:TrySamplePipe(gridPos)
    end
    return { success = success, nodeId = nodeId, unitIndex = unitIndex, unitTemplateId = unitTemplateId, }
end
FacBuildingInteractCtrl.m_interactFacNodeId = HL.Field(HL.Any)
FacBuildingInteractCtrl.m_interactFacNodeIdIsBuilding = HL.Field(HL.Boolean) << false
FacBuildingInteractCtrl.m_buildingUseDefaultOption = HL.Field(HL.Any)
FacBuildingInteractCtrl.m_interactSubBuildingIndex = HL.Field(HL.Number) << -1
FacBuildingInteractCtrl.m_interactLogisticPos = HL.Field(CS.UnityEngine.Vector2Int)
FacBuildingInteractCtrl.m_interactPipeNodeId = HL.Field(HL.Any)
FacBuildingInteractCtrl.m_delayedPipeNodeInfo = HL.Field(HL.Table)
FacBuildingInteractCtrl._UpdateInteractTarget = HL.Method(HL.Opt(HL.Boolean, HL.Boolean)) << function(self, isPreview, forceUpdate)
    if FactoryUtils.isInBuildMode() then
        return
    end
    local hasTarget = false
    local isClickMode = LuaSystemManager.facSystem.inTopView
    local playerPos, playerForward, playerRight
    local maxDist, maxAngle
    if not isClickMode then
        local playerTrans = GameUtil.playerTrans
        playerPos = playerTrans.position
        playerForward = playerTrans.forward
        playerRight = playerTrans.right
        maxDist = self.view.config.BUILDING_INTERACT_RANGE
        maxAngle = self.view.config.BUILDING_INTERACT_ANGLE
    else
        local curMousePos = InputManager.mousePosition
        local camRay = CameraManager.mainCamera:ScreenPointToRay(curMousePos)
        local _, worldPos = CSFactoryUtil.SampleLevelRegionPointWithRay(camRay)
        playerPos = worldPos
        playerForward = Vector3.forward
        playerRight = Vector3.right
        maxDist = 0
        maxAngle = -1
    end
    local foundBuilding, targetBuildingNodeId, targetBuildingTemplateId, targetBuildingPosition, targetBuildingRotation, targetBuildingAdjustMapHeight, subBuildingInfo = CSFactoryUtil.GetShouldInteractFacEntity(LuaSystemManager.facSystem.inDestroyMode, maxDist, maxAngle, playerPos, playerForward, isClickMode)
    if foundBuilding then
        hasTarget = true
        local nodeId = targetBuildingNodeId
        local isBuilding, buildingData = Tables.factoryBuildingTable:TryGetValue(targetBuildingTemplateId)
        local buildingChanged, useDefaultOption
        if not isClickMode then
            useDefaultOption = CSFactoryUtil.ShouldShowBuildingUIInteractOption(nodeId)
            buildingChanged = not self.m_interactFacNodeId or self.m_interactFacNodeId ~= nodeId or self.m_buildingUseDefaultOption ~= useDefaultOption
        else
            buildingChanged = not self.m_interactFacNodeId or self.m_interactFacNodeId ~= nodeId
        end
        local isHub = isBuilding and (buildingData.type == GEnums.FacBuildingType.Hub or buildingData.type == GEnums.FacBuildingType.SubHub)
        local needUpdateBuildingEffect = false
        if buildingChanged or forceUpdate then
            self.m_interactFacNodeIdIsBuilding = isBuilding
            if not isClickMode then
                local args = { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = "MainBuilding", sortId = 200, buildingNodeId = nodeId, templateId = targetBuildingTemplateId, icon = LuaSystemManager.facSystem.inDestroyMode and INTERACT_ICON_DELETE or INTERACT_ICON_COMMON, }
                if isBuilding then
                    args.text = buildingData.name
                    args.action = function()
                        self:_OnInteractFactory({ buildingNodeId = nodeId })
                    end
                else
                    local unitData = FactoryUtils.getLogisticData(targetBuildingTemplateId)
                    args.text = unitData.name
                    args.action = function()
                        self:_OnInteractFactory({ nodeId = nodeId })
                    end
                end
                if LuaSystemManager.facSystem.inDestroyMode then
                    args.isDel = true
                end
                if isBuilding then
                    if not self.m_interactFacNodeId then
                        GameInstance.world.interactiveFacWrapperManager:OnFacBuildingInteractOptionAdded(nodeId)
                    else
                        GameInstance.world.interactiveFacWrapperManager:OnFacBuildingInteractOptionUpdate(nodeId)
                    end
                else
                    if self.m_interactFacNodeId then
                        GameInstance.world.interactiveFacWrapperManager:OnFacBuildingInteractOptionRemove(self.m_interactFacNodeId)
                    end
                end
                if useDefaultOption then
                    if isHub then
                        if Utils.isSystemUnlocked(GEnums.UnlockSystemType.FacHub) then
                            Notify(MessageConst.ADD_INTERACT_OPTION, args)
                            if PhaseManager:CheckCanOpenPhase(PhaseId.EquipProducer) then
                                Notify(MessageConst.ADD_INTERACT_OPTION, {
                                    type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory,
                                    sourceId = "EquipProducer",
                                    sortId = 199,
                                    buildingNodeId = nodeId,
                                    templateId = targetBuildingTemplateId,
                                    text = Language['ui_produce_title'],
                                    action = function()
                                        PhaseManager:OpenPhase(PhaseId.EquipProducer)
                                    end,
                                    icon = INTERACT_ICON_EQUIP_PRODUCE,
                                })
                            end
                        else
                            Notify(MessageConst.REMOVE_INTERACT_OPTION, args)
                        end
                    else
                        Notify(MessageConst.ADD_INTERACT_OPTION, args)
                        Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = "EquipProducer", })
                    end
                else
                    if args.isDel then
                        if CSFactoryUtil.IsSoil(nodeId) then
                            Notify(MessageConst.ADD_INTERACT_OPTION, args)
                        else
                            Notify(MessageConst.REMOVE_INTERACT_OPTION, args)
                        end
                    else
                        Notify(MessageConst.REMOVE_INTERACT_OPTION, args)
                    end
                end
            end
            needUpdateBuildingEffect = true
        end
        local newSubIndex = -1
        local beltUnlocked = GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedBelt
        local portUnlocked = GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedPort
        local subBuildingChanged, subBuildingPos, subBuildingRot, minSubDist
        if isHub and subBuildingInfo and not LuaSystemManager.facSystem.inDestroyMode and beltUnlocked and portUnlocked then
            minSubDist = isClickMode and 1 or self.view.config.SUB_BUILDING_SET_TOP_DIST
            if subBuildingInfo.dist <= minSubDist then
                newSubIndex = LuaIndex(subBuildingInfo.subIndex)
                minSubDist = subBuildingInfo.dist
                subBuildingPos = subBuildingInfo.position
                subBuildingRot = subBuildingInfo.rotation
            end
            subBuildingChanged = newSubIndex ~= -1 or (self.m_interactSubBuildingIndex ~= -1)
        else
            subBuildingChanged = self.m_interactSubBuildingIndex ~= -1
        end
        if subBuildingChanged or forceUpdate then
            local effect = isPreview and self.m_hoverInteractHighlightEffect or self.m_subBuildingInteractHighlightEffect
            if newSubIndex >= 0 then
                if isPreview then
                    needUpdateBuildingEffect = false
                end
                self:_SetEffect(effect, subBuildingPos, 0.5, Vector3(subBuildingRot.x, subBuildingRot.y, subBuildingRot.z))
            else
                if isPreview then
                    needUpdateBuildingEffect = true
                else
                    effect.gameObject:SetActiveIfNecessary(false)
                end
            end
            if not isClickMode then
                local args = { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = "SubBuilding", templateId = targetBuildingTemplateId, }
                local msg
                if newSubIndex == -1 then
                    msg = MessageConst.REMOVE_INTERACT_OPTION
                else
                    if not GameInstance.world.gameMechManager.linkWireBrain.isLinking then
                        args.sortId = -100
                    else
                        args.sortId = 100
                    end
                    args.setTopAsSelectedWhenSort = true
                    args.buildingNodeId = nodeId
                    if self.m_interactSubBuildingIndex == -1 then
                        msg = MessageConst.ADD_INTERACT_OPTION
                    else
                        msg = MessageConst.UPDATE_INTERACT_OPTION
                        args.needReSort = true
                    end
                    args.text = Language.LUA_FAC_HUB_INPUT .. newSubIndex
                    args.action = function()
                        self:_OnInteractFactory({ buildingNodeId = nodeId, subBuildingIndex = newSubIndex, })
                    end
                end
                Notify(msg, args)
            end
        end
        if needUpdateBuildingEffect then
            local pos = targetBuildingPosition
            pos.y = targetBuildingAdjustMapHeight
            local rot = targetBuildingRotation
            local xScale = buildingData and buildingData.range.width or 1
            local zScale = buildingData and buildingData.range.depth or 1
            local effect = isPreview and self.m_hoverInteractHighlightEffect or self.m_buildingInteractHighlightEffect
            self:_SetEffect(effect, pos, 0.5, rot, Vector3(xScale, 1, zScale))
        end
        self.m_interactFacNodeId = nodeId
        self.m_buildingUseDefaultOption = useDefaultOption
        self.m_interactSubBuildingIndex = newSubIndex
    else
        if self.m_interactFacNodeId or forceUpdate then
            if not isClickMode then
                Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = "MainBuilding", })
                Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = "EquipProducer", })
                if self.m_interactFacNodeId then
                    GameInstance.world.interactiveFacWrapperManager:OnFacBuildingInteractOptionRemove(self.m_interactFacNodeId)
                end
                Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = "SubBuilding", })
            end
            self.m_interactFacNodeId = nil
            self.m_buildingUseDefaultOption = nil
            if not isPreview then
                self.m_buildingInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
                self.m_subBuildingInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
            end
            self.m_interactSubBuildingIndex = -1
        end
    end
    local needUpdateHoverHint
    local pipeNodeId, pipeGridUnit, pipeGridPos
    if isClickMode then
        if not FactoryUtils.isPipeInSimpleFigure() then
            pipeGridPos = GameInstance.remoteFactoryManager.visual:WorldToBeltGrid(playerPos)
            pipeGridUnit = self:_GetGridUnitFromWorldPos(pipeGridPos, FacConst.FAC_SAMPLE_TYPE.Pipe)
            pipeGridPos = Unity.Vector2Int(lume.round(pipeGridPos.x), lume.round(pipeGridPos.y))
            if pipeGridUnit.success then
                pipeNodeId = pipeGridUnit.nodeId
            end
        else
            pipeGridUnit = { success = false }
        end
    else
        local success, nodeId, unitIndex
        success, pipeGridPos, nodeId, unitIndex = CSFactoryUtil.GetShouldInteractLogistic(false)
        if success then
            local shouldShow, shouldUpdateInfo = false, true
            if LuaSystemManager.facSystem.inDestroyMode then
                shouldShow = true
            else
                if self.m_delayedPipeNodeInfo then
                    if self.m_delayedPipeNodeInfo.nodeId == nodeId and self.m_delayedPipeNodeInfo.unitIndex == unitIndex then
                        shouldUpdateInfo = false
                        shouldShow = Time.unscaledTime >= self.m_delayedPipeNodeInfo.delayEndTime
                    end
                end
            end
            if shouldShow then
                pipeGridUnit = { success = success, nodeId = nodeId, unitIndex = unitIndex, }
                pipeNodeId = nodeId
            elseif shouldUpdateInfo then
                self.m_delayedPipeNodeInfo = { nodeId = nodeId, unitIndex = unitIndex, delayEndTime = Time.unscaledTime + self.view.config.PIPE_OPTION_DELAY }
            end
        else
            self.m_delayedPipeNodeInfo = nil
        end
    end
    if pipeNodeId then
        hasTarget = true
    end
    if forceUpdate or pipeNodeId ~= self.m_interactPipeNodeId or (pipeNodeId and isPreview) then
        if pipeNodeId then
            local height = CSFactoryUtil.GetPipeUnitHeight(pipeNodeId, pipeGridUnit.unitIndex)
            local worldPos = Vector3(pipeGridPos.x + 0.5, height, pipeGridPos.y + 0.5)
            if isPreview then
                self:_SetEffect(self.m_hoverInteractHighlightEffect, worldPos, 0)
            else
                self.m_pipeInteractHighlightEffect.transform.position = worldPos
                local ray = CS.UnityEngine.Ray(worldPos, Vector3.down)
                local succ, terrainPos = CSFactoryUtil.SampleLevelRegionPointWithRay(ray)
                local dist = succ and (worldPos.y - terrainPos.y) or 3
                self.m_pipeInteractHighlightEffect.dot.localPosition = Vector3(0, -dist, 0)
                self.m_pipeInteractHighlightEffect.line.localScale = Vector3(1, dist + self.m_pipeInteractHighlightEffect.line.localPosition.y, 1)
                self.m_pipeInteractHighlightEffect.gameObject:SetActive(true)
            end
            if not isClickMode then
                local interactArgs = {
                    isDel = LuaSystemManager.facSystem.inDestroyMode,
                    type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory,
                    sourceId = INTERACT_SOURCE_ID_PIPE,
                    templateId = pipeGridUnit.unitTemplateId,
                    text = Language.LUA_FAC_PIPE_INTERACT_OPTION,
                    action = function()
                        if LuaSystemManager.facSystem.inDestroyMode then
                            self:_OnInteractFactory({ nodeId = pipeGridUnit.nodeId, isAll = true })
                        else
                            self:_OnInteractFactory({ nodeId = pipeGridUnit.nodeId })
                        end
                    end,
                    icon = LuaSystemManager.facSystem.inDestroyMode and INTERACT_ICON_DELETE or INTERACT_ICON_COMMON,
                    sortId = 500,
                }
                Notify(MessageConst.ADD_INTERACT_OPTION, interactArgs)
            end
        else
            if not isClickMode then
                Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = INTERACT_SOURCE_ID_PIPE, })
            end
            if not isPreview then
                self.m_pipeInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
            end
        end
        self.m_interactPipeNodeId = pipeNodeId
        needUpdateHoverHint = true
    elseif not isPreview and LuaSystemManager.facSystem.inDestroyMode and pipeNodeId and pipeNodeId == self.m_interactPipeNodeId then
        local height = CSFactoryUtil.GetPipeUnitHeight(pipeNodeId, pipeGridUnit.unitIndex)
        local worldPos = Vector3(pipeGridPos.x + 0.5, height, pipeGridPos.y + 0.5)
        self.m_pipeInteractHighlightEffect.transform.position = worldPos
        local ray = CS.UnityEngine.Ray(worldPos, Vector3.down)
        local succ, terrainPos = CSFactoryUtil.SampleLevelRegionPointWithRay(ray)
        local dist = succ and (worldPos.y - terrainPos.y) or 3
        self.m_pipeInteractHighlightEffect.dot.localPosition = Vector3(0, -dist, 0)
        self.m_pipeInteractHighlightEffect.line.localScale = Vector3(1, dist + self.m_pipeInteractHighlightEffect.line.localPosition.y, 1)
        self.m_pipeInteractHighlightEffect.gameObject:SetActive(true)
    end
    local logisticPos
    local beltGridUnit
    if isClickMode then
        if not FactoryUtils.isBeltInSimpleFigure() and not self.m_interactPipeNodeId then
            local beltPos = GameInstance.remoteFactoryManager.visual:WorldToBeltGrid(playerPos)
            beltGridUnit = self:_GetGridUnitFromWorldPos(beltPos, FacConst.FAC_SAMPLE_TYPE.Belt)
            if beltGridUnit.success then
                logisticPos = Unity.Vector2Int(lume.round(beltPos.x), lume.round(beltPos.y))
            end
        else
            beltGridUnit = { success = false }
        end
    else
        local success, nodeId, unitIndex
        success, logisticPos, nodeId, unitIndex = CSFactoryUtil.GetShouldInteractLogistic(true)
        beltGridUnit = { success = success, nodeId = nodeId, unitIndex = unitIndex, }
    end
    if beltGridUnit.success then
        hasTarget = true
        local chapterInfo = FactoryUtils.getCurChapterInfo()
        local nodeHandler = chapterInfo:GetNode(beltGridUnit.nodeId)
        beltGridUnit.unitTemplateId = nodeHandler.templateId
        local lastPos = self.m_interactLogisticPos
        if forceUpdate or not lastPos or (lastPos.x ~= logisticPos.x) or (lastPos.y ~= logisticPos.y) then
            self.m_interactLogisticPos = logisticPos
            needUpdateHoverHint = true
            if self:_NeedShowHoverHint() then
                if lastPos then
                    self:_ToggleBeltHoverHint(lastPos, false)
                end
                self:_ToggleBeltHoverHint(logisticPos, true)
            end
            local unitHeight = FactoryUtils.queryVoxelRangeHeightAdjust(nodeHandler.transform.position.x, nodeHandler.transform.position.y, nodeHandler.transform.position.z)
            local worldPos = Vector3(logisticPos.x + 0.5, unitHeight, logisticPos.y + 0.5)
            local effect = isPreview and self.m_hoverInteractHighlightEffect or self.m_logisticInteractHighlightEffect
            self:_SetEffect(effect, worldPos, 0.2)
            if not isClickMode then
                local _, logisticData = Tables.factoryGridBeltTable:TryGetValue(beltGridUnit.unitTemplateId)
                if not logisticData then
                    logger.error("No factoryGridBeltData", beltGridUnit.unitTemplateId, beltGridUnit, "logisticPos", logisticPos, "playerPos", playerPos, nodeHandler.belongScene.sceneIdStr)
                else
                    local logisticName = logisticData.beltData.name
                    local args = {
                        type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory,
                        sourceId = INTERACT_SOURCE_ID_BELT,
                        templateId = beltGridUnit.unitTemplateId,
                        text = logisticName,
                        action = function()
                            self:_OnInteractFactory({ nodeId = beltGridUnit.nodeId, unitIndex = beltGridUnit.unitIndex, logisticPos = logisticPos })
                        end,
                        sortId = 300,
                        icon = LuaSystemManager.facSystem.inDestroyMode and INTERACT_ICON_DELETE or INTERACT_ICON_COMMON,
                    }
                    local delAllArgs
                    if LuaSystemManager.facSystem.inDestroyMode then
                        args.isDel = true
                        args.sortId = -100
                        args.text = logisticName
                        delAllArgs = {
                            type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory,
                            sourceId = INTERACT_SOURCE_ID_DELETE_BELT,
                            templateId = beltGridUnit.unitTemplateId,
                            isDel = true,
                            text = string.format(Language.DEL_ALL_BELT_FORMAT, logisticName),
                            icon = INTERACT_ICON_DELETE_ALL,
                            action = function()
                                self:_OnInteractFactory({ nodeId = beltGridUnit.nodeId, unitIndex = beltGridUnit.unitIndex, isAll = true })
                            end,
                            sortId = -200,
                        }
                    else
                        args.text = logisticName
                    end
                    if delAllArgs then
                        Notify(MessageConst.ADD_INTERACT_OPTION, delAllArgs)
                    else
                        Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = INTERACT_SOURCE_ID_DELETE_BELT, })
                    end
                    Notify(MessageConst.ADD_INTERACT_OPTION, args)
                end
            end
        end
    else
        if forceUpdate or self.m_interactLogisticPos then
            if not isClickMode then
                Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = INTERACT_SOURCE_ID_BELT, })
                Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Factory, sourceId = INTERACT_SOURCE_ID_DELETE_BELT, })
            end
            if self:_NeedShowHoverHint() and self.m_interactLogisticPos then
                self:_ClearBeltHoverHint()
            end
            self.m_interactLogisticPos = nil
            needUpdateHoverHint = true
            if not isPreview then
                self.m_logisticInteractHighlightEffect.gameObject:SetActiveIfNecessary(false)
            end
        end
    end
    if needUpdateHoverHint and self:_NeedShowHoverHint() then
        if self.m_interactLogisticPos == nil then
            self:_UpdatePipeHoverHint()
        end
    end
    if isPreview and not hasTarget then
        self.m_hoverInteractHighlightEffect.gameObject:SetActive(false)
    end
end
FacBuildingInteractCtrl.m_selectedInteractFacNodeId = HL.Field(HL.Any)
FacBuildingInteractCtrl.m_selectedInteractFacNodeIdIsBuilding = HL.Field(HL.Boolean) << false
FacBuildingInteractCtrl.m_selectedInteractSubBuildingIndex = HL.Field(HL.Number) << -1
FacBuildingInteractCtrl.m_selectedInteractLogisticPos = HL.Field(CS.UnityEngine.Vector2Int)
FacBuildingInteractCtrl.m_selectedInteractPipeNodeId = HL.Field(HL.Any)
FacBuildingInteractCtrl.m_listInitPos = HL.Field(Vector3)
FacBuildingInteractCtrl._InitFakeInteractOption = HL.Method() << function(self)
    self.view.optionItem.button.onClick:AddListener(function()
        self:_OnClickFakeInteractOption()
    end)
    self.view.listNode.gameObject:SetActive(false)
    self.m_listInitPos = self.view.listNode.transform.position
end
FacBuildingInteractCtrl._UpdateFakeInteractOption = HL.Method() << function(self)
    if self.m_selectedInteractFacNodeId == self.m_interactFacNodeId and self.m_selectedInteractSubBuildingIndex == self.m_interactSubBuildingIndex and self.m_selectedInteractLogisticPos == self.m_interactLogisticPos and self.m_selectedInteractPipeNodeId == self.m_interactPipeNodeId then
        return
    end
    self.m_selectedInteractFacNodeId = self.m_interactFacNodeId
    self.m_selectedInteractSubBuildingIndex = self.m_interactSubBuildingIndex
    self.m_selectedInteractLogisticPos = self.m_interactLogisticPos
    self.m_selectedInteractPipeNodeId = self.m_interactPipeNodeId
    self.m_selectedInteractFacNodeIdIsBuilding = self.m_interactFacNodeIdIsBuilding
    if LuaSystemManager.facSystem.inDestroyMode or not DeviceInfo.usingTouch then
        return
    end
    if not self.m_selectedInteractFacNodeId and not self.m_selectedInteractLogisticPos and not self.m_selectedInteractPipeNodeId then
        self.view.listNode.gameObject:SetActiveIfNecessary(false)
        return
    end
    local name, effect
    if self.m_selectedInteractFacNodeId then
        if self.m_selectedInteractFacNodeIdIsBuilding then
            if self.m_selectedInteractSubBuildingIndex >= 0 then
                name = Language.LUA_FAC_HUB_INPUT .. self.m_selectedInteractSubBuildingIndex
            else
                local nodeHandler = FactoryUtils.getBuildingNodeHandler(self.m_selectedInteractFacNodeId)
                local buildingId = nodeHandler.templateId
                local buildingData = Tables.factoryBuildingTable[buildingId]
                name = buildingData.name
            end
        else
            local nodeHandler = FactoryUtils.getBuildingNodeHandler(self.m_selectedInteractFacNodeId)
            local unitData = FactoryUtils.getLogisticData(nodeHandler.templateId)
            name = unitData.name
        end
        effect = self.m_buildingInteractHighlightEffect
    elseif self.m_selectedInteractLogisticPos then
        local chapterInfo = FactoryUtils.getCurChapterInfo()
        local succ, nodeId, unitIndex = GameInstance.remoteFactoryManager:TrySampleConveyor(self.m_selectedInteractLogisticPos)
        local nodeHandler = chapterInfo:GetNode(nodeId)
        name = Tables.factoryGridBeltTable:GetValue(nodeHandler.templateId).beltData.name
        effect = self.m_logisticInteractHighlightEffect
    elseif self.m_selectedInteractPipeNodeId then
        name = Language.LUA_FAC_PIPE_INTERACT_OPTION
    end
    self.view.optionItem.normalNode.nameTxt.text = name
    self.view.listNode.gameObject:SetActiveIfNecessary(true)
    self.view.optionItem.animator:Play("In", -1, 0)
    self.view.optionItem.animator:Play("Highlighted", -1, 0)
    if DeviceInfo.usingTouch then
        self.view.listNode.transform.position = self.m_listInitPos
    else
        local posList = { effect.corner1.transform.position, effect.corner2.transform.position, effect.corner3.transform.position, effect.corner4.transform.position, }
        local min = effect.corner1.transform.position
        local max = effect.corner1.transform.position
        for _, v in ipairs(posList) do
            min.x = math.min(min.x, v.x)
            min.y = math.min(min.y, v.y)
            min.z = math.min(min.z, v.z)
            max.x = math.max(max.x, v.x)
            max.y = math.max(max.y, v.y)
            max.z = math.max(max.z, v.z)
        end
        min = CameraManager.mainCamera:WorldToScreenPoint(min)
        max = CameraManager.mainCamera:WorldToScreenPoint(max)
        local size = max - min
        size.x = math.abs(size.x)
        size.y = math.abs(size.y)
        min.x = math.min(min.x, max.x)
        min.y = math.min(min.y, max.y)
        min.z = math.min(min.z, max.z)
        max = min + size
        local targetScreenRect = Unity.Rect(min.x, Screen.height - (min.y + size.y), size.x, size.y)
        UIUtils.updateTipsPositionWithScreenRect(self.view.listNode.transform, targetScreenRect, self.view.transform, self.uiCamera, UIConst.UI_TIPS_POS_TYPE.RightMid, { top = 100, left = 250, right = 250, bottom = 280, })
    end
end
FacBuildingInteractCtrl._OnClickFakeInteractOption = HL.Method(HL.Opt(HL.Boolean)) << function(self, isAll)
    if self.m_selectedInteractFacNodeId then
        if self.m_selectedInteractFacNodeIdIsBuilding then
            if self.m_selectedInteractSubBuildingIndex >= 0 then
                self:_OnInteractFactory({ buildingNodeId = self.m_selectedInteractFacNodeId, subBuildingIndex = self.m_selectedInteractSubBuildingIndex, })
            else
                self:_OnInteractFactory({ buildingNodeId = self.m_selectedInteractFacNodeId })
            end
        else
            self:_OnInteractFactory({ nodeId = self.m_selectedInteractFacNodeId })
        end
    elseif self.m_selectedInteractLogisticPos then
        local succ, nodeId, unitIndex = GameInstance.remoteFactoryManager:TrySampleConveyor(self.m_selectedInteractLogisticPos)
        self:_OnInteractFactory({ nodeId = nodeId, unitIndex = unitIndex, logisticPos = self.m_selectedInteractLogisticPos, isAll = isAll, })
    elseif self.m_selectedInteractPipeNodeId then
        self:_OnInteractFactory({ nodeId = self.m_selectedInteractPipeNodeId, })
    end
end
FacBuildingInteractCtrl.OnFacTopViewCamTargetMoved = HL.Method() << function(self)
    if FactoryUtils.isInBuildMode() or LuaSystemManager.facSystem.inDestroyMode then
        return
    end
    if self.m_selectedInteractFacNodeId or self.m_selectedInteractLogisticPos or self.m_selectedInteractPipeNodeId then
        self:_RemoveInteractOption()
    end
end
FacBuildingInteractCtrl.m_isReverseBatchSelect = HL.Field(HL.Boolean) << false
FacBuildingInteractCtrl.m_oldBatchSelectedTargetIds = HL.Field(HL.Table)
FacBuildingInteractCtrl._ResetBatch = HL.Method(HL.Boolean) << function(self, inDestroyMode)
    self.view.batchSelectFrame.gameObject:SetActive(false)
    self.view.batchToggle.isOn = inDestroyMode and LuaSystemManager.facSystem.inTopView and DeviceInfo.usingKeyboard
    self.view.reverseToggle.gameObject:SetActive(false)
    self.view.reverseToggle.isOn = false
end
FacBuildingInteractCtrl._ChangeBatchMode = HL.Method(HL.Boolean) << function(self, isBatch)
    LuaSystemManager.facSystem.inBatchSelectMode = isBatch
    self:_ClearAllBatchTargets()
    Notify(MessageConst.FAC_ON_TOGGLE_BATH_MODE, isBatch)
    self.view.reverseToggle.isOn = false
    self.view.reverseToggle.gameObject:SetActive(false)
    Notify(MessageConst.CHANGE_MOUSE_ICON_HINT, { name = "FacBuildingInteract-BatchMode", type = isBatch and UIConst.MOUSE_ICON_HINT.Frame or UIConst.MOUSE_ICON_HINT.Default, })
    self:_ClearBeltHoverHint()
end
FacBuildingInteractCtrl._OnChangeDragBatchToggle = HL.Method(HL.Boolean) << function(self, isBatch)
    LuaSystemManager.facSystem.inDragSelectBatchMode = isBatch
end
FacBuildingInteractCtrl._ClearAllBatchTargets = HL.Method() << function(self)
    for nodeId, info in pairs(LuaSystemManager.facSystem.batchSelectTargets) do
        GameInstance.remoteFactoryManager:HighLightBuilding(nodeId, false)
    end
    LuaSystemManager.facSystem.batchSelectTargets = {}
end
FacBuildingInteractCtrl._OnChangeReverseToggle = HL.Method(HL.Boolean) << function(self, isReverse)
    self.m_isReverseBatchSelect = isReverse
end
FacBuildingInteractCtrl._OnDragBeginInBathMode = HL.Method(Vector2) << function(self, pos)
    if DeviceInfo.usingKeyboard then
        self.view.reverseToggle.isOn = InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.Mouse1)
    end
    self.m_oldBatchSelectedTargetIds = {}
    for id, info in pairs(LuaSystemManager.facSystem.batchSelectTargets) do
        self.m_oldBatchSelectedTargetIds[id] = lume.copy(info)
    end
    LuaSystemManager.facSystem.canMoveCamTarget = false
    Notify(MessageConst.FAC_ON_DRAG_BEGIN_IN_BATH_MODE)
end
FacBuildingInteractCtrl._OnDragEndInBathMode = HL.Method(Vector2) << function(self, pos)
    if DeviceInfo.usingKeyboard then
        self.view.reverseToggle.isOn = false
    end
    self.view.batchSelectFrame.gameObject:SetActive(false)
    self.m_oldBatchSelectedTargetIds = {}
    LuaSystemManager.facSystem.canMoveCamTarget = true
    Notify(MessageConst.FAC_ON_DRAG_END_IN_BATH_MODE)
end
FacBuildingInteractCtrl._OnDragInBathMode = HL.Method(CS.UnityEngine.EventSystems.PointerEventData) << function(self, eventData)
    local startScreenPos = eventData.pressPosition
    local endScreenPos = eventData.position
    local _, startWorldPos = CSFactoryUtil.SampleLevelRegionPointWithRay(CameraManager.mainCamera:ScreenPointToRay(startScreenPos:XY()))
    local _, endWorldPos = CSFactoryUtil.SampleLevelRegionPointWithRay(CameraManager.mainCamera:ScreenPointToRay(endScreenPos:XY()))
    local posXMin = math.floor(math.min(startWorldPos.x, endWorldPos.x))
    local posZMin = math.floor(math.min(startWorldPos.z, endWorldPos.z))
    local posXMax = math.ceil(math.max(startWorldPos.x, endWorldPos.x))
    local posZMax = math.ceil(math.max(startWorldPos.z, endWorldPos.z))
    local width = posXMax - posXMin
    local height = posZMax - posZMin
    local frame = self.view.batchSelectFrame
    local startUIPos = UIUtils.objectPosToUI(Vector3(posXMin, startWorldPos.y, posZMin), self.uiCamera, self.view.transform)
    local endUIPos = UIUtils.objectPosToUI(Vector3(posXMax, startWorldPos.y, posZMax), self.uiCamera, self.view.transform)
    frame.anchoredPosition = startUIPos
    local uiSize = endUIPos - startUIPos
    frame.sizeDelta = Vector2(math.abs(uiSize.x), math.abs(uiSize.y))
    frame.localScale = Vector3(uiSize.x > 0 and 1 or -1, uiSize.y > 0 and -1 or 1, 1)
    frame.gameObject:SetActive(true)
    local excludeBelt, excludePipe = GameInstance.remoteFactoryManager:GetSimpleFigureInfo()
    local targetNodeIds, beltInfos = CSFactoryUtil.GetFacEntityInRect(LuaSystemManager.facSystem.inDestroyMode, startWorldPos, endWorldPos, excludeBelt, excludePipe)
    local targetNodeIdTbl = {}
    for _, v in pairs(targetNodeIds) do
        targetNodeIdTbl[v] = true
    end
    for k, v in pairs(beltInfos) do
        local t = Utils.csList2Table(v)
        targetNodeIdTbl[k] = t
    end
    if self.m_isReverseBatchSelect then
        for nodeId, info in pairs(self.m_oldBatchSelectedTargetIds) do
            if info == true then
                self:_SelectBatchTarget(nodeId, true)
            else
                for unitIndex, _ in pairs(info) do
                    self:_SelectBatchTarget(nodeId, true, unitIndex)
                end
            end
        end
        for nodeId, info in pairs(targetNodeIdTbl) do
            if info == true then
                self:_SelectBatchTarget(nodeId, false)
            else
                for unitIndex, _ in pairs(info) do
                    self:_SelectBatchTarget(nodeId, false, unitIndex)
                end
            end
        end
    else
        local delInfos = {}
        for nodeId, info in pairs(LuaSystemManager.facSystem.batchSelectTargets) do
            local info1, info2 = targetNodeIdTbl[nodeId], self.m_oldBatchSelectedTargetIds[nodeId]
            if not info1 and not info2 then
                delInfos[nodeId] = true
            elseif info1 ~= true and info2 ~= true then
                local delInfo = {}
                local length = CSFactoryUtil.GetConveyorLength(Utils.getCurrentChapterId(), nodeId)
                for k = 0, length - 1 do
                    if not ((info1 and info1[k]) or (info2 and info2[k])) then
                        delInfo[k] = true
                    end
                end
                delInfos[nodeId] = delInfo
            end
        end
        for nodeId, info in pairs(delInfos) do
            if info == true then
                self:_SelectBatchTarget(nodeId, false)
            else
                for unitIndex, _ in pairs(info) do
                    self:_SelectBatchTarget(nodeId, false, unitIndex)
                end
            end
        end
        for nodeId, info in pairs(targetNodeIdTbl) do
            if info == true then
                self:_SelectBatchTarget(nodeId, true)
            else
                for unitIndex, _ in pairs(info) do
                    self:_SelectBatchTarget(nodeId, true, unitIndex)
                end
            end
        end
    end
end
FacBuildingInteractCtrl._SelectBatchTarget = HL.Method(HL.Number, HL.Boolean, HL.Opt(HL.Number, HL.Boolean)) << function(self, nodeId, isAdd, unitIndex, needToast)
    if not FactoryUtils.canDelBuilding(nodeId, needToast) then
        return
    end
    local targets = LuaSystemManager.facSystem.batchSelectTargets
    local info = targets[nodeId]
    if not unitIndex then
        if isAdd then
            if info ~= true then
                targets[nodeId] = true
                GameInstance.remoteFactoryManager:HighLightBuilding(nodeId, true, -1, true)
            end
        else
            if info then
                targets[nodeId] = nil
                GameInstance.remoteFactoryManager:HighLightBuilding(nodeId, false, -1, true)
            end
        end
    else
        if isAdd then
            if info == true then
                return
            elseif not info then
                info = {}
                targets[nodeId] = info
            elseif info[unitIndex] then
                return
            end
            info[unitIndex] = true
            GameInstance.remoteFactoryManager:HighLightBuilding(nodeId, true, unitIndex, true)
        else
            if not info then
                return
            elseif info == true then
                info = {}
                targets[nodeId] = info
                local length = CSFactoryUtil.GetConveyorLength(Utils.getCurrentChapterId(), nodeId)
                for k = 0, length - 1 do
                    if k ~= unitIndex then
                        info[k] = true
                        GameInstance.remoteFactoryManager:HighLightBuilding(nodeId, true, k, true)
                    else
                        GameInstance.remoteFactoryManager:HighLightBuilding(nodeId, false, unitIndex, true)
                    end
                end
            elseif not info[unitIndex] then
                return
            else
                info[unitIndex] = nil
                GameInstance.remoteFactoryManager:HighLightBuilding(nodeId, false, unitIndex, true)
            end
        end
    end
end
FacBuildingInteractCtrl._NeedShowHoverHint = HL.Method().Return(HL.Boolean) << function(self)
    return LuaSystemManager.facSystem.inTopView and not LuaSystemManager.facSystem.inBatchSelectMode
end
FacBuildingInteractCtrl._ToggleBeltHoverHint = HL.Method(CS.UnityEngine.Vector2Int, HL.Boolean) << function(self, pos, isActive)
    local manager = GameInstance.remoteFactoryManager
    local succ, nodeId, unitIndex = manager:TrySampleConveyor(pos)
    if not isActive then
        manager:HighLightBuilding(nodeId, false)
        return
    end
    manager:HighLightBuilding(nodeId, true)
end
FacBuildingInteractCtrl._UpdatePipeHoverHint = HL.Method() << function(self)
end
FacBuildingInteractCtrl._ClearBeltHoverHint = HL.Method() << function(self)
    if self.m_interactLogisticPos then
        self:_ToggleBeltHoverHint(self.m_interactLogisticPos, false)
    end
    self.view.hoverInfoTextNode.gameObject:SetActive(false)
end
FacBuildingInteractCtrl._SlowlyUpdate = HL.Method() << function(self)
end
FacBuildingInteractCtrl._UpdateHoverInfoText = HL.Method() << function(self)
    if not self.view.hoverInfoTextNode.gameObject.activeInHierarchy then
        return
    end
    local manager = GameInstance.remoteFactoryManager
    local name, itemId, _
    if self.m_interactLogisticPos then
        local succ, nodeId, unitIndex = manager:TrySampleConveyor(self.m_interactLogisticPos)
        local chapterInfo = FactoryUtils.getCurChapterInfo()
        local nodeHandler = chapterInfo:GetNode(nodeId)
        name = Tables.factoryGridBeltTable:GetValue(nodeHandler.templateId).beltData.name
        _, itemId = manager:GetItemInLogisticPos(chapterInfo.chapterId, nodeId, self.m_interactLogisticPos)
    elseif self.m_interactPipeNodeId then
        local nodeId = self.m_interactPipeNodeId
        local chapterInfo = FactoryUtils.getCurChapterInfo()
        local nodeHandler = chapterInfo:GetNode(nodeId)
        name = Tables.factoryLiquidPipeTable:GetValue(nodeHandler.templateId).pipeData.name
        _, itemId = manager:GetItemInPipe(chapterInfo.chapterId, nodeId)
    end
    if string.isEmpty(itemId) then
        self.view.hoverInfoTextNode.text.text = string.format(Language.LUA_FAC_DES_HOVER_INFO_NO_ITEM, name)
    else
        local itemData = Tables.itemTable[itemId]
        self.view.hoverInfoTextNode.text.text = string.format(Language.LUA_FAC_DES_HOVER_INFO, name, itemData.name)
    end
end
HL.Commit(FacBuildingInteractCtrl)