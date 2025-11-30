local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.DomainItemTransferSelect
local RouteStatus = GEnums.DomainTransportRouteStatusType
local MAX_ITEM_COUNT = Tables.factoryConst.domainTransportNumMax
local SEC_PER_HOUR = 3600
local SEC_PER_MIN = 60
local MIN_PER_HOUR = 60
DomainItemTransferSelectCtrl = HL.Class('DomainItemTransferSelectCtrl', uiCtrl.UICtrl)
DomainItemTransferSelectCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_FAC_TRANS_ROUTE_CHANGE] = '_OnNotifyRouteInfoChange', }
DomainItemTransferSelectCtrl.m_targetDomain = HL.Field(HL.String) << ""
DomainItemTransferSelectCtrl.m_chosenItemId = HL.Field(HL.String) << ""
DomainItemTransferSelectCtrl.m_chosenItemCount = HL.Field(HL.Number) << 0
DomainItemTransferSelectCtrl.m_currentSelectItemCell = HL.Field(HL.Any)
DomainItemTransferSelectCtrl.m_waitingToClose = HL.Field(HL.Boolean) << false
DomainItemTransferSelectCtrl.m_info = HL.Field(HL.Any)
DomainItemTransferSelectCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_info = args.info
    self.view.btnBack.onClick:AddListener(function()
        self:_Close()
    end)
    self.view.depotExtraRoot.numberSelector:InitNumberSelector(self:_GetDefaultNumber(), 1, MAX_ITEM_COUNT, function()
        if self.m_chosenItemId ~= "" then
            self.m_chosenItemCount = self.view.depotExtraRoot.numberSelector.curNumber
        else
            self.m_chosenItemCount = 0
        end
        self:_UpdateNumber()
        self:_RefreshBtnAndText()
    end)
    self:_InitBtn()
    self:_InitLeftSidePlatformText(self.m_info.toDomain)
    if self.m_info.status ~= RouteStatus.idle then
        self.m_chosenItemId = self.m_info.itemId
        self.m_chosenItemCount = self.m_info.itemNumMax
        self.m_targetDomain = self.m_info.toDomain
    end
    if self.m_info.status == RouteStatus.idle then
        self:_OpenSelectTargetRoot()
    else
        self:_OpenDepot()
    end
    self.view.depotExtraRoot.timeRemainingText.text = self:_GetTimeText()
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(0.1)
            self.view.depotExtraRoot.timeRemainingText.text = self:_GetTimeText()
        end
    end)
end
DomainItemTransferSelectCtrl._OpenDepot = HL.Method() << function(self)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.forceRebuildTarget)
    self.view.depot.view.depotContent.view.itemList:TryRecalculateSize()
    self.view.leftItemSlotRoot.gameObject:SetActive(true)
    self.view.selectEndPointRoot.gameObject:SetActive(false)
    self.view.selectingTargetMask.gameObject:SetActive(false)
    self.view.leftLineWithEffect.gameObject:SetActive(true)
    self.view.leftLineWithoutEffect.gameObject:SetActive(false)
    local depotArgs = {
        domainId = self.m_info.fromDomain,
        customOnUpdateCell = function(cell, info)
            local itemInfoPack = { id = info.id }
            cell.item:InitItem(itemInfoPack, function()
                self:_OnClickItem(cell, info.id)
                self.view.depotExtraRoot.timeRemainingText.text = self:_GetTimeText()
            end)
            cell.item.view.button.onLongPress:RemoveAllListeners()
            cell.item.view.button.onLongPress:AddListener(function()
                Notify(MessageConst.SHOW_ITEM_TIPS, {
                    itemId = info.id,
                    transform = cell.item.gameObject.transform,
                    onClose = function()
                        cell.item.view.selectedBG.gameObject:SetActive(false)
                    end,
                    posType = UIConst.UI_TIPS_POS_TYPE.LeftMid,
                })
                cell.item.view.selectedBG.gameObject:SetActive(true)
            end)
            cell.item.view.toggle.gameObject:SetActive(self.m_chosenItemId == info.id)
            local itemCount = self:_GetItemCount(info.id)
            cell.item.view.storageNumberText.text = UIUtils.getNumString(itemCount)
            if self.m_chosenItemId == info.id then
                self.m_currentSelectItemCell = cell
            end
        end,
        customItemInfoListPostProcess = function(allItemInfoList)
            if allItemInfoList == nil or next(allItemInfoList) == nil then
                return {}
            end
            local result = {}
            for _, info in ipairs(allItemInfoList) do
                local id = info.id
                local facSuccess, facItemData = Tables.factoryItemTable:TryGetValue(id)
                if facSuccess and not facItemData.itemState then
                    table.insert(result, info)
                end
            end
            return result
        end,
        onChangeTypeFunction = function()
            self:_ClearSelectedItem()
            self:_UpdateNumber()
        end,
        showHistory = true,
        disableDrag = true,
    }
    self.view.depot:InitDepot(GEnums.ItemValuableDepotType.Factory, function(itemId, cell)
        self:_OnClickItem(cell, itemId)
    end, depotArgs)
    self:_RefreshLeftSideItem()
    self:_RefreshBtnAndText()
    self:_UpdateNumber()
