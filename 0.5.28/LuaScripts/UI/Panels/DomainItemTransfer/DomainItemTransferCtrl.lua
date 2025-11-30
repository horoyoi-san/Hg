local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.DomainItemTransfer
local PHASE_ID = PhaseId.DomainItemTransfer
local INDEX_CONST = 1
local RouteStatus = GEnums.DomainTransportRouteStatusType
local UPPER_PLAT_DOMAIN = "domain_1"
local LOWER_PLAT_DOMAIN = "domain_2"
local SEC_PER_HOUR = 3600
local MIN_PER_HOUR = 60
local SEC_PER_MIN = 60
DomainItemTransferCtrl = HL.Class('DomainItemTransferCtrl', uiCtrl.UICtrl)
DomainItemTransferCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_FAC_TRANS_ROUTE_CHANGE] = '_OnNotifyRouteInfoChange', }
DomainItemTransferCtrl.m_domainInfoList = HL.Field(HL.Table)
DomainItemTransferCtrl.m_cacheRouteList = HL.Field(HL.Forward("UIListCache"))
DomainItemTransferCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_domainInfoList = {}
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.DomainItemTransfer)
    end)
    self.m_cacheRouteList = UIUtils.genCellCache(self.view.transmissionLine)
    self:_BuildDomainList()
    self:_SetPlatformText()
    local domainRouteInfo = self:_GetDomainRouteInfo()
    self:_BuildRoutes(domainRouteInfo)
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(0.1)
            self:_RefreshAllCell()
        end
    end)
end
DomainItemTransferCtrl.OnClose = HL.Override() << function(self)
    if UIManager:IsOpen(PanelId.DomainItemTransferSelect) then
        UIManager:Close(PanelId.DomainItemTransferSelect)
    end
end
DomainItemTransferCtrl._RebuildAll = HL.Method() << function(self)
    self.m_domainInfoList = {}
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.DomainItemTransfer)
    end)
    self:_BuildDomainList()
    self:_SetPlatformText()
    local domainRouteInfo = self:_GetDomainRouteInfo()
    self:_BuildRoutes(domainRouteInfo)
end
DomainItemTransferCtrl._SetPlatformText = HL.Method() << function(self)
    local upperText = Tables.domainDataTable[UPPER_PLAT_DOMAIN].domainName
    self.view.platformTopCell.Text.text = upperText
    local lowerText = Tables.domainDataTable[LOWER_PLAT_DOMAIN].domainName
    self.view.platformBottomCell.Text.text = lowerText
end
DomainItemTransferCtrl._BuildDomainList = HL.Method() << function(self)
    self.m_domainInfoList = {}
    for key, domainInfo in pairs(Tables.domainDataTable) do
        table.insert(self.m_domainInfoList, domainInfo)
    end
    table.sort(self.m_domainInfoList, Utils.genSortFunction({ "sortId" }, true))
end
DomainItemTransferCtrl._GetDomainRouteInfo = HL.Method().Return(HL.Table) << function(self)
    local ret = {}
    for _, domainInfo in ipairs(self.m_domainInfoList) do
        local domainId = domainInfo.domainId
        table.insert(ret, self:_GetRouteInfo(domainId))
    end
    return ret
end
DomainItemTransferCtrl._BuildRoutes = HL.Method(HL.Table) << function(self, routeInfoList)
    local buildCellTable = {}
    for i = 1, #self.m_domainInfoList do
        local routeInfo = routeInfoList[i]
        if i == 1 then
            self:_BuildTrackView(self.view.rightTrack, routeInfo)
        else
            self:_BuildTrackView(self.view.leftTrack, routeInfo)
        end
        if routeInfo ~= nil then
            table.insert(buildCellTable, routeInfo)
        end
    end
    self.m_cacheRouteList:Refresh(#buildCellTable, function(route, index)
        self:_BuildRouteCellView(route, buildCellTable[index])
    end)
    self:_RefreshAllCell()
