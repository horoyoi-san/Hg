local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
EquipEnhanceNode = HL.Class('EquipEnhanceNode', UIWidgetBase)
EquipEnhanceNode.m_enhancedLevel = HL.Field(HL.Number) << 0
EquipEnhanceNode.m_maxEnhancedLevel = HL.Field(HL.Number) << 0
EquipEnhanceNode._OnFirstTimeInit = HL.Override() << function(self)
end
EquipEnhanceNode.InitEquipEnhanceNode = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    local equipInstData = EquipTechUtils.getEquipInstData(args.equipInstId)
    if not equipInstData or not EquipTechUtils.canEquipEnhance(equipInstData.templateId) or not Utils.isSystemUnlocked(GEnums.UnlockSystemType.EquipEnhance) then
        self.view.gameObject:SetActive(false)
        return
    end
    self.view.gameObject:SetActiveIfNecessary(true)
    local equipData = Tables.equipTable[equipInstData.templateId]
    local attrMaxEnhanceLevel = #Tables.equipConst.defaultEnhancedRatio
    if args.attrIndex ~= nil then
        self.m_enhancedLevel = equipInstData:GetAttrEnhanceLevel(args.attrIndex)
        self.m_maxEnhancedLevel = attrMaxEnhanceLevel
    else
        self.m_enhancedLevel = equipInstData:GetEnhanceLevel()
        self.m_maxEnhancedLevel = #equipData.displayAttrModifiers * attrMaxEnhanceLevel
    end
    if args.showNextLevel then
        self.m_enhancedLevel = self.m_enhancedLevel + 1
    end
    local isMaxEnhanced = self.m_enhancedLevel >= self.m_maxEnhancedLevel
    local isEnhanced = self.m_enhancedLevel > 0
    self.view.enhanced.gameObject:SetActive(isEnhanced and not isMaxEnhanced)
    self.view.img.color = isMaxEnhanced and self.config.COLOR_ENHANCED or self.config.COLOR_NORMAL
end
EquipEnhanceNode.GetEnhanceLevel = HL.Method().Return(HL.Number, HL.Number) << function(self)
    return self.m_enhancedLevel, self.m_maxEnhancedLevel
end
HL.Commit(EquipEnhanceNode)
return EquipEnhanceNode