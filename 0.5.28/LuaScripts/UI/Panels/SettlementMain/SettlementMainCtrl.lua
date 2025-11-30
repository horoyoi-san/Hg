local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SettlementMain
local PHASE_ID = PhaseId.SettlementMain
local settlementSystem = GameInstance.player.settlementSystem
SettlementMainCtrl = HL.Class('SettlementMainCtrl', uiCtrl.UICtrl)
SettlementMainCtrl.m_curDomainId = HL.Field(HL.String) << ""
SettlementMainCtrl.m_unlockedDomainIds = HL.Field(HL.Table)
SettlementMainCtrl.m_settlementIds = HL.Field(HL.Table)
SettlementMainCtrl.m_prosperityGetCellFunc = HL.Field(HL.Function)
SettlementMainCtrl.m_autoOrderOverviewGetCellFunc = HL.Field(HL.Function)
SettlementMainCtrl.m_manualOrderOverviewGetCellFunc = HL.Field(HL.Function)
SettlementMainCtrl.m_autoOrderOverviewData = HL.Field(HL.Table)
SettlementMainCtrl.m_manualOrderOverviewData = HL.Field(HL.Table)
SettlementMainCtrl.m_autoContentList = HL.Field(HL.Any)
SettlementMainCtrl.m_manualContentList = HL.Field(HL.Any)
SettlementMainCtrl.m_orderSubmitState = HL.Field(HL.Any) << 0
SettlementMainCtrl.m_settlementOverviewGetCellFunc = HL.Field(HL.Function)
SettlementMainCtrl.m_lastRemainTime = HL.Field(HL.Number) << -1
SettlementMainCtrl.m_itemInventoryCache = HL.Field(HL.Table)
SettlementMainCtrl.m_showItemCell = HL.Field(HL.Table)
SettlementMainCtrl.m_refreshOrders = HL.Field(HL.Table)
SettlementMainCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SETTLEMENT_SYS_REFRESH] = '_OnSettlementSysRefresh', [MessageConst.ON_SYNC_PRODUCT_DATA] = 'OnSyncProductData', [MessageConst.ON_SETTLEMENT_SUBMIT] = '_OnOrderSubmit', [MessageConst.ON_SETTLEMENT_AUTO_REFRESH] = '_OnAutoSubmitChange', [MessageConst.ON_ITEM_COUNT_CHANGED] = 'OnItemCountChanged', }
SettlementMainCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local levelId = nil
    if arg and type(arg) == "string" then
        levelId = arg
    else
        levelId = GameInstance.world.curLevelId
    end
    local _, levelInfo = DataManager.levelBasicInfoTable:TryGetValue(levelId)
    local domainId = levelInfo.domainName
    self.view.btnClose.onClick:AddListener(function()
        local isOpen, phase = PhaseManager:IsOpen(PhaseId.Dialog)
        if isOpen then
            self:Notify(MessageConst.DIALOG_CLOSE_UI, { PANEL_ID, PHASE_ID, 0 })
        else
            PhaseManager:PopPhase(PHASE_ID)
        end
    end)
    self.m_autoContentList = UIUtils.genCellCache(self.view.content, nil, self.view.autoContent.transform)
    self.m_manualContentList = UIUtils.genCellCache(self.view.content, nil, self.view.manualContent.transform)
    self.m_settlementOverviewGetCellFunc = UIUtils.genCachedCellFunction(self.view.settlementOverviewScrollList)
    self.view.settlementOverviewScrollList.onUpdateCell:AddListener(function(obj, csIndex)
        local cell = self.m_settlementOverviewGetCellFunc(obj)
        local luaIndex = LuaIndex(csIndex)
        local settlementId = self.m_settlementIds[luaIndex]
        cell:InitContent(settlementId, self.m_curDomainId)
    end)
    self.view.btnSwitchDomain.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.SettlementSwitchRegionPopup, {
            curDomainId = self.m_curDomainId,
            unlockedDomainIds = self.m_unlockedDomainIds,
            onConfirm = function(newDomainId)
                self:_RefreshDomain(newDomainId)
            end
        })
    end)
    self.view.btnBulletinNode.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.SettlementBrief, self.m_curDomainId)
    end)
    self.m_prosperityGetCellFunc = UIUtils.genCachedCellFunction(self.view.prosperityScrollList)
    self.view.prosperityScrollList.onUpdateCell:AddListener(function(obj, csIndex)
        local prosperity, prosperityMax = settlementSystem:GetProsperityByDomainId(self.m_curDomainId)
        self:_RefreshProsperityCell(self.m_prosperityGetCellFunc(obj), csIndex + 1, prosperity)
    end)
    self.view.prosperityClick.onClick:AddListener(function()
        UIManager:Open(PanelId.SettlementProsperity, { self.m_curDomainId })
    end)
    local isSSShopUnlocked = Utils.isSystemUnlocked(GEnums.UnlockSystemType.SpaceshipShop)
    local isSSShopCanShow = false
    if isSSShopUnlocked then
        local instId = Tables.globalConst.spaceShipShopMapMarkInstId
        if not string.isEmpty(instId) and MapUtils.checkIsValidMarkInstId(instId) then
            self.view.exchangeEntranceBtn.onClick:RemoveAllListeners()
            self.view.exchangeEntranceBtn.onClick:AddListener(function()
                MapUtils.openMap(instId)
            end)
            isSSShopCanShow = true
        end
    end
    self.view.exchangeEntranceBtn.gameObject:SetActive(isSSShopCanShow)
    self.m_autoOrderOverviewGetCellFunc = self.m_autoContentList.Get
    self.m_manualOrderOverviewGetCellFunc = self.m_manualContentList.Get
    self.m_itemInventoryCache = {}
    self.m_showItemCell = {}
    self.m_refreshOrders = {}
    self:_RefreshDomain(domainId)
    self:_StartCoroutine(function()
        while true do
            local remainTime = settlementSystem:GetOrderRemainTimeInSeconds()
            self.m_lastRemainTime = remainTime
            if remainTime < 0 then
                remainTime = remainTime % Tables.settlementConst.stmIntervalTime
            end
            for k, v in pairs(self.m_settlementIds) do
                local ctrl = self.m_settlementOverviewGetCellFunc(k)
                if ctrl then
                    ctrl:_UpdateTime()
                end
            end
            coroutine.wait(0.5)
        end
    end)
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.FAC_HUB_UPDATE_INTERVAL)
            if self:IsShow() and self.m_phase.isActive then
                self:_ReqProductData()
            end
        end
    end)
    self:_RefreshLastOutput(domainId)
    self:_StartTimer(10, function()
        self.view.outputNode.gameObject:SetActive(false)
    end)
