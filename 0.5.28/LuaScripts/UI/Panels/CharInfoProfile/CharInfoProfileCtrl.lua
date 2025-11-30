local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CharInfoProfile
CharInfoProfileCtrl = HL.Class('CharInfoProfileCtrl', uiCtrl.UICtrl)
local MESSAGE_STATE_NAME = { SIMPLE = "simple", COLLAPSED = "collapsed", EXPANDED = "expanded", }
local RECORD_STATE_NAME = { LOCKED = "locked", COLLAPSED = "collapsed", EXPANDED = "expanded", FIXED = "fixed", }
local VOICE_STATE_NAME = { LOCKED = "locked", PLAYING = "playing", NORMAL = "normal", }
local LOCK_DESC_FORMAT = { [GEnums.CharDocUnlockType.DefaultUnlock] = Language.LUA_CHAR_PROFILE_LOCK_NONE_FORMAT, [GEnums.CharDocUnlockType.ReachLevel] = Language.LUA_CHAR_PROFILE_LOCK_REACH_LEVEL_FORMAT, [GEnums.CharDocUnlockType.ReachBreakStage] = Language.LUA_CHAR_PROFILE_LOCK_REACH_BREAK_STAGE_FORMAT, [GEnums.CharDocUnlockType.ReachPotentialLevel] = Language.LUA_CHAR_PROFILE_LOCK_REACH_POTENTIAL_FORMAT, [GEnums.CharDocUnlockType.ReachFavorability] = Language.LUA_CHAR_PROFILE_LOCK_REACH_FAVORABILITY_FORMAT, }
local TAB_STATE_NAME = { [0] = "none", [1] = "message", [2] = "record", [3] = "voice", }
local TAB_RED_DOT_KEY = { [2] = "CharDoc", [3] = "CharVoice", }
local TAB_ANIM_NAME = { OPEN = "btnprofiletab_open", CLOSE = "btnprofiletab_close", }
CharInfoProfileCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.P_CHAR_INFO_SELECT_CHAR_CHANGE] = '_OnSelectedCharChange', [MessageConst.ON_CHAR_FRIENDSHIP_CHANGED] = '_OnCharFriendshipChanged', }
CharInfoProfileCtrl.m_charTemplateId = HL.Field(HL.String) << ''
CharInfoProfileCtrl.m_charInstId = HL.Field(HL.Number) << -1
CharInfoProfileCtrl.m_charBagSystem = HL.Field(CS.Beyond.Gameplay.CharBagSystem)
CharInfoProfileCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_charTemplateId = args.initCharInfo.templateId
    self.m_charInstId = args.initCharInfo.instId
    self.m_charBagSystem = GameInstance.player.charBag
    self.m_starCellCache = UIUtils.genCellCache(self.view.starCell)
    self:RefreshAll()
    self.view.btnBack.onClick:AddListener(function()
        self:Notify(MessageConst.TOGGLE_CHAR_INFO_TOGGLE_MENU_AND_TOP_BTN, true)
        self:Notify(MessageConst.P_CHAR_INFO_PAGE_CHANGE, { pageType = UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW, })
        self.view.bgAnimWrapper:PlayOutAnimation()
    end)
    self:Notify(MessageConst.TOGGLE_CHAR_INFO_TOGGLE_MENU_AND_TOP_BTN, false)
end
CharInfoProfileCtrl.OnClose = HL.Override() << function(self)
    self:_SendProfileRead()
    self:_ClearVoice()
end
CharInfoProfileCtrl._OnSelectedCharChange = HL.Method(HL.Table) << function(self, charInfo)
    self.m_charTemplateId = charInfo.templateId
    self.m_charInstId = charInfo.instId
    self.view.simpleStateController:SetState(TAB_STATE_NAME[0])
    self:RefreshAll()
end
CharInfoProfileCtrl._OnCharFriendshipChanged = HL.Method() << function(self)
    self:_RefreshFriendship()
end
CharInfoProfileCtrl.RefreshAll = HL.Method() << function(self)
    self:_InitTab()
    self:_RefreshCharData()
    self:_RefreshFriendship()
    self:_RefreshCurrentTab()
