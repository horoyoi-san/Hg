local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonTaskTrackHud
local Phase = { Normal = 1, Fail = 2, CompleteMainGoal = 3, CompleteAllGoal = 4, }
local CONTENT_SCROLL_FADE_ANIM = "commontasktrackhud_contentscrollfade"
local CONTENT_REFRESH_ANIM = "commontasktrackhud_contentrefresh"
local TITLE_SCROLL_FADE_ANIM = "commontasktrackhud_titlescrollfade"
local TITLE_FINISH_ANIM = "titlefinish_in"
local TITLE_FAIL_ANIM = "titlefail_in"
local STAGE_TEXT_FORMAT = "%d/%d"
CommonTaskTrackHudCtrl = HL.Class('CommonTaskTrackHudCtrl', uiCtrl.UICtrl)
CommonTaskTrackHudCtrl.m_mainGoalCellCache = HL.Field(HL.Forward("UIListCache"))
CommonTaskTrackHudCtrl.m_extraGoalCellCache = HL.Field(HL.Forward("UIListCache"))
CommonTaskTrackHudCtrl.m_curPhase = HL.Field(HL.Number) << Phase.Normal
CommonTaskTrackHudCtrl.m_subGameId = HL.Field(HL.String) << ""
CommonTaskTrackHudCtrl.m_subGameData = HL.Field(CS.Beyond.Gameplay.Core.SubGameInstanceData)
CommonTaskTrackHudCtrl.m_isShowCustomTask = HL.Field(HL.Boolean) << false
CommonTaskTrackHudCtrl.m_originalAnchoredPos = HL.Field(Vector2)
CommonTaskTrackHudCtrl.m_canQuit = HL.Field(HL.Boolean) << false
CommonTaskTrackHudCtrl.m_canReset = HL.Field(HL.Boolean) << false
CommonTaskTrackHudCtrl.m_contentShowingFinish = HL.Field(HL.Boolean) << false
CommonTaskTrackHudCtrl.m_contentShowingCor = HL.Field(HL.Thread)
CommonTaskTrackHudCtrl.m_contentShowing = HL.Field(HL.Boolean) << false
CommonTaskTrackHudCtrl.taskGoalShowing = HL.Field(HL.Boolean) << false
CommonTaskTrackHudCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SUB_GAME_FINISH_STATE_CHANGE] = "OnSubGameFinishStateChange", [MessageConst.ON_SUB_GAME_STAGE_CHANGE] = "OnSubGameStageChange", [MessageConst.ON_SCRIPT_TASK_CHANGE] = "OnTrackingTaskChange", [MessageConst.ON_SUB_GAME_RESET] = "OnSubGameReset", [MessageConst.ON_HUD_BTN_VISIBLE_CHANGE] = "OnHudBtnVisibleChange", }
CommonTaskTrackHudCtrl.InitSubGameTrack = HL.Method(HL.String) << function(self, subGameId)
    if not self:_LoadSubGameData(subGameId) then
        return
    end
    self.m_subGameId = subGameId
    self.m_isShowCustomTask = false
    self.m_contentShowingFinish = false
    self:RefreshAll()
end
CommonTaskTrackHudCtrl.StopSubGameTrack = HL.Method() << function(self)
    self.m_subGameId = ""
    self.m_subGameData = nil
    if self.m_isShowCustomTask then
        self:RefreshAll()
    else
        Notify(MessageConst.ON_DEACTIVATE_COMMON_TASK_TRACK_HUD)
    end
end
CommonTaskTrackHudCtrl.InitCustomTaskTrack = HL.Method() << function(self)
    self.m_isShowCustomTask = true
    self.m_contentShowingFinish = false
    self:RefreshAll()
end
CommonTaskTrackHudCtrl.StopCustomTaskTrack = HL.Method() << function(self)
    self.m_isShowCustomTask = false
    if self.m_subGameId ~= "" then
        self:RefreshAll()
    else
        Notify(MessageConst.ON_DEACTIVATE_COMMON_TASK_TRACK_HUD)
    end
