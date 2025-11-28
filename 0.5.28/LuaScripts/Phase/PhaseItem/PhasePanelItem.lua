local phaseItemBase = require_ex('Phase/Core/PhaseItemBase')
PhasePanelItem = HL.Class("PhasePanelItem", phaseItemBase.PhaseItemBase)
PhasePanelItem.uiCtrl = HL.Field(HL.Forward("UICtrl"))
PhasePanelItem._OnInit = HL.Override() << function(self)
    self.uiCtrl = nil
end
PhasePanelItem.OnPhaseRefresh = HL.Override(HL.Opt(HL.Any)) << function(self, arg)
    self.uiCtrl:OnPhaseRefresh(arg)
end
PhasePanelItem.BindUICtrl = HL.Method(HL.Any) << function(self, uiCtrl)
    self.uiCtrl = uiCtrl
    self.uiCtrl:SetPhaseItem(self)
    for msg, funcName in pairs(HL.GetType(self.uiCtrl).s_messages) do
        if MessageConst.isPhaseMsg(msg) then
            self:Register(msg, function(msgArg)
                if self.uiCtrl and self.uiCtrl[funcName] then
                    self.uiCtrl[funcName](self.uiCtrl, msgArg)
                end
            end)
        end
    end
end
PhasePanelItem._DoTransitionInCoroutine = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
end
PhasePanelItem._DoTransitionOutCoroutine = HL.Override(HL.Boolean, HL.Opt(HL.Table)) << function(self, fastMode, args)
    if not self.uiCtrl or fastMode or UIUtils.usingBlockTransition() then
        return
    end
    if UIManager:IsHide(self.uiCtrl.panelId) then
        return
    end
    self.uiCtrl:PlayAnimationOut()
end
PhasePanelItem._CheckAllTransitionDone = HL.Override().Return(HL.Boolean) << function(self)
    if self.uiCtrl then
        if IsNull(self.uiCtrl.view.gameObject) then
            return true
        end
        if UIManager:IsHide(self.uiCtrl.panelId) then
            return true
        end
        local wrapper = self.uiCtrl:GetAnimationWrapper()
        if wrapper then
            return (wrapper.curState ~= CS.Beyond.UI.UIConst.AnimationState.Out and wrapper.curState ~= CS.Beyond.UI.UIConst.AnimationState.In)
        else
            return true
        end
    else
        return false
    end
end
PhasePanelItem._OnDestroy = HL.Override() << function(self)
    if self.uiCtrl then
        self.uiCtrl:Close()
        self.uiCtrl = nil
    end
end
HL.Commit(PhasePanelItem)