local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSContentSystemMsg = HL.Class('SNSContentSystemMsg', UIWidgetBase)
SNSContentSystemMsg._OnFirstTimeInit = HL.Override() << function(self)
end
SNSContentSystemMsg.InitSNSContentSystemMsg = HL.Method(HL.Table) << function(self, arg)
    self:_FirstTimeInit()
    if not arg.loaded then
        AudioAdapter.PostEvent("Au_UI_Event_SNSContentEndLine_Open")
        if self.view.animationWrapper ~= nil then
            self.view.animationWrapper:PlayInAnimation()
        end
    end
    self.view.contentTxt.text = SNSUtils.resolveTextPlayerName(arg.content)
end
HL.Commit(SNSContentSystemMsg)
return SNSContentSystemMsg