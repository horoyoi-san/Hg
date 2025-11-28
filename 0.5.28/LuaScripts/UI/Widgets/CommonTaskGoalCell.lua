local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
local TaskState = { None = 0, Normal = 1, Finish = 2, Fail = 3, }
local TRACK_GOAL_CELL_ANIM_DEFAULT = "tasktrackhud_celldefault"
local TRACK_GOAL_CELL_ANIM_FAIL = "tasktrackhud_cellfail"
local TRACK_GOAL_CELL_ANIM_FINISH = "tasktrackhud_cellfinish"
local TRACK_GOAL_CELL_ANIM_UPDATE = "tasktrackhud_cellupdate"
CommonTaskGoalCell = HL.Class('CommonTaskGoalCell', UIWidgetBase)
CommonTaskGoalCell.m_index = HL.Field(HL.Number) << -1
CommonTaskGoalCell.m_taskState = HL.Field(HL.Number) << TaskState.None
CommonTaskGoalCell.m_anim = HL.Field(HL.Any)
CommonTaskGoalCell.m_taskType = HL.Field(CS.Beyond.Gameplay.LevelScriptTaskType)
CommonTaskGoalCell.m_taskTracking = HL.Field(CS.Beyond.Gameplay.Core.LevelScriptTaskTracking)
CommonTaskGoalCell.m_taskTrackingObjective = HL.Field(CS.Beyond.Gameplay.Core.LevelScriptTaskTracking.Objective)
CommonTaskGoalCell.m_commonTrackingPointSystem = HL.Field(CS.Beyond.Gameplay.CommonTrackingPointSystem)
CommonTaskGoalCell.m_taskTrackPointId = HL.Field(HL.String) << ""
CommonTaskGoalCell.m_updateDistanceTick = HL.Field(HL.Number) << -1
CommonTaskGoalCell._OnFirstTimeInit = HL.Override() << function(self)
    self:RegisterMessage(MessageConst.ON_TASK_OBJECTIVE_PROGRESS_CHANGE, function(args)
        self:OnGoalProgressChange(args)
    end)
    self.m_anim = self.view.animation
    self.m_commonTrackingPointSystem = GameInstance.player.commonTrackingPoint
end
CommonTaskGoalCell._OnDestroy = HL.Override() << function(self)
    if self.m_updateDistanceTick > 0 then
        self.m_updateDistanceTick = LuaUpdate:Remove(self.m_updateDistanceTick)
    end
end
CommonTaskGoalCell.InitCommonTaskGoalCell = HL.Method(HL.Number, CS.Beyond.Gameplay.LevelScriptTaskType) << function(self, index, taskType)
    self:_FirstTimeInit()
    self.m_taskType = taskType
    self.m_index = index
    local trackingMgr = GameInstance.world.levelScriptTaskTrackingManager
    local trackingTask = trackingMgr:GetTaskByType(self.m_taskType)
    local csIndex = CSIndex(index)
    local objective = trackingTask.objectives[csIndex]
    local objectiveRaw = trackingTask.objectivesRaw[csIndex]
    self.m_taskTracking = trackingTask
    self.m_taskTrackingObjective = objective
    self.m_taskTrackPointId = objectiveRaw.trackingPointId
    local hasTrackPoint = not string.isEmpty(self.m_taskTrackPointId)
    if self.view.distanceNode then
        self.view.distanceNode.gameObject:SetActiveIfNecessary(hasTrackPoint)
    end
    if hasTrackPoint then
        self.m_updateDistanceTick = LuaUpdate:Add("TailTick", function()
            self:_UpdateDistance()
        end, true)
    end
    self:_Refresh(true)
end
CommonTaskGoalCell.OnGoalProgressChange = HL.Method(HL.Any) << function(self, args)
    local taskType, csIndex = unpack(args)
    if self.m_taskType ~= taskType or self.m_index ~= LuaIndex(csIndex) then
        return
    end
    self:_Refresh(false)
end
CommonTaskGoalCell.TrySetStateFail = HL.Method() << function(self)
    if self.m_taskState ~= TaskState.Finish then
        self:_CustomPlayAnimation(TRACK_GOAL_CELL_ANIM_FAIL)
    end
end
CommonTaskGoalCell._Refresh = HL.Method(HL.Boolean) << function(self, isInit)
    if not self.m_taskTrackingObjective then
        return
    end
    if isInit then
        self.m_anim:SampleClipAtPercent(TRACK_GOAL_CELL_ANIM_DEFAULT, 1)
    end
    local isCompleted = self.m_taskTrackingObjective.isCompleted
    self.view.finishedIcon.gameObject:SetActiveIfNecessary(isCompleted)
    self.view.unfinishedIcon.gameObject:SetActiveIfNecessary(not isCompleted)
    local preState = self.m_taskState
    self.m_taskState = isCompleted and TaskState.Finish or TaskState.Normal
    if self.m_taskState == TaskState.Finish and preState ~= TaskState.Finish then
        AudioAdapter.PostEvent("Au_UI_Mission_Step_Complete")
        self:_CustomPlayAnimation(TRACK_GOAL_CELL_ANIM_FINISH)
    elseif self.m_taskState == TaskState.Normal and preState ~= TaskState.Normal then
        self.m_anim:Play(TRACK_GOAL_CELL_ANIM_DEFAULT)
    elseif not isInit and not isCompleted then
        self.m_anim:Play(TRACK_GOAL_CELL_ANIM_UPDATE)
    end
    local success, descText, progressText = self.m_taskTracking:TryGetValueObjectiveDescription(self.m_taskTrackingObjective)
    if success then
        self.view.goalTxt.text = UIUtils.resolveTextStyle(descText)
        self.view.progressTxt.text = UIUtils.resolveTextStyle(progressText)
    else
        self.view.goalTxt.text = ""
        self.view.progressTxt.text = ""
    end
end
CommonTaskGoalCell._UpdateDistance = HL.Method() << function(self)
    local succ, isOutGuidingArea, distance = self.m_commonTrackingPointSystem:GetTrackingPointInfo(self.m_taskTrackPointId)
    self.view.distanceTxt.text = isOutGuidingArea and string.format("%.0fM", distance) or Language.IN_OBJECTIVE_AREA_TIPS
    self.view.distanceNode.gameObject:SetActiveIfNecessary(succ)
end
CommonTaskGoalCell._CustomPlayAnimation = HL.Method(HL.String) << function(self, anim)
    local succ, ctrl = UIManager:IsOpen(PanelId.CommonTaskTrackHud)
    if succ then
        ctrl.taskGoalShowing = true
    end
    self.m_anim:Play(anim, function()
        if succ then
            ctrl.taskGoalShowing = false
        end
    end)
end
HL.Commit(CommonTaskGoalCell)
return CommonTaskGoalCell