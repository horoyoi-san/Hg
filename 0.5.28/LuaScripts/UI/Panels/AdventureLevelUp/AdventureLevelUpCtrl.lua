local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.AdventureLevelUp
local MAIN_HUD_TOAST_TYPE = "AdventureLevelUp"
AdventureLevelUpCtrl = HL.Class('AdventureLevelUpCtrl', uiCtrl.UICtrl)
AdventureLevelUpCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.INTERRUPT_MAIN_HUD_TOAST] = 'InterruptMainHudToast', }
AdventureLevelUpCtrl.m_genRecipeCells = HL.Field(HL.Forward("UIListCache"))
AdventureLevelUpCtrl.m_genRewardCells = HL.Field(HL.Forward("UIListCache"))
AdventureLevelUpCtrl.m_levelUpInfoQueue = HL.Field(HL.Forward("Queue"))
AdventureLevelUpCtrl.m_aniQueue = HL.Field(HL.Forward("Queue"))
AdventureLevelUpCtrl.m_aniPlayInfo = HL.Field(HL.Table)
AdventureLevelUpCtrl.m_clearScreenKey = HL.Field(HL.Number) << -1
AdventureLevelUpCtrl.m_isWorldFreeze = HL.Field(HL.Boolean) << false
AdventureLevelUpCtrl.IsWaitOpen = HL.StaticField(HL.Boolean) << false
AdventureLevelUpCtrl.m_inputBindKeyExit = HL.Field(HL.Number) << -1
AdventureLevelUpCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.continueBtn.onClick:AddListener(function()
        self:_TryPlayUpgrade()
    end)
    self.m_genRecipeCells = UIUtils.genCellCache(self.view.rewardToast.recipeCell)
    self.m_genRewardCells = UIUtils.genCellCache(self.view.rewardToast.rewardCell)
    self.m_levelUpInfoQueue = require_ex("Common/Utils/DataStructure/Queue")()
    self.m_aniQueue = require_ex("Common/Utils/DataStructure/Queue")()
end
AdventureLevelUpCtrl.OnShowAdventureLevelUp = HL.StaticMethod(HL.Any) << function(arg)
    if AdventureLevelUpCtrl.IsWaitOpen then
        return
    end
    AdventureLevelUpCtrl.IsWaitOpen = true
    local preLv, preExp = unpack(arg)
    LuaSystemManager.mainHudToastSystem:AddRequest(MAIN_HUD_TOAST_TYPE, function()
        local self = UIManager:AutoOpen(PANEL_ID)
        self:_StartShow(preLv, preExp)
        AdventureLevelUpCtrl.IsWaitOpen = false
    end)
end
AdventureLevelUpCtrl.InterruptMainHudToast = HL.Method() << function(self)
    self:GetAnimationWrapper():ClearTween(false)
    self:_ClearCache()
    self:Close()
end
AdventureLevelUpCtrl._UpdateData = HL.Method(HL.Number, HL.Number) << function(self, preLv, preExp)
    local adventureData = GameInstance.player.adventure.adventureLevelData
    local totalTargetLv = adventureData.lv
    local totalTargetExp = adventureData.exp
    for level = preLv, totalTargetLv do
        local curLvCfg = Tables.adventureLevelTable[level]
        local curExp = level == preLv and preExp - curLvCfg.levelUpExp or 0
        local totalAddExp = level == preLv and totalTargetExp - preExp or -1
        local curLvMaxExp = curLvCfg.nextLevelUpExp - curLvCfg.levelUpExp
        if level == totalTargetLv then
            local isMaxLevel = level == adventureData.maxLv
            local targetExp = totalTargetExp - curLvCfg.levelUpExp
            if isMaxLevel then
                curExp = curLvCfg.levelUpExp
                targetExp = curExp
                curLvMaxExp = targetExp
            end
            self.m_levelUpInfoQueue:Push({ curLv = level, targetLv = level, curExp = curExp, targetExp = targetExp, maxExp = curLvMaxExp, totalAddExp = totalAddExp, isLevelUp = false, isMaxLevel = isMaxLevel, raiseStamina = 0, recipeItemInfos = nil, rewardItemInfos = nil, })
        else
            local targetLvCfg = Tables.adventureLevelTable[level + 1]
            local recipeItemInfos, rewardItemInfos = self:_ProcessLevelUpReward(targetLvCfg.rewardId)
            self.m_levelUpInfoQueue:Push({ curLv = level, targetLv = level + 1, curExp = curExp, targetExp = targetLvCfg.levelUpExp - curLvCfg.levelUpExp, maxExp = curLvMaxExp, totalAddExp = totalAddExp, isLevelUp = true, isMaxLevel = false, raiseStamina = targetLvCfg.raiseMaxStamina, recipeItemInfos = recipeItemInfos, rewardItemInfos = rewardItemInfos, })
        end
    end
