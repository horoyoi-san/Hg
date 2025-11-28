local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.WikiBuildingDetail
WikiBuildingDetailCtrl = HL.Class('WikiBuildingDetailCtrl', uiCtrl.UICtrl)
WikiBuildingDetailCtrl.s_messages = HL.StaticField(HL.Table) << {}
WikiBuildingDetailCtrl.m_wikiEntryShowData = HL.Field(HL.Table)
WikiBuildingDetailCtrl.m_wikiGroupShowDataList = HL.Field(HL.Table)
WikiBuildingDetailCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local args = arg
    self.m_wikiEntryShowData = args.wikiEntryShowData
    self.m_wikiGroupShowDataList = args.wikiGroupShowDataList
    self.view.btnClose.onClick:AddListener(function()
        self:Close()
    end)
    self.view.right.btnSynthesisTree.onClick:AddListener(function()
        Notify(MessageConst.SHOW_TOAST, "合成树功能暂未实现")
    end)
    local wikiGroupItemListArgs = {
        isInitHidden = true,
        wikiGroupShowDataList = self.m_wikiGroupShowDataList,
        onItemClicked = function(wikiEntryShowData)
            self.m_wikiEntryShowData = wikiEntryShowData
            self:_RefreshCenter()
            self:_RefreshRight()
        end,
        btnExpandList = self.view.center.btnExpandList,
        btnClose = self.view.btnEmpty
    }
    self.view.wikiGroupItemList:InitWikiGroupItemList(wikiGroupItemListArgs)
    self:m_InitBuildingTypeDetailTable()
    self:_RefreshCenter()
    self:_RefreshRight()
end
WikiBuildingDetailCtrl._RefreshCenter = HL.Method() << function(self)
    local args = { wikiEntryShowData = self.m_wikiEntryShowData, imgItem = self.view.center.imgItem }
    self.view.center.wikiItemInfo:InitWikiItemInfo(args)
end
WikiBuildingDetailCtrl._RefreshRight = HL.Method() << function(self)
    local itemId = self.m_wikiEntryShowData.wikiEntryData.refItemId
    local buildingObtainWays = self.view.right.obtainWaysNode.buildingObtainWays
    buildingObtainWays:InitItemObtainWays(itemId)
    buildingObtainWays.gameObject:SetActive(buildingObtainWays.hasObtainWay)
    self.view.right.obtainWaysNode.emptyText.gameObject:SetActive(not buildingObtainWays.hasObtainWay)
    for _, buildingTypeDetail in pairs(self.m_buildingTypeDetailTable) do
        buildingTypeDetail.node.gameObject:SetActiveIfNecessary(false)
    end
    self.m_buildingData = FactoryUtils.getItemBuildingData(itemId)
    if self.m_buildingData ~= nil then
        local buildingTypeDetail = self.m_buildingTypeDetailTable[self.m_buildingData.type]
        if not buildingTypeDetail then
            buildingTypeDetail = self.m_buildingTypeDetailTable[GEnums.FacBuildingType.Unknown]
        end
        buildingTypeDetail.node.gameObject:SetActiveIfNecessary(true)
        self[buildingTypeDetail.refreshFunction](self, buildingTypeDetail.node)
    end
end
WikiBuildingDetailCtrl.m_buildingTypeDetailTable = HL.Field(HL.Table)
WikiBuildingDetailCtrl.m_buildingData = HL.Field(HL.Userdata)
WikiBuildingDetailCtrl.m_buildingDetailsDataList = HL.Field(HL.Table)
WikiBuildingDetailCtrl.m_InitBuildingTypeDetailTable = HL.Method() << function(self)
    local detailsListNode = self.view.right.detailsListNode
    self.m_buildingTypeDetailTable = { [GEnums.FacBuildingType.Unknown] = { node = detailsListNode.normalNode, refreshFunction = "_RefreshNormal", }, [GEnums.FacBuildingType.Miner] = { node = detailsListNode.minerNode, refreshFunction = "_RefreshMiner", }, [GEnums.FacBuildingType.Trader] = { node = detailsListNode.traderNode, refreshFunction = "_RefreshTrader", }, [GEnums.FacBuildingType.PowerStation] = { node = detailsListNode.powerStationNode, refreshFunction = "_RefreshPowerStation", }, [GEnums.FacBuildingType.Recycler] = { node = detailsListNode.recyclerNode, refreshFunction = "_RefreshRecycler", }, [GEnums.FacBuildingType.Manufact] = { node = detailsListNode.manufactNode, refreshFunction = "_RefreshManufact", }, [GEnums.FacBuildingType.Hub] = { node = detailsListNode.hubNode, refreshFunction = "_RefreshHub", }, [GEnums.FacBuildingType.Processor] = { node = detailsListNode.processorNode, refreshFunction = "_RefreshProcessor", }, }
