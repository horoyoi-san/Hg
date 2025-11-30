local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RemoteCommHud
local AUTO_TIME_OUT_TIME = 30
RemoteCommHudCtrl = HL.Class('RemoteCommHudCtrl', uiCtrl.UICtrl)
RemoteCommHudCtrl.s_messages = HL.StaticField(HL.Table) << {}
RemoteCommHudCtrl.s_auto = HL.StaticField(HL.Boolean) << false
RemoteCommHudCtrl.m_updateKey = HL.Field(HL.Number) << -1
RemoteCommHudCtrl.m_inited = HL.Field(HL.Boolean) << false
RemoteCommHudCtrl.m_autoNextTimer = HL.Field(HL.Number) << -1
RemoteCommHudCtrl.m_startTime = HL.Field(HL.Number) << 0
RemoteCommHudCtrl.m_pauseTime = HL.Field(HL.Number) << 0
RemoteCommHudCtrl.m_voiceHandleId = HL.Field(HL.Number) << 0
RemoteCommHudCtrl.m_forceAuto = HL.Field(HL.Any)
RemoteCommHudCtrl.m_singleData = HL.Field(Cfg.Types.RemoteCommonSingleData)
RemoteCommHudCtrl.m_firstShown = HL.Field(HL.Boolean) << false
RemoteCommHudCtrl.m_remoteCommSingleId = HL.Field(HL.String) << ""
RemoteCommHudCtrl.m_clickCount = HL.Field(HL.Number) << 0
RemoteCommHudCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.buttonSkip.onClick:RemoveAllListeners()
    self.view.buttonSkip.onClick:AddListener(function()
        if self.m_forceAuto == nil then
            self:_SwitchAuto(false)
        end
        self:_Pause()
        self:Notify(MessageConst.SHOW_POP_UP, {
            content = Language.LUA_CONFIRM_SKIP_DIALOG,
            onConfirm = function()
                self:_EndRemoteComm()
            end,
            onCancel = function()
                self:_Resume()
            end
        })
    end)
    self.view.buttonAuto.onClick:RemoveAllListeners()
    self.view.buttonAuto.onClick:AddListener(function()
        self:_SwitchAuto()
        self.view.textAuto.gameObject:SetActive(self:_GetCurAuto())
    end)
    self.view.buttonNext.onClick:RemoveAllListeners()
    self.view.buttonNext.onClick:AddListener(function()
        self.m_clickCount = self.m_clickCount + 1
        if self.m_forceAuto then
            return
        end
        local dialogText = self.view.dialogTextNode
        if dialogText.isPlaying then
            dialogText:SeekToEnd()
        elseif self.m_inited then
            self:_Next()
        end
    end)
end
RemoteCommHudCtrl.OnShow = HL.Override() << function(self)
    self:SetForceAuto(nil)
    local autoMode = self:_GetCurAuto()
    self.view.textAuto.gameObject:SetActive(self:_GetCurAuto())
    GameInstance.world.gameMechManager.mainCharRemoteCommBrain:UpdateAutoMode(autoMode)
    self:GetAnimationWrapper():PlayInAnimation(function()
        self.m_startTime = Time.time
        self:_StartAutoNextTimer()
        local voiceId = "au_" .. self.m_singleData.singleId
        local res, _ = VoiceUtils.TryGetVoiceDuration(voiceId)
        if res then
            self.m_voiceHandleId = VoiceManager:SpeakNarrative(voiceId, nil, CS.Beyond.Gameplay.Audio.NarrativeVoiceConfig.DEFAULT_CONFIG)
        end
        self.m_inited = true
        if self.m_updateKey < 0 then
            self.view.dialogTextNode.waitNode.gameObject:SetActive(not self.m_forceAuto)
        end
    end)
end
RemoteCommHudCtrl._GetAutoNextTime = HL.Method().Return(HL.Number) << function(self)
    local pastTime = 0
    if self.m_pauseTime > 0 then
        pastTime = self.m_pauseTime - self.m_startTime
    else
        pastTime = Time.time - self.m_startTime
    end
    local realDuration = -1
    local voiceId = self.m_singleData.voiceId
    local res, duration = VoiceUtils.TryGetVoiceDuration(voiceId)
    if res then
        realDuration = duration + 1
    end
    if realDuration < 0 then
        local remoteCommText = UIUtils.resolveTextCinematic(self.m_singleData.remoteCommText)
        realDuration = UIUtils.getTextShowDuration(remoteCommText)
    end
    local existTime = lume.clamp(realDuration - pastTime, 0, AUTO_TIME_OUT_TIME)
    return existTime
end
RemoteCommHudCtrl._GetCurAuto = HL.Method().Return(HL.Boolean) << function(self)
    if self.m_forceAuto ~= nil then
        return self.m_forceAuto
    end
    return RemoteCommHudCtrl.s_auto
end
RemoteCommHudCtrl.SetForceAuto = HL.Method(HL.Any) << function(self, forceAuto)
    self.m_forceAuto = forceAuto
    self.view.buttonAuto.gameObject:SetActive(self.m_forceAuto == nil)
end
RemoteCommHudCtrl.OnClose = HL.Override() << function(self)
    self:_ClearAutoNextTimer()
    self:_ClearWaitUpdate()
