local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.AdventureDungeon
local SeriesTableFilterItem = { [GEnums.DungeonCategoryType.BasicResource] = {}, [GEnums.DungeonCategoryType.CharResource] = {}, [GEnums.DungeonCategoryType.BossRush] = {}, [GEnums.DungeonCategoryType.Challenge] = {}, }
local IsSeriesTableFiltered = false
local TabDataList = { { type = GEnums.DungeonCategoryType.CharResource, tabName = Language.ui_AdventureDungeonPanel_title_charmaterial, imgPath = "deco_adventure_d_material", }, { type = GEnums.DungeonCategoryType.BasicResource, tabName = Language.ui_AdventureDungeonPanel_title_basematerial, imgPath = "deco_adventure_d_currency", }, { type = GEnums.DungeonCategoryType.BossRush, tabName = Language.ui_AdventureDungeonPanel_title_boss, imgPath = "deco_adventure_d_leaderchallenge", }, { type = GEnums.DungeonCategoryType.Challenge, tabName = Language.ui_AdventureDungeonPanel_title_challenge, imgPath = "deco_adventure_d_challengethis", }, }
AdventureDungeonCtrl = HL.Class('AdventureDungeonCtrl', uiCtrl.UICtrl)
AdventureDungeonCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SCENE_GRADE_CHANGE_NOTIFY] = '_OnSceneGradeChangeNotify', [MessageConst.ON_CHANGE_ADVENTURE_DUNGEON_TAB] = '_OnChangeTab', }
AdventureDungeonCtrl.m_genTabCells = HL.Field(HL.Forward("UIListCache"))
AdventureDungeonCtrl.m_genCategoryCells = HL.Field(HL.Function)
AdventureDungeonCtrl.m_genSingleCategoryCells = HL.Field(HL.Function)
AdventureDungeonCtrl.m_curTabIndex = HL.Field(HL.Number) << 1
AdventureDungeonCtrl.m_dungeonCategoryInfos = HL.Field(HL.Table)
AdventureDungeonCtrl.m_forbidResetTabIndex = HL.Field(HL.Boolean) << false
AdventureDungeonCtrl.m_onGotoDungeon = HL.Field(HL.Function)
AdventureDungeonCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:_InitData()
    self:_UpdateData()
    self:_InitUI()
    self:_RefreshAllUI()
end
AdventureDungeonCtrl.OnClose = HL.Override() << function(self)
    if self.m_curTabIndex > 0 and self.m_curTabIndex <= self.m_genTabCells:GetCount() then
        self:_ReadTabRedDot(self.m_curTabIndex)
    end
