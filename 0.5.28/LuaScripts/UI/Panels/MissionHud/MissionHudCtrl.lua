local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.MissionHud
local missionCompletePopCtrl = require_ex('UI/Panels/MissionCompletePop/MissionCompletePopCtrl')
local QuestState = CS.Beyond.Gameplay.MissionSystem.QuestState
local MissionState = CS.Beyond.Gameplay.MissionSystem.MissionState
local TrackAction = CS.Beyond.Gameplay.MissionSystem.TrackAction
local MissionAnimType = CS.Beyond.Gameplay.MissionShowData.AnimType
local QuestAnimType = CS.Beyond.Gameplay.QuestShowData.AnimType
local ObjectiveAnimType = CS.Beyond.Gameplay.ObjectiveShowData.AnimType
local TARGET_COMPLETE_CLIP_NAME = "missionhud_target_complete_in"
local OBJECTIVE_CELL_PADDING_TOP = 16
local QUEST_CELL_PADDING_TOP = 10
local QUEST_CELL_PADDING_LEFT = 80
local OPTIONAL_TEXT_COLOR = "C7EC59"
MissionHudCtrl = HL.Class('MissionHudCtrl', uiCtrl.UICtrl)
MissionHudCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.OPEN_MISSION_DEBUG] = 'OpenDebug', [MessageConst.ON_SYNC_ALL_MISSION] = 'OnSyncAllMission', [MessageConst.ON_MISSION_STATE_CHANGE] = '_OnMissionStateChange', [MessageConst.ON_QUEST_OBJECTIVE_UPDATE] = '_OnQuestObjectiveUpdate', [MessageConst.GAME_MODE_ENABLE] = '_OnGameModeChange', [MessageConst.ON_TRACKING_SNS] = '_OnTrackingSns', [MessageConst.ON_TOGGLE_FAC_TOP_VIEW] = '_OnFacToggleTopView', [MessageConst.ON_TRACKING_TO_UI] = '_OnTrackingToUI' }
MissionHudCtrl.m_missionSystem = HL.Field(HL.Any)
MissionHudCtrl.m_questCellCache = HL.Field(HL.Forward("UIListCache"))
MissionHudCtrl.m_cntAnimMissionShowData = HL.Field(HL.Any)
MissionHudCtrl.m_hasSignificantMission = HL.Field(HL.Boolean) << false
MissionHudCtrl.m_missionStateChangeSignal = HL.Field(HL.Table)
MissionHudCtrl.m_updateDistanceTimerHandler = HL.Field(HL.Any)
local MISSION_ANIM_TYPE = { None = 0, NewMission = 1, CompleteMission = 2, Track = 3, CompleteObjective = 4, RollbackObjective = 5, NewQuest = 6, CompleteQuest = 7, }
local MissionType = CS.Beyond.Gameplay.MissionSystem.MissionType
local MissionTypeConfig = { [MissionType.Main] = { missionIcon = "main_mission_icon", missionIconBg = "main_mission_icon_gray", }, [MissionType.Char] = { missionIcon = "char_mission_icon", missionIconBg = "char_mission_icon_gray", }, [MissionType.Factory] = { missionIcon = "fac_mission_icon", missionIconBg = "fac_mission_icon_gray", }, [MissionType.World] = { missionIcon = "world_mission_icon", missionIconBg = "world_mission_icon_gray", }, [MissionType.Misc] = { missionIcon = "misc_mission_icon", missionIconBg = "misc_mission_icon_gray", }, [MissionType.Bloc] = { missionIcon = "misc_mission_icon", missionIconBg = "misc_mission_icon_gray", }, }
MissionHudCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_missionSystem = GameInstance.player.mission
    self.m_missionSystem:EnableMissionTrackData()
    self.m_questCellCache = UIUtils.genCellCache(self.view.questCell)
    self.view.trackBtn.onClick:RemoveAllListeners()
    self.view.trackBtn.onClick:AddListener(function()
        self:_SkipAnimationAndTrackMission()
    end)
    self:_RefreshOpenBtn()
    self:_RefreshTrackMission()
    local hasSignificantMission = self.m_missionSystem:HasSignificantMission(-1)
    self.m_hasSignificantMission = hasSignificantMission
    self.view.significantMark.gameObject:SetActive(hasSignificantMission)
    self.view.openMissionUI.onClick:AddListener(function()
        local missionId = ""
        if self.m_cntAnimMissionShowData and not string.isEmpty(self.m_cntAnimMissionShowData.missionId) then
            missionId = self.m_cntAnimMissionShowData.missionId
        end
        PhaseManager:OpenPhase(PhaseId.Mission, { autoSelect = missionId })
    end)
    if LuaSystemManager.facSystem.inTopView then
        self.view.trackBtn.gameObject:GetComponent("NonDrawingGraphic").raycastTarget = false
    else
        self.view.trackBtn.gameObject:GetComponent("NonDrawingGraphic").raycastTarget = true
    end
    local lastGetDistanceTime = 0
    self.m_updateDistanceTimerHandler = LuaUpdate:Add("Tick", function()
        if Time.unscaledTime - lastGetDistanceTime > 0.1 then
            lastGetDistanceTime = Time.unscaledTime
            if self.m_missionStateChangeSignal and Time.unscaledTime - self.m_missionStateChangeSignal.time > 0.1 then
                local hasSignificantMission = self.m_missionSystem:HasSignificantMission(-1)
                if not self.m_hasSignificantMission and hasSignificantMission then
                    self.view.significantMark:ClearTween(false)
                    self.view.significantMark.gameObject:SetActive(true)
                elseif self.m_hasSignificantMission and not hasSignificantMission then
                    self.view.significantMark.gameObject:SetActive(true)
                    self.view.significantMark:ClearTween(false)
                    self.view.significantMark:PlayOutAnimation(function()
                        self.view.significantMark.gameObject:SetActive(false)
                    end)
                end
                self.m_hasSignificantMission = hasSignificantMission
                self.m_missionStateChangeSignal = nil
            end
            self:_UpdateAllObjectiveDistance()
        end
    end)
    local animThread = function(animInfo)
        local animWrapper = animInfo.animWrapper
        local inClipName = animInfo.inClipName
        if not string.isEmpty(inClipName) then
            local clipLength = animWrapper:GetClipLength(inClipName)
            animWrapper:SampleClipAtPercent(inClipName, 0.0)
            animWrapper:PlayWithTween(inClipName)
            local startTime = Time.time
            while true do
                if self:IsHide() then
                    break
                end
                if Time.time - startTime > clipLength then
                    break
                end
                coroutine.yield()
            end
            animWrapper:SampleClipAtPercent(inClipName, 1.0)
        end
        local outClipName = animInfo.outClipName
        if not string.isEmpty(outClipName) then
            local clipLength = animWrapper:GetClipLength(outClipName)
            animWrapper:SampleClipAtPercent(outClipName, 0.0)
            animWrapper:PlayWithTween(outClipName)
            local startTime = Time.time
            while true do
                if self:IsHide() then
                    break
                end
                if Time.time - startTime > clipLength then
                    break
                end
                coroutine.yield()
            end
            animWrapper:SampleClipAtPercent(outClipName, 1.0)
        end
    end
    self:_StartCoroutine(function()
        local panelAnimWrapper = self:GetAnimationWrapper()
        local missionSystem = self.m_missionSystem
        local isPlaying = false
        while true do
            local needRefreshTrackingMission = false
            while true do
                local continueTime = 0
                while self:IsHide() or Time.unscaledTime < continueTime do
                    if self:IsHide() then
                        continueTime = Time.unscaledTime + 0.1
                    end
                    coroutine.step()
                end
                local cntTrackMissionId = missionSystem.trackMissionId
                local missionShowData
                if self.m_missionSystem:InCharDungeon() then
                    if missionSystem:GetMissionShowDataCountByMissionId(cntTrackMissionId) > 0 then
                        missionShowData = missionSystem:GetFirstMissionShowDataByMissionId(cntTrackMissionId)
                    end
                else
                    if missionSystem:GetMissionShowDataCount() > 0 then
                        missionShowData = missionSystem:GetFirstMissionShowData()
                    end
                end
                if missionShowData then
                    missionShowData.isPlaying = true
                end
                if missionShowData and missionShowData.animType ~= MissionAnimType.Refresh then
                    if not isPlaying then
                        isPlaying = true
                        Notify(MessageConst.ON_START_MISSION_HUD_ANIM)
                    end
                else
                    if isPlaying then
                        isPlaying = false
                        Notify(MessageConst.ON_FINISH_MISSION_HUD_ANIM)
                    end
                end
                if not missionShowData then
                    break
                end
                needRefreshTrackingMission = true
                if missionShowData.animType ~= MissionAnimType.Refresh then
                    while not (self:IsShow() and panelAnimWrapper.curState ~= CS.Beyond.UI.UIConst.AnimationState.In) do
                        coroutine.step()
                    end
                    self.view.leftNode.gameObject:SetActive(true)
                    if missionShowData.animType == MissionAnimType.ChapterStart then
                        missionCompletePopCtrl.MissionCompletePopCtrl.OnChapterStart({ missionShowData.chapterId })
                        while missionCompletePopCtrl.MissionCompletePopCtrl.IsOpen() do
                            coroutine.step()
                        end
                    elseif missionShowData.animType == MissionAnimType.ChapterComplete then
                        missionCompletePopCtrl.MissionCompletePopCtrl.OnChapterCompleted({ missionShowData.chapterId })
                        while missionCompletePopCtrl.MissionCompletePopCtrl.IsOpen() do
                            coroutine.step()
                        end
                    else
                        self:_InitMissionShowData(missionShowData)
                        missionShowData.modifyContent = false
                        local clipName
                        if missionShowData.animType == MissionAnimType.New then
                            clipName = self.view.config.NEW_MISSION_CLIP_NAME
                        elseif missionShowData.animType == MissionAnimType.Complete then
                            Notify(MessageConst.ON_COMPLETE_MISSION_ANIM_START, missionShowData.missionId)
                            clipName = self.view.config.MISSION_COMPLETE_CLIP_NAME
                        elseif missionShowData.animType == MissionAnimType.Track then
                            clipName = self.view.config.TRACK_MISSION_CLIP_NAME
                        elseif missionShowData.animType == MissionAnimType.TrackOut then
                            clipName = self.view.config.TRACK_MISSION_OUT_CLIP_NAME
                        end
                        if clipName then
                            if missionShowData.animType == MissionAnimType.New then
                                AudioManager.PostEvent("Au_UI_Mission_New")
                            elseif missionShowData.animType == MissionAnimType.Complete then
                                AudioManager.PostEvent("Au_UI_Mission_Complete")
                            end
                            local animationWrapper = self:GetAnimationWrapper()
                            local clipLength = animationWrapper:GetClipLength(clipName)
                            animationWrapper:SampleClipAtPercent(clipName, 0)
                            animationWrapper:PlayWithTween(clipName)
                            local startTime = Time.time
                            while Time.time - startTime <= clipLength do
                                self:_RefreshQuestContentIfNecessary(self.m_cntAnimMissionShowData)
                                if missionShowData.skipAnimSignal then
                                    break
                                end
                                coroutine.step()
                            end
                            self:_RefreshQuestContentIfNecessary(self.m_cntAnimMissionShowData)
                            animationWrapper:SampleClipAtPercent(clipName, 1)
                            if missionShowData.animType == MissionAnimType.New then
                                clipName = self.view.config.NEW_MISSION_OUT_CLIP_NAME
                                startTime = Time.time
                                while Time.time - startTime <= self.view.config.NEW_ANIM_HOLD_TIME do
                                    if missionShowData.skipAnimSignal then
                                        self.view.trackButtonNode:PlayWithTween("missionhud_trackbutton_press")
                                        local clickLength = self.view.trackButtonNode:GetClipLength("missionhud_trackbutton_press")
                                        coroutine.wait(clickLength)
                                        self.view.trackButtonNode:SampleClipAtPercent("missionhud_trackbutton_press", 1)
                                        break
                                    end
                                    coroutine.step()
                                end
                                clipLength = animationWrapper:GetClipLength(clipName)
                                animationWrapper:SampleClipAtPercent(clipName, 0)
                                animationWrapper:PlayWithTween(clipName)
                                startTime = Time.time
                                local totalTime = clipLength
                                while Time.time - startTime <= totalTime do
                                    if missionShowData.skipAnimSignal then
                                        break
                                    end
                                    if self:IsHide() then
                                        break
                                    end
                                    coroutine.step()
                                end
                                animationWrapper:SampleClipAtPercent(clipName, 1)
                            elseif missionShowData.animType == MissionAnimType.Complete then
                                while LuaSystemManager.mainHudToastSystem.m_isShowing do
                                    coroutine.step()
                                end
                            end
                        else
                            local newQuestAnim = false
                            for _, questShowData in pairs(missionShowData.questShowDataList) do
                                if questShowData.animType == QuestAnimType.New then
                                    newQuestAnim = true
                                end
                            end
                            if newQuestAnim then
                                local skipNewQuestAnim = false
                                if self.m_missionSystem.trackMissionId ~= missionShowData.missionId then
                                    local hasHudUpdateTag = false
                                    for _, questShowData in pairs(missionShowData.questShowDataList) do
                                        if questShowData.needHudUpdateTag then
                                            hasHudUpdateTag = true
                                        end
                                    end
                                    if not hasHudUpdateTag then
                                        skipNewQuestAnim = true;
                                    end
                                end
                                if not skipNewQuestAnim then
                                    AudioManager.PostEvent("Au_UI_Mission_Step_Update")
                                    AudioManager.PostEvent("Au_UI_Mission_Step_New")
                                    local rootAnimationWrapper = self:GetAnimationWrapper()
                                    local newQuestClipLength = rootAnimationWrapper:GetClipLength(self.view.config.NEW_QUEST_CLIP_NAME)
                                    rootAnimationWrapper:SampleClipAtPercent(self.view.config.NEW_QUEST_CLIP_NAME, 0)
                                    rootAnimationWrapper:PlayWithTween(self.view.config.NEW_QUEST_CLIP_NAME)
                                    local moveRightCurve = self.view.config.QUEST_MOVE_RIGHT_CURVE
                                    local moveRightLength = CSUtils.GetAnimationCurveLength(moveRightCurve)
                                    local questCellNewClipLength = self.view.questCell.animationWrapper:GetClipLength(self.view.config.QUEST_CELL_NEW_CLIP_NAME)
                                    local totalTime = math.max(questCellNewClipLength, moveRightLength, newQuestClipLength)
                                    local startTime = Time.time
                                    local hasSkipAnim = false
                                    local function processSkipAnim()
                                        if missionShowData.skipAnimSignal and not hasSkipAnim then
                                            hasSkipAnim = true
                                            missionShowData.skipAnimSignal = false
                                            self.view.trackButtonNode:PlayWithTween("missionhud_trackbutton_press")
                                            local clickLength = self.view.trackButtonNode:GetClipLength("missionhud_trackbutton_press")
                                            totalTime = Time.time + clickLength - startTime
                                        end
                                    end
                                    while Time.time - startTime < totalTime do
                                        self:_RefreshQuestContentIfNecessary(missionShowData)
                                        local needHudUpdateTag = false
                                        for _, questShowData in pairs(missionShowData.questShowDataList) do
                                            if questShowData.needHudUpdateTag then
                                                needHudUpdateTag = true
                                            end
                                        end
                                        self.view.updateTags.gameObject:SetActiveIfNecessary(needHudUpdateTag)
                                        if self:IsHide() then
                                            break
                                        end
                                        processSkipAnim()
                                        for _, questShowData in pairs(missionShowData.questShowDataList) do
                                            if questShowData.animType == QuestAnimType.New then
                                                local questCell = self:_GetQuestCell(questShowData.questId)
                                                if questCell then
                                                    local verticalLayoutGroup = questCell.gameObject:GetComponent(typeof(CS.UnityEngine.UI.VerticalLayoutGroup))
                                                    local questCellRectTransform = questCell.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
                                                    verticalLayoutGroup.padding.left = QUEST_CELL_PADDING_LEFT
                                                    LayoutRebuilder.MarkLayoutForRebuild(questCellRectTransform)
                                                    local questCellWidth = questCellRectTransform.sizeDelta.x
                                                    questCell.animationWrapper:SampleClip(self.view.config.QUEST_CELL_NEW_CLIP_NAME, math.min(Time.time - startTime, questCellNewClipLength))
                                                    local ratio = moveRightCurve:Evaluate(math.min(Time.time - startTime, moveRightLength))
                                                    verticalLayoutGroup.padding.left = math.floor(QUEST_CELL_PADDING_LEFT - questCellWidth * (1 - math.min(ratio, 1)))
                                                    LayoutRebuilder.MarkLayoutForRebuild(questCellRectTransform)
                                                    questCell.left.anchoredPosition = Vector2(-(questCellWidth * (1 - math.min(ratio, 1))), 0)
                                                end
                                            end
                                        end
                                        coroutine.step()
                                    end
                                    self:_RefreshQuestContentIfNecessary(missionShowData)
                                    rootAnimationWrapper:SampleClipAtPercent(self.view.config.NEW_QUEST_CLIP_NAME, 1)
                                    for _, questShowData in pairs(missionShowData.questShowDataList) do
                                        if questShowData.animType == QuestAnimType.New then
                                            local questCell = self:_GetQuestCell(questShowData.questId)
                                            local verticalLayoutGroup = questCell.gameObject:GetComponent(typeof(CS.UnityEngine.UI.VerticalLayoutGroup))
                                            local questCellRectTransform = questCell.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
                                            questCell.animationWrapper:SampleClipAtPercent(self.view.config.QUEST_CELL_NEW_CLIP_NAME, 1)
                                            verticalLayoutGroup.padding.left = QUEST_CELL_PADDING_LEFT
                                            LayoutRebuilder.MarkLayoutForRebuild(questCellRectTransform)
                                            questCell.left.anchoredPosition = Vector2(0, 0)
                                        end
                                    end
                                    if not hasSkipAnim then
                                        if missionShowData.missionId ~= self.m_missionSystem.trackMissionId then
                                            startTime = Time.time
                                            totalTime = self.view.config.NEW_QUEST_ANIM_HOLD_TIME
                                            while Time.time - startTime < totalTime do
                                                processSkipAnim()
                                                coroutine.step();
                                            end
                                        end
                                    end
                                    if not hasSkipAnim then
                                        totalTime = rootAnimationWrapper:GetClipLength(self.view.config.NEW_QUEST_OUT_CLIP_NAME)
                                        rootAnimationWrapper:SampleClipAtPercent(self.view.config.NEW_QUEST_OUT_CLIP_NAME, 0)
                                        rootAnimationWrapper:PlayWithTween(self.view.config.NEW_QUEST_OUT_CLIP_NAME)
                                        startTime = Time.time
                                        while Time.time - startTime < totalTime do
                                            processSkipAnim()
                                            if self:IsHide() then
                                                break
                                            end
                                            coroutine.step()
                                        end
                                    end
                                    rootAnimationWrapper:SampleClipAtPercent(self.view.config.NEW_QUEST_OUT_CLIP_NAME, 1)
                                    self.view.trackButtonNode:SampleClipAtPercent("missionhud_trackbutton_press", 1)
                                end
                            else
                                for _, questShowData in pairs(missionShowData.questShowDataList) do
                                    local questCell
                                    if questShowData.animType == QuestAnimType.Complete then
                                        questCell = self:_GetQuestCell(questShowData.questId)
                                        if questCell then
                                            AudioManager.PostEvent("Au_UI_Mission_Step_Complete")
                                            questCell.animationWrapper:SampleClipAtPercent(self.view.config.QUEST_CELL_COMPLETE_CLIP_NAME, 0)
                                            local clipLength = questCell.animationWrapper:GetClipLength(self.view.config.QUEST_CELL_COMPLETE_CLIP_NAME)
                                            questCell.animationWrapper:PlayWithTween(self.view.config.QUEST_CELL_COMPLETE_CLIP_NAME)
                                            coroutine.wait(clipLength)
                                            questCell.animationWrapper:SampleClipAtPercent(self.view.config.QUEST_CELL_COMPLETE_CLIP_NAME, 1)
                                            local verticalLayoutGroup = questCell.gameObject:GetComponent(typeof(CS.UnityEngine.UI.VerticalLayoutGroup))
                                            local questCellRectTransform = questCell.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
                                            local questCellHeight = questCellRectTransform.sizeDelta.y
                                            local moveUpCurve = self.view.config.QUEST_MOVE_UP_CURVE
                                            local moveUpLength = CSUtils.GetAnimationCurveLength(moveUpCurve)
                                            local startTime = Time.time
                                            while Time.time - startTime <= moveUpLength do
                                                local ratio = moveUpCurve:Evaluate(math.min(Time.time - startTime, moveUpLength))
                                                verticalLayoutGroup.padding.top = math.floor(QUEST_CELL_PADDING_TOP - questCellHeight * ratio)
                                                LayoutRebuilder.MarkLayoutForRebuild(questCellRectTransform)
                                                questCell.left.anchoredPosition = Vector2(0, questCellHeight * ratio)
                                                if self:IsHide() then
                                                    break
                                                end
                                                coroutine.step()
                                            end
                                            questCell.left.anchoredPosition = Vector2(0, 0)
                                        end
                                        break
                                    else
                                        for _, objectiveShowData in pairs(questShowData.objectiveShowDataList) do
                                            local objectiveAnimInfo
                                            if objectiveShowData.animType == ObjectiveAnimType.Complete then
                                                objectiveAnimInfo = self:_GetObjectiveCellAnimInfo(0, objectiveShowData.questId, objectiveShowData.objectiveIdx)
                                            elseif objectiveShowData.animType == ObjectiveAnimType.Rollback then
                                                objectiveAnimInfo = self:_GetObjectiveCellAnimInfo(1, objectiveShowData.questId, objectiveShowData.objectiveIdx)
                                            end
                                            if objectiveAnimInfo then
                                                local co = coroutine.create(animThread)
                                                while coroutine.status(co) ~= "dead" do
                                                    local status, _ = coroutine.resume(co, objectiveAnimInfo)
                                                    if self:IsHide() then
                                                        break
                                                    end
                                                    coroutine.step()
                                                end
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                if self.m_missionSystem:InCharDungeon() then
                    missionSystem:PopMissionShowDataByMissionId(cntTrackMissionId)
                else
                    missionSystem:PopMissionShowData()
                end
            end
            if needRefreshTrackingMission then
                self:_RefreshTrackMission()
            end
            coroutine.step()
        end
    end)
