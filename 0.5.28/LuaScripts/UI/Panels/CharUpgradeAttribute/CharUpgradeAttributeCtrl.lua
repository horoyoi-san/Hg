local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CharUpgradeAttribute
CharUpgradeAttributeCtrl = HL.Class('CharUpgradeAttributeCtrl', uiCtrl.UICtrl)
CharUpgradeAttributeCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_CHAR_INFO_UPGRADE_PREVIEW_LEVEL] = 'OnPreviewLevel', [MessageConst.ON_CHAR_INFO_UPGRADE_REFRESH_GOLD] = 'OnRefreshGoldShow', }
CharUpgradeAttributeCtrl.m_charInfo = HL.Field(HL.Table)
CharUpgradeAttributeCtrl.m_curMainControlTab = HL.Field(HL.Number) << UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW
CharUpgradeAttributeCtrl.m_upgradeAttributeCellCache = HL.Field(HL.Forward("UIListCache"))
CharUpgradeAttributeCtrl.m_charBreakSkillCellCache = HL.Field(HL.Forward("UIListCache"))
CharUpgradeAttributeCtrl.m_upgradeItemInfo = HL.Field(HL.Table)
CharUpgradeAttributeCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local initCharInfo = arg.initCharInfo or CharInfoUtils.getLeaderCharInfo()
    local mainControlTab = arg.mainControlTab or UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW
    self.m_charInfo = initCharInfo
    self.m_curMainControlTab = mainControlTab
    self.m_upgradeItemInfo = { genExp = false, }
    local charInstInfo = CharInfoUtils.getPlayerCharInfoByInstId(initCharInfo.instId)
    self:_InitActionEvent()
    self:_RefreshUpgradePanel(initCharInfo, mainControlTab, charInstInfo.level, charInstInfo.breakStage)
end
CharUpgradeAttributeCtrl.OnRefreshGoldShow = HL.Method(HL.Table) << function(self, data)
    local goldEnough = data.goldEnough
    local gold = data.gold
    if goldEnough == nil then
        goldEnough = true
    end
    self.view.goldCostText.text = UIUtils.setCountColor(gold, not goldEnough)
end
CharUpgradeAttributeCtrl.OnPreviewLevel = HL.Method(HL.Table) << function(self, arg)
    local targetLevel, targetStage, genExp, itemEnough = unpack(arg)
    self:_RefreshAttributeNode(self.m_charInfo, targetLevel, targetStage)
    self:_RefreshSkillNode(self.m_charInfo, targetLevel, targetStage)
    self.m_upgradeItemInfo = { genExp = genExp, itemEnough = itemEnough, }
end
CharUpgradeAttributeCtrl._InitActionEvent = HL.Method() << function(self)
    self.view.confirmButton.onClick:AddListener(function()
        local isUpgrade = self.m_curMainControlTab == UIConst.CHAR_INFO_PAGE_TYPE.UPGRADE
        if isUpgrade and (not self.m_upgradeItemInfo.genExp) then
            self:Notify(MessageConst.SHOW_TOAST, Language.LUA_CHAR_UPGRADE_NONE_ITEM)
            return
        end
        self:_OnConfirmButtonClick()
    end)
    self.view.backButton.onClick:AddListener(function()
        self:Notify(MessageConst.P_CHAR_INFO_PAGE_CHANGE, { pageType = UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW })
    end)
    self.m_upgradeAttributeCellCache = UIUtils.genCellCache(self.view.charUpgradeAttributeCell)
    self.m_charBreakSkillCellCache = UIUtils.genCellCache(self.view.charBreakSkillCell)
end
CharUpgradeAttributeCtrl._RefreshUpgradePanel = HL.Method(HL.Table, HL.Number, HL.Number, HL.Number) << function(self, charInfo, tabType, targetLevel, targetStage)
    local isUpgrade = tabType == UIConst.CHAR_INFO_PAGE_TYPE.UPGRADE
    self.m_curMainControlTab = tabType
    self.view.confirmButton.text = isUpgrade and Language.LUA_CHAR_UPGRADE or Language.LUA_CHAR_BREAK
    self:_RefreshAttributeNode(charInfo, targetLevel, targetStage)
    self:_RefreshSkillNode(charInfo, targetLevel, targetStage)
