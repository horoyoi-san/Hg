local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacPowerDiffuser
FacPowerDiffuserCtrl = HL.Class('FacPowerDiffuserCtrl', uiCtrl.UICtrl)
local FAC_NOT_SHOW_TEMPLATE_ID_MINER = "miner_1"
FacPowerDiffuserCtrl.s_messages = HL.StaticField(HL.Table) << {}
FacPowerDiffuserCtrl.m_nodeId = HL.Field(HL.Any)
FacPowerDiffuserCtrl.m_uiInfo = HL.Field(HL.Userdata)
FacPowerDiffuserCtrl.m_powerInfo = HL.Field(HL.Userdata)
FacPowerDiffuserCtrl.m_driverInfos = HL.Field(HL.Table)
FacPowerDiffuserCtrl.m_getMachineCell = HL.Field(HL.Function)
FacPowerDiffuserCtrl.m_curItemIndex = HL.Field(HL.Number) << 1
FacPowerDiffuserCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_uiInfo = arg.uiInfo
    local nodeId = self.m_uiInfo.nodeId
    self.m_nodeId = nodeId
    self.view.buildingCommon:InitBuildingCommon(self.m_uiInfo, {
        onPowerChanged = function()
            self:_Refresh()
        end
    })
    self.view.buildingCommon.view.powerToggle.gameObject:SetActiveIfNecessary(false)
    self:_InitPowerInfo()
    self.m_getMachineCell = UIUtils.genCachedCellFunction(self.view.machineScrollList, function(object)
        return Utils.wrapLuaNode(object)
    end)
    self.view.machineScrollList.onUpdateCell:AddListener(function(object, csIndex)
        self:_OnUpdateCell(object, LuaIndex(csIndex))
    end)
    self.view.machineScrollList.onSelectedCell:AddListener(function(obj, csIndex)
        self.m_curItemIndex = LuaIndex(csIndex)
    end)
    self.view.machineScrollList.getCurSelectedIndex = function()
        return CSIndex(self.m_curItemIndex)
    end
    self:_Refresh()
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.FAC_COMMON_UI_UPDATE_INTERVAL)
            self:_RefreshPowerInfo()
            self:_RefreshAllDriversPower()
        end
    end)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
    InputManagerInst:MoveVirtualMouseTo(self.view.machineCell.transform, self.uiCamera)
end
FacPowerDiffuserCtrl._Refresh = HL.Method() << function(self)
    local infos = {}
    local linkedNodes = self.m_uiInfo.powerPole.coveredNodeIds
    local nodeCount = 0
    for _, nodeId in pairs(linkedNodes) do
        local nodeHandler = FactoryUtils.getBuildingNodeHandler(nodeId)
        local success, buildingData = Tables.factoryBuildingTable:TryGetValue(nodeHandler.templateId)
        if nodeHandler ~= nil and success then
            if not FacConst.NOT_SHOW_IN_POWER_POLE_FC_NODE_TYPES[nodeHandler.nodeType] and nodeHandler.templateId ~= FAC_NOT_SHOW_TEMPLATE_ID_MINER and buildingData.needPower then
                table.insert(infos, { nodeId = nodeId, nodeHandler = nodeHandler, })
                nodeCount = nodeCount + 1
            end
        end
    end
    self.m_driverInfos = infos
    self.view.emptyInfo.gameObject:SetActive(nodeCount <= 0)
    self.view.machineScrollList:UpdateCount(nodeCount)
end
FacPowerDiffuserCtrl._InitPowerInfo = HL.Method() << function(self)
    self.m_powerInfo = FactoryUtils.getCurRegionPowerInfo()
    local powerStorageCapacity = self.m_powerInfo.powerSaveMax
    self.view.maxRestPowerText.text = string.format("/%s", UIUtils.getNumString(powerStorageCapacity))
    self:_RefreshPowerInfo()
end
FacPowerDiffuserCtrl._RefreshPowerInfo = HL.Method() << function(self)
    local powerInfo = self.m_powerInfo
    self.view.providePowerText.text = string.format("/%s", UIUtils.getNumString(powerInfo.powerGen))
    self.view.currentPowerText.text = UIUtils.getNumString(powerInfo.powerCost)
    local restPower = powerInfo.powerSaveCurrent
    self.view.restPowerText.text = UIUtils.getNumString(restPower)
end
FacPowerDiffuserCtrl._OnUpdateCell = HL.Method(HL.Userdata, HL.Number) << function(self, object, index)
    local cell = self.m_getMachineCell(object)
    local info = self.m_driverInfos[index]
    local nodeMsg = info.nodeHandler
    local data = Tables.factoryBuildingTable:GetValue(nodeMsg.templateId)
    cell.name.text = data.name
    cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_BUILDING_PANEL_ICON, data.iconOnPanel)
    cell.toggle:InitCommonToggle(function(isOn)
        self:_OnToggleMachine(cell, info, isOn)
        self:_RefreshMachineCellToggleState(cell)
    end, not nodeMsg.isDeactive, true)
    cell.bgBtn.onClick:RemoveAllListeners()
    cell.bgBtn.onClick:AddListener(function()
        cell.toggle:Toggle()
        self:_RefreshMachineCellToggleState(cell)
    end)
    cell.bgBtn.clickHintTextId = "virtual_mouse_fac_power_pole_switch"
    self:_RefreshMachineCellToggleState(cell)
    self:_RefreshDriverPower(cell, info)
end
FacPowerDiffuserCtrl._RefreshMachineCellToggleState = HL.Method(HL.Any) << function(self, cell)
    if cell == nil then
        return
    end
    local isOn = cell.toggle.toggle.isOn
    cell.bgOff.gameObject:SetActiveIfNecessary(not isOn)
    cell.machineInfoNode.color = isOn and self.view.config.COLOR_MACHINE_OPENED or self.view.config.COLOR_MACHINE_CLOSED
end
FacPowerDiffuserCtrl._RefreshAllDriversPower = HL.Method() << function(self)
    for index = 1, self.view.machineScrollList.count do
        local cell = self.m_getMachineCell(index)
        local info = self.m_driverInfos[index]
        if cell ~= nil and info ~= nil then
            self:_RefreshDriverPower(cell, info)
        end
    end
end
FacPowerDiffuserCtrl._RefreshDriverPower = HL.Method(HL.Table, HL.Table) << function(self, cell, info)
    cell.power.text = FactoryUtils.getCurBuildingConsumePower(info.nodeId)
    cell.stateIcon.sprite = self:LoadSprite(FactoryUtils.getBuildingStateIconName(info.nodeId))
end
FacPowerDiffuserCtrl._OnToggleMachine = HL.Method(HL.Table, HL.Table, HL.Boolean) << function(self, cell, info, isOn)
    GameInstance.player.remoteFactory.core:Message_OpEnableNode(Utils.getCurrentChapterId(), info.nodeId, isOn)
end
HL.Commit(FacPowerDiffuserCtrl)