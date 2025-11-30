local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Radio
RadioCtrl = HL.Class('RadioCtrl', uiCtrl.UICtrl)
RadioCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.STOP_RADIO] = 'StopRadio', [MessageConst.ON_SCENE_LOAD_START] = '_FlushAll', [MessageConst.ALL_CHARACTER_DEAD] = '_FlushAll', [MessageConst.ON_TELEPORT_SQUAD] = '_FlushAll', [MessageConst.PLAY_CG] = '_FlushAll', [MessageConst.ON_PLAY_CUTSCENE] = '_FlushAll', [MessageConst.ON_DIALOG_START] = '_OnDialogStart', [MessageConst.ON_GUIDE_STOPPED] = 'OnHideGuideStep', [MessageConst.START_GUIDE_GROUP] = 'OnStartGuide', [MessageConst.ON_ULTIMATE_SKILL_START] = "OnUltimateSkillStart", [MessageConst.ON_ULTIMATE_SKILL_END] = "OnUltimateSkillEnd", [MessageConst.ON_NARRATIVE_BLACK_SCREEN_END] = "OnNarrativeScreenEnd", }
RADIO_DATA_SORT_KEYS = { "priorityKey", "needResumeKey", "addTimeKey" }
RadioCtrl.s_radioIndexCache = HL.StaticField(HL.Table) << {}
RadioCtrl.m_curShow = HL.Field(HL.Any)
RadioCtrl.inMainHud = HL.Field(HL.Boolean) << false
RadioCtrl.m_waitingQueue = HL.Field(HL.Table)
RadioCtrl.m_audioEndFunc = HL.Field(HL.Function)
RadioCtrl.m_queueSortFunc = HL.Field(HL.Function)
RadioCtrl.m_pauseRefCount = HL.Field(HL.Number) << 0
RadioCtrl.enableDebugLog = HL.Field(HL.Boolean) << false
RadioCtrl.m_timerId = HL.Field(HL.Number) << 0
RadioCtrl.m_globalTagHandle = HL.Field(CS.Beyond.Gameplay.Core.GlobalTagHandle)
RadioCtrl.m_spriteName = HL.Field(HL.String) << ""
RadioCtrl.m_needHide = HL.Field(HL.Boolean) << false
RadioCtrl.OnInMainHudChanged = HL.StaticMethod(HL.Table) << function(arg)
    local inMainHud = unpack(arg)
    if inMainHud then
        RadioCtrl.OnEnterMainHud()
    else
        RadioCtrl.OnLeaveMainHud()
    end
end
RadioCtrl.OnEnterMainHud = HL.StaticMethod() << function()
    local ctrl = RadioCtrl.AutoOpen(PANEL_ID, {}, true)
    ctrl.inMainHud = true
    ctrl:Show()
end
RadioCtrl.OnLeaveMainHud = HL.StaticMethod() << function()
    local ctrl = RadioCtrl.AutoOpen(PANEL_ID, {}, true)
    ctrl.inMainHud = false
    if UIManager:IsOpen(PANEL_ID) then
        ctrl:Hide()
    end
end
RadioCtrl.ShowRadio = HL.StaticMethod(HL.Table) << function(arg)
    local ctrl = RadioCtrl.AutoOpen(PANEL_ID, {}, true)
    local data = unpack(arg)
    ctrl:DoShowRadio(data.radioId, data.fromBegin, data.index, data.callback, data.entity)
end
RadioCtrl.EnableRadioLog = HL.StaticMethod(HL.Boolean) << function(enable)
    local needHide = false
    if not UIManager:IsShow(PANEL_ID) then
        needHide = true
    end
    local ctrl = RadioCtrl.AutoOpen(PANEL_ID, {}, true)
    ctrl.enableDebugLog = enable
    if needHide then
        ctrl:Hide()
    end
end
RadioCtrl.FlushRadio = HL.StaticMethod(HL.Table) << function(arg)
    local radioId = unpack(arg)
    local res, ctrl = UIManager:IsOpen(PANEL_ID)
    if string.isEmpty(radioId) then
        if res then
            ctrl:DoFlushRadio()
        end
    else
        if not res then
            ctrl = RadioCtrl.AutoOpen(PANEL_ID, {}, true)
        end
        ctrl:DoFlushRadio(radioId)
    end
