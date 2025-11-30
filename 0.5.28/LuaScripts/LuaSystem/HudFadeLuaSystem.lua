local LuaSystemBase = require_ex('LuaSystem/LuaSystemBase')
HudFadeLuaSystem = HL.Class('HudFadeLuaSystem', LuaSystemBase.LuaSystemBase)
HudFadeLuaSystem.HudFadeLuaSystem = HL.Constructor() << function(self)
    self:RegisterMessage(MessageConst.ON_SQUAD_INFIGHT_CHANGED, function(args)
        local inFight = unpack(args)
        self:ToggleHudFade("inFight", inFight)
    end)
    self:RegisterMessage(MessageConst.ON_FAC_MODE_CHANGE, function(toFactoryMode)
        self:ToggleHudFade("facMode", toFactoryMode)
    end)
    self:RegisterMessage(MessageConst.ON_LOCK_TARGET_CHANGED, function(args)
        local lockTarget = unpack(args)
        self:ToggleHudFade("lockTarget", lockTarget ~= nil)
    end)
    self:RegisterMessage(MessageConst.START_GUIDE_GROUP, function(args)
        self:ToggleHudFade("guide", true)
    end)
    self:RegisterMessage(MessageConst.ON_COMPLETE_GUIDE_GROUP, function(args)
        self:ToggleHudFade("guide", false)
    end)
    self:RegisterMessage(MessageConst.ON_TOGGLE_HUD_FADE, function(args)
        local key, showHud = unpack(args)
        self:ToggleHudFade(key, showHud)
    end)
    self.m_hudPreventFadeState = {}
end
HudFadeLuaSystem.OnInit = HL.Override() << function(self)
    self.m_needFade = true
    self.m_inFade = false
    if Unity.PlayerPrefs.GetInt("DebugHudFade", 0) == 0 then
        self:ToggleHudFade("debug", true)
    end
    if DeviceInfo.isMobile then
        self:ToggleHudFade("mobile", true)
    end
end
HudFadeLuaSystem.OnRelease = HL.Override() << function(self)
end
HudFadeLuaSystem.m_needFade = HL.Field(HL.Boolean) << false
HudFadeLuaSystem.m_inFade = HL.Field(HL.Boolean) << false
HudFadeLuaSystem.m_fadeTimer = HL.Field(HL.Number) << -1
HudFadeLuaSystem.m_hudPreventFadeState = HL.Field(HL.Table)
HudFadeLuaSystem.ToggleHudFade = HL.Method(HL.String, HL.Boolean) << function(self, key, showHud)
    if showHud then
        self.m_hudPreventFadeState[key] = true
    else
        self.m_hudPreventFadeState[key] = nil
    end
    local prevNeedFade = self.m_needFade
    self.m_needFade = (next(self.m_hudPreventFadeState) == nil)
    if prevNeedFade ~= self.m_needFade then
        if self.m_needFade then
            self:_StartFadeTimer()
        else
            self.m_inFade = false
            Notify(MessageConst.ON_FADE_HUD, false)
            self.m_fadeTimer = self:_ClearTimer(self.m_fadeTimer)
        end
    end
end
HudFadeLuaSystem._StartFadeTimer = HL.Method() << function(self)
    self.m_fadeTimer = self:_StartTimer(DataManager.gameplayMiscSetting.hudFadeDelay, function()
        self.m_inFade = true
        Notify(MessageConst.ON_FADE_HUD, true)
        self:_ClearTimer(self.m_fadeTimer)
    end)
end
HL.Commit(HudFadeLuaSystem)
return HudFadeLuaSystem