LuaSystemManager = HL.Class('LuaSystemManager')
LuaSystemManager.facSystem = HL.Field(HL.Forward('FacLuaSystem'))
LuaSystemManager.mainHudToastSystem = HL.Field(HL.Forward('MainHudToastSystem'))
LuaSystemManager.audioEventSystem = HL.Field(HL.Forward('AudioEventLuaSystem'))
LuaSystemManager.hudFadeSystem = HL.Field(HL.Forward('HudFadeLuaSystem'))
LuaSystemManager.commonIntTriggerSystem = HL.Field(HL.Forward('CommonIntTriggerSystem'))
LuaSystemManager.gachaSystem = HL.Field(HL.Forward('GachaSystem'))
LuaSystemManager.levelWorldUISystem = HL.Field(HL.Forward('LevelWorldUISystem'))
LuaSystemManager.loginCheckSystem = HL.Field(HL.Forward('LoginCheckSystem'))
LuaSystemManager.commonTaskTrackSystem = HL.Field(HL.Forward('CommonTaskTrackSystem'))
LuaSystemManager.InitSystems = HL.Method() << function(self)
    logger.info("LuaSystemManager.InitSystems")
    self.facSystem = self:_AddSystem("FacLuaSystem")
    self.audioEventSystem = self:_AddSystem("AudioEventLuaSystem")
    self.hudFadeSystem = self:_AddSystem("HudFadeLuaSystem")
    self.commonIntTriggerSystem = self:_AddSystem("CommonIntTriggerSystem")
    self.mainHudToastSystem = self:_AddSystem("MainHudToastSystem")
    self.gachaSystem = self:_AddSystem("GachaSystem")
    self.levelWorldUISystem = self:_AddSystem("LevelWorldUISystem")
    self.loginCheckSystem = self:_AddSystem("LoginCheckSystem")
    self.commonTaskTrackSystem = self:_AddSystem("CommonTaskTrackSystem")
end
LuaSystemManager.LuaSystemManager = HL.Constructor() << function(self)
    Register(MessageConst.INIT_LUA_SYSTEM_MANAGER, function(arg)
        self:InitSystems()
    end, self)
    Register(MessageConst.RELEASE_LUA_SYSTEM_MANAGER, function(arg)
        self:ReleaseSystems()
    end, self)
    self.m_systemList = {}
end
LuaSystemManager.m_systemList = HL.Field(HL.Table)
LuaSystemManager._AddSystem = HL.Method(HL.String).Return(HL.Forward('LuaSystemBase')) << function(self, systemName)
    local class = require_ex("LuaSystem/" .. systemName)
    local system = class()
    table.insert(self.m_systemList, system)
    system:OnInit()
    return system
end
LuaSystemManager.ReleaseSystems = HL.Method() << function(self)
    logger.info("LuaSystemManager.ReleaseSystems")
    for k = #self.m_systemList, 1, -1 do
        local v = self.m_systemList[k]
        v:OnRelease()
        v:Clear()
    end
    self.m_systemList = {}
end
HL.Commit(LuaSystemManager)
return LuaSystemManager