end
DomainItemTransferSelectCtrl._TryGetCell = HL.Method(HL.String).Return(HL.Any) << function(self, itemId)
    local depot = self.view.depot
    local depotContent = depot.view.depotContent
    local depotCellIndex = depotContent:GetItemIndex(itemId)
    local cell = depotContent:GetCell(depotCellIndex)
    return cell
end
DomainItemTransferSelectCtrl._RefreshLeftSideItem = HL.Method() << function(self)
    local view = self.view.leftItemSlotRoot
    if not self:_IsCurrentTransmitting() and (self.m_chosenItemId == "") then
        view.itemSlotCenterTriangle.gameObject:SetActive(false)
        view.itemCanceled.gameObject:SetActive(false)
        view.itemTarget.gameObject:SetActive(false)
        view.itemEmpty.gameObject:SetActive(true)
        view.itemSlotsRightTriangle.gameObject:SetActive(false)
        return
    elseif not self:_IsCurrentTransmitting() and (self.m_chosenItemId ~= "") then
        view.itemSlotCenterTriangle.gameObject:SetActive(true)
        view.itemCanceled.gameObject:SetActive(false)
        view.itemTarget.gameObject:SetActive(true)
        view.itemEmpty.gameObject:SetActive(false)
        view.itemSlotsRightTriangle.gameObject:SetActive(true)
        local itemDataPack = { id = self.m_chosenItemId, count = self.m_chosenItemCount, }
        view.itemTarget:InitItem(itemDataPack, true)
        return
    elseif self:_IsCurrentTransmitting() and not self:_IsItemModified() then
        view.itemSlotCenterTriangle.gameObject:SetActive(false)
        view.itemCanceled.gameObject:SetActive(false)
        view.itemTarget.gameObject:SetActive(true)
        view.itemEmpty.gameObject:SetActive(false)
        view.itemSlotsRightTriangle.gameObject:SetActive(true)
        local itemDataPack = { id = self.m_info.itemId, count = self.m_info.itemNumMax, }
        view.itemTarget:InitItem(itemDataPack, true)
        return
    elseif self:_IsCurrentTransmitting() and self:_IsItemModified() then
        view.itemSlotCenterTriangle.gameObject:SetActive(true)
        view.itemCanceled.gameObject:SetActive(true)
        view.itemTarget.gameObject:SetActive(true)
        view.itemEmpty.gameObject:SetActive(false)
        view.itemSlotsRightTriangle.gameObject:SetActive(false)
        local itemCanceledPack = { id = self.m_info.itemId, count = self.m_info.itemNumMax, }
        view.itemCanceled:InitItem(itemCanceledPack, true)
        local itemTargetPack = { id = self.m_chosenItemId, count = self.m_chosenItemCount, }
        view.itemTarget:InitItem(itemTargetPack, true)
        return
    end
end
DomainItemTransferSelectCtrl._ClearSelectedItem = HL.Method() << function(self)
    self:_OnClickItem(nil, "")
