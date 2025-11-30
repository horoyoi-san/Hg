local phaseBase = require_ex('Phase/Core/PhaseBase')
local PHASE_ID = PhaseId.FacMachine
PhaseFacMachine = HL.Class('PhaseFacMachine', phaseBase.PhaseBase)
PhaseFacMachine.s_messages = HL.StaticField(HL.Table) << { [MessageConst.FAC_OPEN_BUILDING_PANEL] = { 'OpenBuildingPanel', false }, [MessageConst.FAC_OPEN_BUILDING_PANEL_ALTER] = { 'OpenBuildingPanelAlter', false }, [MessageConst.FAC_OPEN_LOGISTIC_PANEL] = { 'OpenLogisticPanel', false }, [MessageConst.FAC_OPEN_NEAREST_BUILDING_PANEL] = { 'OpenNearestBuildingPanel', false }, }
local ReservePanelIds = { PanelId.Joystick, PanelId.LevelCamera, }
local QuestState = CS.Beyond.Gameplay.MissionSystem.QuestState
PhaseFacMachine.curPanelId = HL.Field(HL.Number) << -1
PhaseFacMachine.curPanelItem = HL.Field(HL.Forward("PhasePanelItem"))
PhaseFacMachine.curNodeId = HL.Field(HL.Any)
PhaseFacMachine.m_panelArg = HL.Field(HL.Any)
PhaseFacMachine.m_panelBuildingDataId = HL.Field(HL.Any)
PhaseFacMachine.m_hidePanelKey = HL.Field(HL.Number) << -1
PhaseFacMachine.m_isDoingOut = HL.Field(HL.Boolean) << false
PhaseFacMachine.curUIInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.NodeUIInfo)
PhaseFacMachine.m_curBuildingPos = HL.Field(Vector3)
PhaseFacMachine.m_curBuildingRadius = HL.Field(HL.Number) << 0
PhaseFacMachine.m_isHalfPanel = HL.Field(HL.Boolean) << false
PhaseFacMachine.m_updateKey = HL.Field(HL.Number) << -1
PhaseFacMachine.m_tickInitialized = HL.Field(HL.Boolean) << false
PhaseFacMachine.OpenBuildingPanel = HL.StaticMethod(HL.Table) << function(args)
    local nodeId = args.nodeId
    local buildingSyncNode = FactoryUtils.getBuildingNodeHandler(nodeId)
    if not GameInstance.player.guide.skipAllGuide then
        if PhaseFacMachine.CheckPanelUnlockedState(buildingSyncNode.templateId, buildingSyncNode.instKey, args.customArg) == false then
            return
        end
    end
    args.isBuilding = true
    Notify(MessageConst.FAC_BUILD_EXIT_CUR_MODE, true)
    if args.skipAnim then
        PhaseManager:OpenPhaseFast(PhaseId.FacMachine, args)
    else
        PhaseManager:OpenPhase(PhaseId.FacMachine, args)
    end
end
PhaseFacMachine.OpenBuildingPanelAlter = HL.StaticMethod(HL.Table) << function(args)
    local nodeId, customArg, buildingId = unpack(args)
    PhaseFacMachine.OpenBuildingPanel({ nodeId = nodeId, customArg = customArg, panelBuildingDataId = buildingId, })
end
PhaseFacMachine.OpenLogisticPanel = HL.StaticMethod(HL.Table) << function(args)
    args.isBuilding = false
    PhaseManager:OpenPhase(PhaseId.FacMachine, args)
end
PhaseFacMachine.OpenNearestBuildingPanel = HL.StaticMethod(HL.Table) << function(arg)
    local buildingId, ignoreCull = unpack(arg)
    local isOpen, phase = PhaseManager:IsOpen(PhaseId.FacMachine)
    if isOpen then
        local buildingData = Tables.factoryBuildingTable[buildingId]
        local buildingType = buildingData.type
        local panelName = unpack(FacConst.FACTORY_BUILDING_UI_MAP[buildingType])
        local panelId = PanelId[panelName]
        if phase.curPanelId == panelId then
            return
        end
        PhaseManager:ExitPhaseFast(PhaseId.FacMachine)
    end
    local succ, targetNodeId = FactoryUtils.findNearestBuilding(buildingId, ignoreCull)
    if not succ then
        logger.error("OpenNearestBuildingPanel 失败，找不到建筑", buildingId)
        return
    end
    PhaseFacMachine.OpenBuildingPanel({ nodeId = targetNodeId, skipAnim = true, ignoreDist = true, })
