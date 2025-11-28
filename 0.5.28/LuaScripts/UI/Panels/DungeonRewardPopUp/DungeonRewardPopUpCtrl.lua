local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.DungeonRewardPopUp
DungeonRewardPopUpCtrl = HL.Class('DungeonRewardPopUpCtrl', uiCtrl.UICtrl)
DungeonRewardPopUpCtrl.s_messages = HL.StaticField(HL.Table) << {}
DungeonRewardPopUpCtrl.m_dungeonId = HL.Field(HL.Any)
DungeonRewardPopUpCtrl.m_normalRewardCells = HL.Field(HL.Forward("UIListCache"))
DungeonRewardPopUpCtrl.m_probRewardCells = HL.Field(HL.Forward("UIListCache"))
DungeonRewardPopUpCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_dungeonId = arg.dungeonId
    self.view.closeBtn.onClick:AddListener(function()
        self:_DoClose()
    end)
    self.view.bg.onClick:AddListener(function()
        self:_DoClose()
    end)
    self.m_normalRewardCells = UIUtils.genCellCache(self.view.normalRewardCell)
    self.m_probRewardCells = UIUtils.genCellCache(self.view.probRewardCell)
    local firstPartRewards = self:_ProcessFirstPartReward()
    self.view.normalNode.gameObject:SetActive(#firstPartRewards > 0)
    self.m_normalRewardCells:Refresh(#firstPartRewards, function(rewardCell, luaIdx)
        rewardCell.item:InitItem(firstPartRewards[luaIdx], true)
        rewardCell.getNode.gameObject:SetActive(firstPartRewards[luaIdx].done)
    end)
    local secondPartRewards = self:_ProcessSecondPartReward()
    self.view.probNode.gameObject:SetActive(#secondPartRewards > 0)
    self.m_probRewardCells:Refresh(#secondPartRewards, function(rewardCell, luaIdx)
        rewardCell.item:InitItem(secondPartRewards[luaIdx], true)
        rewardCell.getNode.gameObject:SetActive(secondPartRewards[luaIdx].done)
    end)
end
DungeonRewardPopUpCtrl._ProcessFirstPartReward = HL.Method().Return(HL.Table) << function(self)
    local _, dungeonInfo = Tables.gameMechanicTable:TryGetValue(self.m_dungeonId)
    local rewardItemBundles = {}
    if dungeonInfo then
        local rewardId = dungeonInfo.gameCategory == Tables.dungeonConst.dungeonFactoryCategory and dungeonInfo.firstPassRewardId or dungeonInfo.rewardId
        local findReward, rewardData = Tables.rewardTable:TryGetValue(rewardId)
        if findReward then
            for _, itemBundle in pairs(rewardData.itemBundles) do
                local done = GameInstance.dungeonManager:IsDungeonRewardGained(self.m_dungeonId)
                local _, itemData = Tables.itemTable:TryGetValue(itemBundle.id)
                if itemData and itemBundle.count > 0 then
                    table.insert(rewardItemBundles, { id = itemBundle.id, count = itemBundle.count, rarity = itemData.rarity, type = itemData.type:ToInt(), done = done })
                else
                    logger.error("itemId is not found: " .. itemBundle.id)
                end
            end
        end
        table.sort(rewardItemBundles, Utils.genSortFunction({ "rarity", "type", "id" }, false))
    end
    return rewardItemBundles
end
DungeonRewardPopUpCtrl._ProcessSecondPartReward = HL.Method().Return(HL.Table) << function(self)
    local _, dungeonGameMechData = Tables.gameMechanicTable:TryGetValue(self.m_dungeonId)
    local rewardItemBundles = {}
    if dungeonGameMechData then
        if not string.isEmpty(dungeonGameMechData.extraRewardId) then
            local findReward, rewardData = Tables.rewardTable:TryGetValue(dungeonGameMechData.extraRewardId or "")
            local completed = GameInstance.dungeonManager:IsDungeonExtraRewardGained(self.m_dungeonId)
            if findReward then
                for _, itemBundle in pairs(rewardData.itemBundles) do
                    local _, itemData = Tables.itemTable:TryGetValue(itemBundle.id)
                    if itemData then
                        table.insert(rewardItemBundles, { id = itemBundle.id, count = itemBundle.count, rarity = itemData.rarity, type = itemData.type:ToInt(), done = completed })
                    else
                        logger.error("itemId is not found: " .. itemBundle.id)
                    end
                end
            end
        else
            local success, dungeonData = Tables.dungeonTable:TryGetValue(self.m_dungeonId)
            if success and dungeonData.probRewardItemIds.Count > 0 then
                local count = dungeonData.probRewardItemIds.Count
                local completed = GameInstance.dungeonManager:IsDungeonPassed(self.m_dungeonId)
                for i = 1, count do
                    local itemId = dungeonData.probRewardItemIds[CSIndex(i)]
                    local _, itemData = Tables.itemTable:TryGetValue(itemId)
                    if itemData then
                        table.insert(rewardItemBundles, { id = itemId, rarity = itemData.rarity, type = itemData.type:ToInt(), done = completed })
                    else
                        logger.error("itemId is not found: " .. itemId)
                    end
                end
            end
        end
        table.sort(rewardItemBundles, Utils.genSortFunction({ "rarity", "type", "id" }, false))
    end
    return rewardItemBundles
end
DungeonRewardPopUpCtrl._DoClose = HL.Method() << function(self)
    self:PlayAnimationOut(UIConst.PANEL_PLAY_ANIMATION_OUT_COMPLETE_ACTION_TYPE.Close)
end
DungeonRewardPopUpCtrl.OnShow = HL.Override() << function(self)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
DungeonRewardPopUpCtrl.OnAnimationInFinished = HL.Override() << function(self)
    InputManagerInst:MoveVirtualMouseTo(self.view.itemCellRect.transform, self.uiCamera)
end
HL.Commit(DungeonRewardPopUpCtrl)