local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
CharSkillNodeNew = HL.Class('CharSkillNodeNew', UIWidgetBase)
CharSkillNodeNew.m_skillCells = HL.Field(HL.Forward("UIListCache"))
CharSkillNodeNew.m_lastSelectIndex = HL.Field(HL.Number) << -1
CharSkillNodeNew._OnFirstTimeInit = HL.Override() << function(self)
    self.m_skillCells = UIUtils.genCellCache(self.view.skillCell)
    self.m_lastSelectIndex = -1
end
CharSkillNodeNew.InitCharSkillNodeNew = HL.Method(HL.Number, HL.Opt(HL.Boolean, HL.Boolean, CS.UnityEngine.Transform, HL.Number)) << function(self, charInstId, isSingleChar, hideBtnUpgrade, tipsNode, tipPosType)
    self:_FirstTimeInit()
    local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
    self.m_skillCells:Refresh(#UIConst.CHAR_INFO_SKILL_SHOW_ORDER, function(cell, luaIndex)
        local skillGroupType = UIConst.CHAR_INFO_SKILL_SHOW_ORDER[luaIndex]
        cell:InitCharInfoSkillButtonNew(charInst, skillGroupType, function()
            Notify(MessageConst.SHOW_CHAR_SKILL_TIP, { skillGroupType = skillGroupType, charInstId = charInstId, transform = tipsNode or cell.view.showTipTransform, isSingleChar = isSingleChar, hideBtnUpgrade = hideBtnUpgrade, tipPosType = tipPosType, cell = cell, })
        end)
    end)
end
CharSkillNodeNew.RefreshSkillSelect = HL.Method(HL.Opt(HL.Number)) << function(self, selectIndex)
    local count = self.m_skillCells:GetCount()
    for i = 1, count do
        local cell = self.m_skillCells:GetItem(i)
        cell:SetSelect(selectIndex == i)
    end
end
HL.Commit(CharSkillNodeNew)
return CharSkillNodeNew