end
CharInfoProfileCtrl.m_tabSelectedIndex = HL.Field(HL.Number) << 1
CharInfoProfileCtrl.m_tabRefreshFunction = HL.Field(HL.Table)
CharInfoProfileCtrl._InitTab = HL.Method() << function(self)
    for i = 1, 3 do
        local index = i
        local tab = self.view[string.format("tab%02d", index)]
        if TAB_RED_DOT_KEY[i] then
            tab.redDot:InitRedDot(TAB_RED_DOT_KEY[i], self.m_charTemplateId)
        else
            tab.redDot.gameObject:SetActive(false)
        end
        tab.animWrapper:SampleToOutAnimationEnd()
        tab.btn.onClick:RemoveAllListeners()
        tab.btn.onClick:AddListener(function()
            if index == self.m_tabSelectedIndex then
                return
            end
            local lastSelectedTab = self.view[string.format("tab%02d", self.m_tabSelectedIndex)]
            if lastSelectedTab then
                lastSelectedTab.animWrapper:PlayOutAnimation()
            end
            self.m_tabSelectedIndex = index
            self:_RefreshCurrentTab()
        end)
    end
    self.m_tabRefreshFunction = { [1] = "_RefreshMessage", [2] = "_RefreshRecord", [3] = "_RefreshVoice", }
end
CharInfoProfileCtrl._RefreshCurrentTab = HL.Method() << function(self)
    self:_SendProfileRead()
    self:_ClearVoice()
    self.view.simpleStateController:SetState(TAB_STATE_NAME[self.m_tabSelectedIndex])
    local selectedTab = self.view[string.format("tab%02d", self.m_tabSelectedIndex)]
    if selectedTab then
        selectedTab.animWrapper:PlayInAnimation()
    end
    local refreshFunction = self.m_tabRefreshFunction[self.m_tabSelectedIndex]
    if refreshFunction then
        self[refreshFunction](self)
    end
end
CharInfoProfileCtrl.m_profile = HL.Field(HL.Table)
CharInfoProfileCtrl.m_charTagDescData = HL.Field(HL.Userdata)
CharInfoProfileCtrl._RefreshCharData = HL.Method() << function(self)
    self.m_profile = CharInfoUtils.getCharInfoProfile(self.m_charTemplateId)
    local profileMessage = {}
    local success, charTagDescData = Tables.characterTagDesTable:TryGetValue(self.m_charTemplateId)
    if success then
        self.m_charTagDescData = charTagDescData
    end
    local hasValue
    local characterTagData
    hasValue, characterTagData = Tables.characterTagTable:TryGetValue(self.m_charTemplateId)
    if hasValue then
        table.insert(profileMessage, self:_GetTagShowData(characterTagData.blocTagId))
        table.insert(profileMessage, self:_GetTagShowData(characterTagData.raceTagId))
        self:_AddTagShowData(characterTagData.expertTagIds, profileMessage)
        self:_AddTagShowData(characterTagData.hobbyTagIds, profileMessage)
    else
        logger.error("没有找到档案配置" .. self.m_charTemplateId)
    end
    self.m_profile.profileMessage = profileMessage
end
CharInfoProfileCtrl._AddTagShowData = HL.Method(HL.Userdata, HL.Table) << function(self, tagIds, profileMessage)
    local count = #tagIds
    for i = 1, count do
        local tagShowData = self:_GetTagShowData(tagIds[CSIndex(i)])
        table.insert(profileMessage, tagShowData)
        if count > 1 then
            local numText = Language["LUA_CHAR_PROFILE_TITLE_NO_" .. i]
            if not numText then
                numText = string.format(" %d", i)
            end
            tagShowData.tageType = string.format("%s%s", tagShowData.tageType, numText)
        end
    end
end
CharInfoProfileCtrl._GetTagShowData = HL.Method(HL.String).Return(HL.Table) << function(self, tagId)
    local tagShowData = {}
    local tagData = Tables.tagDataTable[tagId]
    local tagGroupData = Tables.tagGroupDataTable[tagData.tagGroupId]
    tagShowData.tageType = tagGroupData.tagGroupName
    tagShowData.tageName = tagData.tagName
    if self.m_charTagDescData then
        local success, tagDescData = self.m_charTagDescData.tagDesc:TryGetValue(tagId)
        if success then
            tagShowData.tageDesc = tagDescData.desc
        end
    end
    return tagShowData