end
MissionHudCtrl._IsPlayingMissionAnim = HL.Method().Return(HL.Boolean) << function(self)
    if self.m_missionSystem:InCharDungeon() then
        return self.m_missionSystem:GetMissionShowDataCount() > 0
    else
        return self.m_missionSystem:GetMissionShowDataCountByMissionId(self.m_missionSystem.trackMissionId) > 0
    end
end
MissionHudCtrl._InitMissionShowData = HL.Method(HL.Any) << function(self, missionShowData)
    self.m_cntAnimMissionShowData = missionShowData
    self.view.missionName.text = missionShowData.missionName:GetText()
    if MissionTypeConfig[missionShowData.missionType] then
        self.view.missionIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MISSION_TYPE_ICON, MissionTypeConfig[missionShowData.missionType].missionIcon)
        self.view.missionIconBg.sprite = self:LoadSprite(UIConst.UI_SPRITE_MISSION_TYPE_ICON, MissionTypeConfig[missionShowData.missionType].missionIconBg)
    else
        self.view.missionIcon.sprite = nil
        self.view.missionIconBg.sprite = nil
    end
    self.view.newMissionTags.gameObject:SetActive(false)
    self.view.updateTags.gameObject:SetActive(false)
    self.view.finishGlow.gameObject:SetActive(false)
    self.view.trackButtonNode.gameObject:SetActive(false)
    self.view.trackingIcon.gameObject:SetActive(false)
    self.view.trackingIcon.color = self.m_missionSystem:GetMissionColor(missionShowData.missionId)
    self.view.missionIcon.gameObject:SetActive(false)
    self.view.missionIconBg.gameObject:SetActive(false)
    if missionShowData.animType == MissionAnimType.New then
        self.view.newMissionTags.gameObject:SetActive(true)
        self.view.trackButtonNode.gameObject:SetActive(true)
        self.view.missionIcon.gameObject:SetActive(true)
    elseif missionShowData.animType == MissionAnimType.Complete then
        self.view.finishGlow.gameObject:SetActive(true)
        self.view.missionIcon.gameObject:SetActive(true)
    elseif missionShowData.animType == MissionAnimType.Track then
        self.view.trackingIcon.gameObject:SetActive(true)
    elseif missionShowData.animType == MissionAnimType.TrackOut then
        self.view.trackingIcon.gameObject:SetActive(true)
    end
    local animType = self:_GetMissionShowDataAnimType(missionShowData)
    if animType ~= MISSION_ANIM_TYPE.NewQuest then
        self.view.trackingIcon.gameObject:SetActive(true)
    end
    self.m_questCellCache:Refresh(missionShowData.questShowDataList.Count, function(questCell, questLuaIdx)
        local questIdx = CSIndex(questLuaIdx)
        local questShowData = missionShowData.questShowDataList[questIdx]
        if questShowData.animType == QuestAnimType.New then
            self.view.updateTags.gameObject:SetActive(true)
            self.view.trackButtonNode.gameObject:SetActive(true)
            self.view.missionIconBg.gameObject:SetActive(true)
        end
        questCell.questId = questShowData.questId
        local verticalLayoutGroup = questCell.gameObject:GetComponent(typeof(CS.UnityEngine.UI.VerticalLayoutGroup))
        local questCellRectTransform = questCell.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
        verticalLayoutGroup.padding.top = QUEST_CELL_PADDING_TOP
        verticalLayoutGroup.padding.left = QUEST_CELL_PADDING_LEFT
        LayoutRebuilder.MarkLayoutForRebuild(questCellRectTransform)
        questCell.left.anchoredPosition = Vector2(0, 0)
        questCell.multiObjectiveDeco.gameObject:SetActive(questShowData.objectiveShowDataList.Count > 1)
        questCell.objectiveCellCache = questCell.objectiveCellCache or UIUtils.genCellCache(questCell.objectiveCell)
        questCell.objectiveCellCache:Refresh(questShowData.objectiveShowDataList.Count, function(objectiveCell, objectiveLuaIdx)
            local objectiveIdx = CSIndex(objectiveLuaIdx)
            local objectiveShowData = questShowData.objectiveShowDataList[objectiveIdx]
            objectiveCell.questId = questShowData.questId
            objectiveCell.objectiveIdx = objectiveIdx
            self:_UpdateObjectiveCellDesc(objectiveCell, objectiveShowData)
            self:_UpdateObjectiveCellProgress(objectiveCell, objectiveShowData)
            self:_UpdateObjectiveCellDistance(objectiveCell, objectiveShowData)
            self:_UpdateObjectiveCellComplete(objectiveCell, objectiveShowData)
            if objectiveShowData.isCompleted then
                objectiveCell.animationWrapper:SampleClipAtPercent(self.view.config.OBJECTIVE_CELL_COMPLETE_CLIP_NAME, 1)
            else
                objectiveCell.animationWrapper:SampleClipAtPercent(self.view.config.OBJECTIVE_CELL_COMPLETE_CLIP_NAME, 0)
            end
        end)
        questCell.animationWrapper:SampleClipAtPercent(self.view.config.QUEST_CELL_NEW_CLIP_NAME, 1)
    end)
    self.view.animationWrapper:SampleClipAtPercent(self.view.config.TRACK_MISSION_CLIP_NAME, 1)
