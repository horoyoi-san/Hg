local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SNSMain
SNSMainCtrl = HL.Class('SNSMainCtrl', uiCtrl.UICtrl)
SNSMainCtrl.m_tabCellCache = HL.Field(HL.Forward("UIListCache"))
SNSMainCtrl.m_getContactNpcCellFunc = HL.Field(HL.Function)
SNSMainCtrl.m_id2ChatData = HL.Field(HL.Table)
SNSMainCtrl.m_id2DialogData = HL.Field(HL.Table)
SNSMainCtrl.m_currentSelectedSubDialogCell = HL.Field(HL.Forward("SNSSubDialogCell"))
SNSMainCtrl.m_curSelectedSubDialogId = HL.Field(HL.String) << ""
SNSMainCtrl.m_tabInfos = HL.Field(HL.Table)
SNSMainCtrl.m_curTabIndex = HL.Field(HL.Number) << -1
SNSMainCtrl.m_momentInit = HL.Field(HL.Boolean) << false
SNSMainCtrl.m_snsChatData = HL.Field(HL.Table)
SNSMainCtrl.s_messages = HL.StaticField(HL.Table) << {}
SNSMainCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    GameInstance.player.sns:UpdateChatInfoDicForUI()
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.SNS)
    end)
    self:BindInputPlayerAction("close_sns", function()
        PhaseManager:PopPhase(PhaseId.SNS)
    end)
    self.m_tabCellCache = UIUtils.genCellCache(self.view.tabs.tabCell)
    self.m_getContactNpcCellFunc = UIUtils.genCachedCellFunction(self.view.contactNpcScrollList)
    self.view.chat.gameObject:SetActiveIfNecessary(false)
    self.view.moment.gameObject:SetActiveIfNecessary(false)
    self.view.nonSelected.gameObject:SetActiveIfNecessary(true)
    self.view.selected.gameObject:SetActiveIfNecessary(false)
    local dialogId = unpack(arg or {})
    if not string.isEmpty(dialogId) then
        self.m_curSelectedSubDialogId = dialogId
    end
    self:_InitTabInfos()
    self:_RefreshContactNpcList()
    self:_InitContent()
end
SNSMainCtrl.OnClickContactNpcCell = HL.Method(HL.Number) << function(self, csIndex)
    self.view.contactNpcScrollList:Toggle(csIndex)
end
SNSMainCtrl.OnClickDialogCell = HL.Method(HL.String, HL.String, HL.Forward("SNSSubDialogCell")) << function(self, chatId, dialogId, subDialogCell)
    if self.m_curSelectedSubDialogId == dialogId then
        return
    end
    self.m_curSelectedSubDialogId = dialogId
    GameInstance.player.sns:ReadDialog(chatId, dialogId)
    if self.m_currentSelectedSubDialogCell then
        self.m_currentSelectedSubDialogCell:SetSelected(false)
    end
    subDialogCell:SetSelected(true)
    self.m_currentSelectedSubDialogCell = subDialogCell
    self.view.nonSelected.gameObject:SetActiveIfNecessary(false)
    self.view.selected.gameObject:SetActiveIfNecessary(true)
    self.view.snsDialogContent:InitSNSDialogContent(self.m_id2ChatData[chatId], dialogId, false)
end
SNSMainCtrl.JumpToDialogById = HL.Method(HL.String, HL.String) << function(self, chatId, dialogId)
    local cell = self.m_id2DialogData[dialogId].cell
    self:OnClickDialogCell(chatId, dialogId, cell)
end
SNSMainCtrl.AddDialogDataCell = HL.Method(HL.String, HL.Any) << function(self, dialogId, cell)
    self.m_id2DialogData[dialogId].cell = cell