end
AdventureDungeonCtrl._OnChangeTab = HL.Method(HL.Any) << function(self, arg)
    local dungeonTab = arg
    local index = 1
    for _, categoryInfo in pairs(self.m_dungeonCategoryInfos) do
        if categoryInfo.tabJumpName == dungeonTab then
            break
        end
        index = index + 1
    end
    if index > #self.m_dungeonCategoryInfos then
        logger.error(ELogChannel.UI, "[AdventureDungeonCtrl._OnChangeTab] 跳转到指定dungeonTab失败，可能是没解锁或配置错，tabName:" .. dungeonTab)
        index = 1
    end
    self.m_curTabIndex = math.min(index, #self.m_dungeonCategoryInfos)
    local cell = self.m_genTabCells:Get(self.m_curTabIndex)
    cell.toggle:SetIsOnWithoutNotify(true)
    self:_OnClickTabToggle(self.m_curTabIndex, true)
end
AdventureDungeonCtrl._InitUI = HL.Method() << function(self)
    self.m_genTabCells = UIUtils.genCellCache(self.view.tabTogCell)
    self.m_genCategoryCells = UIUtils.genCachedCellFunction(self.view.dungeonCategoryList)
    self.view.dungeonCategoryList.onUpdateCell:AddListener(function(obj, csIndex)
        local cell = self.m_genCategoryCells(obj)
        self:_UpdateDungeonCategory(cell, LuaIndex(csIndex))
    end)
    self.m_genSingleCategoryCells = UIUtils.genCachedCellFunction(self.view.singleCategoryNode.singleCategoryList)
    self.view.singleCategoryNode.singleCategoryList.onUpdateCell:AddListener(function(obj, csIndex)
        local cell = self.m_genSingleCategoryCells(obj)
        self:_UpdateSingleDungeonCell(cell, LuaIndex(csIndex))
    end)
end
AdventureDungeonCtrl._InitData = HL.Method() << function(self)
    if not IsSeriesTableFiltered then
        IsSeriesTableFiltered = true
        for _, item in pairs(Tables.dungeonSeriesTable) do
            local category = item.dungeonCategory
            if SeriesTableFilterItem[category] then
                table.insert(SeriesTableFilterItem[category], item)
            end
        end
    end
    self.m_onGotoDungeon = function()
        self.m_forbidResetTabIndex = true
    end
end
AdventureDungeonCtrl.OnShow = HL.Override() << function(self)
    self.m_forbidResetTabIndex = false
end
AdventureDungeonCtrl.OnHide = HL.Override() << function(self)
    if self.m_forbidResetTabIndex then
        return
    end
    local count = self.m_genTabCells:GetCount()
    if count > 0 then
        local cell = self.m_genTabCells:Get(1)
        cell.toggle.isOn = true
    end
end
AdventureDungeonCtrl._UpdateData = HL.Method() << function(self)
    self.m_dungeonCategoryInfos = {}
    for _, v in pairs(TabDataList) do
        self:_InitDataCommonDungeon(v.type, v.tabName, v.imgPath)
    end
    self:_InitDataMonsterSpawnPoint()
    self.m_curTabIndex = math.min(self.m_curTabIndex, #self.m_dungeonCategoryInfos)
end
AdventureDungeonCtrl._RefreshAllUI = HL.Method() << function(self)
    self.m_genTabCells:Refresh(#self.m_dungeonCategoryInfos, function(cell, luaIndex)
        self:_RefreshUITabCell(cell, luaIndex)
    end)
    self:_OnClickTabToggle(self.m_curTabIndex, true)
end
AdventureDungeonCtrl._OnSceneGradeChangeNotify = HL.Method(HL.Table) << function(self, args)
    self:_UpdateData()
    self:_RefreshAllUI()
end
AdventureDungeonCtrl._InitDataCommonDungeon = HL.Method(HL.Any, HL.String, HL.String) << function(self, categoryType, tabName, tabImg)
    local isCategoryUnlocked = GameInstance.dungeonManager:IsDungeonSeriesFirCategoryUnlock(categoryType)
    if not isCategoryUnlocked then
        return
    end
    local tableDataList = SeriesTableFilterItem[categoryType]
    if (#tableDataList <= 0) then
        return
    end
    local newCategoryInfo = { tabName = tabName, tabImgPath = tabImg, tabJumpName = categoryType:ToString(), dungeonInfosList = {}, subGameIds = {}, }
    local tempTable = {}
    for _, tableData in pairs(tableDataList) do
        local isUnlocked = GameInstance.dungeonManager:IsDungeonSeriesUnlock(tableData.id, tableData.dungeonCategory)
        if isUnlocked then
            local category2ndType = tableData.dungeonCategory2nd
            local infosBundle = tempTable[category2ndType]
            if not infosBundle then
                local cfgExist, category2ndTypeCfg = Tables.DungeonCategory2ndTable:TryGetValue(category2ndType)
                infosBundle = { category2ndType = category2ndType:GetHashCode(), name = cfgExist and category2ndTypeCfg.name or "", infos = {}, }
                tempTable[tableData.dungeonCategory2nd] = infosBundle
            end
            local info = self:_HandleAndCreateSeriesInfo(tableData, newCategoryInfo)
            if info then
                table.insert(infosBundle.infos, info)
            end
        end
    end
    for _, v in pairs(tempTable) do
        table.sort(v.infos, Utils.genSortFunction({ "sortId" }, true))
        table.insert(newCategoryInfo.dungeonInfosList, v)
    end
    table.sort(newCategoryInfo.dungeonInfosList, Utils.genSortFunction({ "category2ndType" }, true))
    table.insert(self.m_dungeonCategoryInfos, newCategoryInfo)
end
AdventureDungeonCtrl._HandleAndCreateSeriesInfo = HL.Method(HL.Any, HL.Table).Return(HL.Table) << function(self, seriesCfg, categoryInfo)
    local hasCfg, dungeonTypeCfg = Tables.dungeonTypeTable:TryGetValue(seriesCfg.gameCategory)
    if hasCfg then
        local dungeonCategory = seriesCfg.dungeonCategory
        local seriesId = seriesCfg.id
        local isActive = ((dungeonCategory == GEnums.DungeonCategoryType.CharResource or dungeonCategory == GEnums.DungeonCategoryType.BasicResource) and GameInstance.dungeonManager:IsDungeonInteractiveActive(seriesId))
        local info = { seriesId = seriesId, sortId = seriesCfg.sortId, mapMarkType = dungeonTypeCfg.mapMarkType, dungeonImg = seriesCfg.dungeonImg, dungeonRoleImg = seriesCfg.dungeonRoleImg, dungeonName = seriesCfg.name, staminaTxt = "", isActive = isActive, rewardInfos = self:_ProcessDungeonSeriesRewards(seriesId), subGameIds = {}, onGotoDungeon = self.m_onGotoDungeon, }
        local minStaminaCost = math.maxinteger
        local maxStaminaCost = math.mininteger
        for _, subGameId in pairs(seriesCfg.includeDungeonIds) do
            table.insert(info.subGameIds, subGameId)
            table.insert(categoryInfo.subGameIds, subGameId)
            local cfg = Utils.tryGetTableCfg(Tables.gameMechanicTable, subGameId)
            if cfg then
                minStaminaCost = math.min(minStaminaCost, cfg.costStamina)
                maxStaminaCost = math.max(maxStaminaCost, cfg.costStamina)
            end
        end
        local count = #info.subGameIds
        if count <= 0 or maxStaminaCost <= 0 then
            info.staminaTxt = ""
        elseif count == 1 then
            info.staminaTxt = tostring(maxStaminaCost)
        else
            info.staminaTxt = minStaminaCost .. "~" .. maxStaminaCost
        end
        return info
    end
    return nil
end
AdventureDungeonCtrl._InitDataMonsterSpawnPoint = HL.Method() << function(self)
    local newCategoryInfo = { tabName = Language.ui_AdventureDungeonPanel_title_enemyspawner, tabImgPath = "deco_adventure_d_brushingmonsters", tabJumpName = "EnemySpawner", dungeonInfosList = {}, subGameIds = {}, }
    local infosBundle = { category2ndType = GEnums.DungeonCategory2ndType.None:GetHashCode(), name = "", infos = {}, }
    table.insert(newCategoryInfo.dungeonInfosList, infosBundle)
    for id, tableData in pairs(Tables.worldGameMechanicsDisplayInfoTable) do
        local canShow = false
        if GameInstance.player.subGameSys:IsGameMapMarkUnlock(id, GEnums.MarkType.EnemySpawner) and GameInstance.player.subGameSys:IsGameUnlocked(id) then
            canShow = true
        end
        if canShow then
            local hasCfg, gameCfg = Tables.gameMechanicTable:TryGetValue(id)
            if hasCfg then
                local info = { seriesId = id, sortId = tableData.sortId, mapMarkType = GEnums.MarkType.EnemySpawner, dungeonRoleImg = tableData.icon, dungeonName = gameCfg.gameName, staminaTxt = "", isActive = false, rewardInfos = AdventureDungeonCtrl._ProcessMonsterSpawnRewards(id), subGameIds = { id }, onGotoDungeon = self.m_onGotoDungeon, }
                table.insert(infosBundle.infos, info)
                table.insert(newCategoryInfo.subGameIds, id)
            else
                logger.error("[Game Mechanic Table] missing, id = " .. id)
            end
        end
    end
    if #newCategoryInfo.subGameIds <= 0 then
        return
    end
    table.sort(infosBundle.infos, Utils.genSortFunction({ "sortId" }, true))
    table.insert(self.m_dungeonCategoryInfos, newCategoryInfo)
end
AdventureDungeonCtrl._RefreshUITabCell = HL.Method(HL.Table, HL.Number) << function(self, cell, luaIndex)
    local tabInfo = self.m_dungeonCategoryInfos[luaIndex]
    cell.tabNameTxt.text = tabInfo.tabName
    cell.tabImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_ADVENTURE, tabInfo.tabImgPath)
    cell.toggle.isOn = luaIndex == self.m_curTabIndex
    cell.toggle.onValueChanged:RemoveAllListeners()
    cell.toggle.onValueChanged:AddListener(function(isOn)
        if isOn then
            self:_OnClickTabToggle(luaIndex)
        end
    end)
    cell.toggle.onHoverChange:RemoveAllListeners()
    cell.toggle.onHoverChange:AddListener(function(isHover)
        if cell.toggle.isOn then
            return
        end
        if isHover then
            cell.aniWrap:Play("adventuredungeontabtogcell_hover")
        else
            cell.aniWrap:Play("adventuredungeontabtogcell_normal")
        end
    end)
    cell.redDot:InitRedDot("AdventureDungeonTab", tabInfo.subGameIds)
end
AdventureDungeonCtrl._OnClickTabToggle = HL.Method(HL.Number, HL.Opt(HL.Boolean)) << function(self, luaIndex, isInit)
    if self.m_curTabIndex == luaIndex and not isInit then
        return
    end
    local count = #self.m_dungeonCategoryInfos
    if count < luaIndex or luaIndex < 1 then
        return
    end
    local preIndex = self.m_curTabIndex
    if (preIndex ~= luaIndex) then
        self:_ReadTabRedDot(preIndex)
    end
    self.m_curTabIndex = luaIndex
    local dungeonInfosList = self.m_dungeonCategoryInfos[luaIndex].dungeonInfosList
    local listCount = #dungeonInfosList
    if listCount > 1 then
        self.view.dungeonCategoryList.gameObject:SetActiveIfNecessary(true)
        self.view.singleCategoryNode.gameObject:SetActiveIfNecessary(false)
        self.view.dungeonCategoryList:UpdateCount(listCount, true)
    elseif listCount == 1 then
        local singleCategoryNode = self.view.singleCategoryNode
        singleCategoryNode.gameObject:SetActiveIfNecessary(true)
        self.view.dungeonCategoryList.gameObject:SetActiveIfNecessary(false)
        local infosBundle = dungeonInfosList[1]
        infosBundle.hasRead = true
        local category2ndType = GEnums.DungeonCategory2ndType.__CastFrom(infosBundle.category2ndType)
        if (category2ndType == GEnums.DungeonCategory2ndType.None) then
            singleCategoryNode.titleState:SetState("HideTitle")
        else
            singleCategoryNode.titleState:SetState("ShowTitle")
            singleCategoryNode.titleTxt.text = infosBundle.name
        end
        local cellCount = #infosBundle.infos
        self.view.singleCategoryNode.singleCategoryList:UpdateCount(cellCount, true)
    end
    if listCount > 0 then
        local infoBundle = dungeonInfosList[1]
        if string.isEmpty(infoBundle.name) then
            self.view.titleBgMask.gameObject:SetActiveIfNecessary(true)
        else
            self.view.titleBgMask.gameObject:SetActiveIfNecessary(false)
        end
    else
        self.view.titleBgMask.gameObject:SetActiveIfNecessary(true)
    end
    if not isInit then
        local aniWrapper = self:GetAnimationWrapper()
        aniWrapper:Play("adventuredungeonnode_change")
    end
end
AdventureDungeonCtrl._ReadTabRedDot = HL.Method(HL.Number) << function(self, luaIndex)
    if luaIndex <= 0 or luaIndex > #self.m_dungeonCategoryInfos then
        return
    end
    local subGameIds = {}
    local categoryInfo = self.m_dungeonCategoryInfos[luaIndex]
    for _, infosBundle in pairs(categoryInfo.dungeonInfosList) do
        if infosBundle.hasRead then
            for _, info in pairs(infosBundle.infos) do
                if info.hasRead then
                    for _, id in pairs(info.subGameIds) do
                        table.insert(subGameIds, id)
                    end
                end
            end
        end
    end
    if (#subGameIds) > 0 then
        GameInstance.player.subGameSys:SendSubGameListRead(subGameIds)
    end
end
AdventureDungeonCtrl._UpdateDungeonCategory = HL.Method(HL.Any, HL.Number) << function(self, cell, luaIndex)
    local infosBundle = self.m_dungeonCategoryInfos[self.m_curTabIndex].dungeonInfosList[luaIndex]
    cell:InitDungeonCategoryCell(infosBundle)
end
AdventureDungeonCtrl._UpdateSingleDungeonCell = HL.Method(HL.Any, HL.Number) << function(self, cell, luaIndex)
    local infosBundle = self.m_dungeonCategoryInfos[self.m_curTabIndex].dungeonInfosList[1]
    local cellInfo = infosBundle.infos[luaIndex]
    cell:InitAdventureDungeonCell(cellInfo)
    cellInfo.hasRead = true
end
AdventureDungeonCtrl._ProcessDungeonSeriesRewards = HL.Method(HL.String).Return(HL.Table) << function(self, seriesId)
    local dungeonSeriesCfg = Tables.dungeonSeriesTable[seriesId]
    if not dungeonSeriesCfg then
        return {}
    end
    local rewardList = {}
    if dungeonSeriesCfg.dungeonCategory == GEnums.DungeonCategoryType.Challenge then
        for _, v in pairs(dungeonSeriesCfg.includeDungeonIds) do
            self:_ProcessDungeonRewardsNoMerge(v, rewardList)
        end
    else
        local rewards = {}
        for _, v in pairs(dungeonSeriesCfg.includeDungeonIds) do
            self:_ProcessDungeonRewards(v, rewards)
        end
        for _, v in pairs(rewards) do
            table.insert(rewardList, v)
        end
    end
    table.sort(rewardList, Utils.genSortFunction({ "gainedSortId", "rewardTypeSortId", "rarity", "type" }))
    return rewardList
end
AdventureDungeonCtrl._ProcessDungeonRewards = HL.Method(HL.String, HL.Table) << function(self, dungeonId, rewards)
    local gameMechanicCfg = Tables.gameMechanicTable[dungeonId]
    local hasFirstReward = not string.isEmpty(gameMechanicCfg.firstPassRewardId)
    local hasRecycleReward = not string.isEmpty(gameMechanicCfg.rewardId)
    local hasExtraReward = not string.isEmpty(gameMechanicCfg.extraRewardId)
    if hasFirstReward then
        local rewardsCfg = Tables.rewardTable[gameMechanicCfg.firstPassRewardId]
        for _, itemBundle in pairs(rewardsCfg.itemBundles) do
            local itemId = itemBundle.id
            local reward = rewards[itemId]
            if not reward then
                local itemCfg = Tables.itemTable[itemId]
                reward = { id = itemId, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), gainedSortId = 1, rewardTypeSortId = 3, gained = false, }
                rewards[itemId] = reward
            end
        end
    end
    if hasRecycleReward then
        local rewardsCfg = Tables.rewardTable[gameMechanicCfg.rewardId]
        for _, itemBundle in pairs(rewardsCfg.itemBundles) do
            local itemId = itemBundle.id
            local reward = rewards[itemId]
            if not reward then
                local itemCfg = Tables.itemTable[itemId]
                reward = { id = itemId, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), gainedSortId = 1, rewardTypeSortId = 1, gained = false, }
                rewards[itemId] = reward
            end
        end
    end
    if hasExtraReward then
        local rewardsCfg = Tables.rewardTable[gameMechanicCfg.extraRewardId]
        for _, itemBundle in pairs(rewardsCfg.itemBundles) do
            local itemId = itemBundle.id
            local reward = rewards[itemId]
            if not reward then
                local itemCfg = Tables.itemTable[itemId]
                reward = { id = itemId, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), gainedSortId = 1, rewardTypeSortId = 2, gained = false, }
                rewards[itemId] = reward
            end
        end
    end
