local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlemenReportTips
local settlementSystem = GameInstance.player.settlementSystem
settlementDevelopmentState = { none = 1, allManual = 2, partManual = 3, allStop = 4, partStop = 5, allSlow = 6, partSlow = 7, normal = 8, partMax = 9, allMax = 10, initial = 11, }
local csSubmitState = CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState
SettlemenReportTipsCtrl = HL.Class('SettlemenReportTipsCtrl', uiCtrl.UICtrl)
SettlemenReportTipsCtrl.defineState = HL.Field(HL.Table)
SettlemenReportTipsCtrl.m_lastTipsTime = HL.Field(HL.Number) << 0
SettlemenReportTipsCtrl.m_nowTime = HL.Field(HL.Number) << 0
SettlemenReportTipsCtrl.m_enableTips = HL.Field(HL.Boolean) << false
SettlemenReportTipsCtrl.m_isShowTips = HL.Field(HL.Boolean) << false
SettlemenReportTipsCtrl.m_isBreak = HL.Field(HL.Boolean) << false
SettlemenReportTipsCtrl.m_needRetry = HL.Field(HL.Boolean) << false
SettlemenReportTipsCtrl.m_curState = HL.Field(HL.Number) << 0
SettlemenReportTipsCtrl.m_itemInventoryCache = HL.Field(HL.Table)
SettlemenReportTipsCtrl.m_unlockedDomainIds = HL.Field(HL.Table)
SettlemenReportTipsCtrl.m_settlementIds = HL.Field(HL.Table)
SettlemenReportTipsCtrl.m_settlementBeforeStates = HL.Field(HL.Table)
SettlemenReportTipsCtrl.m_domainStates = HL.Field(HL.Table)
SettlemenReportTipsCtrl.developmentState = HL.StaticField(HL.Table)
SettlemenReportTipsCtrl.m_domainIncomeLast = HL.Field(HL.Table)
SettlemenReportTipsCtrl.m_domainIncomeRecent = HL.Field(HL.Table)
SettlemenReportTipsCtrl.m_settlementIdToDomain = HL.Field(HL.Table)
SettlemenReportTipsCtrl.m_tipsThread = HL.Field(HL.Thread)
SettlemenReportTipsCtrl.m_levelUpCacheExp = HL.Field(HL.Table)
SettlemenReportTipsCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_IN_MAIN_HUD_CHANGED] = 'OnInMainHudChanged', [MessageConst.ON_SETTLEMENT_SUBMIT] = 'OnSyncProductData', [MessageConst.ON_SETTLEMENT_UNLOCK] = 'UnlockNewSettlement', [MessageConst.ON_SETTLEMENT_AUTO_REFRESH] = 'ResetManualState', [MessageConst.ON_SETTLEMENT_UPGRADE] = 'OnSettlementLevelUp', }
SettlemenReportTipsCtrl.CheckReportTips = HL.Method() << function(self)
    if self.m_lastTipsTime == 0 then
        self.m_lastTipsTime = settlementSystem.lastTickTimeStamp
        self.m_nowTime = settlementSystem.lastTickTimeStamp
        return
    end
    self.m_nowTime = self.m_nowTime + 15
    if Utils.isInDungeon() or Utils.isInRacingDungeon() or UIUtils.inCinematic() then
        return
    end
    local diff = self.m_nowTime - self.m_lastTipsTime
    if diff < Tables.settlementConst.stmDevelopmentTipsIntervalTime then
        return
    end
    if diff > Tables.settlementConst.stmDevelopmentTipsIntervalTime + Tables.settlementConst.stmDevelopmentTipsRetryTime then
        self.m_lastTipsTime = self.m_nowTime
        self.m_needRetry = false
        self:_clearState()
        return
    end
    if not self.m_enableTips then
        return
    end
    if self.m_isShowTips then
        return
    end
    local curLevelId = GameInstance.world.curLevelId
    local _, levelInfo = DataManager.levelBasicInfoTable:TryGetValue(curLevelId)
    local domainId = levelInfo.domainName
    if string.isEmpty(domainId) or not Tables.domainDataTable:ContainsKey(domainId) then
        self:_OnShowEnd(true)
        return
    end
    local state = self.m_domainStates[domainId]
    local isAllManual = settlementSystem:IsAllManualSubmit(domainId)
    local _, curDomainData = Tables.domainDataTable:TryGetValue(domainId)
    local haveSettlement = false
    if curDomainData then
        for i, settlementId in pairs(curDomainData.settlementGroup) do
            local level, exp, maxExp = settlementSystem:GetSettlementExp(settlementId)
            if level > 0 then
                haveSettlement = true
                break
            end
        end
    end
    if (state == settlementDevelopmentState.none and not isAllManual) or not haveSettlement then
        self.m_lastTipsTime = self.m_nowTime
        self.m_needRetry = false
        self:_clearState()
        return
    end
    self:_ShowRewardTips(domainId)
