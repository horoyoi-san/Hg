local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingDungeonAchieveReward
RacingDungeonAchieveRewardCtrl = HL.Class('RacingDungeonAchieveRewardCtrl', uiCtrl.UICtrl)
RacingDungeonAchieveRewardCtrl.m_rewardListCache = HL.Field(HL.Table)
RacingDungeonAchieveRewardCtrl.m_dataList = HL.Field(HL.Table)
RacingDungeonAchieveRewardCtrl.m_getCell = HL.Field(HL.Function)
RacingDungeonAchieveRewardCtrl.m_racingDungeonSystem = HL.Field(HL.Any)
RacingDungeonAchieveRewardCtrl.m_waitAnimation = HL.Field(HL.Boolean) << false
RacingDungeonAchieveRewardCtrl.m_dungeon = HL.Field(HL.String) << ''
RacingDungeonAchieveRewardCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_RACING_DUNGEON_GET_ACHIEVE_REWARD] = 'OnGetReward', }
RacingDungeonAchieveRewardCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.allGetButton.onClick:AddListener(function()
        self.m_racingDungeonSystem:ReqGetAchieveReward(self.m_dungeon, -1)
    end)
    self.view.btnBack.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.m_dungeon = arg.dungeon
    self.m_racingDungeonSystem = GameInstance.player.racingDungeonSystem
    self.m_dataList = {}
    self.m_rewardListCache = {}
    self.m_getCell = UIUtils.genCachedCellFunction(self.view.scrollView)
    for k, v in pairs(Tables.racingAchievementTable) do
        local data = { achievementId = k, conditionDesc = v.list[0].conditionDesc, rewardId = v.list[0].rewardId, }
        table.insert(self.m_dataList, data)
    end
    self.view.scrollView.onUpdateCell:AddListener(function(cell, index)
        self:_UpdateCell(cell, index)
    end)
    self:UpdateView()
end
RacingDungeonAchieveRewardCtrl.UpdateViewForReward = HL.Method() << function(self)
    if self.m_waitAnimation then
        self:_StartTimer(1, function()
            self:UpdateView()
        end)
    else
        self:UpdateView()
    end
