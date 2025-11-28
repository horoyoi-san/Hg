local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
BuildingCommon = HL.Class('BuildingCommon', UIWidgetBase)
local BUILDING_BOTTOM_BG_NAME = "bg_machine_base_%d"
BuildingCommon.nodeId = HL.Field(HL.Number) << -1
BuildingCommon.buildingId = HL.Field(HL.String) << ""
BuildingCommon.buildingUiInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.NodeUIInfo)
BuildingCommon.buildingItemId = HL.Field(HL.String) << ""
BuildingCommon.lastState = HL.Field(GEnums.FacBuildingState)
BuildingCommon.bgRatio = HL.Field(HL.Number) << -1
BuildingCommon.m_arg = HL.Field(HL.Table)
BuildingCommon.m_showPower = HL.Field(HL.Boolean) << false
BuildingCommon.m_powerColor = HL.Field(HL.String) << ""
BuildingCommon._OnFirstTimeInit = HL.Override() << function(self)
    self.view.closeButton.onClick:AddListener(function()
        self:Close()
    end)
    self.view.wikiButton.onClick:AddListener(function()
        local args = {}
        if not string.isEmpty(self.buildingItemId) then
            args.itemId = self.buildingItemId
        else
            args.buildingId = self.buildingId
        end
        Notify(MessageConst.SHOW_WIKI_ENTRY, args)
    end)
    self.view.moveButton.onClick:AddListener(function()
        self:_MoveBuilding()
    end)
    self.view.delButton.onClick:AddListener(function()
        self:_DelBuilding()
    end)
    self.view.forbiddenMoveButton.onClick:AddListener(function()
        Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_FORBID_MOVE_OR_DELETE)
    end)
    self.view.forbiddenDelButton.onClick:AddListener(function()
        Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_FORBID_MOVE_OR_DELETE)
    end)
end
BuildingCommon.InitBuildingCommon = HL.Method(HL.Opt(CS.Beyond.Gameplay.RemoteFactory.NodeUIInfo, HL.Table)) << function(self, uiInfo, arg)
    self:_FirstTimeInit()
    local hasUiInfo = uiInfo ~= nil
    arg = arg or {}
    self.m_arg = arg
    local data
    if hasUiInfo then
        self.buildingUiInfo = uiInfo
        self.nodeId = uiInfo.nodeId
        self.buildingId = uiInfo.buildingId
        data = Tables.factoryBuildingTable:GetValue(self.buildingId)
        self.view.powerToggle:InitCommonToggle(function(isOn)
            self:_OnToggleBuildingPower(isOn)
        end, self.buildingUiInfo.isActive, true)
        self:_UpdateBuildingState(true)
        self:_StartCoroutine(function()
            while true do
                coroutine.step()
                self:_UpdateBuildingState()
            end
        end)
        self.m_showPower = data.powerConsume > 0
        if uiInfo.skillBoard and uiInfo.skillBoard.powerCostDeltaScale < 0 then
            self.m_powerColor = UIConst.FAC_BUILDING_BUFF_COLOR_STR
        elseif uiInfo.skillBoard and uiInfo.skillBoard.powerCostDeltaScale > 0 then
            self.m_powerColor = UIConst.FAC_BUILDING_DEBUFF_COLOR_STR
        end
        self.view.facCharacterBonusNode:InitFacCharacterBonusNode(uiInfo.nodeId)
        self:_InitBuildingBG(uiInfo.nodeId, data.bgOnPanel)
        self:_InitBuildingOperateButtonState(uiInfo.nodeId)
    else
        data = arg.data
        self.buildingItemId = data.itemId
        self.view.moveButton.gameObject:SetActive(false)
        self.view.delButton.gameObject:SetActive(false)
        self.view.leftButtonDecoLine.gameObject:SetActive(false)
        self.view.powerToggle.gameObject:SetActive(false)
        self.view.stateIcon.gameObject:SetActive(false)
        self.view.facCharacterBonusNode.gameObject:SetActive(false)
        self.m_showPower = false
        self:_InitBuildingCustomButtons()
        if data.nodeId ~= nil then
            self:_InitBuildingOperateButtonState(data.nodeId)
        end
    end
    self:_InitBuildingDescription()
    if self.m_showPower then
        self.view.powerNode.gameObject:SetActive(true)
        self.view.decoLine.gameObject:SetActive(true)
        local powerCost = FactoryUtils.getCurBuildingConsumePower(self.nodeId)
        if string.isEmpty(self.m_powerColor) then
            self.view.powerText.text = powerCost
        else
            self.view.powerText.text = string.format(UIConst.COLOR_STRING_FORMAT, self.m_powerColor, powerCost)
        end
    else
        self.view.powerNode.gameObject:SetActive(false)
        self.view.decoLine.gameObject:SetActive(false)
    end
    self:UpdateBasicInfo(data)
    local ctrl = self:GetUICtrl()
    ctrl.view.controllerHintPlaceholder = self.view.controllerHintPlaceholder
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ ctrl.view.inputGroup.groupId })
    local extraBtnInfos = {}
    if self.view.powerToggle.gameObject.activeInHierarchy then
        table.insert(extraBtnInfos, {
            action = function()
                self.view.powerToggle:Toggle()
            end,
            sprite = self:LoadSprite("Factory/BuildingCommon/controller_second_menu_power_icon"),
            textId = "key_hint_fac_machine_power_toggle",
            priority = 19,
        })
    end
    if ctrl.view.formulaNode then
        table.insert(extraBtnInfos, { button = ctrl.view.formulaNode.view.openBtn, sprite = ctrl.view.formulaNode.view.openBtnIcon.sprite, textId = "key_hint_fac_machine_toggle_formula", priority = 18, })
    end
    self.view.controllerSecondMenuBtn:InitControllerSecondMenuBtn({ buildingNodeId = self.nodeId, extraBtnInfos = extraBtnInfos, })
