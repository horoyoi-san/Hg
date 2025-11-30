local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RewardsPopUpForBlackBox
RewardsPopUpForBlackBoxCtrl = HL.Class('RewardsPopUpForBlackBoxCtrl', uiCtrl.UICtrl)
RewardsPopUpForBlackBoxCtrl.m_isAnimationIn = HL.Field(HL.Boolean) << false
RewardsPopUpForBlackBoxCtrl.s_messages = HL.StaticField(HL.Table) << {}
RewardsPopUpForBlackBoxCtrl.m_items = HL.Field(HL.Table)
RewardsPopUpForBlackBoxCtrl.m_getItemCells = HL.Field(HL.Function)
RewardsPopUpForBlackBoxCtrl.m_failPointCells = HL.Field(HL.Forward("UIListCache"))
RewardsPopUpForBlackBoxCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_getItemCells = UIUtils.genCachedCellFunction(self.view.rewardsScrollList)
    self.m_failPointCells = UIUtils.genCellCache(self.view.pointCell)
    self.view.rewardsScrollList.onUpdateCell:AddListener(function(object, csIndex)
        local cell = self.m_getItemCells(object)
        self:_OnUpdateCell(cell, LuaIndex(csIndex))
    end)
    self.view.leaveDungeonBtn.onClick:AddListener(function()
        self:_OnLeaveDungeonBtnClick()
    end)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
    self.m_isAnimationIn = true
end
RewardsPopUpForBlackBoxCtrl.OnShowBlackboxResult = HL.StaticMethod(HL.Any) << function(args)
    local dungeonId, levelTimestamp, isFail, failReason = unpack(args)
    local ctrl = UIManager:AutoOpen(PANEL_ID)
    ctrl:UpdateContent(dungeonId, levelTimestamp, isFail, failReason)
end
RewardsPopUpForBlackBoxCtrl.UpdateContent = HL.Method(HL.String, HL.Number, HL.Boolean, HL.Opt(HL.Table)) << function(self, dungeonId, leaveTimestamp, isFail, failReason)
    local _, dungeonGameMechData = Tables.gameMechanicTable:TryGetValue(dungeonId)
    if dungeonGameMechData then
        local canReChallenge = isFail
        if canReChallenge then
            self.view.restartDungeonBtn.onClick:AddListener(function()
                local cntStamina = GameInstance.player.inventory.curStamina
                if cntStamina < dungeonGameMechData.costStamina then
                    Notify(MessageConst.SHOW_TOAST, Language.LUA_NOT_ENOUGH_STAMINA_HINT)
                    return
                end
                self:PlayAnimationOutWithCallback(function()
                    GameInstance.dungeonManager:RestartDungeon(dungeonId)
                    self:Close()
                end)
            end)
        end
        self.view.restartDungeonBtn.gameObject:SetActive(canReChallenge)
    end
    self:_StartCoroutine(function()
        local seconds = math.floor(leaveTimestamp - CS.Beyond.DateTimeUtils.GetCurrentTimestampBySeconds())
        while seconds > 0 do
            local leaveTxt = tostring(seconds) .. Language.LUA_LEAVE_DUNGEON_TEXT
            self.view.leaveTxt.text = leaveTxt
            coroutine.wait(1)
            seconds = seconds - 1
        end
        self:_OnLeaveDungeonBtnClick()
    end)
    local animWrapper = self:GetAnimationWrapper()
    if isFail then
        local success, dungeonData = Tables.dungeonTable:TryGetValue(dungeonId)
        local featureDesc = dungeonData and dungeonData.featureDesc or ""
        local contentTxt = string.isEmpty(featureDesc) and {} or string.split(featureDesc, "\n")
        self.m_failPointCells:Refresh(#contentTxt, function(cell, index)
            cell.label.text = UIUtils.resolveTextStyle(contentTxt[index])
        end)
        self.view.failReasonTxt.text = UIUtils.resolveTextStyle(failReason)
        animWrapper:Play("rewardspopupforblackbox_fail", function()
            self.m_isAnimationIn = false
            animWrapper:Play("rewardspopupforblackbox_failloop")
        end)
    else
        local rewardPack = GameInstance.player.inventory:ConsumeLatestRewardPackOfType(CS.Beyond.GEnums.RewardSourceType.Dungeon)
        if rewardPack and rewardPack.rewardSourceType == CS.Beyond.GEnums.RewardSourceType.Dungeon then
            local items = {}
            local count = 0
            for _, itemBundle in pairs(rewardPack.itemBundleList) do
                local _, itemData = Tables.itemTable:TryGetValue(itemBundle.id)
                if itemData then
                    table.insert(items, { id = itemBundle.id, count = itemBundle.count, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2 })
                end
            end
            table.sort(items, Utils.genSortFunction(UIConst.COMMON_ITEM_SORT_KEYS))
            count = #items
            self.m_items = items
            self.view.rewardsScrollList.gameObject:SetActiveIfNecessary(false)
            self.view.rewardsScrollList:UpdateCount(count, true)
        end
        animWrapper:Play("rewardspopupforblackbox_in", function()
            self.m_isAnimationIn = false
            animWrapper:Play("rewardspopupforblackbox_inloop")
        end)
    end
end
RewardsPopUpForBlackBoxCtrl._OnUpdateCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local itemBundle = self.m_items[index]
    cell:InitItem(itemBundle, true)
    UIUtils.setRewardItemRarityGlow(cell, UIUtils.getItemRarity(itemBundle.id))
end
RewardsPopUpForBlackBoxCtrl._OnLeaveDungeonBtnClick = HL.Method() << function(self)
    if self.m_isAnimationIn then
        return
    end
    self:Notify(MessageConst.HIDE_ITEM_TIPS)
    GameInstance.dungeonManager:LeaveDungeon()
end
RewardsPopUpForBlackBoxCtrl.OnShow = HL.Override() << function(self)
    Notify(MessageConst.ON_ENTER_BLOCKED_REWARD_POP_UP_PANEL)
end
RewardsPopUpForBlackBoxCtrl.OnHide = HL.Override() << function(self)
    Notify(MessageConst.ON_EXIT_BLOCKED_REWARD_POP_UP_PANEL)
end
RewardsPopUpForBlackBoxCtrl.OnClose = HL.Override() << function(self)
    Notify(MessageConst.ON_EXIT_BLOCKED_REWARD_POP_UP_PANEL)
end
HL.Commit(RewardsPopUpForBlackBoxCtrl)