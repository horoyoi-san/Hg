local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
SNSContentPRTS = HL.Class('SNSContentPRTS', UIWidgetBase)
SNSContentPRTS._OnFirstTimeInit = HL.Override() << function(self)
end
SNSContentPRTS.InitSNSContentPRTS = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    if not args.loaded then
        self.view.animationWrapper:PlayInAnimation()
        AudioAdapter.PostEvent("Au_UI_Popup_SNSDialogContent_OtherNode_Open")
    end
    local jumpId = args.jumpId
    local succ, cfg = Tables.systemJumpTable:TryGetValue(jumpId)
    if not succ then
        logger.error("no such jumpId")
        return
    end
    local jumpArgs = Json.decode(cfg.phaseArgs)
    if jumpArgs.isFirstLvId then
        local firstLvData = Tables.prtsFirstLv[jumpArgs.id]
        self.view.titleText.text = firstLvData.name
    else
        local prtsTableData = Tables.prtsAllItem[jumpArgs.id]
        self.view.titleText.text = prtsTableData.name
    end
    self.view.button.onClick:RemoveAllListeners()
    self.view.button.onClick:AddListener(function()
        local prts = GameInstance.player.prts
        local unlock = jumpArgs.isFirstLvId and prts:IsFirstLvUnlock(jumpArgs.id) or prts:IsPrtsUnlocked(jumpArgs.id)
        if unlock then
            Utils.jumpToSystem(jumpId)
        else
            Notify(MessageConst.SHOW_TOAST, Language.LUA_SNS_DONT_HAVE_PRTS_DATA)
        end
    end)
end
HL.Commit(SNSContentPRTS)
return SNSContentPRTS