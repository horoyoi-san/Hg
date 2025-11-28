local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSContentTweet = HL.Class('SNSContentTweet', UIWidgetBase)
SNSContentTweet._OnFirstTimeInit = HL.Override() << function(self)
end
SNSContentTweet.InitSNSContentTweet = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    if not args.loaded then
        self.view.animationWrapper:PlayInAnimation()
        AudioAdapter.PostEvent("Au_UI_Popup_SNSDialogContent_OtherNode_Open")
    end
    local momentId = args.momentId
    local momentTableData = Tables.sNSMomentTable[momentId]
    local chatTableData = Tables.sNSChatTable[momentTableData.owner]
    self.view.titleText.text = string.format(Language.LUA_SNS_TWEET_TITLE, chatTableData.name)
    self.view.contentText.text = momentTableData.text
    self.view.headIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ROUND_CHAR_HEAD, chatTableData.icon)
    self.view.button.onClick:RemoveAllListeners()
    self.view.button.onClick:AddListener(function()
        PhaseManager:GoToPhase(PhaseId.SNS, { momentId = momentId })
    end)
end
HL.Commit(SNSContentTweet)
return SNSContentTweet