end
SettlementMainCtrl._RefreshLastOutput = HL.Method(HL.String) << function(self, domainId)
    local _, ctrl = UIManager:IsOpen(PanelId.SettlemenReportTips)
    local output = ctrl:GetLastIncome(domainId)
    local exp = output.exp
    self.view.product2Number.text = output.exp
    output.exp = nil
    local need = false
    for i, v in pairs(output) do
        if v > 0 then
            local itemData = Tables.itemTable[i]
            self.view.icon1.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, itemData.iconId)
            self.view.product1Number.text = v
            need = true
        end
    end
    self.view.icon2.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, Tables.settlementConst.stmExpItemId)
    if need then
        self.view.outputNode.gameObject:SetActive(true)
    else
        self.view.outputNode.gameObject:SetActive(false)
    end
end
SettlementMainCtrl._RefreshMoney = HL.Method() << function(self)
    if #self.m_settlementIds == 0 then
        return
    end
    local settlementId = self.m_settlementIds[1]
    local settlementData = Tables.settlementBasicDataTable[settlementId]
    local level = settlementSystem:GetSettlementLevel(settlementId)
    level = level == 0 and 1 or level
    local orderIds = settlementData.settlementLevelMap[level].orderIdGroup
    local orderId = orderIds[0]
    if orderId then
        local orderData = Tables.settlementOrderDataTable[orderId]
        local rewardData = Tables.rewardTable[orderData.rewardId]
        for _, itemBundles in pairs(rewardData.itemBundles) do
            local itemData = Tables.itemTable[itemBundles.id]
            if GameInstance.player.inventory:IsMoneyType(itemData.type) then
                self.view.moneyCell:InitMoneyCell(itemData.id, true, true)
                return
            end
        end
    end
