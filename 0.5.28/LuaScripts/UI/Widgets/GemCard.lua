local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
GemCard = HL.Class('GemCard', UIWidgetBase)
GemCard.m_starCellCache = HL.Field(HL.Forward("UIListCache"))
GemCard._OnFirstTimeInit = HL.Override() << function(self)
    self.m_starCellCache = UIUtils.genCellCache(self.view.starCell)
end
GemCard.InitGemCard = HL.Method(HL.Number, HL.Opt(HL.Number)) << function(self, gemInstId, tryWeaponInstId)
    self:_FirstTimeInit()
    if not gemInstId or gemInstId <= 0 then
        return
    end
    self:_RefreshBasicInfo(gemInstId)
    self.view.gemSkillNode:InitGemSkillNode(gemInstId, { weaponInstId = tryWeaponInstId })
end
GemCard._RefreshBasicInfo = HL.Method(HL.Number) << function(self, gemInstId)
    local gemInst = CharInfoUtils.getGemByInstId(gemInstId)
    local gemItemCfg = Tables.itemTable:GetValue(gemInst.templateId)
    local gemName = gemItemCfg.name
    self.view.gemName.text = UIUtils.getItemName(gemInst.templateId, gemInst.instId)
    self.view.gemItemIcon:InitItemIcon(gemInst.templateId, false, gemInst.instId)
    self.view.lockToggle:InitLockToggle(gemInst.templateId, gemInst.instId)
    UIUtils.setItemRarityImage(self.view.bgColor, gemItemCfg.rarity)
    UIUtils.setItemRarityImage(self.view.titleColor, gemItemCfg.rarity)
    self.m_starCellCache:Refresh(gemItemCfg.rarity)
end
HL.Commit(GemCard)
return GemCard