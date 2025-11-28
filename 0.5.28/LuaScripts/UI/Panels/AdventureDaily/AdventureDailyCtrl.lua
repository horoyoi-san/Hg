local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.AdventureDaily
AdventureDailyCtrl = HL.Class('AdventureDailyCtrl', uiCtrl.UICtrl)
AdventureDailyCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_ADVENTURE_TASK_MODIFY] = 'OnAdventureTaskModify', [MessageConst.ON_DAILY_ACTIVATION_MODIFY] = 'OnDailyActivationModify', [MessageConst.ON_RESET_DAILY_ADVENTURE_TASK] = 'Refresh', }
AdventureDailyCtrl.m_getTaskCell = HL.Field(HL.Function)
AdventureDailyCtrl.m_taskInfos = HL.Field(HL.Table)
AdventureDailyCtrl.m_isCurActivationMax = HL.Field(HL.Boolean) << false
AdventureDailyCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.getAllBtn.onClick:AddListener(function()
        self:_OnClickGetAllBtn()
    end)
    self.m_getTaskCell = UIUtils.genCachedCellFunction(self.view.taskList)
    self.view.taskList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateCell(self.m_getTaskCell(obj), LuaIndex(csIndex))
    end)
    self.view.rewardTips.gameObject:SetActive(false)
    self:_InitProgressNode()
    self:_RefreshTaskNode()
    self.view.countDownText:InitCountDownText(Utils.getNextCommonServerRefreshTime())
end
AdventureDailyCtrl.OnClose = HL.Override() << function(self)
    self.view.progressNode.progressBarImg:DOKill()
end
AdventureDailyCtrl.OnShow = HL.Override() << function(self)
    self.view.taskList:SetTop()
end
AdventureDailyCtrl.OnAdventureTaskModify = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    self:_RefreshTaskNode()
end
AdventureDailyCtrl.OnDailyActivationModify = HL.Method() << function(self)
    self:_RefreshProgressNode()
    self:_RefreshTaskNode()
end
AdventureDailyCtrl.Refresh = HL.Method() << function(self)
    self:_RefreshProgressNode()
    self:_RefreshTaskNode()