end
SettlemenReportTipsCtrl._clearState = HL.Method() << function(self)
    for k, v in pairs(self.m_settlementBeforeStates) do
        local csState = settlementSystem:GetSettlementLastSubmitState(k)
        self.m_settlementBeforeStates[k] = settlementDevelopmentState.initial
        if csState == csSubmitState.None then
            self.m_settlementBeforeStates[k] = settlementDevelopmentState.none
        end
        if csState == csSubmitState.Manual then
            self.m_settlementBeforeStates[k] = settlementDevelopmentState.allManual
        end
        if csState == csSubmitState.All then
            self.m_settlementBeforeStates[k] = settlementDevelopmentState.initial
        end
        if csState == csSubmitState.Zero then
            self.m_settlementBeforeStates[k] = settlementDevelopmentState.initial
        end
        if csState == csSubmitState.Max then
            self.m_settlementBeforeStates[k] = settlementDevelopmentState.allMax
        end
    end
    for k, v in pairs(self.m_domainStates) do
        self.m_domainStates[k] = settlementDevelopmentState.initial
    end
end
SettlemenReportTipsCtrl._UpdateState = HL.Method() << function(self)
    for i, domainId in pairs(self.m_unlockedDomainIds) do
        local data = Tables.domainDataTable[domainId]
        for i, settlementId in pairs(data.settlementGroup) do
            local state = self:_GetState(domainId, settlementId)
            self.m_settlementBeforeStates[settlementId] = state
        end
        local domainState = settlementDevelopmentState.max
        local allStop = true
        local allSlow = true
        local oneStop = false
        local oneSlow = false
        local oneMax = false
        local allMax = true
        local allManual = true
        local oneManual = false
        local none = true
        for i, settlementId in pairs(data.settlementGroup) do
            local state = self.m_settlementBeforeStates[settlementId]
            if state ~= settlementDevelopmentState.none then
                none = false
                if state == settlementDevelopmentState.allStop then
                    oneStop = true
                end
                if state == settlementDevelopmentState.allSlow then
                    oneSlow = true
                end
                if state == settlementDevelopmentState.normal then
                    allStop = false
                    allSlow = false
                end
                if state ~= settlementDevelopmentState.allStop then
                    allStop = false
                end
                if state ~= settlementDevelopmentState.allSlow then
                    allSlow = false
                end
                if state ~= settlementDevelopmentState.allMax then
                    allMax = false
                end
                if state == settlementDevelopmentState.allMax then
                    oneMax = true
                end
                if state == settlementDevelopmentState.allManual then
                    oneManual = true
                end
                if state ~= settlementDevelopmentState.allManual then
                    allManual = false
                end
            end
        end
        domainState = settlementDevelopmentState.normal
        if allStop then
            domainState = settlementDevelopmentState.allStop
        end
        if allSlow then
            domainState = settlementDevelopmentState.allSlow
        end
        if allMax then
            domainState = settlementDevelopmentState.allMax
        end
        if allManual then
            domainState = settlementDevelopmentState.allManual
        end
        if oneMax and not allMax then
            domainState = settlementDevelopmentState.partMax
        end
        if oneSlow and not allSlow then
            domainState = settlementDevelopmentState.partSlow
        end
        if oneStop and not allStop then
            domainState = settlementDevelopmentState.partStop
        end
        if oneManual and not allManual then
            domainState = settlementDevelopmentState.partManual
        end
        if none then
            domainState = settlementDevelopmentState.none
        end
        self.m_domainStates[domainId] = domainState
    end
