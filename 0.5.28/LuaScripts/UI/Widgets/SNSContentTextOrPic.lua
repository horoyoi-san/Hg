local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSContentTextOrPic = HL.Class('SNSContentTextOrPic', UIWidgetBase)
SNSContentTextOrPic.m_emojiResultCellCache = HL.Field(HL.Forward("UIListCache"))
SNSContentTextOrPic.m_emojiIconCache = HL.Field(HL.Forward("UIListCache"))
SNSContentTextOrPic.m_textCor = HL.Field(HL.Thread)
SNSContentTextOrPic.m_onSizeChange = HL.Field(HL.Function)
SNSContentTextOrPic._OnFirstTimeInit = HL.Override() << function(self)
    self.m_emojiResultCellCache = UIUtils.genCellCache(self.view.emojiResultContent)
    self.m_emojiIconCache = UIUtils.genCellCache(self.view.emojiSelectCell)
end
SNSContentTextOrPic._OnDisable = HL.Override() << function(self)
    if self.m_textCor then
        self.m_textCor = self:_ClearCoroutine(self.m_textCor)
    end
end
SNSContentTextOrPic.InitSNSContentTextOrPic = HL.Method(HL.Table, HL.Opt(HL.Function)) << function(self, args, onSizeChange)
    self:_FirstTimeInit()
    self.m_onSizeChange = onSizeChange
    self.view.textNode.gameObject:SetActiveIfNecessary(false)
    self.view.bg.gameObject:SetActiveIfNecessary(false)
    self.view.pictureNode.gameObject:SetActiveIfNecessary(false)
    self.view.pictureBG.gameObject:SetActiveIfNecessary(false)
    self.view.stickerNode.gameObject:SetActiveIfNecessary(false)
    self.view.stickerBG.gameObject:SetActiveIfNecessary(false)
    self.view.emojiResultNode.gameObject:SetActiveIfNecessary(false)
    self.view.emojiEntryNode.gameObject:SetActiveIfNecessary(false)
    self.view.emojiSelectNode.gameObject:SetActiveIfNecessary(false)
    self.view.loadingNode.gameObject:SetActiveIfNecessary(false)
    if self.m_textCor then
        self.m_textCor = self:_ClearCoroutine(self.m_textCor)
    end
    local loadingTime = (args.isSelf or args.loaded) and 0 or args.loadingTime
    if loadingTime > 0 then
        self.m_textCor = self:_StartCoroutine(function()
            self.view.bg.gameObject:SetActiveIfNecessary(true)
            self.view.loadingNode.gameObject:SetActiveIfNecessary(true)
            self:_UpdateContainerSize()
            coroutine.wait(loadingTime)
            self.view.bg.gameObject:SetActiveIfNecessary(false)
            self.view.loadingNode.gameObject:SetActiveIfNecessary(false)
            self.view.animationWrapper:PlayInAnimation(function()
                self:_TryShowEmojiComment(args)
            end)
            self:_InitTextOrPicState(args)
            self:_UpdateContainerSize()
        end)
    else
        if not args.loaded then
            self.view.animationWrapper:PlayInAnimation()
        end
        self:_InitTextOrPicState(args)
        self:_TryShowEmojiComment(args)
    end
end
SNSContentTextOrPic._InitTextOrPicState = HL.Method(HL.Table) << function(self, args)
    if not args.loaded then
        if args.isSelf then
            AudioAdapter.PostEvent("Au_UI_Popup_SNSDialogContent_MyselfNode_Open")
        else
            AudioAdapter.PostEvent("Au_UI_Popup_SNSDialogContent_OtherNode_Open")
        end
    end
    local hasTxt = args.text ~= nil
    self.view.bg.gameObject:SetActiveIfNecessary(hasTxt)
    self.view.textNode.gameObject:SetActiveIfNecessary(hasTxt)
    if hasTxt then
        self.view.mainText.text = SNSUtils.resolveTextStyleWithPlayerName(args.text)
        self.view.textMaxWidth.preferredWidth = args.fromConstraintPanel and self.config.FROM_CONSTRAINT_PANEL or self.config.FROM_MAIN_PANEL
    end
    local hasSticker = args.sticker ~= nil
    self.view.stickerBG.gameObject:SetActiveIfNecessary(hasSticker)
    self.view.stickerNode.gameObject:SetActiveIfNecessary(hasSticker)
    if hasSticker then
        self.view.stickerImage.sprite = self:LoadSprite(UIConst.UI_SPRITE_SNS_STICKER, args.sticker)
    end
    local hasPic = args.image ~= nil
    self.view.pictureBG.gameObject:SetActiveIfNecessary(hasPic)
    self.view.pictureNode.gameObject:SetActiveIfNecessary(hasPic)
    if hasPic then
        local picSprite = self:LoadSprite(UIConst.UI_SPRITE_SNS_PICTURE, args.image)
        self.view.picImage.sprite = picSprite
        self.view.picImageRectTransform.sizeDelta = SNSUtils.regulatePicSizeDelta(picSprite)
        self.view.imageBtn.onClick:RemoveAllListeners()
        self.view.imageBtn.onClick:AddListener(function()
            Notify(MessageConst.SHOW_COMMON_PICTURE, args.image)
        end)
    end
