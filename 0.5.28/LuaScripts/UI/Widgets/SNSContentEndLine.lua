local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSContentEndLine = HL.Class('SNSContentEndLine', UIWidgetBase)
SNSContentEndLine._OnFirstTimeInit = HL.Override() << function(self)
end
SNSContentEndLine.InitSNSContentEndLine = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    if not args.loaded then
        self.view.animationWrapper:PlayInAnimation()
        AudioAdapter.PostEvent("Au_UI_Event_SNSContentEndLine_Open")
    end
end
HL.Commit(SNSContentEndLine)
return SNSContentEndLine