end
CharInfoProfileCtrl._GetLockedDesc = HL.Method(GEnums.CharDocUnlockType, HL.Number).Return(HL.String) << function(self, unlockType, unlockValue)
    if unlockType == GEnums.CharDocUnlockType.ReachFavorability then
        local friendshipLv = CSPlayerDataUtil.GetFriendshipLevel(unlockValue)
        unlockValue = Tables.spaceshipCharRelationLevelTable[friendshipLv].favorDesc
    end
    return string.format(LOCK_DESC_FORMAT[unlockType], unlockValue)
end
CharInfoProfileCtrl.m_messageCellCache = HL.Field(HL.Forward("UIListCache"))
CharInfoProfileCtrl._RefreshMessage = HL.Method() << function(self)
    if not self.m_messageCellCache then
        self.m_messageCellCache = UIUtils.genCellCache(self.view.messageNode)
    end
    local profileMessage = self.m_profile.profileMessage
    self.m_messageCellCache:Refresh(#profileMessage, function(cell, luaIndex)
        local data = profileMessage[luaIndex]
        cell.textTitle.text = data.tageType
        cell.textDataSimple.text = data.tageName
        cell.textData.text = data.tageName
        cell.textDes.text = data.tageDesc
        local isSimple = string.isEmpty(data.tageDesc)
        local stateName = isSimple and MESSAGE_STATE_NAME.SIMPLE or MESSAGE_STATE_NAME.COLLAPSED
        cell.simpleStateController:SetState(stateName)
        cell.togTitle.isOn = false
        cell.togTitle.gameObject:GetComponent("NonDrawingGraphic").raycastTarget = not isSimple
        cell.togTitle.onValueChanged:RemoveAllListeners()
        cell.togTitle.onValueChanged:AddListener(function(isOn)
            if isSimple then
                return
            end
            if isOn then
                cell.simpleStateController:SetState(MESSAGE_STATE_NAME.EXPANDED)
            else
                cell.simpleStateController:SetState(MESSAGE_STATE_NAME.COLLAPSED)
            end
        end)
    end)
    self.view.recordList:ScrollTo(Vector2(0, 0), false)
end
CharInfoProfileCtrl.m_recordCellCache = HL.Field(HL.Forward("UIListCache"))
CharInfoProfileCtrl._RefreshRecord = HL.Method() << function(self)
    if not self.m_recordCellCache then
        self.m_recordCellCache = UIUtils.genCellCache(self.view.recordNode)
        self.view.recordList.onValueChanged:AddListener(function()
            self.m_readDocs = self.m_readDocs or {}
            for i = 1, self.m_recordCellCache:GetCount() do
                local data = self.m_profile.profileRecord[CSIndex(i)]
                if data and self.m_charBagSystem:IsCharDocUnread(data.id) and not self.m_readDocs[data.id] then
                    local cell = self.m_recordCellCache:GetItem(i)
                    if self.view.recordList:IsCellViewed(cell.transform) then
                        self.m_readDocs[data.id] = true
                    end
                end
            end
        end)
    end
    local profileRecord = self.m_profile.profileRecord
    self.m_recordCellCache:Refresh(profileRecord.Count, function(cell, luaIndex)
        local data = profileRecord[CSIndex(luaIndex)]
        local isLocked = not self.m_charBagSystem:IsCharDocUnlocked(data.id)
        local stateName = isLocked and RECORD_STATE_NAME.LOCKED or (luaIndex <= 2 and RECORD_STATE_NAME.FIXED or RECORD_STATE_NAME.COLLAPSED)
        cell.simpleStateController:SetState(stateName)
        if isLocked then
            cell.redDot:Stop()
            cell.textUnlockPrompt.text = self:_GetLockedDesc(data.unlockType, data.unlockValue)
            cell.lockedBtn.onClick:RemoveAllListeners()
            cell.lockedBtn.onClick:AddListener(function()
                Notify(MessageConst.SHOW_TOAST, Language.LUA_CHAR_PROFILE_DOC_LOCKED)
            end)
        else
            if luaIndex <= 2 then
                cell.redDot:Stop()
                if self.m_charBagSystem:IsCharDocUnread(data.id) then
                    self.m_readDocs = self.m_readDocs or {}
                    self.m_readDocs[data.id] = true
                end
            else
                cell.redDot:InitRedDot("CharDocEntry", data.id)
            end
            cell.textRecordTitle.text = data.recordTitle
            cell.textRecordDetail.text = UIUtils.resolveTextStyle(data.recordDesc)
            cell.btnOpen.onClick:RemoveAllListeners()
            cell.btnOpen.onClick:AddListener(function()
                cell.simpleStateController:SetState(RECORD_STATE_NAME.EXPANDED)
                if self.m_charBagSystem:IsCharDocUnread(data.id) then
                    self.m_charBagSystem:SetCharDocRead({ data.id })
                end
            end)
            cell.btnPackUp.onClick:RemoveAllListeners()
            cell.btnPackUp.onClick:AddListener(function()
                cell.simpleStateController:SetState(RECORD_STATE_NAME.COLLAPSED)
            end)
        end
    end)
    self.view.recordList:ScrollTo(Vector2(0, 0), true)
