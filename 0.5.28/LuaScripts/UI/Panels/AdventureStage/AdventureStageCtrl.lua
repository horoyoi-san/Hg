local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.AdventureStage
AdventureStageCtrl = HL.Class('AdventureStageCtrl', uiCtrl.UICtrl)
AdventureStageCtrl.m_curAdventureStage = HL.Field(HL.Number) << -1
AdventureStageCtrl.m_adventureMaxStage = HL.Field(HL.Number) << -1
AdventureStageCtrl.m_curAdventureStageTaskInfos = HL.Field(HL.Table)
AdventureStageCtrl.m_getTaskCellFunc = HL.Field(HL.Function)
AdventureStageCtrl.m_adventureStageRewardCellCache = HL.Field(HL.Forward("UIListCache"))
AdventureStageCtrl.m_genTaskCell = HL.Field(HL.Forward("UIListCache"))
AdventureStageCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_ADVENTURE_TASK_MODIFY] = 'OnAdventureTaskModify', [MessageConst.ON_ADVENTURE_BOOK_STAGE_MODIFY] = 'OnAdventureBookStageModify', }
AdventureStageCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local adventure = self.view
    adventure.incBtn.onClick:AddListener(function()
        self:_OnIncBtnClick()
    end)
    adventure.decBtn.onClick:AddListener(function()
        self:_OnDecBtnClick()
    end)
    adventure.getStageReward.onClick:AddListener(function()
        self:_OnGetStageRewardBtnClick()
    end)
    self.m_adventureStageRewardCellCache = UIUtils.genCellCache(adventure.itemReward)
    self.m_genTaskCell = UIUtils.genCellCache(adventure.adventureTaskCell)
    self:_ManualAdaptationTaskGroupCellSize()
    self:_ManualAdaptationOverviewProgSize()
    self:_ResetAdventureStage()
    self:_RefreshAdventurePage()
end
AdventureStageCtrl._OnIncBtnClick = HL.Method() << function(self)
    self.m_curAdventureStage = self.m_curAdventureStage + 1
    self.view.stageTxt2.text = self.m_curAdventureStage
    self:_RefreshAdventurePage()
end
AdventureStageCtrl._OnDecBtnClick = HL.Method() << function(self)
    self.m_curAdventureStage = self.m_curAdventureStage - 1
    self.view.stageTxt2.text = self.m_curAdventureStage
    self:_RefreshAdventurePage()
end
AdventureStageCtrl._OnGetStageRewardBtnClick = HL.Method() << function(self)
    GameInstance.player.adventure:TakeAdventureBookStageReward(self.m_curAdventureStage)
end
AdventureStageCtrl._ResetAdventureStage = HL.Method() << function(self)
    local adventureBookData = GameInstance.player.adventure.adventureBookData
    self.m_curAdventureStage = adventureBookData.adventureBookStage
    self.m_adventureMaxStage = adventureBookData.adventureBookStage
    self.view.stageTxt2.text = self.m_curAdventureStage
end
AdventureStageCtrl._RefreshAdventurePage = HL.Method() << function(self)
    self:_RefreshBtnState()
    self:_RefreshAdventureStageOverview()
    self:_RefreshAdventureStageTask()
end
AdventureStageCtrl._RefreshBtnState = HL.Method() << function(self)
    local adventure = self.view
    adventure.incBtn.interactable = self.m_curAdventureStage < self.m_adventureMaxStage
    adventure.decBtn.interactable = self.m_curAdventureStage > 1
end
AdventureStageCtrl._RefreshAdventureStageOverview = HL.Method() << function(self)
    local rewardId = Tables.adventureBookStageRewardTable[self.m_curAdventureStage].rewardId
    local rewardData = Tables.rewardTable[rewardId]
    local adventureBookData = GameInstance.player.adventure.adventureBookData
    local isActualStage = self.m_curAdventureStage == adventureBookData.actualBookStage
    local isComplete = adventureBookData.isCurAdventureBookStateComplete
    local rewards = {}
    for _, itemBundle in pairs(rewardData.itemBundles) do
        local cfg = Utils.tryGetTableCfg(Tables.itemTable, itemBundle.id)
        if cfg then
            table.insert(rewards, { id = itemBundle.id, count = itemBundle.count, rarity = -cfg.rarity, sortId1 = cfg.sortId1, sortId2 = cfg.sortId2, })
        end
    end
    table.sort(rewards, Utils.genSortFunction({ "rarity", "sortId1", "sortId2", "id" }, true))
    self.m_adventureStageRewardCellCache:Refresh(#rewards, function(cell, luaIndex)
        cell.view.rewardedCover.gameObject:SetActiveIfNecessary(not isActualStage)
        cell:InitItem(rewards[luaIndex], true)
    end)
    local adventure = self.view
    adventure.stageProgress.gameObject:SetActiveIfNecessary(isActualStage and not isComplete)
    adventure.stageComplete.gameObject:SetActiveIfNecessary(isActualStage and isComplete)
    adventure.stageCompleteBg.gameObject:SetActiveIfNecessary(isActualStage and isComplete)
    adventure.stageRewarded.gameObject:SetActiveIfNecessary(not isActualStage)
    if isActualStage and not isComplete then
        local curCount = adventureBookData.curStageCurProgress
        local targetCount = adventureBookData.curStageTargetProgress
        adventure.progressTxt.text = string.format(Language.LUA_ADVENTURE_REWARD_EXP_PROGRESS_FORMAT, curCount, targetCount)
        self:_RefreshOverviewProg(curCount / targetCount)
    end