end
RadioCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_waitingQueue = {}
    self.m_curShow = nil
    self.m_queueSortFunc = Utils.genSortFunction(RADIO_DATA_SORT_KEYS, true)
    self.inMainHud = GameInstance.world.inMainHud
    self.m_audioEndFunc = function(handleId)
        self:_OnAudioEnd(handleId)
    end
end
RadioCtrl.StopRadio = HL.Method(HL.Table) << function(self, arg)
    if self.m_curShow == nil then
        return
    end
    local radioId = unpack(arg)
    if self.m_curShow.radioId ~= radioId then
        return
    end
    RadioCtrl.s_radioIndexCache[radioId] = self.m_curShow.curIndex - 1
    self:_CutCurRadio(true)
    if not self.m_curShow then
        if not self:_TryShowRadio() then
            self:_TryHide()
        end
    end
end
RadioCtrl.OnHideGuideStep = HL.Method(HL.Opt(HL.Any)) << function(self, arg)
    if arg then
        local isForceGuide = unpack(arg)
        if isForceGuide then
            self:Show()
        end
    end
end
RadioCtrl.OnUltimateSkillStart = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    if self:IsShow() then
        self:_TryHide()
    end
end
RadioCtrl.OnUltimateSkillEnd = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    self:Show()
end
RadioCtrl.OnNarrativeScreenEnd = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    self:Show()
end
RadioCtrl.OnStartGuide = HL.Method(HL.Any) << function(self, arg)
    local info = unpack(arg)
    if info.type == CS.Beyond.Gameplay.GuideGroupType.Force then
        if self:IsShow() then
            self:_TryHide()
        end
    end
end
RadioCtrl._TryAddRadio2Queue = HL.Method(HL.String, HL.Opt(HL.Table)) << function(self, radioId, extraData)
    if self:_CheckRadioInQueue(radioId) <= 0 then
        local res, radioData = Tables.radioTable:TryGetValue(radioId)
        if res then
            local data = { radioId = radioId, curIndex = 0, priority = radioData.priority, addTime = TimeManagerInst.unscaledTime, }
            if extraData then
                for k, v in pairs(extraData) do
                    data[k] = v
                end
            end
            local needResume = data.curIndex == 0
            data["priorityKey"] = -radioData.priority
            data["needResumeKey"] = needResume and 0 or -1
            data["addTimeKey"] = needResume and data.addTime or -data.addTime
            table.insert(self.m_waitingQueue, data)
            table.sort(self.m_waitingQueue, self.m_queueSortFunc)
            if BEYOND_DEBUG then
                self:_UpdateLog()
            end
        end
    end
end
RadioCtrl._CheckRadioInQueue = HL.Method(HL.String).Return(HL.Number) << function(self, radioId)
    for index, v in pairs(self.m_waitingQueue) do
        if v.radioId == radioId then
            return index
        end
    end
    return -1
end
RadioCtrl.DoShowRadio = HL.Method(HL.String, HL.Opt(HL.Boolean, HL.Number, HL.Any, HL.Any)) << function(self, radioId, fromBegin, index, callback, entity)
    local res, radioData = Tables.radioTable:TryGetValue(radioId)
    local extraData = { callback = callback, entity = entity, }
    local tmpIndex
    index = index == nil and 0 or index
    if not fromBegin then
        if index >= 0 then
            tmpIndex = index
        elseif RadioCtrl.s_radioIndexCache[radioId] then
            tmpIndex = RadioCtrl.s_radioIndexCache[radioId]
            RadioCtrl.s_radioIndexCache[radioId] = -1
        end
    end
    if tmpIndex and tmpIndex >= 0 then
        extraData.curIndex = tmpIndex
    end
    if res then
        if not self.m_curShow then
            if self:IsShow() then
                self:_TryAddRadio2Queue(radioId, extraData)
                self:_TryShowRadio()
            else
                self:_TryAddRadio2Queue(radioId, extraData)
                if self:_CheckCanPlay() then
                    self:Show()
                end
            end
        else
            local curExtraData = { callback = self.m_curShow.callback, entity = self.m_curShow.entity, curIndex = self.m_curShow.curIndex - 1 }
            if self.m_curShow.priority > radioData.priority then
                if radioData.continueAfterRadio then
                    self:_TryAddRadio2Queue(radioId, extraData)
                end
            elseif self.m_curShow.priority < radioData.priority then
                self:_TryAddRadio2Queue(radioId, extraData)
                if self.m_curShow.continueAfterRadio then
                    self:_TryAddRadio2Queue(self.m_curShow.radioId, curExtraData)
                end
                self:_CutCurRadio(true)
                if not self.m_curShow then
                    self:_TryShowRadio()
                end
            else
                self:_TryAddRadio2Queue(radioId, extraData)
                if self.m_curShow.radioId ~= radioId and self.m_curShow.continueAfterRadio then
                    self:_TryAddRadio2Queue(self.m_curShow.radioId, curExtraData)
                end
                self:_CutCurRadio(true)
                if not self.m_curShow then
                    self:_TryShowRadio()
                end
            end
        end
    else
        logger.error("Radio play fail, no radioId in table: " .. radioId)
    end
