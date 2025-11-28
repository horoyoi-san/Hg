local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.StaminaPopUp
StaminaPopUpCtrl = HL.Class('StaminaPopUpCtrl', uiCtrl.UICtrl)
StaminaPopUpCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_STAMINA_CHANGED] = '_OnStaminaChanged', [MessageConst.ON_ITEM_COUNT_CHANGED] = '_OnItemCountChangedImm', [MessageConst.ON_WALLET_CHANGED] = '_OnWalletChanged', }
local ExchangeStateEnum = { QuickExchange = 0, ExchangeOfItem = 1, ExchangeOfOriginium = 2, }
StaminaPopUpCtrl.m_exchangeState = HL.Field(HL.Number) << 0
StaminaPopUpCtrl.m_coroutineRecover = HL.Field(HL.Thread)
StaminaPopUpCtrl.m_totalExchangeStamina = HL.Field(HL.Number) << 0
StaminaPopUpCtrl.m_genItemCells = HL.Field(HL.Forward("UIListCache"))
StaminaPopUpCtrl.m_allItemTableInfoList = HL.Field(HL.Table)
StaminaPopUpCtrl.m_invItemInfoList = HL.Field(HL.Table)
StaminaPopUpCtrl.m_quickExchangeItemId = HL.Field(HL.String) << ""
StaminaPopUpCtrl.m_quickExchangeItemTableInfo = HL.Field(HL.Table)
StaminaPopUpCtrl.m_quickExchangeItemInfo = HL.Field(HL.Table)
StaminaPopUpCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local itemTog = self.view.exchangeNode.costItemTabTog
    local originiumTog = self.view.exchangeNode.costOriginiumTabTog
    itemTog.onValueChanged:RemoveAllListeners()
    itemTog.onValueChanged:AddListener(function(isOn)
        if isOn then
            self:_RefreshUIExchangeCostItem()
        end
    end)
    originiumTog.onValueChanged:RemoveAllListeners()
    originiumTog.onValueChanged:AddListener(function(isOn)
        if isOn then
            self:_RefreshUIExchangeCostOriginium()
        end
    end)
    self.view.fullScreenCloseBtn.onClick:AddListener(function()
        self:_DoClose()
    end)
    self.view.closeBtn.onClick:AddListener(function()
        self:_DoClose()
    end)
    self.view.confirmBtn.onClick:AddListener(function()
        self:_OnConfirm()
    end)
    self.m_genItemCells = UIUtils.genCellCache(self.view.exchangeNode.costItemCell)
    self:_InitBasicUI()
    if arg then
        self:_InitQuickExchange(arg)
    else
        self:_InitNormalExchange()
    end
    self:_RefreshTickRecoverTxt()
    self:_TryStartTickRecover()
    AudioManager.PostEvent("au_ui_menu_side_open")
end
StaminaPopUpCtrl.OnClose = HL.Override() << function(self)
    self:_StopTickRecover()
end
StaminaPopUpCtrl._OnItemCountChangedImm = HL.Method(HL.Table) << function(self, eventData)
    if not eventData then
        return
    end
    local itemId2DiffCount = unpack(eventData)
    if self.m_exchangeState == ExchangeStateEnum.ExchangeOfItem then
        if self.m_allItemTableInfoList then
            for _, v in ipairs(self.m_allItemTableInfoList) do
                if itemId2DiffCount:ContainsKey(v.itemId) then
                    self:_UpdateItemData()
                    self:_RefreshUIExchangeCostItem()
                    break
                end
            end
        end
    elseif self.m_exchangeState == ExchangeStateEnum.QuickExchange then
        if itemId2DiffCount:ContainsKey(self.m_quickExchangeItemId) then
            self:_UpdateQuickExchangeItemData()
            self:_RefreshUIQuickExchange()
        end
    end
end
StaminaPopUpCtrl._OnWalletChanged = HL.Method(HL.Table) << function(self, eventData)
    if not eventData then
        return
    end
    local data = unpack(eventData)
    if self.m_exchangeState == ExchangeStateEnum.ExchangeOfOriginium and data == Tables.dungeonConst.recoverApMoneyId then
        self:_RefreshUIExchangeCostOriginium()
    end
