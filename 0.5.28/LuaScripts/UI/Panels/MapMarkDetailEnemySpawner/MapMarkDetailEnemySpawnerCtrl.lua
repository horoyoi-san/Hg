local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.MapMarkDetailEnemySpawner
MapMarkDetailEnemySpawnerCtrl = HL.Class('MapMarkDetailEnemySpawnerCtrl', uiCtrl.UICtrl)
local ENEMY_POPUP_TITLE_TEXT_ID = "LUA_ADVENTURE_DUNGEON_TAB_NAME_MONSTER_SPAWN"
MapMarkDetailEnemySpawnerCtrl.s_messages = HL.StaticField(HL.Table) << {}
MapMarkDetailEnemySpawnerCtrl.m_firstRewardList = HL.Field(HL.Forward('UIListCache'))
MapMarkDetailEnemySpawnerCtrl.m_commonRewardList = HL.Field(HL.Forward('UIListCache'))
MapMarkDetailEnemySpawnerCtrl.m_subGameId = HL.Field(HL.String) << ""
MapMarkDetailEnemySpawnerCtrl.m_levelId = HL.Field(HL.String) << ""
MapMarkDetailEnemySpawnerCtrl.MAX_SCENE_GRADE = HL.Field(HL.Number) << 4
MapMarkDetailEnemySpawnerCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    local markInstId = args.markInstId
    self.m_firstRewardList = UIUtils.genCellCache(self.view.firstTimeRewardItem)
    self.m_commonRewardList = UIUtils.genCellCache(self.view.commonRewardItem)
    self.view.finishCountDown.gameObject:SetActive(false)
    local commonArgs = {}
    commonArgs.bigBtnActive = true
    commonArgs.markInstId = markInstId
    self.view.detailCommon:InitMapMarkDetailCommon(commonArgs)
    local getRuntimeDataSuccess, markRuntimeData = GameInstance.player.mapManager:GetMarkInstRuntimeData(markInstId)
    if getRuntimeDataSuccess == false then
        logger.error("地图详情页获取实例数据失败" .. markInstId)
        return
    end
    self.m_levelId = markRuntimeData.levelId
    local detail = markRuntimeData.detail
    if detail == nil then
        logger.error("刷怪点详情数据中没有detailData   " .. markInstId)
    end
    local subGameId = detail.subGameId
    self.m_subGameId = subGameId
    local getDisplayDataSuccess, displayData = Tables.worldGameMechanicsDisplayInfoTable:TryGetValue(subGameId)
    if getDisplayDataSuccess == false then
        logger.error("表格中找不到刷怪点ID对应的展示信息   " .. subGameId)
    end
    local curSceneLevel = GameInstance.player.mapManager:GetSceneGrade(displayData.sceneId)
    self:_FillSubGameData(displayData)
    self.view.commonRewardDetailBtn.onClick:AddListener(function()
        local itemLists = self:_GetSceneGradeDifferenceItems(subGameId)
        PhaseManager:OpenPhase(PhaseId.SceneGradeDifferenceItemPopUp, { itemLists = itemLists, sceneGrade = curSceneLevel, titleText = Language.LUA_ENEMY_SPAWNER_MAP_DETAIL_POP_UP_TITLE, })
    end)
    self.view.enemyDetailBtn.onClick:AddListener(function()
        local enemyIdList = {}
        local enemyLevelList = {}
        if displayData.diffGradeEnemyInfosList.Count ~= self.MAX_SCENE_GRADE then
            logger.error("刷怪点的地方情报并未正确配置地图等级的差分，请检查【大世界玩法表】  " .. subGameId)
            return
        end
        for i = 1, displayData.diffGradeEnemyInfosList[curSceneLevel - 1].ids.Count do
            table.insert(enemyIdList, displayData.diffGradeEnemyInfosList[curSceneLevel - 1].ids[CSIndex(i)])
        end
        for i = 1, displayData.diffGradeEnemyInfosList[curSceneLevel - 1].levels.Count do
            table.insert(enemyLevelList, displayData.diffGradeEnemyInfosList[curSceneLevel - 1].levels[CSIndex(i)])
        end
        UIManager:AutoOpen(PanelId.CommonEnemyPopup, { title = Language[ENEMY_POPUP_TITLE_TEXT_ID], enemyIds = enemyIdList, enemyLevels = enemyLevelList, })
    end)
    local gotRecord, record = GameInstance.player.subGameSys:TryGetSubGameRecord(subGameId)
    if not gotRecord then
        return
    end
    local gotSubGameData, subGameData = Tables.gameMechanicTable:TryGetValue(subGameId)
    if not gotSubGameData then
        logger.error("找不到subGameId对应的SubGameData" .. subGameId)
        return
    end
    local finishTimeSec = record.lastEnterTimestamp + subGameData.gameCoolDown
    if finishTimeSec < CS.Beyond.DateTimeUtils.GetCurrentTimestampBySeconds() then
        return
    end
    self.view.finishCountDown.gameObject:SetActive(true)
    self:_StartCoroutine(function()
        local seconds = math.floor(finishTimeSec - CS.Beyond.DateTimeUtils.GetCurrentTimestampBySeconds())
        while seconds > 0 do
            local displayMin = math.floor(seconds / 60)
            local displaySec = seconds % 60
            self.view.refreshTimeText.text = string.format(Language.LUA_ENEMY_SPAWNER_MAP_DETAIL_COUNT_DOWN, displayMin, displaySec)
            coroutine.wait(1)
            seconds = seconds - 1
        end
        self.view.finishCountDown.gameObject:SetActive(false)
    end)
