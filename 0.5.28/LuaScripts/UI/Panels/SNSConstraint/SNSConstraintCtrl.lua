local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SNSConstraint
local PHASE_ID = PhaseId.SNSConstraint
SNSConstraintCtrl = HL.Class('SNSConstraintCtrl', uiCtrl.UICtrl)
SNSConstraintCtrl.s_messages = HL.StaticField(HL.Table) << {}
SNSConstraintCtrl.InterruptForceSNS = HL.StaticMethod() << function()
    GameInstance.player.sns:EndForceDialog(true)
    if PhaseManager:IsOpen(PHASE_ID) then
        PhaseManager:ExitPhaseFast(PHASE_ID)
    end
end
SNSConstraintCtrl.OnForceDialogPanelOpen = HL.StaticMethod(HL.Any) << function(args)
    PhaseManager:OpenPhase(PHASE_ID, args, nil, true)
end
SNSConstraintCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local chatId, dialogId = unpack(arg)
    self.view.constraintFinishNode.gameObject:SetActive(false)
    self.view.btnClose.onClick:AddListener(function()
        GameInstance.player.sns:EndForceDialog(false)
        PhaseManager:PopPhase(PHASE_ID)
    end)
    self:StartDialog(chatId, dialogId)
end
SNSConstraintCtrl.OnClose = HL.Override() << function(self)
    self:Notify(MessageConst.ON_SNS_FORCE_DIALOG_END)
end
SNSConstraintCtrl.StartDialog = HL.Method(HL.String, HL.String) << function(self, chatId, dialogId)
    local snsChatData = self:_GetSNSChatData(chatId)
    if snsChatData.isSettlementChannel then
        local sns = GameInstance.player.sns
        local succ, chatInfo = sns.chatInfoDic:TryGetValue(snsChatData.chatId)
        if succ then
            local dialogData = {}
            for _, dialogId in pairs(chatInfo.dialogIds) do
                local succ, dialogInfo = sns.dialogInfoDic:TryGetValue(dialogId)
                if succ then
                    local dialogUnitData = {}
                    dialogUnitData.chatId = chatId
                    dialogUnitData.dialogId = dialogId
                    dialogUnitData.timestamp = dialogInfo.timestamp
                    dialogUnitData.sortId1 = dialogInfo.isRead and 0 or 1
                    dialogUnitData.sortId2 = dialogInfo.isEnd and 0 or 1
                    table.insert(dialogData, dialogUnitData)
                end
            end
            table.sort(dialogData, Utils.genSortFunction({ "sortId1", "sortId2", "timestamp" }))
            snsChatData.dialogData = dialogData
        end
    end
    GameInstance.player.sns:ReadDialog(chatId, dialogId)
    self.view.snsDialogContent:InitSNSDialogContent(snsChatData, dialogId, true, function()
        self.view.constraintFinishNode.gameObject:SetActive(true)
    end)
end
SNSConstraintCtrl._GetSNSChatData = HL.Method(HL.String).Return(HL.Table) << function(self, chatId)
    local chatInfo = GameInstance.player.sns.chatInfoDic:get_Item(chatId)
    local chatConfig = Tables.sNSChatTable[chatId]
    return SNSUtils.getChatData(chatInfo, chatConfig)
end
HL.Commit(SNSConstraintCtrl)