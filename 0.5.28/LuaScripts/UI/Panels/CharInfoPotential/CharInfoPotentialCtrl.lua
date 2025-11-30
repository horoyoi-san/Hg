local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CharInfoPotential
CharInfoPotentialCtrl = HL.Class('CharInfoPotentialCtrl', uiCtrl.UICtrl)
CharInfoPotentialCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_CHAR_POTENTIAL_UNLOCK] = '_OnCharPotentialUnlock', [MessageConst.P_CHAR_INFO_SELECT_CHAR_CHANGE] = '_OnSelectCharChange', }
CharInfoPotentialCtrl.m_charTemplateId = HL.Field(HL.String) << ''
CharInfoPotentialCtrl.m_charInstId = HL.Field(HL.Number) << -1
CharInfoPotentialCtrl.m_phaseCharInfo = HL.Field(HL.Forward("PhaseCharInfo"))
CharInfoPotentialCtrl.m_potentialList = HL.Field(HL.Userdata)
CharInfoPotentialCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_charInstId = args.initCharInfo.instId
    self.m_charTemplateId = args.initCharInfo.templateId
    self.m_phaseCharInfo = args.phase
    self.view.currentPotentialNode.btnGoToLevelUp.onClick:AddListener(function()
        local isTrailCard = CharInfoUtils.checkIsCardInTrail(self.m_charInstId)
        if isTrailCard then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_CHAR_INFO_TALENT_UPGRADE_FORBID)
            return
        end
        self:_ActiveLevelUp(true)
    end)
    self.view.btnBack.onClick:AddListener(function()
        self:_ActiveLevelUp(false)
    end)
    self.view.rightNode.btnLevelUp.onClick:AddListener(function()
        self:_OnLevelUpClicked()
    end)
    self:RefreshAll()
    self.view.main:SetState("Current")
end
CharInfoPotentialCtrl._OnCharPotentialUnlock = HL.Method(HL.Table) << function(self, args)
    local charInstId, level = unpack(args)
    if charInstId ~= self.m_charInstId then
        return
    end
    self.view.leftNode.animWrapper:PlayOutAnimation(function()
        self:RefreshAll(true)
        AudioAdapter.PostEvent("Au_UI_Event_CharPotentialLevelUp")
        local charInst = CharInfoUtils.getPlayerCharInfoByInstId(self.m_charInstId)
        local templateId = charInst.templateId
        if self.m_isPotentialMax then
            Utils.triggerVoice("chrup_telant_max", templateId)
        else
            Utils.triggerVoice("chrup_telant_common", templateId)
        end
        self.view.leftNode.animWrapper:PlayInAnimation()
    end)
    self.view.rightNode.animWrapper:PlayOutAnimation(function()
        self.view.rightNode.animWrapper:PlayInAnimation()
    end)
end
CharInfoPotentialCtrl._OnSelectCharChange = HL.Method(HL.Table) << function(self, charInfo)
    self.view.animWrapper:PlayOutAnimation(function()
        self.m_charInstId = charInfo.instId
        self.m_charTemplateId = charInfo.templateId
        self:RefreshAll()
        self.m_phase:RefreshPotentialCharImg(self.m_charTemplateId, true)
        self.view.animWrapper:PlayInAnimation()
    end)
end
CharInfoPotentialCtrl._OnLevelUpClicked = HL.Method() << function(self)
    GameInstance.player.charBag:CharPotentialUnlock(self.m_charInstId, self.m_selectedItemId, self.m_potentialLevel + 1)
end
CharInfoPotentialCtrl.RefreshAll = HL.Method(HL.Opt(HL.Boolean)) << function(self, isLvUp)
    local success, characterPotentialList = Tables.characterPotentialTable:TryGetValue(self.m_charTemplateId)
    if success then
        self.m_potentialList = characterPotentialList
        self.m_maxPotentialLevel = #self.m_potentialList.potentialUnlockBundle
    else
        logger.error("潜能数据不存在:" .. self.m_charTemplateId)
    end
    self:_InitPotentialSkills()
    self:_RefreshPotentialData()
    self:_RefreshPotentialSkills()
    self:_RefreshAllPotentialLevel()
    self:_RefreshPotentialLevelUpInfo()
    self.m_phaseCharInfo:RefreshPotentialStar(self.m_potentialLevel, self.m_maxPotentialLevel, isLvUp)
end
CharInfoPotentialCtrl._ActiveLevelUp = HL.Method(HL.Boolean) << function(self, active)
    if active then
        self.view.animWrapper:PlayOutAnimation(function()
            self.view.main:SetState("LevelUp")
            self:Notify(MessageConst.TOGGLE_CHAR_INFO_FOCUS_MODE, true)
            self.m_phase:SetActivePotentialNextStar(self.m_potentialLevel + 1, true, false)
        end)
    else
        self.view.leftNode.animWrapper:PlayOutAnimation()
        self.view.rightNode.animWrapper:PlayOutAnimation(function()
            self.view.main:SetState("Current")
            self:Notify(MessageConst.TOGGLE_CHAR_INFO_FOCUS_MODE, false)
            self.view.animWrapper:PlayInAnimation()
            self.m_phase:SetActivePotentialNextStar(self.m_potentialLevel + 1, false, false)
        end)
    end
