local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSContactNpcCell = HL.Class('SNSContactNpcCell', UIWidgetBase)
SNSContactNpcCell.m_subDialogCellCache = HL.Field(HL.Forward("UIListCache"))
SNSContactNpcCell.m_snsMainCtr = HL.Field(HL.Forward("SNSMainCtrl"))
SNSContactNpcCell.m_isFoldOut = HL.Field(HL.Boolean) << false
SNSContactNpcCell._OnFirstTimeInit = HL.Override() << function(self)
    self.m_subDialogCellCache = UIUtils.genCellCache(self.view.subDialogCell)
end
SNSContactNpcCell.InitSNSContactNpcCell = HL.Method(HL.Number, HL.Table, HL.Forward("SNSMainCtrl"), HL.Boolean) << function(self, csIndex, snsChatData, snsMainCtr, defaultFoldOut)
    self:_FirstTimeInit()
    self.m_snsMainCtr = snsMainCtr
    self.view.name.text = UIUtils.resolveTextStyle(snsChatData.name)
    self.view.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ROUND_CHAR_HEAD, snsChatData.listIcon)
    self.view.official.gameObject:SetActiveIfNecessary(snsChatData.isGroup and snsChatData.tagType == GEnums.SNSGroupDialogTagType.Official)
    self.view.external.gameObject:SetActiveIfNecessary(snsChatData.isGroup and snsChatData.tagType == GEnums.SNSGroupDialogTagType.External)
    self.view.foldOut.onClick:RemoveAllListeners()
    self.view.foldOut.onClick:AddListener(function()
        self:_OnFoldButtonClick(csIndex)
    end)
    self.view.foldBtn.onClick:RemoveAllListeners()
    self.view.foldBtn.onClick:AddListener(function()
        self:_OnFoldButtonClick(csIndex)
    end)
    self.view.redDot:InitRedDot("SNSContactNpcCell", snsChatData.chatId)
    local count = snsChatData.isSettlementChannel and 1 or #snsChatData.dialogData
    self.m_subDialogCellCache:Refresh(count, function(cell, index)
        local dialogData = snsChatData.dialogData[index]
        snsMainCtr:AddDialogDataCell(dialogData.dialogId, cell)
        cell:InitSNSSubDialogCell(dialogData, snsMainCtr)
    end)
    self.m_isFoldOut = defaultFoldOut
    self:_RefreshFoldOutIcon()
end
SNSContactNpcCell._OnFoldButtonClick = HL.Method(HL.Number) << function(self, csIndex)
    self.m_snsMainCtr:OnClickContactNpcCell(csIndex)
    self.m_isFoldOut = not self.m_isFoldOut
    self:_RefreshFoldOutIcon()
end
SNSContactNpcCell._RefreshFoldOutIcon = HL.Method() << function(self)
    self.view.foldIconUp.gameObject:SetActiveIfNecessary(self.m_isFoldOut)
    self.view.foldIconDown.gameObject:SetActiveIfNecessary(not self.m_isFoldOut)
end
HL.Commit(SNSContactNpcCell)
return SNSContactNpcCell