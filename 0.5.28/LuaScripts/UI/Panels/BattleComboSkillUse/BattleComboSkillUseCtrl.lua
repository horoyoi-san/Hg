local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.BattleComboSkillUse
BattleComboSkillUseCtrl = HL.Class('BattleComboSkillUseCtrl', uiCtrl.UICtrl)
BattleComboSkillUseCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_COMBO_SKILL_START] = 'OnComboSkillStart', }
local COMBO_USE_STATE_NONE = 1
local COMBO_USE_STATE_IN = 2
local COMBO_USE_STATE_OUT = 3
do
    BattleComboSkillUseCtrl.m_comboSkillUseList = HL.Field(HL.Table)
    BattleComboSkillUseCtrl.m_useBgShowing = HL.Field(HL.Boolean) << false
end
BattleComboSkillUseCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_comboSkillUseList = {}
    for i = 1, Const.BATTLE_SQUAD_MAX_CHAR_NUM do
        local use = self.view['comboSkillUse' .. i]
        use.gameObject:SetActive(false)
        use.state = COMBO_USE_STATE_NONE
        self.m_comboSkillUseList[i] = use
    end
end
BattleComboSkillUseCtrl.OnShow = HL.Override() << function(self)
    self.view.useBgAnim:SampleToOutAnimationEnd()
    self.m_useBgShowing = false
end
BattleComboSkillUseCtrl.OnHide = HL.Override() << function(self)
    for i, useObj in ipairs(self.m_comboSkillUseList) do
        if useObj.state ~= COMBO_USE_STATE_NONE then
            useObj.anim:ClearTween()
            useObj.gameObject:SetActive(false)
            useObj.state = COMBO_USE_STATE_NONE
        end
    end
    self:_CheckUseState()
end
BattleComboSkillUseCtrl.OnComboSkillStart = HL.Method(HL.Table) << function(self, args)
    local charIndex = LuaIndex(unpack(args))
    local findIndex = -1
    for i, useObj in ipairs(self.m_comboSkillUseList) do
        if useObj.state == COMBO_USE_STATE_NONE or useObj.charIndex == charIndex then
            useObj.anim:ClearTween()
            findIndex = i
            useObj.gameObject:SetActive(true)
            local abilityCom = GameInstance.player.squadManager:GetMemberBySlot(CSIndex(charIndex)):Lock().abilityCom
            local data = abilityCom.data.skillDataBundle
            useObj.charIndex = charIndex
            useObj.charIcon.sprite = self:LoadSprite("ComboSkillUI", data.comboSkillUIBigSpriteName)
            useObj.state = COMBO_USE_STATE_IN
            useObj.anim:PlayInAnimation(function()
                if self:IsHide() then
                    return
                end
                useObj.state = COMBO_USE_STATE_OUT
                useObj.anim:PlayOutAnimation(function()
                    useObj.gameObject:SetActive(false)
                    useObj.state = COMBO_USE_STATE_NONE
                    self:_CheckUseState()
                end)
                self:_CheckUseState()
            end)
            self:_CheckUseState()
            break
        end
    end
    if findIndex > 0 then
        for i, useObj in ipairs(self.m_comboSkillUseList) do
            if i ~= findIndex and useObj.state == COMBO_USE_STATE_IN then
                useObj.state = COMBO_USE_STATE_OUT
                useObj.anim:PlayOutAnimation(function()
                    useObj.gameObject:SetActive(false)
                end)
                useObj.gameObject:SetActive(true)
            end
        end
    end
end
BattleComboSkillUseCtrl._CheckUseState = HL.Method() << function(self)
    local hasIn = false
    local hasOut = false
    for i, useObj in ipairs(self.m_comboSkillUseList) do
        if useObj.state == COMBO_USE_STATE_IN then
            hasIn = true
            useObj.gameObject:SetActive(true)
        elseif useObj.state == COMBO_USE_STATE_OUT then
            hasOut = true
            useObj.gameObject:SetActive(true)
        end
    end
    if hasIn then
        if self.m_useBgShowing then
            self.view.useBgAnim:SampleToInAnimationEnd()
        else
            self.m_useBgShowing = true
            self.view.useBgAnim:PlayWithTween("combo_skill_bg_in")
        end
    elseif hasOut then
        self.view.useBgAnim:PlayWithTween("combo_skill_bg_out")
        self.m_useBgShowing = false
    else
        self.view.useBgAnim:SampleToOutAnimationEnd()
        self.m_useBgShowing = false
    end
end
HL.Commit(BattleComboSkillUseCtrl)