end
AdventureLevelUpCtrl._ProcessLevelUpReward = HL.Method(HL.String).Return(HL.Table, HL.Table) << function(self, rewardId)
    local recipeItemInfos = {}
    local rewardItemInfos = {}
    local rewardsCfg = Tables.rewardTable[rewardId]
    for _, itemBundle in pairs(rewardsCfg.itemBundles) do
        local itemCfg = Tables.itemTable[itemBundle.id]
        local count = itemBundle.count
        local rarity = itemCfg.rarity
        local type = itemCfg.type
        local info = { id = itemBundle.id, count = count, rarity = rarity, type = type, sortId1 = itemCfg.sortId1, sortId2 = itemCfg.sortId2, }
        if type == GEnums.ItemType.EquipFormula then
            table.insert(recipeItemInfos, info)
        else
            table.insert(rewardItemInfos, info)
        end
    end
    table.sort(recipeItemInfos, Utils.genSortFunction(UIConst.COMMON_ITEM_SORT_KEYS, true))
    table.sort(rewardItemInfos, Utils.genSortFunction(UIConst.COMMON_ITEM_SORT_KEYS, true))
    return recipeItemInfos, rewardItemInfos
end
AdventureLevelUpCtrl._ClearCache = HL.Method() << function(self)
    if self.m_aniPlayInfo and self.m_aniPlayInfo.updateKey > 0 then
        LuaUpdate:Remove(self.m_aniPlayInfo.updateKey)
    end
    self:_ClearOrRecoverScreen(false)
    self:_SetFreezeWorld(false)
    self.m_aniPlayInfo = nil
    self.m_levelUpInfoQueue:Clear()
    self.m_aniQueue:Clear()
end
AdventureLevelUpCtrl._StartShow = HL.Method(HL.Number, HL.Number) << function(self, preLv, preExp)
    self:_UpdateData(preLv, preExp)
    self:_TryPlayUpgrade()
end
AdventureLevelUpCtrl._TryPlayUpgrade = HL.Method() << function(self)
    if self.m_levelUpInfoQueue:Count() <= 0 then
        self:_CompleteCloseSelf()
        return
    end
    local lvUpInfo = self.m_levelUpInfoQueue:Pop()
    self.m_aniPlayInfo = { basicInfo = lvUpInfo, updateKey = -1, curLvGainExp = lvUpInfo.targetExp - lvUpInfo.curExp, curTickTime = 0, totalTime = self.view.config.PROGRESS_INCREASE_ANI_DURATION, }
    if lvUpInfo.isLevelUp then
        if BEYOND_DEBUG_COMMAND then
            self.m_inputBindKeyExit = self:BindInputPlayerAction("common_cancel", function()
                self:_CompleteCloseSelf()
            end)
        end
        self:_ClearOrRecoverScreen(true)
        self:_StartPlayLevelUpAni()
        GameInstance.player.guide:OnAdventureLevelUpShow()
    else
        self:_StartPlayNotLevelUpAni()
    end
end
AdventureLevelUpCtrl._StartPlayLevelUpAni = HL.Method() << function(self)
    if self.m_aniPlayInfo == nil or self.m_aniPlayInfo.basicInfo == nil then
        self:_CompleteCloseSelf()
        return
    end
    local lvUpInfo = self.m_aniPlayInfo.basicInfo
    local viewRef = self.view
    local upgradeView = self.view.upgradeToast
    viewRef.upgradeToast.gameObject:SetActiveIfNecessary(true)
    viewRef.rewardToast.gameObject:SetActiveIfNecessary(false)
    viewRef.blurWithUI.gameObject:SetActiveIfNecessary(true)
    self:ChangePanelCfg("blockKeyboardEvent", true)
    self:ChangePanelCfg("realMouseMode", Types.EPanelMouseMode.NeedShow)
    self:_SetFreezeWorld(true)
    self:_UpdateUIProgress(upgradeView.progressNode, lvUpInfo.curExp, lvUpInfo.targetExp, lvUpInfo.maxExp)
    upgradeView.curLvTxt.text = lvUpInfo.curLv
    upgradeView.targetLvTxt.text = lvUpInfo.targetLv
    local showTotalAddExp = lvUpInfo.totalAddExp > 0
    if showTotalAddExp then
        upgradeView.diffExpTxt.text = "+" .. lvUpInfo.totalAddExp
        upgradeView.diffExpNode.gameObject:SetActiveIfNecessary(true)
    else
        upgradeView.diffExpNode.gameObject:SetActiveIfNecessary(false)
    end
    AudioManager.PostEvent("Au_UI_Menu_AdventureLevelUpPanel_B_Open")
    local aniWrapper = self:GetAnimationWrapper()
    aniWrapper:PlayWithTween("adventurelevelup_upgradetoast_levelup_init", function()
        AudioManager.PostEvent("Au_UI_Event_Count")
        if showTotalAddExp then
            upgradeView.aniWrapper:PlayWithTween("adventurelevelup_diffexptext_out")
        end
        self.m_aniPlayInfo.updateKey = LuaUpdate:Add("Tick", function(deltaTime)
            self:_OnUpdateLevelUpProgressAni(deltaTime)
        end)
    end)
