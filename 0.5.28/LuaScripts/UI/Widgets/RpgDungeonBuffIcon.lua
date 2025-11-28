local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
RpgDungeonBuffIcon = HL.Class('RpgDungeonBuffIcon', UIWidgetBase)
RpgDungeonBuffIcon.m_updateTickKey = HL.Field(HL.Number) << -1
RpgDungeonBuffIcon._OnFirstTimeInit = HL.Override() << function(self)
end
RpgDungeonBuffIcon._OnDestroy = HL.Override() << function(self)
    if self.m_updateTickKey > 0 then
        LuaUpdate:Remove(self.m_updateTickKey)
    end
    self.m_updateTickKey = -1
end
RpgDungeonBuffIcon.InitRpgDungeonBuffIcon = HL.Method(HL.Table, HL.Forward("RpgDungeonMainHudCtrl")) << function(self, buffData, rpgHudCtl)
    self:_FirstTimeInit()
    if self.m_updateTickKey > 0 then
        LuaUpdate:Remove(self.m_updateTickKey)
    end
    if buffData.buffCountdown > 0 then
        local countdownMgr = GameInstance.player.countdownManager
        local duration = buffData.buffCountdown
        local countdownId = rpgHudCtl:GetBuffCountdownIdByLevel(buffData.buffOwnLevel)
        if not countdownId then
            countdownId = countdownMgr:NewCountdown(duration, function()
            end)
            rpgHudCtl:AddBuffCountdownId(buffData.buffOwnLevel, countdownId)
        end
        self.m_updateTickKey = LuaUpdate:Add("Tick", function()
            local left = countdownMgr:GetCountdown(countdownId)
            self.view.cdImage.fillAmount = left / duration
        end)
    else
        self.view.cdImage.fillAmount = 1
    end
end
HL.Commit(RpgDungeonBuffIcon)
return RpgDungeonBuffIcon