end
DomainItemTransferSelectCtrl._OnClickItem = HL.Method(HL.Any, HL.String) << function(self, itemCell, itemId)
    if self:_IsCurrentTransmitting() and itemId == self.m_chosenItemId then
        return
    end
    if self.m_currentSelectItemCell ~= nil then
        local view = self.m_currentSelectItemCell.view
        if view ~= nil then
            local toggle = view.item.view.toggle
            if toggle ~= nil then
                toggle.gameObject:SetActive(false)
            end
        end
        self.m_currentSelectItemCell = nil
    end
    if itemId == "" or (not self:_IsCurrentTransmitting() and itemId == self.m_chosenItemId) then
        self.m_chosenItemId = self.m_info.itemId
        self:_ChangeCount(self.m_info.itemNumMax)
        if self:_IsCurrentTransmitting() then
            local toggleCell = self:_TryGetCell(self.m_info.itemId)
            self.m_currentSelectItemCell = toggleCell
            if self.m_currentSelectItemCell ~= nil then
                self.m_currentSelectItemCell.view.item.view.toggle.gameObject:SetActive(true)
            end
        end
        self:_RefreshBtnAndText()
        self:_RefreshLeftSideItem()
        self:_UpdateNumber()
        return
    end
    if itemId ~= self.m_chosenItemId and itemId ~= "" then
        self.m_currentSelectItemCell = itemCell
        self.m_chosenItemId = itemId
        local targetCount = self:_GetCurrentNeedAssignCount()
        self:_ChangeCount(targetCount)
        self.m_currentSelectItemCell.view.item.view.toggle.gameObject:SetActive(true)
    end
    self:_RefreshBtnAndText()
    self:_RefreshLeftSideItem()
    self:_UpdateNumber()
end
DomainItemTransferSelectCtrl._GetCurrentNeedAssignCount = HL.Method().Return(HL.Number) << function(self)
    if self:_IsCurrentTransmitting() then
        return self.view.depotExtraRoot.numberSelector.curNumber
    end
    if self.m_chosenItemCount ~= 0 then
        return self.m_chosenItemCount
    end
    return MAX_ITEM_COUNT
end
DomainItemTransferSelectCtrl._RefreshBtnAndText = HL.Method() << function(self)
    local itemModified = self:_IsItemModified()
    self.view.startTransBtn.gameObject:SetActive(itemModified)
    local blockOrRetry = (self.m_info.status == RouteStatus.blocked) or (self.m_info.status == RouteStatus.retry)
    self.view.transmittingFakeBtn.gameObject:SetActive(self:_IsCurrentTransmitting() and (not blockOrRetry) and (not itemModified))
    local showCancelBtn = self:_IsCurrentTransmitting() and itemModified
    self.view.cancelSelectBtn.gameObject:SetActive(showCancelBtn)
    local depotExtra = self.view.depotExtraRoot
    local showChooseText = (self.m_chosenItemId == "")
    self.view.depot.view.bottomNode.gameObject:SetActive(showChooseText)
    self.view.depot.view.sortNode.gameObject:SetActive(showChooseText)
    depotExtra.selectItemInDepotRoot.gameObject:SetActive(showChooseText)
    depotExtra.transPausedRoot.gameObject:SetActive(blockOrRetry and (not itemModified))
    if showChooseText then
        depotExtra.timeRemainingRoot.gameObject:SetActive(false)
    else
        depotExtra.timeRemainingRoot.gameObject:SetActive((not blockOrRetry) or (itemModified))
    end
    depotExtra.numberSelector.gameObject:SetActive(not showChooseText)
    self.view.depot.view.sortNode.gameObject:SetActive(showChooseText)
end
DomainItemTransferSelectCtrl._Close = HL.Method() << function(self)
    self:PlayAnimationOut(UIConst.PANEL_PLAY_ANIMATION_OUT_COMPLETE_ACTION_TYPE.Close)
