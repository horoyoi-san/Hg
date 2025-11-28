local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ControllerNaviTarget
ControllerNaviTargetCtrl = HL.Class('ControllerNaviTargetCtrl', uiCtrl.UICtrl)
ControllerNaviTargetCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_CONTROLLER_NAVI_TARGET_CHANGED] = 'OnControllerNaviTargetChanged', [MessageConst.ON_PANEL_ORDER_RECALCULATED] = 'OnPanelOrderRecalculated', }
ControllerNaviTargetCtrl.m_lateTickKey = HL.Field(HL.Number) << -1
ControllerNaviTargetCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.hintArrow.gameObject:SetActive(true)
end
ControllerNaviTargetCtrl.OnShow = HL.Override() << function(self)
    self:StartTick()
end
ControllerNaviTargetCtrl.OnHide = HL.Override() << function(self)
    self:StopTick()
end
ControllerNaviTargetCtrl.OnClose = HL.Override() << function(self)
    self:StopTick()
end
ControllerNaviTargetCtrl.OnInputDeviceTypeChanged = HL.StaticMethod() << function()
    if DeviceInfo.usingController then
        UIManager:AutoOpen(PANEL_ID)
    else
        UIManager:Hide(PANEL_ID)
    end
end
ControllerNaviTargetCtrl.StartTick = HL.Method() << function(self)
    self.m_lateTickKey = LuaUpdate:Add("LateTick", function(deltaTime)
        self:_SyncHintArrow()
    end)
end
ControllerNaviTargetCtrl.StopTick = HL.Method() << function(self)
    self.m_lateTickKey = LuaUpdate:Remove(self.m_lateTickKey)
end
ControllerNaviTargetCtrl.OnPanelOrderRecalculated = HL.Method() << function(self)
    self:_CalcCanvasOrder()
end
ControllerNaviTargetCtrl.OnControllerNaviTargetChanged = HL.Method() << function(self)
    self:_CalcCanvasOrder()
    self:_SyncHintArrow()
    if self.view.hintArrow.gameObject.activeInHierarchy then
        self.view.arrowAni:ClearTween()
        self.view.arrowAni:PlayInAnimation()
    end
end
ControllerNaviTargetCtrl._SyncHintArrow = HL.Method() << function(self)
    local hint = self.view.hintArrow
    if not DeviceInfo.usingController then
        hint.gameObject:SetActiveIfNecessary(false)
        return
    end
    local target = InputManagerInst.controllerNaviManager.curTarget
    local selfIsActive = hint.gameObject.activeInHierarchy
    if IsNull(target) then
        if selfIsActive then
            hint.gameObject:SetActive(false)
        end
        return
    end
    local active = target.gameObject.activeInHierarchy and InputManagerInst.controllerNaviManager:IsNavigationBindingEnabled()
    if selfIsActive ~= active then
        hint.gameObject:SetActive(active)
    end
    if not active then
        return
    end
    local targetScreenRect = UIUtils.getTransformScreenRect(target.transform, self.uiCamera)
    local canvasSize = self.view.transform.rect.size
    hint.anchoredPosition = Vector2(targetScreenRect.xMin / Screen.width * canvasSize.x, -targetScreenRect.yMin / Screen.height * canvasSize.y)
end
ControllerNaviTargetCtrl._CalcCanvasOrder = HL.Method() << function(self)
    local target = InputManagerInst.controllerNaviManager.curTarget
    if IsNull(target) then
        return
    end
    local canvas = target.transform:GetComponentInParent(typeof(Unity.Canvas), true)
    self:SetSortingOrder(canvas.sortingOrder + 1, false)
end
HL.Commit(ControllerNaviTargetCtrl)