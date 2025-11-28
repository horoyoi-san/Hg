local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RacingDungeonWeeklyReward
RacingDungeonWeeklyRewardCtrl = HL.Class('RacingDungeonWeeklyRewardCtrl', uiCtrl.UICtrl)
RacingDungeonWeeklyRewardCtrl.m_rewardListCache = HL.Field(HL.Table)
RacingDungeonWeeklyRewardCtrl.m_dataList = HL.Field(HL.Table)
RacingDungeonWeeklyRewardCtrl.m_getCell = HL.Field(HL.Function)
RacingDungeonWeeklyRewardCtrl.m_racingDungeonSystem = HL.Field(HL.Any)
RacingDungeonWeeklyRewardCtrl.m_dungeon = HL.Field(HL.String) << ''
RacingDungeonWeeklyRewardCtrl.m_maxLevel = HL.Field(HL.Number) << 0
RacingDungeonWeeklyRewardCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_RACING_DUNGEON_GET_WEEKLY_REWARD] = 'OnGetReward', }
RacingDungeonWeeklyRewardCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnBack.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.view.allGetButton.onClick:AddListener(function()
        self.m_racingDungeonSystem:ReqGetWeeklyReward(self.m_dungeon, -1)
    end)
    self.m_getCell = UIUtils.genCachedCellFunction(self.view.mainScrollView)
    self.m_dataList = {}
    self.m_rewardListCache = {}
    self.view.mainScrollView.onUpdateCell:AddListener(function(cell, index)
        self:_UpdateCell(cell, index)
    end)
    self.m_racingDungeonSystem = GameInstance.player.racingDungeonSystem
    local t = Tables.racingDungeonTable
    for k, v in pairs(t) do
        self.m_maxLevel = self.m_racingDungeonSystem:GetRacingDungeonPassedLevel(k)
        self.m_maxLevel = self.m_maxLevel
    end
    for k, v in pairs(Tables.racingBattlePassTable) do
        self.m_dungeon = k
        for index, item in pairs(v.list) do
            table.insert(self.m_dataList, item)
        end
    end
    self:UpdateView()
end
RacingDungeonWeeklyRewardCtrl.OnWeeklyRefresh = HL.StaticMethod() << function(arg)
    xlua.private_accessible(CS.Beyond.Gameplay.RacingDungeonSystem)
    local arg = unpack(arg)
    if arg.Count == 0 then
        for k, v in cs_pairs(GameInstance.player.racingDungeonSystem.m_racingDungeonWeeklyRewardInfo) do
            if v.exp == 0 then
                v.haveGetRewardNodes:Clear()
            end
        end
        local isOpen, ctrl = UIManager:IsOpen(PANEL_ID)
        if isOpen then
            ctrl:UpdateView()
        end
    end
end
RacingDungeonWeeklyRewardCtrl.OnGetReward = HL.Method(HL.Any) << function(self, arg)
    local arg = unpack(arg)
    if arg.Count == 0 then
        self:UpdateView()
        return
    end
    local items = {}
    for i = 0, arg.Count - 1 do
        local nodeId = arg[i]
        for k, v in pairs(Tables.racingBattlePassTable) do
            for index, item in pairs(v.list) do
                if item.nodeId == nodeId then
                    local rewardData = Tables.rewardTable[item.rewardId]
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
    end
    local itemsList = {}
    for k, v in pairs(items) do
        table.insert(itemsList, v)
    end
    Notify(MessageConst.SHOW_SYSTEM_REWARDS, { icon = "icon_common_rewards", items = itemsList, })
    self:UpdateView()
