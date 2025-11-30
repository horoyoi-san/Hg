local LuaSystemBase = require_ex('LuaSystem/LuaSystemBase')
LoginCheckSystem = HL.Class('LoginCheckSystem', LuaSystemBase.LuaSystemBase)
LoginCheckSystem.m_currentCheckStep = HL.Field(HL.Table)
LoginCheckSystem.m_isRunningStep = HL.Field(HL.Boolean) << false
LoginCheckSystem.m_isInterrupted = HL.Field(HL.Boolean) << false
LoginCheckSystem.m_checkingIndex = HL.Field(HL.Number) << -1
LoginCheckSystem.m_interruptHandlers = HL.Field(HL.Table)
LoginCheckSystem.m_loginChecked = HL.Field(HL.Boolean) << false
LoginCheckSystem.m_cachedCallback = HL.Field(HL.Function)
LoginCheckSystem.m_isResuming = HL.Field(HL.Boolean) << false
LoginCheckSystem.m_resumeFunc = HL.Field(HL.Function)
LoginCheckSystem.m_resumeCor = HL.Field(HL.Thread)
LoginCheckSystem.m_globalTagChangedCallback = HL.Field(HL.Userdata)
LoginCheckSystem.LoginCheckSystem = HL.Constructor() << function(self)
    self.m_currentCheckStep = nil
    self.m_interruptHandlers = {}
end
LoginCheckSystem.PerformLoginCheck = HL.Method() << function(self)
    if self.m_loginChecked then
        return
    end
    self.m_loginChecked = true
    self:InitializeCheck()
    if #LoginCheckConst.LOGIN_CHECK_STEP_CONFIG == 0 then
        self:_LoginCheckFinished()
        return
    end
    self.m_checkingIndex = 1
    local firstStep = LoginCheckConst.LOGIN_CHECK_STEP_CONFIG[self.m_checkingIndex]
    self:_TryRunOrCacheCheckStep(firstStep)
end
LoginCheckSystem.InitializeCheck = HL.Method() << function(self)
    self:_AddInterruptSourceHandler(MessageConst.ON_BLACK_SCREEN_IN, MessageConst.ON_BLACK_SCREEN_OUT)
    self:_AddInterruptSourceHandler(MessageConst.TOGGLE_LEVEL_CAMERA_MOVE, MessageConst.TOGGLE_LEVEL_CAMERA_MOVE)
    self:_RegisterOnGlobalTagChanged()
    self.m_cachedCallback = function(stepResult)
        self:_OnStepFinished(stepResult)
    end
end
LoginCheckSystem._RegisterOnGlobalTagChanged = HL.Method() << function(self)
    if self.m_globalTagChangedCallback then
        return
    end
    local callback = function()
        if self.m_isInterrupted then
            self:_TryResume()
        else
            self:_TryInterrupt()
        end
    end
    self.m_globalTagChangedCallback = CS.Beyond.Gameplay.GameplayUIUtils.RegisterOnGlobalTagChanged(callback)
end
LoginCheckSystem._UnRegisterOnGlobalTagChanged = HL.Method() << function(self)
    if self.m_globalTagChangedCallback then
        CS.Beyond.Gameplay.GameplayUIUtils.UnregisterOnGlobalTagChanged(self.m_globalTagChangedCallback)
        self.m_globalTagChangedCallback = nil
    end
end
LoginCheckSystem._TryInterrupt = HL.Method() << function(self)
    if not self.m_isRunningStep or self.m_isInterrupted then
        return
    end
    if not self:_CheckCanRunStep(true) then
        self.m_isInterrupted = true
        Notify(MessageConst.ON_LOGIN_CHECK_INTERRUPT, self.m_currentCheckStep.key)
    end