end
BuildingCommon.UpdateBasicInfo = HL.Method(HL.Any) << function(self, data)
    self.view.machineName.text = data.name
    self.view.machineIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_BUILDING_PANEL_ICON, data.iconOnPanel)
    if self.m_showPower then
        self.view.powerNode.gameObject:SetActive(data.needPower)
        self.view.powerNodeNeedPower.gameObject:SetActive(not data.needPower)
    end
end
BuildingCommon._OnToggleBuildingPower = HL.Method(HL.Boolean) << function(self, isOn)
    if isOn == self.buildingUiInfo.isActive then
        return
    end
    self.buildingUiInfo.sender:Message_OpEnableNode(Utils.getCurrentChapterId(), self.nodeId, isOn, function()
        if self.m_showPower then
            self.view.powerText.text = FactoryUtils.getCurBuildingConsumePower(self.nodeId)
        end
        if self.m_arg.onPowerChanged then
            self.m_arg.onPowerChanged(isOn)
        end
    end)
end
BuildingCommon._UpdateBuildingState = HL.Method(HL.Opt(HL.Boolean)) << function(self, forceUpdate)
    local state = FactoryUtils.getBuildingStateType(self.nodeId)
    if not forceUpdate and state == self.lastState then
        return
    end
    self.lastState = state
    self:_RefreshBuildingStateDisplay(state, self.view.stateNode)