end
SettlemenReportTipsCtrl.ResetManualState = HL.Method(HL.Any) << function(self, arg)
    local id = arg[1]
    local isAuto = settlementSystem:GetSettlementAutoSubmit(id)
    if isAuto then
        self.m_settlementBeforeStates[id] = settlementDevelopmentState.normal
    else
        self.m_settlementBeforeStates[id] = settlementDevelopmentState.allManual
    end
    self:_UpdateState()
end
SettlemenReportTipsCtrl.OnSettlementLevelUp = HL.Method(HL.Any) << function(self, arg)
    local id = unpack(arg)
    local domainId = self.m_settlementIdToDomain[id]
    local daily = settlementSystem:GetSettlementDailyReport(id, 0)
    local exp = self.m_domainIncomeLast[domainId][id].exp
    local level = settlementSystem:GetSettlementLevel(id)
    local lastMaxExp = Tables.settlementBasicDataTable[id].settlementLevelMap[level - 1].levelUpExp
    local cacheExp = lastMaxExp - exp
    if not self.m_levelUpCacheExp[id] then
        self.m_levelUpCacheExp[id] = cacheExp
    else
        self.m_levelUpCacheExp[id] = cacheExp + self.m_levelUpCacheExp[id]
    end
    self.m_domainIncomeLast[domainId].exp = self.m_domainIncomeLast[domainId].exp - exp
end
SettlemenReportTipsCtrl.GetDomainState = HL.Method(HL.String).Return(HL.Number) << function(self, domainId)
    return self.m_domainStates[domainId]
end
SettlemenReportTipsCtrl.GetSettlementState = HL.Method(HL.String).Return(HL.Number) << function(self, settlementId)
    return self.m_settlementBeforeStates[settlementId]
end
SettlemenReportTipsCtrl._GetState = HL.Method(HL.String, HL.Opt(HL.String)).Return(HL.Number) << function(self, domainId, settlement)
    local state = nil
    state = settlementSystem:GetSettlementLastSubmitState(settlement)
    local beforeState = self.m_settlementBeforeStates[settlement]
    if state == csSubmitState.None then
        beforeState = settlementDevelopmentState.none
        return beforeState
    end
    if state == csSubmitState.Manual then
        beforeState = settlementDevelopmentState.allManual
        return beforeState
    end
    local isAuto = settlementSystem:GetSettlementAutoSubmit(settlement)
    if not isAuto then
        return settlementDevelopmentState.allManual
    end
    if beforeState == 0 then
        beforeState = settlementDevelopmentState.none
        return beforeState
    end
    if (beforeState == settlementDevelopmentState.initial or beforeState == settlementDevelopmentState.normal) and state == csSubmitState.All then
        beforeState = settlementDevelopmentState.normal
        return beforeState
    end
    if beforeState == settlementDevelopmentState.initial and state == csSubmitState.Zero then
        beforeState = settlementDevelopmentState.allStop
        return beforeState
    end
    if beforeState == settlementDevelopmentState.allStop and (state == csSubmitState.All) then
        beforeState = settlementDevelopmentState.allSlow
        return beforeState
    end
    if beforeState == settlementDevelopmentState.normal and (state == csSubmitState.Part or state == csSubmitState.Zero) then
        beforeState = settlementDevelopmentState.allSlow
        return beforeState
    end
    if beforeState == settlementDevelopmentState.allMax and state == csSubmitState.All then
        beforeState = settlementDevelopmentState.normal
        return beforeState
    end
    if (beforeState == settlementDevelopmentState.normal or beforeState == settlementDevelopmentState.allSlow) and state == csSubmitState.Max then
        beforeState = settlementDevelopmentState.allMax
        return beforeState
    end
    return beforeState