end
AdventureLevelUpCtrl._OnUpdateLevelUpProgressAni = HL.Method(HL.Number) << function(self, deltaTime)
    local playInfo = self.m_aniPlayInfo
    local lvUpInfo = playInfo.basicInfo
    playInfo.curTickTime = playInfo.curTickTime + deltaTime
    if playInfo.curTickTime >= playInfo.totalTime then
        self:_OnEndLevelUpProgressAni()
        return
    end
    local progressNode = self.view.upgradeToast.progressNode
    local timeProg = self.view.config.PROGRESSIVE_CURVE:Evaluate(playInfo.curTickTime / playInfo.totalTime)
    local curTickExp = timeProg * playInfo.curLvGainExp + lvUpInfo.curExp
    self:_UpdateUIProgress(progressNode, math.floor(curTickExp), lvUpInfo.targetExp, lvUpInfo.maxExp)
end
AdventureLevelUpCtrl._OnEndLevelUpProgressAni = HL.Method() << function(self)
    if self.m_aniPlayInfo == nil or self.m_aniPlayInfo.basicInfo == nil then
        self:_CompleteCloseSelf()
        return
    end
    local aniWrapper = self:GetAnimationWrapper()
    local targetExp = self.m_aniPlayInfo.basicInfo.targetExp
    self:_UpdateUIProgress(self.view.upgradeToast.progressNode, targetExp, targetExp, self.m_aniPlayInfo.basicInfo.maxExp)
    LuaUpdate:Remove(self.m_aniPlayInfo.updateKey)
    self.m_aniPlayInfo.updateKey = -1
    logger.info("LevelUp Start Play Levelup")
    AudioManager.PostEvent("Au_UI_Event_AdventureLevelUp")
    aniWrapper:PlayWithTween("adventurelevelup_upgradetoast_levelup", function()
        logger.info("LevelUp Start Play Reward")
        self:_PlayReward()
    end)
end
AdventureLevelUpCtrl._StartPlayNotLevelUpAni = HL.Method() << function(self)
    if BEYOND_DEBUG_COMMAND then
        if self.m_inputBindKeyExit >= 0 then
            self:DeleteInputBinding(self.m_inputBindKeyExit)
            self.m_inputBindKeyExit = -1
        end
    end
    if self.m_aniPlayInfo == nil or self.m_aniPlayInfo.basicInfo == nil then
        self:_CompleteCloseSelf()
        return
    end
    local lvUpInfo = self.m_aniPlayInfo.basicInfo
    local viewRef = self.view
    local rewardToast = self.view.rewardToast
    viewRef.upgradeToast.gameObject:SetActiveIfNecessary(false)
    viewRef.continueBtnNode.gameObject:SetActiveIfNecessary(false)
    viewRef.blurWithUI.gameObject:SetActiveIfNecessary(false)
    rewardToast.gameObject:SetActiveIfNecessary(true)
    rewardToast.state:SetState("ShowToast")
    self:_ClearOrRecoverScreen(false)
    self:ChangePanelCfg("blockKeyboardEvent", false)
    self:ChangePanelCfg("realMouseMode", Types.EPanelMouseMode.NotNeedShow)
    self:_SetFreezeWorld(false)
    self:_UpdateUIProgress(rewardToast.progressNode, lvUpInfo.curExp, lvUpInfo.targetExp, lvUpInfo.maxExp)
    rewardToast.curLvTxt.text = lvUpInfo.curLv
    rewardToast.maxLevelText.gameObject:SetActiveIfNecessary(lvUpInfo.isMaxLevel)
    rewardToast.numProgressNode.gameObject:SetActiveIfNecessary(not lvUpInfo.isMaxLevel)
    local showTotalAddExp = lvUpInfo.totalAddExp > 0
    if showTotalAddExp then
        rewardToast.diffExpTxt.text = "+" .. lvUpInfo.totalAddExp
        rewardToast.diffExpNode.gameObject:SetActiveIfNecessary(true)
    else
        rewardToast.diffExpNode.gameObject:SetActiveIfNecessary(false)
    end
    AudioManager.PostEvent("Au_UI_Menu_AdventureLevelUpPanel_A_Open")
    local aniWrapper = self:GetAnimationWrapper()
    aniWrapper:PlayWithTween("adventurelevelup_exptoast_init", function()
        AudioManager.PostEvent("Au_UI_Event_Count")
        if showTotalAddExp then
            rewardToast.aniWrapper:PlayWithTween("adventurelevelup_exptoast_diffexptext_out")
        end
        self.m_aniPlayInfo.updateKey = LuaUpdate:Add("Tick", function(deltaTime)
            self:_OnUpdateNotLevelUpProgressAni(deltaTime)
        end)
    end)