end
StaminaPopUpCtrl._OnStaminaChanged = HL.Method() << function(self)
    self:_TryStartTickRecover()
    self:_RefreshUICurrentAndTargetStamina()
end
StaminaPopUpCtrl._OnConfirm = HL.Method() << function(self)
    AudioAdapter.PostEvent("au_ui_item_ap_supply_use")
    local targetStamina = self.m_totalExchangeStamina + GameInstance.player.inventory.curStamina
    local staminaLimit = Tables.dungeonConst.staminaCapacity
    if targetStamina > staminaLimit then
        local originiumItemCfg = Utils.tryGetTableCfg(Tables.itemTable, Tables.dungeonConst.recoverApMoneyId)
        local originiumName = originiumItemCfg.name
        local tipStr = string.format(Language.LUA_STAMINA_POPUP_EXCEED_STAMINA_LIMIT_TIP, originiumName, staminaLimit)
        Notify(MessageConst.SHOW_TOAST, tipStr)
        return
    end
    if self.m_exchangeState == ExchangeStateEnum.ExchangeOfItem then
        local msg = CS.Proto.CS_DUNGEON_RECOVER_AP()
        msg.UseMoney = false
        for i, info in ipairs(self.m_invItemInfoList) do
            if info.selectCount > info.invCount then
                Notify(MessageConst.SHOW_TOAST, string.format(Language.LUA_STAMINA_LACK_ITEM_TOAST, info.itemTableData.name))
                return
            end
            local bundle = CS.Proto.ITEM_BUNDLE()
            bundle.Id = info.itemId
            bundle.Count = info.selectCount
            msg.Items:Add(bundle)
        end
        GameInstance.player.inventory:SendUIMsg(msg)
    elseif self.m_exchangeState == ExchangeStateEnum.ExchangeOfOriginium then
        local msg = CS.Proto.CS_DUNGEON_RECOVER_AP()
        msg.UseMoney = true
        GameInstance.player.inventory:SendUIMsg(msg)
    else
        local info = self.m_quickExchangeItemInfo
        if info.selectCount > info.count then
            Notify(MessageConst.SHOW_TOAST, string.format(Language.LUA_STAMINA_LACK_ITEM_TOAST, info.itemTableData.name))
            return
        end
        local msg = CS.Proto.CS_DUNGEON_RECOVER_AP()
        msg.UseMoney = false
        local bundle = CS.Proto.ITEM_BUNDLE()
        bundle.Id = self.m_quickExchangeItemId
        bundle.Count = self.m_quickExchangeItemInfo.selectCount
        msg.Items:Add(bundle)
        GameInstance.player.inventory:SendUIMsg(msg)
    end
    self:_DoClose()
end
StaminaPopUpCtrl._DoClose = HL.Method() << function(self)
    self:PlayAnimationOut(UIConst.PANEL_PLAY_ANIMATION_OUT_COMPLETE_ACTION_TYPE.Close)
    AudioManager.PostEvent("au_ui_menu_side_close")
end
StaminaPopUpCtrl._InitQuickExchange = HL.Method(HL.Any) << function(self, itemId)
    self.m_quickExchangeItemId = itemId
    self.m_exchangeState = ExchangeStateEnum.QuickExchange
    self.view.exchangeState:SetState("QuickExchangeState")
    self.view.buttonOperateState:SetState("OnlyConfirmState")
    self:_UpdateQuickExchangeItemData()
    self:_RefreshUIQuickExchange()
end
StaminaPopUpCtrl._InitNormalExchange = HL.Method() << function(self)
    self.view.exchangeState:SetState("ExchangeState")
    self:_UpdateItemData()
    if self:_HasItemForExchange() then
        self.view.exchangeNode.costItemTabTog.isOn = true
        self:_RefreshUIExchangeCostItem()
    else
        self.view.exchangeNode.costOriginiumTabTog.isOn = true
        self:_RefreshUIExchangeCostOriginium()
    end
