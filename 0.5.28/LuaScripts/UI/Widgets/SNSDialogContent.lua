local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
local SNSDialogContentType = GEnums.SNSDialogContentType
local SNSDialogOptionType = GEnums.SNSDialogOptionType
local SNSGroupDialogTagType = GEnums.SNSGroupDialogTagType
local CONTENT_CELL_RECT_Y = 110
local RAW_BOTTOM_PADDING = 30
SNSDialogContent = HL.Class('SNSDialogContent', UIWidgetBase)
SNSDialogContent.m_textOptionCellCache = HL.Field(HL.Forward("UIListCache"))
SNSDialogContent.m_pictureOptionCellCache = HL.Field(HL.Forward("UIListCache"))
SNSDialogContent.m_getDialogContentCellFunc = HL.Field(HL.Function)
SNSDialogContent.m_curDialogOptions = HL.Field(HL.Table)
SNSDialogContent.m_curChatId = HL.Field(HL.String) << ""
SNSDialogContent.m_curDialogId = HL.Field(HL.String) << ""
SNSDialogContent.m_dialogIds = HL.Field(HL.Table)
SNSDialogContent.m_curDialogContent = HL.Field(HL.Table)
SNSDialogContent.m_curDialogProgress = HL.Field(HL.Number) << -1
SNSDialogContent.m_curDialogThread = HL.Field(HL.Thread)
SNSDialogContent.m_curDialogEndCb = HL.Field(HL.Function)
SNSDialogContent.m_fromConstraintPanel = HL.Field(HL.Boolean) << false
SNSDialogContent.m_curBottomPadding = HL.Field(HL.Number) << -1
SNSDialogContent._OnFirstTimeInit = HL.Override() << function(self)
    self:RegisterMessage(MessageConst.ON_SNS_DIALOG_SET_OPTION, function(args)
        self:OnSNSDialogModify(args)
    end)
    self.m_textOptionCellCache = UIUtils.genCellCache(self.view.snsTextOptionCell)
    self.m_pictureOptionCellCache = UIUtils.genCellCache(self.view.snsPictureOptionCell)
    self.m_getDialogContentCellFunc = UIUtils.genCachedCellFunction(self.view.dialogScrollList)
    self.view.dialogScrollList.additiveContainerSizeBuffer = 1000