end
AdventureLevelUpCtrl._OnUpdateNotLevelUpProgressAni = HL.Method(HL.Number) << function(self, deltaTime)
    local playInfo = self.m_aniPlayInfo
    local lvUpInfo = playInfo.basicInfo
    playInfo.curTickTime = playInfo.curTickTime + deltaTime
    if playInfo.curTickTime >= playInfo.totalTime then
        self:_OnEndNotLevelUpProgressAni()
        return
    end
    local progressNode = self.view.rewardToast.progressNode
    local timeProg = self.view.config.PROGRESSIVE_CURVE:Evaluate(playInfo.curTickTime / playInfo.totalTime)
    local curTickExp = timeProg * playInfo.curLvGainExp + lvUpInfo.curExp
    self:_UpdateUIProgress(progressNode, math.floor(curTickExp), lvUpInfo.targetExp, lvUpInfo.maxExp)
end
AdventureLevelUpCtrl._OnEndNotLevelUpProgressAni = HL.Method() << function(self)
    if self.m_aniPlayInfo == nil or self.m_aniPlayInfo.basicInfo == nil then
        self:_CompleteCloseSelf()
        return
    end
    local aniWrapper = self:GetAnimationWrapper()
    local lvUpInfo = self.m_aniPlayInfo.basicInfo
    local targetExp = lvUpInfo.targetExp
    self:_UpdateUIProgress(self.view.rewardToast.progressNode, targetExp, targetExp, lvUpInfo.maxExp)
    self.view.rewardToast.maxLevelText.gameObject:SetActiveIfNecessary(lvUpInfo.isMaxLevel)
    LuaUpdate:Remove(self.m_aniPlayInfo.updateKey)
    self.m_aniPlayInfo.updateKey = -1
    aniWrapper:PlayWithTween("adventurelevelup_exptoast_out", function()
        self:_TryPlayUpgrade()
    end)
end
AdventureLevelUpCtrl._PlayReward = HL.Method() << function(self)
    if self.m_aniPlayInfo == nil or self.m_aniPlayInfo.basicInfo == nil then
        self:_CompleteCloseSelf()
        return
    end
    local levelUpInfo = self.m_aniPlayInfo.basicInfo
    local upgradeView = self.view.upgradeToast
    local rewardView = self.view.rewardToast
    upgradeView.gameObject:SetActiveIfNecessary(false)
    rewardView.gameObject:SetActiveIfNecessary(true)
    rewardView.state:SetState("ShowReward")
    rewardView.diffExpNode.gameObject:SetActiveIfNecessary(false)
    rewardView.numProgressNode.gameObject:SetActiveIfNecessary(false)
    self.view.continueBtnNode.gameObject:SetActiveIfNecessary(false)
    self.m_aniQueue:Push({ aniName = "adventurelevelup_rewardtoast_in" })
    rewardView.curLvTxt.text = levelUpInfo.targetLv
    rewardView.staminaRewardNode.gameObject:SetActiveIfNecessary(false)
    if levelUpInfo.raiseStamina > 0 then
        local curStamina = Utils.getStaminaLimit(levelUpInfo.curLv)
        local targetStamina = curStamina + levelUpInfo.raiseStamina
        rewardView.curStaminaTxt.text = curStamina
        rewardView.targetStaminaTxt.text = targetStamina
        self.m_aniQueue:Push({ targetObj = rewardView.staminaRewardNode.gameObject, aniName = "adventurelevelup_rewardtoast_stamina_in", voice = "Au_UI_Event_AdventureReward", })
    end
    local count = #levelUpInfo.recipeItemInfos
    rewardView.recipeRewardNode.gameObject:SetActiveIfNecessary(false)
    if count > 0 then
        self.m_genRecipeCells:Refresh(count, function(cell, luaIndex)
            local info = levelUpInfo.recipeItemInfos[luaIndex]
            cell:InitItem(info, true)
        end)
        self.m_aniQueue:Push({ targetObj = rewardView.recipeRewardNode.gameObject, aniName = "adventurelevelup_rewardtoast_recipe_in", voice = "Au_UI_Event_AdventureReward", })
    end
    count = #levelUpInfo.rewardItemInfos
    rewardView.rewardNode.gameObject:SetActiveIfNecessary(false)
    if count > 0 then
        self.m_genRewardCells:Refresh(count, function(cell, luaIndex)
            local info = levelUpInfo.rewardItemInfos[luaIndex]
            cell:InitItem(info, true)
        end)
        self.m_aniQueue:Push({ targetObj = rewardView.rewardNode.gameObject, aniName = "adventurelevelup_rewardtoast_reward_in", voice = "Au_UI_Event_AdventureReward", })
    end
    self.m_aniQueue:Push({ aniName = "adventurelevelup_rewardtoast_continueBtn_in" })
    self:_NestedPlayAniQueue()
