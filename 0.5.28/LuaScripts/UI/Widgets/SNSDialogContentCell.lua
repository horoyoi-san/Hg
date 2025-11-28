local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSDialogContentCell = HL.Class('SNSDialogContentCell', UIWidgetBase)
SNSDialogContentCell.m_othersTextOrPicWidget = HL.Field(HL.Any)
SNSDialogContentCell.m_selfTextOrPicWidget = HL.Field(HL.Any)
SNSDialogContentCell.m_taskWidget = HL.Field(HL.Any)
SNSDialogContentCell.m_endLineWidget = HL.Field(HL.Any)
SNSDialogContentCell.m_videoWidget = HL.Field(HL.Any)
SNSDialogContentCell.m_voiceWidget = HL.Field(HL.Any)
SNSDialogContentCell.m_itemWidget = HL.Field(HL.Any)
SNSDialogContentCell.m_systemWidget = HL.Field(HL.Any)
SNSDialogContentCell.m_cardWidget = HL.Field(HL.Any)
SNSDialogContentCell.m_momentWidget = HL.Field(HL.Any)
SNSDialogContentCell.m_prtsWidget = HL.Field(HL.Any)
SNSDialogContentCell.m_voteWidget = HL.Field(HL.Any)
SNSDialogContentCell.m_curActiveNode = HL.Field(GameObject)
SNSDialogContentCell._OnFirstTimeInit = HL.Override() << function(self)
end
SNSDialogContentCell.InitSNSDialogContentCell = HL.Method(HL.Table, HL.Boolean, HL.Boolean, HL.Function) << function(self, dialogSingleContent, fromConstraintPanel, isGroup, onSizeChangeFunc)
    self:_FirstTimeInit()
    if self.m_curActiveNode then
        self.m_curActiveNode:SetActiveIfNecessary(false)
    end
    local contentType = dialogSingleContent.contentType
    local isContent = contentType ~= GEnums.SNSDialogContentType.System and contentType ~= GEnums.SNSDialogContentType.Task and not dialogSingleContent.endLine
    self.view.snsContentMyselfNode.gameObject:SetActiveIfNecessary(isContent and dialogSingleContent.isSelf)
    self.view.snsContentOtherNode.gameObject:SetActiveIfNecessary(isContent and not dialogSingleContent.isSelf)
    self.view.systemContentNode.gameObject:SetActiveIfNecessary(not isContent)
    if isContent then
        local node = dialogSingleContent.isSelf and self.view.snsContentMyselfNode or self.view.snsContentOtherNode
        if not dialogSingleContent.loaded then
            node.animationWrapper:PlayInAnimation()
        end
    end
    if contentType == GEnums.SNSDialogContentType.System or contentType == GEnums.SNSDialogContentType.Task or dialogSingleContent.endLine then
        local node = self.view.systemContentNode
        if contentType == GEnums.SNSDialogContentType.System then
            if not self.m_systemWidget then
                self.m_systemWidget = self:_CreateWidget(self.view.config.SYSTEM_MSG, node.transform)
            end
            self.m_systemWidget:InitSNSContentSystemMsg({ content = dialogSingleContent.content, loaded = dialogSingleContent.loaded })
            self.m_curActiveNode = self.m_systemWidget.gameObject
        elseif contentType == GEnums.SNSDialogContentType.Task then
            if not self.m_taskWidget then
                self.m_taskWidget = self:_CreateWidget(self.view.config.TASK, node.transform)
            end
            self.m_taskWidget:InitSNSContentTask({ missionId = dialogSingleContent.contentParam[0], loaded = dialogSingleContent.loaded })
            self.m_curActiveNode = self.m_taskWidget.gameObject
        elseif dialogSingleContent.endLine and not dialogSingleContent.endLineForceHide then
            if not self.m_endLineWidget then
                self.m_endLineWidget = self:_CreateWidget(self.view.config.END_LINE, node.transform)
            end
            self.m_endLineWidget:InitSNSContentEndLine({ loaded = dialogSingleContent.loaded })
            self.m_curActiveNode = self.m_endLineWidget.gameObject
        end
    else
        local node = dialogSingleContent.isSelf and self.view.snsContentMyselfNode or self.view.snsContentOtherNode
        node.isFirstPlaceholder.gameObject:SetActiveIfNecessary(dialogSingleContent.isFirst)
        node.headIconNode.gameObject:SetActiveIfNecessary(dialogSingleContent.isFirst)
        node.nameTxt.gameObject:SetActiveIfNecessary(dialogSingleContent.isFirst and isGroup)
        node.groupOwnerNode.gameObject:SetActiveIfNecessary(dialogSingleContent.isGroupOwner and dialogSingleContent.isFirst)
        if dialogSingleContent.isFirst then
            local iconName = dialogSingleContent.isSelf and SNSUtils.getEndminCharHeadIcon() or dialogSingleContent.icon
            node.headIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ROUND_CHAR_HEAD, iconName)
            node.nameTxt.text = dialogSingleContent.isSelf and SNSUtils.getPlayerNameOrPlaceholder() or dialogSingleContent.speaker
        end
        if contentType == GEnums.SNSDialogContentType.Text or contentType == GEnums.SNSDialogContentType.Image or contentType == GEnums.SNSDialogContentType.Sticker then
            local arg = {}
            if contentType == GEnums.SNSDialogContentType.Text then
                arg.text = dialogSingleContent.content
            elseif contentType == GEnums.SNSDialogContentType.Image then
                arg.image = SNSUtils.getDiffPicNameByGender(dialogSingleContent.contentParam)
            elseif contentType == GEnums.SNSDialogContentType.Sticker then
                arg.sticker = dialogSingleContent.contentParam[0]
            end
            arg.loadingTime = dialogSingleContent.loadingTime or 0.5
            arg.loaded = dialogSingleContent.loaded
            arg.isSelf = dialogSingleContent.isSelf
            arg.needSpecEffect = dialogSingleContent.needSpecEffect
            arg.fromConstraintPanel = fromConstraintPanel
            if dialogSingleContent.emojiCommentArgs then
                arg.emojiId = dialogSingleContent.emojiCommentArgs.emojiId
                arg.emojiInfo = dialogSingleContent.emojiCommentArgs.optionInfo
            end
            if dialogSingleContent.isSelf then
                if not self.m_selfTextOrPicWidget then
                    self.m_selfTextOrPicWidget = self:_CreateWidget(self.view.config.TEXT_OR_PIC_SELF, node.content)
                end
                self.m_selfTextOrPicWidget:InitSNSContentTextOrPic(arg)
                self.m_curActiveNode = self.m_selfTextOrPicWidget.gameObject
            else
                if not self.m_othersTextOrPicWidget then
                    self.m_othersTextOrPicWidget = self:_CreateWidget(self.view.config.TEXT_OR_PIC, node.content)
                end
                self.m_othersTextOrPicWidget:InitSNSContentTextOrPic(arg, onSizeChangeFunc)
                self.m_curActiveNode = self.m_othersTextOrPicWidget.gameObject
            end
        elseif contentType == GEnums.SNSDialogContentType.Video then
            if not self.m_videoWidget then
                self.m_videoWidget = self:_CreateWidget(self.view.config.VIDEO, node.content)
            end
            self.m_videoWidget:InitSNSContentVideo({ imageName = dialogSingleContent.contentParam[0], videoName = dialogSingleContent.contentParam[1], loaded = dialogSingleContent.loaded })
            self.m_curActiveNode = self.m_videoWidget.gameObject
        elseif contentType == GEnums.SNSDialogContentType.Voice then
            if not self.m_voiceWidget then
                self.m_voiceWidget = self:_CreateWidget(self.view.config.VOICE, node.content)
            end
            self.m_voiceWidget:InitSNSContentVoice({ voiceId = dialogSingleContent.contentParam[0], voiceText = dialogSingleContent.content, loaded = dialogSingleContent.loaded }, onSizeChangeFunc)
            self.m_curActiveNode = self.m_voiceWidget.gameObject
        elseif contentType == GEnums.SNSDialogContentType.Item then
            if not self.m_itemWidget then
                self.m_itemWidget = self:_CreateWidget(self.view.config.ITEM, node.content)
            end
            self.m_itemWidget:InitSNSContentItem({ itemId = dialogSingleContent.contentParam[0], loaded = dialogSingleContent.loaded })
            self.m_curActiveNode = self.m_itemWidget.gameObject
        elseif contentType == GEnums.SNSDialogContentType.Card then
            if not self.m_cardWidget then
                self.m_cardWidget = self:_CreateWidget(self.view.config.CARD, node.content)
            end
            self.m_cardWidget:InitSNSContentCard({ chatId = dialogSingleContent.contentParam[0], dialogId = dialogSingleContent.contentParam[1], loaded = dialogSingleContent.loaded })
            self.m_curActiveNode = self.m_cardWidget.gameObject
        elseif contentType == GEnums.SNSDialogContentType.Moment then
            if not self.m_momentWidget then
                self.m_momentWidget = self:_CreateWidget(self.view.config.MOMENT, node.content)
            end
            self.m_momentWidget:InitSNSContentTweet({ momentId = dialogSingleContent.contentParam[0], loaded = dialogSingleContent.loaded })
            self.m_curActiveNode = self.m_momentWidget.gameObject
        elseif contentType == GEnums.SNSDialogContentType.PRTS then
            if not self.m_prtsWidget then
                self.m_prtsWidget = self:_CreateWidget(self.view.config.PRTS, node.content)
            end
            self.m_prtsWidget:InitSNSContentPRTS({ jumpId = dialogSingleContent.contentParam[0], loaded = dialogSingleContent.loaded })
            self.m_curActiveNode = self.m_prtsWidget.gameObject
        elseif contentType == GEnums.SNSDialogContentType.Vote then
            if not self.m_voteWidget then
                self.m_voteWidget = self:_CreateWidget(self.view.config.VOTE, node.content)
            end
            local args = dialogSingleContent.voteArgs
            args.loaded = dialogSingleContent.loaded
            self.m_voteWidget:InitSNSContentVote(dialogSingleContent.voteArgs)
            self.m_curActiveNode = self.m_voteWidget.gameObject
        end
    end
    if self.m_curActiveNode then
        self.m_curActiveNode:SetActiveIfNecessary(true)
    end
end
SNSDialogContentCell._CreateWidget = HL.Method(HL.String, HL.Any).Return(HL.Any) << function(self, widgetName, parentNode)
    local go = self:_CreateGameObject(widgetName, parentNode)
    return Utils.wrapLuaNode(go)
end
SNSDialogContentCell._CreateGameObject = HL.Method(HL.String, HL.Any).Return(GameObject) << function(self, widgetName, parentNode)
    local path = string.format(UIConst.UI_SNS_DIALOG_CONTENT_WIDGETS_PATH, widgetName)
    local goAsset = self:LoadGameObject(path)
    local go = CSUtils.CreateObject(goAsset)
    go.transform:SetParent(parentNode)
    go.transform.localScale = Vector3.one
    go.transform.localPosition = Vector3.zero
    return go
end
HL.Commit(SNSDialogContentCell)
return SNSDialogContentCell