end
PhaseFacMachine._OnInit = HL.Override() << function(self)
    PhaseFacMachine.Super._OnInit(self)
    local nodeId = self.arg.nodeId
    self.curNodeId = nodeId
    if self.arg.isBuilding then
        local panelBuildingDataId = self.arg.panelBuildingDataId
        local customArg = self.arg.customArg
        local buildingSyncNode = FactoryUtils.getBuildingNodeHandler(nodeId)
        local buildingId = buildingSyncNode.templateId
        local buildingData = Tables.factoryBuildingTable[buildingId]
        local buildingType
        if buildingSyncNode.nodeType == GEnums.FCNodeType.Special:GetHashCode() then
            buildingType = buildingData.type
        else
            _, buildingType = CSFactoryUtil.GetFacBuildingType(buildingSyncNode.nodeType)
        end
        if nodeId then
            local needRepairItems = nil
            local predefinedParam = buildingSyncNode.predefinedParam
            if predefinedParam then
                local common = predefinedParam.common
                if common then
                    if common.needRepair then
                        needRepairItems = common.repairNeedItem
                    end
                end
            end
            if needRepairItems then
                local unRepair = buildingSyncNode.isNeedRepair
                if unRepair then
                    self.curPanelId = PanelId.FacRepairBuilding
                    self.m_isHalfPanel = true
                    self.m_panelArg = { needRepairItems = needRepairItems, nodeId = nodeId }
                    return
                end
            end
        end
        local panelBuildingType
        if panelBuildingDataId then
            panelBuildingType = Tables.factoryBuildingTable[panelBuildingDataId or buildingId].type
        else
            panelBuildingDataId = buildingId
            panelBuildingType = buildingType
        end
        local panelName, isHalfPanel = unpack(FacConst.FACTORY_BUILDING_UI_MAP[panelBuildingType])
        local panelId = PanelId[panelName]
        self.curPanelId = panelId
        self.m_isHalfPanel = isHalfPanel
        self.curNodeId = nodeId
        self.curUIInfo = GameInstance.remoteFactoryManager.uiInfoProvider:GetBuildingUIInfo(buildingType)
        if self.curUIInfo then
            if not self.arg.ignoreDist then
                self.m_curBuildingPos = CSFactoryUtil.GetBuildingModelPosition(buildingSyncNode)
            end
            local width = buildingData.range.width
            local depth = buildingData.range.depth
            self.m_curBuildingRadius = math.sqrt(width * width + depth * depth) / 2
            if customArg and customArg.subIndex then
                self.curUIInfo:SetupChapterIdAndNodeId(Utils.getCurrentChapterId(), nodeId, customArg.subIndex)
            else
                self.curUIInfo:SetupChapterIdAndNodeId(Utils.getCurrentChapterId(), nodeId)
            end
            if not customArg then
                customArg = { uiInfo = self.curUIInfo }
            else
                customArg.uiInfo = self.curUIInfo
            end
        else
            if not customArg then
                customArg = { nodeId = nodeId }
            else
                customArg.nodeId = nodeId
            end
        end
        self.m_panelBuildingDataId = panelBuildingDataId
        self.m_panelArg = customArg
    else
        self.m_panelArg = self:_ParseNonBuildingPanelArgs(self.arg)
    end
    self:_StartFbAndTickUpdate()
end
PhaseFacMachine._ParseNonBuildingPanelArgs = HL.Method(HL.Table).Return(HL.Table) << function(self, args)
    local result = {}
    if args == nil then
        return result
    end
    local nodeId = args.nodeId
    local nodeHandler = FactoryUtils.getBuildingNodeHandler(nodeId)
    if nodeHandler == nil then
        return result
    end
    local templateId = nodeHandler.templateId
    local panelId = FacConst.FACTORY_NON_BUILDING_UI_MAP[templateId]
    if panelId == nil then
        return result
    end
    local nodeType = nodeHandler.nodeType
    if nodeType == GEnums.FCNodeType.BoxConveyor:GetHashCode() then
        self.curUIInfo = GameInstance.remoteFactoryManager.uiInfoProvider:GetConveyorUIInfo()
        self.curUIInfo:SetupChapterIdAndNodeId(Utils.getCurrentChapterId(), nodeId, args.index)
        result.index = args.index
    elseif nodeType == GEnums.FCNodeType.BoxRouterM1:GetHashCode() or nodeType == GEnums.FCNodeType.BoxBridge:GetHashCode() then
        self.curUIInfo = GameInstance.remoteFactoryManager.uiInfoProvider:GetLogisticUIInfo(templateId)
        self.curUIInfo:SetupChapterIdAndNodeId(Utils.getCurrentChapterId(), nodeId)
    elseif nodeType == GEnums.FCNodeType.FluidConveyor:GetHashCode() then
        self.curUIInfo = GameInstance.remoteFactoryManager.uiInfoProvider:GetPipeUIInfo()
        self.curUIInfo:SetupChapterIdAndNodeId(Utils.getCurrentChapterId(), nodeId)
    elseif nodeType == GEnums.FCNodeType.FluidRouterM1:GetHashCode() or nodeType == GEnums.FCNodeType.FluidBridge:GetHashCode() then
        self.curUIInfo = GameInstance.remoteFactoryManager.uiInfoProvider:GetFluidUnitUIInfo(templateId)
        self.curUIInfo:SetupChapterIdAndNodeId(Utils.getCurrentChapterId(), nodeId)
    end
    self.curPanelId = PanelId[panelId]
    self.m_curBuildingPos = GameUtil.playerPos
    self.m_curBuildingRadius = 1
    self.m_isHalfPanel = false
    result.uiInfo = self.curUIInfo
    return result
