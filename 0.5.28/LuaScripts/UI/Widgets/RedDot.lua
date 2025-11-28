local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
RedDot = HL.Class('RedDot', UIWidgetBase)
RedDot.name = HL.Field(HL.String) << ''
RedDot.needUpdateOnActive = HL.Field(HL.Boolean) << false
RedDot.m_arg = HL.Field(HL.Any)
RedDot.m_instId = HL.Field(HL.Number) << -1
RedDot.m_readLike = HL.Field(HL.Boolean) << false
RedDot.curIsActive = HL.Field(HL.Boolean) << false
RedDot.curRdType = HL.Field(HL.Any)
RedDot.keyHintRedDot = HL.Field(HL.Forward('RedDot'))
RedDot._OnFirstTimeInit = HL.Override() << function(self)
end
RedDot.InitRedDot = HL.Method(HL.String, HL.Opt(HL.Any)) << function(self, redDotName, arg)
    self:_OnFirstTimeInit()
    if self.keyHintRedDot then
        self.gameObject:SetActive(false)
        self.keyHintRedDot:InitRedDot(redDotName, arg)
    else
        self.needUpdateOnActive = false
        self.gameObject:SetActive(true)
    end
    self.m_arg = arg
    if self.m_instId > 0 then
        if redDotName == self.name then
            self:UpdateState()
            return
        else
            self:Stop()
            self.m_readLike = false
        end
    end
    self.name = redDotName
    if string.isEmpty(redDotName) then
        self:ApplyState(false)
        return
    end
    self.m_readLike = RedDotManager.configs[redDotName].readLike
    local isActive = self:UpdateState()
    if isActive or not self.m_readLike then
        self.m_instId = RedDotManager:AddRedDotInstance(redDotName, function(active, rdType)
            if active == nil then
                self:UpdateState()
            else
                self:ApplyState(active, rdType)
            end
        end, self)
    else
        self.m_instId = -1
    end
end
RedDot.Stop = HL.Method() << function(self)
    if self.m_instId > 0 then
        self.m_instId = RedDotManager:RemoveRedDotInstance(self.m_instId)
    end
    self.curIsActive = false
    self.curRdType = nil
    self.view.content.gameObject:SetActive(false)
end
RedDot._OnEnable = HL.Override() << function(self)
    if self.m_instId <= 0 or not self.needUpdateOnActive then
        return
    end
    self.needUpdateOnActive = false
    self:UpdateState()
end
RedDot._OnDestroy = HL.Override() << function(self)
    self:Stop()
end
RedDot.GetActiveState = HL.Method().Return(HL.Boolean) << function(self)
    return self.gameObject.activeInHierarchy
end
RedDot.UpdateState = HL.Method().Return(HL.Boolean, HL.Opt(HL.Number)) << function(self)
    if string.isEmpty(self.name) then
        return false
    end
    local active, rdType = RedDotManager:GetRedDotState(self.name, self.m_arg)
    self:ApplyState(active, rdType)
    return active, rdType
end
RedDot.ApplyState = HL.Method(HL.Boolean, HL.Opt(HL.Number)) << function(self, active, rdType)
    self.curIsActive = active
    self.curRdType = rdType
    self.view.content.gameObject:SetActive(active)
    if active then
        rdType = rdType or UIConst.RED_DOT_TYPE.Normal
        self.view.normal.gameObject:SetActiveIfNecessary(rdType == UIConst.RED_DOT_TYPE.Normal)
        self.view.new.gameObject:SetActiveIfNecessary(rdType == UIConst.RED_DOT_TYPE.New)
    else
        if self.m_readLike then
            self:Stop()
        end
    end
end
RedDot.SetKeyHintTarget = HL.Method(HL.Opt(HL.Forward('RedDot'))) << function(self, redDot)
    self.keyHintRedDot = redDot
    self.gameObject:SetActive(redDot == nil)
    if redDot then
        redDot:InitRedDot(self.name, self.m_arg)
    end
end
HL.Commit(RedDot)
return RedDot