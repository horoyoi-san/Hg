local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CG
local Status = CS.CriWare.CriMana.Player.Status
CGCtrl = HL.Class('CGCtrl', uiCtrl.UICtrl)
do
    CGCtrl.m_time = HL.Field(HL.Number) << -1
    CGCtrl.m_targetTime = HL.Field(HL.Number) << -1
    CGCtrl.m_lateTickKey = HL.Field(HL.Number) << -1
end
CGCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.SKIP_FMV] = 'SkipVideo', [MessageConst.ON_SHOW_BIG_LOGO_FMV] = '_OnShowBigLogo' }
CGCtrl.m_shouldClose = HL.Field(HL.Boolean) << false
CGCtrl.m_volume = HL.Field(HL.Number) << 1.0
CGCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.exUINode.view.button.onClick:RemoveAllListeners()
    self.view.exUINode.view.button.onClick:AddListener(function()
        self:OnSkipButtonClick()
    end)
end
CGCtrl.OnShow = HL.Override() << function(self)
    self.view.image.gameObject:SetActive(false)
    self.view.exUINode:InitCinematicExUI()
    self:_HideBigLogo()
end
CGCtrl.OnClose = HL.Override() << function(self)
    self.view.exUINode.view.button.onClick:RemoveAllListeners()
    self.view.movieController.player.statusChangeCallback = nil
    GameInstance.audioManager.music:ResumeMusic();
    LuaUpdate:Remove(self.m_lateTickKey)
    self.m_lateTickKey = -1
    self.view.exUINode:Clear()
end
CGCtrl.OnHide = HL.Override() << function(self)
    self.view.exUINode:Clear()
end
CGCtrl.PlayCG = HL.Method(HL.String, HL.String, HL.Opt(HL.Any)) << function(self, path, fmvId, maskData)
    self.m_shouldClose = false
    local image = self.view.image
    image.gameObject:SetActive(true)
    if maskData and maskData.fadeInDuration then
        local dynamicMaskData = UIUtils.genDynamicBlackScreenMaskData("FMV-IN", maskData.fadeInDuration, 0, function()
            self:LoadAndPlayCG(path, fmvId, maskData)
        end)
        dynamicMaskData.fadeType = UIConst.UI_COMMON_MASK_FADE_TYPE.FadeIn
        dynamicMaskData.waitHide = true
        GameAction.ShowBlackScreen(dynamicMaskData)
    else
        self:LoadAndPlayCG(path, fmvId, maskData)
    end
end
CGCtrl.LoadAndPlayCG = HL.Method(HL.String, HL.String, HL.Opt(HL.Any)) << function(self, path, fmvId, maskData)
    local canSkip = Utils.checkCGCanSkip(fmvId)
    if BEYOND_DEBUG then
        canSkip = canSkip or CS.Beyond.DebugSettings.instance:LuaGetBool(CS.Beyond.DebugDefines.USE_CINEMATIC_DEBUG) == true
    end
    local res, cgConfig = DataManager.cgConfig.data:TryGetValue(fmvId)
    local isInitComplete = false
    self.view.exUINode.view.button.gameObject:SetActive(canSkip)
    self.view.subtitleController:PreloadFMVConfig(fmvId, function()
        self.view.movieController.player:SetFile(nil, path)
        self.view.movieController.player:Start()
        self.view.movieController.player:SetVolume(0)
        self.view.movieController.player.statusChangeCallback = nil
        self.view.movieController.player.statusChangeCallback = function(status)
            local movieInfo = self.view.movieController.player.movieInfo
            if status == Status.Playing and movieInfo then
                if not isInitComplete then
                    local fadeOutTime = 0
                    if maskData and maskData.fadeOutDuration then
                        fadeOutTime = maskData.fadeOutDuration
                    end
                    local dynamicMaskData = UIUtils.genDynamicBlackScreenMaskData("FMV-OUT", 0, fadeOutTime, function()
                        self.view.image.gameObject:SetActive(true)
                    end)
                    dynamicMaskData.fadeType = UIConst.UI_COMMON_MASK_FADE_TYPE.FadeOut
                    GameAction.ShowBlackScreen(dynamicMaskData)
                end
                isInitComplete = true
                local screenWidth = self.view.image.transform.rect.width
                local screenHeight = self.view.image.transform.rect.height
                local w = movieInfo.dispWidth
                local h = movieInfo.dispHeight
                local noSafeZone = false
                if cgConfig then
                    noSafeZone = cgConfig.noSafeZone
                end
                local offsetMin, offsetMax = FMVUtils.GetSuitableFMVImageOffset(screenWidth, screenHeight, w, h, noSafeZone)
                self.view.movieController.transform.offsetMin = offsetMin
                self.view.movieController.transform.offsetMax = offsetMax
                self.view.subtitleController:Play()
            end
            if status == Status.PlayEnd then
                self:OnVideoEnd()
            end
        end
        self.m_time = 0
        self.m_targetTime = 1
    end)
end
CGCtrl.SkipVideo = HL.Method() << function(self)
    self:OnVideoEnd(true)
end
CGCtrl.OnVideoEnd = HL.Method(HL.Opt(HL.Boolean)) << function(self, isSkip)
    if isSkip == nil then
        isSkip = false
    end
    self.m_shouldClose = true
    local fmvDirector = self.view.subtitleController.fmvDirector
    if isSkip then
        CS.Beyond.Gameplay.Core.TimelineUtils.HandleDirectorSkipAudio(fmvDirector)
    end
    self.view.subtitleController:Stop()
    VideoManager:OnPlayCGEnd(isSkip)
    self:Close()
end
CGCtrl.OnSkipButtonClick = HL.Method() << function(self)
    self.view.movieController:Pause(true)
    self.view.exUINode:SetPause(true)
    self.view.subtitleController:Pause(true)
    AudioAdapter.PostEvent("au_global_contr_fmv_pause")
    GameInstance.audioManager.music:PauseMusic();
    self:Notify(MessageConst.SHOW_POP_UP, {
        content = Language.LUA_CONFIRM_SKIP_DIALOG,
        onConfirm = function()
            self:OnVideoEnd(true)
        end,
        onCancel = function()
            self.view.subtitleController:Pause(false)
            self.view.movieController:Pause(false)
            self.view.exUINode:SetPause(false)
            GameInstance.audioManager.music:ResumeMusic();
            AudioAdapter.PostEvent("au_global_contr_fmv_resume")
        end,
    })
end
CGCtrl.OnPlayVideo = HL.StaticMethod(HL.Opt(HL.Any)) << function(arg)
    local ctrl = CGCtrl.AutoOpen(PANEL_ID, arg, true)
    local path, rawName, exData = unpack(arg)
    ctrl:PlayCG(path, rawName, exData)
end
CGCtrl._HideBigLogo = HL.Method() << function(self)
    self.view.bigLogoMain.gameObject:SetActive(false)
    self.view.stretchImageMain.gameObject:SetActive(false)
end
CGCtrl._OnShowBigLogo = HL.Method(HL.Table) << function(self, args)
    local spriteId, useStretchImage = unpack(args)
    self.view.subtitleController:SetBigLogoImage(spriteId, useStretchImage)
end
HL.Commit(CGCtrl)