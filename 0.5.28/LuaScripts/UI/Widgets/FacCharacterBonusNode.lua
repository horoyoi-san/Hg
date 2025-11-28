local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
FacCharacterBonusNode = HL.Class('FacCharacterBonusNode', UIWidgetBase)
FacCharacterBonusNode.m_nodeId = HL.Field(HL.Number) << 0
FacCharacterBonusNode.m_buildingId = HL.Field(HL.String) << ""
FacCharacterBonusNode.m_system = HL.Field(CS.Beyond.Gameplay.FacCharacterSystem)
FacCharacterBonusNode.m_skillCells = HL.Field(HL.Forward('UIListCache'))
FacCharacterBonusNode.m_skillInfoList = HL.Field(HL.Table)
FacCharacterBonusNode._OnFirstTimeInit = HL.Override() << function(self)
    self.m_skillCells = UIUtils.genCellCache(self.view.skillCell)
    self:ToggleContent(false)
    self.view.btn.onClick:AddListener(function()
        self:ToggleContent(true)
    end)
    self.view.mask.onClick:AddListener(function()
        self:ToggleContent(false)
    end)
end
FacCharacterBonusNode.InitFacCharacterBonusNode = HL.Method(HL.Number) << function(self, nodeId)
    self:_FirstTimeInit()
    self.m_nodeId = nodeId
    local buildingId = FactoryUtils.getBuildingNodeHandler(nodeId).templateId
    self.m_buildingId = buildingId
    self.m_system = GameInstance.player.facCharacterSystem
    local haveBuff = self.m_system:HaveBuildingBuff(self.m_buildingId)
    self.gameObject:SetActive(haveBuff)
    if not haveBuff then
        return
    end
    local skillInfoList = {}
    local charList = self.m_system:GatFacSkillCharacter(nodeId)
    for i = 1, charList.Count do
        local charId = charList[CSIndex(i)]
        local skillList = self.m_system:GetSkillEffectBuilding(charId, buildingId)
        for j = 1, skillList.Count do
            local skillId = skillList[CSIndex(j)]
            table.insert(skillInfoList, { charId = charId, skillId = skillId, })
        end
    end
    self.m_skillInfoList = skillInfoList
    self.m_skillCells:Refresh(#skillInfoList, function(cell, index)
        self:_UpdateCell(cell, index)
    end)
end
FacCharacterBonusNode.ToggleContent = HL.Method(HL.Boolean) << function(self, active)
    self.view.skillNode.gameObject:SetActiveIfNecessary(active)
end
FacCharacterBonusNode._UpdateCell = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local skillInfo = self.m_skillInfoList[index]
    local charId = skillInfo.charId
    local skillId = skillInfo.skillId
    local charData = Tables.characterTable:GetValue(charId)
    local skillData = Tables.factorySkillTable:GetValue(skillId)
    local spriteName = UIConst.UI_CHAR_HEAD_PREFIX .. charId
    local skillDesc = GameInstance.player.facCharacterSystem:GetSkillDesc(skillId)
    cell.charIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD, spriteName)
    cell.charName.text = charData.name
    cell.skillDesc.text = UIUtils.resolveTextStyle(skillDesc)
    cell.skillIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_SKILL_ICON, skillData.icon)
    cell.skillName.text = string.format(Language.LUA_FAC_BUFF_SKILL_NAME, skillData.name)
end
HL.Commit(FacCharacterBonusNode)
return FacCharacterBonusNode