end
DomainItemTransferCtrl._BuildRouteCellView = HL.Method(HL.Any, HL.Any) << function(self, cell, info)
    cell.info = info
    local isIdle = (info.status == RouteStatus.idle and info.toDomain ~= "")
    local isTransmitting = (info.status == RouteStatus.working or info.status == RouteStatus.notFill)
    local isBlocked = (info.status == RouteStatus.blocked)
    local isRetry = (info.status == RouteStatus.retry)
    local isNoTarget = (info.toDomain == "")
    cell.idleRoot.gameObject:SetActive(isIdle)
    cell.transmittingRoot.gameObject:SetActive(isTransmitting)
    cell.blockRoot.gameObject:SetActive(isBlocked)
    cell.retryRoot.gameObject:SetActive(isRetry)
    cell.noTargetRoot.gameObject:SetActive(isNoTarget)
    cell.notEnoughItemRoot.gameObject:SetActive(false)
    self:_SetSideCell(cell.leftSideNode, info.fromDomain)
    self:_SetSideCell(cell.rightSideNode, info.toDomain)
    cell.normalItem.gameObject:SetActive(isTransmitting or isBlocked)
    cell.retryItem.gameObject:SetActive(isRetry)
    cell.idleItem.gameObject:SetActive(isIdle)
    cell.restartBtn.onClick:RemoveAllListeners()
    cell.restartBtn.onClick:AddListener(function()
        self:_ReqRestartRoute(info)
    end)
    cell.editBtn.onClick:RemoveAllListeners()
    cell.editBtn.onClick:AddListener(function()
        self:_OpenEditPanel(info)
    end)
    cell.restartBtn.gameObject:SetActive(isBlocked)
    cell.editBtn.gameObject:SetActive(true)
    if isRetry then
        local itemInfoPack = { id = info.itemId, count = info.itemNumMax, }
        cell.retryItem:InitItem(itemInfoPack, true)
        return
    end
    if isTransmitting or isBlocked then
        local itemInfoPack = { id = info.itemId, count = info.itemNum }
        cell.normalItem:InitItem(itemInfoPack, true)
        if info.itemNum ~= info.itemNumMax then
            cell.normalItem.view.count.text = tostring(info.itemNum) .. "/" .. tostring(info.itemNumMax)
            cell.notEnoughItemRoot.gameObject:SetActive(true)
        end
        return
    end
end
DomainItemTransferCtrl._RefreshItemCount = HL.Method(HL.Any) << function(self, cell)
    local info = cell.info
    local isTransmitting = (info.status == RouteStatus.working or info.status == RouteStatus.notFill)
    local isBlocked = (info.status == RouteStatus.blocked)
    if isTransmitting or isBlocked then
        local itemInfoPack = { id = info.itemId, count = info.itemNum }
        cell.normalItem:InitItem(itemInfoPack, true)
        if info.itemNum ~= info.itemNumMax then
            cell.normalItem.view.count.text = tostring(info.itemNum) .. "/" .. tostring(info.itemNumMax)
            cell.notEnoughItemRoot.gameObject:SetActive(true)
        end
        return
    end
end
DomainItemTransferCtrl._RefreshAllCell = HL.Method() << function(self)
    self.m_cacheRouteList:Update(function(cell, index)
        self:_RefreshCellTimeText(cell)
        self:_RefreshCellBlockState(cell)
        self:_RefreshItemCount(cell)
    end)
end
DomainItemTransferCtrl._RefreshCellTimeText = HL.Method(HL.Any) << function(self, cell)
    local info = cell.info
    cell.transmittingRoot.timeText.text = self:_GetTimeText(info)
    cell.retryRoot.retryText.text = self:_GetTimeText(info)
end
DomainItemTransferCtrl._RefreshCellBlockState = HL.Method(HL.Any) << function(self, cell)
    local info = cell.info
    if info.status ~= RouteStatus.blocked then
        return
    end
    local itemId = info.itemId
    local itemCount = info.itemNum
    local factoryDepot = GameInstance.player.inventory.factoryDepot
    local depotInChapter = factoryDepot:GetOrFallback(Utils.getCurrentScope())
    local actualDepot = depotInChapter[ScopeUtil.ChapterIdStr2Int(info.toDomain)]
    local canPut = actualDepot:CanPutInItem(itemId, itemCount)
    cell.blockRoot.pleaseRestartNode.gameObject:SetActive(canPut)
    cell.blockRoot.spaceIsNotEnoughNode.gameObject:SetActive(not canPut)