end
RacingDungeonAchieveRewardCtrl.UpdateView = HL.Method() << function(self)
    table.sort(self.m_dataList, function(a, b)
        local stateA = self.m_racingDungeonSystem:GetAchieveState(self.m_dungeon, a.achievementId)
        local stateB = self.m_racingDungeonSystem:GetAchieveState(self.m_dungeon, b.achievementId)
        if stateA == stateB then
            return a.achievementId < b.achievementId
        else
            if stateA == CS.Proto.RACING_ACHIEVEMENT_STATUS.RacingStatusCompleted then
                return true
            end
            if stateB == CS.Proto.RACING_ACHIEVEMENT_STATUS.RacingStatusCompleted then
                return false
            end
            if stateA == CS.Proto.RACING_ACHIEVEMENT_STATUS.RacingStatusReceived then
                return false
            end
            if stateB == CS.Proto.RACING_ACHIEVEMENT_STATUS.RacingStatusReceived then
                return true
            end
        end
    end)
    local activeNumber = 0
    local haveReward = false
    for k, v in pairs(self.m_dataList) do
        local state = self.m_racingDungeonSystem:GetAchieveState(self.m_dungeon, v.achievementId)
        if state == CS.Proto.RACING_ACHIEVEMENT_STATUS.RacingStatusCompleted or state == CS.Proto.RACING_ACHIEVEMENT_STATUS.RacingStatusReceived then
            activeNumber = activeNumber + 1
        end
        if state == CS.Proto.RACING_ACHIEVEMENT_STATUS.RacingStatusCompleted then
            haveReward = true
        end
    end
    self.view.scrollView:UpdateCount(#self.m_dataList)
    self.view.acieveNumber1.text = activeNumber
    self.view.acieveNumber2.text = #self.m_dataList
    self.view.allGetButton.gameObject:SetActive(haveReward)
end
RacingDungeonAchieveRewardCtrl.OnGetReward = HL.Method(HL.Any) << function(self, arg)
    local arg = unpack(arg)
    local items = {}
    for i = 0, arg.Count - 1 do
        local nodeId = arg[i].NodeId
        for k, v in pairs(self.m_dataList) do
            if v.achievementId == nodeId then
                local rewardData = Tables.rewardTable[v.rewardId]
                for j = 0, rewardData.itemBundles.Count - 1 do
                    if items[rewardData.itemBundles[j].id] then
                        items[rewardData.itemBundles[j].id].count = items[rewardData.itemBundles[j].id].count + rewardData.itemBundles[j].count
                    else
                        items[rewardData.itemBundles[j].id] = { id = rewardData.itemBundles[j].id, count = rewardData.itemBundles[j].count }
                    end
                end
            end
        end
    end
    local itemsList = {}
    for k, v in pairs(items) do
        table.insert(itemsList, v)
    end
    Notify(MessageConst.SHOW_SYSTEM_REWARDS, { icon = "icon_common_rewards", items = itemsList, })
    self:UpdateView()
end
RacingDungeonAchieveRewardCtrl._UpdateCell = HL.Method(GameObject, HL.Number) << function(self, cell, index)
    local index = LuaIndex(index)
    local data = self.m_dataList[index]
    local state = self.m_racingDungeonSystem:GetAchieveState(self.m_dungeon, data.achievementId)
    cell = self.m_getCell(cell)
    cell.inPogress.gameObject:SetActive(false)
    cell.receive.gameObject:SetActive(false)
    cell.receivedAlready.gameObject:SetActive(false)
    local activeNode = nil
    if state == CS.Proto.RACING_ACHIEVEMENT_STATUS.RacingStatusNone then
        activeNode = cell.inPogress
    elseif state == CS.Proto.RACING_ACHIEVEMENT_STATUS.RacingStatusActive then
        activeNode = cell.inPogress
    elseif state == CS.Proto.RACING_ACHIEVEMENT_STATUS.RacingStatusCompleted then
        activeNode = cell.receive
    elseif state == CS.Proto.RACING_ACHIEVEMENT_STATUS.RacingStatusReceived then
        activeNode = cell.receivedAlready
    end
    activeNode.gameObject:SetActive(true)
    activeNode.text.text = data.conditionDesc
    if state == CS.Proto.RACING_ACHIEVEMENT_STATUS.RacingStatusCompleted then
        activeNode.btn.onClick:RemoveAllListeners()
        activeNode.btn.onClick:AddListener(function()
            self.m_racingDungeonSystem:ReqGetAchieveReward(self.m_dungeon, data.achievementId)
            cell.receive.transform:Find("SelectedEffect").gameObject:SetActive(true)
            self.m_waitAnimation = true
            self:_StartTimer(1, function()
                self.m_waitAnimation = false
            end)
        end)
    end
    local needUpdateItem = false
    local rewardList = self.m_rewardListCache[cell]
    if not rewardList then
        needUpdateItem = true
        rewardList = {}
        local rewardCache = UIUtils.genCellCache(cell.item)
        rewardList = { cache = rewardCache, id = data.rewardId }
        self.m_rewardListCache[cell] = rewardList
    end
    if data.rewardId ~= rewardList.id then
        needUpdateItem = true
        rewardList.id = data.rewardId
    end
    if needUpdateItem then
        local rewardItems = Tables.rewardTable[data.rewardId]
        rewardList.cache:Refresh(4, function(rewardCell, rewardIndex)
            if rewardItems.itemBundles.Count < rewardIndex then
                rewardCell.empty.gameObject:SetActive(true)
                rewardCell.item.gameObject:SetActive(false)
                return
            else
                local itemData = rewardItems.itemBundles[CSIndex(rewardIndex)]
                rewardCell.item:InitItem(itemData, true)
                rewardCell.empty.gameObject:SetActive(false)
                rewardCell.item.gameObject:SetActive(true)
            end
        end)
    end
end
HL.Commit(RacingDungeonAchieveRewardCtrl)