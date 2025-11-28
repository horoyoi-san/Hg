local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacPowerPole
FacPowerPoleCtrl = HL.Class('FacPowerPoleCtrl', uiCtrl.UICtrl)
FacPowerPoleCtrl.s_messages = HL.StaticField(HL.Table) << {}
FacPowerPoleCtrl.m_nodeId = HL.Field(HL.Any)
FacPowerPoleCtrl.m_uiInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.BuildingUIInfo_PowerPole)
FacPowerPoleCtrl.m_powerInfo = HL.Field(HL.Userdata)
FacPowerPoleCtrl.m_driverInfos = HL.Field(HL.Table)
FacPowerPoleCtrl.m_getMachineCell = HL.Field(HL.Function)
FacPowerPoleCtrl.m_curItemIndex = HL.Field(HL.Number) << 1
FacPowerPoleCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_uiInfo = arg.uiInfo
    local nodeId = self.m_uiInfo.nodeId
    self.m_nodeId = nodeId
    self.view.buildingCommon:InitBuildingCommon(self.m_uiInfo, {
        onPowerChanged = function()
            self:_RefreshLinkedInfo()
        end
    })
    self.view.buildingCommon.view.powerToggle.gameObject:SetActiveIfNecessary(false)
    self:_InitPowerInfo()
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.FAC_COMMON_UI_UPDATE_INTERVAL)
            self:_RefreshPowerInfo()
        end
    end)
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
    self:_RefreshLinkedInfo()
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
    InputManagerInst:MoveVirtualMouseTo(self.view.machineCell.transform, self.uiCamera)
end
FacPowerPoleCtrl._RefreshLinkedInfo = HL.Method() << function(self)
    local node = self.m_uiInfo.nodeHandler
    local linkedNodes = CS.Beyond.Gameplay.RemoteFactory.RemoteFactoryUtil.GetAllConnectedNodes(node)
    local infos = {}
    local nodeCount = 0
    for _, linkNode in pairs(linkedNodes) do
        local linkNodeEntry
        for _, v in pairs(infos) do
            if v.templateId == linkNode.templateId then
                linkNodeEntry = v
                break
            end
        end
        if not linkNodeEntry then
            linkNodeEntry = { templateId = linkNode.templateId, nodeCount = 0 }
            table.insert(infos, linkNodeEntry)
        end
        linkNodeEntry.nodeCount = linkNodeEntry.nodeCount + 1
    end
    local nodeCount = #infos
    self.m_driverInfos = infos
    self.view.emptyInfo.gameObject:SetActive(nodeCount <= 0)
    self.view.machineScrollList:UpdateCount(nodeCount)
end
FacPowerPoleCtrl._InitPowerInfo = HL.Method() << function(self)
    self.m_powerInfo = FactoryUtils.getCurRegionPowerInfo()
    local powerStorageCapacity = self.m_powerInfo.powerSaveMax
    self.view.maxRestPowerText.text = string.format("/%s", UIUtils.getNumString(powerStorageCapacity))
    self:_RefreshPowerInfo()
end
FacPowerPoleCtrl._RefreshPowerInfo = HL.Method() << function(self)
    local powerInfo = self.m_powerInfo
    self.view.providePowerText.text = string.format("/%s", UIUtils.getNumString(powerInfo.powerGen))
    self.view.currentPowerText.text = UIUtils.getNumString(powerInfo.powerCost)
    local restPower = powerInfo.powerSaveCurrent
    self.view.restPowerText.text = UIUtils.getNumString(restPower)
end
FacPowerPoleCtrl._OnUpdateCell = HL.Method(HL.Userdata, HL.Number) << function(self, object, index)
    local cell = self.m_getMachineCell(object)
    local info = self.m_driverInfos[index]
    local data = Tables.factoryBuildingTable:GetValue(info.templateId)
    local isOdd = index % 2 > 0
    cell.name.text = data.name
    cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_BUILDING_PANEL_ICON, data.iconOnPanel)
    cell.bgOdd.gameObject:SetActive(isOdd)
    cell.bgEven.gameObject:SetActive(not isOdd)
    cell.btnController.clickHintTextId = "virtual_mouse_fac_power_pole_switch"
    self:_RefreshDriverPower(cell, info)
end
FacPowerPoleCtrl._RefreshDriverPower = HL.Method(HL.Table, HL.Table) << function(self, cell, info)
    cell.power.text = tostring(info.nodeCount)
end
FacPowerPoleCtrl._OnToggleMachine = HL.Method(HL.Table, HL.Table, HL.Boolean) << function(self, cell, info, isOn)
    GameInstance.player.remoteFactory.core:Message_OpEnableNode(Utils.getCurrentChapterId(), info.nodeId, isOn, function()
        self:_RefreshDriverPower(cell, info)
    end)
end
HL.Commit(FacPowerPoleCtrl)