end
CommonTaskTrackHudCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_mainGoalCellCache = UIUtils.genCellCache(self.view.mainGoalCell)
    self.m_extraGoalCellCache = UIUtils.genCellCache(self.view.extraGoalCell)
    self.m_originalAnchoredPos = self.view.main.anchoredPosition
    self.view.btnReset.onClick:AddListener(function()
        self:_OnBtnResetClick()
    end)
    self.view.btnStop.onClick:AddListener(function()
        self:_OnBtnStopClick()
    end)
end
CommonTaskTrackHudCtrl.OnClose = HL.Override() << function(self)
    if self.m_contentShowingCor then
        self.m_contentShowingCor = self:_ClearCoroutine(self.m_contentShowingCor)
    end
end
CommonTaskTrackHudCtrl.OnShow = HL.Override() << function(self)
    if not self.m_contentShowingFinish then
        local opened, missionHudCtrl = UIManager:IsOpen(PanelId.MissionHud)
        if opened then
            if UIManager:IsShow(PanelId.MissionHud) then
                missionHudCtrl:PlayAnimationOut()
            else
                missionHudCtrl:Close()
            end
        end
    else
        self:Close()
    end
end
CommonTaskTrackHudCtrl.RefreshAll = HL.Method() << function(self)
    if self.m_isShowCustomTask then
        self:_RefreshCustomTaskTrack()
    else
        self:_RefreshSubGameTrack()
    end
    if self.m_contentShowingCor then
        self.m_contentShowingCor = self:_ClearCoroutine(self.m_contentShowingCor)
    end
    local wrapper = self:GetAnimationWrapper()
    wrapper:PlayInAnimation()
end
CommonTaskTrackHudCtrl._RefreshSubGameTrack = HL.Method() << function(self)
    local trackingMgr = GameInstance.world.levelScriptTaskTrackingManager
    local mainTask = trackingMgr.mainTask
    local goalCount = mainTask ~= nil and mainTask.objectives.Length or 0
    local extraTask = trackingMgr.extraTask
    local extraGoalCount = extraTask ~= nil and extraTask.objectives.Length or 0
    local hasGoal = goalCount > 0 or extraGoalCount > 0
    self.view.goalRoot.gameObject:SetActive(hasGoal)
    self.view.failReasonRoot.gameObject:SetActive(not hasGoal)
    self.view.mainGoalRoot.gameObject:SetActive(goalCount > 0)
    self.m_mainGoalCellCache:Refresh(goalCount, function(cell, index)
        cell:InitCommonTaskGoalCell(index, CS.Beyond.Gameplay.LevelScriptTaskType.Main)
    end)
    self.view.extraGoalRoot.gameObject:SetActive(extraGoalCount > 0)
    self.m_extraGoalCellCache:Refresh(extraGoalCount, function(cell, index)
        cell:InitCommonTaskGoalCell(index, CS.Beyond.Gameplay.LevelScriptTaskType.Extra)
    end)
    self.m_canQuit = self.m_subGameData.canQuit
    self.view.btnStopNode.gameObject:SetActiveIfNecessary(self.m_subGameData.canQuit)
    self.view.btnStopTxt.text = UIUtils.resolveTextStyle(self.m_subGameData.resetBtnName:GetText())
    local success, gameMechanicData = Tables.gameMechanicTable:TryGetValue(self.m_subGameId)
    if success then
        local gameMechanicCategoryData = Tables.gameMechanicCategoryTable[gameMechanicData.gameCategory]
        self.view.btnResetNode.gameObject:SetActiveIfNecessary(gameMechanicCategoryData.canReChallenge)
        self.m_canReset = gameMechanicCategoryData.canReChallenge
    end
    local title = gameMechanicData and gameMechanicData.gameName or ""
    if mainTask and mainTask.extraInfo then
        title = string.isEmpty(title) and mainTask.extraInfo.taskTitle:GetText() or title
    end
    self:ProcessTitle(title)
    self:ProcessTitleIcon()
    self:_UpdateSubGameStage()