end
AdventureStageCtrl._OnUpdateTaskCell = HL.Method(GameObject, HL.Number) << function(self, gameObject, csIndex)
    local cell = self.m_getTaskCellFunc(gameObject)
    local info = self.m_curAdventureStageTaskInfos[LuaIndex(csIndex)]
    cell:InitAdventureTaskCell(info)
end
AdventureStageCtrl._RefreshAdventureStageTask = HL.Method() << function(self)
    local taskIds = Tables.adventureBookStageRewardTable[self.m_curAdventureStage].taskIds
    local adventure = GameInstance.player.adventure
    local taskInfos = {}
    for _, taskId in pairs(taskIds) do
        local taskInfo = {}
        local isComplete = adventure:IsTaskComplete(taskId)
        local isRewarded = adventure:IsTaskRewarded(taskId)
        taskInfo.taskId = taskId
        taskInfo.isComplete = isComplete
        taskInfo.isRewarded = isRewarded
        taskInfo.completeSortId = isComplete and 0 or 1
        taskInfo.rewardSortId = isRewarded and 1 or 0
        table.insert(taskInfos, taskInfo)
    end
    table.sort(taskInfos, Utils.genSortFunction({ "rewardSortId", "completeSortId" }, true))
    self.m_curAdventureStageTaskInfos = taskInfos
    self.m_genTaskCell:Refresh(#taskInfos, function(cell, luaIndex)
        local info = self.m_curAdventureStageTaskInfos[luaIndex]
        cell:InitAdventureTaskCell(info)
    end)
end
AdventureStageCtrl.OnAdventureTaskModify = HL.Method(HL.Any) << function(self, args)
    local rewardedTaskIds = unpack(args)
    local rewardedIds = {}
    for _, rewardedTaskId in pairs(rewardedTaskIds) do
        local taskData = Tables.AdventureTaskTable[rewardedTaskId]
        if taskData.taskType ~= GEnums.AdventureTaskType.AdventureBook then
            return
        end
        table.insert(rewardedIds, taskData.rewardId)
    end
    self:_ShowRewardPopup(Language.LUA_ADVENTURE_BOOK_TASK_REWARD_TITLE_DESC, rewardedIds)
    self:_RefreshAdventureStageOverview()
    self:_RefreshAdventureStageTask()
end
AdventureStageCtrl.OnAdventureBookStageModify = HL.Method(HL.Any) << function(self, args)
    local preBookStage = unpack(args)
    local bookStageData = Tables.adventureBookStageRewardTable[preBookStage]
    self:_ShowRewardPopup(Language.LUA_ADVENTURE_BOOK_STAGE_REWARD_TITLE_DESC, { bookStageData.rewardId })
    local adventureBookData = GameInstance.player.adventure.adventureBookData
    self.m_curAdventureStage = adventureBookData.adventureBookStage
    self.m_adventureMaxStage = adventureBookData.adventureBookStage
    self.view.stageTxt2.text = self.m_curAdventureStage
    self:_RefreshAdventurePage()
end
AdventureStageCtrl._ShowRewardPopup = HL.Method(HL.String, HL.Table) << function(self, title, rewardedIds)
    if #rewardedIds < 1 then
        return
    end
    local rewardData = Tables.RewardTable[rewardedIds[1]]
    Notify(MessageConst.SHOW_SYSTEM_REWARDS, { title = title, items = rewardData.itemBundles, })
end
AdventureStageCtrl._ManualAdaptationTaskGroupCellSize = HL.Method() << function(self)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.rootLayout)
    local taskGroup = self.view.taskGroup
    local groupRectTrans = taskGroup.transform:RectTransform()
    local spacing = taskGroup.spacing
    local rowNum = self.view.config.TASK_GROUP_ROW_NUM
    local colNum = self.view.config.TASK_GROUP_COL_NUM
    local groupSize = groupRectTrans.rect.size
    local width = (groupSize.x - (colNum - 1) * spacing.x) / colNum
    local height = (groupSize.y - (rowNum - 1) * spacing.y) / rowNum
    taskGroup.cellSize = Vector2(width, height)
end
AdventureStageCtrl._ManualAdaptationOverviewProgSize = HL.Method() << function(self)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.sliderRoot)
    local sliderRectTrans = self.view.slider.transform:RectTransform()
    local sliderBGRectTrans = self.view.sliderBG
    local sliderMaskRectTrans = self.view.sliderMask
    local sliderWidth = sliderBGRectTrans.rect.width
    sliderRectTrans:SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, sliderWidth)
    sliderMaskRectTrans:SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, sliderWidth)
end
AdventureStageCtrl._RefreshOverviewProg = HL.Method(HL.Number) << function(self, progress)
    local sliderMaskRectTrans = self.view.sliderMask
    local sliderRectTrans = self.view.sliderBG
    local sliderWidth = sliderRectTrans.rect.width * progress
    sliderMaskRectTrans:SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, sliderWidth)
end
HL.Commit(AdventureStageCtrl)