end
AdventureDailyCtrl.m_progressInfos = HL.Field(HL.Table)
AdventureDailyCtrl.m_maxActivation = HL.Field(HL.Number) << -1
AdventureDailyCtrl._InitProgressNode = HL.Method() << function(self)
    local node = self.view.progressNode
    local infos = {}
    for k, v in pairs(Tables.dailyActivationRewardTable) do
        table.insert(infos, { id = k, activation = v.activation, rewardId = v.rewardId, })
    end
    table.sort(infos, Utils.genSortFunction({ "id" }, true))
    self.m_progressInfos = infos
    self.m_maxActivation = infos[#infos].activation
    node.m_progressCells = UIUtils.genCellCache(node.progressCell)
    node.m_progressCells:Refresh(#self.m_progressInfos, function(cell, index)
        cell.hintBtn.onPressStart:AddListener(function()
            self:_OnClickProgressRewardHint(index)
        end)
    end)
    self:_RefreshProgressNode(true)
end
AdventureDailyCtrl._RefreshProgressNode = HL.Method(HL.Opt(HL.Boolean)) << function(self, isInit)
    local node = self.view.progressNode
    node.m_progressCells:Update(function(cell, index)
        self:_RefreshProgressCell(cell, index)
    end)
    local curDailyActivation = GameInstance.player.adventure.adventureBookData.dailyActivation
    local percent = curDailyActivation / self.m_maxActivation
    if isInit then
        node.progressBarImg.fillAmount = percent
    else
        node.progressBarImg:DOFillAmount(percent, 0.3)
    end
    node.progressTxt.text = curDailyActivation
end
AdventureDailyCtrl._RefreshProgressCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local info = self.m_progressInfos[index]
    local curDailyActivation = GameInstance.player.adventure.adventureBookData.dailyActivation
    local isRewarded = curDailyActivation >= info.activation
    cell.txt.text = info.activation
    cell.simpleStateController:SetState(isRewarded and "Rewarded" or "Normal")
end
AdventureDailyCtrl.m_curShowingRewardHintIndex = HL.Field(HL.Number) << -1
AdventureDailyCtrl._OnClickProgressRewardHint = HL.Method(HL.Number) << function(self, index)
    local node = self.view.rewardTips
    local preCell = self.view.progressNode.m_progressCells:Get(self.m_curShowingRewardHintIndex)
    if preCell then
        preCell.lightCircle.gameObject:SetActive(false)
    end
    if node.gameObject.activeSelf and self.m_curShowingRewardHintIndex == index then
        node.gameObject:SetActive(false)
        return
    end
    self.m_curShowingRewardHintIndex = index
    local info = self.m_progressInfos[index]
    local cell = self.view.progressNode.m_progressCells:Get(index)
    local curDailyActivation = GameInstance.player.adventure.adventureBookData.dailyActivation
    cell.lightCircle.gameObject:SetActive(true)
    node.rewardItems:InitRewardItems(info.rewardId, curDailyActivation >= info.activation)
    node.txt.text = string.format(Language.LUA_ADV_DAILY_REWARD_HINT, info.activation)
    node.autoCloseArea.tmpSafeArea = cell.hintBtn.transform
    node.autoCloseArea.onTriggerAutoClose:RemoveAllListeners()
    node.autoCloseArea.onTriggerAutoClose:AddListener(function()
        cell.lightCircle.gameObject:SetActive(false)
    end)
    node.gameObject:SetActive(true)
    UIUtils.updateTipsPosition(node.transform, cell.hintBtn.transform, self.view.rectTransform, self.uiCamera, UIConst.UI_TIPS_POS_TYPE.RightMid)
end
AdventureDailyCtrl._RefreshTaskNode = HL.Method() << function(self)
    local taskDic = GameInstance.player.adventure.adventureBookData.adventureTasks
    self.m_taskInfos = {}
    local completeCount = 0
    for k, v in pairs(Tables.adventureTaskTable) do
        if v.taskType == GEnums.AdventureTaskType.Daily then
            local info = { id = k, data = v, sortId = v.sortId, csTask = taskDic:get_Item(k), }
            if info.csTask.isRewarded then
                info.stateOrder = -1
            elseif info.csTask.isComplete then
                info.stateOrder = 1
                completeCount = completeCount + 1
            else
                info.stateOrder = 0
            end
            table.insert(self.m_taskInfos, info)
        end
    end
    table.sort(self.m_taskInfos, Utils.genSortFunction({ "stateOrder", "sortId" }))
    local curActivation = GameInstance.player.adventure.adventureBookData.dailyActivation
    self.m_isCurActivationMax = curActivation >= self.m_maxActivation
    self.view.taskList:UpdateCount(#self.m_taskInfos)
    local showGetAll = completeCount > 0 and not self.m_isCurActivationMax
    self.view.getAllNode.gameObject:SetActive(showGetAll)
end
AdventureDailyCtrl._OnUpdateCell = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local info = self.m_taskInfos[index]
    cell.desc.text = info.data.taskDesc
    local itemBundle = UIUtils.getRewardFirstItem(info.data.rewardId)
    cell.rewardTxt.text = itemBundle.count
    cell.progressTxt.text = string.format("%d/%d", info.csTask.progress, info.csTask.targetProgress)
    cell.progressImg.fillAmount = info.csTask.progress / info.csTask.targetProgress
    cell.getBtn.onClick:RemoveAllListeners()
    cell.gotoBtn.onClick:RemoveAllListeners()
    if self.m_isCurActivationMax then
        cell.stateNode:PlayWithTween("adv_daily_task_max")
    elseif info.csTask.isRewarded then
        cell.stateNode:PlayWithTween("adv_daily_task_rewarded")
    elseif info.csTask.isComplete then
        cell.stateNode:PlayWithTween("adv_daily_task_can_get")
        cell.getBtn.onClick:AddListener(function()
            self:_OnClickGetBtn(index)
        end)
    else
        cell.stateNode:PlayWithTween("adv_daily_task_normal")
        if not string.isEmpty(info.data.jumpSystemId) then
            cell.gotoBtn.gameObject:SetActive(true)
            cell.unfinishHint.gameObject:SetActive(false)
            cell.gotoBtn.onClick:AddListener(function()
                Utils.jumpToSystem(info.data.jumpSystemId)
            end)
        else
            cell.gotoBtn.gameObject:SetActive(false)
            cell.unfinishHint.gameObject:SetActive(true)
        end
    end
    cell.cellAniWrapper:PlayWithTween("adventuredailytaskcell_in")
end
AdventureDailyCtrl._OnClickGetBtn = HL.Method(HL.Number) << function(self, index)
    local info = self.m_taskInfos[index]
    GameInstance.player.adventure:TakeAdventureTaskReward(info.id)
end
AdventureDailyCtrl._OnClickGetAllBtn = HL.Method() << function(self)
    GameInstance.player.adventure:TakeAdventureAllTaskRewardOfType(GEnums.AdventureTaskType.Daily)
end
HL.Commit(AdventureDailyCtrl)