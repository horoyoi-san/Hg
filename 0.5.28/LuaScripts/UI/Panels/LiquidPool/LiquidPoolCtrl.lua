local FluidContainerInfo = CS.Beyond.Gameplay.Factory.FactoryUtil.FluidContainerInfo
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.LiquidPool
LiquidPoolCtrl = HL.Class('LiquidPoolCtrl', uiCtrl.UICtrl)
LiquidPoolCtrl.s_messages = HL.StaticField(HL.Table) << {}
LiquidPoolCtrl.m_nodeId = HL.Field(HL.Number) << -1
LiquidPoolCtrl.m_isFilling = HL.Field(HL.Boolean) << true
LiquidPoolCtrl.m_selectedItemList = HL.Field(HL.Table)
LiquidPoolCtrl.m_selectedItemMap = HL.Field(HL.Table)
LiquidPoolCtrl.m_csInfo = HL.Field(CS.Beyond.Gameplay.Factory.FactoryUtil.FluidContainerInfo)
LiquidPoolCtrl.m_selectTargetLiquidId = HL.Field(HL.Any)
LiquidPoolCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeBtn.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.LiquidPool)
    end)
    self.view.confirmBtn.onClick:AddListener(function()
        self:_OnConfirmAction()
    end)
    self.view.actionTypeToggle.onValueChanged:AddListener(function(isOn)
        self:_ToggleContent(isOn)
    end)
    local nodeId = arg.nodeId
    self.m_nodeId = nodeId
    self.m_selectedItemList = {}
    self.m_selectedItemMap = {}
    self.m_selectedBottleLiquidCapacity = 0
    self:_ToggleBag(false, true)
    self.view.actionTypeToggle:SetIsOnWithoutNotify(true)
    self:_ToggleContent(true)
end
LiquidPoolCtrl._ToggleContent = HL.Method(HL.Boolean) << function(self, isFilling)
    self.m_isFilling = isFilling
    local node = isFilling and self.view.fillContent or self.view.dumpContent
    node.animationWrapper:PlayWithTween(isFilling and "liquidpool_fill_change" or "liquidpool_dump_change")
    self.m_csInfo = CSFactoryUtil.GetFluidContainerInfo(self.m_nodeId)
    self.m_selectedBottleLiquidCapacity = 0
    self.m_selectedItemList = {}
    self.m_selectedItemMap = {}
    self:_UpdatePoolNode(node)
    self:_UpdateItemNode(node)
    self:_UpdateBottomNode()
    self.view.confirmBtn.text = isFilling and Language["ui_fac_liquid_op_fill_button"] or Language["ui_fac_liquid_op_dump_button"]
    if not isFilling then
        CS.Beyond.Gameplay.Conditions.OnLiquidInteractInDumpMode.Trigger()
    end
end
LiquidPoolCtrl._UpdatePoolNode = HL.Method(HL.Table) << function(self, contentNode)
    local node = contentNode.poolNode
    local info = self.m_csInfo
    node.nameTxt.text = info.name
    local isEmpty = string.isEmpty(info.itemId)
    if isEmpty then
        node.content:PlayOutAnimation()
    else
        node.content:PlayInAnimation()
        node.item:InitItem({ id = info.itemId }, true)
    end
    node.storageTxt.text = info.isInfinite and Language.LUA_LIQUID_POOL_INFINITE_COUNT or string.format(Language.LUA_LIQUID_STORAGE_FORMAT, info.itemCount, info.maxAmount)