end
StaminaPopUpCtrl._InitBasicUI = HL.Method() << function(self)
    local originiumItemCfg = Utils.tryGetTableCfg(Tables.itemTable, Tables.dungeonConst.recoverApMoneyId)
    local originiumName = originiumItemCfg.name
    local staminaItemCfg = Utils.tryGetTableCfg(Tables.itemTable, Tables.globalConst.apItemId)
    local staminaName = staminaItemCfg.name
    local tabName = string.format(Language.LUA_STAMINA_POPUP_EXCHANGE_COST_ORIGINIUM, originiumName)
    self.view.exchangeNode.costOriginiumNode.staminaNameTxt.text = staminaName
    self.view.insufficientOriginiumTxt.text = string.format(Language.LUA_STAMINA_POPUP_INSUFFICIENT_TXT, originiumName)
    self.view.exchangeNode.costOriginiumTxt.text = tabName
    self.view.exchangeNode.costOriginiumTxt2.text = tabName
end
StaminaPopUpCtrl._InitItemTableData = HL.Method() << function(self)
    self.m_allItemTableInfoList = {}
    for id, cfg in pairs(Tables.recoverApItemTable) do
        table.insert(self.m_allItemTableInfoList, { itemId = id, recoverValue = cfg.apRecoverValue, itemTableData = Tables.itemTable:GetValue(id), })
    end
end
StaminaPopUpCtrl._UpdateItemData = HL.Method() << function(self)
    if not self.m_allItemTableInfoList then
        self:_InitItemTableData()
    end
    self.m_invItemInfoList = {}
    for _, v in ipairs(self.m_allItemTableInfoList) do
        local itemCount = GameInstance.player.inventory:GetItemCount(Utils.getCurrentScope(), Utils.getCurrentChapterId(), v.itemId)
        if itemCount > 0 then
            table.insert(self.m_invItemInfoList, { itemId = v.itemId, recoverValue = v.recoverValue, itemTableData = v.itemTableData, invCount = itemCount, selectCount = 0, })
        end
    end
end
StaminaPopUpCtrl._UpdateQuickExchangeItemData = HL.Method() << function(self)
    if not self.m_allItemTableInfoList then
        self:_InitItemTableData()
        for _, v in ipairs(self.m_allItemTableInfoList) do
            if (v.itemId == self.m_quickExchangeItemId) then
                self.m_quickExchangeItemTableInfo = v
                break
            end
        end
    end
    local tableInfo = self.m_quickExchangeItemTableInfo
    self.m_quickExchangeItemInfo = { name = tableInfo.itemTableData.name, desc = tableInfo.itemTableData.desc, decoDesc = tableInfo.itemTableData.decoDesc, imgPath = tableInfo.itemTableData.iconId, recoverValue = tableInfo.recoverValue, count = GameInstance.player.inventory:GetItemCount(Utils.getCurrentScope(), Utils.getCurrentChapterId(), tableInfo.itemId), selectCount = 1, }
