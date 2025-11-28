local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacMedicalTowerNew
FacMedicalTowerNewCtrl = HL.Class('FacMedicalTowerNewCtrl', uiCtrl.UICtrl)
FacMedicalTowerNewCtrl.m_nodeId = HL.Field(HL.Any)
FacMedicalTowerNewCtrl.m_uiInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.BuildingUIInfo_HealTower)
FacMedicalTowerNewCtrl.s_messages = HL.StaticField(HL.Table) << {}
FacMedicalTowerNewCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_uiInfo = arg.uiInfo
    local nodeId = self.m_uiInfo.nodeId
    self.m_nodeId = nodeId
    self.view.buildingCommon:InitBuildingCommon(self.m_uiInfo)
    self:_UpdateStateInfo()
    self:_StartCoroutine(function()
        while true do
            coroutine.step()
            self:_UpdateStateInfo()
        end
    end)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
FacMedicalTowerNewCtrl._UpdateStateInfo = HL.Method() << function(self)
    local buildingId = self.m_uiInfo.buildingId
    local state = FactoryUtils.getBuildingStateType(self.m_nodeId)
    local isNormal = (state == GEnums.FacBuildingState.Normal)
    local cfg = Tables.factoryMedicTable:GetValue(buildingId)
    if cfg == nil then
        return
    end
    local chargeTick = cfg.energyChargeTicks
    local maxEnergy = cfg.maxEnergy
    local currentPoint = self.m_uiInfo.healTower.currentPoint
    local curProg = self.m_uiInfo.healTower.currentProgress
    local curProgPerMs = self.m_uiInfo.healTower.progressIncreasePerMS
    self.view.statusValTxt.text = string.format("%d/%d", currentPoint, maxEnergy)
    self.view.fill.fillAmount = currentPoint / maxEnergy
    local time = 0
    if currentPoint < maxEnergy and isNormal and curProgPerMs ~= 0 then
        time = ((maxEnergy - currentPoint - 1) * chargeTick) / FacLogicFrameRate
        time = time - ((curProg / curProgPerMs) / 1000)
        if (time < 0) then
            time = 0
        end
    end
    self.view.runTxt.gameObject:SetActiveIfNecessary(isNormal)
    self.view.stopTxt.gameObject:SetActiveIfNecessary(not isNormal)
    self.view.cdText.text = string.format(UIUtils.getRemainingText(time))
    if isNormal then
        self.view.fill.color = Color(0.75, 0.82, 0.18, 1)
        self.view.statusValTxt.color = Color(0.75, 0.82, 0.18, 1)
    else
        self.view.fill.color = Color(0.92, 0.27, 0.08, 1)
        self.view.statusValTxt.color = Color(0.92, 0.27, 0.08, 1)
    end
end
HL.Commit(FacMedicalTowerNewCtrl)