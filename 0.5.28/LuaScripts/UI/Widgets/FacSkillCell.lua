local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
FacSkillCell = HL.Class('FacSkillCell', UIWidgetBase)
FacSkillCell._OnFirstTimeInit = HL.Override() << function(self)
end
FacSkillCell.InitFacSkillCell = HL.Method(HL.String, HL.Opt(HL.Boolean)) << function(self, skillId, showBuffIcon)
    self:_FirstTimeInit()
    local skillData = Tables.factorySkillTable:GetValue(skillId)
    self.view.skillIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_SKILL_ICON, skillData.icon)
    self.view.skillName.text = skillData.name
    local skillDesc = GameInstance.player.facCharacterSystem:GetSkillDesc(skillId)
    self.view.skillDesc.text = UIUtils.resolveTextStyle(skillDesc)
    self.view.buffNode.gameObject:SetActive(showBuffIcon)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.topInfo.transform)
end
HL.Commit(FacSkillCell)
return FacSkillCell