local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSMomentContent = HL.Class('SNSMomentContent', UIWidgetBase)
SNSMomentContent._OnFirstTimeInit = HL.Override() << function(self)
end
SNSMomentContent.InitSNSMomentContent = HL.Method(HL.String) << function(self, momentId)
    self:_FirstTimeInit()
    local snsTableData = Tables.sNSMomentTable[momentId]
    local ownerId = snsTableData.owner
    local ownerTableData = Tables.sNSChatTable[ownerId]
    self.view.nameText.text = ownerTableData.name
    self.view.contentText.text = snsTableData.text
    self.view.pictureNode.onClick:RemoveAllListeners()
    if snsTableData.imgPath ~= "" then
        self.view.pictureNode.gameObject:SetActiveIfNecessary(true)
        self.view.image.sprite = self:LoadSprite(UIConst.UI_SPRITE_SNS_PICTURE, snsTableData.imgPath)
        self.view.pictureNode.onClick:AddListener(function()
            Notify(MessageConst.SHOW_COMMON_PICTURE, snsTableData.imgPath)
            local _, momentInfo = GameInstance.player.sns.momentInfoDic:TryGetValue(momentId)
            if not momentInfo.hasRead then
                GameInstance.player.sns:ReadMoment(momentId)
            end
        end)
    else
        self.view.pictureNode.gameObject:SetActiveIfNecessary(false)
    end
    self.view.videoNode.onClick:RemoveAllListeners()
    if snsTableData.videoPath.Count > 1 then
        self.view.videoNode.gameObject:SetActiveIfNecessary(true)
        self.view.videoPreview.sprite = self:LoadSprite(UIConst.UI_SPRITE_SNS_VIDEO_PREVIEW, snsTableData.videoPath[0])
        local time = CS.Beyond.Gameplay.VideoDataTable.instance:GetVideoLength(snsTableData.videoPath[1])
        self.view.text.text = UIUtils.getLeftTimeToSecondMS(time)
        self.view.videoNode.onClick:AddListener(function()
            Notify(MessageConst.SHOW_COMMON_VIDEO, snsTableData.videoPath[1])
            local _, momentInfo = GameInstance.player.sns.momentInfoDic:TryGetValue(momentId)
            if not momentInfo.hasRead then
                GameInstance.player.sns:ReadMoment(momentId)
            end
        end)
    else
        self.view.videoNode.gameObject:SetActiveIfNecessary(false)
    end
end
HL.Commit(SNSMomentContent)
return SNSMomentContent