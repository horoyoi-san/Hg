local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Loading
LoadingCtrl = HL.Class('LoadingCtrl', uiCtrl.UICtrl)
LoadingCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.CLOSE_LOADING_PANEL] = 'CloseLoadingPanel', [MessageConst.ADD_LOADING_SYSTEM] = 'AddLoadingSystem', [MessageConst.REMOVE_LOADING_SYSTEM] = 'RemoveLoadingSystem', }
LoadingCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
end
LoadingCtrl.OnClose = HL.Override() << function(self)
    Notify(MessageConst.ON_TOGGLE_HUD_FADE, { "loading", false })
end
LoadingCtrl.OpenLoadingPanel = HL.StaticMethod(HL.Opt(HL.Table)) << function(args)
    local isShowing = UIManager:IsShow(PANEL_ID)
    local self = UIManager:AutoOpen(PANEL_ID)
    Notify(MessageConst.ON_LOADING_PANEL_OPENED)
    self:_Init(args)
    if not isShowing then
        CS.Beyond.Resource.ResourceManager.SetBurstMode(false)
        self:_StartTimer(0.5, function()
            if UIManager:IsShow(PANEL_ID) and not self:IsPlayingAnimationOut() then
                CS.Beyond.Resource.ResourceManager.SetBurstMode(true)
            end
        end)
    end
end
LoadingCtrl.m_extraLoadingSystems = HL.Field(HL.Table)
LoadingCtrl._Init = HL.Method(HL.Opt(HL.Table)) << function(self, args)
    self.m_extraLoadingSystems = {}
    local index = math.floor(lume.random(1, #Tables.loadingTipsTable + 0.99))
    for _, v in pairs(Tables.loadingTipsTable) do
        index = index - 1
        if index == 0 then
            self.view.tipsTxt.text = UIUtils.resolveTextStyle(v)
        end
    end
    self.view.progressBar.value = 0
    self:_StartCoroutine(function()
        while true do
            coroutine.step()
            self:_Update()
        end
    end)
    Notify(MessageConst.ON_TOGGLE_HUD_FADE, { "loading", true })
end
LoadingCtrl.CloseLoadingPanel = HL.Method() << function(self)
    self:_TryCloseLoading()
end
LoadingCtrl.AddLoadingSystem = HL.Method(HL.Table) << function(self, args)
    local sysName = unpack(args)
    self.m_extraLoadingSystems[sysName] = true
end
LoadingCtrl.RemoveLoadingSystem = HL.Method(HL.Table) << function(self, args)
    local sysName = unpack(args)
    self.m_extraLoadingSystems[sysName] = nil
    self:_TryCloseLoading()
end
LoadingCtrl.m_isClosing = HL.Field(HL.Boolean) << false
LoadingCtrl._TryCloseLoading = HL.Method() << function(self)
    if next(self.m_extraLoadingSystems) or self.m_isClosing then
        return
    end
    CS.Beyond.Resource.ResourceManager.SetBurstMode(false)
    self.m_isClosing = true
    self:_StartCoroutine(function()
        coroutine.step()
        if not self:IsPlayingAnimationOut() then
            self:PlayAnimationOutWithCallback(function()
                Notify(MessageConst.ON_LOADING_PANEL_CLOSED)
                self:Close()
            end)
        end
    end)
end
LoadingCtrl._Update = HL.Method() << function(self)
    self.view.progressBar.value = GameInstance.world.levelLoader.progress
end
HL.Commit(LoadingCtrl)