local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CharFormationSkillTips
CharFormationSkillTipsCtrl = HL.Class('CharFormationSkillTipsCtrl', uiCtrl.UICtrl)
CharFormationSkillTipsCtrl.s_messages = HL.StaticField(HL.Table) << {}
CharFormationSkillTipsCtrl.m_curSkillId = HL.Field(HL.String) << ""
CharFormationSkillTipsCtrl.m_cachedArgs = HL.Field(HL.Table)
CharFormationSkillTipsCtrl.m_extraInfoCellCache = HL.Field(HL.Forward("UIListCache"))
CharFormationSkillTipsCtrl.ShowCharSkillTip = HL.StaticMethod(HL.Table) << function(args)
    local isShowing = UIManager:IsShow(PANEL_ID)
    local self = UIManager:AutoOpen(PANEL_ID)
    if isShowing then
        self:_ClearArgs()
        if not self:IsPlayingAnimationOut() then
            self:PlayAnimationOutWithCallback(function()
                self:_ShowTips(args)
            end)
        else
            self.m_cachedArgs = args
        end
    else
        self:_ShowTips(args)
    end
end
CharFormationSkillTipsCtrl._ShowTips = HL.Method(HL.Table) << function(self, args)
    self:_InitActionEvent()
    self.m_extraInfoCellCache = UIUtils.genCellCache(self.view.extraInfo)
    self.view.skillInfoNode.gameObject:SetActive(not args.isPassiveSkill)
    self.view.passiveSkillInfoNode.gameObject:SetActive(args.isPassiveSkill)
    if args.isPassiveSkill then
        self:_RefreshPassiveSkillTip(args)
    else
        self:_RefreshSkillGroupTip(args)
    end
    UIUtils.updateTipsPosition(self.view.content, args.transform, self.view.rectTransform, self.uiCamera, args.tipPosType)
end
CharFormationSkillTipsCtrl._RefreshSkillGroupTip = HL.Method(HL.Table) << function(self, args)
    local charInstId = args.charInstId
    local skillGroupType = args.skillGroupType
    local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
    local skillGroupCfg = CharInfoUtils.getCharSkillGroupCfgByType(charInst.templateId, skillGroupType)
    local skillInfo = CharInfoUtils.getCharSkillLevelInfoByType(charInst, skillGroupType)
    local desc = UIUtils.resolveTextStyle(Utils.SkillUtil.GetSkillGroupDescription(charInst.templateId, skillGroupCfg.skillGroupId, skillInfo.level))
    self.view.skillName.text = skillGroupCfg.name
    self.view.desc.text = desc
    self.view.skillTypeName.text = UIConst.CHAR_INFO_SKILL_GROUP_TYPE_TO_TYPE_NAME[skillGroupType]
    local canUpgrade = skillInfo.level < UIConst.CHAR_MAX_SKILL_LV and not args.hideBtnUpgrade
    self.view.btnUpgrade.gameObject:SetActive(canUpgrade)
    self.view.btnUpgrade.onClick:AddListener(function()
        local isOpen, openedPhase = PhaseManager:IsOpen(PhaseId.CharInfo)
        if isOpen then
            PhaseManager:SendMessageToOpenedPhase(PhaseId.CharInfo, MessageConst.P_CHAR_INFO_PAGE_CHANGE, { pageType = UIConst.CHAR_INFO_PAGE_TYPE.TALENT, isFast = true, showGlitch = true, extraArg = { showSkillGroupType = skillGroupType, } })
        else
            CharInfoUtils.openCharInfoBestWay({ initCharInfo = { instId = charInstId, templateId = charInst.templateId, isSingleChar = args.isSingleChar == true, }, pageType = UIConst.CHAR_INFO_PAGE_TYPE.TALENT, isFast = true, showGlitch = true, extraArg = { showSkillGroupType = skillGroupType, } })
        end
        self:Close()
    end)
    local curSkillLv = skillInfo.level
    local isElite = curSkillLv >= UIConst.CHAR_MAX_SKILL_NORMAL_LV
    local showSkillLv = lume.clamp(curSkillLv, 1, UIConst.CHAR_MAX_SKILL_NORMAL_LV)
    local eliteLv = isElite and curSkillLv - UIConst.CHAR_MAX_SKILL_NORMAL_LV or 0
    self.view.rank.text = string.format(Language.LUA_CHAR_INFO_TALENT_SKILL_LEVEL_PREFIX, showSkillLv)
    self.view.elitepolygon.gameObject:SetActive(isElite)
    self.view.elitepolygon:InitElitePolygon(eliteLv)
    if skillGroupCfg.skillGroupType ~= GEnums.SkillGroupType.NormalAttack then
        local skillId = skillGroupCfg.skillIdList[0]
        local extraInfoList = CharInfoUtils.getSkillExtraInfoList(skillId, skillInfo.level)
        self.m_extraInfoCellCache:Refresh(#extraInfoList, function(cell, index)
            local info = extraInfoList[index]
            cell.title.text = info.name
            cell.num.text = info.value
        end)
    end