end
DomainItemTransferSelectCtrl._InitBtn = HL.Method() << function(self)
    local view = self.view.leftItemSlotRoot
    view.changeTargetBtn.onClick:AddListener(function()
        self:_OpenSelectTargetRoot()
    end)
    view.stopTransBtn.onClick:AddListener(function()
        self:Notify(MessageConst.SHOW_POP_UP, {
            content = Language.LUA_FAC_TRANS_CONFIRM_RESET,
            onConfirm = function()
                self:_DoResetRoute()
            end,
            onCancel = function()
                self:_ClearSelectedItem()
                self:_UpdateNumber()
            end
        })
    end)
    view.changeTargetBtn.gameObject:SetActive(not self:_IsCurrentTransmitting())
    view.stopTransBtn.gameObject:SetActive(self:_IsCurrentTransmitting())
    self.view.cancelSelectBtn.onClick:AddListener(function()
        self:_ClearSelectedItem()
    end)
    if self:_IsCurrentTransmitting() then
        self.view.startTransBtnText.text = Language.LUA_FAC_TRANS_MODIFY_BTN_TEXT
        self.view.startTransBtn.onClick:AddListener(function()
            self:Notify(MessageConst.SHOW_POP_UP, {
                content = Language.LUA_FAC_TRANS_CONFIRM_MODIFY,
                onConfirm = function()
                    self:_DoChangeRoute()
                end,
                onCancel = function()
                    self:_ClearSelectedItem()
                    self:_UpdateNumber()
                end
            })
        end)
    else
        self.view.startTransBtnText.text = Language.LUA_FAC_TRANS_START_BTN_TEXT
        self.view.startTransBtn.onClick:AddListener(function()
            self:_DoChangeRoute()
        end)
    end
end
DomainItemTransferSelectCtrl._OpenSelectTargetRoot = HL.Method() << function(self)
    self.view.selectingTargetMask.gameObject:SetActive(true)
    self.view.leftItemSlotRoot.gameObject:SetActive(false)
    self.view.selectEndPointRoot.gameObject:SetActive(true)
    self.view.leftLineWithEffect.gameObject:SetActive(false)
    self.view.leftLineWithoutEffect.gameObject:SetActive(true)
    self:_InitLeftSidePlatformText("")
    local panel = self.view.selectEndPointRoot
    if panel.cellCache ~= nil then
        return
    end
    panel.cellCache = UIUtils.genCellCache(panel.siteCell)
    local domainList = {}
    for key, domainInfo in pairs(Tables.domainDataTable) do
        if domainInfo.domainId ~= self.m_info.fromDomain then
            table.insert(domainList, domainInfo)
        end
    end
    table.sort(domainList, Utils.genSortFunction({ "sortId" }, true))
    panel.cellCache:Refresh(#domainList, function(cell, index)
        local domainData = domainList[index]
        local domainName = domainData.domainName
        local domainId = domainData.domainId
        cell.text.text = domainName
        cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_TRANS, UIConst.FAC_TRANS_DOMAIN_ICONS[domainId])
        cell.button.onClick:AddListener(function()
            self:_OnSelectTargetDomain(domainId)
        end)
    end)
end
DomainItemTransferSelectCtrl._UpdateNumber = HL.Method() << function(self)
    local view = self.view.leftItemSlotRoot
    if not self:_IsItemModified() then
        local showNotEnoughItem = (self.m_info.itemNum ~= self.m_info.itemNumMax)
        self.view.notEnoughItemText.text = tostring(self.m_info.itemNum)
        self.view.notEnoughItemRoot.gameObject:SetActive(showNotEnoughItem)
        if self:_IsCurrentTransmitting() then
            local itemTargetPack = { id = self.m_chosenItemId, count = self.m_chosenItemCount, }
            view.itemTarget:InitItem(itemTargetPack, true)
        end
        return
    end
    if self.m_chosenItemId == "" then
        self.view.notEnoughItemRoot.gameObject:SetActive(false)
        return
    end
    local itemTargetPack = { id = self.m_chosenItemId, count = self.m_chosenItemCount, }
    view.itemTarget:InitItem(itemTargetPack, true)
    local depotCount = self:_GetItemCount(self.m_chosenItemId)
    self.view.notEnoughItemRoot.gameObject:SetActive(depotCount < self.m_chosenItemCount)
    self.view.notEnoughItemText.text = tostring(depotCount)
end
DomainItemTransferSelectCtrl._GetItemCount = HL.Method(HL.String).Return(HL.Number) << function(self, itemId)
    local factoryDepot = GameInstance.player.inventory.factoryDepot
    local depotInChapter = factoryDepot:GetOrFallback(Utils.getCurrentScope())
    local actualDepot = depotInChapter[ScopeUtil.ChapterIdStr2Int(self.m_info.fromDomain)]
    local count = actualDepot:GetCount(itemId)
    return count