end
RadioCtrl._UpdateLog = HL.Method() << function(self)
    if self.enableDebugLog then
        local text = ""
        for i, debugData in pairs(self.m_waitingQueue) do
            if i ~= 1 then
                text = text .. "\n"
            end
            text = text .. string.format("{%s : %d}", debugData.radioId, debugData.curIndex)
        end
        self:Notify(MessageConst.UPDATE_DEBUG_TEXT, text)
    end
end
RadioCtrl._DoFlushRadio = HL.Method() << function(self)
    local radioIds = {}
    for _, data in pairs(self.m_waitingQueue) do
        table.insert(radioIds, data.radioId)
        if data.callback then
            data.callback(data.radioId)
        end
    end
    if #radioIds > 0 then
        NarrativeUtils.RadioFinish(radioIds)
    end
    self.m_waitingQueue = {}
    if self.m_curShow then
        self:_CutCurRadio(true)
    end
    if BEYOND_DEBUG then
        self:_UpdateLog()
    end
end
RadioCtrl.DoFlushRadio = HL.Method(HL.Opt(HL.String)) << function(self, radioId)
    self:_DoFlushRadio()
    if not string.isEmpty(radioId) then
        self:DoShowRadio(radioId)
    else
        self:_TryHide()
    end
end
RadioCtrl._AddGlobalTag = HL.Method() << function(self)
    self:_RemoveGlobalTag()
    self.m_globalTagHandle = GameInstance.instance:AddGlobalTag(CS.Beyond.Gameplay.Core.GameplayTag(CS.Beyond.GlobalTagConsts.TAG_RADIO_PATH))
end
RadioCtrl._RemoveGlobalTag = HL.Method() << function(self)
    if self.m_globalTagHandle then
        self.m_globalTagHandle:RemoveTag()
    end
end
RadioCtrl.OnShow = HL.Override() << function(self)
    self.m_needHide = false
    self:GetAnimationWrapper():ClearTween(false)
    self:PlayAnimationIn()
    local showRadio = true
    local resume = false
    if self.m_curShow and self.m_pauseRefCount > 0 then
        resume = true
        self.m_pauseRefCount = self.m_pauseRefCount - 1
        if self.m_curShow.cacheCallbackVoiceHandleId > 0 and self.m_curShow and self.m_curShow.voiceHandleId and self.m_pauseRefCount == 0 then
            if self.m_curShow.cacheCallbackVoiceHandleId == self.m_curShow.voiceHandleId then
                self.m_curShow.voiceHandleId = -1
                self.m_curShow.cacheCallbackVoiceHandleId = -1
            else
                VoiceManager:ResumeVoice(self.m_curShow.voiceHandleId)
            end
        end
    end
    if self:_CheckCanPlay() then
        if resume then
            self:_ContinueCurRadio()
        elseif not self.m_curShow then
            if not self:_TryShowRadio() then
                showRadio = false
                self:_TryHide()
            end
        else
            showRadio = false
            self:_TryHide()
        end
    else
        showRadio = false
        self:_TryHide()
    end
    if showRadio then
        self:_AddGlobalTag()
    end