end
AdventureLevelUpCtrl._NestedPlayAniQueue = HL.Method() << function(self)
    if self.m_aniQueue:Count() > 0 then
        local aniWrapper = self:GetAnimationWrapper()
        local aniBundle = self.m_aniQueue:Pop()
        if aniBundle.targetObj then
            aniBundle.targetObj:SetActiveIfNecessary(true)
        end
        if aniBundle.voice then
            AudioManager.PostEvent(aniBundle.voice)
        end
        aniWrapper:PlayWithTween(aniBundle.aniName, function()
            self:_NestedPlayAniQueue()
        end)
    end
end
AdventureLevelUpCtrl._CompleteCloseSelf = HL.Method() << function(self)
    self:PlayAnimationOutWithCallback(function()
        self:_ClearCache()
        self:Close()
        Notify(MessageConst.ON_ONE_MAIN_HUD_TOAST_FINISH, MAIN_HUD_TOAST_TYPE)
    end)
end
AdventureLevelUpCtrl._UpdateUIProgress = HL.Method(HL.Any, HL.Number, HL.Number, HL.Number) << function(self, viewRef, curValue, targetGrowthValue, totalValue)
    local fillOffset = self.view.config.PROGRESS_STATIC_FILLAMOUNT_OFFSET
    local realFillPercent = 1 - 2 * fillOffset
    local fillAmount = curValue / totalValue
    local realFill = fillAmount * realFillPercent + fillOffset
    viewRef.curExpTxt.text = curValue
    viewRef.targetExpTxt.text = totalValue
    viewRef.progressive.fillAmount = realFill
    if curValue < totalValue then
        viewRef.progressStatic.gameObject:SetActiveIfNecessary(true)
        local pStaticRectTransform = viewRef.progressStaticRectTransform
        local pRectTransform = viewRef.progressiveRectTransform
        local posXOffset = self.view.config.PROGRESS_STATIC_POS_X_OFFSET
        local staticFillAmount = (targetGrowthValue - curValue) / totalValue
        local realStaticFill = staticFillAmount * realFillPercent + fillOffset
        viewRef.progressStatic.fillAmount = realStaticFill
        local posX = pRectTransform.rect.width * realFill + posXOffset
        pStaticRectTransform.anchoredPosition = Vector2(posX, 0)
    else
        viewRef.progressStatic.gameObject:SetActiveIfNecessary(false)
    end
end
AdventureLevelUpCtrl._ClearOrRecoverScreen = HL.Method(HL.Boolean) << function(self, isClear)
    if isClear then
        if self.m_clearScreenKey <= 0 then
            self.m_clearScreenKey = UIManager:ClearScreen({ PanelId.AdventureLevelUp })
        end
    else
        if self.m_clearScreenKey > 0 then
            UIManager:RecoverScreen(self.m_clearScreenKey)
            self.m_clearScreenKey = -1
        end
    end
end
AdventureLevelUpCtrl._SetFreezeWorld = HL.Method(HL.Boolean) << function(self, isFreeze)
    if self.m_isWorldFreeze == isFreeze then
        return
    end
    self.m_isWorldFreeze = isFreeze
    if isFreeze then
        UIWorldFreezeManager:_OnPanelActivate("TemporaryEmptyFreezeWorld")
    else
        UIWorldFreezeManager:_OnPanelDeActivate("TemporaryEmptyFreezeWorld")
    end
end
HL.Commit(AdventureLevelUpCtrl)