local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.BattleComboSkill
BattleComboSkillCtrl = HL.Class('BattleComboSkillCtrl', uiCtrl.UICtrl)
BattleComboSkillCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_COMBO_SKILL_READY] = 'OnAtbSkillReady', [MessageConst.ON_COMBO_SKILL_REMOVE] = 'OnAtbSkillRemove', }
do
    BattleComboSkillCtrl.m_hintList = HL.Field(HL.Table)
    BattleComboSkillCtrl.m_charIndexList = HL.Field(HL.Table)
    BattleComboSkillCtrl.m_updateKey = HL.Field(HL.Number) << -1
end
BattleComboSkillCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_hintList = {}
    for i = 1, Const.BATTLE_SQUAD_MAX_CHAR_NUM do
        local hint = self.view['comboSkillHint' .. i]
        hint.gameObject:SetActive(false)
        self.m_hintList[i] = hint
    end
    self.view.buttonCast.onPressStart:AddListener(function()
        self:_CastComboSkill()
    end)
    self.m_charIndexList = {}
    self:_CheckUpdate()
end
BattleComboSkillCtrl.OnClose = HL.Override() << function(self)
    self:_ClearUpdate()
end
BattleComboSkillCtrl._Update = HL.Method(HL.Number) << function(self, deltaTime)
    for i, charIndex in ipairs(self.m_charIndexList) do
        local hint = self.m_hintList[charIndex]
        local available, remainTime, canCast = GameInstance.world.battle:GetRemainComboSkillPendingTime(CSIndex(charIndex))
        if available then
            hint.fill.fillAmount = remainTime / DataManager.skillSetting.comboSkillPendingInterval
            if canCast then
                hint.content.alpha = 1
            else
                hint.content.alpha = 0.5
            end
        end
    end
end
BattleComboSkillCtrl._CheckUpdate = HL.Method() << function(self)
    local needUpdate = (#self.m_charIndexList > 0)
    self.view.buttonCast.gameObject:SetActive(needUpdate)
    if not needUpdate then
        self:_ClearUpdate()
        return
    end
    if self.m_updateKey < 0 then
        self.m_updateKey = LuaUpdate:Add("Tick", function(deltaTime)
            self:_Update(deltaTime)
        end)
        self:_Update(0)
    end
end
BattleComboSkillCtrl._ClearUpdate = HL.Method() << function(self)
    if self.m_updateKey > 0 then
        LuaUpdate:Remove(self.m_updateKey)
        self.m_updateKey = -1
    end
end
BattleComboSkillCtrl.OnAtbSkillReady = HL.Method(HL.Table) << function(self, args)
    local charIndex = LuaIndex(unpack(args))
    local index = -1
    for i = 1, #self.m_charIndexList do
        if self.m_charIndexList[i] == charIndex then
            index = i
            break
        end
    end
    local hint = self.m_hintList[charIndex]
    if index ~= -1 then
        self:_SetData(hint, charIndex)
    else
        table.insert(self.m_charIndexList, charIndex)
    end
    self:_SetData(hint, charIndex)
    hint.anim:ClearTween()
    hint.gameObject:SetActive(true)
    hint.anim:SampleClip("combo_skill_ui_end", 0.0, true)
    hint.anim:PlayWithTween("combo_skill_ui_start")
    self:_CheckUpdate()
    self:_ResortSiblingIndex()
end
BattleComboSkillCtrl.OnAtbSkillRemove = HL.Method(HL.Table) << function(self, args)
    local charIndex = LuaIndex(unpack(args))
    local index = -1
    for i, _ in ipairs(self.m_charIndexList) do
        if self.m_charIndexList[i] == charIndex then
            index = i
            break
        end
    end
    if index < 0 then
        return
    end
    table.remove(self.m_charIndexList, index)
    self.m_hintList[charIndex].anim:PlayWithTween("combo_skill_ui_end", function()
        self.m_hintList[charIndex].gameObject:SetActive(false)
        self:_ResortSiblingIndex()
    end)
    self:_CheckUpdate()
end
BattleComboSkillCtrl._CastComboSkill = HL.Method() << function(self)
    if #self.m_charIndexList == 0 then
        return
    end
    local charIndex = self.m_charIndexList[1]
    local available, remainTime, canCast = GameInstance.world.battle:GetRemainComboSkillPendingTime(CSIndex(charIndex))
    if available and canCast then
        GameInstance.world.battle:CastPendingComboSkill(CSIndex(charIndex))
        table.remove(self.m_charIndexList, 1)
        self.m_hintList[charIndex].anim:PlayWithTween("combo_skill_ui_use", function()
            self.m_hintList[charIndex].gameObject:SetActive(false)
            self:_ResortSiblingIndex()
        end)
        self:_CheckUpdate()
    else
        Notify(MessageConst.SHOW_TOAST, Language.LUA_BATTLE_SKILL_COMBO_CAST_FAILED)
    end
end
BattleComboSkillCtrl._SetData = HL.Method(HL.Table, HL.Number) << function(self, hintItem, charIndex)
    local abilityCom = GameInstance.player.squadManager:GetMemberBySlot(CSIndex(charIndex)):Lock().abilityCom
    local data = abilityCom.data.skillDataBundle
    hintItem.charHead.sprite = self:LoadSprite(UIConst.UI_SPRITE_ROUND_CHAR_HEAD, data.comboSkillUISpriteName)
    local comboSkill = abilityCom.activeSkillMap:get_Item(abilityCom.data.skillDataBundle.comboSkillId)
    local comboSkillData = comboSkill.data
    hintItem.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_SKILL_ICON, comboSkillData.iconId)
end
BattleComboSkillCtrl._ResortSiblingIndex = HL.Method() << function(self)
    if #self.m_charIndexList == 0 then
        return
    end
    for i, charIndex in ipairs(self.m_charIndexList) do
        local hint = self.m_hintList[charIndex]
        hint.transform:SetSiblingIndex(CSIndex(i) + 1)
        if i == 1 then
            hint.content.transform.localScale = Vector3.one * self.view.config.COMBO_HINT_FIRST_SCALE
        else
            hint.content.transform.localScale = Vector3.one
        end
    end
end
HL.Commit(BattleComboSkillCtrl)