end
CharFormationSkillTipsCtrl._RefreshPassiveSkillTip = HL.Method(HL.Table) << function(self, args)
    local isLock = args.isLock
    local charInstId = args.charInstId
    local nodeIndex = args.skillId
    local nodeLevel = args.skillLevel
    local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
    local talentUpgradeCfg = CharInfoUtils.getPassiveSkillTalentNodeByIndex(charInst.templateId, nodeIndex, nodeLevel + 1)
    local talentNodeCfg = CharInfoUtils.getPassiveSkillTalentNodeByIndex(charInst.templateId, nodeIndex, nodeLevel)
    self.m_curSkillId = talentNodeCfg.nodeId
    self.view.skillName.text = talentNodeCfg.passiveSkillNodeInfo.name
    self.view.passiveSkillInfoNode.locked.gameObject:SetActive(isLock)
    self.view.passiveSkillInfoNode.stageLevelCellGroup.view.gameObject:SetActive(not isLock)
    self.view.passiveSkillInfoNode.rank.gameObject:SetActive(not isLock)
    local foundNodeList = CharInfoUtils.getAllPassiveSkillTalentNodeByIndex(charInst.templateId, nodeIndex)
    self.view.passiveSkillInfoNode.stageLevelCellGroup:InitStageLevelCellGroupByPassiveNodeList(charInst.instId, foundNodeList)
    local nodeDesc = CS.Beyond.Gameplay.TalentUtil.GetTalentNodeDescription(charInst.templateId, talentNodeCfg.nodeId)
    self.view.desc.text = UIUtils.resolveTextStyle(nodeDesc)
    self.view.skillTypeName.text = Language.LUA_CHAR_INFO_TALENT_SKILL_NAME
    self.view.elitepolygon.gameObject:SetActive(false)
    local canUpgrade = talentUpgradeCfg ~= nil and not args.hideBtnUpgrade
    self.view.btnUpgrade.gameObject:SetActive(canUpgrade)
    self.view.btnUpgrade.onClick:AddListener(function()
        self:Close()
        if PhaseManager:IsOpen(PhaseId.CharInfo) then
            PhaseManager:SendMessageToOpenedPhase(PhaseId.CharInfo, MessageConst.P_CHAR_INFO_PAGE_CHANGE, { pageType = UIConst.CHAR_INFO_PAGE_TYPE.TALENT, isFast = true, showGlitch = true, extraArg = { showPassiveSkillId = talentNodeCfg.nodeId, } })
        else
            CharInfoUtils.openCharInfoBestWay({ initCharInfo = { instId = charInstId, templateId = charInst.templateId, isSingleChar = args.isSingleChar == true, }, pageType = UIConst.CHAR_INFO_PAGE_TYPE.TALENT, isFast = true, showGlitch = true, extraArg = { showPassiveSkillId = talentNodeCfg.nodeId, } })
        end
    end)
end
CharFormationSkillTipsCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
end
CharFormationSkillTipsCtrl._InitActionEvent = HL.Method() << function(self)
    self.view.btnTouch.onClick:AddListener(function()
        Notify(MessageConst.CHAR_INFO_CLOSE_SKILL_TIP)
        self:Close()
    end)
end
HL.Commit(CharFormationSkillTipsCtrl)