end
SNSMainCtrl._RefreshContactNpcList = HL.Method() << function(self)
    self.view.chat.gameObject:SetActiveIfNecessary(true)
    self.m_snsChatData = self:_ProcessSNSChatData()
    if #self.m_snsChatData > 0 then
        local targetCsIndex = -1
        if not string.isEmpty(self.m_curSelectedSubDialogId) then
            local chatId = self.m_id2DialogData[self.m_curSelectedSubDialogId].chatId
            for luaIndex, snsChatData in ipairs(self.m_snsChatData) do
                if snsChatData.chatId == chatId then
                    targetCsIndex = CSIndex(luaIndex)
                    break
                end
            end
        end
        self.view.contactNpcScrollList.onUpdateCell:RemoveAllListeners()
        self.view.contactNpcScrollList.onUpdateCell:AddListener(function(gameObject, index)
            local luaIndex = LuaIndex(index)
            local content = self.m_getContactNpcCellFunc(gameObject)
            content:InitSNSContactNpcCell(index, self.m_snsChatData[luaIndex], self, index == targetCsIndex)
        end)
        if targetCsIndex > -1 then
            self:_StartCoroutine(function()
                self.view.contactNpcScrollList:UpdateCount(#self.m_snsChatData)
                self.view.contactNpcScrollList:ScrollToIndex(targetCsIndex, true)
                coroutine.step()
                self.view.contactNpcScrollList:FoldAll(false)
                coroutine.step()
                self.view.contactNpcScrollList:Toggle(targetCsIndex, true)
            end)
        else
            self:_StartCoroutine(function()
                self.view.contactNpcScrollList:UpdateCount(#self.m_snsChatData)
                coroutine.step()
                self.view.contactNpcScrollList:FoldAll(false)
            end)
        end
    end
end
SNSMainCtrl._InitContent = HL.Method() << function(self)
    local hasDefaultContent = not string.isEmpty(self.m_curSelectedSubDialogId)
    self.view.nonSelected.gameObject:SetActiveIfNecessary(not hasDefaultContent)
    self.view.selected.gameObject:SetActiveIfNecessary(hasDefaultContent)
    if not hasDefaultContent then
        return
    end
    local dialogId = self.m_curSelectedSubDialogId
    local chatId = self.m_id2DialogData[dialogId].chatId
    GameInstance.player.sns:ReadDialog(chatId, dialogId)
    self.view.snsDialogContent:InitSNSDialogContent(self.m_id2ChatData[chatId], dialogId, false)
end
SNSMainCtrl._ProcessSNSChatData = HL.Method().Return(HL.Table) << function(self)
    self.m_id2ChatData = {}
    self.m_id2DialogData = {}
    local sns = GameInstance.player.sns
    local chatData = {}
    for chatId, chatInfo in pairs(sns.chatInfoDic) do
        local chatConfig = Tables.sNSChatTable[chatId]
        local chatUnitData = SNSUtils.getChatData(chatInfo, chatConfig)
        local dialogData = {}
        local hasUnread = false
        local hasUnfinished = false
        for _, dialogId in pairs(chatInfo.dialogIds) do
            local succInfo, dialogInfo = sns.dialogInfoDic:TryGetValue(dialogId)
            local hasCfg = Tables.sNSDialogTable:ContainsKey(dialogId)
            if succInfo and hasCfg then
                local dialogUnitData = {}
                dialogUnitData.chatId = chatId
                dialogUnitData.dialogId = dialogId
                dialogUnitData.isRead = dialogInfo.isRead
                dialogUnitData.isEnd = dialogInfo.isEnd
                dialogUnitData.timestamp = dialogInfo.timestamp
                dialogUnitData.curContentId = dialogInfo.curContentId
                local isRead = dialogInfo.isRead
                local isEnd = dialogInfo.isEnd
                dialogUnitData.sortId1 = isRead and 0 or 1
                dialogUnitData.sortId2 = isEnd and 0 or 1
                table.insert(dialogData, dialogUnitData)
                if not isRead then
                    hasUnread = true
                end
                if not isEnd then
                    hasUnfinished = true
                end
                self.m_id2DialogData[dialogId] = dialogUnitData
            end
        end
        table.sort(dialogData, Utils.genSortFunction({ "sortId1", "sortId2", "timestamp" }))
        chatUnitData.sortId1 = hasUnread and 1 or 0
        chatUnitData.sortId2 = hasUnfinished and 1 or 0
        chatUnitData.dialogData = dialogData
        table.insert(chatData, chatUnitData)
        self.m_id2ChatData[chatId] = chatUnitData
    end
    table.sort(chatData, Utils.genSortFunction({ "sortId1", "sortId2", "timestamp" }))
    return chatData
end
SNSMainCtrl._InitTabInfos = HL.Method() << function(self)
    self.m_tabInfos = { { name = Language.LUA_SNS_TITLE_DESC, icon = "SNS/sns_icon_chat", goNode = self.view.chat.gameObject, redDotName = "SNSMainPanelChatTabCell", }, { name = Language.LUA_SNS_MOMENT_TITLE_DESC, icon = "SNS/sns_icon_tweet", goNode = self.view.moment.gameObject, redDotName = "SNSMainPanelMomentTabCell", }, }
    self.m_tabCellCache:Refresh(#self.m_tabInfos, function(cell, index)
        local info = self.m_tabInfos[index]
        cell.defaultIcon.sprite = self:LoadSprite(info.icon)
        cell.selectedIcon.sprite = self:LoadSprite(info.icon)
        cell.toggle.onValueChanged:RemoveAllListeners()
        cell.toggle.isOn = index == self.m_curTabIndex
        cell.toggle.onValueChanged:AddListener(function(isOn)
            if isOn then
                self:_OnClickTab(index)
            end
        end)
        cell.redDot:InitRedDot(info.redDotName)
        cell.gameObject.name = "Tab-" .. index
    end)
    local dialogCell = self.m_tabCellCache:Get(1)
    dialogCell.toggle.isOn = true
    if not GameInstance.player.sns:HasMoment() then
        local momentCell = self.m_tabCellCache:GetItem(2)
        momentCell.gameObject:SetActiveIfNecessary(false)
    end
end
SNSMainCtrl._OnClickTab = HL.Method(HL.Number) << function(self, index)
    if self.m_curTabIndex == index then
        return
    end
    if self.m_curTabIndex > 0 then
        self.m_tabInfos[self.m_curTabIndex].goNode:SetActiveIfNecessary(false)
    end
    self.m_curTabIndex = index
    local info = self.m_tabInfos[index]
    self.view.title.text = info.name
    info.goNode:SetActiveIfNecessary(true)
    if index == 2 and not self.m_momentInit then
        self.view.snsMomentContent:InitSNSMoment()
        self.m_momentInit = true
    end
end
SNSMainCtrl.JumpToMomentById = HL.Method(HL.String) << function(self, momentId)
    local tabCell = self.m_tabCellCache:GetItem(2)
    tabCell.toggle.isOn = true
    self.view.snsMomentContent:JumpToMoment(momentId)
end
HL.Commit(SNSMainCtrl)