end
SettlemenReportTipsCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.conentNode.gameObject:SetActive(false)
    self.m_enableTips = true
    self.m_isShowTips = false
    self.m_lastTipsTime = 0
    self.m_isBreak = false
    self.m_needRetry = false
    self.m_curState = 0
    self.m_itemInventoryCache = {}
    self.m_unlockedDomainIds = {}
    self.m_domainStates = {}
    self.m_settlementIdToDomain = {}
    self.m_domainIncomeLast = {}
    self.m_domainIncomeRecent = {}
    self.m_settlementBeforeStates = {}
    self.m_levelUpCacheExp = {}
    self.defineState = settlementDevelopmentState
    local tempList = {}
    for i, v in pairs(GameInstance.player.mapManager:GetUnlockedLevels()) do
        local _, levelInfo = DataManager.levelBasicInfoTable:TryGetValue(v)
        local domainId = levelInfo.domainName
        if tempList[domainId] == nil and not string.isEmpty(domainId) and Tables.domainDataTable:ContainsKey(domainId) then
            tempList[domainId] = true
        end
    end
    for key, v in pairs(tempList) do
        table.insert(self.m_unlockedDomainIds, key)
    end
    self.m_settlementIds = {}
    for i, domainId in pairs(self.m_unlockedDomainIds) do
        if tempList[domainId] and Tables.domainDataTable:ContainsKey(domainId) then
            local data = Tables.domainDataTable[domainId]
            for i, settlementId in pairs(data.settlementGroup) do
                table.insert(self.m_settlementIds, settlementId)
                self.m_settlementIdToDomain[settlementId] = domainId
                local csState = settlementSystem:GetSettlementLastSubmitState(settlementId)
                self.m_settlementBeforeStates[settlementId] = settlementDevelopmentState.initial
                if csState == csSubmitState.Initial then
                    self.m_settlementBeforeStates[settlementId] = settlementDevelopmentState.initial
                end
                if csState == csSubmitState.None then
                    self.m_settlementBeforeStates[settlementId] = settlementDevelopmentState.none
                end
                if csState == csSubmitState.Manual then
                    self.m_settlementBeforeStates[settlementId] = settlementDevelopmentState.allManual
                end
                if csState == csSubmitState.All then
                    self.m_settlementBeforeStates[settlementId] = settlementDevelopmentState.normal
                end
                if csState == csSubmitState.Zero then
                    self.m_settlementBeforeStates[settlementId] = settlementDevelopmentState.allStop
                end
                if csState == csSubmitState.Max then
                    self.m_settlementBeforeStates[settlementId] = settlementDevelopmentState.allMax
                end
            end
        end
    end
    self:_InitDomainProduct()
    SettlemenReportTipsCtrl.developmentState = settlementDevelopmentState
    self.view.button.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.SettlementMain)
    end)
    self:_StartCoroutine(function()
        while true do
            self:CheckReportTips()
            coroutine.wait(15)
        end
    end)
    self:_UpdateState()
