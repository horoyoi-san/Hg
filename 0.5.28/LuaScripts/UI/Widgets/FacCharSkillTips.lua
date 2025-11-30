local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
FacCharSkillTips = HL.Class('FacCharSkillTips', UIWidgetBase)
FacCharSkillTips.m_skillCells = HL.Field(HL.Forward('UIListCache'))
FacCharSkillTips.m_onClose = HL.Field(HL.Function)
FacCharSkillTips._OnFirstTimeInit = HL.Override() << function(self)
    self.m_skillCells = UIUtils.genCellCache(self.view.skillCell)
    self:BindInputPlayerAction("common_cancel", function()
        self:ClickClose()
    end)
end
FacCharSkillTips.InitFacCharSkillTips = HL.Method(HL.String, HL.Number, HL.Function) << function(self, charId, nodeId, onClose)
    self:_FirstTimeInit()
    self.m_onClose = onClose
    local charData = Tables.characterTable:GetValue(charId)
    local spriteName = UIConst.UI_CHAR_HEAD_PREFIX .. charId
    self.view.charIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD, spriteName)
    self.view.charName.text = charData.name
    local skills = GameInstance.player.facCharacterSystem:GetCharCurSkill(charId)
    self.m_skillCells:Refresh(skills.Count, function(skillCell, skillIndex)
        local skillId = skills[CSIndex(skillIndex)]
        local buildingId = GameInstance.player.facCharacterSystem:GetBuildingId(nodeId)
        local skillData = Tables.factorySkillTable:GetValue(skillId)
        local buildingType = Tables.factoryBuildingTable[buildingId].type
        skillCell:InitFacSkillCell(skillId, skillData.buildingType == buildingType)
    end)
    local charInfo = GameInstance.player.facCharacterSystem:GetFacCharInfo(charId)
    if charInfo then
        self.view.stateTxt.text = Language.LUA_FAC_CHAR_SKILL_STATE_2
    else
        self.view.stateTxt.text = Language.LUA_FAC_CHAR_SKILL_STATE_1
    end
end
FacCharSkillTips.ClickClose = HL.Method() << function(self)
    if self.gameObject.activeSelf then
        self.view.animationWrapper:PlayOutAnimation(function()
            self.gameObject:SetActiveIfNecessary(false)
            if self.m_onClose then
                self.m_onClose()
            end
        end)
    end
end
HL.Commit(FacCharSkillTips)
return FacCharSkillTips