end
MapMarkDetailEnemySpawnerCtrl._GetSceneGradeDifferenceItems = HL.Method(HL.Any).Return(HL.Any) << function(self, subGameId)
    local getDisplayDataSuccess, displayData = Tables.worldGameMechanicsDisplayInfoTable:TryGetValue(subGameId)
    if getDisplayDataSuccess == false or displayData.diffGradeItemList.Count ~= self.MAX_SCENE_GRADE then
        logger.error("表格中找不到刷怪点ID的物品展示信息错误。   " .. subGameId)
    end
    local retList = {}
    for i = 1, self.MAX_SCENE_GRADE do
        local itemIdList = displayData.diffGradeItemList[CSIndex(i)].ids
        local itemCount = itemIdList.Count
        local displayList = {}
        for i = 1, itemCount do
            local itemId = itemIdList[CSIndex(i)]
            local itemCfg = Tables.itemTable[itemId]
            table.insert(displayList, { id = itemId, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), count = nil, isInfinite = false, })
        end
        table.sort(displayList, Utils.genSortFunction({ "rarity", "type" }, false))
        table.insert(retList, displayList)
    end
    return retList
end
MapMarkDetailEnemySpawnerCtrl._FillSubGameData = HL.Method(HL.Any) << function(self, displayData)
    local subGameId = displayData.gameMechanicsId
    local firstRewardId = displayData.firstPassRewardId
    self:_FillFirstRewardsInfo(firstRewardId, subGameId)
    if displayData.sceneId ~= self.m_levelId then
        logger.error("刷怪点地图标记显示信息中的所在场景配置错误，与地图标记所在level不同。" .. subGameId)
    end
    local curSceneLevel = GameInstance.player.mapManager:GetSceneGrade(displayData.sceneId)
    local itemList = displayData.diffGradeItemList[curSceneLevel - 1].ids
    local itemCount = itemList.Count
    local displayList = {}
    for i = 1, itemCount do
        local itemId = itemList[CSIndex(i)]
        local itemCfg = Tables.itemTable[itemId]
        table.insert(displayList, { id = itemId, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), count = nil, isInfinite = false, })
    end
    table.sort(displayList, Utils.genSortFunction({ "rarity", "type" }, false))
    self.m_commonRewardList:Refresh(itemCount, function(itemCell, index)
        local fakeBundle = displayList[index]
        itemCell:InitItem(fakeBundle, true)
    end)
end
MapMarkDetailEnemySpawnerCtrl._FillFirstRewardsInfo = HL.Method(HL.String, HL.String) << function(self, rewardId, subGameId)
    local firstRewardReceived = GameInstance.player.subGameSys:IsGameRewardGained(subGameId, GEnums.GameMechanicsRewardKey.GameFirstPassReward);
    local rewardItemsTable = {}
    local findReward, rewardData = Tables.rewardTable:TryGetValue(rewardId or "")
    if findReward then
        for _, itemBundle in pairs(rewardData.itemBundles) do
            local itemCfg = Tables.itemTable[itemBundle.id]
            table.insert(rewardItemsTable, { id = itemBundle.id, count = itemBundle.count, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), })
        end
    end
    local rewardItemCount = #rewardItemsTable
    if rewardItemCount == 0 then
        self.view.firstClearRewardNode.gameObject:SetActive(false)
        return
    end
    table.sort(rewardItemsTable, Utils.genSortFunction({ "rarity", "type" }, false))
    self.m_firstRewardList:Refresh(rewardItemCount, function(item, index)
        item:InitItem(rewardItemsTable[index], function()
            Notify(MessageConst.SHOW_ITEM_TIPS, { itemId = rewardItemsTable[index].id, transform = item.gameObject.transform, posType = UIConst.UI_TIPS_POS_TYPE.LeftTop, })
        end)
        item.view.rewardedCover.gameObject:SetActive(firstRewardReceived)
    end)
end
HL.Commit(MapMarkDetailEnemySpawnerCtrl)