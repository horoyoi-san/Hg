local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GenderSelectController
local FIRST_IN_ANIM_DELAY = 1
GenderSelectControllerCtrl = HL.Class('GenderSelectControllerCtrl', uiCtrl.UICtrl)
GenderSelectControllerCtrl.s_messages = HL.StaticField(HL.Table) << {}
GenderSelectControllerCtrl.m_hasInited = HL.Field(HL.Boolean) << false
GenderSelectControllerCtrl.m_animTimer = HL.Field(HL.Number) << 0
GenderSelectControllerCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:_InitActionEvent()
end
GenderSelectControllerCtrl._InitActionEvent = HL.Method() << function(self)
    self.view.btnFemale.onClick:AddListener(function()
        self.m_phase:ChooseFemale()
    end)
    self.view.btnFemale.onHoverChange:AddListener(function(isHover)
        self:Notify(MessageConst.ON_GENDER_HOVER_CHANGE, { false, isHover })
    end)
    self.view.btnMale.onClick:AddListener(function()
        self.m_phase:ChooseMale()
    end)
    self.view.btnMale.onHoverChange:AddListener(function(isHover)
        self:Notify(MessageConst.ON_GENDER_HOVER_CHANGE, { true, isHover })
    end)
end
GenderSelectControllerCtrl._DoPlayInAnim = HL.Method() << function(self)
    if self.m_animTimer > 0 then
        self:_ClearTimer(self.m_animTimer)
        self.m_animTimer = 0
    end
    if self.m_hasInited then
        self:PlayAnimationIn()
    else
        local wrapper = self:GetAnimationWrapper()
        wrapper:SampleClipAtPercent("genderselectcontroller_in", 0)
        self.m_animTimer = self:_StartTimer(FIRST_IN_ANIM_DELAY, function()
            self:PlayAnimationIn()
            self:_ClearTimer(self.m_animTimer)
            self.m_animTimer = 0
        end)
    end
end
GenderSelectControllerCtrl.OnShow = HL.Override() << function(self)
    self:_DoPlayInAnim()
    self:Notify(MessageConst.ON_GENDER_HOVER_ANIM, { true, not self.m_hasInited })
    self.m_hasInited = true
end
GenderSelectControllerCtrl.OnHide = HL.Override() << function(self)
    self:Notify(MessageConst.ON_GENDER_HOVER_ANIM, { false, false })
end
HL.Commit(GenderSelectControllerCtrl)