end
SettlemenReportTipsCtrl._ShowRewardTips = HL.Method(HL.String) << function(self, domainId)
    self.m_isShowTips = true
    self.view.conentNode.gameObject:SetActive(true)
    self.view.stateNode.gameObject:SetActive(false)
    self.view.rewardNode.gameObject:SetActive(false)
    self.view.conentNode:SetState("reward")
    local output = self:GetRecentIncome(domainId)
    local haveReward = false
    local isAllManual = settlementSystem:IsAllManualSubmit(domainId)
    if not isAllManual then
        for k, v in pairs(output) do
            if v > 0 then
                local item = Tables.itemTable[k]
                self.view.rewardText.text = string.format(Language.LUA_SETTLEMENT_REWARD_REPORT_TIPS, item.name, v)
                self.view.iconItem.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, item.iconId)
                haveReward = true
            end
        end
    end
    if not haveReward then
        self.view.iconItem.gameObject:SetActive(false)
        self.view.stateNode.gameObject:SetActive(true)
        self.view.rewardNode.gameObject:SetActive(false)
        self:_ShowTips(domainId)
        return
    else
        self.view.rewardNode.gameObject:SetActive(true)
        self.view.animationWrapper:Play("settlementreporttips_in")
    end
    self.m_tipsThread = self:_StartCoroutine(function()
        coroutine.wait(10)
        self.view.animationWrapper:Play("settlementreporttips_out", function()
            self.view.iconItem.gameObject:SetActive(false)
            self.view.stateNode.gameObject:SetActive(true)
            self.view.rewardNode.gameObject:SetActive(false)
            self:_ShowTips(domainId)
        end)
        self.m_tipsThread = nil
        return
    end)
end
SettlemenReportTipsCtrl._ShowTips = HL.Method(HL.String) << function(self, domainId)
    if self.m_isBreak then
        self:_OnShowEnd(false)
        return
    end
    if Utils.isInDungeon() or Utils.isInRacingDungeon() or UIUtils.inCinematic() then
        self:_OnShowEnd(false)
        return
    end
    self.view.conentNode.gameObject:SetActive(true)
    self.view.conentNode:SetState("normal")
    self.view.animationWrapper:Play("settlementreporttips_in")
    local state = self.m_domainStates[domainId]
    local isAllManual = settlementSystem:IsAllManualSubmit(domainId)
    if isAllManual then
        state = settlementDevelopmentState.allManual
    end
    self.view.stateNode.gameObject:SetActive(state ~= settlementDevelopmentState.normal)
    if state == settlementDevelopmentState.allManual then
        self.view.stateNode.text = Language.LUA_SETTLEMENT_DEVELOPMENT_ALL_MANUAL_TIPS
        self.view.conentNode:SetState("manual")
    end
    if state == settlementDevelopmentState.partManual then
        self.view.stateNode.text = Language.LUA_SETTLEMENT_DEVELOPMENT_PART_MANUAL_TIPS
        self.view.conentNode:SetState("manual")
    end
    if state == settlementDevelopmentState.allMax then
        self.view.stateNode.text = Language.LUA_SETTLEMENT_DEVELOPMENT_ALL_MAX_TIPS
        self.view.conentNode:SetState("max")
    end
    if state == settlementDevelopmentState.partMax then
        self.view.stateNode.text = Language.LUA_SETTLEMENT_DEVELOPMENT_PART_MAX_TIPS
        self.view.conentNode:SetState("max")
    end
    if state == settlementDevelopmentState.allStop then
        self.view.stateNode.text = Language.LUA_SETTLEMENT_DEVELOPMENT_ALL_STOP_TIPS
        self.view.conentNode:SetState("stop")
    end
    if state == settlementDevelopmentState.partStop then
        self.view.stateNode.text = Language.LUA_SETTLEMENT_DEVELOPMENT_PART_STOP_TIPS
        self.view.conentNode:SetState("stop")
    end
    if state == settlementDevelopmentState.allSlow then
        self.view.stateNode.text = Language.LUA_SETTLEMENT_DEVELOPMENT_ALL_SLOW_TIPS
        self.view.conentNode:SetState("slow")
    end
    if state == settlementDevelopmentState.partSlow then
        self.view.stateNode.text = Language.LUA_SETTLEMENT_DEVELOPMENT_PART_SLOW_TIPS
        self.view.conentNode:SetState("slow")
    end
    if state == settlementDevelopmentState.none then
        self:_OnShowEnd(true)
        return
    end
    if state == settlementDevelopmentState.normal then
        self:_OnShowEnd(true)
        return
    end
    if self.m_tipsThread then
        self:_ClearCoroutine(self.m_tipsThread)
    end
    self.m_tipsThread = self:_StartCoroutine(function()
        coroutine.wait(10)
        self:_OnShowEnd(true)
        self.m_tipsThread = nil
        self.m_isShowTips = false
    end)
