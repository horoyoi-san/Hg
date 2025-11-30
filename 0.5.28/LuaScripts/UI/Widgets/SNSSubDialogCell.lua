local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSSubDialogCell = HL.Class('SNSSubDialogCell', UIWidgetBase)
SNSSubDialogCell.m_dialogId = HL.Field(HL.String) << ""
SNSSubDialogCell._OnFirstTimeInit = HL.Override() << function(self)
    self:RegisterMessage(MessageConst.ON_SNS_DIALOG_MODIFY, function(args)
        local dialogId = unpack(args)
        self:_OnSNSDialogModify(dialogId)
    end)
end
SNSSubDialogCell._OnSNSDialogModify = HL.Method(HL.String) << function(self, dialogId)
    if dialogId ~= self.m_dialogId then
        return
    end
    self:_UpdateSNSInfo()
end
SNSSubDialogCell._UpdateSNSInfo = HL.Method() << function(self)
    local latestContent = SNSUtils.findLatestContent(self.m_dialogId)
    local richStyleContent = SNSUtils.resolveTextStyleWithPlayerName(latestContent)
    self.view.normalTxt.text = richStyleContent
    self.view.selectTxt.text = richStyleContent
    local isEnd = GameInstance.player.sns:DialogHasEnd(self.m_dialogId)
    self.view.informationN.gameObject:SetActiveIfNecessary(not isEnd)
    self.view.informationS.gameObject:SetActiveIfNecessary(not isEnd)
    self.view.finishN.gameObject:SetActiveIfNecessary(isEnd)
    self.view.finishS.gameObject:SetActiveIfNecessary(isEnd)
end
SNSSubDialogCell.InitSNSSubDialogCell = HL.Method(HL.Table, HL.Forward("SNSMainCtrl")) << function(self, dialogData, snsMainCtr)
    self:_FirstTimeInit()
    self.m_dialogId = dialogData.dialogId
    local isSelected = snsMainCtr.m_curSelectedSubDialogId == dialogData.dialogId
    if isSelected then
        snsMainCtr.m_currentSelectedSubDialogCell = self
    end
    self:SetSelected(isSelected, true)
    self.view.button.onClick:RemoveAllListeners()
    self.view.button.onClick:AddListener(function()
        snsMainCtr:OnClickDialogCell(dialogData.chatId, dialogData.dialogId, self)
    end)
    self:_UpdateSNSInfo()
    self.view.redDot:InitRedDot("SNSSubDialogCell", dialogData.dialogId)
end
SNSSubDialogCell.SetSelected = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, selected, isInit)
    if isInit == true then
        self.view.selectNode.gameObject:SetActiveIfNecessary(selected)
        self.view.normalNode.gameObject:SetActiveIfNecessary(not selected)
        if selected then
            self.view.animationWrapper:SampleToInAnimationEnd()
        else
            self.view.animationWrapper:SampleToOutAnimationEnd()
        end
    else
        if selected then
            self.view.animationWrapper:PlayInAnimation()
        else
            self.view.animationWrapper:PlayOutAnimation()
        end
    end
end
HL.Commit(SNSSubDialogCell)
return SNSSubDialogCell