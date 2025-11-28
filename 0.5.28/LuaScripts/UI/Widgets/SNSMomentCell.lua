local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSMomentCell = HL.Class('SNSMomentCell', UIWidgetBase)
SNSMomentCell.m_momentId = HL.Field(HL.String) << ""
SNSMomentCell.m_curOptionId = HL.Field(HL.String) << ""
SNSMomentCell.m_onSizeChange = HL.Field(HL.Function)
SNSMomentCell.m_commentCellCache = HL.Field(HL.Forward("UIListCache"))
SNSMomentCell.m_commentOptionCache = HL.Field(HL.Forward("UIListCache"))
SNSMomentCell._OnFirstTimeInit = HL.Override() << function(self)
    self.m_commentCellCache = UIUtils.genCellCache(self.view.commentCell)
    self.m_commentOptionCache = UIUtils.genCellCache(self.view.commentOptionCell)
end
SNSMomentCell.InitSNSMomentCell = HL.Method(HL.String, HL.Any) << function(self, momentId, onSizeChange)
    self:_FirstTimeInit()
    self.m_momentId = momentId
    self.m_onSizeChange = onSizeChange
    local hasData, momentInfo = GameInstance.player.sns.momentInfoDic:TryGetValue(momentId)
    if not hasData then
        logger.error(ELogChannel.UI, "SNS推文数据中没有ID{0}", momentId)
        return
    end
    local snsTableData = Tables.sNSMomentTable[momentId]
    local chatTableData = Tables.sNSChatTable[snsTableData.owner]
    self.view.headIcon.spriteName = chatTableData.icon
    self.view.mainContent:InitSNSMomentContent(momentId)
    if snsTableData.forwardId ~= "" then
        self.view.forwardContent.gameObject:SetActiveIfNecessary(true)
        self.view.forwardContent:InitSNSMomentContent(snsTableData.forwardId)
    else
        self.view.forwardContent.gameObject:SetActiveIfNecessary(false)
    end
    self.view.likeBtn.onClick:RemoveAllListeners()
    self.view.likeBtn.onClick:AddListener(function()
        local _, momentInfo = GameInstance.player.sns.momentInfoDic:TryGetValue(momentId)
        self:_RefreshLikeContent(momentId, not momentInfo.isLike)
        GameInstance.player.sns:LikeMoment(momentId, not momentInfo.isLike)
        self:_OnRead()
        if not momentInfo.isLike then
            self.view.likeNodeAnim:PlayInAnimation()
        else
            self.view.likeNodeAnim:PlayOutAnimation()
        end
    end)
    self:_RefreshLikeContent(momentId)
    self.view.commentOptionNode.gameObject:SetActiveIfNecessary(false)
    self.view.commentBtn.onClick:RemoveAllListeners()
    if momentInfo:CanComment() then
        self.view.commentBtn.gameObject:SetActiveIfNecessary(true)
        if not momentInfo:HasFinishedComment() then
            self.view.commentBtn.onClick:AddListener(function()
                self:_ShowCommentOption(momentId)
                self:_OnRead()
            end)
        end
    else
        self.view.commentBtn.gameObject:SetActiveIfNecessary(false)
    end
    self:_RefreshCommentContent(momentId)
