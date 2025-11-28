local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacMainLeft
FacMainLeftCtrl = HL.Class('FacMainLeftCtrl', uiCtrl.UICtrl)
FacMainLeftCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_TOGGLE_FAC_TOP_VIEW] = 'OnToggleFacTopView', [MessageConst.FAC_SWITCH_BUILDING_TARGET_DISPLAY_MODE] = 'OnSwitchBuildingTargetDisplayMode', [MessageConst.ON_IN_FAC_MAIN_REGION_CHANGE] = 'OnInFacMainRegionChange', [MessageConst.ON_SYSTEM_UNLOCK] = 'OnSystemUnlock', }
FacMainLeftCtrl.showMachineTarget = HL.Field(HL.Boolean) << true
FacMainLeftCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.showMachineTarget = GameInstance.remoteFactoryManager:GetBuildingOutputVisible()
    self.view.buildingTargetToggle.isOn = self.showMachineTarget
    self.view.buildingTargetToggle.onValueChanged:AddListener(function(isOn)
        self:_ToggleMachineTarget(isOn)
    end)
    self.view.topViewToggle.isOn = LuaSystemManager.facSystem.inTopView
    self.view.topViewToggle.checkIsValueValid = function(isOn)
        return CSFactoryUtil.CanEnterTopView()
    end
    self.view.topViewToggle.onValueChanged:AddListener(function(isOn)
        Notify(MessageConst.FAC_TOGGLE_TOP_VIEW, isOn)
    end)
    self.view.topViewToggle.gameObject:SetActive(Utils.isSystemUnlocked(GEnums.UnlockSystemType.FacTransferPort))
end
FacMainLeftCtrl.OnSystemUnlock = HL.Method(HL.Any) << function(self, arg)
    local systemIndex = unpack(arg)
    if systemIndex == GEnums.UnlockSystemType.FacTransferPort:GetHashCode() then
        self.view.topViewToggle.gameObject.gameObject:SetActive(true)
    end
end
FacMainLeftCtrl._SwitchBuildingTargetToggle = HL.Method() << function(self)
    if not Utils.isInFacMainRegion() then
        return
    end
    self.view.buildingTargetToggle.isOn = not self.showMachineTarget
end
FacMainLeftCtrl._ToggleMachineTarget = HL.Method(HL.Boolean) << function(self, isOn)
    self.showMachineTarget = isOn
    GameInstance.remoteFactoryManager:SwitchBuildingOutputVisible(self.showMachineTarget)
    local toastTextId = self.showMachineTarget and "LUA_BUILDING_TARGET_ICON_SHOW_TOAST" or "LUA_BUILDING_TARGET_ICON_HIDE_TOAST"
    Notify(MessageConst.SHOW_TOAST, Language[toastTextId])
end
FacMainLeftCtrl.OnShow = HL.Override() << function(self)
    self.view.leftBottomNode.gameObject:SetActive(Utils.isInFacMainRegion())
end
FacMainLeftCtrl.OnSwitchBuildingTargetDisplayMode = HL.Method() << function(self)
    self:_SwitchBuildingTargetToggle()
end
FacMainLeftCtrl.OnToggleFacTopView = HL.Method(HL.Boolean) << function(self, active)
    self.view.topViewToggle:SetIsOnWithoutNotify(active)
end
FacMainLeftCtrl.OnInFacMainRegionChange = HL.Method(HL.Boolean) << function(self, inFacMain)
    self.view.leftBottomNode.gameObject:SetActive(inFacMain)
end
HL.Commit(FacMainLeftCtrl)