end
MissionHudCtrl._RefreshQuestContentIfNecessary = HL.Method(HL.Any) << function(self, missionShowData)
    if missionShowData.modifyContent then
        missionShowData.modifyContent = false
        self:_RefreshQuestContent(missionShowData)
    end
end
MissionHudCtrl._RefreshQuestContent = HL.Method(HL.Any) << function(self, missionShowData)
    self.m_questCellCache:Refresh(missionShowData.questShowDataList.Count, function(questCell, questLuaIdx)
        local questIdx = CSIndex(questLuaIdx)
        local questShowData = missionShowData.questShowDataList[questIdx]
        if questShowData.animType == QuestAnimType.New then
            self.view.updateTags.gameObject:SetActive(true)
            self.view.trackButtonNode.gameObject:SetActive(true)
        end
        questCell.questId = questShowData.questId
        local verticalLayoutGroup = questCell.gameObject:GetComponent(typeof(CS.UnityEngine.UI.VerticalLayoutGroup))
        local questCellRectTransform = questCell.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
        verticalLayoutGroup.padding.top = QUEST_CELL_PADDING_TOP
        verticalLayoutGroup.padding.left = QUEST_CELL_PADDING_LEFT
        LayoutRebuilder.MarkLayoutForRebuild(questCellRectTransform)
        questCell.multiObjectiveDeco.gameObject:SetActive(questShowData.objectiveShowDataList.Count > 1)
        questCell.objectiveCellCache = questCell.objectiveCellCache or UIUtils.genCellCache(questCell.objectiveCell)
        questCell.objectiveCellCache:Refresh(questShowData.objectiveShowDataList.Count, function(objectiveCell, objectiveLuaIdx)
            local objectiveIdx = CSIndex(objectiveLuaIdx)
            local objectiveShowData = questShowData.objectiveShowDataList[objectiveIdx]
            objectiveCell.questId = questShowData.questId
            objectiveCell.objectiveIdx = objectiveIdx
            self:_UpdateObjectiveCellDesc(objectiveCell, objectiveShowData)
            self:_UpdateObjectiveCellProgress(objectiveCell, objectiveShowData)
            self:_UpdateObjectiveCellDistance(objectiveCell, objectiveShowData)
            self:_UpdateObjectiveCellComplete(objectiveCell, objectiveShowData)
            if objectiveShowData.isCompleted then
                objectiveCell.animationWrapper:SampleClipAtPercent(self.view.config.OBJECTIVE_CELL_COMPLETE_CLIP_NAME, 1)
            else
                objectiveCell.animationWrapper:SampleClipAtPercent(self.view.config.OBJECTIVE_CELL_COMPLETE_CLIP_NAME, 0)
            end
        end)
        questCell.animationWrapper:SampleClipAtPercent(self.view.config.QUEST_CELL_NEW_CLIP_NAME, 1)
    end)
