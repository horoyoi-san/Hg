local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
MainHudRacingEffectBtn = HL.Class('MainHudRacingEffectBtn', UIWidgetBase)
MainHudRacingEffectBtn.m_lateTickKey = HL.Field(HL.Number) << -1
MainHudRacingEffectBtn.m_remainFloatingTime = HL.Field(HL.Number) << 0
MainHudRacingEffectBtn._OnFirstTimeInit = HL.Override() << function(self)
end
MainHudRacingEffectBtn.InitMainHudRacingEffectBtn = HL.Method() << function(self)
    self:_FirstTimeInit()
end
MainHudRacingEffectBtn.OnShow = HL.Method() << function(self)
    self.view.floatingIcon.gameObject:SetActiveIfNecessary(false)
end
MainHudRacingEffectBtn.OnHide = HL.Method() << function(self)
    self.view.floatingIcon.gameObject:SetActiveIfNecessary(false)
    LuaUpdate:Remove(self.m_lateTickKey)
    self.m_lateTickKey = -1
end
local noEffectBuff = { ["race_item_1"] = true, ["race_item_2"] = true }
MainHudRacingEffectBtn.CanPlayEffect = HL.Method(HL.String).Return(HL.Boolean) << function(self, buffId)
    return not noEffectBuff[buffId]
end
MainHudRacingEffectBtn.OnShowRacingDungeonObtainBuff = HL.Method(HL.Table) << function(self, args)
    local buffId, worldPos = unpack(args)
    if noEffectBuff[buffId] then
        return
    end
    local found, data = Tables.racingInterTable:TryGetValue(buffId)
    if not found then
        return
    end
    self.view.floatingIcon.sprite = self:LoadSprite("RacingEffectIcon", data.icon)
    self.view.floatingIcon.gameObject:SetActiveIfNecessary(true)
    local screenPos = CameraManager.mainCamera:WorldToScreenPoint(worldPos):XY()
    local _, pos = Unity.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.view.floatingIcon.transform.parent, screenPos, self:GetLuaPanel().uiCamera)
    self.view.floatingIcon.transform.localPosition = Vector3(pos.x, pos.y, 0)
    LuaUpdate:Remove(self.m_lateTickKey)
    self.m_lateTickKey = LuaUpdate:Add("LateTick", function(deltaTime)
        self:_Update(deltaTime)
    end)
    self.m_remainFloatingTime = self.config.FLOATING_TIME
    self:_Update(0)
end
MainHudRacingEffectBtn._Update = HL.Method(HL.Number) << function(self, deltaTime)
    self.m_remainFloatingTime = self.m_remainFloatingTime - deltaTime
    if self.m_remainFloatingTime <= 0 then
        self.view.floatingIcon.gameObject:SetActiveIfNecessary(false)
        LuaUpdate:Remove(self.m_lateTickKey)
        self.m_lateTickKey = -1
        return
    end
    local localPosition = self.view.floatingIcon.transform.localPosition
    self.view.floatingIcon.transform.localPosition = Vector3(localPosition.x - localPosition.x / self.m_remainFloatingTime * deltaTime, localPosition.y - localPosition.y / self.m_remainFloatingTime * deltaTime, 0)
end
HL.Commit(MainHudRacingEffectBtn)
return MainHudRacingEffectBtn