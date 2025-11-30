local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FullScreenSceneBlur
local MarkerState = CS.Beyond.UI.FullScreenSceneBlurMarker.State
FullScreenSceneBlurCtrl = HL.Class('FullScreenSceneBlurCtrl', uiCtrl.UICtrl)
FullScreenSceneBlurCtrl.s_messages = HL.StaticField(HL.Table) << {}
FullScreenSceneBlurCtrl.m_activeMarkers = HL.Field(HL.Table)
FullScreenSceneBlurCtrl.m_whiteBlurMarkers = HL.Field(HL.Table)
FullScreenSceneBlurCtrl.m_needUpdate = HL.Field(HL.Boolean) << false
FullScreenSceneBlurCtrl.m_updateKey = HL.Field(HL.Number) << -1
FullScreenSceneBlurCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_activeMarkers = {}
    self.m_whiteBlurMarkers = {}
    self.view.blurBG.gameObject:SetActive(false)
    self.view.blurBG.enabled = true
    CS.Beyond.UI.FullScreenSceneBlurMarker.s_onFullScreenSceneBlurMarkerStateChanged = function(id, state, useWhiteBlur)
        self:OnFullScreenSceneBlurMarkerStateChanged(id, state, useWhiteBlur)
    end
    self.m_updateKey = LuaUpdate:Add("TailTick", function()
        self:_Update()
    end)
end
FullScreenSceneBlurCtrl.OnClose = HL.Override() << function(self)
    self.m_updateKey = LuaUpdate:Remove(self.m_updateKey)
    CS.Beyond.UI.FullScreenSceneBlurMarker.s_onFullScreenSceneBlurMarkerStateChanged = nil
    self.view.blurBGRawImage:DOKill()
end
FullScreenSceneBlurCtrl.OnFullScreenSceneBlurMarkerStateChanged = HL.Method(HL.Number, MarkerState, HL.Boolean) << function(self, id, state, useWhiteBlur)
    if state == MarkerState.OnEnable then
        self.m_activeMarkers[id] = true
        if useWhiteBlur then
            self.m_whiteBlurMarkers[id] = true
        end
        self:_UpdateState()
    else
        self.m_activeMarkers[id] = nil
        if useWhiteBlur then
            self.m_whiteBlurMarkers[id] = nil
        end
        self.m_needUpdate = true
    end
end
FullScreenSceneBlurCtrl._Update = HL.Method() << function(self)
    if self.m_needUpdate then
        self:_UpdateState()
    end
end
FullScreenSceneBlurCtrl._UpdateState = HL.Method() << function(self)
    self.m_needUpdate = false
    local shouldShow = next(self.m_activeMarkers) ~= nil
    local curIsShowing = self.view.blurBG.gameObject.activeSelf
    self.view.blurBGRawImage:DOKill()
    if shouldShow then
        local useWhiteBlur = next(self.m_whiteBlurMarkers) ~= nil
        local color = useWhiteBlur and self.view.config.WHITE_BLUR_COLOR or self.view.config.DEFAULT_COLOR
        if self.view.blurBGRawImage.color ~= color then
            if curIsShowing then
                self.view.blurBGRawImage:DOColor(color, 0.2)
            else
                self.view.blurBGRawImage.color = color
            end
        end
    end
    if curIsShowing == shouldShow then
        return
    end
    if shouldShow then
        self.view.blurBGAnimationWrapper:ClearTween(false)
        self.view.blurBG.gameObject:SetActive(true)
    elseif self.view.blurBGAnimationWrapper.curState ~= CS.Beyond.UI.UIConst.AnimationState.Out then
        self.view.blurBGAnimationWrapper:PlayOutAnimation(function()
            self.view.blurBG.gameObject:SetActive(false)
        end)
    end
end
HL.Commit(FullScreenSceneBlurCtrl)