end
MissionHudCtrl._OnQuestObjectiveUpdate = HL.Method(HL.Any) << function(self, arg)
    local questId = unpack(arg)
    if self.m_cntAnimMissionShowData and self.m_cntAnimMissionShowData.noAnimTrackMission then
        local questCellCount = self.m_questCellCache:GetCount()
        for questIdx = 1, questCellCount do
            local questCell = self.m_questCellCache:GetItem(questIdx)
            local questInfo = self.m_missionSystem:GetQuestInfo(questCell.questId)
            local objectiveCellCount = questCell.objectiveCellCache:GetCount()
            for objectiveIdx = 1, objectiveCellCount do
                local objectiveCell = questCell.objectiveCellCache:GetItem(objectiveIdx)
                local objective = questInfo.objectiveList[objectiveCell.objectiveIdx]
                if objective.isShowProgress then
                    objectiveCell.progress.gameObject:SetActive(true)
                    if objective.isCompleted then
                        objectiveCell.progress.text = string.format("%d/%d", objective.progressToCompareForShow, objective.progressToCompareForShow)
                    else
                        objectiveCell.progress.text = string.format("%d/%d", objective.progressForShow, objective.progressToCompareForShow)
                    end
                else
                    objectiveCell.progress.gameObject:SetActive(false)
                end
            end
        end
    end