end
SettlementMainCtrl._RefreshDomain = HL.Method(HL.String) << function(self, domainId)
    self.m_curDomainId = domainId
    local curDomainData = Tables.domainDataTable[self.m_curDomainId]
    self.m_unlockedDomainIds = {}
    local tempList = {}
    for i, v in pairs(GameInstance.player.mapManager:GetUnlockedLevels()) do
        local _, levelInfo = DataManager.levelBasicInfoTable:TryGetValue(v)
        local domainId = levelInfo.domainName
        local _, curDomainData = Tables.domainDataTable:TryGetValue(domainId)
        if curDomainData then
            if curDomainData.settlementGroup.Count > 0 then
                tempList[domainId] = true
            end
        end
    end
    self.view.decoImage.sprite = self:LoadSprite(UIConst.UI_SPRITE_SETTLEMENT, "deco_" .. self.m_curDomainId)
    for key, v in pairs(tempList) do
        table.insert(self.m_unlockedDomainIds, key)
    end
    self.m_settlementIds = {}
    for i, settlementId in pairs(curDomainData.settlementGroup) do
        table.insert(self.m_settlementIds, settlementId)
    end
    self.view.sceneNormalNode.gameObject:SetActiveIfNecessary(#self.m_unlockedDomainIds > 1)
    self.view.sceneSingleNode.gameObject:SetActiveIfNecessary(#self.m_unlockedDomainIds <= 1)
    self.view.domainName.text = curDomainData.domainName
    self.view.domainNameSingle.text = curDomainData.domainName
    self.view.domainIcon.spriteName = curDomainData.domainIcon
    self.view.settlementOverviewScrollList:UpdateCount(#self.m_settlementIds)
    self:_RefreshProsperity()
    self:_RefreshOrderOverview()
    self:_RefreshMoney()
end
SettlementMainCtrl._RefreshProsperityCell = HL.Method(HL.Table, HL.Number, HL.Number) << function(self, cell, level, prosperity)
    local levelStr = tostring(level)
    cell.arrow.gameObject:SetActiveIfNecessary(level == prosperity)
    cell.activateText.gameObject:SetActiveIfNecessary(level <= prosperity)
    cell.activateText.text = levelStr
    cell.lockText.text = levelStr
    cell.line.gameObject:SetActiveIfNecessary(level ~= 1)
    cell.highlight.gameObject:SetActive(false)
    local curDomainData = Tables.domainDataTable[self.m_curDomainId]
    for k, v in pairs(Tables.levelGradeTable) do
        local array = v.grades
        for i = 0, array.Count - 1 do
            local grade = array[i]
            local isInDomain = false
            for j = 0, curDomainData.levelGroup.Count - 1 do
                if v.name == curDomainData.levelGroup[j] then
                    isInDomain = true
                    break
                end
            end
            if grade.prosperity > 0 and isInDomain and grade.prosperity == level and grade.prosperity > prosperity then
                cell.highlight.gameObject:SetActive(true)
                break
            end
        end
    end
end
SettlementMainCtrl._RefreshProsperity = HL.Method() << function(self)
    local prosperity, prosperityMax = settlementSystem:GetProsperityByDomainId(self.m_curDomainId)
    self.view.prosperityLevelText.text = tostring(prosperity)
    self.view.prosperityScrollList:UpdateCount(prosperityMax)
end
SettlementMainCtrl._RefreshOrderCell = HL.Method(HL.Table, HL.Number, HL.Table) << function(self, cell, luaIndex, list)
    local costItem = list[luaIndex].costItem
    local storageCount = Utils.getDepotItemCount(costItem.id, nil, self.m_curDomainId)
    self.m_showItemCell[costItem.id] = cell
    cell.itemId = costItem.id
    cell.itemBlack:InitItem({ id = costItem.id }, true)
    cell.demandNumberTxt.text = tostring(costItem.count)
    cell.storageNumberTxt.text = tostring(storageCount)
    cell.redAlert.gameObject:SetActiveIfNecessary(costItem.count > storageCount)
    if self.m_refreshOrders[list[luaIndex].id] then
        cell.gameObject:GetComponent("UIAnimationWrapper"):Play("settlementmain_cost")
        self.m_refreshOrders[list[luaIndex].id] = nil
    end
    local info = GameInstance.player.facSpMachineSystem:GetItemData(costItem.id, self.m_curDomainId)
    if info then
        local type = info.productDataType
        if type == GEnums.FacStatisticRank_Productivity.Minute10:GetHashCode() then
            local genValue = info.productGen
            local count = Tables.factoryProductivityDataTypeTable:GetValue(type).count
            if genValue.Count >= count then
                cell.productivity.text = genValue[genValue.Count - 1]
            else
                cell.productivity.text = 0
            end
        end
    else
        cell.productivity.text = 0
    end
end
SettlementMainCtrl._ReqProductData = HL.Method() << function(self)
    local itemIds = {}
    for k, v in pairs(self.m_showItemCell) do
        if v.itemId then
            table.insert(itemIds, v.itemId)
        end
    end
    GameInstance.player.facSpMachineSystem:ReqProductData(GEnums.FacStatisticRank_Productivity.Minute10, itemIds, self.m_curDomainId)
end
SettlementMainCtrl.OnSyncProductData = HL.Method() << function(self)
    for k, v in pairs(self.m_showItemCell) do
        local cell = v
        local info = GameInstance.player.facSpMachineSystem:GetItemData(cell.itemId, self.m_curDomainId)
        if info then
            local type = info.productDataType
            if type == GEnums.FacStatisticRank_Productivity.Minute10:GetHashCode() then
                local genValue = info.productGen
                local count = Tables.factoryProductivityDataTypeTable:GetValue(type).count
                if genValue.Count >= count then
                    cell.productivity.text = genValue[genValue.Count - 1]
                else
                    cell.productivity.text = 0
                end
            end
        end
    end
end
SettlementMainCtrl._RefreshOrderOverview = HL.Method() << function(self)
    self:_RefreshOrderOverviewData()
    self.m_autoContentList:Refresh(#self.m_autoOrderOverviewData, function(obj, luaIndex)
        self:_RefreshOrderCell(obj, luaIndex, self.m_autoOrderOverviewData)
    end)
    self.m_manualContentList:Refresh(#self.m_manualOrderOverviewData, function(obj, luaIndex)
        self:_RefreshOrderCell(obj, luaIndex, self.m_manualOrderOverviewData)
    end)
    self.view.autoContent.gameObject:SetActiveIfNecessary(#self.m_autoOrderOverviewData > 0)
    self.view.manualContent.gameObject:SetActiveIfNecessary(#self.m_manualOrderOverviewData > 0)
    self.view.listEmptyNode.gameObject:SetActiveIfNecessary(#self.m_autoOrderOverviewData == 0 and #self.m_manualOrderOverviewData == 0)
    self.view.autoTitle.gameObject:SetActiveIfNecessary(#self.m_autoOrderOverviewData > 0)
    self.view.manualTitle.gameObject:SetActiveIfNecessary(#self.m_manualOrderOverviewData > 0)
end
SettlementMainCtrl._RefreshOrderOverviewData = HL.Method() << function(self)
    local autoIndex = 1
    local manualIndex = 1
    self.m_autoOrderOverviewData = {}
    self.m_manualOrderOverviewData = {}
    local autoTemp = {}
    local manualTemp = {}
    for i, settlementId in pairs(Tables.domainDataTable[self.m_curDomainId].settlementGroup) do
        local orderId = settlementSystem:GetSettlementOrderId(settlementId)
        local isAuto = settlementSystem:GetSettlementAutoSubmit(settlementId)
        if orderId ~= nil and isAuto then
            local orderData = Tables.settlementOrderDataTable[orderId]
            for j, costItem in pairs(orderData.costItems) do
                if not autoTemp[costItem.id] then
                    autoTemp[costItem.id] = { costItem = { id = costItem.id, count = costItem.count }, id = { orderId } }
                else
                    autoTemp[costItem.id].costItem.count = autoTemp[costItem.id].costItem.count + costItem.count
                end
            end
        end
        if orderId ~= nil and not isAuto then
            local orderData = Tables.settlementOrderDataTable[orderId]
            for j, costItem in pairs(orderData.costItems) do
                if not manualTemp[costItem.id] then
                    manualTemp[costItem.id] = { costItem = { id = costItem.id, count = costItem.count }, id = { orderId } }
                else
                    manualTemp[costItem.id].costItem.count = manualTemp[costItem.id].costItem.count + costItem.count
                end
            end
        end
    end
    for k, v in pairs(autoTemp) do
        table.insert(self.m_autoOrderOverviewData, v)
    end
    for k, v in pairs(manualTemp) do
        table.insert(self.m_manualOrderOverviewData, v)
    end
end
SettlementMainCtrl._RefreshOrderSubmitState = HL.Method() << function(self)
    local _, ctrl = UIManager:IsOpen(PanelId.SettlemenReportTips)
    local data = Tables.domainDataTable[self.m_curDomainId]
    local oneSubmit = false
    local allSubmit = true
    for k, v in pairs(data.settlementGroup) do
        local state = settlementSystem:GetSettlementLastSubmitState(v)
        if state == CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.All then
            oneSubmit = true
        end
        if state == CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Zero then
            allSubmit = false
        end
    end
    if oneSubmit and not allSubmit then
        self.m_orderSubmitState = CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Part
    elseif allSubmit then
        self.m_orderSubmitState = CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.All
    elseif not oneSubmit then
        self.m_orderSubmitState = CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Zero
    else
        self.m_orderSubmitState = CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.None
    end
end
SettlementMainCtrl._OnSettlementSysRefresh = HL.Method() << function(self)
    self:_RefreshOrderSubmitState()
    local remainTime = settlementSystem:GetOrderRemainTimeInSeconds()
    if remainTime > self.m_lastRemainTime and self.m_orderSubmitState ~= CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.None then
        self.view.orderDoneNode.gameObject:SetActiveIfNecessary(self.m_orderSubmitState == CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.All)
        self.view.orderLackNode.gameObject:SetActiveIfNecessary(self.m_orderSubmitState ~= CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.All)
        self.view.orderPartText.gameObject:SetActiveIfNecessary(self.m_orderSubmitState == CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Part)
        self.view.orderZeroText.gameObject:SetActiveIfNecessary(self.m_orderSubmitState == CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Zero)
    end
    self:_RefreshDomain(self.m_curDomainId)
end
SettlementMainCtrl._ManuallySubmit = HL.Method(HL.String) << function(self, settlementId)
    settlementSystem:ManualSubmitOrder(settlementId)
end
SettlementMainCtrl._OnAutoSubmitChange = HL.Method(HL.Any) << function(self, settlementId)
    local id = settlementId[1]
    for i, settlementId in pairs(self.m_settlementIds) do
        if settlementId == id then
            local settlementCtrl = self.m_settlementOverviewGetCellFunc(i)
            if settlementCtrl then
                settlementCtrl:InitContent(settlementId, self.m_curDomainId, false)
            end
            break
        end
    end
    self:_RefreshOrderOverview()
end
SettlementMainCtrl._OnOrderSubmit = HL.Method(HL.Any) << function(self, settlementIds)
    settlementIds = settlementIds[1]
    for i = 0, settlementIds.Count - 1 do
        local id = settlementIds[i] and settlementIds[i].SettlementId or settlementIds[i]
        for j, settlementId in pairs(self.m_settlementIds) do
            if settlementId == id then
                local settlementCtrl = self.m_settlementOverviewGetCellFunc(j)
                if settlementCtrl then
                    settlementCtrl:InitContent(settlementId, self.m_curDomainId, true)
                end
                break
            end
        end
        local submitState = settlementSystem:GetSettlementSubmitState(id)
        if submitState == CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.Max or submitState == CS.Beyond.Gameplay.SettlementSystem.EOrderSubmitState.All then
            local orderId = settlementSystem:GetSettlementOrderId(id)
            self.m_refreshOrders[orderId] = true
            self.view.moneyCell.gameObject:GetComponent("UIAnimationWrapper"):Play("settlementmainmoney_in")
            AudioAdapter.PostEvent("Au_UI_Event_Settlement_Provide")
        end
    end
    self:_RefreshOrderOverview()
end
SettlementMainCtrl.OnItemCountChanged = HL.Method(HL.Any) << function(self, param)
    self:_RefreshOrderOverview()
end
SettlementMainCtrl._OnOrderManuallySubmit = HL.Method(HL.Any) << function(self, arg)
end
HL.Commit(SettlementMainCtrl)