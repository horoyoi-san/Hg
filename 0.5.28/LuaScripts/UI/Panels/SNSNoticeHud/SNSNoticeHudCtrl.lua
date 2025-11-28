local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SNSNoticeHud
SNSNoticeHudCtrl = HL.Class('SNSNoticeHudCtrl', uiCtrl.UICtrl)
SNSNoticeHudCtrl.m_chatId = HL.Field(HL.String) << ""
SNSNoticeHudCtrl.m_dialogId = HL.Field(HL.String) << ""
SNSNoticeHudCtrl.m_effectLoopCor = HL.Field(HL.Thread)
SNSNoticeHudCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_PHASE_LEVEL_NOT_ON_TOP] = 'OnPhaseLevelNotOnTop', }
SNSNoticeHudCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.bg.onClick:AddListener(function()
        self:_OnIconKeyClick()
    end)
    self.view.layout.onClick:AddListener(function()
        self:_OnIconKeyClick()
    end)
    self:_RefreshNoticeInfo(arg)
end
SNSNoticeHudCtrl.OnClose = HL.Override() << function(self)
    if self.m_effectLoopCor then
        self.m_effectLoopCor = self:_ClearCoroutine(self.m_effectLoopCor)
    end
end
SNSNoticeHudCtrl._RefreshNoticeInfo = HL.Method(HL.Any) << function(self, arg)
    local chatId, dialogId = unpack(arg.args)
    local noticeFinishFunc = arg.noticeFinishFunc
    local chatInfo = GameInstance.player.sns.chatInfoDic:get_Item(chatId)
    local dialogContent = Tables.sNSDialogTable[dialogId].dialogSingData
    local firstContent = dialogContent[Tables.sNSConst.snsDialogStartId]
    self.view.newMsg.gameObject:SetActive(firstContent.noticeType == GEnums.SNSNewDialogNoticeType.Normal)
    self.view.newChatPerson.gameObject:SetActive(firstContent.noticeType == GEnums.SNSNewDialogNoticeType.NewPerson)
    local chatConfig = Tables.sNSChatTable[chatId]
    if firstContent.noticeType == GEnums.SNSNewDialogNoticeType.Normal then
        self.view.newMsgTxt.text = chatInfo.isGroup and Language.LUA_SNS_NOTICE_GROUP_MSG_DESC or Language.LUA_SNS_NOTICE_PERSON_MSG_DESC
        self.view.newMsgHeadIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ROUND_CHAR_HEAD, chatConfig.icon)
    elseif firstContent.noticeType == GEnums.SNSNewDialogNoticeType.NewPerson then
        self.view.newChatPersonNameTxt.text = chatConfig.name
        self.view.newChatPersonHeadIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ROUND_CHAR_HEAD, chatConfig.icon)
    end
    local anim
    if firstContent.noticeType == GEnums.SNSNewDialogNoticeType.Normal then
        anim = self.view.newMsg
    elseif firstContent.noticeType == GEnums.SNSNewDialogNoticeType.NewPerson then
        anim = self.view.newChatPerson
    end
    if anim then
        local times = self.view.config.NOTICE_LOOP_TIMES
        local cur = 0
        local loopClipLength = anim:GetLoopClipLength()
        anim:PlayInAnimation(function()
            self.m_effectLoopCor = self:_StartCoroutine(function()
                while true do
                    AudioAdapter.PostEvent("Au_UI_Event_SNSNoticeHudPanel_Breathe")
                    cur = cur + 1
                    coroutine.wait(loopClipLength)
                    if cur == times then
                        break
                    end
                end
                anim:PlayOutAnimation(function()
                    self:Close()
                    if noticeFinishFunc then
                        noticeFinishFunc()
                    end
                end)
            end)
        end)
    end
    self.m_chatId = chatId
    self.m_dialogId = dialogId
end
SNSNoticeHudCtrl._OnIconKeyClick = HL.Method() << function(self)
    PhaseManager:OpenPhase(PhaseId.SNS, { self.m_dialogId })
end
SNSNoticeHudCtrl.OnPhaseLevelNotOnTop = HL.Method() << function(self)
    self:Close()
end
HL.Commit(SNSNoticeHudCtrl)