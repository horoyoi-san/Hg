local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.UpgradePopUp
UpgradePopUpCtrl = HL.Class('UpgradePopUpCtrl', uiCtrl.UICtrl)
UpgradePopUpCtrl.s_messages = HL.StaticField(HL.Table) << {}
UpgradePopUpCtrl.m_upgradeAttributeCellCache = HL.Field(HL.Forward("UIListCache"))
UpgradePopUpCtrl.m_breakAttributeCellCache = HL.Field(HL.Forward("UIListCache"))
UpgradePopUpCtrl.m_breakSkillCellCache = HL.Field(HL.Forward("UIListCache"))
UpgradePopUpCtrl.m_attributeShowCor = HL.Field(HL.Thread)
UpgradePopUpCtrl.m_skillShowCor = HL.Field(HL.Thread)
UpgradePopUpCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:_InitActionEvent()
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
UpgradePopUpCtrl._InitActionEvent = HL.Method() << function(self)
    self.view.buttonClose.onClick:AddListener(function()
        self:PlayAnimationOut(UIConst.PANEL_PLAY_ANIMATION_OUT_COMPLETE_ACTION_TYPE.Close)
    end)
    self.m_upgradeAttributeCellCache = UIUtils.genCellCache(self.view.upgradeList.charPopupAttributeCell)
    self.m_breakAttributeCellCache = UIUtils.genCellCache(self.view.breakList.charPopupAttributeCell)
    self.m_breakSkillCellCache = UIUtils.genCellCache(self.view.breakList.charBreakSkillCell)
end
UpgradePopUpCtrl.ShowLevelUpPopUp = HL.StaticMethod(HL.Table) << function(arg)
    local instId = arg.instId
    local self = UpgradePopUpCtrl.AutoOpen(PANEL_ID, nil, false)
    local charInstInfo = CharInfoUtils.getPlayerCharInfoByInstId(instId)
    local _, _, _, maxLevel = CharInfoUtils.getCharExpInfo(instId)
    self.view.contentTitle.text = Language.LUA_CHAR_UPGRADE_POP_UP_UPGRADE_TITLE
    self.view.upgradeInfo.gameObject:SetActive(true)
    self.view.upgradeList.gameObject:SetActive(true)
    self.view.breakInfo.gameObject:SetActive(false)
    self.view.breakList.gameObject:SetActive(false)
    self.view.upgradeInfo.fromLevelText.text = arg.fromLevel
    self.view.upgradeInfo.fromMaxLevelText.text = maxLevel
    self.view.upgradeInfo.toLevelText.text = arg.toLevel
    self.view.upgradeInfo.toMaxLevelText.text = maxLevel
    local baseAttributes = CharInfoUtils.getCharPaperAttributes(charInstInfo.templateId, arg.fromLevel, arg.fromBreakStage)
    local targetAttributes = CharInfoUtils.getCharPaperAttributes(charInstInfo.templateId, arg.toLevel, arg.toBreakStage)
    local showAttributes = CharInfoUtils.generateBasicAttributeShowInfoList(baseAttributes)
    local showTargetAttributes = CharInfoUtils.generateBasicAttributeShowInfoList(targetAttributes)
    self.m_upgradeAttributeCellCache:Refresh(#showAttributes, function(cell, index)
        local attributeInfo = showAttributes[index]
        local attributeType = attributeInfo.attributeType
        local attributeKey = Const.ATTRIBUTE_TYPE_2_ATTRIBUTE_DATA_KEY[attributeType]
        cell.numText.text = attributeInfo.showValue
        cell.mainText.text = attributeInfo.showName
        cell.numTextAdd.text = showTargetAttributes[index].showValue
        cell.attributeIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ATTRIBUTE_ICON, UIConst.UI_ATTRIBUTE_ICON_PREFIX .. attributeKey)
        cell.gameObject:SetActive(false)
    end)
    self.m_attributeShowCor = self:_StartCoroutine(function()
        for i = 1, #showAttributes do
            local cell = self.m_upgradeAttributeCellCache:GetItem(i)
            cell.gameObject:SetActive(true)
            coroutine.wait(self.view.config.ATTRIBUTE_SHOW_DURATION)
        end
    end)