end
SNSDialogContent.InitSNSDialogContent = HL.Method(HL.Table, HL.String, HL.Boolean, HL.Opt(HL.Function)) << function(self, snsChatData, dialogId, fromConstraintPanel, finishCb)
    self:_FirstTimeInit()
    if self.m_curChatId ~= snsChatData.chatId then
        self.view.dialogDetails:Play("snsdialogdetailpeople_in")
    end
    self.view.dialogDetailsPeopleNode.gameObject:SetActive(not snsChatData.isGroup)
    self.view.dialogDetailsGroupNode.gameObject:SetActive(snsChatData.isGroup)
    if snsChatData.isGroup then
        self.view.groupName.text = snsChatData.name
        self.view.groupDesc.text = snsChatData.desc
        self.view.groupDesc.gameObject:SetActiveIfNecessary(not string.isEmpty(snsChatData.desc))
        self.view.groupNumberNode.gameObject:SetActive(snsChatData.memberNum ~= nil)
        self.view.groupNumber.text = snsChatData.memberNum
        self.view.official.gameObject:SetActiveIfNecessary(snsChatData.tagType == SNSGroupDialogTagType.Official)
        self.view.external.gameObject:SetActiveIfNecessary(snsChatData.tagType == SNSGroupDialogTagType.External)
    else
        self.view.peopleName.text = snsChatData.name
        self.view.peopleDesc.text = snsChatData.desc
        self.view.peopleDesc.gameObject:SetActiveIfNecessary(not string.isEmpty(snsChatData.desc))
    end
    self.m_curChatId = snsChatData.chatId
    self.m_curDialogId = dialogId
    self.m_curDialogEndCb = finishCb
    self.m_fromConstraintPanel = fromConstraintPanel
    self.m_dialogIds = self:_ProcessDialogIds(snsChatData, dialogId)
    self.m_curDialogContent, self.m_curDialogOptions, self.m_curDialogProgress = self:_ProcessSNSDialogData(snsChatData.chatId, dialogId, self.m_dialogIds)
    self.view.dialogScrollList.onUpdateCell:RemoveAllListeners()
    self.view.dialogScrollList.onUpdateCell:AddListener(function(gameObject, csIndex)
        local luaIndex = LuaIndex(csIndex)
        local singleDialog = self.m_curDialogContent[luaIndex]
        local cell = self.m_getDialogContentCellFunc(gameObject)
        if singleDialog then
            cell:InitSNSDialogContentCell(singleDialog, fromConstraintPanel, snsChatData.isGroup, function(setTop)
                local transform = cell.transform
                LayoutRebuilder.ForceRebuildLayoutImmediate(transform)
                self.view.dialogScrollList:NotifyCellSizeChange(csIndex, transform.sizeDelta.y)
                if setTop then
                    self.view.dialogScrollList:ScrollToIndex(CSIndex(self.m_curDialogProgress - 1), true)
                end
            end)
        end
    end)
    self.view.dialogScrollList:UpdateCount(0)
    self.view.dialogScrollList:SetPaddingBottom(RAW_BOTTOM_PADDING)
    self.m_curBottomPadding = RAW_BOTTOM_PADDING
    if self.m_curDialogProgress == 1 then
        if self.m_curDialogContent[self.m_curDialogProgress].skipToFirstOption then
            self.m_curDialogProgress = #self.m_curDialogContent
        end
        for i = 1, self.m_curDialogProgress do
            self.m_curDialogContent[i].loaded = i <= self.m_curDialogProgress
        end
    else
        for i = 1, self.m_curDialogProgress do
            if not fromConstraintPanel or i <= self.m_curDialogProgress then
                self.m_curDialogContent[i].loaded = true
            end
        end
    end
    local noDelay = self.m_curDialogProgress == #self.m_curDialogContent
    self.view.options.gameObject:SetActiveIfNecessary(false)
    self:_StartDialog(0, noDelay and 0 or (fromConstraintPanel and 0.3 or 0.2), false)
    self:_CBT2TempProcess()
end
SNSDialogContent._CBT2TempProcess = HL.Method() << function(self)
    if self.m_curDialogId == "sns_c1m2_1" then
        CONTENT_CELL_RECT_Y = 80
    end
end
SNSDialogContent.OnSNSDialogModify = HL.Method(HL.Any) << function(self, args)
    local curContentId = unpack(args)
    local dialogCfg = Tables.sNSDialogTable[self.m_curDialogId].dialogSingData
    local isSpecialOption = false
    local curContent = dialogCfg[curContentId]
    local curCommentId = curContent.preId
    local commentContentCfg = string.isEmpty(curCommentId) and {} or dialogCfg[curCommentId]
    isSpecialOption = commentContentCfg.optionType == SNSDialogOptionType.Vote or commentContentCfg.optionType == SNSDialogOptionType.EmojiComment
    local offset = (isSpecialOption and curContent.optionType == SNSDialogOptionType.None) and -1 or 0
    self.view.optionsAnimationWrapper:PlayOutAnimation(function()
        self.view.options.gameObject:SetActiveIfNecessary(false)
    end)
    self.m_curDialogContent, self.m_curDialogOptions, self.m_curDialogProgress = self:_ProcessSNSDialogData(self.m_curChatId, self.m_curDialogId, self.m_dialogIds, isSpecialOption)
    self:_StartDialog(offset, self.config.DELAY_TIME_AFTER_OPTION, isSpecialOption)
end
SNSDialogContent.NotifyCellSizeChange = HL.Method(HL.Number, HL.Number) << function(self, csIndex, y)
    self.view.dialogScrollList:NotifyCellSizeChange(csIndex, y)