end
DomainItemTransferCtrl._SetSideCell = HL.Method(HL.Any, HL.Any) << function(self, sideCell, domainId)
    local selected = (domainId ~= "")
    sideCell.selectedRoot.gameObject:SetActive(selected)
    sideCell.nonSelectedRoot.gameObject:SetActive(not selected)
    if selected then
        local domainInfo = Tables.domainDataTable[domainId]
        sideCell.selectedText.text = domainInfo.domainName
        sideCell.selectedIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_TRANS, UIConst.FAC_TRANS_DOMAIN_ICONS[domainId])
    end
end
DomainItemTransferCtrl._BuildTrackView = HL.Method(HL.Any, HL.Any) << function(self, track, routeInfo)
    local notUnlocked = (routeInfo == nil)
    local stuck = false
    local idle = false
    local working = false
    local noTarget = false
    if (routeInfo ~= nil) then
        stuck = (routeInfo.status == RouteStatus.blocked)
        idle = (routeInfo.status == RouteStatus.idle or routeInfo.status == RouteStatus.retry)
        working = (routeInfo.status == RouteStatus.working or routeInfo.status == RouteStatus.notFill)
        if routeInfo.toDomain == "" then
            noTarget = true
            idle = false
        end
    end
    track.notUnlockedRoot.gameObject:SetActive(notUnlocked)
    track.stuckRoot.gameObject:SetActive(stuck)
    track.normalRoot.gameObject:SetActive(working)
    track.idleRoot.gameObject:SetActive(idle)
    track.noTargetRoot.gameObject:SetActive(noTarget)
end
DomainItemTransferCtrl._GetRouteInfo = HL.Method(HL.String).Return(HL.Any) << function(self, domainId)
    return GameInstance.player.remoteFactory:GetFacHubTransData(domainId, INDEX_CONST)
end
DomainItemTransferCtrl._GetTimeText = HL.Method(HL.Any).Return(HL.String) << function(self, info)
    local curTime = DateTimeUtils.GetCurrentTimestampBySeconds()
    local lastTryTime = info.timeStamp - info.progress
    local curProgress = curTime - lastTryTime
    local needTime = Tables.factoryConst.domainTransportIntervalTime
    local curNeedTimeSec = needTime - curProgress
    local curNeedHour = curNeedTimeSec // SEC_PER_HOUR
    local restSec = curNeedTimeSec % SEC_PER_HOUR
    local curNeedMin = restSec // SEC_PER_MIN
    restSec = restSec % SEC_PER_MIN
    if restSec % SEC_PER_MIN > 0 then
        curNeedMin = curNeedMin + 1
    end
    if curNeedMin >= MIN_PER_HOUR then
        curNeedMin = curNeedMin - 60
        curNeedHour = curNeedHour + 1
    end
    local hourText = ""
    if curNeedHour > 0 then
        hourText = string.format(Language.LUA_TIME_HOUR, curNeedHour)
    end
    local minuteText = ""
    if curNeedMin > 0 then
        minuteText = string.format(Language.LUA_TIME_MIN, curNeedMin)
    end
    local text = hourText .. minuteText
    return text
end
DomainItemTransferCtrl._ReqRestartRoute = HL.Method(HL.Any) << function(self, routeInfo)
    GameInstance.player.remoteFactory:SendReqRestartHubTransRoute(routeInfo.fromDomain, routeInfo.index)
end
DomainItemTransferCtrl._OpenEditPanel = HL.Method(HL.Any) << function(self, routeInfo)
    local args = { info = routeInfo }
    UIManager:Open(PanelId.DomainItemTransferSelect, args)
end
DomainItemTransferCtrl._OnNotifyRouteInfoChange = HL.Method() << function(self)
    self:_RebuildAll()
end
HL.Commit(DomainItemTransferCtrl)