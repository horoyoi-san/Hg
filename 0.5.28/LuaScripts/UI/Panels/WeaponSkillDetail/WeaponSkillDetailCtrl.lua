local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.WeaponSkillDetail
WeaponSkillDetailCtrl = HL.Class('WeaponSkillDetailCtrl', uiCtrl.UICtrl)
WeaponSkillDetailCtrl.s_messages = HL.StaticField(HL.Table) << {}
WeaponSkillDetailCtrl.m_skillNodeCellCache = HL.Field(HL.Forward("UIListCache"))
WeaponSkillDetailCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    local weaponInstId = args.weaponInstId
    self:_InitActionEvent()
    local weaponInst = CharInfoUtils.getWeaponByInstId(weaponInstId)
    local _, itemCfg = Tables.itemTable:TryGetValue(weaponInst.templateId)
    local _, fromSkillLevelInfoList = CS.Beyond.Gameplay.WeaponUtil.TryGetWeaponSkillIdAndLevel(Utils.getCurrentScope(), weaponInstId, 0, weaponInst.breakthroughLv, weaponInst.refineLv)
    local _, toSkillLevelInfoList = CS.Beyond.Gameplay.WeaponUtil.TryGetWeaponSkillIdAndLevel(Utils.getCurrentScope(), weaponInstId, weaponInst.attachedGemInstId, weaponInst.breakthroughLv, weaponInst.refineLv)
    self.view.titleTxt.text = string.format(Language.LUA_WEAPON_EXHIBIT_FULL_SKILL_TITLE, itemCfg.name)
    self.m_skillNodeCellCache:Refresh(3, function(cell, index)
        if index > toSkillLevelInfoList.Count then
            cell.skillScrollRect.gameObject:SetActive(false)
            cell.weaponInfoSkillAttributeCell.gameObject:SetActive(false)
            cell.emptyState.gameObject:SetActive(true)
            return
        end
        cell.emptyState.gameObject:SetActive(false)
        local fromSkillLevelInfo = fromSkillLevelInfoList[CSIndex(index)]
        local toSkillLevelInfo = toSkillLevelInfoList[CSIndex(index)]
        cell.bgSingle.gameObject:SetActive(index % 2 == 1)
        cell.bgPlural.gameObject:SetActive(index % 2 == 0)
        cell.weaponInfoSkillAttributeCell:InitWeaponSkillCell(toSkillLevelInfo, fromSkillLevelInfo, "")
        if cell.descCellCache == nil then
            cell.descCellCache = UIUtils.genCellCache(cell.descCell)
        end
        cell.descCellCache:Refresh(Tables.characterConst.maxWeaponSkillLevel, function(descCell, index)
            local _, skillName, skillDesc = CS.Beyond.Gameplay.WeaponUtil.GetSkillNameAndDescriptionFromSkillId(toSkillLevelInfo.skillId, index)
            descCell.level.text = index
            descCell.desc.text = UIUtils.resolveTextStyle(skillDesc)
            if index == toSkillLevelInfo.level then
                descCell.desc.color = self.view.config.TEXT_COLOR_ACTIVE
            else
                descCell.desc.color = self.view.config.TEXT_COLOR_DEFAULT
            end
            local isCurLevel = index == toSkillLevelInfo.level
            local cellColor = isCurLevel and self.view.config.LEVEL_COLOR_CURRENT or self.view.config.LEVEL_COLOR_DEFAULT
            descCell.leftArrow.gameObject:SetActive(isCurLevel)
            descCell.leftArrow.color = cellColor
            descCell.stageDeco.color = cellColor
            descCell.rankTitle.color = cellColor
            descCell.level.color = cellColor
        end)
    end)
end
WeaponSkillDetailCtrl._InitActionEvent = HL.Method() << function(self)
    self.view.btnClose.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.m_skillNodeCellCache = UIUtils.genCellCache(self.view.skillNode)
end
HL.Commit(WeaponSkillDetailCtrl)