end
RadioCtrl.OnHide = HL.Override() << function(self)
    self:_RemoveGlobalTag()
    self:TryPauseCurRadio()
end
RadioCtrl.OnClose = HL.Override() << function(self)
    self:_CutCurRadio(true)
end
RadioCtrl._PauseCurRadio = HL.Method() << function(self)
    if self.m_curShow then
        if self.m_pauseRefCount == 0 then
            if self.m_curShow.voiceHandleId and self.m_curShow.voiceHandleId > 0 then
                VoiceManager:PauseVoice(self.m_curShow.voiceHandleId)
            elseif self.m_curShow.timerId then
                local triggerTime = TimerManager:GetTimerTriggerTime(self.m_curShow.timerId)
                if triggerTime > 0 then
                    self.m_curShow.resumeTime = triggerTime - Time.time
                end
                self:_ClearTimer(self.m_curShow.timerId)
            end
        end
        self.m_pauseRefCount = self.m_pauseRefCount + 1
    end
    NarrativeUtils.SetRadioId("")
end
RadioCtrl._ContinueCurRadio = HL.Method() << function(self)
    if self.m_pauseRefCount == 0 then
        if self.m_curShow then
            if self.m_curShow.voiceHandleId then
                VoiceManager:ResumeVoice(self.m_curShow.voiceHandleId)
                if self.m_curShow.cacheCallbackVoiceHandleId <= 0 and self.m_curShow.cacheCallbackVoiceHandleId == self.m_curShow.voiceHandleId then
                    self:_ShowSingleRadio()
                end
            elseif self.m_curShow.resumeTime > 0 then
                local timerId = self:_StartTimer(self.m_curShow.resumeTime, function()
                    self:_ShowSingleRadio()
                end)
                self.m_curShow.timerId = timerId
            else
                self:_ShowSingleRadio()
            end
            self.view.textTalk:Play()
            self.view.textTalkCenter:Play()
            if self.m_curShow then
                NarrativeUtils.SetRadioId(self.m_curShow.radioId)
            end
        end
    end
end
RadioCtrl._CutCurRadio = HL.Method(HL.Opt(HL.Boolean)) << function(self, doCallback)
    local curShow = self.m_curShow
    local callback
    local radioId
    if curShow then
        callback = curShow.callback
        radioId = curShow.radioId
        if curShow.timerId then
            self:_ClearTimer(curShow.timerId)
        end
        if not string.isEmpty(curShow.voiceId) then
            if curShow.voiceHandleId then
                VoiceManager:StopVoice(curShow.voiceHandleId)
            end
            VoiceCallbackUtil.UnsubscribeOnVoiceEndEvent(self.m_audioEndFunc)
        end
    end
    self.m_curShow = nil
    self.m_pauseRefCount = 0
    if doCallback and callback and not string.isEmpty(radioId) then
        callback(radioId)
    end
    NarrativeUtils.RadioFinish({ radioId })
    NarrativeUtils.SetRadioId("")
end
RadioCtrl._ShowRadioUI = HL.Method(HL.Userdata).Return(HL.Number) << function(self, radioSingleData)
    local actorName = radioSingleData.actorName
    local infoActorName = radioSingleData.infoActorName
    local iconSuffix = radioSingleData.iconSuffix
    local index = radioSingleData.index
    local radioText = UIUtils.resolveTextCinematic(radioSingleData.radioText)
    actorName = UIUtils.resolveTextCinematic(actorName)
    infoActorName = UIUtils.resolveTextCinematic(infoActorName)
    local noActor = string.isEmpty(actorName)
    self.view.textTalkCenterNode.gameObject:SetActive(noActor)
    self.view.bottomMid.gameObject:SetActive(not noActor)
    local num
    if noActor then
        self.view.textTalkCenter:SetText(radioText)
        self.view.textTalkCenter:Play()
        num = self.view.textTalkCenter.totalCharacterNum
    else
        self.view.textName.text = UIUtils.removePattern(actorName, UIConst.NARRATIVE_ANONYMITY_PATTERN)
        self.view.textTalk:SetText(radioText)
        self.view.textTalk:Play()
        num = self.view.textTalk.totalCharacterNum
    end
    local spriteName = ""
    if not string.isEmpty(iconSuffix) then
        self.view.charImage.gameObject:SetActive(true)
        self.view.charBlueMask.gameObject:SetActive(true)
        spriteName = UIConst.UI_CHAR_HEAD_SQUARE_PREFIX .. iconSuffix
        self.view.charImage.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD_RECTANGLE, spriteName)
        self.view.charBlueMask.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD_RECTANGLE, spriteName)
        self.m_curShow.icon = iconSuffix
    elseif not self.m_curShow.icon then
        self.view.charImage.gameObject:SetActive(false)
        self.view.charBlueMask.gameObject:SetActive(false)
    end
    if not string.isEmpty(spriteName) then
        self.m_curShow.spriteName = spriteName
        self.view.infoNode.gameObject:SetActive(true)
        if self.m_spriteName ~= spriteName or index == 1 then
            self.view.infoNode:PlayInAnimation()
        end
    elseif string.isEmpty(self.m_curShow.spriteName) then
        self.view.infoNode.gameObject:SetActive(false)
    end
    self.m_spriteName = spriteName
    return num
