local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.DialogSkipPopUp
DialogSkipPopUpCtrl = HL.Class('DialogSkipPopUpCtrl', uiCtrl.UICtrl)
DialogSkipPopUpCtrl.s_messages = HL.StaticField(HL.Table) << {}
DialogSkipPopUpCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.confirmButton.onClick:RemoveAllListeners()
    self.view.confirmButton.onClick:AddListener(function()
        self:PlayAnimationOutWithCallback(function()
            self:Notify(MessageConst.P_SKIP_DIALOG)
        end)
    end)
    self.view.cancelButton.onClick:RemoveAllListeners()
    self.view.cancelButton.onClick:AddListener(function()
        self:PlayAnimationOutWithCallback(function()
            self:Notify(MessageConst.P_HIDE_DIALOG_SKIP_POP_UP)
        end)
    end)
end
DialogSkipPopUpCtrl.RefreshSummary = HL.Method(HL.Any) << function(self, summaryId)
    self.view.subText.text = Language.LUA_CONFIRM_SKIP_DIALOG
    if string.isEmpty(summaryId) then
        self.view.contentText.gameObject:SetActive(false)
    else
        local res, text = Tables.dialogSummaryTable:TryGetValue(summaryId)
        self.view.contentText.gameObject:SetActive(res)
        if res then
            self.view.contentText.text = UIUtils.resolveTextCinematic(text)
        end
    end
end
HL.Commit(DialogSkipPopUpCtrl)