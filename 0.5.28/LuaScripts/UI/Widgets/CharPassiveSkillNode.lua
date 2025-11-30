local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
CharPassiveSkillNode = HL.Class('CharPassiveSkillNode', UIWidgetBase)
CharPassiveSkillNode.m_passiveSkillCellCache = HL.Field(HL.Forward("UIListCache"))
CharPassiveSkillNode._OnFirstTimeInit = HL.Override() << function(self)
    self.m_passiveSkillCellCache = UIUtils.genCellCache(self.view.passiveSkillCell)
end
CharPassiveSkillNode.InitCharPassiveSkillNode = HL.Method(HL.Number, HL.Opt(HL.Boolean, HL.Boolean, CS.UnityEngine.Transform, HL.Number)) << function(self, charInstId, isSingleChar, hideBtnUpgrade, tipsNode, tipPosType)
    self:_FirstTimeInit()
    local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
    local luaPassiveSkillNodeList = {}
    local _, passiveSkillNodeList, _ = CharInfoUtils.classifyTalentNode(charInst.templateId)
    local passiveSkillAList = passiveSkillNodeList[0]
    local passiveSkillBList = passiveSkillNodeList[1]
    if passiveSkillAList then
        table.insert(luaPassiveSkillNodeList, passiveSkillAList)
    end
    if passiveSkillBList then
        table.insert(luaPassiveSkillNodeList, passiveSkillBList)
    end
    local highestA = passiveSkillAList[1]
    for i, passiveSkillNodeCfg in ipairs(passiveSkillAList) do
        local isActive = CharInfoUtils.getPassiveSkillNodeStatus(charInst.instId, passiveSkillNodeCfg.nodeId)
        if isActive then
            highestA = passiveSkillNodeCfg
        end
    end
    local highestB = passiveSkillBList[1]
    for i, passiveSkillNodeCfg in ipairs(passiveSkillBList) do
        local isActive = CharInfoUtils.getPassiveSkillNodeStatus(charInst.instId, passiveSkillNodeCfg.nodeId)
        if isActive then
            highestB = passiveSkillNodeCfg
        end
    end
    local highestList = {}
    table.insert(highestList, highestA)
    table.insert(highestList, highestB)
    self.m_passiveSkillCellCache:Refresh(#highestList, function(cell, index)
        local passiveSkillNodeCfg = highestList[index]
        local isActive = CharInfoUtils.getPassiveSkillNodeStatus(charInst.instId, passiveSkillNodeCfg.nodeId)
        cell.stageLevelCellGroup:InitStageLevelCellGroupByPassiveNodeList(charInst.instId, luaPassiveSkillNodeList[index], true)
        cell.name.text = passiveSkillNodeCfg.passiveSkillNodeInfo.name
        cell.lockIcon.gameObject:SetActive(not isActive)
        cell.icon.gameObject:SetActive(isActive)
        cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_SKILL_ICON, passiveSkillNodeCfg.passiveSkillNodeInfo.iconId)
        cell.name.color = isActive and self.view.config.TEXT_COLOR_DEFAULT or self.view.config.TEXT_COLOR_LOCK
        cell.button.onClick:RemoveAllListeners()
        cell.button.onClick:AddListener(function()
            Notify(MessageConst.SHOW_CHAR_SKILL_TIP, { isPassiveSkill = true, skillId = passiveSkillNodeCfg.passiveSkillNodeInfo.index, skillLevel = passiveSkillNodeCfg.passiveSkillNodeInfo.level, charInstId = charInstId, transform = tipsNode or cell.showTipTransform, isSingleChar = isSingleChar, hideBtnUpgrade = hideBtnUpgrade, tipPosType = tipPosType, isLock = not isActive, cell = cell, })
        end)
    end)
end
HL.Commit(CharPassiveSkillNode)
return CharPassiveSkillNode