end
CommonTaskTrackHudCtrl._RefreshCustomTaskTrack = HL.Method() << function(self)
    local trackingMgr = GameInstance.world.levelScriptTaskTrackingManager
    local customTask = trackingMgr.customTask
    local goalCount = customTask ~= nil and customTask.objectives.Length or 0
    self.view.goalRoot.gameObject:SetActive(goalCount > 0)
    self.view.failReasonRoot.gameObject:SetActive(false)
    self.view.mainGoalRoot.gameObject:SetActive(goalCount > 0)
    self.m_mainGoalCellCache:Refresh(goalCount, function(cell, index)
        cell:InitCommonTaskGoalCell(index, CS.Beyond.Gameplay.LevelScriptTaskType.Custom)
    end)
    self.view.extraGoalRoot.gameObject:SetActive(false)
    self.m_extraGoalCellCache:Refresh(0)
    self.view.bottomBtnNode.gameObject:SetActive(false)
    if customTask ~= nil then
        local taskExtraInfo = customTask.extraInfo
        local title = taskExtraInfo.taskTitle:GetText()
        self:ProcessTitle(title)
    end
    self:_UpdateSubGameStage()
end
CommonTaskTrackHudCtrl._RefreshMainTask = HL.Method() << function(self)
    local trackingMgr = GameInstance.world.levelScriptTaskTrackingManager
    local mainTask = trackingMgr.mainTask
    local goalCount = mainTask ~= nil and mainTask.objectives.Length or 0
    self.view.mainGoalRoot.gameObject:SetActive(goalCount > 0)
    self.m_mainGoalCellCache:Refresh(goalCount, function(cell, index)
        cell:InitCommonTaskGoalCell(index, CS.Beyond.Gameplay.LevelScriptTaskType.Main)
    end)
end
CommonTaskTrackHudCtrl._RefreshExtraTask = HL.Method() << function(self)
    local trackingMgr = GameInstance.world.levelScriptTaskTrackingManager
    local extraTask = trackingMgr.extraTask
    local extraGoalCount = extraTask ~= nil and extraTask.objectives.Length or 0
    self.view.extraGoalRoot.gameObject:SetActive(extraGoalCount > 0)
    self.m_extraGoalCellCache:Refresh(extraGoalCount, function(cell, index)
        cell:InitCommonTaskGoalCell(index, CS.Beyond.Gameplay.LevelScriptTaskType.Extra)
    end)
end
CommonTaskTrackHudCtrl._RefreshCustomTask = HL.Method() << function(self)
    local trackingMgr = GameInstance.world.levelScriptTaskTrackingManager
    local customTask = trackingMgr.customTask
    local goalCount = customTask ~= nil and customTask.objectives.Length or 0
    self.view.goalRoot.gameObject:SetActive(goalCount > 0)
    self.view.failReasonRoot.gameObject:SetActive(false)
    self.view.mainGoalRoot.gameObject:SetActive(goalCount > 0)
    self.m_mainGoalCellCache:Refresh(goalCount, function(cell, index)
        cell:InitCommonTaskGoalCell(index, CS.Beyond.Gameplay.LevelScriptTaskType.Custom)
    end)
end
CommonTaskTrackHudCtrl.OnSubGameStageChange = HL.Method() << function(self)
    self:_ToggleBtnVisible(false)
    self:_StartCoroutine(function()
        while true do
            if not self.taskGoalShowing then
                break
            end
            coroutine.step()
        end
        local wrapper = self:GetAnimationWrapper()
        self.m_contentShowing = true
        local scrollFadeTime = wrapper:GetClipLength(CONTENT_SCROLL_FADE_ANIM)
        wrapper:Play(CONTENT_SCROLL_FADE_ANIM)
        coroutine.wait(scrollFadeTime)
        self.m_contentShowing = false
        self:_UpdateSubGameStage()
        local contentRefreshTime = wrapper:GetClipLength(CONTENT_REFRESH_ANIM)
        wrapper:Play(CONTENT_REFRESH_ANIM)
        coroutine.wait(contentRefreshTime)
        self:_ToggleBtnVisible(true)
    end)