end
SettlemenReportTipsCtrl.OnSyncProductData = HL.Method(HL.Any) << function(self, arg)
    self:_UpdateState()
end
SettlemenReportTipsCtrl.UnlockNewSettlement = HL.Method(HL.Any) << function(self, args)
    local settlementId, mainText, subText = unpack(args)
    local settlementData = Tables.settlementBasicDataTable[settlementId]
    local domainId = settlementData.domainId
    self.m_settlementBeforeStates[settlementId] = settlementDevelopmentState.allManual
    if self.m_domainStates[domainId] ~= settlementDevelopmentState.allManual then
        self.m_domainStates[domainId] = settlementDevelopmentState.partManual
    end
    self:_InitSettlementProduct(domainId, settlementId)
end
SettlemenReportTipsCtrl._InitSettlementProduct = HL.Method(HL.String, HL.String) << function(self, domainId, settlementId)
    local daily = settlementSystem:GetSettlementDailyReport(settlementId, 0)
    if daily then
        for j = 0, daily.rewardItems.Count - 1 do
            local data = self.m_domainIncomeRecent[domainId][daily.rewardItems[j].id]
            if not data then
                data = {}
                data.count = 0
                self.m_domainIncomeRecent[domainId][daily.rewardItems[j].id] = data
            end
            data.count = daily.rewardItems[j].count + data.count
            local data2 = self.m_domainIncomeLast[domainId][daily.rewardItems[j].id]
            if not data2 then
                data2 = {}
                data2.count = 0
                self.m_domainIncomeLast[domainId][daily.rewardItems[j].id] = data2
            end
            data2.count = daily.rewardItems[j].count + data2.count
        end
        self.m_domainIncomeLast[domainId][settlementId] = {}
        self.m_domainIncomeLast[domainId][settlementId].exp = daily.postExp
        self.m_domainIncomeLast[domainId].exp = daily.postExp + self.m_domainIncomeLast[domainId].exp
    end
end
SettlemenReportTipsCtrl._InitDomainProduct = HL.Method() << function(self)
    for i, domainId in pairs(self.m_unlockedDomainIds) do
        local count = 0
        self.m_domainIncomeRecent[domainId] = {}
        self.m_domainIncomeLast[domainId] = {}
        self.m_domainIncomeLast[domainId].exp = 0
        for i, settlementId in pairs(Tables.domainDataTable[domainId].settlementGroup) do
            self.m_domainIncomeLast[domainId][settlementId] = { exp = 0 }
            self:_InitSettlementProduct(domainId, settlementId)
        end
    end
