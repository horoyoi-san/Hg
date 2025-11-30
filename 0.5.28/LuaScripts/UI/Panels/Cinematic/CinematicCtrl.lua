local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Cinematic
CinematicCtrl = HL.Class('CinematicCtrl', uiCtrl.UICtrl)
CinematicCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_LOAD_NEW_CUTSCENE] = 'OnLoadNewCinematic', }
CinematicCtrl.m_timelineHandle = HL.Field(HL.Userdata)
CinematicCtrl.m_debugSkipCounter = HL.Field(HL.Number) << 0
CinematicCtrl.OnLoadNewCinematic = HL.Method(HL.Any) << function(self, arg)
    if arg == nil then
        logger.error("CinematicCtrl.OnLoadNewCinematic handle is nil")
        return
    end
    self.m_timelineHandle = unpack(arg)
    self:OnShow()
end
CinematicCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local handle = unpack(arg)
    self.m_timelineHandle = handle
    self.view.exUINode.view.button.onClick:RemoveAllListeners()
    self.view.exUINode.view.button.onClick:AddListener(function()
        self:OnBtnSkipClick()
    end)
    self:_InitBorderMask()
end
CinematicCtrl._InitBorderMask = HL.Method() << function(self, arg)
    local screenWidth = Screen.width
    local screenHeight = Screen.height
    local maxScreenWidth = FMVUtils.MAX_FMV_ASPECT_RATIO * screenHeight
    local borderSize = (screenWidth - maxScreenWidth) / 2
    local ratio = self.view.transform.rect.width / Screen.width
    self.view.leftBorder.transform.sizeDelta = Vector2(borderSize, screenHeight) * ratio
    self.view.rightBorder.transform.sizeDelta = Vector2(borderSize, screenHeight) * ratio
end
CinematicCtrl.OnShow = HL.Override() << function(self)
    self:_ShowCinematic()
    self.view.debugNode.gameObject:SetActive(false)
    if NarrativeUtils.ShouldShowNarrativeDebugNode() then
        local curCutsceneData = GameInstance.world.cutsceneManager.curMainTimelineData
        self.view.debugNode.gameObject:SetActive(true)
        self.view.textCutsceneId.text = curCutsceneData.cutsceneName
    end
    if UNITY_EDITOR and BEYOND_DEBUG then
        GameInstance.world.cutsceneManager:BindDebugFramingInfo(self.view.textCutsceneFrame)
    end
    local canSkip = Utils.checkCinematicCanSkip(self.m_timelineHandle.data)
    self.view.exUINode.view.button.gameObject:SetActive(canSkip)
    if canSkip then
        self.view.exUINode:InitCinematicExUI()
    end
end
CinematicCtrl.OnHide = HL.Override() << function(self)
    self.view.exUINode:Clear()
end
CinematicCtrl.OnClose = HL.Override() << function(self)
    self.view.exUINode.view.button.onClick:RemoveAllListeners()
    self.view.exUINode:Clear()
end
CinematicCtrl._ShowCinematic = HL.Method() << function(self)
    local cinematicMgr = GameInstance.world.cutsceneManager
    local hasSubtitle = cinematicMgr:BindSubtitle(self.m_timelineHandle, self.view.subtitlePanel)
    self.view.subtitlePanel.gameObject:SetActive(hasSubtitle)
    local hasLeftSubtitle = cinematicMgr:BindLeftSubtitle(self.m_timelineHandle, self.view.leftSubtitlePanel)
    self.view.leftSubtitlePanel.gameObject:SetActive(hasLeftSubtitle)
    self.view.leftSubtitlePanel:UpdateAlpha(0)
    local hasMask = cinematicMgr:BindMask(self.m_timelineHandle, self.view.mask)
    self.view.mask.gameObject:SetActive(hasMask)
end
CinematicCtrl.OnBtnSkipClick = HL.Method() << function(self)
    local cinematicMgr = GameInstance.world.cutsceneManager
    self.view.exUINode:SetPause(true)
    cinematicMgr:PauseTimelineByUI(true)
    cinematicMgr:PauseTimeByTimeline(true)
    self:Notify(MessageConst.SHOW_POP_UP, {
        content = Language.LUA_CONFIRM_SKIP_DIALOG,
        onConfirm = function()
            cinematicMgr:PauseTimelineByUI(false)
            cinematicMgr:PauseTimeByTimeline(false)
            cinematicMgr:SkipTimeline(self.m_timelineHandle)
        end,
        onCancel = function()
            self.view.exUINode:SetPause(true)
            cinematicMgr:PauseTimelineByUI(false)
            cinematicMgr:PauseTimeByTimeline(false)
        end
    })
end
HL.Commit(CinematicCtrl)