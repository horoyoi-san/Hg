local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSContentVote = HL.Class('SNSContentVote', UIWidgetBase)
SNSContentVote.m_args = HL.Field(HL.Table)
SNSContentVote.m_voteResultCellCache = HL.Field(HL.Forward("UIListCache"))
SNSContentVote.m_headIconCacheDic = HL.Field(HL.Table)
SNSContentVote._OnFirstTimeInit = HL.Override() << function(self)
    self.m_voteResultCellCache = UIUtils.genCellCache(self.view.voteResultCell)
    self.m_headIconCacheDic = {}
end
SNSContentVote.InitSNSContentVote = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    if not args.loaded then
        self.view.animationWrapper:PlayInAnimation()
        AudioAdapter.PostEvent("Au_UI_Popup_SNSDialogContent_OtherNode_Open")
    end
    self.m_args = args
    self.view.titleText.text = args.title
    local hasVoted = args.optionIndex ~= nil and args.optionIndex > 0
    if not hasVoted then
        self.view.titleText.color = self.view.config.TEXT_SPECIAL_COLOR
        self.view.icon.color = self.view.config.TEXT_SPECIAL_COLOR
        self.view.voteResultNode.gameObject:SetActiveIfNecessary(false)
    else
        self.view.titleText.color = self.view.config.TEXT_NORMAL_COLOR
        self.view.icon.color = self.view.config.TEXT_NORMAL_COLOR
        self:RefreshVoteResult(args.optionIndex)
    end
end
SNSContentVote.RefreshVoteResult = HL.Method(HL.Number) << function(self, selectOptionIndex)
    self.view.voteResultNode.gameObject:SetActiveIfNecessary(true)
    local totalCount = 1
    for i = 1, #self.m_args.optionInfo do
        local info = self.m_args.optionInfo[i]
        totalCount = totalCount + (info.count or (info.chatIds and #info.chatIds) or 0)
    end
    self.m_voteResultCellCache:Refresh(math.min(#self.m_args.optionInfo, 3), function(cell, index)
        local info = self.m_args.optionInfo[index]
        local count = info.count or (info.chatIds and #info.chatIds) or 0
        local isSelected = index == selectOptionIndex
        if isSelected then
            count = count + 1
            cell.nameText.text = Language.LUA_SNS_VOTE_SELECTED .. info.name
        else
            cell.nameText.text = info.name
        end
        if self.m_headIconCacheDic[cell] == nil then
            self.m_headIconCacheDic[cell] = UIUtils.genCellCache(cell.iconCell)
        end
        local displayCount = (info.chatIds and #info.chatIds or 0) + (isSelected and 1 or 0)
        self.m_headIconCacheDic[cell]:Refresh(math.min(displayCount, 3), function(iconCell, iconIndex)
            if isSelected then
                if iconIndex == 1 then
                    iconCell.headIcon.spriteName = SNSUtils.getEndminCharHeadIcon()
                    return
                else
                    iconIndex = iconIndex - 1
                end
            end
            local chatTableData = Tables.sNSChatTable[info.chatIds[iconIndex]]
            iconCell.headIcon.spriteName = chatTableData.icon
        end)
        if count > 3 then
            cell.numText.gameObject:SetActiveIfNecessary(true)
            cell.numText.text = "+" .. tostring(count - math.min(#info.chatIds, 3))
        else
            cell.numText.gameObject:SetActiveIfNecessary(false)
        end
        if isSelected then
            cell.bar.color = self.view.config.TEXT_SPECIAL_COLOR
        else
            cell.bar.color = self.view.config.TEXT_NORMAL_COLOR
        end
        cell.bar.fillAmount = count / totalCount
    end)
end
HL.Commit(SNSContentVote)
return SNSContentVote