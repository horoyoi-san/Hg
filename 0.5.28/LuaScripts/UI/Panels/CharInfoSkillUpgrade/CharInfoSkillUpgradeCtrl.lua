local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CharInfoSkillUpgrade
CharInfoSkillUpgradeCtrl = HL.Class('CharInfoSkillUpgradeCtrl', uiCtrl.UICtrl)
local stateEnum = { None = 0, SkillSingle = 1, SkillPlural = 2, Talent = 3, FacSkill = 4, }
local pluralNum = 2
CharInfoSkillUpgradeCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.P_CHAR_INFO_SELECT_CHAR_CHANGE] = 'OnSelectCharChange', [MessageConst.P_CHAR_INFO_SKILL_UPGRADE_SHOW_TALENT] = 'ShowTalent', [MessageConst.P_CHAR_INFO_SKILL_UPGRADE_SHOW_SKILL] = 'ShowSkill', [MessageConst.P_CHAR_INFO_SKILL_UPGRADE_SHOW_FAC_SKILL] = 'ShowFacSkill', }
CharInfoSkillUpgradeCtrl.m_charInfo = HL.Field(HL.Table)
CharInfoSkillUpgradeCtrl.m_charSkillLevelUp = HL.Field(HL.Table)
CharInfoSkillUpgradeCtrl.m_isToggle = HL.Field(HL.Boolean) << false
CharInfoSkillUpgradeCtrl.state = HL.Field(HL.Number) << 0
CharInfoSkillUpgradeCtrl.OnSelectCharChange = HL.Method(HL.Table) << function(self, charInfo)
    self.m_charInfo = charInfo
    if self:IsShow() then
        self:_Refresh()
    end
    self.m_charSkillLevelUp = CharInfoUtils.getCharSkillLevelData(self.m_charInfo.templateId)
end
CharInfoSkillUpgradeCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnBack.onClick:RemoveAllListeners()
    self.view.btnBack.onClick:AddListener(function()
        self:Notify(MessageConst.P_CHAR_INFO_SKILL_UPGRADE_CLOSE)
    end)
    self.view.emptyButton.onClick:RemoveAllListeners()
    self.view.emptyButton.onClick:AddListener(function()
        if self.view.btnClose.gameObject.activeSelf or self.view.btnOpen.gameObject.activeSelf then
            self:_RefreshToggle(false)
        end
    end)
    self.view.emptyButton.gameObject:SetActive(false)
    self.view.btnOpen.onClick:RemoveAllListeners()
    self.view.btnOpen.onClick:AddListener(function()
        self:_RefreshToggle(true)
    end)
    self.view.btnClose.onClick:RemoveAllListeners()
    self.view.btnClose.onClick:AddListener(function()
        self:_RefreshToggle(false)
    end)
    self.view.btnClose.customBindingViewLabelText = Language.key_hint_char_compare_disable
    local initCharInfo = arg.initCharInfo or CharInfoUtils.getLeaderCharInfo()
    self.m_charInfo = initCharInfo
    self.m_charSkillLevelUp = CharInfoUtils.getCharSkillLevelData(self.m_charInfo.templateId)
    self.view.walletBarPlaceholder:InitWalletBarPlaceholder(UIConst.INVENTORY_MONEY_IDS)
end
CharInfoSkillUpgradeCtrl.OnShow = HL.Override() << function(self)
    self:_Refresh()
    InputManagerInst:MoveVirtualMouseTo(self.view.transform, self.uiCamera, false)
    InputManagerInst:SetVirtualMouseIconVisible(true)
end
CharInfoSkillUpgradeCtrl._Refresh = HL.Method() << function(self)
    local characterTable = Tables.characterTable
    local charData = characterTable:GetValue(self.m_charInfo.templateId)
    self.view.textTitle.text = charData.name