end
CommonTaskTrackHudCtrl.OnTrackingTaskChange = HL.Method(HL.Any) << function(self, args)
    self:_StartCoroutine(function()
        while true do
            if not self.taskGoalShowing and not self.m_contentShowing then
                break
            end
            coroutine.step()
        end
        local taskType = unpack(args)
        if taskType == CS.Beyond.Gameplay.LevelScriptTaskType.Main then
            self:_RefreshMainTask()
        elseif taskType == CS.Beyond.Gameplay.LevelScriptTaskType.Extra then
            self:_RefreshExtraTask()
        elseif taskType == CS.Beyond.Gameplay.LevelScriptTaskType.Custom then
            self:_RefreshCustomTask()
        end
    end)
end
CommonTaskTrackHudCtrl.OnSubGameFinishStateChange = HL.Method(HL.Any) << function(self, args)
    local subGameId, phase = unpack(args)
    if phase == Phase.Normal then
        self:_ToggleTitleState(phase)
    elseif phase == Phase.Fail then
        if self.m_subGameData.modeType ~= GEnums.GameModeType.Blackbox then
            LuaSystemManager.commonTaskTrackSystem:AddRequest("TrackHudShowEndEffect", function()
                self:_DoFailContentShowing(phase)
            end, function()
                self:Close()
            end)
        else
            self:RefreshFailInfo()
            self:_ManuSetFailState()
            self:_ToggleTitleState(phase)
            self.view.titleFail:Play(TITLE_FAIL_ANIM)
        end
    else
        if self.m_curPhase ~= Phase.CompleteMainGoal and self.m_curPhase ~= Phase.CompleteAllGoal then
            if self.m_subGameData.modeType ~= GEnums.GameModeType.Blackbox then
                LuaSystemManager.commonTaskTrackSystem:AddRequest("TrackHudShowEndEffect", function()
                    self:_DoSuccContentShowing(phase)
                end, function()
                    self:Close()
                end)
            else
                self:_ToggleTitleState(phase)
                self.view.titleFinish:Play(TITLE_FINISH_ANIM)
            end
        end
    end
    self.m_curPhase = phase
end
CommonTaskTrackHudCtrl._DoFailContentShowing = HL.Method(HL.Number) << function(self, phase)
    self:_ToggleBtnVisible(false)
    self:_ManuSetFailState()
    AudioAdapter.PostEvent("Au_UI_Mission_Step_Fail")
    self.m_contentShowingFinish = false
    self.m_contentShowingCor = self:_StartCoroutine(function()
        while true do
            if not self.taskGoalShowing then
                break
            end
            coroutine.step()
        end
        local wrapper = self:GetAnimationWrapper()
        local contentScrollFadeTime = wrapper:GetClipLength(CONTENT_SCROLL_FADE_ANIM)
        wrapper:Play(CONTENT_SCROLL_FADE_ANIM)
        coroutine.wait(contentScrollFadeTime)
        Notify(MessageConst.ON_ONE_COMMON_TASK_PANEL_FINISH, "TrackHudShowEndEffect")
        AudioAdapter.PostEvent("Au_UI_Mission_Fail")
        self:RefreshFailInfo()
        self:_ToggleTitleState(phase)
        local titleFail = self.view.titleFail
        local titleStateTime = titleFail:GetClipLength(TITLE_FAIL_ANIM)
        titleFail:Play(TITLE_FAIL_ANIM)
        coroutine.wait(titleStateTime)
        local titleScrollFadeTime = wrapper:GetClipLength(TITLE_SCROLL_FADE_ANIM)
        wrapper:Play(TITLE_SCROLL_FADE_ANIM)
        coroutine.wait(titleScrollFadeTime)
        self.m_contentShowingFinish = true
    end)
