UI_SNS_EMOJI_PATH = "SNS/Emoji/"
UI_SNS_EMOJI_FORMAT = "<image=\"%s\">"
PIC_STANDARD_SIZE = Vector2(480, 270)
getChatData = function(chatInfo, chatCfg)
    local chatData = {}
    chatData.chatId = chatInfo.chatId
    chatData.isGroup = chatInfo.isGroup
    chatData.timestamp = chatInfo.timestamp
    chatData.memberNum = chatInfo.memberNum
    chatData.icon = chatCfg.icon
    chatData.listIcon = chatCfg.listIcon
    chatData.owner = chatCfg.owner
    chatData.name = SNSUtils.resolveTextPlayerName(chatCfg.name)
    chatData.desc = chatCfg.desc
    chatData.tagType = chatCfg.tagType
    chatData.isSettlementChannel = chatCfg.isSettlementChannel and chatInfo.isGroup
    return chatData
end
getPlayerNameOrPlaceholder = function()
    local playerName = Utils.getPlayerName()
    playerName = string.isEmpty(playerName) and Language.LUA_SNS_ENDMIN_NAME_PLACEHOLDER or playerName
    return playerName
end
resolveTextPlayerName = function(text)
    local targetText = string.gsub(text, UIConst.PLAYER_NAME_FORMATTER, SNSUtils.getPlayerNameOrPlaceholder())
    return targetText
end
resolveEmojiFormat = function(text)
    local path = SNSUtils.UI_SNS_EMOJI_PATH
    return string.gsub(text, "<image=\"(.-)\">", function(emojiName)
        if string.sub(emojiName, 1, string.len(path)) == path then
            return string.format(SNSUtils.UI_SNS_EMOJI_FORMAT, emojiName)
        else
            return string.format(SNSUtils.UI_SNS_EMOJI_FORMAT, path .. emojiName)
        end
    end)
end
resolveTextStyleWithPlayerName = function(text)
    local withPlayerName = SNSUtils.resolveTextPlayerName(text)
    local processEmoji = SNSUtils.resolveEmojiFormat(withPlayerName)
    local returnContent = UIUtils.resolveTextCinematic(processEmoji)
    return returnContent
end
getEndminCharHeadIcon = function()
    local curEndminCharTemplateId = CS.Beyond.Gameplay.CharUtils.curEndminCharTemplateId
    return UIConst.UI_CHAR_HEAD_PREFIX .. curEndminCharTemplateId
end
getDiffPicNameByGender = function(contentParam)
    if contentParam.Count == 0 then
        logger.warn("no pic name")
        return ""
    end
    if contentParam.Count == 1 then
        return contentParam[0]
    end
    local gender = Utils.getPlayerGender()
    return gender == CS.Proto.GENDER.GenMale and contentParam[0] or contentParam[1]
end
getTextLoadingTime = function(content, minTime, maxTime, minStrLength, maxStrLength, curve)
    local content = string.gsub(content, "(<image=.->)", function(emoji)
        return "_"
    end)
    local contentLength = string.utf8len(content)
    if contentLength >= maxStrLength then
        return maxTime
    end
    if contentLength <= minStrLength then
        return minTime
    end
    local relative = (contentLength - minStrLength) / (maxStrLength - minStrLength)
    local eva = curve:Evaluate(relative)
    return eva * (maxTime - minTime) + minTime
end
findLatestContent = function(dialogId)
    if not GameInstance.player.sns.dialogInfoDic:ContainsKey(dialogId) then
        logger.error(string.format("sns dialogInfoDic doesn't have dialogId:%s", dialogId))
        return ""
    end
    if not Tables.sNSDialogTable:ContainsKey(dialogId) then
        logger.error(string.format("sns sNSDialogTable doesn't have dialogId:%s", dialogId))
        return ""
    end
    local dialogInfo = GameInstance.player.sns.dialogInfoDic:get_Item(dialogId)
    local dialogContents = Tables.sNSDialogTable[dialogId].dialogSingData
    if not dialogContents:ContainsKey(dialogInfo.curContentId) then
        logger.error(string.format("sns dialogInfo:%s doesn't have curContentId:%s", dialogId, dialogInfo.curContentId))
        return ""
    end
    local curContent = dialogContents[dialogInfo.curContentId]
    if not Tables.sNSChatTable:ContainsKey(curContent.chatId) then
        logger.error(string.format("sns sNSChatTable doesn't have chatId:%s", curContent.chatId))
        return ""
    end
    local chatCfg = Tables.sNSChatTable[curContent.chatId]
    local isGroup = chatCfg.chatType == GEnums.SNSChatType.Group
    if curContent.isEnd then
        curContent = dialogContents[curContent.preId]
    end
    local contentPrefix = ""
    local content = ""
    local curContentType = curContent.contentType
    if curContent.optionType ~= GEnums.SNSDialogOptionType.None then
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_WRITING
    elseif curContentType == GEnums.SNSDialogContentType.Text then
        content = curContent.content
    elseif curContentType == GEnums.SNSDialogContentType.Image then
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_COMPONENT_Image
    elseif curContentType == GEnums.SNSDialogContentType.Sticker then
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_COMPONENT_Sticker
    elseif curContentType == GEnums.SNSDialogContentType.Video then
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_COMPONENT_Video
    elseif curContentType == GEnums.SNSDialogContentType.Voice then
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_COMPONENT_Voice
    elseif curContentType == GEnums.SNSDialogContentType.Item then
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_COMPONENT_Item
    elseif curContentType == GEnums.SNSDialogContentType.Card then
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_COMPONENT_Card
    elseif curContentType == GEnums.SNSDialogContentType.Moment then
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_COMPONENT_Moment
    elseif curContentType == GEnums.SNSDialogContentType.PRTS then
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_COMPONENT_PRTS
    elseif curContentType == GEnums.SNSDialogContentType.Vote then
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_COMPONENT_Vote .. curContent.content
    elseif curContentType == GEnums.SNSDialogContentType.Task then
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_COMPONENT_Task
    elseif curContentType == GEnums.SNSDialogContentType.System then
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_COMPONENT_System
    else
        content = Language.LUA_SNS_SUB_DIALOG_CELL_SHOW_CONTENT_COMPONENT_TBD
    end
    if isGroup and curContentType ~= GEnums.SNSDialogContentType.System and curContentType ~= GEnums.SNSDialogContentType.Task then
        if curContent.speaker == Tables.sNSConst.myselfSpeaker then
            contentPrefix = Language.LUA_SNS_SUB_DIALOG_CELL_GROUP_SHOW_CONTENT_MYSELF
        else
            contentPrefix = Tables.sNSChatTable[curContent.speaker].name
        end
        content = string.format(Language.LUA_SNS_SUB_DIALOG_CELL_GROUP_SHOW_CONTENT_FORMAT, contentPrefix, content)
    end
    return content
end
regulatePicSizeDelta = function(picSprite)
    if picSprite == nil then
        return SNSUtils.PIC_STANDARD_SIZE
    end
    local width = picSprite.rect.width
    local height = picSprite.rect.height
    local xRate = width / SNSUtils.PIC_STANDARD_SIZE.x
    local yRate = height / SNSUtils.PIC_STANDARD_SIZE.y
    if xRate < 1 and yRate < 1 then
        return Vector2(width, height)
    else
        local rate = xRate > yRate and xRate or yRate
        return Vector2(width / rate, height / rate)
    end
end