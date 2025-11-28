local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
TeamCell = HL.Class('TeamCell', UIWidgetBase)
TeamCell.index = HL.Field(HL.Number) << -1
TeamCell.data = HL.Field(HL.Table)
TeamCell._OnFirstTimeInit = HL.Override() << function(self)
end
TeamCell.InitTeamCell = HL.Method(HL.Any, HL.Opt(HL.Function)) << function(self, data, onClickItem)
    self:_FirstTimeInit()
    self.index = data.index
    self.data = data
    self:SetSelect(false)
    if self.view.buttonSelect then
        self.view.buttonSelect.onClick:RemoveAllListeners()
        self.view.buttonSelect.onClick:AddListener(function()
            if onClickItem then
                onClickItem()
            end
        end)
    end
end
TeamCell.SetSelect = HL.Method(HL.Boolean) << function(self, select)
    self.view.imageTabSelect.gameObject:SetActive(select)
end
HL.Commit(TeamCell)
return TeamCell