end
SNSDialogContent._StartDialog = HL.Method(HL.Number, HL.Number, HL.Boolean) << function(self, offset, corDelayTime, isSpecialOption)
    self:_ToggleScrollRectInteractable(false)
    local showingProgress = self.m_curDialogProgress + offset
    local specialOptButNoOffsetFlag = isSpecialOption and offset == 0
    if self.m_curDialogThread then
        self:_ClearCoroutine(self.m_curDialogThread)
    end
    self.m_curDialogThread = self:_StartCoroutine(function()
        local contentCount = #self.m_curDialogContent
        coroutine.wait(corDelayTime)
        while showingProgress <= contentCount do
            local curProgress = showingProgress
            local curContent = self.m_curDialogContent[curProgress]
            showingProgress = showingProgress + 1
            local optionCount = #self.m_curDialogOptions
            local needOption = curProgress == contentCount and optionCount > 0
            if curProgress ~= 0 then
                local isLastDialog = self.m_dialogIds[#self.m_dialogIds] == curContent.dialogId
                self.m_curDialogId = curContent.dialogId
                local loadingTime
                if offset < 0 and curProgress < self.m_curDialogProgress or specialOptButNoOffsetFlag then
                    local specCommentArgs = curContent.emojiCommentArgs
                    local showEmojiCount = specCommentArgs ~= nil and #specCommentArgs.needShowEmojis or 0
                    loadingTime = showEmojiCount * self.config.PER_EMOJI_SHOWING_TIME
                else
                    loadingTime = curContent.loaded and 0 or (curContent.loadingTime or self.config.NON_BUBBLE_LOADING_TIME)
                end
                self.m_curBottomPadding = self.m_curBottomPadding - CONTENT_CELL_RECT_Y
                self.view.dialogScrollList:SetPaddingBottom(math.max(self.m_curBottomPadding, RAW_BOTTOM_PADDING))
                self.view.dialogScrollList:UpdateCount(curProgress, CSIndex(curProgress))
                loadingTime = (needOption and not curContent.loadingTime) and self.config.NON_BUBBLE_NEXT_OPTION_LOADING_TIME or loadingTime
                coroutine.wait(loadingTime)
                if curProgress == self.m_curDialogProgress then
                    if curContent.loaded ~= true and not specialOptButNoOffsetFlag then
                        self:_ModifyDialogCurContent(self.m_curChatId, self.m_curDialogId, curContent.id)
                    end
                    specialOptButNoOffsetFlag = false
                    self.m_curDialogProgress = self.m_curDialogProgress + 1
                end
                local intervalTime = loadingTime == 0 and 0 or self.config.INTERVAL_SECONDS
                coroutine.wait(intervalTime)
                if isLastDialog and curContent.isEnd then
                    if self.m_curDialogEndCb then
                        self.m_curDialogEndCb()
                        self.view.dialogScrollList:ScrollToIndex(CSIndex(curProgress))
                    end
                    if not self.m_fromConstraintPanel then
                        GameInstance.player.sns:FinishDialog(self.m_curChatId, self.m_curDialogId)
                    end
                end
                curContent.loaded = true
                curContent.needSpecEffect = false
            end
            if needOption then
                local optionType = self.m_curDialogOptions[1].optionType
                local isOptionSticker = optionType == SNSDialogOptionType.Sticker
                local isOptionEmoji = optionType == SNSDialogOptionType.EmojiComment
                if not isOptionEmoji then
                    local cellCache = isOptionSticker and self.m_pictureOptionCellCache or self.m_textOptionCellCache
                    cellCache:Refresh(#self.m_curDialogOptions, function(cell, index)
                        local option = self.m_curDialogOptions[index]
                        if isOptionSticker then
                            cell.image.sprite = self:LoadSprite(UIConst.UI_SPRITE_SNS_STICKER, option.picPath)
                        else
                            cell.desc.text = SNSUtils.resolveTextStyleWithPlayerName(option.desc)
                        end
                        cell.optionBtn.onClick:RemoveAllListeners()
                        cell.optionBtn.onClick:AddListener(function()
                            self:_SelectDialogOption(option.chatId, option.dialogId, option.curContentId, index)
                        end)
                    end)
                    AudioAdapter.PostEvent("Au_UI_Popup_SNSDialogContent_Options_Open")
                    self.view.pictureOptions.gameObject:SetActiveIfNecessary(isOptionSticker)
                    self.view.textOptions.gameObject:SetActiveIfNecessary(not isOptionSticker)
                end
                self.view.options.gameObject:SetActiveIfNecessary(not isOptionEmoji)
            end
            local needPadding = (curContent ~= nil and curContent.isEnd and self.m_curDialogEndCb ~= nil) or (needOption and not self.m_curDialogOptions[1].optionType ~= SNSDialogOptionType.EmojiComment)
            if needPadding then
                LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.bottomNode)
                coroutine.step()
                self.m_curBottomPadding = self.view.bottomNode.sizeDelta.y
                self.view.dialogScrollList:SetPaddingBottom(self.m_curBottomPadding)
                self.view.dialogScrollList:ScrollToIndex(CSIndex(curProgress))
            end
        end
        self:_ToggleScrollRectInteractable(true)
    end)
