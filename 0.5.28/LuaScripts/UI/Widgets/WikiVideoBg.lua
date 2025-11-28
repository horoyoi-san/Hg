local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
WikiVideoBg = HL.Class('WikiVideoBg', UIWidgetBase)
local VIDEO_START_KEY = "ui_wiki_entry_start"
local VIDEO_LOOP_KEY = "ui_wiki_entry_loop"
WikiVideoBg._OnFirstTimeInit = HL.Override() << function(self)
end
WikiVideoBg.InitWikiVideoBg = HL.Method() << function(self)
    self:_FirstTimeInit()
    self.view.video:Stop()
    local successStart, videoStartFile = CS.Beyond.Gameplay.View.VideoManager.TryGetVideoPlayFullPath(VIDEO_START_KEY)
    local successLoop, videoLoopFile = CS.Beyond.Gameplay.View.VideoManager.TryGetVideoPlayFullPath(VIDEO_LOOP_KEY)
    if successStart and successLoop then
        self.view.video.player:SetFile(nil, videoStartFile)
        self.view.video.player:SetFile(nil, videoLoopFile, CS.CriWare.CriMana.Player.SetMode.AppendRepeatedly)
        self.view.video.player.applyTargetAlpha = true
        self:_StartCoroutine(function()
            while true do
                local status = self.view.video.player.status
                if status == CS.CriWare.CriMana.Player.Status.Stop or status == CS.CriWare.CriMana.Player.Status.Ready then
                    break
                end
                coroutine.step()
            end
            self.view.video:Play()
        end)
    end
end
WikiVideoBg._OnEnable = HL.Override() << function(self)
    if not self.m_isFirstTimeInit then
        self.view.video:Stop()
        local successLoop, videoLoopFile = CS.Beyond.Gameplay.View.VideoManager.TryGetVideoPlayFullPath(VIDEO_LOOP_KEY)
        if successLoop then
            self.view.video.player:SetFile(nil, videoLoopFile, CS.CriWare.CriMana.Player.SetMode.AppendRepeatedly)
            self.view.video.player.applyTargetAlpha = true
            self:_StartCoroutine(function()
                while true do
                    local status = self.view.video.player.status
                    if status == CS.CriWare.CriMana.Player.Status.Stop or status == CS.CriWare.CriMana.Player.Status.Ready or status == CS.CriWare.CriMana.Player.Status.PlayEnd then
                        break
                    end
                    coroutine.step()
                end
                self.view.video:Play()
            end)
        end
    end
end
WikiVideoBg._OnDisable = HL.Override() << function(self)
end
HL.Commit(WikiVideoBg)
return WikiVideoBg