end
CharInfoProfileCtrl.m_getVoiceCell = HL.Field(HL.Function)
CharInfoProfileCtrl.m_voiceSelectIndex = HL.Field(HL.Number) << -1
CharInfoProfileCtrl._RefreshVoice = HL.Method() << function(self)
    if not self.m_getVoiceCell then
        self.m_getVoiceCell = UIUtils.genCachedCellFunction(self.view.voiceNode)
        self.view.voiceList.onUpdateCell:AddListener(function(object, csIndex)
            self:_VoiceOnUpdateCell(self.m_getVoiceCell(object), LuaIndex(csIndex))
        end)
    end
    self.m_voiceSelectIndex = -1
    self.view.voiceList:UpdateCount(self.m_profile.profileVoice.Count, true, true)
end
CharInfoProfileCtrl._VoiceOnUpdateCell = HL.Method(HL.Table, HL.Number) << function(self, cell, luaIndex)
    local isSelected = self.m_voiceSelectIndex == luaIndex
    local data = self.m_profile.profileVoice[CSIndex(luaIndex)]
    cell.textNormalTitle.text = data.voiceTitle
    cell.textPlayingTitle.text = data.voiceTitle
    cell.redDot:InitRedDot("CharVoiceEntry", data.id)
    local isLocked = not self.m_charBagSystem:IsCharVoiceUnlocked(data.id)
    local stateName = isLocked and VOICE_STATE_NAME.LOCKED or (isSelected and VOICE_STATE_NAME.PLAYING or VOICE_STATE_NAME.NORMAL)
    cell.simpleStateController:SetState(stateName)
    if isSelected then
        self:_SetVoiceCellIsPlaying(cell, self.m_voiceHandleId > 0)
    end
    if isLocked then
        cell.textLockedTitle.text = self:_GetLockedDesc(data.unlockType, data.unlockValue)
    end
    cell.btnOpenVoice.onClick:RemoveAllListeners()
    cell.btnOpenVoice.onClick:AddListener(function()
        if isLocked then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_CHAR_PROFILE_VOICE_LOCKED)
            return
        end
        self:_ClearVoice()
        self.m_voiceSelectIndex = luaIndex
        self:_PlayVoice()
        if self.m_charBagSystem:IsCharVoiceUnread(data.id) then
            self.m_charBagSystem:SetCharVoiceRead({ data.id })
        end
    end)
    if not isLocked then
        if self.m_charBagSystem:IsCharVoiceUnread(data.id) then
            self.m_readVoices = self.m_readVoices or {}
            self.m_readVoices[data.id] = true
        end
    end
end
CharInfoProfileCtrl._SetVoiceCellIsPlaying = HL.Method(HL.Table, HL.Boolean) << function(self, cell, isPlaying)
    cell.imgDataBg.gameObject:SetActive(isPlaying)
    cell.imgPlaying.gameObject:SetActive(isPlaying)
    cell.imgPlay.gameObject:SetActive(not isPlaying)