end
UpgradePopUpCtrl.ShowBreakPopUp = HL.StaticMethod(HL.Table) << function(arg)
    AudioAdapter.PostEvent("au_ui_char_level_break")
    local instId = arg.instId
    local self = UpgradePopUpCtrl.AutoOpen(PANEL_ID, nil, false)
    local charInstInfo = CharInfoUtils.getPlayerCharInfoByInstId(instId)
    local baseAttributes = CharInfoUtils.getCharPaperAttributes(charInstInfo.templateId, arg.fromLevel, arg.fromBreakStage)
    local targetAttributes = CharInfoUtils.getCharPaperAttributes(charInstInfo.templateId, arg.toLevel, arg.toBreakStage)
    local showAttributes = CharInfoUtils.generateBasicAttributeShowInfoList(baseAttributes)
    local showTargetAttributes = CharInfoUtils.generateBasicAttributeShowInfoList(targetAttributes)
    local fromBreakStageCfg = Tables.charBreakTable[arg.fromBreakStage]
    local toBreakStageCfg = Tables.charBreakTable[arg.toBreakStage]
    self.view.contentTitle.text = Language.LUA_CHAR_UPGRADE_POP_UP_BREAK_TITLE
    self.view.upgradeInfo.gameObject:SetActive(false)
    self.view.upgradeList.gameObject:SetActive(false)
    self.view.breakInfo.gameObject:SetActive(true)
    self.view.breakList.gameObject:SetActive(true)
    self.view.breakInfo.fromLevelText.text = fromBreakStageCfg.maxLevel
    self.view.breakInfo.fromLevelText1.text = fromBreakStageCfg.maxLevel
    self.view.breakInfo.toLevelText1.text = fromBreakStageCfg.maxLevel
    self.view.breakInfo.toLevelText.text = toBreakStageCfg.maxLevel
    self.view.breakInfo.levelBreakNode:InitLevelBreakNode(arg.fromBreakStage, true)
    self.view.breakInfo.levelBreakNodeShadow:InitLevelBreakNode(arg.fromBreakStage, true)
    self.m_breakAttributeCellCache:Refresh(#showAttributes, function(cell, index)
        local attributeInfo = showAttributes[index]
        local attributeType = attributeInfo.attributeType
        local attributeKey = Const.ATTRIBUTE_TYPE_2_ATTRIBUTE_DATA_KEY[attributeType]
        cell.numText.text = attributeInfo.showValue
        cell.mainText.text = attributeInfo.showName
        cell.numTextAdd.text = showTargetAttributes[index].showValue
        cell.attributeIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ATTRIBUTE_ICON, UIConst.UI_ATTRIBUTE_ICON_PREFIX .. attributeKey)
        cell.gameObject:SetActive(false)
    end)
    self.m_attributeShowCor = self:_StartCoroutine(function()
        for i = 1, #showAttributes do
            local cell = self.m_breakAttributeCellCache:GetItem(i)
            cell.gameObject:SetActive(true)
            coroutine.wait(self.view.config.ATTRIBUTE_SHOW_DURATION)
        end
    end)
    local templateId = charInstInfo.templateId
    local skillIds = CharInfoUtils.getBreakStageUnlockSkills(templateId, arg.toBreakStage)
    local talents = CharInfoUtils.getCharBreakStageTalents(templateId, arg.fromBreakStage, arg.toBreakStage)
    local facSkills = CharInfoUtils.getCharBreakStageFacSkills(templateId, arg.fromBreakStage, arg.toBreakStage)
    local unlockTalents = talents.unlockTalents
    local enhancedTalents = talents.enhancedTalents
    local unlockFacSkills = facSkills.unlockFacSkills
    local upgradeFacSkills = facSkills.upgradeFacSkills
    local skillCount = skillIds.Count or #skillIds
    local unlockCount = #unlockTalents
    local enhancedCount = #enhancedTalents
    local talentCount = unlockCount + enhancedCount
    local unlockFacCount = #unlockFacSkills
    local upgradeFacCount = #upgradeFacSkills
    local count = skillCount + unlockCount + enhancedCount + unlockFacCount + upgradeFacCount
    self.view.breakList.lineSpace.gameObject:SetActive(count > 0)
    self.m_breakSkillCellCache:Refresh(count, function(cell, luaIndex)
        local skillData
        local talent
        local isSkill = CSIndex(luaIndex) < skillCount
        local isTalent = CSIndex(luaIndex) >= skillCount and CSIndex(luaIndex) < skillCount + talentCount
        local isUnlock = isSkill
        if CSIndex(luaIndex) >= skillCount and CSIndex(luaIndex) < skillCount + unlockCount then
            isUnlock = true
        elseif CSIndex(luaIndex) >= skillCount + talentCount and CSIndex(luaIndex) < skillCount + talentCount + unlockFacCount then
            isUnlock = true
        end
        local data = { isUnlock = isUnlock, }
        if isSkill then
            local skillId = skillIds[CSIndex(luaIndex)]
            skillData = CharInfoUtils.getSkillDataById(skillId, 1)
            data.skillData = skillData
            data.skillData.unlock = true
        elseif isTalent then
            talent = unlockTalents[luaIndex - skillCount]
            if not talent then
                talent = enhancedTalents[luaIndex - skillCount - unlockCount]
            end
            data.talentData = talent.talentData
        else
            local facSkillData = unlockFacSkills[luaIndex - skillCount - talentCount]
            if not facSkillData then
                facSkillData = upgradeFacSkills[luaIndex - skillCount - talentCount - unlockFacCount]
            end
            data.facSkillData = facSkillData
        end
        cell:InitCharBreakSkillCell(data)
        cell.gameObject:SetActive(false)
    end)
    self.m_skillShowCor = self:_StartCoroutine(function()
        for i = 1, count do
            local cell = self.m_breakSkillCellCache:GetItem(i)
            cell.gameObject:SetActive(true)
            coroutine.wait(self.view.config.SKILL_SHOW_DURATION)
        end
    end)
end
HL.Commit(UpgradePopUpCtrl)