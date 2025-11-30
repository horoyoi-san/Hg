LOGIN_CHECK_STEP_RESULT = { Continue = 1, Stop = 2, BackToStart = 3, BackToCurrent = 4, }
LoginCheckConflictConfigKey = { BLACK_SCREEN = "blackScreen", NARRATIVE = "narrative", BLOCK_MSG = "blockMsg" }
LoginCheckConflictCheckFunc = {
    [LoginCheckConflictConfigKey.BLACK_SCREEN] = function()
        return NarrativeUtils.inBlackScreen
    end,
    [LoginCheckConflictConfigKey.NARRATIVE] = function()
        return NarrativeUtils.isInCommonNarrative
    end,
    [LoginCheckConflictConfigKey.BLOCK_MSG] = function()
        return UIManager:IsShow(PanelId.TransparentBlockInput)
    end
}
LOGIN_CHECK_STEP_KEY = { CHECK_IN = "CheckIn", FORCE_SNS = "ForceSns", GUIDE = "Guide" }
LOGIN_CHECK_STEP_CONFIG = {
    {
        key = LOGIN_CHECK_STEP_KEY.CHECK_IN,
        checkFunction = function(callback)
            if not PhaseManager:IsPhaseUnlocked(PhaseId.CheckIn) then
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
                return
            end
            local hasReward = RedDotUtils.hasCheckInRewardsNotCollected()
            if hasReward then
                local args = {
                    closeCallback = function()
                        callback(LOGIN_CHECK_STEP_RESULT.Continue)
                    end
                }
                PhaseManager:OpenPhaseFast(PhaseId.CheckIn, args)
            else
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
            end
        end,
        interruptConfig = { [LoginCheckConflictConfigKey.BLACK_SCREEN] = true, [LoginCheckConflictConfigKey.NARRATIVE] = true, [LoginCheckConflictConfigKey.BLOCK_MSG] = true },
        waitConfig = { [LoginCheckConflictConfigKey.BLACK_SCREEN] = true, [LoginCheckConflictConfigKey.NARRATIVE] = true, [LoginCheckConflictConfigKey.BLOCK_MSG] = true }
    },
    {
        key = LOGIN_CHECK_STEP_KEY.FORCE_SNS,
        checkFunction = function(callback)
            local sns = GameInstance.player.sns
            local findForceDialog = sns:TryCheckAndStartSNSForceDialog()
            if findForceDialog then
                sns:BindOnCompleteAction(function()
                    callback(LOGIN_CHECK_STEP_RESULT.Continue)
                    sns:UnBindCompleteAction()
                end)
            else
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
            end
        end
    },
    {
        key = LOGIN_CHECK_STEP_KEY.GUIDE,
        checkFunction = function(callback)
            local guideSystem = GameInstance.player.guide
            local findGuideGroup = guideSystem:TryCheckAndStartGuideGroup()
            if findGuideGroup then
                guideSystem:BindOnCompleteAction(function()
                    callback(LOGIN_CHECK_STEP_RESULT.Stop)
                    guideSystem:UnBindOnCompleteAction()
                end)
            else
                callback(LOGIN_CHECK_STEP_RESULT.Continue)
            end
        end
    },
}