end
MissionHudCtrl._GetMissionShowDataAnimType = HL.Method(HL.Any).Return(HL.Number) << function(self, missionShowData)
    if missionShowData.animType == MissionAnimType.New then
        return MISSION_ANIM_TYPE.NewMission
    elseif missionShowData.animType == MissionAnimType.Complete then
        return MISSION_ANIM_TYPE.CompleteMission
    elseif missionShowData.animType == MissionAnimType.Track then
        return MISSION_ANIM_TYPE.Track
    end
    for _, questShowData in pairs(missionShowData.questShowDataList) do
        if questShowData.animType == QuestAnimType.New then
            return MISSION_ANIM_TYPE.NewQuest
        elseif questShowData.animType == QuestAnimType.Complete then
            return MISSION_ANIM_TYPE.CompleteQuest
        end
        for _, objectiveShowData in pairs(questShowData.objectiveShowDataList) do
            if objectiveShowData.animType == ObjectiveAnimType.Complete then
                return MISSION_ANIM_TYPE.CompleteObjective
            elseif objectiveShowData.animType == ObjectiveAnimType.Rollback then
                return MISSION_ANIM_TYPE.RollbackObjective
            end
        end
    end
    return MISSION_ANIM_TYPE.None
end
MissionHudCtrl._SkipAnimationAndTrackMission = HL.Method() << function(self)
    if self:_IsPlayingMissionAnim() then
        local missionShowData = self.m_missionSystem:GetFirstMissionShowData()
        if missionShowData then
            local animType = self:_GetMissionShowDataAnimType(missionShowData)
            if animType == MISSION_ANIM_TYPE.NewMission or animType == MISSION_ANIM_TYPE.NewQuest then
                self.m_cntAnimMissionShowData.skipAnimSignal = true
                local toBeTrackedMissionId = missionShowData.missionId or ""
                if not string.isEmpty(toBeTrackedMissionId) then
                    self.m_missionSystem:TrackMission(toBeTrackedMissionId)
                end
            end
        end
    else
        self:_TriggerTrack()
    end
