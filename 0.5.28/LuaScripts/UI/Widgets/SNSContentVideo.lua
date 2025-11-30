local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSContentVideo = HL.Class('SNSContentVideo', UIWidgetBase)
SNSContentVideo._OnFirstTimeInit = HL.Override() << function(self)
end
SNSContentVideo.InitSNSContentVideo = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    if not args.loaded then
        self.view.animationWrapper:PlayInAnimation()
        AudioAdapter.PostEvent("Au_UI_Popup_SNSDialogContent_OtherNode_Open")
    end
    self.view.image.sprite = self:LoadSprite(UIConst.UI_SPRITE_SNS_VIDEO_PREVIEW, args.imageName)
    self.view.image.preserveAspect = true
    self.view.playBtn.onClick:RemoveAllListeners()
    self.view.playBtn.onClick:AddListener(function()
        Notify(MessageConst.SHOW_COMMON_VIDEO, args.videoName)
    end)
    local time = CS.Beyond.Gameplay.VideoDataTable.instance:GetVideoLength(args.videoName)
    self.view.timeTxt.text = UIUtils.getLeftTimeToSecondMS(time)
end
HL.Commit(SNSContentVideo)
return SNSContentVideo