end
RemoteCommHudCtrl._SwitchAuto = HL.Method(HL.Opt(HL.Boolean)) << function(self, auto)
    local tmpAuto = not RemoteCommHudCtrl.s_auto
    if auto ~= nil then
        tmpAuto = auto
    end
    RemoteCommHudCtrl.s_auto = tmpAuto
    if not self:_GetCurAuto() then
        self:_ClearAutoNextTimer()
    else
        self:_StartAutoNextTimer()
    end
    local autoMode = self:_GetCurAuto()
    GameInstance.world.gameMechManager.mainCharRemoteCommBrain:UpdateAutoMode(autoMode)
end
RemoteCommHudCtrl._StartAutoNextTimer = HL.Method() << function(self)
    self:_ClearAutoNextTimer()
    if self:_GetCurAuto() then
        local existTime = self:_GetAutoNextTime()
        self.m_autoNextTimer = self:_StartTimer(existTime, function()
            self:_ClearAutoNextTimer()
            self:_Next()
        end)
    end
end
RemoteCommHudCtrl._Next = HL.Method() << function(self)
    self:Notify(MessageConst.P_REMOTE_COMM_NEXT)
end
RemoteCommHudCtrl._ClearAutoNextTimer = HL.Method() << function(self)
    if self.m_autoNextTimer >= 0 then
        self:_ClearTimer(self.m_autoNextTimer)
    end
    self.m_autoNextTimer = -1
end
RemoteCommHudCtrl._ClearWaitUpdate = HL.Method() << function(self)
    if self.m_updateKey >= 0 then
        LuaUpdate:Remove(self.m_updateKey)
    end
    self.m_updateKey = -1
end
RemoteCommHudCtrl._AddWaitUpdate = HL.Method() << function(self)
    self:_ClearWaitUpdate()
    self.m_updateKey = LuaUpdate:Add("Tick", function(_)
        if not self.view.dialogTextNode.textTalk.isPlaying then
            self:_ClearWaitUpdate()
            self.view.dialogTextNode.waitNode.gameObject:SetActive(self.m_inited)
        end
    end)
end
RemoteCommHudCtrl._StopVoice = HL.Method() << function(self)
    if self.m_voiceHandleId > 0 then
        VoiceManager:StopVoice(self.m_voiceHandleId)
    end
    self.m_voiceHandleId = -1
end
RemoteCommHudCtrl.RefreshText = HL.Method(HL.String, Cfg.Types.RemoteCommonSingleData) << function(self, remoteCommId, singleData)
    self.m_singleData = singleData
    local index = singleData.index
    local remoteCommText = UIUtils.resolveTextCinematic(singleData.remoteCommText)
    local actorName = UIUtils.resolveTextCinematic(singleData.actorName)
    local isEmpty = string.isEmpty(remoteCommText) and string.isEmpty(actorName)
    self.view.dialogTextNode.gameObject:SetActive(not isEmpty)
    if not isEmpty then
        local dialogTextNode = self.view.dialogTextNode
        dialogTextNode.textTalk:SetText(remoteCommText)
        dialogTextNode.textTalk:Play()
        local hint = singleData.hint
        dialogTextNode.textHint.gameObject:SetActive(not string.isEmpty(hint))
        dialogTextNode.textHint.text = UIUtils.resolveTextCinematic(hint)
        dialogTextNode.textName.text = UIUtils.resolveTextCinematic(actorName)
        dialogTextNode.waitNode.gameObject:SetActive(false)
    end
    self.m_pauseTime = 0
    self:_ClearAutoNextTimer()
    self:_ClearWaitUpdate()
    if not self.m_forceAuto then
        self:_AddWaitUpdate()
    end
    if self.m_firstShown then
        self.m_startTime = Time.time
        self:_StartAutoNextTimer()
        self:_StopVoice()
        local voiceId = "au_" .. singleData.singleId
        local res, _ = VoiceUtils.TryGetVoiceDuration(voiceId)
        if res then
            self.m_voiceHandleId = VoiceManager:SpeakNarrative(voiceId, nil, CS.Beyond.Gameplay.Audio.NarrativeVoiceConfig.DEFAULT_CONFIG)
        end
    end
    self.m_firstShown = true
    self:_UpdateClickRecord()
    self.m_remoteCommSingleId = string.format("%s_%d", remoteCommId, index)
end
RemoteCommHudCtrl._EndRemoteComm = HL.Method() << function(self)
    self:Notify(MessageConst.P_REMOTE_COMM_SKIP_END)
end
RemoteCommHudCtrl._Pause = HL.Method() << function(self)
    VoiceManager:PauseVoice(self.m_voiceHandleId)
    self:_ClearAutoNextTimer()
    self.m_pauseTime = Time.time
    self:Notify(MessageConst.P_REMOTE_COMM_PAUSE)
end
RemoteCommHudCtrl._Resume = HL.Method() << function(self)
    if self.m_voiceHandleId > 0 then
        VoiceManager:ResumeVoice(self.m_voiceHandleId)
    end
    if self.m_forceAuto then
        self:_StartAutoNextTimer()
    end
    self.m_pauseTime = 0
    self:Notify(MessageConst.P_REMOTE_COMM_RESUME)
end
RemoteCommHudCtrl._UpdateClickRecord = HL.Method() << function(self)
    GameInstance.world.gameMechManager.mainCharRemoteCommBrain:UpdateClickRecord(self.m_remoteCommSingleId, self.m_clickCount)
    self.m_clickCount = 0
end
HL.Commit(RemoteCommHudCtrl)