end
AdventureDungeonCtrl._ProcessDungeonRewardsNoMerge = HL.Method(HL.String, HL.Table) << function(self, dungeonId, rewards)
    local dungeonMgr = GameInstance.dungeonManager
    local gameMechanicCfg = Tables.gameMechanicTable[dungeonId]
    local hasFirstReward = not string.isEmpty(gameMechanicCfg.firstPassRewardId)
    local hasRecycleReward = not string.isEmpty(gameMechanicCfg.rewardId)
    local hasExtraReward = not string.isEmpty(gameMechanicCfg.extraRewardId)
    if hasFirstReward then
        local firstRewardGained = dungeonMgr:IsDungeonRewardGained(dungeonId)
        local hideFirstReward = firstRewardGained and hasRecycleReward
        if not hideFirstReward then
            local rewardsCfg = Tables.rewardTable[gameMechanicCfg.firstPassRewardId]
            for _, itemBundle in pairs(rewardsCfg.itemBundles) do
                local itemCfg = Tables.itemTable[itemBundle.id]
                local reward = { id = itemBundle.id, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), isFirst = true, isExtra = false, gainedSortId = firstRewardGained and 1 or 2, rewardTypeSortId = 3, gained = firstRewardGained, }
                table.insert(rewards, reward)
            end
        end
    end
    if hasRecycleReward then
        local rewardsCfg = Tables.rewardTable[gameMechanicCfg.rewardId]
        for _, itemBundle in pairs(rewardsCfg.itemBundles) do
            local itemCfg = Tables.itemTable[itemBundle.id]
            local reward = { id = itemBundle.id, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), isFirst = false, isExtra = false, gainedSortId = 1, rewardTypeSortId = 1, gained = false, }
            table.insert(rewards, reward)
        end
    end
    if hasExtraReward then
        local extraRewardGained = dungeonMgr:IsDungeonExtraRewardGained(dungeonId)
        local hideExtraReward = extraRewardGained and hasRecycleReward
        if not hideExtraReward then
            local rewardsCfg = Tables.rewardTable[gameMechanicCfg.extraRewardId]
            for _, itemBundle in pairs(rewardsCfg.itemBundles) do
                local itemCfg = Tables.itemTable[itemBundle.id]
                local reward = { id = itemBundle.id, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), isFirst = false, isExtra = true, gainedSortId = extraRewardGained and 1 or 2, rewardTypeSortId = 2, gained = extraRewardGained, }
                table.insert(rewards, reward)
            end
        end
    end
