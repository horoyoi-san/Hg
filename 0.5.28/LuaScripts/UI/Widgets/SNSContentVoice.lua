local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSContentVoice = HL.Class('SNSContentVoice', UIWidgetBase)
SNSContentVoice.m_args = HL.Field(HL.Table)
SNSContentVoice.m_timerId = HL.Field(HL.Number) << -1
SNSContentVoice.m_voiceHandleId = HL.Field(HL.Number) << -1
SNSContentVoice.m_onSizeChange = HL.Field(HL.Function)
SNSContentVoice.s_playingVoice = HL.StaticField(HL.Forward("SNSContentVoice"))
SNSContentVoice._OnFirstTimeInit = HL.Override() << function(self)
end
SNSContentVoice._OnDisable = HL.Override() << function(self)
    self:_ClearVoice()
end
SNSContentVoice._OnDestroy = HL.Override() << function(self)
    self:_ClearVoice()
end
SNSContentVoice.InitSNSContentVoice = HL.Method(HL.Table, HL.Function) << function(self, args, onSizeChange)
    self:_FirstTimeInit()
    if not args.loaded then
        self.view.animationWrapper:PlayInAnimation()
        AudioAdapter.PostEvent("Au_UI_Popup_SNSDialogContent_OtherNode_Open")
    end
    self.m_args = args
    self.m_onSizeChange = onSizeChange
    self.view.playIcon.gameObject:SetActiveIfNecessary(true)
    self.view.foldBtn.gameObject:SetActiveIfNecessary(false)
    self.view.showTextBtn.gameObject:SetActiveIfNecessary(true)
    self.view.voiceTextNode.gameObject:SetActiveIfNecessary(false)
    self.view.timeText.text = self:_GetTimeText()
    self.view.voiceText.text = args.voiceText
    self.view.playBtn.onClick:RemoveAllListeners()
    self.view.playBtn.onClick:AddListener(function()
        if SNSContentVoice.s_playingVoice ~= nil then
            SNSContentVoice.s_playingVoice:_ClearVoice()
        end
        self:_PlayVoice()
    end)
    self.view.showTextBtn.onClick:RemoveAllListeners()
    self.view.showTextBtn.onClick:AddListener(function()
        self:_Unfold()
    end)
    self.view.foldBtn.onClick:RemoveAllListeners()
    self.view.foldBtn.onClick:AddListener(function()
        self:_Fold()
    end)
end
SNSContentVoice._PlayVoice = HL.Method() << function(self)
    local voiceId = self.m_args.voiceId
    local res, duration = VoiceUtils.TryGetVoiceDuration(voiceId)
    if res then
        self.m_voiceHandleId = VoiceManager:SpeakNarrative(voiceId, nil, CS.Beyond.Gameplay.Audio.NarrativeVoiceConfig.DEFAULT_CONFIG)
        self.m_timerId = self:_StartTimer(duration, function()
            self:_ClearVoice()
        end)
    end
    SNSContentVoice.s_playingVoice = self
end
SNSContentVoice._ClearVoice = HL.Method() << function(self)
    if self.m_timerId >= 0 then
        self:_ClearTimer(self.m_timerId)
        self.m_timerId = -1
    end
    if self.m_voiceHandleId >= 0 then
        VoiceManager:StopVoice(self.m_voiceHandleId)
        self.m_voiceHandleId = -1
    end
    SNSContentVoice.s_playingVoice = nil
end
SNSContentVoice._Fold = HL.Method() << function(self)
    self.view.playIcon.gameObject:SetActiveIfNecessary(true)
    self.view.foldBtn.gameObject:SetActiveIfNecessary(false)
    self.view.showTextBtn.gameObject:SetActiveIfNecessary(true)
    self.view.voiceTextNode.gameObject:SetActiveIfNecessary(false)
    if self.m_onSizeChange then
        self.m_onSizeChange()
    end
end
SNSContentVoice._Unfold = HL.Method() << function(self)
    self.view.playIcon.gameObject:SetActiveIfNecessary(false)
    self.view.foldBtn.gameObject:SetActiveIfNecessary(true)
    self.view.showTextBtn.gameObject:SetActiveIfNecessary(false)
    self.view.voiceTextNode.gameObject:SetActiveIfNecessary(true)
    if self.m_onSizeChange then
        self.m_onSizeChange()
    end
end
SNSContentVoice._GetTimeText = HL.Method().Return(HL.String) << function(self)
    local _, duration = VoiceUtils.TryGetVoiceDuration(self.m_args.voiceId)
    duration = math.ceil(duration)
    local min = duration // 60
    local sec = duration % 60
    if min > 0 then
        return tostring(min) .. "'" .. tostring(sec) .. "''"
    else
        return tostring(sec) .. "''"
    end
end
HL.Commit(SNSContentVoice)
return SNSContentVoice