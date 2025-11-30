local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
FacBackground = HL.Class('FacBackground', UIWidgetBase)
FacBackground.nodeId = HL.Field(HL.Any)
FacBackground.buildingId = HL.Field(HL.String) << ""
FacBackground._OnFirstTimeInit = HL.Override() << function(self)
    self:RegisterMessage(MessageConst.ON_FACTORY_CHARACTER_MODIFY, function()
        self:OnCharModify()
    end)
    self:RegisterMessage(MessageConst.ON_FACTORY_SKILL_BOARD_MODIFY, function()
        self:OnSkillBroadModify()
    end)
end
FacBackground.InitFacBackground = HL.Method(HL.Any) << function(self, nodeId)
    self:_FirstTimeInit()
    self.nodeId = nodeId
    local node = FactoryUtils.getBuildingNodeHandler(nodeId)
    local buildingId = node.templateId
    self.buildingId = buildingId
    self.view.facCharacterBonusNode:InitFacCharacterBonusNode(nodeId)
    local data = Tables.factoryBuildingTable:GetValue(buildingId)
    self.view.machineName.text = data.name
    self.view.machineIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_BUILDING_PANEL_ICON, data.iconOnPanel)
    self.view.lvNode.gameObject:SetActiveIfNecessary(true)
    self.view.lvTxt.text = GameInstance.player.facSpMachineSystem:GetLevel(nodeId)
    self.view.closeButton.onClick:RemoveAllListeners()
    self.view.closeButton.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.FacMachine)
    end)
    self.view.moveButton.onClick:RemoveAllListeners()
    self.view.moveButton.onClick:AddListener(function()
        UIManager:Close(self:GetPanelId())
        Notify(MessageConst.FAC_ENTER_BUILDING_MODE, { nodeId = nodeId })
    end)
    self.view.delButton.onClick:RemoveAllListeners()
    self.view.delButton.onClick:AddListener(function()
        UIManager:Close(self:GetPanelId())
        FactoryUtils.delBuilding(nodeId)
    end)
    self.view.powerToggle:InitCommonToggle(function(isOn)
        self:_OnToggleBuildingPower(isOn)
    end, not node.IsDeactive, true)
    self.view.btnChar.onClick:RemoveAllListeners()
    self.view.btnChar.onClick:AddListener(function()
        UIManager:Open(PanelId.FacAssignChar, { nodeId = nodeId })
    end)
    self.view.wikiButton.onClick:RemoveAllListeners()
    self.view.wikiButton.onClick:AddListener(function()
        Notify(MessageConst.SHOW_WIKI_ENTRY, { buildingId = buildingId })
    end)
    self:_RefreshCharSet()
end
FacBackground._RefreshCharSet = HL.Method() << function(self)
    local soltCount = GameInstance.player.facCharacterSystem:GetCharSoltCount(self.buildingId, GameInstance.player.facSpMachineSystem:GetLevel(self.nodeId))
    if soltCount <= 0 then
        self.view.charSet.gameObject:SetActiveIfNecessary(false)
        return
    end
    self.view.charSet.gameObject:SetActiveIfNecessary(true)
    local characterList = GameInstance.player.facCharacterSystem:GetCharList(self.nodeId)
    local charList = {}
    for i = 1, characterList.Count do
        table.insert(charList, characterList[CSIndex(i)])
    end
    self.view.charNode:InitFacCharNode(self.nodeId, charList)
end
FacBackground._OnToggleBuildingPower = HL.Method(HL.Boolean) << function(self, isOn)
    GameInstance.player.remoteFactory.core:Message_OpEnableNode(Utils.getCurrentChapterId(), self.nodeId, isOn)
end
FacBackground.HideToggle = HL.Method() << function(self)
    self.view.powerToggle.gameObject:SetActiveIfNecessary(false)
end
FacBackground.HideDeleteButton = HL.Method() << function(self)
    self.view.delButton.gameObject:SetActiveIfNecessary(false)
end
FacBackground.HideLevel = HL.Method() << function(self)
    self.view.lvNode.gameObject:SetActiveIfNecessary(false)
end
FacBackground.SetStopState = HL.Method() << function(self)
    self:_UpdateStateInfo(GEnums.FacBuildingState.Closed)
end
FacBackground.SetNormalState = HL.Method() << function(self)
    self:_UpdateStateInfo(GEnums.FacBuildingState.Normal)
end
FacBackground.SetBlockedState = HL.Method() << function(self)
    self:_UpdateStateInfo(GEnums.FacBuildingState.Blocked)
end
FacBackground.SetIdleState = HL.Method() << function(self)
    self:_UpdateStateInfo(GEnums.FacBuildingState.Idle)
end
FacBackground._UpdateStateInfo = HL.Method(HL.Number) << function(self, state)
    local stateNode = self.view.stateNode
    local isBlock, isNoPower, isNormal, isStopped, isNotLinked, isIdle = false, false, false, false, false, false
    if state == GEnums.FacBuildingState.Closed then
        isStopped = true
    elseif state == GEnums.FacBuildingState.Blocked then
        isBlock = true
    elseif state == GEnums.FacBuildingState.NoPower then
        isNoPower = true
    elseif state == GEnums.FacBuildingState.NotInPowerNet then
        isNotLinked = true
    elseif state == GEnums.FacBuildingState.Idle then
        isIdle = true
    else
        isNormal = true
    end
    stateNode.stopped.gameObject:SetActiveIfNecessary(isStopped)
    stateNode.normal.gameObject:SetActiveIfNecessary(isNormal)
    stateNode.powerNotEnough.gameObject:SetActiveIfNecessary(isNoPower)
    stateNode.notLinked.gameObject:SetActiveIfNecessary(isNotLinked)
    stateNode.block.gameObject:SetActiveIfNecessary(isBlock)
    stateNode.idle.gameObject:SetActiveIfNecessary(isIdle)
end
FacBackground.OnCharModify = HL.Method() << function(self)
    self:_RefreshCharSet()
end
FacBackground.OnSkillBroadModify = HL.Method() << function(self)
    self.view.facCharacterBonusNode:InitFacCharacterBonusNode(self.nodeId)
end
HL.Commit(FacBackground)
return FacBackground