end
LoginCheckSystem._TryResume = HL.Method() << function(self)
    if not self.m_isInterrupted or self.m_isResuming then
        return
    end
    self.m_isResuming = true
    if self.m_resumeFunc == nil then
        self.m_resumeFunc = function()
            coroutine.step()
            self.m_isResuming = false
            if not self.m_isRunningStep then
                self:_TryRunCurrentCheckStep()
                return
            end
            if self:_CheckCanRunStep() then
                self.m_isInterrupted = false
                Notify(MessageConst.ON_LOGIN_CHECK_RESUME, self.m_currentCheckStep.key)
            end
        end
    end
    self.m_resumeCor = self:_ClearCoroutine(self.m_resumeCor)
    self.m_resumeCor = self:_StartCoroutine(self.m_resumeFunc)
end
LoginCheckSystem._AddInterruptSourceHandler = HL.Method(HL.Number, HL.Number) << function(self, interruptMsg, resumeMsg)
    local handlerKey = MessageManager:Register(interruptMsg, function(args)
        self:_TryInterrupt()
    end)
    table.insert(self.m_interruptHandlers, handlerKey)
    handlerKey = MessageManager:Register(resumeMsg, function(args)
        self:_TryResume()
    end)
    table.insert(self.m_interruptHandlers, handlerKey)
end
LoginCheckSystem._TryRunOrCacheCheckStep = HL.Method(HL.Table) << function(self, stepConfig)
    self.m_currentCheckStep = stepConfig
    self.m_isRunningStep = false
    if stepConfig == nil or stepConfig.checkFunction == nil then
        self:_LoginCheckFinished()
        return
    end
    self:_TryRunCurrentCheckStep()
end
LoginCheckSystem._TryRunCurrentCheckStep = HL.Method() << function(self)
    if not self:_CheckCanRunStep() then
        return
    end
    self.m_isRunningStep = true
    self.m_currentCheckStep.checkFunction(self.m_cachedCallback)
end
LoginCheckSystem._CheckCanRunStep = HL.Method(HL.Opt(HL.Boolean)).Return(HL.Boolean) << function(self, checkInterrupt)
    if self.m_currentCheckStep == nil then
        return true
    end
    local checkConfig = checkInterrupt == true and self.m_currentCheckStep.interruptConfig or self.m_currentCheckStep.waitConfig
    if not checkConfig then
        return true
    end
    for key, checkEnabled in pairs(checkConfig) do
        local checkFunc = LoginCheckConst.LoginCheckConflictCheckFunc[key]
        if checkEnabled == true and checkFunc and checkFunc() then
            return false
        end
    end
    return true
end
LoginCheckSystem._OnStepFinished = HL.Method(HL.Number) << function(self, stepResult)
    if stepResult == LoginCheckConst.LOGIN_CHECK_STEP_RESULT.Continue then
        self.m_checkingIndex = self.m_checkingIndex + 1
    elseif stepResult == LoginCheckConst.LOGIN_CHECK_STEP_RESULT.BackToStart then
        self.m_checkingIndex = 1
    elseif stepResult == LoginCheckConst.LOGIN_CHECK_STEP_RESULT.BackToCurrent then
    elseif stepResult == LoginCheckConst.LOGIN_CHECK_STEP_RESULT.Stop then
        self:_LoginCheckFinished()
        return
    end
    local nextStep = LoginCheckConst.LOGIN_CHECK_STEP_CONFIG[self.m_checkingIndex]
    self:_TryRunOrCacheCheckStep(nextStep)
end
LoginCheckSystem._LoginCheckFinished = HL.Method() << function(self)
    self:ReleaseCheck()
end
LoginCheckSystem.ReleaseCheck = HL.Method() << function(self)
    for index, handlerKey in pairs(self.m_interruptHandlers) do
        MessageManager:Unregister(handlerKey)
        self.m_interruptHandlers[index] = nil
    end
    self:_UnRegisterOnGlobalTagChanged()
    self.m_resumeCor = self:_ClearCoroutine(self.m_resumeCor)
    self.m_resumeFunc = nil
    self.m_cachedCallback = nil
end
LoginCheckSystem.OnRelease = HL.Override() << function(self)
    self:ReleaseCheck()
end
HL.Commit(LoginCheckSystem)
return LoginCheckSystem