end
RacingDungeonWeeklyRewardCtrl.UpdateView = HL.Method() << function(self)
    self.view.txtExising.text = self.m_racingDungeonSystem:GetWeeklyExp(self.m_dungeon)
    local maxExp = 0
    for k, v in pairs(Tables.racingBattlePassTable) do
        self.m_dungeon = k
        for index, item in pairs(v.list) do
            if item.exp > maxExp then
                maxExp = item.exp
            end
        end
    end
    self.view.txtLevel.text = maxExp
    self.view.mainScrollView:UpdateCount(#self.m_dataList + 1)
    local haveReward = false
    for i = 1, #self.m_dataList do
        local data = self.m_dataList[i]
        if self.m_racingDungeonSystem:CheckWeeklyRewardCanGet(self.m_dungeon, data.nodeId) and self.m_maxLevel >= data.unlockLevel then
            haveReward = true
            break
        end
    end
    self.view.allGetButton.gameObject:SetActive(haveReward)
    local curTime = DateTimeUtils.GetCurrentTimestampBySeconds()
    local nextWeek = Utils.getNextWeeklyServerRefreshTime()
    local leftTime = ((nextWeek - curTime) // 86400) + 1
    self.view.textTime.text = string.format(Language.LUA_RPG_DUNGEON_TIME_DAY_FORMAT, leftTime)
end
RacingDungeonWeeklyRewardCtrl._UpdateCell = HL.Method(GameObject, HL.Number) << function(self, cell, index)
    local index = LuaIndex(index)
    cell = self.m_getCell(cell)
    if index == 1 then
        cell.empty.gameObject:SetActive(true)
        cell.contentNode.gameObject:SetActive(false)
        cell.progressNode.gameObject:SetActive(false)
        return
    else
        cell.empty.gameObject:SetActive(false)
        cell.contentNode.gameObject:SetActive(true)
        cell.progressNode.gameObject:SetActive(true)
    end
    index = index - 1
    local data = self.m_dataList[index]
    local nowExp = self.m_racingDungeonSystem:GetWeeklyExp(self.m_dungeon)
    if nowExp >= data.exp then
        cell.progressBar.fillAmount = 1
        cell.pointFull.gameObject:SetActive(true)
    else
        cell.pointFull.gameObject:SetActive(false)
        if index == 1 then
            cell.progressBar.fillAmount = nowExp / data.exp
        else
            local lastData = self.m_dataList[index - 1]
            nowExp = nowExp - lastData.exp
            cell.progressBar.fillAmount = nowExp / (data.exp - lastData.exp)
        end
    end
    if self.m_maxLevel < data.unlockLevel then
        cell.difficultyTip.gameObject:SetActive(true)
        cell.difficultyTipText.text = string.format(Language.LUA_RACING_DUNGEON_LOCK_CONDITION, data.unlockLevel)
        cell.decoIock.gameObject:SetActive(true)
    else
        cell.difficultyTip.gameObject:SetActive(false)
        cell.decoIock.gameObject:SetActive(false)
    end
    cell.txtSchedule.text = data.exp
    local canGet = self.m_racingDungeonSystem:CheckWeeklyRewardCanGet(self.m_dungeon, data.nodeId) and self.m_maxLevel >= data.unlockLevel
    local haveGet = self.m_racingDungeonSystem:CheckWeeklyRewardHaveGet(self.m_dungeon, data.nodeId)
    cell.canGet.gameObject:SetActive(canGet)
    cell.button.gameObject:SetActive(canGet or haveGet)
    cell.unclaimed.gameObject:SetActive(not haveGet)
    cell.receive.gameObject:SetActive(haveGet)
    cell.button.onClick:RemoveAllListeners()
    cell.button.onClick:AddListener(function()
        self.m_racingDungeonSystem:ReqGetWeeklyReward(self.m_dungeon, data.nodeId)
    end)
    local needUpdateItem = false
    local cache = nil
    if not self.m_rewardListCache[cell] then
        cache = { cache = cell.rewardItems, id = data.rewardId }
        self.m_rewardListCache[cell] = cache
        needUpdateItem = true
    else
        cache = self.m_rewardListCache[cell]
    end
    if cache.id ~= data.rewardId then
        cache.id = data.rewardId
        needUpdateItem = true
    end
    needUpdateItem = true
    if needUpdateItem then
        local rewardData = Tables.rewardTable[data.rewardId]
        local list = {}
        for i = 0, rewardData.itemBundles.Count - 1 do
            table.insert(list, rewardData.itemBundles[i])
        end
        cache.cache.gameObject:SetActive(true)
        cache.cache:InitRewardItems(list, haveGet)
    end
end
HL.Commit(RacingDungeonWeeklyRewardCtrl)