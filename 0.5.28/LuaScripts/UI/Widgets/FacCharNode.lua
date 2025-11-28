local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
FacCharNode = HL.Class('FacCharNode', UIWidgetBase)
FacCharNode.m_charCells = HL.Field(HL.Forward('UIListCache'))
FacCharNode.m_nodeId = HL.Field(HL.Number) << 0
FacCharNode.m_buildingId = HL.Field(HL.String) << ""
FacCharNode.m_system = HL.Field(CS.Beyond.Gameplay.FacCharacterSystem)
FacCharNode.m_node = HL.Field(CS.Beyond.Gameplay.FacSpMachineSystem.SpNodeBase)
FacCharNode._OnFirstTimeInit = HL.Override() << function(self)
    self.m_charCells = UIUtils.genCellCache(self.view.charCell)
end
FacCharNode.InitFacCharNode = HL.Method(HL.Number, HL.Opt(HL.Table, HL.Table)) << function(self, nodeId, charList, removeCharList)
    self:_FirstTimeInit()
    self.m_nodeId = nodeId
    self.m_node = GameInstance.player.facSpMachineSystem:GetNode(nodeId)
    self.m_buildingId = FactoryUtils.getBuildingNodeHandler(nodeId).templateId
    self.m_system = GameInstance.player.facCharacterSystem
    if self.m_node == nil then
        return
    end
    local soltCount = self.m_system:GetCharSoltCount(self.m_buildingId, self.m_node.level)
    self.view.maxCount.text = string.format("/%d", soltCount)
    self.view.curCount.text = string.format("%d", self:_GetCurCharCount())
    local buildingData = Tables.factoryBuildingTable:GetValue(self.m_buildingId)
    self.view.buildingIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_BUILDING_PANEL_ICON, buildingData.iconOnPanel)
    self.view.buildingName.text = buildingData.name
    if not charList then
        local characterList = self.m_system:GetCharList(self.m_nodeId)
        charList = {}
        for i = 1, characterList.Count do
            table.insert(charList, characterList[CSIndex(i)])
        end
    end
    self.m_charCells:Refresh(FacConst.FAC_CHARACTER_MAX_SOLT_NUM, function(cell, index)
        if index <= #charList then
            local charId = charList[index]
            if not string.isEmpty(charId) then
                local spriteName = UIConst.UI_CHAR_HEAD_PREFIX .. charId
                cell.charIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD, spriteName)
                if not cell.skillCells then
                    cell.skillCells = UIUtils.genCellCache(cell.skillCell)
                end
                local skills = self.m_system:GetActiveSkill(charId, self.m_nodeId)
                cell.skillCells:Refresh(skills.Count, function(skillCell, skillIndex)
                    local skillId = skills[CSIndex(skillIndex)]
                    local skillData = Tables.factorySkillTable:GetValue(skillId)
                    skillCell.image.sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_SKILL_ICON, skillData.icon)
                end)
                cell.remove.gameObject:SetActiveIfNecessary(self:_IsRemoveChar(charId, removeCharList))
                cell.normal.gameObject:SetActiveIfNecessary(true)
                cell.empty.gameObject:SetActiveIfNecessary(false)
                cell.forbid.gameObject:SetActiveIfNecessary(false)
            else
                cell.normal.gameObject:SetActiveIfNecessary(false)
                cell.empty.gameObject:SetActiveIfNecessary(true)
                cell.forbid.gameObject:SetActiveIfNecessary(false)
            end
        else
            cell.normal.gameObject:SetActiveIfNecessary(false)
            cell.empty.gameObject:SetActiveIfNecessary(false)
            cell.forbid.gameObject:SetActiveIfNecessary(true)
        end
    end)
end
FacCharNode._IsRemoveChar = HL.Method(HL.String, HL.Table).Return(HL.Boolean) << function(self, charId, removeCharList)
    if not removeCharList then
        return false
    end
    if string.isEmpty(charId) then
        return false
    end
    for i = 1, #removeCharList do
        if charId == removeCharList[i] then
            return true
        end
    end
    return false
end
FacCharNode._GetCurCharCount = HL.Method().Return(HL.Number) << function(self)
    local count = 0
    local characterList = self.m_system:GetCharList(self.m_nodeId)
    for i = 1, characterList.Count do
        if not string.isEmpty(characterList[CSIndex(i)]) then
            count = count + 1
        end
    end
    return count
end
HL.Commit(FacCharNode)
return FacCharNode