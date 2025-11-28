local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSContentCard = HL.Class('SNSContentCard', UIWidgetBase)
SNSContentCard._OnFirstTimeInit = HL.Override() << function(self)
end
SNSContentCard.InitSNSContentCard = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    if not args.loaded then
        self.view.animationWrapper:PlayInAnimation()
        AudioAdapter.PostEvent("Au_UI_Popup_SNSDialogContent_OtherNode_Open")
    end
    local chatId = args.chatId
    local dialogId = args.dialogId
    local chatTableData = Tables.sNSChatTable[chatId]
    self.view.nameText.text = chatTableData.name
    local organization = nil
    if organization ~= nil and organization ~= "" then
        self.view.orgNode.gameObject:SetActiveIfNecessary(true)
        self.view.noOrgNode.gameObject:SetActiveIfNecessary(false)
        self.view.orgText.text = organization
    else
        self.view.orgNode.gameObject:SetActiveIfNecessary(false)
        self.view.noOrgNode.gameObject:SetActiveIfNecessary(true)
    end
    self.view.button.onClick:RemoveAllListeners()
    self.view.button.onClick:AddListener(function()
        PhaseManager:GoToPhase(PhaseId.SNS, { chatId = chatId, dialogId = dialogId })
    end)
end
HL.Commit(SNSContentCard)
return SNSContentCard