end
CharUpgradeAttributeCtrl._RefreshAttributeNode = HL.Method(HL.Table, HL.Number, HL.Number) << function(self, charInfo, targetLevel, targetStage)
    local charInstInfo = CharInfoUtils.getPlayerCharInfoByInstId(charInfo.instId)
    local baseAttributes = CharInfoUtils.getCharPaperAttributes(charInstInfo.templateId, charInstInfo.level, charInstInfo.breakStage)
    local targetAttributes = CharInfoUtils.getCharPaperAttributes(charInstInfo.templateId, targetLevel, targetStage)
    local showAttributes = CharInfoUtils.generateBasicAttributeShowInfoList(baseAttributes)
    local showTargetAttributes = CharInfoUtils.generateBasicAttributeShowInfoList(targetAttributes)
    self.m_upgradeAttributeCellCache:Refresh(#showAttributes, function(cell, index)
        local attributeInfo = showAttributes[index]
        local diffInfo = showTargetAttributes[index]
        local attributeType = attributeInfo.attributeType
        local attributeKey = Const.ATTRIBUTE_TYPE_2_ATTRIBUTE_DATA_KEY[attributeType]
        cell.numText.text = attributeInfo.showValue
        cell.mainText.text = attributeInfo.showName
        cell.numTextAdd.text = diffInfo.showValue
        cell.numTextAdd.color = baseAttributes[attributeType] == targetAttributes[attributeType] and self.view.config.ATTRIBUTE_SAME_COLOR or self.view.config.ATTRIBUTE_DIFF_COLOR
        cell.attributeIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ATTRIBUTE_ICON, attributeInfo.iconName)
    end)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.attributeNode.transform)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.skillNode.transform)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.mainInfoNode.transform)
end
CharUpgradeAttributeCtrl._RefreshSkillNode = HL.Method(HL.Table, HL.Number, HL.Number) << function(self, charInfo, targetLevel, targetStage)
    local templateId = charInfo.templateId
    local charInstInfo = CharInfoUtils.getPlayerCharInfoByInstId(charInfo.instId)
    local breakStage = charInstInfo.breakStage
    local instId = charInfo.instId
    local skillIds = CharInfoUtils.getBreakStageUnlockSkills(templateId, targetStage)
    local talents = CharInfoUtils.getCharBreakStageTalents(templateId, targetStage - 1, targetStage)
    local unlockTalents = talents.unlockTalents
    local enhancedTalents = talents.enhancedTalents
    local facSkills = CharInfoUtils.getCharBreakStageFacSkills(templateId, targetStage - 1, targetStage)
    local unlockFacSkills = facSkills.unlockFacSkills
    local upgradeFacSkills = facSkills.upgradeFacSkills
    local skillCount = skillIds.Count or #skillIds
    local unlockCount = #unlockTalents
    local enhancedCount = #enhancedTalents
    local talentCount = unlockCount + enhancedCount
    local unlockFacCount = #unlockFacSkills
    local upgradeFacCount = #upgradeFacSkills
    local count = skillCount + unlockCount + enhancedCount + unlockFacCount + upgradeFacCount
    if breakStage == targetStage or (count <= 0 and (not skillIds or skillCount <= 0)) then
        self.view.skillNode.gameObject:SetActive(false)
    else
        self.m_charBreakSkillCellCache:Refresh(count, function(cell, luaIndex)
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
            local transform = cell.view.transform
            if isSkill then
                local skillId = skillIds[CSIndex(luaIndex)]
                skillData = CharInfoUtils.getSkillDataById(skillId, 1)
                data.skillData = skillData
                data.callback = function()
                    local skillInfo = { skillData = skillData, transform = transform, skillType = skillData.bundleData.skillType, charId = templateId, charInstId = instId, }
                    self:Notify(MessageConst.SHOW_CHAR_SKILL_TIP, { skillInfo, false })
                end
            elseif isTalent then
                talent = unlockTalents[luaIndex - skillCount]
                if not talent then
                    talent = enhancedTalents[luaIndex - skillCount - unlockCount]
                end
                local talentData = talent.talentData
                data.talentData = talentData
                data.callback = function()
                    local talentInfo = { talentData = talentData, nextBreakStage = talent.nextBreakStage, transform = transform, }
                    self:Notify(MessageConst.ON_CHAR_SHOW_TALENT_TIPS, talentInfo)
                end
            else
                local facSkillData = unlockFacSkills[luaIndex - skillCount - talentCount]
                if not facSkillData then
                    facSkillData = upgradeFacSkills[luaIndex - skillCount - talentCount - unlockFacCount]
                end
                data.facSkillData = facSkillData
                data.callback = function()
                    local facSkillInfo = { facSkillData = facSkillData, transform = transform, }
                    self:Notify(MessageConst.ON_CHAR_SHOW_FAC_SKILL_TIPS, facSkillInfo)
                end
            end
            cell:InitCharBreakSkillCell(data)
        end)
        self.view.skillNode.gameObject:SetActive(true)
    end
end
HL.Commit(CharUpgradeAttributeCtrl)