end
CharInfoSkillUpgradeCtrl.ShowTalent = HL.Method(HL.Any) << function(self, data)
    self:_SetState(stateEnum.Talent)
    local talent, unlock = unpack(data)
    local talentData = talent.talentData
    local breakStage = talentData.breakStage
    local nextBreakStage = talent.nextBreakStage
    local maxBreakStage = CharInfoUtils.getTalentMaxBreakStage(self.m_charInfo.templateId, talentData.talentIndex)
    local talentNode = self.view.talentNode
    talentNode.textName.text = talentData.talentName
    talentNode.text.text = UIUtils.resolveTextStyle(talentData.description)
    talentNode.rank.text = "RANK " .. tostring(talentData.rank)
    if not unlock then
        local textNum = Language[string.format("LUA_NUM_%d", breakStage)]
        talentNode.textHint.text = string.format(Language.LUA_TALENT_UNLOCK_HINT, textNum)
        talentNode.tips.gameObject:SetActive(true)
    elseif breakStage < maxBreakStage then
        local textNum = Language[string.format("LUA_NUM_%d", nextBreakStage)]
        talentNode.textHint.text = string.format(Language.LUA_TALENT_UPGRADE_HINT, textNum)
        talentNode.tips.gameObject:SetActive(true)
    else
        talentNode.tips.gameObject:SetActive(false)
    end
end
CharInfoSkillUpgradeCtrl.ShowSkill = HL.Method(HL.Table) << function(self, skills)
    local single = #skills == 1
    if single then
        self:_SetState(stateEnum.SkillSingle)
        self:_RefreshSkillSingle(skills[1])
    else
        self:_SetState(stateEnum.SkillPlural)
        self:_RefreshSkillPlural(skills)
    end
end
CharInfoSkillUpgradeCtrl.ShowFacSkill = HL.Method(HL.Any) << function(self, facSkill)
    self:_SetState(stateEnum.FacSkill)
    self:_RefreshFacSkill(facSkill)
end
CharInfoSkillUpgradeCtrl._RefreshSkillSingle = HL.Method(HL.Table) << function(self, skillData)
    local bundleData = skillData.bundleData
    local patchData = skillData.patchData
    local level = patchData.level
    local skillId = patchData.skillId
    local maxLevel = 1
    local realMaxLevel = maxLevel
    local skillType = bundleData.skillType
    if skillType ~= Const.SkillTypeEnum.NormalAttack then
        maxLevel = skillData.maxLevel
        realMaxLevel = self.m_charSkillLevelUp[skillId].realMaxLevel
    end
    local skillInfo = { skillData = skillData, maxLevel = maxLevel, realMaxLevel = realMaxLevel, }
    self.view.skillNodeSingle.charInfoSkillNode:InitCharInfoSkillDesNode(skillInfo)
    if level < maxLevel then
        local skillLevelUpData = self.m_charSkillLevelUp[skillId][level + 1]
        self.view.skillNodeSingle.upgrade.gameObject:SetActive(true)
        self.view.skillNodeSingle.upgrade:InitSkillUpgradeNode(skillLevelUpData, function()
            self:_OnSkillLevelUpgradeClick(skillId, skillType)
        end)
        self.view.btnOpen.gameObject:SetActive(true)
        self:_RefreshSkillUpgradeSingle(skillData)
        self.view.skillNodeSingle.unable.gameObject:SetActive(false)
    else
        local hintText
        if level == realMaxLevel then
            hintText = Language.LUA_SKILL_MAX_LEVEL
        else
            local charInfo = CharInfoUtils.getPlayerCharInfoByInstId(self.m_charInfo.instId)
            local breakStage = charInfo.breakStage
            local targetBreakStage = CharInfoUtils.getCharSkillUpgradeNextBreakStage(self.m_charInfo.templateId, breakStage, skillType)
            if targetBreakStage then
                local textNum = Language[string.format("LUA_NUM_%d", targetBreakStage)]
                hintText = string.format(Language.LUA_SKILL_UPGRADE_HINT, textNum)
            else
                hintText = Language.LUA_SKILL_MAX_LEVEL
            end
        end
        self.view.skillNodeSingle.textHint.text = hintText
        self.view.skillNodeSingle.unable.gameObject:SetActive(true)
        self.view.skillNodeSingle.upgrade.gameObject:SetActive(false)
        self.view.btnOpen.gameObject:SetActive(false)
    end