end
CharInfoPotentialCtrl.m_potentialLevel = HL.Field(HL.Number) << 0
CharInfoPotentialCtrl.m_isPotentialMax = HL.Field(HL.Boolean) << false
CharInfoPotentialCtrl.m_maxPotentialLevel = HL.Field(HL.Number) << 0
CharInfoPotentialCtrl._RefreshPotentialData = HL.Method() << function(self)
    local charInfo = CharInfoUtils.getPlayerCharInfoByInstId(self.m_charInstId)
    self.m_potentialLevel = charInfo.potentialLevel
    self.m_isPotentialMax = self.m_potentialLevel >= self.m_maxPotentialLevel
end
CharInfoPotentialCtrl._RefreshAllPotentialLevel = HL.Method() << function(self)
    self.view.leftNode.charPotential:InitCharPotential(self.m_potentialLevel)
    self.view.leftNode.level:SetState(self.m_isPotentialMax and "Max" or "Normal")
    self.view.leftNode.currentLevel.text = tostring(self.m_potentialLevel)
    self.view.leftNode.maxLevel.text = self.m_isPotentialMax and "MAX" or tostring(self.m_maxPotentialLevel)
    self.view.leftNode.nextLevel.text = tostring(math.min(self.m_potentialLevel + 1, self.m_maxPotentialLevel))
    self.view.currentPotentialNode.simpleStateController:SetState(self.m_isPotentialMax and "Max" or "Normal")
    self.view.currentPotentialNode.charPotential:InitCharPotential(self.m_potentialLevel)
    self.view.currentPotentialNode.currentLevel.text = tostring(self.m_potentialLevel)
    self.view.currentPotentialNode.maxLevel.text = self.m_isPotentialMax and "MAX" or tostring(self.m_maxPotentialLevel)
    self.view.currentPotentialNode.redDot:InitRedDot("CharInfoPotential", self.m_charInstId)
end
CharInfoPotentialCtrl._InitPotentialSkills = HL.Method() << function(self)
    for i = 1, 5 do
        local skillNode = self.view[string.format("skill%02d", i)]
        if skillNode then
            local isShow = i <= self.m_maxPotentialLevel
            skillNode.gameObject:SetActive(isShow)
            if isShow then
                local potentialData = self.m_potentialList.potentialUnlockBundle[CSIndex(i)]
                skillNode.name.text = potentialData.name
            end
            skillNode.button.onClick:RemoveAllListeners()
            skillNode.button.onClick:AddListener(function()
                local isRight = i == 1 or i == 3
                local tipsArgs = { charId = self.m_charTemplateId, potentialLevel = i, isLocked = i > self.m_potentialLevel, isArrowLeft = not isRight, followedTransform = skillNode.transform }
                self:Notify(MessageConst.SHOW_CHAR_POTENTIAL_SKILL_TIPS, tipsArgs)
            end)
        end
    end
end
CharInfoPotentialCtrl._RefreshPotentialSkills = HL.Method() << function(self)
    for i = 1, self.m_maxPotentialLevel do
        local skillNode = self.view[string.format("skill%02d", i)]
        if skillNode then
            local stateName = "charInfo_potential_locked"
            if i <= self.m_potentialLevel then
                stateName = "charInfo_potential_unlocked"
            elseif i == self.m_potentialLevel + 1 then
                stateName = "charInfo_potential_nextUnlocked"
            end
            skillNode.animation:Play(stateName)
        end
    end
end
CharInfoPotentialCtrl.m_selectedItemId = HL.Field(HL.String) << ''
CharInfoPotentialCtrl._RefreshPotentialLevelUpInfo = HL.Method() << function(self)
    local stateName = "Normal"
    if self.m_isPotentialMax then
        stateName = "Max"
    else
        local nextPotentialLevel = self.m_potentialLevel + 1
        local potentialData = self.m_potentialList.potentialUnlockBundle[CSIndex(nextPotentialLevel)]
        self.view.rightNode.name.text = potentialData.name
        local potentialDesc = CS.Beyond.Gameplay.PotentialUtil.GetPotentialDescription(self.m_charTemplateId, nextPotentialLevel)
        self.view.rightNode.textDesc.text = UIUtils.resolveTextStyle(potentialDesc)
        local itemId = potentialData.itemIds[0]
        local itemCount = Utils.getItemCount(itemId)
        local needCount = potentialData.itemCnts[0]
        local isLack = itemCount < needCount
        self.m_selectedItemId = itemId
        self.view.rightNode.itemBigBlack:InitItem({ id = itemId, count = needCount }, true)
        self.view.rightNode.storageText.text = UIUtils.setCountColor(Language.ui_char_info_potential_mat_owned, isLack)
        self.view.rightNode.storageCount.text = UIUtils.setCountColor(UIUtils.getNumString(itemCount), isLack)
        if isLack then
            stateName = "Unable"
        end
    end
    self.view.rightNode.simpleStateController:SetState(stateName)
end
HL.Commit(CharInfoPotentialCtrl)