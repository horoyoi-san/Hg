local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
AdventureTaskCell = HL.Class('AdventureTaskCell', UIWidgetBase)
AdventureTaskCell.m_itemRewardCellCache = HL.Field(HL.Forward("UIListCache"))
AdventureTaskCell.m_taskId = HL.Field(HL.String) << ""
AdventureTaskCell._OnFirstTimeInit = HL.Override() << function(self)
    self.m_itemRewardCellCache = UIUtils.genCellCache(self.view.itemSmallReward)
    self.view.finished.getTaskReward.onClick:AddListener(function()
        GameInstance.player.adventure:TakeAdventureTaskReward(self.m_taskId)
    end)
end
AdventureTaskCell.InitAdventureTaskCell = HL.Method(HL.Table) << function(self, info)
    self:_FirstTimeInit()
    self.m_taskId = info.taskId
    local isNormal = not info.isComplete and not info.isRewarded
    local isFinish = info.isComplete
    local isRewarded = info.isRewarded
    self.view.normal.gameObject:SetActiveIfNecessary(isNormal)
    self.view.finished.gameObject:SetActiveIfNecessary(isFinish)
    self.view.rewarded.gameObject:SetActiveIfNecessary(isRewarded)
    self.view.bgn.gameObject:SetActiveIfNecessary(isNormal)
    self.view.bgf.gameObject:SetActiveIfNecessary(isFinish)
    self.view.bgr.gameObject:SetActiveIfNecessary(isRewarded)
    local taskCfg = Tables.AdventureTaskTable[info.taskId]
    local rewardId = taskCfg.rewardId
    local rewardData = Tables.rewardTable[rewardId]
    local adventure = GameInstance.player.adventure
    local rewards = {}
    for _, itemBundle in pairs(rewardData.itemBundles) do
        local cfg = Utils.tryGetTableCfg(Tables.itemTable, itemBundle.id)
        if cfg then
            table.insert(rewards, { id = itemBundle.id, count = itemBundle.count, rarity = -cfg.rarity, sortId1 = cfg.sortId1, sortId2 = cfg.sortId2, })
        end
    end
    table.sort(rewards, Utils.genSortFunction({ "rarity", "sortId1", "sortId2", "id" }, true))
    self.m_itemRewardCellCache:Refresh(#rewards, function(cell, luaIndex)
        cell.view.rewardedCover.gameObject:SetActiveIfNecessary(isRewarded)
        cell:InitItem(rewards[luaIndex], true)
    end)
    local node
    if info.isRewarded then
        node = self.view.rewarded
    elseif info.isComplete then
        node = self.view.finished
    else
        node = self.view.normal
    end
    local taskData = Tables.adventureTaskTable[info.taskId]
    local taskProgress = adventure:GetTaskProgress(info.taskId)
    local isCompleted = adventure:IsTaskComplete(info.taskId)
    local curProgress = (isRewarded or isCompleted) and taskData.progressToCompare or taskProgress
    node.text.text = string.format("%d/%d", curProgress, taskData.progressToCompare)
    node.taskDesc.text = taskData.taskDesc
    if isNormal then
        if string.isEmpty(taskCfg.jumpSystemId) then
            self.view.normal.jumpState:SetState("CanNotJump")
        else
            local jumpId = taskCfg.jumpSystemId
            self.view.normal.jumpState:SetState("CanJump")
            self.view.normal.jumpBtn.onClick:RemoveAllListeners()
            self.view.normal.jumpBtn.onClick:AddListener(function()
                Utils.jumpToSystem(jumpId)
            end)
        end
    end
end
HL.Commit(AdventureTaskCell)
return AdventureTaskCell