end
MissionHudCtrl._TriggerTrack = HL.Method() << function(self)
    Notify(MessageConst.SHOW_MISSION_TRACKER)
    local trackMissionId = self.m_missionSystem:GetTrackMissionId()
    if not string.isEmpty(trackMissionId) then
        local displayQuestIds = self.m_missionSystem:GetDisplayQuestIdsByMissionId(trackMissionId)
        if displayQuestIds then
            for _, questId in pairs(displayQuestIds) do
                local questInfo = self.m_missionSystem:GetQuestInfo(questId)
                for _, objective in pairs(questInfo.objectiveList) do
                    local _, _, trackAction, trackDataIdxInMap = self.m_missionSystem:GetObjectiveDistanceTextForMissionHud(objective)
                    if trackAction == TrackAction.OpenMap then
                        MapUtils.openMapByMissionId(trackMissionId, trackDataIdxInMap)
                        break
                    elseif trackAction == TrackAction.Special then
                        self.m_missionSystem:SpecialTracking(objective)
                        break
                    end
                end
            end
        end
    end
end
MissionHudCtrl._ShowMissionHud = HL.Method(HL.Boolean) << function(self, isShow)
    self.view.main.gameObject:SetActiveIfNecessary(isShow)
end
MissionHudCtrl.OpenDebug = HL.Method() << function(self)
    self.view.tmp.gameObject:SetActive(true)