end
BuildingCommon._RefreshBuildingStateDisplay = HL.Method(GEnums.FacBuildingState, HL.Table) << function(self, state, stateNode)
    local isBlock, isNoPower, isNoCraft, isNormal, isStopped, isNotLinked = false, false, false, false, false, false
    if state == GEnums.FacBuildingState.Closed then
        isStopped = true
    elseif state == GEnums.FacBuildingState.Blocked then
        isBlock = true
    elseif state == GEnums.FacBuildingState.NoPower then
        isNoPower = true
    elseif state == GEnums.FacBuildingState.NotInPowerNet then
        isNotLinked = true
    else
        if state == GEnums.FacBuildingState.Idle then
            if string.isEmpty(self.buildingUiInfo.formulaId) or self.lastState == GEnums.FacBuildingState.Invalid then
                isNoCraft = true
            end
        end
        if not isNoCraft then
            isNormal = true
        end
    end
    stateNode.stopped.gameObject:SetActiveIfNecessary(isStopped)
    stateNode.normal.gameObject:SetActiveIfNecessary(isNormal)
    stateNode.powerNotEnough.gameObject:SetActiveIfNecessary(isNoPower)
    stateNode.notLinked.gameObject:SetActiveIfNecessary(isNotLinked)
    stateNode.noCraft.gameObject:SetActiveIfNecessary(isNoCraft)
    stateNode.block.gameObject:SetActiveIfNecessary(isBlock)
    self.view.stateIcon.sprite = self:LoadSprite(FactoryUtils.getBuildingStateIconName(nil, state))
    if self.m_arg.onStateChanged then
        self.m_arg.onStateChanged(state)
    end
end
BuildingCommon._MoveBuilding = HL.Method() << function(self)
    local nodeId = self.nodeId
    if not FactoryUtils.canMoveBuilding(nodeId) then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_FACTORY_BUILDING_MOVE_NOT_ALLOWED)
        return
    end
    self:Close(true)
    Notify(MessageConst.FAC_ENTER_BUILDING_MODE, { nodeId = nodeId })
end
BuildingCommon._DelBuilding = HL.Method() << function(self)
    if not FactoryUtils.canDelBuilding(self.nodeId, true) then
        return
    end
    self:Close(true)
    local data = Tables.factoryBuildingTable:GetValue(self.buildingId)
    local hintTxt
    if data ~= nil then
        hintTxt = data.delConfirmText
    end
    FactoryUtils.delBuilding(self.nodeId, nil, false, hintTxt)
end
BuildingCommon._InitBuildingBG = HL.Method(HL.Number, HL.String) << function(self, buildingNodeId, buildingBgId)
    local inPortInfoList, outPortInfoList = FactoryUtils.getBuildingPortState(buildingNodeId, false)
    if inPortInfoList == nil or outPortInfoList == nil then
        return
    end
    if not string.isEmpty(buildingBgId) and not self.view.config.USE_CUSTOM_BG then
        local inPortCount, outPortCount = #inPortInfoList, #outPortInfoList
        if not GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedBelt or not GameInstance.remoteFactoryManager:IsWorldPositionInMainRegion(self.buildingUiInfo.nodeHandler.transform.worldPosition) then
            inPortCount, outPortCount = 0, 0
        end
        local inBottomBGName = string.format(BUILDING_BOTTOM_BG_NAME, inPortCount)
        local outBottomBGName = string.format(BUILDING_BOTTOM_BG_NAME, outPortCount)
        local inBottomBG = self:LoadSprite(UIConst.UI_SPRITE_FAC_MACHINE_BG, inBottomBGName)
        local outBottomBG = self:LoadSprite(UIConst.UI_SPRITE_FAC_MACHINE_BG, outBottomBGName)
        if inBottomBG ~= nil then
            self.view.leftPart.sprite = inBottomBG
        end
        if outBottomBG ~= nil then
            self.view.rightPart.sprite = outBottomBG
        end
        local buildingBg = self:LoadSprite(UIConst.UI_SPRITE_FAC_MACHINE_BG, buildingBgId)
        if buildingBg ~= nil then
            self.view.machineBg.sprite = buildingBg
            if self.view.config.NEED_RESIZE_BOTTOM_BG then
                local originalWidth = self.view.machineBgRect.rect.width
                self.view.machineBg:SetNativeSize()
                local currentWidth = self.view.machineBgRect.rect.width
                if currentWidth ~= originalWidth then
                    local ratio = currentWidth / originalWidth * self.view.config.MACHINE_TO_BOTTOM_RATIO
                    local originalBottomSize = self.view.bottomBgRect.sizeDelta
                    self.view.bottomBgRect.sizeDelta = Vector2(originalBottomSize.x * ratio, originalBottomSize.y)
                    local originalPartSize = self.view.leftPartRect.sizeDelta
                    self.view.leftPartRect.sizeDelta = Vector2(originalPartSize.x * ratio, originalPartSize.y)
                    self.view.rightPartRect.sizeDelta = Vector2(originalPartSize.x * ratio, originalPartSize.y)
                    self.bgRatio = ratio
                end
            end
        end
    end