end
CommonTaskTrackHudCtrl._DoSuccContentShowing = HL.Method(HL.Number) << function(self, phase)
    self:_ToggleBtnVisible(false)
    self.m_contentShowingFinish = false
    self.m_contentShowingCor = self:_StartCoroutine(function()
        while true do
            if not self.taskGoalShowing then
                break
            end
            coroutine.step()
        end
        local wrapper = self:GetAnimationWrapper()
        local contentScrollFadeTime = wrapper:GetClipLength(CONTENT_SCROLL_FADE_ANIM)
        wrapper:Play(CONTENT_SCROLL_FADE_ANIM)
        coroutine.wait(contentScrollFadeTime)
        Notify(MessageConst.ON_ONE_COMMON_TASK_PANEL_FINISH, "TrackHudShowEndEffect")
        AudioAdapter.PostEvent("Au_UI_Mission_Complete")
        self:_ToggleTitleState(phase)
        local titleFinish = self.view.titleFinish
        local titleStateTime = titleFinish:GetClipLength(TITLE_FINISH_ANIM)
        titleFinish:Play(TITLE_FINISH_ANIM)
        coroutine.wait(titleStateTime)
        local titleScrollFadeTime = wrapper:GetClipLength(TITLE_SCROLL_FADE_ANIM)
        wrapper:Play(TITLE_SCROLL_FADE_ANIM)
        coroutine.wait(titleScrollFadeTime)
        self.m_contentShowingFinish = true
    end)
end
CommonTaskTrackHudCtrl._ManuSetFailState = HL.Method() << function(self)
    local itemCells = self.m_mainGoalCellCache:GetItems()
    for _, itemCell in ipairs(itemCells) do
        itemCell:TrySetStateFail()
    end
    local itemCells = self.m_extraGoalCellCache:GetItems()
    for _, itemCell in ipairs(itemCells) do
        itemCell:TrySetStateFail()
    end
end
CommonTaskTrackHudCtrl._ToggleTitleState = HL.Method(HL.Number) << function(self, phase)
    self.view.titleDefault.gameObject:SetActive(phase == Phase.Normal)
    self.view.titleFail.gameObject:SetActive(phase == Phase.Fail)
    self.view.titleFinish.gameObject:SetActive(phase == Phase.CompleteMainGoal or phase == Phase.CompleteAllGoal)
end
CommonTaskTrackHudCtrl._UpdateSubGameStage = HL.Method() << function(self)
    local content = ""
    if not self.m_isShowCustomTask and GameInstance.mode.curSubGame ~= nil then
        local game = GameInstance.mode.curSubGame
        local maxStage = game.maxStage
        if maxStage > 1 then
            local stage = game.stage
            content = string.format(STAGE_TEXT_FORMAT, stage, maxStage)
        end
    end
    local hasContent = not string.isEmpty(content)
    self.view.scheduleNode.gameObject:SetActiveIfNecessary(hasContent)
    self.view.scheduleText.text = UIUtils.resolveTextStyle(content)
end
CommonTaskTrackHudCtrl.RefreshFailInfo = HL.Method() << function(self)
    local failInfo = self.m_subGameData.failInfo:GetText()
    self.view.goalRoot.gameObject:SetActive(false)
    self.view.failReasonRoot.gameObject:SetActive(true)
    self.view.failReason.text = UIUtils.resolveTextStyle(failInfo)
end
CommonTaskTrackHudCtrl.ProcessTitle = HL.Method(HL.String) << function(self, title)
    self.view.titleDefaultTxt.text = UIUtils.resolveTextStyle(title)
    self.view.titleFailTxt.text = UIUtils.resolveTextStyle(title)
    self.view.titleFinishTxt.text = UIUtils.resolveTextStyle(title)
end
CommonTaskTrackHudCtrl.ProcessTitleIcon = HL.Method() << function(self)
    local success, gameTblData = Tables.gameMechanicTable:TryGetValue(self.m_subGameId)
    local gameTypeData = success and Tables.gameMechanicCategoryTable[gameTblData.gameCategory] or {}
    local iconName = gameTypeData.icon
    local iconBgName = gameTypeData.iconBg
    if not string.isEmpty(iconName) then
        local sprite = self:LoadSprite(UIConst.UI_SPRITE_COMMON_TASK_TRACK, iconName)
        self.view.defaultIcon.sprite = sprite
        self.view.finishIcon.sprite = sprite
        self.view.failIcon.sprite = sprite
    end
    local hasIconBgName = not string.isEmpty(iconBgName)
    self.view.defaultIconBg.gameObject:SetActiveIfNecessary(hasIconBgName)
    self.view.finishIconBg.gameObject:SetActiveIfNecessary(hasIconBgName)
    self.view.failIconBg.gameObject:SetActiveIfNecessary(hasIconBgName)
    if hasIconBgName then
        local bgSprite = self:LoadSprite(UIConst.UI_SPRITE_COMMON_TASK_TRACK, iconBgName)
        self.view.defaultIconBg.sprite = bgSprite
        self.view.finishIconBg.sprite = bgSprite
        self.view.failIconBg.sprite = bgSprite
    end
