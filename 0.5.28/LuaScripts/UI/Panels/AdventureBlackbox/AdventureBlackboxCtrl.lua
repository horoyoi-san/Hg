local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.AdventureBlackbox
AdventureBlackboxCtrl = HL.Class('AdventureBlackboxCtrl', uiCtrl.UICtrl)
AdventureBlackboxCtrl.s_messages = HL.StaticField(HL.Table) << {}
AdventureBlackboxCtrl.m_genTabCells = HL.Field(HL.Forward("UIListCache"))
AdventureBlackboxCtrl.m_tabInfos = HL.Field(HL.Table)
AdventureBlackboxCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_genTabCells = UIUtils.genCellCache(self.view.tabCell)
    self:_UpdateData()
    self:_RefreshAllUI()
end
AdventureBlackboxCtrl._UpdateData = HL.Method() << function(self)
    self.m_tabInfos = {}
    for _, cfg in pairs(Tables.domainDataTable) do
        local canShow = true
        local hasCfg, facCfg = Tables.facSTTGroupTable:TryGetValue(cfg.facTechPackageId)
        if not hasCfg then
            logger.error("[Domain Data Table] missing, id = " .. cfg.facTechPackageId)
            canShow = false
        end
        if canShow then
            local isLock = GameInstance.player.facTechTreeSystem:PackageIsLocked(cfg.facTechPackageId)
            if not isLock then
                isLock = GameInstance.player.facTechTreeSystem:PackageIsHidden(cfg.facTechPackageId)
            end
            local info
            if isLock then
                info = { sortId = cfg.sortId, isLock = true, }
            else
                local rewardList = AdventureBlackboxCtrl._GetBlackboxRewardList(facCfg.blackboxIds)
                local passedCount = AdventureBlackboxCtrl._GetBlackboxPassedCount(facCfg.blackboxIds)
                local maxCount = #facCfg.blackboxIds
                info = { sortId = cfg.sortId, icon = cfg.domainBlackboxIcon, bg = cfg.domainBlackboxPic, title = cfg.domainName, color = cfg.domainColor, rewardList = rewardList, packageId = cfg.facTechPackageId, isLock = false, curCount = passedCount, targetCount = maxCount, }
            end
            table.insert(self.m_tabInfos, info)
        end
    end
    table.sort(self.m_tabInfos, Utils.genSortFunction({ "sortId" }, true))
end
AdventureBlackboxCtrl._RefreshAllUI = HL.Method() << function(self)
    self.m_genTabCells:Refresh(#self.m_tabInfos, function(cell, luaIndex)
        local info = self.m_tabInfos[luaIndex]
        cell:InitAdventureBlackboxTabCell(info)
    end)
end
AdventureBlackboxCtrl._GetBlackboxPassedCount = HL.StaticMethod(HL.Any).Return(HL.Number) << function(blackboxIds)
    local count = 0
    for _, id in pairs(blackboxIds) do
        if GameInstance.dungeonManager:IsDungeonPassed(id) then
            count = count + 1
        end
    end
    return count
end
AdventureBlackboxCtrl._GetBlackboxRewardList = HL.StaticMethod(HL.Any).Return(HL.Table) << function(blackboxIds)
    local rewards = {}
    for _, id in pairs(blackboxIds) do
        AdventureBlackboxCtrl._ProcessBlackboxRewards(id, rewards)
    end
    local rewardList = {}
    for _, v in pairs(rewards) do
        table.insert(rewardList, v)
    end
    table.sort(rewardList, Utils.genSortFunction({ "rarity", "type" }))
    return rewardList
end
AdventureBlackboxCtrl._ProcessBlackboxRewards = HL.StaticMethod(HL.String, HL.Table) << function(dungeonId, rewards)
    local hasCfg, gameMechanicCfg = Tables.gameMechanicTable:TryGetValue(dungeonId)
    if not hasCfg then
        logger.error("[Game Mechanic Table] missing dungeon, id = " .. dungeonId)
        return
    end
    local hasFirstReward = not string.isEmpty(gameMechanicCfg.firstPassRewardId)
    if hasFirstReward then
        AdventureBlackboxCtrl._MergeReward(gameMechanicCfg.firstPassRewardId, rewards)
    end
    local hasRecycleReward = not string.isEmpty(gameMechanicCfg.rewardId)
    if hasRecycleReward then
        AdventureBlackboxCtrl._MergeReward(gameMechanicCfg.rewardId, rewards)
    end
    local hasExtraReward = not string.isEmpty(gameMechanicCfg.extraRewardId)
    if hasExtraReward then
        AdventureBlackboxCtrl._MergeReward(gameMechanicCfg.extraRewardId, rewards)
    end
end
AdventureBlackboxCtrl._MergeReward = HL.StaticMethod(HL.String, HL.Table) << function(rewardId, rewards)
    local hasCfg, rewardsCfg = Tables.rewardTable:TryGetValue(rewardId)
    if not hasCfg then
        logger.error("[Reward Table] missing, id = " .. rewardId)
        return
    end
    for _, itemBundle in pairs(rewardsCfg.itemBundles) do
        local reward = rewards[itemBundle.id]
        if not reward then
            local itemCfg
            hasCfg, itemCfg = Tables.itemTable:TryGetValue(itemBundle.id)
            if hasCfg then
                reward = { id = itemBundle.id, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), }
                rewards[itemBundle.id] = reward
            else
                logger.error("[Item Table] missing, id = " .. itemBundle.id)
                return
            end
        end
    end
end
HL.Commit(AdventureBlackboxCtrl)