end
CharInfoSkillUpgradeCtrl._RefreshSkillUpgradeSingle = HL.Method(HL.Table) << function(self, skillData)
    local bundleData = skillData.bundleData
    local patchData = skillData.patchData
    local level = patchData.level
    local skillType = bundleData.skillType
    local templateId = self.m_charInfo.templateId
    local instId = self.m_charInfo.instId
    local skillId = patchData.skillId
    local nextSkillData = CharInfoUtils.getPlayerCharSkillByTypeUnlock(instId, templateId, skillType, level + 1)[1]
    local nextSkillInfo = { skillData = nextSkillData, maxLevel = skillData.maxLevel, realMaxLevel = self.m_charSkillLevelUp[skillId].realMaxLevel }
    self.view.upgradeNodeSingle.charInfoSkillNode:InitCharInfoSkillDesNode(nextSkillInfo)
end
CharInfoSkillUpgradeCtrl._RefreshSkillPlural = HL.Method(HL.Table) << function(self, skills)
    local showUnable = true
    local reachRealMaxLevel = false
    local skillType
    for i = 1, pluralNum do
        local skillData = skills[i]
        local patchData = skillData.patchData
        local level = patchData.level
        local skillId = patchData.skillId
        local realMaxLevel = self.m_charSkillLevelUp[skillId].realMaxLevel
        local bundleData = skillData.bundleData
        skillType = bundleData.skillType
        local maxLevel = skillData.maxLevel
        local skillInfo = { skillData = skillData, maxLevel = maxLevel, realMaxLevel = realMaxLevel, }
        self.view.skillNodePlural[string.format("charInfoSkillNode%d", i)]:InitCharInfoSkillDesNode(skillInfo)
        reachRealMaxLevel = reachRealMaxLevel or level == realMaxLevel
        if level < maxLevel then
            local skillLevelUpData = self.m_charSkillLevelUp[skillId][level + 1]
            self.view.skillNodePlural.upgrade.gameObject:SetActive(true)
            self.view.skillNodePlural.upgrade:InitSkillUpgradeNode(skillLevelUpData, function()
                self:_OnSkillLevelUpgradeClick("", skillType)
            end)
            self.view.btnOpen.gameObject:SetActive(true)
            self:_RefreshSkillUpgradePlural(skills)
            showUnable = false
        else
            showUnable = true
        end
    end
    if showUnable then
        self.view.skillNodePlural.unable.gameObject:SetActive(true)
        self.view.skillNodePlural.upgrade.gameObject:SetActive(false)
        self.view.btnOpen.gameObject:SetActive(false)
        local hintText
        if reachRealMaxLevel then
            hintText = Language.LUA_SKILL_MAX_LEVEL
        else
            local charInfo = CharInfoUtils.getPlayerCharInfoByInstId(self.m_charInfo.instId)
            local breakStage = charInfo.breakStage
            local targetBreakStage = CharInfoUtils.getCharSkillUpgradeNextBreakStage(self.m_charInfo.templateId, breakStage, skillType)
            if targetBreakStage then
                local textNum = Language[string.format("LUA_NUM_%d", targetBreakStage)]
                hintText = string.format(Language.LUA_SKILL_UPGRADE_HINT, textNum)
            else
                hintText = Language.LUA_SKILL_MAX_LEVEL
            end
        end
        self.view.skillNodePlural.textHint.text = hintText
    else
        self.view.skillNodePlural.unable.gameObject:SetActive(false)
    end
end
CharInfoSkillUpgradeCtrl._RefreshSkillUpgradePlural = HL.Method(HL.Table) << function(self, skills)
    for i = 1, pluralNum do
        local skillData = skills[i]
        local bundleData = skillData.bundleData
        local patchData = skillData.patchData
        local level = patchData.level
        local skillType = bundleData.skillType
        local templateId = self.m_charInfo.templateId
        local instId = self.m_charInfo.instId
        local skillId = patchData.skillId
        local nextSkillData = CharInfoUtils.getPlayerCharSkillByType(instId, templateId, skillType, level + 1)[i]
        local nextSkillInfo = { skillData = nextSkillData, maxLevel = skillData.maxLevel, realMaxLevel = self.m_charSkillLevelUp[skillId].realMaxLevel }
        self.view.upgradeNodePlural[string.format("charInfoSkillNode%d", i)]:InitCharInfoSkillDesNode(nextSkillInfo)
    end