end
RadioCtrl._OnAudioEnd = HL.Method(HL.Number) << function(self, voiceHandleId)
    if self.m_curShow and self.m_curShow.voiceHandleId == voiceHandleId then
        if self.m_pauseRefCount > 0 then
            self.m_curShow.cacheCallbackVoiceHandleId = voiceHandleId
        else
            local timerId = self:_StartTimer(Tables.cinematicConst.radioAudioWaitTime, function()
                self:_ShowSingleRadio()
            end)
            self.m_curShow.timerId = timerId
            self.m_curShow.cacheCallbackVoiceHandleId = -1
            self.m_curShow.voiceHandleId = nil
        end
        VoiceCallbackUtil.UnsubscribeOnVoiceEndEvent(self.m_audioEndFunc)
    end
end
RadioCtrl._ShowSingleRadio = HL.Method() << function(self)
    if self.m_curShow then
        local nextIndex = self.m_curShow.curIndex + 1
        if nextIndex <= self.m_curShow.radioSingleDataList.Count then
            self.view.infoNode:ClearTween()
            local nextSingleData = self.m_curShow.radioSingleDataList[CSIndex(nextIndex)]
            local num = self:_ShowRadioUI(nextSingleData)
            num = num / I18nUtils.GetTextSpeedFactor()
            local voiceId = "au_" .. nextSingleData.id
            if not string.isEmpty(nextSingleData.audioOverride) then
                voiceId = nextSingleData.audioOverride
            end
            local res, _ = VoiceUtils.TryGetVoiceDuration(voiceId)
            if not res then
                voiceId = ""
            end
            local audioEffect = nextSingleData.audioEffect
            if self.m_curShow.timerId then
                self:_ClearTimer(self.m_curShow.timerId)
            end
            local durationOnText = lume.clamp(num * Tables.cinematicConst.textShowDurationPerWord, Tables.cinematicConst.radioMinWaitTime, Tables.cinematicConst.radioMaxWaitTime)
            if not string.isEmpty(voiceId) then
                local cfg = CS.Beyond.Gameplay.Audio.NarrativeVoiceConfig(audioEffect, 1)
                local voiceHandleId
                local entity = self.m_curShow.entity
                if entity then
                    voiceHandleId = VoiceManager:SpeakNarrative(voiceId, entity, cfg)
                else
                    voiceHandleId = VoiceManager:SpeakNarrative(voiceId, nil, cfg)
                end
                if voiceHandleId > 0 and VoiceManager:IsVoicePlaying(voiceHandleId) then
                    self.m_curShow.voiceHandleId = voiceHandleId
                    VoiceCallbackUtil.SubscribeOnVoiceEndEvent(self.m_audioEndFunc)
                    self.m_curShow.voiceId = voiceId
                else
                    local duration = durationOnText
                    local timerId = self:_StartTimer(duration, function()
                        self:_ShowSingleRadio()
                    end)
                    self.m_curShow.timerId = timerId
                end
            else
                local duration = durationOnText
                local minDuration = Tables.cinematicConst.radioTextMinDuration
                local finalTime = math.max(minDuration, duration)
                local timerId = self:_StartTimer(finalTime, function()
                    self:_ShowSingleRadio()
                end)
                self.m_curShow.timerId = timerId
            end
            self.m_curShow.curIndex = nextIndex
            self.m_curShow.cacheCallbackVoiceHandleId = -1
        else
            NarrativeUtils.SetLastFinishRadio(self.m_curShow.radioId)
            self:_CutCurRadio(true)
            if not self.m_curShow then
                if not self:_TryShowRadio() then
                    if self.view.infoNode.gameObject.activeSelf then
                        self.view.infoNode:PlayOutAnimation()
                        self:_TryHide(true)
                    else
                        self:_TryHide(true)
                    end
                end
            end
        end
    end