end
SNSMomentCell._RefreshLikeContent = HL.Method(HL.String, HL.Opt(HL.Boolean)) << function(self, momentId, isLike)
    local playerName = SNSUtils.getPlayerNameOrPlaceholder()
    local _, momentInfo = GameInstance.player.sns.momentInfoDic:TryGetValue(momentId)
    local snsTableData = Tables.sNSMomentTable[momentId]
    if isLike == nil then
        isLike = momentInfo.isLike
    end
    local likeText
    if isLike then
        likeText = string.format("<color=#%s>%s</color>", self.view.config.PLAYER_NAME_HIGHLIGHT_COLOR_STR, playerName)
    else
        likeText = ""
    end
    for i, chatId in pairs(snsTableData.likeList) do
        if i > 0 or isLike then
            likeText = likeText .. Language.LUA_SNS_LIKE_NAME_SEPARATOR
        end
        likeText = likeText .. Tables.sNSChatTable[chatId].name
    end
    if snsTableData.likeCount > 3 then
        likeText = likeText .. string.format(Language.LUA_SNS_LIKE_NAME_MORE, snsTableData.likeCount - #snsTableData.likeList)
    end
    local hasLickList = not string.isEmpty(likeText)
    self.view.likeNameText.gameObject:SetActiveIfNecessary(hasLickList)
    self.view.likeImage2.gameObject:SetActiveIfNecessary(hasLickList)
    if hasLickList then
        self.view.likeNameText.text = likeText
    end
    if isLike then
        self.view.likeImage.color = self.view.config.LIKE_BTN_COLOR_ACTIVE
        self.view.likeImage2.color = self.view.config.LIKE_BTN_COLOR_ACTIVE
    else
        self.view.likeImage.color = self.view.config.LIKE_BTN_COLOR_NORMAL
        self.view.likeImage2.color = self.view.config.LIKE_BTN_COLOR_NORMAL
    end
end
SNSMomentCell._RefreshCommentContent = HL.Method(HL.String) << function(self, momentId)
    local playerName = Utils.getPlayerName()
    local _, momentInfo = GameInstance.player.sns.momentInfoDic:TryGetValue(momentId)
    local succ, commentDataBeanDic = Tables.sNSMomentCommentTable:TryGetValue(momentId)
    if succ then
        local snsTableData = Tables.sNSMomentTable[momentId]
        local commentDataDic = commentDataBeanDic.commentSingDataDic
        local commentList = {}
        local index = 0
        local curId = "1"
        local hasData, singleData = commentDataDic:TryGetValue(curId)
        while hasData do
            if singleData.isEnd then
                break
            end
            if singleData.optionType == GEnums.SNSDialogOptionType.None then
                local speakerName
                if singleData.speakerName == "" then
                    speakerName = playerName
                else
                    speakerName = singleData.speakerName
                end
                table.insert(commentList, { speakerName, singleData.content })
                curId = singleData.nextId
            else
                if momentInfo.commentOptions.Count > index and momentInfo.commentOptions[index] > 0 then
                    local option = momentInfo.commentOptions[index]
                    index = index + 1
                    local optionData = singleData.dialogOptions[option - 1]
                    curId = optionData.optionNextId
                else
                    self.m_curOptionId = curId
                    break
                end
            end
            hasData, singleData = commentDataDic:TryGetValue(curId)
        end
        self.m_commentCellCache:Refresh(#commentList, function(cell, index)
            local name, content = unpack(commentList[index])
            if name == playerName then
                name = string.format("<color=#%s>%s</color>", self.view.config.PLAYER_NAME_HIGHLIGHT_COLOR_STR, name .. Language.LUA_COLON)
            else
                name = name .. Language.LUA_COLON
            end
            cell.nameText.text = name
            cell.contentText.text = SNSUtils.resolveTextStyleWithPlayerName(content)
        end)
    end
    if momentInfo:HasFinishedComment() then
        self.view.commentImage.color = self.view.config.COMMENT_BTN_COLOR_ACTIVE
        self.view.commentBtn.onClick:RemoveAllListeners()
    else
        self.view.commentImage.color = self.view.config.COMMENT_BTN_COLOR_NORMAL
    end
end
SNSMomentCell._ShowCommentOption = HL.Method(HL.String) << function(self, momentId)
    self.view.commentOptionNode.gameObject:SetActiveIfNecessary(true)
    local singleData = Tables.sNSMomentCommentTable[momentId].commentSingDataDic[self.m_curOptionId]
    local options = {}
    for i, v in pairs(singleData.dialogOptions) do
        if v.optionDesc ~= "" then
            table.insert(options, { index = LuaIndex(i), text = v.optionDesc, })
        end
    end
    self.view.commentOptionNode.onTriggerAutoClose:RemoveAllListeners()
    self.view.commentOptionNode.onTriggerAutoClose:AddListener(function()
        self:_HideCommentOption()
    end)
    self.m_commentOptionCache:Refresh(#options, function(cell, index)
        cell.desc.text = options[index].text
        cell.optionBtn.onClick:RemoveAllListeners()
        cell.optionBtn.onClick:AddListener(function()
            GameInstance.player.sns:SelectMomentOption(momentId, options[index].index)
            self:_RefreshCommentContent(momentId)
            self:_HideCommentOption()
        end)
    end)
    if self.m_onSizeChange ~= nil then
        self.m_onSizeChange()
    end
end
SNSMomentCell._HideCommentOption = HL.Method() << function(self)
    self.view.commentOptionNode.gameObject:SetActiveIfNecessary(false)
    if self.m_onSizeChange ~= nil then
        self.m_onSizeChange()
    end
end
SNSMomentCell._OnRead = HL.Method() << function(self)
    local _, momentInfo = GameInstance.player.sns.momentInfoDic:TryGetValue(self.m_momentId)
    if not momentInfo.hasRead then
        momentInfo.hasRead = true
        GameInstance.player.sns:ReadMoment(self.m_momentId)
    end
end
HL.Commit(SNSMomentCell)
return SNSMomentCell