end
WikiBuildingDetailCtrl.m_normalCachedCellFunction = HL.Field(HL.Function)
WikiBuildingDetailCtrl._RefreshNormal = HL.Method(HL.Table) << function(self, node)
    if not self.m_normalCachedCellFunction then
        self.m_normalCachedCellFunction = UIUtils.genCachedCellFunction(node.scrollView)
        node.scrollView.onUpdateCell:AddListener(function(object, csIndex)
            local cell = self.m_normalCachedCellFunction(object)
            local normalInfo = self.m_buildingDetailsDataList[LuaIndex(csIndex)]
            normalInfo.buildingId = nil
            cell.craftCell:InitCraftCell(normalInfo)
        end)
    end
    self.m_buildingDetailsDataList = FactoryUtils.getBuildingCrafts(self.m_buildingData.id)
    local count = self.m_buildingDetailsDataList and #self.m_buildingDetailsDataList or 0
    node.scrollView:UpdateCount(count)
    node.emptyText.gameObject:SetActiveIfNecessary(count == 0)
end
WikiBuildingDetailCtrl.m_minerCachedCellFunction = HL.Field(HL.Function)
WikiBuildingDetailCtrl._RefreshMiner = HL.Method(HL.Table) << function(self, node)
    if not self.m_minerCachedCellFunction then
        self.m_minerCachedCellFunction = UIUtils.genCachedCellFunction(node.scrollView)
        node.scrollView.onUpdateCell:AddListener(function(object, csIndex)
            local cell = self.m_minerCachedCellFunction(object)
            local minerInfo = self.m_buildingDetailsDataList[LuaIndex(csIndex)]
            minerInfo.buildingId = nil
            cell.craftCell:InitCraftCell(minerInfo)
        end)
    end
    self.m_buildingDetailsDataList = FactoryUtils.getBuildingCrafts(self.m_buildingData.id)
    local count = self.m_buildingDetailsDataList and #self.m_buildingDetailsDataList or 0
    node.scrollView:UpdateCount(count)
end
WikiBuildingDetailCtrl.m_traderCellCache = HL.Field(HL.Forward("UIListCache"))
WikiBuildingDetailCtrl._RefreshTrader = HL.Method(HL.Table) << function(self, node)
    if not self.m_traderCellCache then
        self.m_traderCellCache = UIUtils.genCellCache(node.traderCellNode)
    end
    local currentTraderLevel = GameInstance.player.facSpMachineSystem:GetLevelByType(GEnums.FacBuildingType.Trader)
    self.m_buildingDetailsDataList = {}
    for contractId, contractData in pairs(Tables.contractTable) do
        if contractData.traderLevel <= currentTraderLevel then
            table.insert(self.m_buildingDetailsDataList, { contractId = contractId, contractData = contractData, })
        end
    end
    self.m_traderCellCache:Refresh(#self.m_buildingDetailsDataList, function(cell, index)
        self:_UpdateTraderCell(cell, index)
    end)
end
WikiBuildingDetailCtrl._UpdateTraderCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local tradeData = self.m_buildingDetailsDataList[index].contractData
    if tradeData == nil then
        return
    end
    local success, contractTypeInfo = Tables.contractTypeTable:TryGetValue(tradeData.type)
    if success then
        cell.titleText.text = string.format(Language.LUA_WIKI_BUILDING_TRADER_TITLE, contractTypeInfo.name, tradeData.contractName)
    end
    if cell.needCells == nil then
        cell.needCells = UIUtils.genCellCache(cell.needItemCell)
    end
    cell.needCells:Refresh(tradeData.neededItems.Count, function(needItemCell, needItemIndex)
        local itemId = tradeData.neededItems[CSIndex(needItemIndex)]
        needItemCell:InitItem({ id = itemId }, true)
    end)
    if cell.rewardCells == nil then
        cell.rewardCells = UIUtils.genCellCache(cell.rewardItemCell)
    end
    cell.rewardCells:Refresh(tradeData.rewardItems.Count, function(rewardItemCell, rewardItemIndex)
        local itemId = tradeData.rewardItems[CSIndex(rewardItemIndex)]
        rewardItemCell:InitItem({ id = itemId }, true)
    end)