end
BuildingCommon._InitBuildingDescription = HL.Method() << function(self)
    if self.config.SHOW_BUILDING_DESCRIPTION then
        self.view.machineDescNode.gameObject:SetActiveIfNecessary(true)
        local itemData
        if string.isEmpty(self.buildingId) then
            itemData = Tables.itemTable:GetValue(self.buildingItemId)
        else
            itemData = FactoryUtils.getBuildingItemData(self.buildingId)
        end
        if itemData ~= nil then
            self.view.descText.text = itemData.desc
        end
    else
        self.view.machineDescNode.gameObject:SetActiveIfNecessary(false)
    end
end
BuildingCommon._InitBuildingOperateButtonState = HL.Method(HL.Number) << function(self, nodeId)
    local canMove, canDel = FactoryUtils.canMoveBuilding(nodeId), FactoryUtils.canDelBuilding(nodeId)
    local needMoveBtn = self.view.moveButton.gameObject.activeSelf
    local needDelBtn = self.view.delButton.gameObject.activeSelf
    self.view.moveButton.gameObject:SetActive(needMoveBtn and canMove)
    self.view.forbiddenMoveButton.gameObject:SetActive(needMoveBtn and not canMove)
    self.view.delButton.gameObject:SetActive(needDelBtn and canDel)
    self.view.forbiddenDelButton.gameObject:SetActive(needDelBtn and not canDel)
end
BuildingCommon._InitBuildingCustomButtons = HL.Method() << function(self)
    local leftButtonValid, rightButtonValid = false, false
    if self.m_arg.customLeftButtonOnClicked ~= nil then
        self.view.moveButton.onClick:RemoveAllListeners()
        self.view.moveButton.onClick:AddListener(function()
            self.m_arg.customLeftButtonOnClicked()
        end)
        self.view.moveButton.gameObject:SetActive(true)
        leftButtonValid = true
    end
    if self.m_arg.customRightButtonOnClicked ~= nil then
        self.view.delButton.onClick:RemoveAllListeners()
        self.view.delButton.onClick:AddListener(function()
            self.m_arg.customRightButtonOnClicked()
        end)
        self.view.delButton.gameObject:SetActive(true)
        rightButtonValid = true
    end
    self.view.leftButtonDecoLine.gameObject:SetActive(leftButtonValid and rightButtonValid)
end
BuildingCommon.Close = HL.Method(HL.Opt(HL.Boolean)) << function(self, skipAnim)
    if not skipAnim then
        if PhaseManager:GetTopPhaseId() == PhaseId.FacMachine then
            PhaseManager:PopPhase(PhaseId.FacMachine)
        end
    else
        PhaseManager:ExitPhaseFast(PhaseId.FacMachine)
    end
end
BuildingCommon.ChangeBuildingStateDisplay = HL.Method(GEnums.FacBuildingState) << function(self, state)
    if state == nil then
        return
    end
    if state == self.lastState then
        return
    end
    self:_RefreshBuildingStateDisplay(state, self.view.stateNode)
    self.lastState = state
end
HL.Commit(BuildingCommon)
return BuildingCommon