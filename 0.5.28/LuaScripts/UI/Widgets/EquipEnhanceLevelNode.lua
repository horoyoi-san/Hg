local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
EquipEnhanceLevelNode = HL.Class('EquipEnhanceLevelNode', UIWidgetBase)
EquipEnhanceLevelNode.m_levelCellCache = HL.Field(HL.Forward("UIListCache"))
EquipEnhanceLevelNode._OnFirstTimeInit = HL.Override() << function(self)
    self.m_levelCellCache = UIUtils.genCellCache(self.view.lvDotCell)
end
EquipEnhanceLevelNode.InitEquipEnhanceLevelNode = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    self.view.enhanceNode:InitEquipEnhanceNode(args)
    local enhancedLevel, maxEnhanceLevel = self.view.enhanceNode:GetEnhanceLevel()
    self.m_levelCellCache:Refresh(maxEnhanceLevel, function(cell, luaIndex)
        local color = luaIndex < enhancedLevel and self.config.COLOR_ENHANCED or self.config.COLOR_NORMAL
        if luaIndex == enhancedLevel then
            color = args.showNextLevel and self.config.COLOR_NEXT_ENHANCED or self.config.COLOR_ENHANCED
        end
        cell.imgDot.color = color
    end)
end
HL.Commit(EquipEnhanceLevelNode)
return EquipEnhanceLevelNode