end
SettlemenReportTipsCtrl.GetLastIncome = HL.Method(HL.String).Return(HL.Table) << function(self, domainId)
    local data = self.m_domainIncomeLast[domainId]
    local domainData = Tables.domainDataTable[domainId]
    local newCount = {}
    local exp = 0
    local cacheExp = 0
    for i, id in pairs(domainData.settlementGroup) do
        local daily = settlementSystem:GetSettlementDailyReport(id, 0)
        if daily then
            for j = 0, daily.rewardItems.Count - 1 do
                local id = daily.rewardItems[j].id
                if data[id] then
                    if not newCount[id] then
                        newCount[id] = data[id].count
                    end
                    newCount[id] = newCount[id] - daily.rewardItems[j].count
                else
                    data[id] = { count = 0 }
                    newCount[id] = data[id].count - daily.rewardItems[j].count
                end
            end
            if self.m_levelUpCacheExp[id] and daily.postExp <= data[id].exp then
                exp = daily.postExp + exp + self.m_levelUpCacheExp[id]
                cacheExp = self.m_levelUpCacheExp[id] + cacheExp
                self.m_levelUpCacheExp[id] = 0
            else
                exp = daily.postExp + exp
            end
            self.m_domainIncomeLast[domainId][id].exp = daily.postExp
        end
    end
    for k, v in pairs(newCount) do
        if v < 0 then
            newCount[k] = -v
            data[k].count = data[k].count - v
        end
    end
    newCount.exp = exp - self.m_domainIncomeLast[domainId].exp
    self.m_domainIncomeLast[domainId].exp = exp - cacheExp
    return newCount
end
SettlemenReportTipsCtrl.GetRecentIncome = HL.Method(HL.String).Return(HL.Table) << function(self, domainId)
    local data = self.m_domainIncomeRecent[domainId]
    local domainData = Tables.domainDataTable[domainId]
    local newCount = {}
    for k, v in pairs(data) do
        newCount[k] = v.count
    end
    for i, id in pairs(domainData.settlementGroup) do
        local daily = settlementSystem:GetSettlementDailyReport(id, 0)
        if daily then
            for j = 0, daily.rewardItems.Count - 1 do
                local id = daily.rewardItems[j].id
                if data[id] then
                    if not newCount[id] then
                        newCount[id] = data[id].count
                    end
                    newCount[id] = newCount[id] - daily.rewardItems[j].count
                else
                    data[id] = { count = 0 }
                    newCount[id] = data[id].count - daily.rewardItems[j].count
                end
            end
        end
    end
    for k, v in pairs(newCount) do
        if v < 0 then
            newCount[k] = -v
            data[k].count = data[k].count - v
        end
    end
    return newCount
end
SettlemenReportTipsCtrl.OnMainHudDisable = HL.Method() << function(self)
    if self.m_isShowTips then
    end
    self.view.animationWrapper:Play("settlementreporttips_out", function()
        self.view.conentNode.gameObject:SetActive(false)
    end)
    self.m_enableTips = false
end
SettlemenReportTipsCtrl.OnMainHudEnable = HL.Method() << function(self)
    self.m_enableTips = true
    self.m_isBreak = false
    if self.m_isShowTips then
        self.view.conentNode.gameObject:SetActive(true)
        self.view.animationWrapper:Play("settlementreporttips_in")
    end
end
SettlemenReportTipsCtrl.OnInMainHudChanged = HL.Method(HL.Table) << function(self, arg)
    local inMainHud = unpack(arg)
    if inMainHud then
        self:OnMainHudEnable()
    else
        self:OnMainHudDisable()
    end
end
SettlemenReportTipsCtrl.OnClickTips = HL.Method() << function(self)
    self.m_isShowTips = false
    self.view.conentNode.gameObject:SetActive(false)
end
SettlemenReportTipsCtrl._OnShowEnd = HL.Method(HL.Boolean) << function(self, normalEnd)
    self.m_isShowTips = false
    self.view.animationWrapper:Play("settlementreporttips_out", function()
        self.view.conentNode.gameObject:SetActive(false)
        self.view.stateNode.gameObject:SetActive(false)
        self.view.rewardNode.gameObject:SetActive(false)
    end)
    self.view.animationWrapper:SampleToInAnimationBegin()
    if normalEnd then
        self.m_needRetry = false
        self.m_lastTipsTime = self.m_nowTime
        self:_clearState()
    else
        self.m_needRetry = true
    end
end
SettlemenReportTipsCtrl.OnHide = HL.Override() << function(self)
end
HL.Commit(SettlemenReportTipsCtrl)