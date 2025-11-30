local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
local MissionState = CS.Beyond.Gameplay.MissionSystem.MissionState
local MissionType = CS.Beyond.Gameplay.MissionSystem.MissionType
SNSContentTask = HL.Class('SNSContentTask', UIWidgetBase)
SNSContentTask._OnFirstTimeInit = HL.Override() << function(self)
end
SNSContentTask.InitSNSContentTask = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    if not args.loaded then
        self.view.animationWrapper:PlayInAnimation()
        AudioAdapter.PostEvent("Au_UI_Event_SNSContentEndLine_Open")
    end
    local missionId = args.missionId
    local missionInfo = GameInstance.player.mission:GetMissionInfo(missionId)
    self.view.mainText.text = missionInfo.missionName:GetText()
    local levelTableData = Tables.levelDescTable[missionInfo.levelId]
    local icon = UIConst.MISSION_TYPE_CONFIG[missionInfo.missionType].missionIcon
    self.view.subText.text = levelTableData.showName
    self.view.taskIcon:LoadSprite(UIConst.UI_SPRITE_MISSION_TYPE_ICON, icon)
    self.view.linkBtn.onClick:RemoveAllListeners()
    self.view.linkBtn.onClick:AddListener(function()
        local missionRuntimeAsset = GameInstance.player.mission:GetMissionInfo(missionId)
        local missionState = GameInstance.player.mission:GetMissionState(missionId)
        local otherCaseHintText = missionRuntimeAsset.missionType == MissionType.Misc and Language["ui_sns_toast_mission_misc_failed"] or Language["ui_mis_empty_default"]
        if missionState == MissionState.Processing then
            PhaseManager:OpenPhase(PhaseId.Mission, { autoSelect = missionId, useBlackMask = true })
        elseif missionState == MissionState.Completed then
            Notify(MessageConst.SHOW_TOAST, Language["ui_sns_toast_mission_completed"])
        else
            Notify(MessageConst.SHOW_TOAST, otherCaseHintText)
        end
    end)
end
HL.Commit(SNSContentTask)
return SNSContentTask