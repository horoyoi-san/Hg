local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
DungeonCategoryCell = HL.Class('DungeonCategoryCell', UIWidgetBase)
DungeonCategoryCell.m_genDungeonCells = HL.Field(HL.Forward("UIListCache"))
DungeonCategoryCell.m_dungeonInfos = HL.Field(HL.Table)
DungeonCategoryCell._OnFirstTimeInit = HL.Override() << function(self)
    self.m_genDungeonCells = UIUtils.genCellCache(self.view.dungeonCell)
end
DungeonCategoryCell.InitDungeonCategoryCell = HL.Method(HL.Table) << function(self, infosBundle)
    self:_FirstTimeInit()
    infosBundle.hasRead = true
    self.m_dungeonInfos = infosBundle.infos
    local category2ndType = GEnums.DungeonCategory2ndType.__CastFrom(infosBundle.category2ndType)
    if (category2ndType == GEnums.DungeonCategory2ndType.None) then
        self.view.titleState:SetState("HideTitle")
    else
        self.view.titleState:SetState("ShowTitle")
        self.view.titleTxt.text = infosBundle.name
    end
    self.m_genDungeonCells:Refresh(#self.m_dungeonInfos, function(cell, luaIndex)
        local cellInfo = self.m_dungeonInfos[luaIndex]
        cell:InitAdventureDungeonCell(cellInfo)
        cellInfo.hasRead = true
    end)
end
HL.Commit(DungeonCategoryCell)
return DungeonCategoryCell