end
RadioCtrl._DoShowRadio = HL.Method(HL.Table) << function(self, data)
    self.m_needHide = false
    self.m_needHide = false
    self:GetAnimationWrapper():ClearTween()
    self:PlayAnimationIn()
    local radioId = data.radioId
    local curIndex = data.curIndex
    local callback = data.callback
    local entity = data.entity
    local res, radioData = Tables.radioTable:TryGetValue(radioId)
    if res then
        local canStop = false
        local radioType = radioData.radioType
        if radioType == GEnums.RadioType.Wireless then
            self.m_curShow = { radioId = radioId, priority = radioData.priority, continueAfterRadio = radioData.continueAfterRadio, continueAfterDialog = radioData.continueAfterDialog, radioSingleDataList = radioData.radioSingleDataList, callback = callback, curIndex = curIndex, timerId = nil, voiceHandleId = nil, entity = entity, icon = nil, spriteName = nil, cacheCallbackVoiceHandleId = -1, resumeTime = -1, }
            self:_ShowSingleRadio()
            NarrativeUtils.SetRadioId(self.m_curShow.radioId)
        else
            logger.error("_DoShowRadio radioType error, only wireless supported, radioId: %s!!!", radioId)
        end
    else
        logger.error("_DoShowRadio data error, radioId: %s!!!", radioId)
    end
end
RadioCtrl._FlushAll = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    self:_DoFlushRadio()
    self:_TryHide(true)
end
RadioCtrl._OnDialogStart = HL.Method(HL.Opt(HL.Table)) << function(self, data)
    local _, dialogType = unpack(data)
    if dialogType == Const.DialogType.Cinematic then
        self:_FlushAll()
    else
        if self.m_curShow and self.m_curShow.continueAfterDialog then
            local extraData = { curIndex = self.m_curShow.curIndex - 1, }
            self:_TryAddRadio2Queue(self.m_curShow.radioId, extraData)
        end
        self:_CutCurRadio(true)
    end
end
RadioCtrl._CheckCanPlay = HL.Method(HL.Opt(HL.String)).Return(HL.Boolean) << function(self, radioId)
    if Utils.isInNarrative() then
        return false
    end
    if GameInstance.player.guide.isInForceGuide and not GameInstance.player.guide.isInHelperGuideStep then
        return false
    end
    return self.inMainHud
end
RadioCtrl.TryPauseCurRadio = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    self:_PauseCurRadio()
end
RadioCtrl.TryContinueCurRadio = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    self:_ContinueCurRadio()
end
RadioCtrl._TryHide = HL.Method(HL.Opt(HL.Boolean)) << function(self, useAnim)
    if self:IsHide() then
        return
    end
    if useAnim then
        self.m_needHide = true
        self:PlayAnimationOutWithCallback(function()
            if self.m_needHide then
                self:Hide()
            end
        end)
    else
        self:Hide()
    end
end
RadioCtrl._TryShowRadio = HL.Method().Return(HL.Boolean) << function(self)
    if #self.m_waitingQueue <= 0 then
        return false
    end
    local data = self.m_waitingQueue[1]
    local radioId = data.radioId
    if not self:_CheckCanPlay(radioId) then
        return false
    end
    if not self:IsShow() then
        return false
    end
    table.remove(self.m_waitingQueue, 1)
    self:_DoShowRadio(data)
    if BEYOND_DEBUG then
        self:_UpdateLog()
    end
    return true
end
HL.Commit(RadioCtrl)