end
PhaseFacMachine._StartFbAndTickUpdate = HL.Method() << function(self)
    if self.curUIInfo and not self.m_tickInitialized then
        self.curUIInfo.sender:Message_HSFB(Utils.getCurrentChapterId(), false, { self.curNodeId })
        self.curUIInfo:Update(true)
        self.m_updateKey = LuaUpdate:Add("Tick", function()
            self:_Update()
        end)
        self.m_tickInitialized = true
    end
end
PhaseFacMachine._StopFbAndTickUpdate = HL.Method() << function(self)
    if self.curUIInfo and self.m_tickInitialized then
        self.m_updateKey = LuaUpdate:Remove(self.m_updateKey)
        self.curUIInfo.sender:Message_HSFB(Utils.getCurrentChapterId(), true, { self.curNodeId })
        self.m_tickInitialized = false
    end
end
PhaseFacMachine.PrepareTransition = HL.Override(HL.Number, HL.Boolean, HL.Opt(HL.Number)) << function(self, transitionType, fastMode, anotherPhaseId)
    if transitionType == PhaseConst.EPhaseState.TransitionIn then
        if self.curPanelId then
            UIManager:PreloadPanelAsset(self.curPanelId)
        end
        if self.m_isHalfPanel and anotherPhaseId == PhaseId.Level then
            Notify(MessageConst.SET_PHASE_LEVEL_TRANSITION_RESERVE_PANELS, ReservePanelIds)
        end
    end
end
PhaseFacMachine._DoPhaseTransitionIn = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    self.m_isDoingOut = false
    local reservePanelIds = self.m_isHalfPanel and ReservePanelIds or nil
    self.m_hidePanelKey = UIManager:ClearScreen(reservePanelIds)
    CS.Beyond.Gameplay.Audio.AudioRemoteFactoryBridge.OnUnitUiOpened(self.curNodeId, self.m_panelBuildingDataId)
    self.curPanelItem = self:CreatePhasePanelItem(self.curPanelId, self.m_panelArg)
    if self.m_isHalfPanel then
        Notify(MessageConst.ENTER_LEVEL_HALF_SCREEN_PANEL_MODE)
    end
    if self.m_panelBuildingDataId then
        CS.Beyond.Gameplay.Conditions.OnBuildingPanelOpen.Trigger(self.m_panelBuildingDataId, false)
    end
end
PhaseFacMachine._DoPhaseTransitionOut = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    self.m_isDoingOut = true
    Notify(MessageConst.HIDE_ITEM_TIPS)
    Notify(MessageConst.EXIT_LEVEL_HALF_SCREEN_PANEL_MODE)
    CS.Beyond.Gameplay.Audio.AudioRemoteFactoryBridge.OnUnitUiClosed(self.curNodeId, self.m_panelBuildingDataId)
end
PhaseFacMachine._DoPhaseTransitionOutAfterItems = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    self.m_hidePanelKey = UIManager:RecoverScreen(self.m_hidePanelKey)
end
PhaseFacMachine._DoPhaseTransitionBehind = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseFacMachine._DoPhaseTransitionBackToTop = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhaseFacMachine._OnActivated = HL.Override() << function(self)
    self:_StartFbAndTickUpdate()
    if self.m_panelBuildingDataId and not self.m_isDoingOut then
        CS.Beyond.Gameplay.Conditions.OnBuildingPanelOpen.Trigger(self.m_panelBuildingDataId, true)
    end
end
PhaseFacMachine._OnDeActivated = HL.Override() << function(self)
    self:_StopFbAndTickUpdate()
end
PhaseFacMachine._OnDestroy = HL.Override() << function(self)
    self:_StopFbAndTickUpdate()
    if self.curPanelItem ~= nil then
        self:RemovePhasePanelItem(self.curPanelItem)
    end
end
PhaseFacMachine._Update = HL.Method() << function(self)
    if self.curUIInfo then
        self.curUIInfo:Update()
    end
    if self.m_curBuildingPos and not LuaSystemManager.facSystem.inTopView then
        local playerPos = GameUtil.playerPos
        local dist = (playerPos - self.m_curBuildingPos).magnitude
        if dist > self.m_curBuildingRadius + FacConst.BUILDING_PANEL_AUTO_CLOSE_RANGE then
            self.m_curBuildingPos = nil
            PhaseManager:PopPhase(PhaseId.FacMachine)
            Notify(MessageConst.FAC_UPDATE_INTERACT_OPTION, true)
        end
    end
end
PhaseFacMachine.CheckPanelUnlockedState = HL.StaticMethod(HL.String, HL.String, HL.Opt(HL.Table)).Return(HL.Boolean) << function(buildingId, instKey, args)
    local subIndex = args and args.subIndex or -1
    return not CSFactoryUtil.CheckIsBuildingInteractLocked(buildingId, instKey, true, subIndex)
end
HL.Commit(PhaseFacMachine)