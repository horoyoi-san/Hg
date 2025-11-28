local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.MapMarkDetailRecycler
MapMarkDetailRecyclerCtrl = HL.Class('MapMarkDetailRecyclerCtrl', uiCtrl.UICtrl)
MapMarkDetailRecyclerCtrl.s_messages = HL.StaticField(HL.Table) << {}
MapMarkDetailRecyclerCtrl.m_rewardItemCache = HL.Field(HL.Forward('UIListCache'))
MapMarkDetailRecyclerCtrl.MAX_SCENE_GRADE = HL.Field(HL.Number) << 4
MapMarkDetailRecyclerCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_rewardItemCache = UIUtils.genCellCache(self.view.itemReward)
    local markInstId = args.markInstId
    local commonArgs = {}
    commonArgs.bigBtnActive = true
    commonArgs.markInstId = markInstId
    self.view.detailCommon:InitMapMarkDetailCommon(commonArgs)
    local markInstId = args.markInstId
    local getRuntimeDataSuccess, markRuntimeData = GameInstance.player.mapManager:GetMarkInstRuntimeData(markInstId)
    if getRuntimeDataSuccess == false then
        logger.error("地图详情页获取实例数据失败" .. self.m_instId)
        return
    end
    local detail = markRuntimeData.detail
    local _, doodadData = Tables.doodadGeneralTable:TryGetValue(detail.doodadId)
    local csListRewardIdList = doodadData.pickableRewardId
    local sceneGrade = GameInstance.player.mapManager:GetSceneGrade(markRuntimeData.levelId)
    local rewardId = csListRewardIdList[CSIndex(sceneGrade)]
    local itemBundleList = self:_GetRewardIdItems(rewardId)
    self.m_rewardItemCache:Refresh(#itemBundleList, function(itemCell, index)
        itemCell:InitItem(itemBundleList[index], true)
        itemCell.view.rewardedCover.gameObject:SetActive(false)
    end)
    self.view.detailItemsBtn.onClick:AddListener(function()
        local itemLists = {}
        for i = 1, self.MAX_SCENE_GRADE do
            local itemList = self:_GetRewardIdItems(csListRewardIdList[CSIndex(i)])
            table.insert(itemLists, itemList)
        end
        PhaseManager:OpenPhase(PhaseId.SceneGradeDifferenceItemPopUp, { itemLists = itemLists, sceneGrade = sceneGrade, titleText = Language.LUA_RECYCLER_MAP_DETAIL_POP_UP_TITLE, })
    end)
end
MapMarkDetailRecyclerCtrl._GetRewardIdItems = HL.Method(HL.String).Return(HL.Table) << function(self, rewardId)
    local rewardItemBundles = {}
    local findReward, rewardData = Tables.rewardTable:TryGetValue(rewardId or "")
    if findReward then
        for _, itemBundle in pairs(rewardData.itemBundles) do
            local itemCfg = Tables.itemTable[itemBundle.id]
            table.insert(rewardItemBundles, { id = itemBundle.id, count = itemBundle.count, rarity = itemCfg.rarity, type = itemCfg.type:ToInt(), })
        end
    end
    local rewardItemCount = #rewardItemBundles
    if rewardItemCount == 0 then
        self.view.reward.gameObject:SetActive(false)
        return
    end
    table.sort(rewardItemBundles, Utils.genSortFunction({ "rarity", "type" }, false))
    return rewardItemBundles
end
HL.Commit(MapMarkDetailRecyclerCtrl)