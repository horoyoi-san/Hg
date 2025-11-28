local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
RacingEffectCell = HL.Class('RacingEffectCell', UIWidgetBase)
RacingEffectCell._OnFirstTimeInit = HL.Override() << function(self)
end
RacingEffectCell.InitRacingEffectCell = HL.Method(HL.String, HL.Number) << function(self, buffId, layer)
    self:_FirstTimeInit()
    local found, data = Tables.racingInterTable:TryGetValue(buffId)
    if not found then
        return
    end
    self.view.icon.sprite = self:LoadSprite("RacingEffectIcon", data.icon)
    self.view.nameText.text = data.name
    self.view.numberText.text = "×" .. layer
    self.view.infoText.text = UIUtils.resolveTextStyle(GameInstance.player.racingDungeonSystem:GetRacingBuffDescription(buffId, layer))
end
HL.Commit(RacingEffectCell)
return RacingEffectCell