end
StaminaPopUpCtrl._HasItemForExchange = HL.Method().Return(HL.Boolean) << function(self)
    if not self.m_invItemInfoList or (#self.m_invItemInfoList <= 0) then
        return false
    end
    return true
end
StaminaPopUpCtrl._RefreshUIExchangeCostItem = HL.Method() << function(self)
    self.m_exchangeState = ExchangeStateEnum.ExchangeOfItem
    if not self:_HasItemForExchange() then
        self.view.exchangeNode.contentState:SetState("ItemInsufficientState")
        self.view.buttonOperateState:SetState("NotSelectItemState")
        self.m_totalExchangeStamina = 0
        self:_RefreshUICurrentAndTargetStamina()
        return
    end
    self.view.exchangeNode.contentState:SetState("ItemEnoughState")
    self:_CalculateExchangeStaminaOfItemList()
    self.m_genItemCells:Refresh(#self.m_invItemInfoList, function(cell, luaIndex)
        local info = self.m_invItemInfoList[luaIndex]
        local args = {
            itemBundle = { id = info.itemId, count = info.invCount },
            curNum = info.selectCount,
            tryChangeNum = nil,
            onNumChanged = function(curNum)
                self.m_invItemInfoList[luaIndex].selectCount = curNum
                self:_RefreshUIExchangeCostItem()
            end,
        }
        cell:InitItemCellForSelect(args)
    end)
    if self.m_totalExchangeStamina <= 0 then
        self.view.buttonOperateState:SetState("NotSelectItemState")
    else
        self.view.buttonOperateState:SetState("CostItemState")
        local formatString = UIUtils.resolveTextStyle(Language.LUA_STAMINA_POPUP_EXCHANGE_COST_ITEM_TIP)
        self.view.costItemTipTxt.text = string.format(formatString, self.m_totalExchangeStamina)
    end
    self:_RefreshUICurrentAndTargetStamina()
end
StaminaPopUpCtrl._RefreshUIExchangeCostOriginium = HL.Method() << function(self)
    self.m_exchangeState = ExchangeStateEnum.ExchangeOfOriginium
    self.view.exchangeNode.contentState:SetState("OriginiumState")
    local onceCostOriginiumNum = 1
    local recoverStaminaNum = Tables.dungeonConst.apRecoverValueByMoney
    local curOriginiumNum = GameInstance.player.inventory:GetItemCount(Utils.getCurrentScope(), Utils.getCurrentChapterId(), Tables.dungeonConst.recoverApMoneyId)
    local originiumItemCfg = Tables.itemTable[Tables.dungeonConst.recoverApMoneyId]
    local name = ""
    local imgPath = ""
    if originiumItemCfg then
        name = originiumItemCfg.name
        imgPath = originiumItemCfg.iconId
    end
    local maxExchangeCount = Tables.dungeonConst.recoverApByMoneyDailyLimit
    local hasValue
    local usedExchangeCount
    hasValue, usedExchangeCount = GameInstance.player.globalVar:TryGetServerVar(GEnums.ServerGameVarEnum.RecoverApByMoneyCount)
    local remainExchangeCount = maxExchangeCount - usedExchangeCount
    self.m_totalExchangeStamina = recoverStaminaNum
    local viewNode = self.view.exchangeNode.costOriginiumNode
    viewNode.costNumTxt.text = onceCostOriginiumNum
    viewNode.recoverNumTxt.text = recoverStaminaNum
    if curOriginiumNum <= 0 then
        viewNode.totalNumTxt.text = curOriginiumNum
        viewNode.totalNumTxt.color = self.view.config.NUM_TEXT_COLOR_INSUFFICIENT
    else
        viewNode.totalNumTxt.text = curOriginiumNum
        viewNode.totalNumTxt.color = self.view.config.NUM_TEXT_COLOR_NORMAL_BLACK
    end
    viewNode.img.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, imgPath)
    viewNode.originiumNameTxt.text = name
    if maxExchangeCount <= 0 then
        if curOriginiumNum < onceCostOriginiumNum then
            self.view.buttonOperateState:SetState("InsufficientOriginiumState")
        else
            self.view.buttonOperateState:SetState("CostOriginiumState")
            self.view.costOriginiumTipTxt.text = string.format(Language.LUA_STAMINA_POPUP_EXCHANGE_COST_ORIGINIUM_TIP_NO_LIMIT, onceCostOriginiumNum, name, recoverStaminaNum)
        end
    else
        if curOriginiumNum < onceCostOriginiumNum then
            self.view.buttonOperateState:SetState("InsufficientOriginiumState")
        elseif remainExchangeCount <= 0 then
            self.view.buttonOperateState:SetState("InsufficientTimesState")
        else
            self.view.buttonOperateState:SetState("CostOriginiumState")
            self.view.costOriginiumTipTxt.text = string.format(Language.LUA_STAMINA_POPUP_EXCHANGE_COST_ORIGINIUM_TIP, remainExchangeCount, onceCostOriginiumNum, name, recoverStaminaNum)
        end
    end
    self:_RefreshUICurrentAndTargetStamina()