end
SNSDialogContent._ProcessSNSDialogData = HL.Method(HL.String, HL.String, HL.Table, HL.Opt(HL.Boolean)).Return(HL.Table, HL.Table, HL.Number) << function(self, chatId, dialogId, dialogIds, isSpecOption)
    local dialogContent = {}
    local dialogOptions = {}
    local dialogProgress = 0
    for _, dialogId in ipairs(dialogIds) do
        local getDialogSucc, dialogInfo = GameInstance.player.sns.dialogInfoDic:TryGetValue(dialogId)
        if not getDialogSucc then
            logger.warn("没有获取到对应的dialogInfo, dialogId:%s", dialogId)
            return dialogContent, dialogOptions, dialogProgress
        end
        local rawChatConfig = Tables.sNSChatTable[chatId]
        local rawDialogConfig = Tables.sNSDialogTable[dialogId].dialogSingData
        local preSpeaker = ""
        local checkOptionCsIndex = 0
        local myself = Tables.sNSConst.myselfSpeaker
        local curSingleDialogCfg = rawDialogConfig[Tables.sNSConst.snsDialogStartId]
        while not curSingleDialogCfg.isEnd do
            while curSingleDialogCfg.dialogOptions.Count > 0 do
                local dialogInfoOptionCount = dialogInfo.options.Count
                if checkOptionCsIndex < dialogInfoOptionCount then
                    local option = curSingleDialogCfg.dialogOptions[CSIndex(dialogInfo.options[checkOptionCsIndex])]
                    curSingleDialogCfg = rawDialogConfig[option.optionNextId]
                    checkOptionCsIndex = checkOptionCsIndex + 1
                else
                    for i = 0, curSingleDialogCfg.dialogOptions.Count - 1 do
                        local dialogOptionsCfg = curSingleDialogCfg.dialogOptions[i]
                        local option = {}
                        option.chatId = curSingleDialogCfg.chatId
                        option.dialogId = curSingleDialogCfg.dialogId
                        option.curContentId = curSingleDialogCfg.id
                        option.desc = dialogOptionsCfg.optionDesc
                        option.nextId = dialogOptionsCfg.optionNextId
                        option.optionType = curSingleDialogCfg.optionType
                        if rawDialogConfig[dialogOptionsCfg.optionNextId].contentParam.Count > 0 then
                            option.picPath = rawDialogConfig[dialogOptionsCfg.optionNextId].contentParam[0]
                        end
                        table.insert(dialogOptions, option)
                    end
                    break
                end
            end
            if #dialogOptions > 0 then
                break
            end
            local isSelf = curSingleDialogCfg.speaker == myself
            local dialogSingleContent = {}
            dialogSingleContent.isSelf = isSelf
            dialogSingleContent.dialogId = dialogId
            dialogSingleContent.chatId = chatId
            dialogSingleContent.skipToFirstOption = curSingleDialogCfg.skipToFirstOption
            dialogSingleContent.id = curSingleDialogCfg.id
            dialogSingleContent.contentType = curSingleDialogCfg.contentType
            dialogSingleContent.contentParam = curSingleDialogCfg.contentParam
            dialogSingleContent.optionType = curSingleDialogCfg.optionType
            dialogSingleContent.content = curSingleDialogCfg.content
            dialogSingleContent.isGroupOwner = curSingleDialogCfg.speaker == rawChatConfig.owner
            dialogSingleContent.isFirst = curSingleDialogCfg.speaker ~= preSpeaker
            preSpeaker = curSingleDialogCfg.speaker
            if curSingleDialogCfg.contentType == SNSDialogContentType.Text then
                if isSelf then
                    dialogSingleContent.loadingTime = self.config.ENDMIN_CONTENT_SECONDS
                else
                    dialogSingleContent.loadingTime = SNSUtils.getTextLoadingTime(dialogSingleContent.content, self.config.LOADING_MIN_TIME, self.config.LOADING_MAX_TIME, self.config.MIN_STR_LENGTH, self.config.MAX_STR_LENGTH, self.config.LOADING_TIME_CURVE)
                end
            elseif curSingleDialogCfg.contentType == SNSDialogContentType.PRTS then
                dialogSingleContent.loadingTime = 0.1
            elseif curSingleDialogCfg.contentType == SNSDialogContentType.Task then
                dialogSingleContent.loadingTime = 0
            end
            if not isSelf and not string.isEmpty(curSingleDialogCfg.speaker) then
                local speakerInfo = Tables.sNSChatTable[curSingleDialogCfg.speaker]
                dialogSingleContent.icon = speakerInfo.icon
                dialogSingleContent.speaker = speakerInfo.name
            end
            if curSingleDialogCfg.contentType == SNSDialogContentType.Text or curSingleDialogCfg.contentType == SNSDialogContentType.Sticker then
                local nextSingleDialogCfg = rawDialogConfig[curSingleDialogCfg.nextId]
                if nextSingleDialogCfg.optionType == SNSDialogOptionType.EmojiComment then
                    local hasComment = checkOptionCsIndex < dialogInfo.options.Count
                    local args = {}
                    local commentOptions = nextSingleDialogCfg.dialogOptions
                    if hasComment then
                        args.emojiId = commentOptions[CSIndex(dialogInfo.options[checkOptionCsIndex])].optionResPath
                    end
                    args.optionInfo = {}
                    args.needShowEmojis = {}
                    for csIndex, option in pairs(commentOptions) do
                        local optionUnit = {}
                        optionUnit.emojiId = option.optionResPath
                        optionUnit.chatIds = {}
                        for _, chatId in pairs(option.npcIds) do
                            table.insert(optionUnit.chatIds, chatId)
                        end
                        local npcCount = string.isEmpty(option.npcCount) and 0 or tonumber(option.npcCount)
                        optionUnit.count = npcCount
                        optionUnit.func = function()
                            self:_SelectDialogOption(self.m_curChatId, self.m_curDialogId, nextSingleDialogCfg.id, LuaIndex(csIndex))
                        end
                        table.insert(args.optionInfo, optionUnit)
                        if npcCount > 0 or hasComment then
                            if npcCount > 0 and not lume.find(args.needShowEmojis, csIndex) then
                                table.insert(args.needShowEmojis, csIndex)
                            end
                            if hasComment then
                                local playerOptCsIndex = CSIndex(dialogInfo.options[checkOptionCsIndex])
                                if not lume.find(args.needShowEmojis, playerOptCsIndex) then
                                    table.insert(args.needShowEmojis, playerOptCsIndex)
                                end
                            end
                        end
                    end
                    dialogSingleContent.emojiCommentArgs = args
                    dialogSingleContent.needSpecEffect = checkOptionCsIndex == dialogInfo.options.Count - 1 and isSpecOption == true
                end
            end
            if curSingleDialogCfg.contentType == SNSDialogContentType.Vote then
                local hasVote = checkOptionCsIndex < dialogInfo.options.Count
                local args = {}
                args.title = curSingleDialogCfg.content
                if hasVote then
                    args.optionIndex = dialogInfo.options[checkOptionCsIndex]
                    args.optionInfo = {}
                    for _, option in pairs(rawDialogConfig[curSingleDialogCfg.nextId].dialogOptions) do
                        local optionUnit = {}
                        optionUnit.name = option.optionDesc
                        optionUnit.chatIds = {}
                        for _, chatId in pairs(option.npcIds) do
                            table.insert(optionUnit.chatIds, chatId)
                        end
                        optionUnit.count = tonumber(option.npcCount)
                        table.insert(args.optionInfo, optionUnit)
                    end
                end
                dialogSingleContent.voteArgs = args
                dialogSingleContent.needSpecEffect = checkOptionCsIndex == dialogInfo.options.Count - 1 and isSpecOption == true
            end
            table.insert(dialogContent, dialogSingleContent)
            local pre = curSingleDialogCfg
            curSingleDialogCfg = rawDialogConfig[pre.nextId]
            if curSingleDialogCfg.isEnd then
                if not self.m_fromConstraintPanel or (self.m_fromConstraintPanel and rawChatConfig.isSettlementChannel) then
                    table.insert(dialogContent, { id = curSingleDialogCfg.id, dialogId = dialogId, endLine = true, isEnd = true, })
                else
                    dialogSingleContent.isEnd = true
                end
            end
        end
        if #dialogOptions > 0 then
            break
        end
    end
    local curDialogId
    local curContentId
    for _, dialogId in ipairs(dialogIds) do
        local getDialogSucc, dialogInfo = GameInstance.player.sns.dialogInfoDic:TryGetValue(dialogId)
        if getDialogSucc and not dialogInfo.isEnd and curDialogId == nil then
            curDialogId = dialogId
            curContentId = dialogInfo.curContentId
        end
    end
    if curContentId == nil then
        local dialogId = dialogIds[#dialogIds]
        local _, dialogInfo = GameInstance.player.sns.dialogInfoDic:TryGetValue(dialogId)
        curDialogId = dialogId
        curContentId = dialogInfo.curContentId
    end
    for index, value in ipairs(dialogContent) do
        if value.dialogId == curDialogId and value.id == curContentId then
            dialogProgress = index
            break
        end
        dialogProgress = index
        value.loaded = true
    end
    return dialogContent, dialogOptions, dialogProgress
end
SNSDialogContent._ProcessDialogIds = HL.Method(HL.Table, HL.String).Return(HL.Table) << function(self, snsChatData, dialogId)
    local returnIds = {}
    if snsChatData.isSettlementChannel then
        for i = #snsChatData.dialogData, 1, -1 do
            local dialogData = snsChatData.dialogData[i]
            table.insert(returnIds, dialogData.dialogId)
        end
    else
        table.insert(returnIds, dialogId)
    end
    return returnIds
end
SNSDialogContent._SelectDialogOption = HL.Method(HL.String, HL.String, HL.String, HL.Number) << function(self, chatId, dialogId, contentId, index)
    GameInstance.player.sns:SelectDialogOption(chatId, dialogId, contentId, index)
end
SNSDialogContent._ModifyDialogCurContent = HL.Method(HL.String, HL.String, HL.String) << function(self, chatId, dialogId, contentId)
    GameInstance.player.sns:ModifyDialogCurContent(chatId, dialogId, contentId)
    local _, dialogCfg = Tables.sNSDialogTable:TryGetValue(dialogId)
    if dialogCfg then
        local singleDialogCfg = dialogCfg.dialogSingData
        local _, dialogContentCfg = singleDialogCfg:TryGetValue(contentId)
        local nextContentId = dialogContentCfg.nextId
        if dialogContentCfg and not string.isEmpty(nextContentId) then
            local _, nextDialogContentCfg = singleDialogCfg:TryGetValue(nextContentId)
            if nextDialogContentCfg.isEnd then
                GameInstance.player.sns:ModifyDialogCurContent(chatId, dialogId, nextContentId)
            end
        end
    end
end
SNSDialogContent._ToggleScrollRectInteractable = HL.Method(HL.Boolean) << function(self, isOn)
    self.view.dialogScrollRect.enabled = isOn
end
HL.Commit(SNSDialogContent)
return SNSDialogContent