end
LiquidPoolCtrl._UpdateItemNode = HL.Method(HL.Table) << function(self, contentNode)
    local node = contentNode.itemNode
    local info = self.m_csInfo
    if not node.getCell then
        node.m_getCell = UIUtils.genCachedCellFunction(node.scrollList)
        node.scrollList.onUpdateCell:AddListener(function(obj, csIndex)
            self:_OnUpdateCell(node.m_getCell(obj), LuaIndex(csIndex))
        end)
        node.content.onClick:AddListener(function()
            self:_ToggleBag(true)
        end)
        node.emptyAddBtn.onClick:AddListener(function()
            self:_ToggleBag(true)
        end)
    end
    local count = #self.m_selectedItemList
    node.scrollList:UpdateCount(count)
    local isEmpty = count == 0
    node.emptyAddBtn.gameObject:SetActive(isEmpty)
    contentNode.arrowNode:Play(isEmpty and "liquidpoolarrow_black" or "liquidpoolarrow_blue")
end
LiquidPoolCtrl._UpdateBottomNode = HL.Method() << function(self)
    local count = #self.m_selectedItemList
    local isEmpty = count == 0
    self.view.emptyHint.gameObject:SetActive(isEmpty)
    self.view.confirmBtn.gameObject:SetActive(not isEmpty)
    local info = self.m_csInfo
    local liquidId
    if string.isEmpty(info.itemId) then
        if not self.m_isFilling and not isEmpty then
            liquidId = self.m_selectTargetLiquidId
        end
    else
        liquidId = info.itemId
    end
    if liquidId then
        local itemData = Tables.itemTable[liquidId]
        self.view.liquidNameTxt.text = itemData.name
        self.view.liquidNumTxt.text = self.m_selectedBottleLiquidCapacity
        UIUtils.setItemRarityImage(self.view.liquidRarity, itemData.rarity)
        self.view.countNode.gameObject:SetActive(true)
    else
        self.view.countNode.gameObject:SetActive(false)
    end
end
LiquidPoolCtrl._OnUpdateCell = HL.Method(HL.Forward('Item'), HL.Number) << function(self, cell, index)
    local info = self.m_selectedItemList[index]
    cell:InitItem(info, true)
end
LiquidPoolCtrl._OnConfirmAction = HL.Method() << function(self)
    self:_SendActionMsg()
end
LiquidPoolCtrl._SendActionMsg = HL.Method() << function(self)
    local idList = {}
    local countList = {}
    for k, v in ipairs(self.m_selectedItemList) do
        idList[k] = v.id
        countList[k] = v.count
    end
    if self.m_isFilling then
        AudioManager.PostEvent("Au_UI_Event_WaterUp")
        GameInstance.player.remoteFactory.core:Message_TakeOutFluidFromLiquidBody(Utils.getCurrentChapterId(), self.m_csInfo.waterKey, idList, countList, function(op, opRet)
            self:_OnActionReturn(true, op, opRet)
        end)
    else
        AudioManager.PostEvent("Au_UI_Event_WaterDown")
        GameInstance.player.remoteFactory.core:Message_PutInFluidToLiquidBody(Utils.getCurrentChapterId(), self.m_csInfo.waterKey, idList, countList, function(op, opRet)
            self:_OnActionReturn(false, op, opRet)
        end)
    end
end
LiquidPoolCtrl._OnActionReturn = HL.Method(HL.Boolean, CS.Proto.CS_FACTORY_OP, CS.Proto.SC_FACTORY_OP_RET) << function(self, isFilling, op, opRet)
    if opRet.RetCode ~= CS.Proto.FACTORY_OP_RET_CODE.Ok then
        self:_ToggleContent(self.m_isFilling)
        return
    end
    local retType = isFilling and opRet.TakeOutFluidFromLiquidBody.Ret or opRet.PutInFluidToLiquidBody.Ret
    if retType == CS.Proto.RET_FLUID_WITH_LIQUID_BODY.None then
        if isFilling then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_LIQUID_ACTION_FAIL_FILL_NONE)
        else
            Notify(MessageConst.SHOW_TOAST, Language.LUA_LIQUID_ACTION_FAIL_DUMP_NONE)
        end
        self:_ToggleContent(self.m_isFilling)
        return
    end
    local node = self.m_isFilling and self.view.fillContent or self.view.dumpContent
    local anim = self.m_isFilling and "liquid_pool_filling" or "liquid_pool_dumpping"
    Notify(MessageConst.SHOW_BLOCK_INPUT_PANEL, node.animationWrapper:GetClipLength(anim))
    node.animationWrapper:PlayWithTween(anim, function()
        self:_StartTimer(0, function()
            node.animationWrapper:PlayWithTween("liquid_pool_normal")
        end)
        self:_ShowReward(isFilling, opRet, retType)
    end)