end
SNSContentTextOrPic._TryShowEmojiComment = HL.Method(HL.Any) << function(self, args)
    if args.emojiInfo ~= nil and #args.emojiInfo > 0 then
        if args.emojiId ~= nil then
            self:_RefreshEmojiResult(args.emojiId, args)
        else
            AudioAdapter.PostEvent("Au_UI_Popup_SNSDialogContent_Options_Open")
            self.view.emojiEntryNode.gameObject:SetActiveIfNecessary(true)
            self.view.emojiSelectNode.gameObject:SetActiveIfNecessary(false)
            self.view.emojiResultNode.gameObject:SetActiveIfNecessary(false)
            self.view.emojiEntryBtn.onClick:RemoveAllListeners()
            self.view.emojiEntryBtn.onClick:AddListener(function()
                self.view.emojiEntryNode.gameObject:SetActiveIfNecessary(false)
                self.view.emojiSelectNode.gameObject:SetActiveIfNecessary(true)
                self:_UpdateContainerSize()
            end)
            self.view.emojiSelectNode.onTriggerAutoClose:AddListener(function()
                self.view.emojiEntryNode.gameObject:SetActiveIfNecessary(true)
                self.view.emojiSelectNode.gameObject:SetActiveIfNecessary(false)
                self:_UpdateContainerSize()
            end)
            self.m_emojiIconCache:Refresh(#args.emojiInfo, function(cell, index)
                local emojiInfoUnit = args.emojiInfo[index]
                cell.image.sprite = self:LoadSprite(UIConst.UI_SPRITE_SNS_EMOJI, emojiInfoUnit.emojiId)
                cell.button.onClick:RemoveAllListeners()
                cell.button.onClick:AddListener(function()
                    self.view.emojiSelectNode.gameObject:SetActiveIfNecessary(false)
                    if emojiInfoUnit.func then
                        emojiInfoUnit.func()
                    end
                end)
            end)
        end
    else
        self.view.emojiEntryNode.gameObject:SetActiveIfNecessary(false)
        self.view.emojiSelectNode.gameObject:SetActiveIfNecessary(false)
        self.view.emojiResultNode.gameObject:SetActiveIfNecessary(false)
    end
end
SNSContentTextOrPic._RefreshEmojiResult = HL.Method(HL.String, HL.Table) << function(self, selectEmojiId, args)
    self.view.emojiEntryNode.gameObject:SetActiveIfNecessary(false)
    self.view.emojiSelectNode.gameObject:SetActiveIfNecessary(false)
    self.view.emojiResultNode.gameObject:SetActiveIfNecessary(true)
    local emojiInfo = {}
    for i, info in ipairs(args.emojiInfo) do
        if (info.chatIds ~= nil and #info.chatIds > 0) or info.emojiId == selectEmojiId then
            table.insert(emojiInfo, info)
        end
    end
    local waitTime = args.needSpecEffect and SNSUtils.VOTE_RESULT_PER_PIECE_SECOND or 0
    if args.needSpecEffect then
        self.m_emojiResultCellCache:GraduallyRefresh(#emojiInfo, waitTime, function(cell, index)
            self:_UpdateEmojiResultCell(emojiInfo, selectEmojiId, cell, index)
            if args.needSpecEffect then
                cell.animationWrapper:PlayInAnimation()
                AudioAdapter.PostEvent("Au_UI_Popup_SNSDialogContent_Emoji_Open")
                self:_UpdateContainerSize()
            end
        end)
    else
        self.m_emojiResultCellCache:Refresh(#emojiInfo, function(cell, index)
            self:_UpdateEmojiResultCell(emojiInfo, selectEmojiId, cell, index)
        end)
    end
end
SNSContentTextOrPic._UpdateEmojiResultCell = HL.Method(HL.Table, HL.String, HL.Any, HL.Number) << function(self, emojiInfo, selectEmojiId, cell, index)
    local info = emojiInfo[index]
    local emojiId = info.emojiId
    cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_SNS_EMOJI, emojiId)
    local text
    if emojiId == selectEmojiId then
        text = SNSUtils.getPlayerNameOrPlaceholder()
    else
        text = ""
    end
    for i, chatId in ipairs(info.chatIds) do
        local chatTableData = Tables.sNSChatTable[chatId]
        if i > 1 or emojiId == selectEmojiId then
            text = text .. Language.LUA_SNS_LIKE_NAME_SEPARATOR
        end
        text = text .. chatTableData.name
    end
    local count = info.count or 0
    if count > #info.chatIds then
        text = text .. string.format(Language.LUA_SNS_LIKE_NAME_MORE, count - #info.chatIds)
    end
    cell.text.text = text
end
SNSContentTextOrPic._UpdateContainerSize = HL.Method(HL.Opt(HL.Boolean)) << function(self, setTop)
    if self.m_onSizeChange then
        self.m_onSizeChange(true)
    end
end
HL.Commit(SNSContentTextOrPic)
return SNSContentTextOrPic