end
MissionHudCtrl.OnUpdateMissionInfo = HL.Method(HL.Any) << function(self, arg)
    self.view.missionInfoText.text = unpack(arg)
end
MissionHudCtrl.OnSyncAllMission = HL.Method() << function(self)
    self:_RefreshTrackMission()
end
MissionHudCtrl._RefreshTrackMission = HL.Method() << function(self)
    local trackMissionId = self.m_missionSystem.trackMissionId
    if not string.isEmpty(trackMissionId) then
        self.view.leftNode.gameObject:SetActive(true)
        local trackMissionShowData = self.m_missionSystem:GetMissionShowDataByMissionId(trackMissionId)
        trackMissionShowData.noAnimTrackMission = true
        self:_InitMissionShowData(trackMissionShowData)
    else
        self.m_cntAnimMissionShowData = nil
        self.view.leftNode.gameObject:SetActive(false)
    end
end
MissionHudCtrl._UpdateQuestCellComplete = HL.Method(HL.Any) << function(self, questCell)
    local questState = self.m_missionSystem:GetQuestState(questCell.questId)
    questCell.completeNode.gameObject:SetActive(questState == QuestState.Completed)
    questCell.processingNode.gameObject:SetActive(questState ~= QuestState.Completed)
end
MissionHudCtrl._UpdateObjectiveCellDistance = HL.Method(HL.Any, HL.Any) << function(self, objectiveCell, objectiveShowData)
    if not string.isEmpty(objectiveShowData.distanceText) then
        objectiveCell.distanceNode.gameObject:SetActive(true)
        objectiveCell.distance.text = objectiveShowData.distanceText
        objectiveCell.hotKeyIcon.gameObject:SetActive(objectiveShowData.needHotKeyIcon)
    else
        objectiveCell.distanceNode.gameObject:SetActive(false)
    end
end
MissionHudCtrl._UpdateAllObjectiveDistance = HL.Method() << function(self)
    if self:_IsPlayingMissionAnim() then
        return
    end
    if self.m_cntAnimMissionShowData then
        local trackMissionId = self.m_missionSystem.trackMissionId
        if self.m_cntAnimMissionShowData.missionId == trackMissionId then
            local hasHotKeyIcon = false
            local questCellCount = self.m_questCellCache:GetCount()
            for questIdx = 1, questCellCount do
                local questCell = self.m_questCellCache:GetItem(questIdx)
                local questInfo = self.m_missionSystem:GetQuestInfo(questCell.questId)
                local objectiveCellCount = questCell.objectiveCellCache:GetCount()
                for objLuaIdx = 1, objectiveCellCount do
                    local objectiveCell = questCell.objectiveCellCache:GetItem(objLuaIdx)
                    local objective = questInfo.objectiveList[CSIndex(objLuaIdx)]
                    local missionSystem = self.m_missionSystem
                    local objTextInfo = missionSystem:GetObjectiveDistanceTextForMissionHudWrap(objective)
                    local distanceText, needHotKeyIcon = objTextInfo.distanceText, objTextInfo.needHotKeyIcon
                    if hasHotKeyIcon then
                        needHotKeyIcon = false
                    end
                    if needHotKeyIcon then
                        hasHotKeyIcon = true
                    end
                    if not string.isEmpty(distanceText) then
                        objectiveCell.distanceNode.gameObject:SetActive(true)
                        objectiveCell.distance.text = distanceText
                        objectiveCell.hotKeyIcon.gameObject:SetActive(needHotKeyIcon)
                        if needHotKeyIcon then
                            hasHotKeyIcon = true
                        end
                    else
                        objectiveCell.distanceNode.gameObject:SetActive(false)
                    end
                end
            end
        end
    end
end
MissionHudCtrl._UpdateObjectiveCellDesc = HL.Method(HL.Any, HL.Any) << function(self, objectiveCell, objectiveShowData)
    local objectiveDesc
    if objectiveShowData.description.isEmpty then
        objectiveDesc = " "
    else
        objectiveDesc = objectiveShowData.description:GetText()
    end
    if objectiveShowData.optional then
        objectiveCell.desc.text = string.format("<color=#%s>%s</color> %s", OPTIONAL_TEXT_COLOR, Language.ui_optional_quest, UIUtils.resolveTextStyle(objectiveDesc))
    else
        objectiveCell.desc.text = UIUtils.resolveTextStyle(objectiveDesc)
    end
end
MissionHudCtrl._UpdateObjectiveCellProgress = HL.Method(HL.Any, HL.Any) << function(self, objectiveCell, objectiveShowData)
    if objectiveShowData.isShowProgress then
        objectiveCell.progress.gameObject:SetActive(true)
        objectiveCell.progress.text = string.format("%d/%d", objectiveShowData.progress, objectiveShowData.progressToCompare)
    else
        objectiveCell.progress.gameObject:SetActive(false)
    end
end
MissionHudCtrl._UpdateObjectiveCellComplete = HL.Method(HL.Any, HL.Any) << function(self, objectiveCell, objectiveShowData)
    if objectiveShowData.isCompleted then
        local clipName = self.view.config.OBJECTIVE_CELL_COMPLETE_CLIP_NAME
        objectiveCell.animationWrapper:SampleClipAtPercent(clipName, 1)
    else
        local clipName = self.view.config.OBJECTIVE_CELL_COMPLETE_CLIP_NAME
        objectiveCell.animationWrapper:SampleClipAtPercent(clipName, 0)
    end