end
LiquidPoolCtrl._ShowReward = HL.Method(HL.Boolean, CS.Proto.SC_FACTORY_OP_RET, CS.Proto.RET_FLUID_WITH_LIQUID_BODY) << function(self, isFilling, opRet, retType)
    if retType == CS.Proto.RET_FLUID_WITH_LIQUID_BODY.PartialByBag then
        if isFilling then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_LIQUID_ACTION_FILL_PARTIAL_BY_BAG)
        else
            Notify(MessageConst.SHOW_TOAST, Language.LUA_LIQUID_ACTION_DUMP_PARTIAL_BY_BAG)
        end
    elseif retType == CS.Proto.RET_FLUID_WITH_LIQUID_BODY.PartialByLiquidBody then
        if isFilling then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_LIQUID_ACTION_FILL_PARTIAL_BY_LIQUID_BODY)
        else
            Notify(MessageConst.SHOW_TOAST, Language.LUA_LIQUID_ACTION_DUMP_PARTIAL_BY_LIQUID_BODY)
        end
    end
    local protoItems, liquidAmount
    if isFilling then
        local body = opRet.TakeOutFluidFromLiquidBody
        protoItems = body.GainBottleWaterItems
        liquidAmount = body.CostLiquid
    else
        local body = opRet.PutInFluidToLiquidBody
        protoItems = body.GainBottleItems
        liquidAmount = body.GainLiquid
    end
    local liquidId
    if isFilling then
        liquidId = self.m_csInfo.itemId
    else
        local bottleId = opRet.PutInFluidToLiquidBody.CostBottleWaterItems[0].Id
        local data = Tables.fullBottleTable[bottleId]
        liquidId = data.liquidId
    end
    local itemList = {}
    for k = 0, protoItems.Count - 1 do
        local bundle = protoItems[k]
        table.insert(itemList, { id = bundle.Id, count = bundle.Count })
    end
    local itemData = Tables.itemTable[liquidId]
    Notify(MessageConst.SHOW_SYSTEM_REWARDS, { title = isFilling and Language.LUA_LIQUID_FILL_SUCCESS or Language.LUA_LIQUID_DUMP_SUCCESS, subTitle = string.format(isFilling and Language.LUA_LIQUID_FILL_RESULT or Language.LUA_LIQUID_DUMP_RESULT, liquidAmount, itemData.name), icon = isFilling and "icon_liquid_0" or "icon_liquid_1", items = itemList, })
    self:_ToggleContent(self.m_isFilling)