end
CharInfoProfileCtrl.m_stopVoiceTimerId = HL.Field(HL.Number) << -1
CharInfoProfileCtrl.m_voiceHandleId = HL.Field(HL.Number) << -1
CharInfoProfileCtrl._PlayVoice = HL.Method() << function(self)
    local data = self.m_profile.profileVoice[CSIndex(self.m_voiceSelectIndex)]
    local voiceId = self.m_charTemplateId .. "_" .. data.voiceID
    local res, duration = VoiceUtils.TryGetVoiceDuration(voiceId)
    if res then
        self.m_voiceHandleId = VoiceManager:SpeakNarrative(voiceId, nil, CS.Beyond.Gameplay.Audio.NarrativeVoiceConfig.CHAR_PROFILE_INFO_CONFIG)
        self.m_stopVoiceTimerId = self:_StartTimer(duration, function()
            self:_StopVoice()
        end)
        if self.m_voiceSelectIndex > 0 then
            local object = self.view.voiceList:Get(CSIndex(self.m_voiceSelectIndex))
            if object then
                local cell = self.m_getVoiceCell(object)
                cell.simpleStateController:SetState(VOICE_STATE_NAME.PLAYING)
                self:_SetVoiceCellIsPlaying(cell, true)
            end
        end
        self.view.voiceInformation.gameObject:SetActive(true)
        self.view.roleInformation.gameObject:SetActive(false)
        self.view.textVoiceInformation.text = data.voiceDesc
    else
        logger.error("no such voiceId: " .. voiceId, "!!!")
    end
end
CharInfoProfileCtrl._ClearVoice = HL.Method() << function(self)
    self:_StopVoice()
    if self.m_voiceSelectIndex > 0 then
        local object = self.view.voiceList:Get(CSIndex(self.m_voiceSelectIndex))
        if object then
            local cell = self.m_getVoiceCell(object)
            cell.simpleStateController:SetState(VOICE_STATE_NAME.NORMAL)
        end
        self.m_voiceSelectIndex = -1
    end
    self.view.voiceInformation.gameObject:SetActive(false)
    self.view.roleInformation.gameObject:SetActive(true)
end
CharInfoProfileCtrl._StopVoice = HL.Method() << function(self)
    if self.m_stopVoiceTimerId >= 0 then
        self:_ClearTimer(self.m_stopVoiceTimerId)
        self.m_stopVoiceTimerId = -1
    end
    if self.m_voiceHandleId >= 0 then
        VoiceManager:StopVoice(self.m_voiceHandleId)
        self.m_voiceHandleId = -1
    end
    if self.m_voiceSelectIndex > 0 then
        local object = self.view.voiceList:Get(CSIndex(self.m_voiceSelectIndex))
        if object then
            local cell = self.m_getVoiceCell(object)
            self:_SetVoiceCellIsPlaying(cell, false)
        end
    end
end
CharInfoProfileCtrl.m_starCellCache = HL.Field(HL.Forward("UIListCache"))
CharInfoProfileCtrl._RefreshFriendship = HL.Method() << function(self)
    local charCfg = Tables.characterTable[self.m_charTemplateId]
    self.view.charNameTextShadow.text = charCfg.name
    self.m_starCellCache:Refresh(charCfg.rarity)
    local isEndmin = CharInfoUtils.isEndmin(self.m_charTemplateId)
    self.view.lowerNode.gameObject:SetActive(not isEndmin)
    if isEndmin then
        return
    end
    self.view.friendshipNode:InitFriendshipNode(self.m_charInstId)
    local friendshipLevel = CSPlayerDataUtil.GetFriendshipLevelByChar(self.m_charTemplateId)
    self.view.friendshipTxt.text = Tables.spaceshipCharRelationLevelTable[friendshipLevel].favorDesc
end
CharInfoProfileCtrl.m_readVoices = HL.Field(HL.Table)
CharInfoProfileCtrl.m_readDocs = HL.Field(HL.Table)
CharInfoProfileCtrl._SendProfileRead = HL.Method() << function(self)
    if self.m_readVoices then
        local voiceIdList = {}
        for voiceId, _ in pairs(self.m_readVoices) do
            table.insert(voiceIdList, voiceId)
        end
        if #voiceIdList > 0 then
            self.m_charBagSystem:SetCharVoiceRead(voiceIdList)
        end
        self.m_readVoices = nil
    end
    if self.m_readDocs then
        local docIdList = {}
        for docId, _ in pairs(self.m_readDocs) do
            table.insert(docIdList, docId)
        end
        if #docIdList > 0 then
            self.m_charBagSystem:SetCharDocRead(docIdList)
        end
        self.m_readDocs = nil
    end
end
HL.Commit(CharInfoProfileCtrl)