end
WikiBuildingDetailCtrl.m_powerStationCachedCellFunction = HL.Field(HL.Function)
WikiBuildingDetailCtrl._RefreshPowerStation = HL.Method(HL.Table) << function(self, node)
    if not self.m_powerStationCachedCellFunction then
        self.m_powerStationCachedCellFunction = UIUtils.genCachedCellFunction(node.scrollView)
        node.scrollView.onUpdateCell:AddListener(function(object, csIndex)
            local cell = self.m_powerStationCachedCellFunction(object)
            local powerStationInfo = self.m_buildingDetailsDataList[LuaIndex(csIndex)]
            powerStationInfo.buildingId = nil
            cell.craftCell:InitCraftCell(powerStationInfo)
        end)
    end
    self.m_buildingDetailsDataList = FactoryUtils.getBuildingCrafts(self.m_buildingData.id)
    local count = self.m_buildingDetailsDataList and #self.m_buildingDetailsDataList or 0
    node.scrollView:UpdateCount(count)
end
WikiBuildingDetailCtrl.m_recyclerProducerCellCache = HL.Field(HL.Forward("UIListCache"))
WikiBuildingDetailCtrl.m_recyclerRecyclableCellCache = HL.Field(HL.Forward("UIListCache"))
WikiBuildingDetailCtrl._RefreshRecycler = HL.Method(HL.Table) << function(self, node)
    if not self.m_recyclerProducerCellCache or not self.m_recyclerRecyclableCellCache then
        self.m_recyclerProducerCellCache = UIUtils.genCellCache(node.productItem)
        self.m_recyclerRecyclableCellCache = UIUtils.genCellCache(node.recyclableItem)
    end
    local productItemIdList = {}
    for productItemId, _ in pairs(Tables.factoryRecyclerProductTable) do
        table.insert(productItemIdList, productItemId)
    end
    self.m_recyclerProducerCellCache:Refresh(#productItemIdList, function(cell, index)
        cell:InitItem({ id = productItemIdList[index] }, true)
    end)
    local recyclableItemIdList = {}
    local inventory = GameInstance.player.inventory
    for recyclableItemId, _ in pairs(Tables.factoryRecyclerMaterialTable) do
        if inventory:IsItemFound(recyclableItemId) then
            table.insert(recyclableItemIdList, recyclableItemId)
        end
    end
    self.m_recyclerRecyclableCellCache:Refresh(#recyclableItemIdList, function(cell, index)
        cell:InitItem({ id = recyclableItemIdList[index] }, true)
    end)
end
WikiBuildingDetailCtrl.m_manufactCellCache = HL.Field(HL.Forward("UIListCache"))
WikiBuildingDetailCtrl._RefreshManufact = HL.Method(HL.Table) << function(self, node)
    if not self.m_manufactCellCache then
        self.m_manufactCellCache = UIUtils.genCellCache(node.manufactCellNode)
    end
    local currentTraderLevel = GameInstance.player.facSpMachineSystem:GetLevelByType(GEnums.FacBuildingType.Manufact)
    local craftsData = FactoryUtils.getBuildingCrafts(self.m_buildingData.id)
    self.m_buildingDetailsDataList = {}
    for _, craftData in pairs(craftsData) do
        if craftData.usableLevel <= currentTraderLevel then
            if self.m_buildingDetailsDataList[craftData.usableLevel] == nil then
                self.m_buildingDetailsDataList[craftData.usableLevel] = {}
            end
            table.insert(self.m_buildingDetailsDataList[craftData.usableLevel], craftData)
        end
    end
    self.m_manufactCellCache:Refresh(#self.m_buildingDetailsDataList, function(cell, index)
        local manufactInfo = self.m_buildingDetailsDataList[index]
        cell.levelText.text = string.format(Language.LUA_WIKI_BUILDING_LEVEL_TEXT, index, self.m_buildingData.name)
        if cell.craftCells == nil then
            cell.craftCells = UIUtils.genCellCache(cell.craftCell)
        end
        cell.craftCells:Refresh(#manufactInfo, function(craftCell, craftCellIndex)
            local craftData = manufactInfo[craftCellIndex]
            craftData.buildingId = nil
            if craftData ~= nil then
                craftCell:InitCraftCell(craftData)
            end
        end)
    end)
end
WikiBuildingDetailCtrl._RefreshHub = HL.Method(HL.Table) << function(self, node)
end
WikiBuildingDetailCtrl._RefreshProcessor = HL.Method(HL.Table) << function(self, node)
end
HL.Commit(WikiBuildingDetailCtrl)