end
StaminaPopUpCtrl._RefreshUIQuickExchange = HL.Method() << function(self)
    local node = self.view.quickExchangeNode
    local info = self.m_quickExchangeItemInfo
    node.itemImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, info.imgPath)
    node.itemNameTxt.text = info.name
    node.descTxt.text = info.desc
    node.decoDescTxt.text = info.decoDesc
    node.itemStorage:InitStorageNode(info.count, 0, true)
    node.itemCountSelector:InitNumberSelector(info.selectCount, 1, info.count, function(curNum, _)
        self.m_quickExchangeItemInfo.selectCount = curNum
        self.m_totalExchangeStamina = self.m_quickExchangeItemInfo.recoverValue * curNum
        self:_RefreshUICurrentAndTargetStamina()
    end)
    self:_RefreshUICurrentAndTargetStamina()
end
StaminaPopUpCtrl._CalculateExchangeStaminaOfItemList = HL.Method() << function(self)
    self.m_totalExchangeStamina = 0
    if not self.m_invItemInfoList then
        return
    end
    for _, v in ipairs(self.m_invItemInfoList) do
        self.m_totalExchangeStamina = self.m_totalExchangeStamina + v.recoverValue * v.selectCount
    end
end
StaminaPopUpCtrl._RefreshUICurrentAndTargetStamina = HL.Method() << function(self)
    local cur = GameInstance.player.inventory.curStamina
    local target = self.m_totalExchangeStamina + cur
    local max = GameInstance.player.inventory.maxStamina
    self.view.curStaminaTxt.text = cur
    self.view.curMaxStaminaTxt.text = max
    self.view.targetMaxStaminaTxt.text = max
    if self.m_totalExchangeStamina <= 0 then
        self.view.targetStaminaTxt.text = target
        self.view.targetStaminaTxt.color = self.view.config.NUM_TEXT_COLOR_NORMAL
    else
        self.view.targetStaminaTxt.text = target
        self.view.targetStaminaTxt.color = self.view.config.NUM_TEXT_COLOR_CHANGE
    end
end
StaminaPopUpCtrl._TryStartTickRecover = HL.Method() << function(self)
    if self.m_coroutineRecover then
        return
    end
    if StaminaPopUpCtrl._IsStaminaMax() then
        self:_StopTickRecover()
        return
    end
    self.view.recoverTimeNode.gameObject:SetActive(true)
    self.view.fullRecoverTimeNode.gameObject:SetActive(true)
    self:_RefreshTickRecoverTxt()
    self.m_coroutineRecover = self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.COMMON_UI_TIME_UPDATE_INTERVAL)
            self:_RefreshTickRecoverTxt()
            self:_RefreshUICurrentAndTargetStamina()
            if StaminaPopUpCtrl._IsStaminaMax() then
                self:_StopTickRecover()
            end
        end
    end)
end
StaminaPopUpCtrl._StopTickRecover = HL.Method() << function(self)
    self.view.recoverTimeNode.gameObject:SetActive(false)
    self.view.fullRecoverTimeNode.gameObject:SetActive(false)
    if self.m_coroutineRecover then
        self:_ClearCoroutine(self.m_coroutineRecover)
        self.m_coroutineRecover = nil
    end
end
StaminaPopUpCtrl._RefreshTickRecoverTxt = HL.Method() << function(self)
    local nextLeftTime = Utils.nextStaminaRecoverLeftTime()
    local fullLeftTime = Utils.fullStaminaRecoverLeftTime()
    self.view.nextRecoverTimeTxt.text = UIUtils.getLeftTimeToSecondMS(nextLeftTime)
    self.view.fullRecoverTimeTxt.text = UIUtils.getLeftTimeToSecondFull(fullLeftTime)
end
StaminaPopUpCtrl._IsStaminaMax = HL.StaticMethod().Return(HL.Boolean) << function()
    local cur = GameInstance.player.inventory.curStamina
    local max = GameInstance.player.inventory.maxStamina
    return cur >= max
end
HL.Commit(StaminaPopUpCtrl)