end
AdventureDungeonCtrl._ProcessMonsterSpawnRewards = HL.StaticMethod(HL.String).Return(HL.Table) << function(gameId)
    local displayCfg = Tables.worldGameMechanicsDisplayInfoTable[gameId]
    local rewards = {}
    local rewardList = {}
    rewards = {}
    local hasCycleReward = false
    local sceneGrade = GameInstance.player.mapManager:GetSceneGrade(displayCfg.sceneId)
    if (sceneGrade <= #displayCfg.diffGradeItemList) then
        local itemList = displayCfg.diffGradeItemList[CSIndex(sceneGrade)]
        for _, itemId in pairs(itemList.ids) do
            local reward = rewards[itemId]
            local hasCfg, itemCfg = Tables.itemTable:TryGetValue(itemId)
            if (not reward and hasCfg) then
                reward = { id = itemId, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), isFirst = false, isExtra = false, gainedSortId = 2, rewardTypeSortId = 1, gained = false, }
                rewards[itemId] = reward
                hasCycleReward = true
            end
        end
    end
    local hasFirstReward = not string.isEmpty(displayCfg.firstPassRewardId)
    if hasFirstReward then
        local firstRewardGained = GameInstance.player.subGameSys:IsGamePassed(gameId)
        local hasCfg, rewardsCfg = Tables.rewardTable:TryGetValue(displayCfg.firstPassRewardId)
        local needHide = firstRewardGained and hasCycleReward
        if hasCfg and not needHide then
            for _, itemBundle in pairs(rewardsCfg.itemBundles) do
                local itemId = itemBundle.id
                local reward = rewards[itemId]
                if not reward then
                    local itemCfg = Tables.itemTable[itemId]
                    reward = { id = itemId, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), isFirst = true, isExtra = false, gainedSortId = firstRewardGained and 1 or 2, rewardTypeSortId = 2, gained = firstRewardGained, }
                    rewards[itemId] = reward
                end
            end
        end
    end
    for _, v in pairs(rewards) do
        table.insert(rewardList, v)
    end
    table.sort(rewardList, Utils.genSortFunction({ "gainedSortId", "rewardTypeSortId", "rarity", "type" }))
    return rewardList
end
HL.Commit(AdventureDungeonCtrl)