end
CharInfoSkillUpgradeCtrl._RefreshFacSkill = HL.Method(HL.Any) << function(self, facSkill)
    local skillId = facSkill.skillId
    local isUnlock = facSkill.isUnlock
    local skillData = Tables.factorySkillTable:GetValue(skillId)
    self.view.facSkillNode.textName.text = skillData.name
    local skillDesc = GameInstance.player.facCharacterSystem:GetSkillDesc(skillId)
    self.view.facSkillNode.text.text = UIUtils.resolveTextStyle(skillDesc)
    self.view.facSkillNode.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_SKILL_ICON, skillData.icon)
    local haveAdvancedSkill, breakStage = GameInstance.player.facCharacterSystem:HaveAdvancedSkill(self.m_charInfo.templateId, skillId)
    self.view.facSkillNode.tips.gameObject:SetActive(haveAdvancedSkill or isUnlock)
    if haveAdvancedSkill then
        local textNum = Language[string.format("LUA_NUM_%d", breakStage)]
        self.view.facSkillNode.textHint.text = string.format(Language.LUA_TALENT_UPGRADE_HINT, textNum)
    elseif isUnlock then
        local unlockBreakStage = CharInfoUtils.getCharFacSkillUnlockBreakStage(self.m_charInfo.templateId, skillId)
        local textNum = Language[string.format("LUA_NUM_%d", unlockBreakStage)]
        self.view.facSkillNode.textHint.text = string.format(Language.LUA_TALENT_UNLOCK_HINT, textNum)
    end
end
CharInfoSkillUpgradeCtrl._SetState = HL.Method(HL.Number) << function(self, state)
    self.view.skillNodeSingle.gameObject:SetActive(state == stateEnum.SkillSingle)
    self.view.upgradeNodeSingle.gameObject:SetActive(false)
    self.view.skillNodePlural.gameObject:SetActive(state == stateEnum.SkillPlural)
    self.view.upgradeNodePlural.gameObject:SetActive(false)
    self.view.talentNode.gameObject:SetActive(state == stateEnum.Talent)
    self.view.facSkillNode.gameObject:SetActive(state == stateEnum.FacSkill)
    self.state = state
    self:_RefreshToggle()
end
CharInfoSkillUpgradeCtrl._RefreshToggle = HL.Method(HL.Opt(HL.Boolean)) << function(self, expand)
    if expand then
        if self.state == stateEnum.SkillSingle then
            self.view.upgradeNodeSingle.gameObject:SetActive(true)
        else
            self.view.upgradeNodePlural.gameObject:SetActive(true)
        end
        self.view.btnOpen.gameObject:SetActive(false)
        self.view.btnClose.gameObject:SetActive(true)
    elseif expand == false then
        if self.state == stateEnum.SkillSingle then
            self.view.upgradeNodeSingle.gameObject:SetActive(false)
        else
            self.view.upgradeNodePlural.gameObject:SetActive(false)
        end
        self.view.btnOpen.gameObject:SetActive(true)
        self.view.btnClose.gameObject:SetActive(false)
    else
        local showExpand = self.state == stateEnum.SkillPlural or self.state == stateEnum.SkillSingle
        self.view.btnOpen.gameObject:SetActive(showExpand)
        self.view.btnClose.gameObject:SetActive(false)
    end
    self.view.emptyButton.gameObject:SetActive(expand)
    self.m_isToggle = not expand
end
CharInfoSkillUpgradeCtrl._OnSkillLevelUpgradeClick = HL.Method(HL.String, Const.SkillTypeEnum) << function(self, skillId, skillType)
    GameInstance.player.charBag:SkillLevelUpgrade(self.m_charInfo.instId, skillId, skillType)
end
HL.Commit(CharInfoSkillUpgradeCtrl)