local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
local BLACKBOX_SELECT_IN_ANIM = "blackboxselection_in"
local BLACKBOX_SELECT_OUT_ANIM = "blackboxselection_out"
BlackboxSelectionCell = HL.Class('BlackboxSelectionCell', UIWidgetBase)
BlackboxSelectionCell._OnFirstTimeInit = HL.Override() << function(self)
end
BlackboxSelectionCell.InitBlackboxSelectionCell = HL.Method(HL.Table, HL.Function, HL.Boolean) << function(self, info, onClickFunc, preDependenciesRedDot)
    self:_FirstTimeInit()
    self.view.nameTxtS.text = info.name
    self.view.nameTxtN.text = info.name
    if info.isComplete then
        self.view.leftIconCtrl:SetState("complete")
    elseif info.isActive and not info.isUnlock then
        self.view.leftIconCtrl:SetState("lock")
    else
        self.view.leftIconCtrl:SetState("normal")
    end
    if info.isActive then
        self.view.rightIconCtrl:SetState("active")
    else
        self.view.rightIconCtrl:SetState("inactive")
    end
    self.view.button.onClick:RemoveAllListeners()
    self.view.button.onClick:AddListener(function()
        if onClickFunc then
            onClickFunc()
        end
    end)
    if preDependenciesRedDot then
        self.view.redDot:InitRedDot("BlackboxSelectionCellPassed", info.blackboxId)
    else
        self.view.redDot:InitRedDot("BlackboxSelectionCellRead", info.blackboxId)
    end
end
BlackboxSelectionCell.SetSelected = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, selected, ignoreEffect)
    if ignoreEffect == true then
        self.view.selected.gameObject:SetActiveIfNecessary(selected)
        self.view.normal.gameObject:SetActiveIfNecessary(not selected)
        local anim = selected and BLACKBOX_SELECT_IN_ANIM or BLACKBOX_SELECT_OUT_ANIM
        self.view.animationWrapper:SampleClipAtPercent(anim, 1)
    else
        if selected then
            self.view.animationWrapper:Play(BLACKBOX_SELECT_IN_ANIM)
        else
            self.view.animationWrapper:Play(BLACKBOX_SELECT_OUT_ANIM)
        end
    end
end
HL.Commit(BlackboxSelectionCell)
return BlackboxSelectionCell