end
CommonTaskTrackHudCtrl._OnBtnResetClick = HL.Method() << function(self)
    if self.m_subGameData.modeType == GEnums.GameModeType.Dungeon then
        local gameMechanicCfg = Tables.gameMechanicTable[self.m_subGameId]
        local dungeonTypeCfg = Tables.dungeonTypeTable[gameMechanicCfg.gameCategory]
        self:_ShowConfirmPopup(dungeonTypeCfg.resetConfirmText, function()
            GameInstance.mode:SendReStart()
        end)
    elseif self.m_subGameData.modeType == GEnums.GameModeType.WorldChallenge then
        logger.error("world challenge cannot reset")
    end
end
CommonTaskTrackHudCtrl._OnBtnStopClick = HL.Method() << function(self)
    if self.m_subGameData.modeType == GEnums.GameModeType.Dungeon then
        logger.error("dungeon cannot click stop btn")
    elseif self.m_subGameData.modeType == GEnums.GameModeType.WorldChallenge then
        self:_ShowConfirmPopup(Language.LUA_COMMON_TASK_TRACK_STOP_WORLD_CHALLENGE, function()
            GameInstance.mode:SendQuit()
        end)
    end
end
CommonTaskTrackHudCtrl._ShowConfirmPopup = HL.Method(HL.String, HL.Function) << function(self, content, confirmFunc)
    self:Notify(MessageConst.SHOW_POP_UP, {
        content = content,
        onConfirm = function()
            confirmFunc()
        end,
        freezeWorld = true,
        freezeServer = true,
    })
end
CommonTaskTrackHudCtrl._LoadSubGameData = HL.Method(HL.Any).Return(HL.Boolean) << function(self, instId)
    local success, subGameData = DataManager.subGameInstDataTable:TryGetValue(instId)
    if success then
        self.m_subGameData = subGameData
    end
    return success
end
CommonTaskTrackHudCtrl._ToggleBtnVisible = HL.Method(HL.Boolean) << function(self, isOn)
    self.view.btnResetNode.gameObject:SetActiveIfNecessary(isOn and self.m_canReset)
    self.view.btnStopNode.gameObject:SetActiveIfNecessary(isOn and self.m_canQuit)
end
CommonTaskTrackHudCtrl.OnHudBtnVisibleChange = HL.Method(HL.Any) << function(self, arg)
    local isOn = unpack(arg)
    self:_ToggleBtnVisible(isOn)
end
CommonTaskTrackHudCtrl.OnSubGameReset = HL.Method() << function(self)
    self.m_subGameId = ""
    self.m_subGameData = nil
    self:_ToggleBtnVisible(false)
end
CommonTaskTrackHudCtrl.AddPositionOffset = HL.Method(Vector2) << function(self, offset)
    if offset == nil then
        return
    end
    local anchoredPosition = self.view.main.anchoredPosition
    self.view.main.anchoredPosition = anchoredPosition + offset
end
CommonTaskTrackHudCtrl.ClearPositionOffset = HL.Method() << function(self)
    self.view.main.anchoredPosition = self.m_originalAnchoredPos
end
CommonTaskTrackHudCtrl.GetContentBottomFollowPosition = HL.Method().Return(Vector3) << function(self)
    return self.view.bottomFollowNode.position
end
CommonTaskTrackHudCtrl.HideBottomNode = HL.Method() << function(self)
    self.view.bottomBtnNode.gameObject:SetActiveIfNecessary(false)
end
HL.Commit(CommonTaskTrackHudCtrl)