end
DomainItemTransferSelectCtrl._InitLeftSidePlatformText = HL.Method(HL.String) << function(self, targetDomainId)
    local domainInfo = Tables.domainDataTable[self.m_info.fromDomain]
    self.view.platformFrom.Text.text = domainInfo.domainName
    if targetDomainId ~= "" then
        local targetDomainInfo = Tables.domainDataTable[targetDomainId]
        self.view.platformTo.Text.text = targetDomainInfo.domainName
        return
    else
        local found, targetDomainInfo = Tables.domainDataTable:TryGetValue(self.m_info.toDomain)
        if not found then
            self.view.platformTo.Text.text = ""
        else
            self.view.platformTo.Text.text = targetDomainInfo.domainName
        end
    end
end
DomainItemTransferSelectCtrl._IsCurrentTransmitting = HL.Method().Return(HL.Boolean) << function(self)
    return (self.m_info.status ~= RouteStatus.idle)
end
DomainItemTransferSelectCtrl._GetDefaultNumber = HL.Method().Return(HL.Number) << function(self)
    if self:_IsCurrentTransmitting() then
        return self.m_info.itemNumMax
    end
    return MAX_ITEM_COUNT
end
DomainItemTransferSelectCtrl._IsItemModified = HL.Method().Return(HL.Boolean) << function(self)
    return (self.m_chosenItemId ~= self.m_info.itemId) or (self.m_chosenItemCount ~= self.m_info.itemNumMax)
end
DomainItemTransferSelectCtrl._GiveUpItemSelect = HL.Method() << function(self)
    if self:_IsCurrentTransmitting() then
        self.m_chosenItemId = self.m_info.itemId
        self:_ChangeCount(self.m_info.itemNumMax)
        self.m_chosenItemCount = 0
        return
    end
    self.m_chosenItemId = ""
    self.m_chosenItemCount = 0
end
DomainItemTransferSelectCtrl._DoChangeRoute = HL.Method() << function(self)
    local itemId = self.m_chosenItemId
    local itemCount = self.m_chosenItemCount
    local toDomain = self.m_targetDomain
    local fromDomain = self.m_info.fromDomain
    local index = self.m_info.index
    GameInstance.player.remoteFactory:SendReqSetHubTransRoute(fromDomain, toDomain, index, itemId, itemCount)
    self.m_waitingToClose = true
end
DomainItemTransferSelectCtrl._ChangeCount = HL.Method(HL.Number) << function(self, count)
    self.m_chosenItemCount = count
    self.view.depotExtraRoot.numberSelector:_Refresh(count)
end
DomainItemTransferSelectCtrl._DoResetRoute = HL.Method() << function(self)
    local routeInfo = self.m_info
    GameInstance.player.remoteFactory:SendReqResetHubTransRoute(routeInfo.fromDomain, routeInfo.index)
    self.m_waitingToClose = true
end
DomainItemTransferSelectCtrl._OnSelectTargetDomain = HL.Method(HL.String) << function(self, domainId)
    self.view.animationWrapper:Play("domainItemtransferselect_out_2", function()
        self:_InitLeftSidePlatformText(domainId)
        self.m_targetDomain = domainId
        self:_OpenDepot()
        self.view.animationWrapper:Play("domainItemtransferselect_in_2")
    end)
end
DomainItemTransferSelectCtrl._OnNotifyRouteInfoChange = HL.Method() << function(self)
    if self.m_waitingToClose then
        self:_Close()
    end
end
DomainItemTransferSelectCtrl._GetTimeText = HL.Method().Return(HL.String) << function(self)
    local curTime = DateTimeUtils.GetCurrentTimestampBySeconds()
    local lastTryTime = self.m_info.timeStamp - self.m_info.progress
    local curProgress = curTime - lastTryTime
    local needTime = Tables.factoryConst.domainTransportIntervalTime
    local curNeedTimeSec = needTime - curProgress
    if (not self:_IsCurrentTransmitting()) or self:_IsItemModified() then
        curNeedTimeSec = needTime
    end
    while curNeedTimeSec < 0 do
        local reverse = -curNeedTimeSec
        local times = reverse // needTime
        if reverse % needTime > 0 then
            times = times + 1
        end
        curNeedTimeSec = curNeedTimeSec + needTime * times
    end
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
HL.Commit(DomainItemTransferSelectCtrl)