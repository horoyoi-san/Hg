local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.AdventureReward
local PHASE_ID = PhaseId.AdventureReward
AdventureRewardCtrl = HL.Class('AdventureRewardCtrl', uiCtrl.UICtrl)
AdventureRewardCtrl.m_contactLineCellCache = HL.Field(HL.Forward("UIListCache"))
AdventureRewardCtrl.m_rewardCellCache = HL.Field(HL.Forward("UIListCache"))
AdventureRewardCtrl.m_levelRewardData = HL.Field(HL.Table)
AdventureRewardCtrl.m_genLeftCellFunc = HL.Field(HL.Function)
AdventureRewardCtrl.m_genRightCellFunc = HL.Field(HL.Function)
AdventureRewardCtrl.m_genRewardCellFunc = HL.Field(HL.Function)
AdventureRewardCtrl.m_selectLevelData = HL.Field(HL.Table)
AdventureRewardCtrl.m_selectLevelRewards = HL.Field(HL.Table)
AdventureRewardCtrl.m_posFollowerTick = HL.Field(HL.Thread)
AdventureRewardCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_ADVENTURE_REWARD_RECEIVE] = "OnAdventureRewardReceive", }
AdventureRewardCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_genLeftCellFunc = UIUtils.genCachedCellFunction(self.view.leftScrollList)
    self.m_genRightCellFunc = UIUtils.genCachedCellFunction(self.view.rightScrollList)
    self.m_genRewardCellFunc = UIUtils.genCachedCellFunction(self.view.rewardScrollList)
    self.m_rewardCellCache = UIUtils.genCellCache(self.view.rewardCell)
    self.view.helpBtn.onClick:AddListener(function()
        UIManager:Open(PanelId.InstructionBook, "adventure_reward")
    end)
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PHASE_ID)
    end)
    self.view.leftScrollList.onUpdateCell:AddListener(function(gameObject, csIndex)
        self:_UpdateLeftScrollCell(gameObject, csIndex)
    end)
    self.view.leftScrollList.onCenterIndexChanged:AddListener(function(oldCenterCellIndex, newCenterCellIndex)
        self:_OnCenterIndexChanged(oldCenterCellIndex, newCenterCellIndex)
    end)
    self.view.rightScrollList.onUpdateCell:AddListener(function(gameObject, csIndex)
        self:_UpdateRightScrollCell(gameObject, csIndex)
    end)
    self.view.rightScrollList.onChangeView:AddListener(function(gameObject, index, value)
        self:_UpdateRightTagView(gameObject, index, value)
    end)
    self.view.rewardScrollList.onUpdateCell:AddListener(function(gameObject, csIndex)
        local cell = self.m_genRewardCellFunc(gameObject)
        self:_UpdateRewardCell(cell, LuaIndex(csIndex))
    end)
    self.view.getAll.onClick:AddListener(function()
        GameInstance.player.adventure:TakeLevelRewardAll()
    end)
    local leftScrollListPadding = self.view.leftScrollList.gameObject:GetComponent(typeof(RectTransform)).rect.height / 2 - 40
    self.view.leftScrollList:SetPaddingBottom(leftScrollListPadding)
    self.view.leftScrollList:SetPaddingTop(leftScrollListPadding)
    local rightScrollListPadding = self.view.rightScrollList.gameObject:GetComponent(typeof(RectTransform)).rect.height / 2 - 40
    self.view.rightScrollList:SetPaddingBottom(rightScrollListPadding)
    self.view.rightScrollList:SetPaddingTop(rightScrollListPadding)
    local adventureLevelData = GameInstance.player.adventure.adventureLevelData
    local relativeExp = adventureLevelData.relativeExp
    local relativeLevelUpExp = adventureLevelData.relativeLevelUpExp
    self.view.expProgress.fillAmount = relativeExp / relativeLevelUpExp
    self.view.expTxt.text = string.format(Language.LUA_ADVENTURE_REWARD_EXP_PROGRESS_FORMAT, relativeExp, relativeLevelUpExp)
    self.view.curLevelTxt.text = adventureLevelData.lv
    self.m_levelRewardData = self:_ProcessRewardData()
    self.view.leftScrollList:UpdateCount(#self.m_levelRewardData)
    self.view.rightScrollList:UpdateCount(#self.m_levelRewardData)
    self:_StartCoroutine(function()
        coroutine.step()
        local findCurLvIndex = function()
            local curLv = GameInstance.player.adventure.adventureLevelData.lv
            for index, levelReward in ipairs(self.m_levelRewardData) do
                if levelReward.level == curLv then
                    return index
                end
            end
            return #self.m_levelRewardData
        end
        local index = findCurLvIndex()
        self.view.leftScrollList:ScrollToIndex(CSIndex(index))
    end)
    local rightScrollRect = self.view.rightScrollList.gameObject:GetComponent(typeof(CS.Beyond.UI.UIScrollRect))
    local leftScrollRect = self.view.leftScrollList.gameObject:GetComponent(typeof(CS.Beyond.UI.UIScrollRect))
    self.m_posFollowerTick = self:_StartCoroutine(function()
        while (true) do
            rightScrollRect.verticalNormalizedPosition = leftScrollRect.verticalNormalizedPosition
            coroutine.step()
        end
    end)
end
AdventureRewardCtrl.OnClose = HL.Override() << function(self)
    if self.m_posFollowerTick then
        self:_ClearCoroutine(self.m_posFollowerTick)
    end
end
AdventureRewardCtrl._ProcessRewardData = HL.Method().Return(HL.Table) << function(self)
    local rewardData = {}
    for _, adventureLevelData in pairs(Tables.adventureLevelTable) do
        if adventureLevelData.level ~= 1 then
            local rewardDataUnit = {}
            rewardDataUnit.level = adventureLevelData.level
            rewardDataUnit.rewardId = adventureLevelData.rewardId
            table.insert(rewardData, rewardDataUnit)
        end
    end
    table.sort(rewardData, Utils.genSortFunction({ "level" }))
    return rewardData
end
AdventureRewardCtrl._UpdateLeftScrollCell = HL.Method(GameObject, HL.Number) << function(self, gameObject, csIndex)
    local cell = self.m_genLeftCellFunc(gameObject)
    local luaIndex = LuaIndex(csIndex)
    cell:InitAdventureRewardShortInfoCell(self.m_levelRewardData[luaIndex], luaIndex, function(luaIndex)
        self:_OnLevelRewardCellClick(luaIndex)
    end)
end
AdventureRewardCtrl._UpdateRightScrollCell = HL.Method(GameObject, HL.Number) << function(self, gameObject, csIndex)
    local cell = self.m_genRightCellFunc(gameObject)
    local luaIndex = LuaIndex(csIndex)
    cell:InitAdventureRewardTagCell(self.m_levelRewardData[luaIndex], function(rewardInfo)
    end)
end
AdventureRewardCtrl._UpdateRightTagView = HL.Method(GameObject, HL.Number, HL.Number) << function(self, go, csIndex, value)
    local canvasGroup = go:GetComponentInChildren(typeof(Unity.CanvasGroup))
    canvasGroup.alpha = value
end
AdventureRewardCtrl._OnLevelRewardCellClick = HL.Method(HL.Number) << function(self, luaIndex)
    self.view.leftScrollList:ScrollToIndex(CSIndex(luaIndex))
end
AdventureRewardCtrl._OnCenterIndexChanged = HL.Method(HL.Number, HL.Number) << function(self, oldCenterCellIndex, newCenterCellIndex)
    local rewardInfo = self.m_levelRewardData[LuaIndex(newCenterCellIndex)]
    self.m_selectLevelData = rewardInfo
    self:_RefreshRightDownNode(rewardInfo)
    self:_RefreshLineNode(newCenterCellIndex)
end
AdventureRewardCtrl._RefreshLineNode = HL.Method(HL.Number) << function(self, newCenterIndex)
    self.view.lineNode.gameObject:SetActiveIfNecessary(true)
    local offset = (1 + self.view.config.CONTACT_LINE_COUNT) / 2
    for i = 1, self.view.config.CONTACT_LINE_COUNT do
        local relativeOffset = i - offset
        local realInfoIndex = LuaIndex(relativeOffset + newCenterIndex)
        self.view["line" .. i].gameObject:SetActiveIfNecessary(self.m_levelRewardData[realInfoIndex] ~= nil)
    end
end
AdventureRewardCtrl._RefreshRightDownNode = HL.Method(HL.Table) << function(self, rewardInfo)
    local itemBundles = Tables.rewardTable[rewardInfo.rewardId].itemBundles
    local useScrollList = itemBundles.Count > self.view.config.REWARDS_SCROLL_THRESHOLD
    local adventure = GameInstance.player.adventure
    local reach = adventure.adventureLevelData.lv >= rewardInfo.level
    local receive = adventure:IsAdventureLevelRewardReceived(rewardInfo.level)
    self.view.rewardLevelTxt.text = string.format(Language.LUA_ADVENTURE_LEVEL_FORMAT, rewardInfo.level)
    local rewards = {}
    for _, itemBundle in pairs(itemBundles) do
        local reward = {}
        reward.id = itemBundle.id
        reward.count = itemBundle.count
        table.insert(rewards, reward)
    end
    self.m_selectLevelRewards = rewards
    self.view.rewardScrollList.gameObject:SetActiveIfNecessary(useScrollList)
    self.view.rewardList.gameObject:SetActiveIfNecessary(not useScrollList)
    if useScrollList then
        self.view.rewardScrollList:UpdateCount(#rewards)
    else
        self.m_rewardCellCache:Refresh(#rewards, function(cell, luaIndex)
            self:_UpdateRewardCell(cell, luaIndex)
        end)
    end
    self.view.received.gameObject:SetActiveIfNecessary(receive)
    self.view.unreached.gameObject:SetActiveIfNecessary(not reach)
    self.view.getAll.gameObject:SetActiveIfNecessary(not receive and reach)
end
AdventureRewardCtrl._UpdateRewardCell = HL.Method(HL.Any, HL.Number) << function(self, cell, luaIndex)
    local reward = self.m_selectLevelRewards[luaIndex]
    cell:InitItem({ id = reward.id, count = reward.count }, true)
end
AdventureRewardCtrl.OnAdventureRewardReceive = HL.Method(HL.Any) << function(self, args)
    local rewardLevels = unpack(args)
    local rewardItemsDic = {}
    for _, rewardLevel in pairs(rewardLevels) do
        local rewardId = Tables.adventureLevelTable[rewardLevel].rewardId
        local rewardCfg = Tables.rewardTable[rewardId]
        for _, bundle in pairs(rewardCfg.itemBundles) do
            if not rewardItemsDic[bundle.id] then
                rewardItemsDic[bundle.id] = { id = bundle.id, count = bundle.count, }
            else
                local count = rewardItemsDic[bundle.id].count
                rewardItemsDic[bundle.id].count = count + bundle.count
            end
        end
    end
    local rewardList = {}
    for _, rewardItem in pairs(rewardItemsDic) do
        table.insert(rewardList, rewardItem)
    end
    Notify(MessageConst.SHOW_SYSTEM_REWARDS, { title = Language.LUA_ADVENTURE_LEVEL_REWARD_TITLE_DESC, items = rewardList })
    self:_RefreshRightDownNode(self.m_selectLevelData)
end
HL.Commit(AdventureRewardCtrl)