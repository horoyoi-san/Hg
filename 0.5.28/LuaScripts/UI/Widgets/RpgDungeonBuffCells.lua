local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
RpgDungeonBuffCells = HL.Class('RpgDungeonBuffCells', UIWidgetBase)
RpgDungeonBuffCells.m_updateTickKey = HL.Field(HL.Number) << -1
RpgDungeonBuffCells._OnFirstTimeInit = HL.Override() << function(self)
end
RpgDungeonBuffCells._OnDestroy = HL.Override() << function(self)
    if self.m_updateTickKey > 0 then
        LuaUpdate:Remove(self.m_updateTickKey)
    end
    self.m_updateTickKey = -1
end
RpgDungeonBuffCells.InitRpgDungeonBuffCells = HL.Method(HL.Table, HL.Forward("RpgDungeonMainHudCtrl")) << function(self, buffData, rpgHudCtl)
    self:_FirstTimeInit()
    if self.m_updateTickKey > 0 then
        LuaUpdate:Remove(self.m_updateTickKey)
    end
    self.view.buffName.text = UIUtils.resolveTextStyle(buffData.buffName)
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
            self.view.rpgDungeonBuffIcon.view.cdImage.fillAmount = left / duration
            self.view.countdownTxt.text = string.format(Language.LUA_RPG_DUNGEON_ABILITY_COUNTDOWN_FORMAT, math.floor(left))
        end)
    else
        self.view.rpgDungeonBuffIcon.view.cdImage.fillAmount = 1
        self.view.countdownTxt.text = "~"
    end
end
HL.Commit(RpgDungeonBuffCells)
return RpgDungeonBuffCells