end
MissionHudCtrl._GetObjectiveCellAnimInfo = HL.Method(HL.Number, HL.String, HL.Number).Return(HL.Table) << function(self, type, questId, objectiveCSIdx)
    local ret = {}
    local questCellCount = self.m_questCellCache:GetCount()
    for i = 1, questCellCount do
        local questCell = self.m_questCellCache:GetItem(i)
        if questCell.questId == questId then
            local objectiveCount = questCell.objectiveCellCache:GetCount()
            if objectiveCSIdx < objectiveCount then
                local objectiveCell = questCell.objectiveCellCache:GetItem(LuaIndex(objectiveCSIdx))
                ret.animWrapper = objectiveCell.animationWrapper
                if type == 0 then
                    ret.inClipName = self.view.config.OBJECTIVE_CELL_COMPLETE_CLIP_NAME
                else
                    ret.inClipName = self.view.config.OBJECTIVE_CELL_ROLLBACK_CLIP_NAME
                end
            end
            break
        end
    end
    return ret
end
MissionHudCtrl._GetQuestCellAnimInfo = HL.Method(HL.Number, HL.String).Return(HL.Table) << function(self, type, questId)
    local ret = {}
    local questCellCount = self.m_questCellCache:GetCount()
    for i = 1, questCellCount do
        local questCell = self.m_questCellCache:GetItem(i)
        if questCell.questId == questId then
            ret.animWrapper = questCell.animationWrapper
            if type == 0 then
                ret.inClipName = self.view.config.QUEST_CELL_NEW_CLIP_NAME
            else
                ret.inClipName = self.view.config.QUEST_CELL_COMPLETE_CLIP_NAME
            end
            break
        end
    end
    return ret
end
MissionHudCtrl._GetMissionNewAnimInfo = HL.Method(HL.String).Return(HL.Table) << function(self, missionId)
    local clipName = self.view.config.NEW_MISSION_CLIP_NAME
    local ret = {}
    ret.animWrapper = self:GetAnimationWrapper()
    ret.inClipName = clipName
    return ret
end
MissionHudCtrl._GetMissionCompleteAnimInfo = HL.Method(HL.String).Return(HL.Table) << function(self, missionId)
    local clipName = self.view.config.MISSION_COMPLETE_CLIP_NAME
    local ret = {}
    ret.animWrapper = self:GetAnimationWrapper()
    ret.inClipName = clipName
    return ret
end
MissionHudCtrl._GetMissionTrackAnimInfo = HL.Method().Return(HL.Table) << function(self)
    local inClipName = self.view.config.TRACK_MISSION_CLIP_NAME
    local outClipName = self.view.config.TRACK_MISSION_OUT_CLIP_NAME
    local ret = {}
    ret.animWrapper = self:GetAnimationWrapper()
    ret.inClipName = inClipName
    ret.outClipName = outClipName
    return ret
end
MissionHudCtrl._GetQuestCell = HL.Method(HL.String).Return(HL.Any) << function(self, questId)
    local questCellCount = self.m_questCellCache:GetCount()
    for i = 1, questCellCount do
        local questCell = self.m_questCellCache:GetItem(i)
        if questCell.questId == questId then
            return questCell
        end
    end
    return nil
end
MissionHudCtrl._GetObjectiveCell = HL.Method(HL.String, HL.Number).Return(HL.Any) << function(self, questId, objectiveIdx)
    local questCellCount = self.m_questCellCache:GetCount()
    for i = 1, questCellCount do
        local questCell = self.m_questCellCache:GetItem(i)
        if questCell.questId == questId then
            local objectiveCellCount = questCell.objectiveCellCache:GetCount()
            for j = 1, objectiveCellCount do
                local objectiveCell = questCell.objectiveCellCache:GetItem(j)
                if objectiveCell.objectiveIdx == objectiveIdx then
                    return objectiveCell
                end
            end
        end
    end
    return nil
end
MissionHudCtrl._RefreshOpenBtn = HL.Method() << function(self)
    local isMissionForbidden = PhaseManager:IsPhaseForbidden(PhaseId.Mission)
    local inCharDungeon = self.m_missionSystem:InCharDungeon()
    self.view.openMissionUI.gameObject:SetActive(not isMissionForbidden and not inCharDungeon)
    self.view.significantMarkRoot.gameObject:SetActive(not isMissionForbidden and not inCharDungeon)
end
MissionHudCtrl._OnGameModeChange = HL.Method(HL.Table) << function(self, evtData)
    self:_RefreshOpenBtn()
end
MissionHudCtrl._OnTrackingSns = HL.Method(HL.Any) << function(self, args)
    self:Notify(MessageConst.TRY_OPEN_PHASE_SNS, args)
end
MissionHudCtrl._OnFacToggleTopView = HL.Method(HL.Boolean) << function(self, isTopView)
    if isTopView then
        self.view.trackBtn.gameObject:GetComponent("NonDrawingGraphic").raycastTarget = false
    else
        self.view.trackBtn.gameObject:GetComponent("NonDrawingGraphic").raycastTarget = true
    end
end
MissionHudCtrl._OnMissionStateChange = HL.Method(HL.Any) << function(self, args)
    if not self.m_missionStateChangeSignal then
        self.m_missionStateChangeSignal = { time = Time.unscaledTime }
    end
end
MissionHudCtrl._OnTrackingToUI = HL.Method(HL.Any) << function(self, args)
    local jumpId = unpack(args)
    Utils.jumpToSystem(jumpId)
end
MissionHudCtrl.OnShow = HL.Override() << function(self)
end
MissionHudCtrl.OnHide = HL.Override() << function(self)
    self.view.significantMark.gameObject:SetActive(self.m_hasSignificantMission)
end
MissionHudCtrl.OnClose = HL.Override() << function(self)
    self.m_missionSystem:DisableMissionTrackData()
    if self.m_updateDistanceTimerHandler then
        LuaUpdate:Remove(self.m_updateDistanceTimerHandler)
        self.m_updateDistanceTimerHandler = nil
    end
end
HL.Commit(MissionHudCtrl)