end
LiquidPoolCtrl.m_bagNodeItemInfos = HL.Field(HL.Table)
LiquidPoolCtrl.m_selectedBottleLiquidCapacity = HL.Field(HL.Number) << 0
LiquidPoolCtrl.m_getBagNodeItemCell = HL.Field(HL.Function)
LiquidPoolCtrl.m_bagNodeSelectTargetLiquidId = HL.Field(HL.Any)
LiquidPoolCtrl._ToggleBag = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, active, isInit)
    local node = self.view.bagNode
    if isInit then
        node.gameObject:SetActive(active)
        return
    end
    node.gameObject:SetActive(true)
    if not active then
        node.animationWrapper:PlayOutAnimation(function()
            node.gameObject:SetActive(false)
        end)
        return
    end
    if not self.m_getBagNodeItemCell then
        self.m_getBagNodeItemCell = UIUtils.genCachedCellFunction(node.itemScrollList)
        node.itemScrollList.onUpdateCell:AddListener(function(obj, csIndex)
            self:_OnUpdateBagNodeItemCell(self.m_getBagNodeItemCell(obj), LuaIndex(csIndex))
        end)
        node.closeBtn.onClick:AddListener(function()
            self:_CancelBagSelect()
        end)
        node.confirmBtn.onClick:AddListener(function()
            self:_OnClickBagConfirm()
        end)
    end
    self:_PrepareBagData()
    node.itemScrollList:UpdateCount(#self.m_bagNodeItemInfos)
end
LiquidPoolCtrl._OnUpdateBagNodeItemCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local info = self.m_bagNodeItemInfos[index]
    cell:InitItemCellForSelect({
        itemBundle = info,
        curNum = info.selectedCount,
        tryChangeNum = function(newNum)
            return self:_TryChangeSelectNum(index, newNum)
        end,
        onNumChanged = function(newNum)
            self:_OnSelectNumChanged(index, newNum)
        end,
    })
    cell.view.nonValidNode.gameObject:SetActive(not info.isValid)
    cell.view.item.view.button.onClick:AddListener(function()
        if not cell.view.item.showingTips then
            cell.view.item:ShowTips({ tipsPosTransform = self.view.bagNode.tipsPos, tipsPosType = UIConst.UI_TIPS_POS_TYPE.LeftDown, safeArea = cell.transform, isSideTips = true, })
        end
    end)
end
LiquidPoolCtrl._OnSelectNumChanged = HL.Method(HL.Number, HL.Number) << function(self, index, newNum)
    local info = self.m_bagNodeItemInfos[index]
    info.selectedCount = newNum
    if not self.m_isFilling then
        if newNum == 0 then
            if string.isEmpty(self.m_csInfo.itemId) then
                for k, v in ipairs(self.m_bagNodeItemInfos) do
                    if v.selectedCount > 0 then
                        return
                    end
                end
                self.m_bagNodeSelectTargetLiquidId = nil
                self:_UpdateBagNodeAllItemValidStateOnSelect()
            end
        elseif not self.m_bagNodeSelectTargetLiquidId then
            self.m_bagNodeSelectTargetLiquidId = info.liquidId
            self:_UpdateBagNodeAllItemValidStateOnSelect()
        end
    end
end
LiquidPoolCtrl._TryChangeSelectNum = HL.Method(HL.Number, HL.Number).Return(HL.Boolean, HL.Opt(HL.Number)) << function(self, index, newNum)
    local info = self.m_bagNodeItemInfos[index]
    if not self.m_isFilling then
        if not info.isValid then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_LIQUID_DUMP_LIQUID_TYPE_MISMATCH)
            return false
        end
    end
    local bottleCount = 0
    local capacity = 0
    for k, v in ipairs(self.m_bagNodeItemInfos) do
        if k ~= index then
            bottleCount = bottleCount + v.selectedCount
            capacity = capacity + v.selectedCount * v.liquidCapacity
        end
    end
    if self.m_isFilling then
        if bottleCount + newNum > Tables.factoryConst.maxFillingBottleCount then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_LIQUID_FILL_TOO_MUCH_BOTTLE)
            return true, math.max(0, Tables.factoryConst.maxFillingBottleCount - bottleCount)
        end
    end
    if not self.m_csInfo.isInfinite then
        local restCapacity
        if self.m_isFilling then
            restCapacity = self.m_csInfo.itemCount - capacity
        else
            restCapacity = self.m_csInfo.maxAmount - self.m_csInfo.itemCount - capacity
        end
        local maxNum = math.max(0, math.floor(restCapacity / info.liquidCapacity))
        if maxNum < newNum then
            if self.m_isFilling then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_LIQUID_FILL_NOT_ENOUGH)
            else
                Notify(MessageConst.SHOW_TOAST, Language.LUA_LIQUID_DUMP_NOT_ENOUGH)
            end
            newNum = maxNum
        end
    end
    return true, newNum
end
LiquidPoolCtrl._UpdateBagNodeAllItemValidStateOnSelect = HL.Method() << function(self)
    local targetLiquidId = self.m_bagNodeSelectTargetLiquidId
    for k, v in ipairs(self.m_bagNodeItemInfos) do
        v.isValid = not targetLiquidId or v.liquidId == targetLiquidId
        local cell = self.m_getBagNodeItemCell(k)
        if cell then
            cell.view.nonValidNode.gameObject:SetActive(not v.isValid)
        end
    end
end
LiquidPoolCtrl._PrepareBagData = HL.Method() << function(self)
    self.m_bagNodeItemInfos = {}
    local targetLiquidId = (not string.isEmpty(self.m_csInfo.itemId)) and self.m_csInfo.itemId or nil
    self.m_bagNodeSelectTargetLiquidId = targetLiquidId
    local bottleTable = self.m_isFilling and Tables.emptyBottleTable or Tables.fullBottleTable
    for id, bottleData in pairs(bottleTable) do
        local needShow
        if not targetLiquidId then
            needShow = true
        else
            if self.m_isFilling then
                needShow = lume.find(bottleData.liquidItems, targetLiquidId)
            else
                needShow = true
            end
        end
        if needShow then
            local count = Utils.getItemCount(id)
            if count > 0 then
                local itemData = Tables.itemTable[id]
                local info = { id = id, count = count, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2, rarity = itemData.rarity, liquidCapacity = bottleData.liquidCapacity, selectedCount = self.m_selectedItemMap[id] and self.m_selectedItemMap[id] or 0, }
                if not self.m_isFilling then
                    info.liquidId = bottleData.liquidId
                    info.isValid = not targetLiquidId or bottleData.liquidId == targetLiquidId
                else
                    info.isValid = true
                end
                info.validSortId = info.isValid and 1 or 0
                info.countSortId = info.count > 0 and 1 or 0
                table.insert(self.m_bagNodeItemInfos, info)
            end
        end
    end
    table.sort(self.m_bagNodeItemInfos, Utils.genSortFunction({ "validSortId", "countSortId", "rarity", "sortId1", "sortId2", "id" }, false))
end
LiquidPoolCtrl._OnClickBagConfirm = HL.Method() << function(self)
    self.m_selectedItemList = {}
    self.m_selectedItemMap = {}
    for _, info in ipairs(self.m_bagNodeItemInfos) do
        if info.selectedCount > 0 then
            table.insert(self.m_selectedItemList, { id = info.id, count = info.selectedCount })
            self.m_selectedItemMap[info.id] = info.selectedCount
        end
    end
    self:_CalcCurBottleLiquidIdAndCapacity()
    self:_ToggleBag(false)
    local node = self.m_isFilling and self.view.fillContent or self.view.dumpContent
    self:_UpdateItemNode(node)
    self:_UpdateBottomNode()
end
LiquidPoolCtrl._CancelBagSelect = HL.Method() << function(self)
    self:_ToggleBag(false)
end
LiquidPoolCtrl._CalcCurBottleLiquidIdAndCapacity = HL.Method() << function(self)
    self.m_selectTargetLiquidId = nil
    self.m_selectedBottleLiquidCapacity = 0
    for _, info in ipairs(self.m_bagNodeItemInfos) do
        self.m_selectedBottleLiquidCapacity = self.m_selectedBottleLiquidCapacity + info.liquidCapacity * info.selectedCount
        if not self.m_isFilling and info.selectedCount > 0 then
            self.m_selectTargetLiquidId = info.liquidId
        end
    end
end
LiquidPoolCtrl.ShowLiquidPool = HL.StaticMethod(HL.Table) << function(args)
    local nodeId = args[1]
    PhaseManager:OpenPhase(PhaseId.LiquidPool, { nodeId = nodeId })
end
HL.Commit(LiquidPoolCtrl)