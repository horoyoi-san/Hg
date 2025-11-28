local MAX_SHOW_CHAR_INFO_COUNT = 3
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GachaPool
GachaPoolCtrl = HL.Class('GachaPoolCtrl', uiCtrl.UICtrl)
GachaPoolCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_GACHA_SUCC] = 'OnGachaSucc', [MessageConst.ON_GACHA_POOL_INFO_CHANGED] = 'OnGachaPoolInfoChanged', [MessageConst.ON_GACHA_POOL_ROLE_DATA_CHANGED] = 'OnGachaPoolRoleDataChanged', [MessageConst.ON_WALLET_CHANGED] = 'OnWalletChanged', [MessageConst.ON_ITEM_COUNT_CHANGED] = 'OnItemChanged', }
GachaPoolCtrl.m_getCell = HL.Field(HL.Function)
GachaPoolCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    arg = arg or {}
    self.view.closeBtn.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.GachaPool)
    end)
    self:BindInputPlayerAction("common_open_gacha", function()
        PhaseManager:PopPhase(PhaseId.GachaPool)
    end, self.view.closeBtn.groupId)
    self.view.weaponShopBtn.onClick:AddListener(function()
        Utils.jumpToSystem("jump_payshop_weapon")
    end)
    self.view.leftBtn.onClick:AddListener(function()
        self.view.poolList:ScrollToIndex(CSIndex(self.m_curIndex - 1))
    end)
    self.view.rightBtn.onClick:AddListener(function()
        self.view.poolList:ScrollToIndex(CSIndex(self.m_curIndex + 1))
    end)
    self.m_poolTabCache = UIUtils.genCellCache(self.view.poolTabCell)
    self.m_getCell = UIUtils.genCachedCellFunction(self.view.poolList)
    self.view.poolList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateCell(self.m_getCell(obj), LuaIndex(csIndex))
    end)
    self.view.poolList.onCenterIndexChanged:AddListener(function(oldIndex, newIndex)
        self:_OnCenterIndexChanged(LuaIndex(newIndex))
    end)
    self.view.poolList.onChangeView:AddListener(function(gameObject, index, value)
        self:_UpdatePoolNodeEffectView(self.m_getCell(gameObject), LuaIndex(index), value)
    end)
    self.m_curIndex = 1
    self:_InitData(arg.poolId)
    self:_InitMoneyNode()
    local curCell = self.m_getCell(self.m_curIndex)
    if curCell then
        curCell.node.main:PlayInAnimation()
    end
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.COMMON_UI_TIME_UPDATE_INTERVAL)
            local cell = self.m_getCell(self.m_curIndex)
            if cell then
                self:_UpdateRemainingTime(cell.node)
            end
        end
    end)
end
GachaPoolCtrl.OnShow = HL.Override() << function(self)
    local time = Time.unscaledTime
    self.loader:LoadGameObjectAsync("Assets/Beyond/DynamicAssets/Gameplay/Prefabs/Gacha/GachaOutside.prefab", function()
        logger.info("GachaOutside 预载完成", Time.unscaledTime - time)
    end)
    self.loader:LoadGameObjectAsync("Assets/Beyond/DynamicAssets/Gameplay/Prefabs/Gacha/GachaRoom.prefab", function()
        logger.info("GachaRoom 预载完成", Time.unscaledTime - time)
    end)
end
GachaPoolCtrl.OnHide = HL.Override() << function(self)
    local cell = self.m_getCell(self.m_curIndex)
    self:_UpdatePoolNodeEffectView(cell, self.m_curIndex, 0)
end
GachaPoolCtrl.OnClose = HL.Override() << function(self)
    GameInstance.player.charBag:ClearAllClientCharInfo()
end
GachaPoolCtrl._OnPlayAnimationOut = HL.Override() << function(self)
    GachaPoolCtrl.Super._OnPlayAnimationOut(self)
    LuaSystemManager.gachaSystem:UpdateGachaSettingState()
    local cell = self.m_getCell(self.m_curIndex)
    if cell then
        cell.node.main:PlayOutAnimation()
    end
end
GachaPoolCtrl.m_curPoolId = HL.Field(HL.String) << ''
GachaPoolCtrl.m_pools = HL.Field(HL.Table)
GachaPoolCtrl.m_curIndex = HL.Field(HL.Number) << 1
GachaPoolCtrl._InitData = HL.Method(HL.Opt(HL.String)) << function(self, poolId)
    local targetIndex = 1
    self.m_pools = {}
    local csGacha = GameInstance.player.gacha
    for id, csInfo in pairs(csGacha.poolInfos) do
        if csInfo.isOpenValid then
            local info = { id = id, csInfo = csInfo, data = csInfo.data, sortId = csInfo.data.sortId, }
            table.insert(self.m_pools, info)
        end
    end
    table.sort(self.m_pools, Utils.genSortFunction({ "sortId" }, true))
    local count = #self.m_pools
    self.m_poolTabCache:Refresh(count, function(cell, index)
        if poolId and self.m_pools[index].id == poolId then
            targetIndex = index
        end
        self:_UpdateTabCell(cell, index)
    end)
    self.view.poolList:UpdateCount(count)
    self.view.poolList:ScrollToIndex(CSIndex(targetIndex), true)
end
GachaPoolCtrl.m_poolTabCache = HL.Field(HL.Forward('UIListCache'))
GachaPoolCtrl._UpdateTabCell = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local info = self.m_pools[index]
    local poolTypeData = Tables.gachaCharPoolTypeTable[info.data.type]
    cell.nameTxt.text = poolTypeData.tagName
    cell.nameTxt.color = UIUtils.getColorByString(info.data.textColor)
    cell.nameBG.color = UIUtils.getColorByString(info.data.color)
    cell.selectedGlow.color = UIUtils.getColorByString(info.data.color, cell.selectedGlow.color.a * 255)
    cell.bannerImg:LoadSprite(UIConst.UI_SPRITE_GACHA_POOL, info.data.tabImage)
    cell.toggle.onValueChanged:RemoveAllListeners()
    cell.toggle.onValueChanged:AddListener(function(isOn)
        if isOn then
            self.view.poolList:ScrollToIndex(CSIndex(index))
        end
    end)
    cell.gameObject.name = info.data.type:ToString()
end
GachaPoolCtrl._OnCenterIndexChanged = HL.Method(HL.Number) << function(self, index)
    logger.info("GachaPoolCtrl._OnCenterIndexChanged", index)
    local info = self.m_pools[index]
    self.m_curIndex = index
    self.m_curPoolId = info.id
    self.view.leftBtn.gameObject:SetActive(index > 1)
    self.view.rightBtn.gameObject:SetActive(index < #self.m_pools)
    local tab = self.m_poolTabCache:Get(index)
    tab.toggle:SetIsOnWithoutNotify(true)
    local cell = self.m_getCell(self.m_curIndex)
    if cell then
        self:_OnUpdateCell(cell, self.m_curIndex)
    end
    if self.view.poolList.centerIndex ~= CSIndex(index) then
        self.view.poolList:ScrollToIndex(CSIndex(index))
    end
end
GachaPoolCtrl._OnUpdateCell = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    if cell.m_lastUpdateFrame and cell.m_lastUpdateFrame == Time.frameCount then
        return
    end
    cell.m_lastUpdateFrame = Time.frameCount
    logger.info("GachaPoolCtrl._OnUpdateCell", index)
    local poolInfo = self.m_pools[index]
    local poolData = Tables.gachaCharPoolTable[poolInfo.id]
    local poolTypeData = Tables.gachaCharPoolTypeTable[poolData.type]
    local uiPrefabName = poolData.uiPrefab
    if cell.uiPrefabName ~= uiPrefabName then
        if cell.node then
            GameObject.Destroy(cell.node.gameObject)
        end
        local path = string.format("Assets/Beyond/DynamicAssets/Gameplay/UI/Prefabs/Gacha/Widgets/%s.prefab", uiPrefabName)
        local prefab = self.loader:LoadGameObject(path)
        local obj = CSUtils.CreateObject(prefab, cell.transform)
        obj.name = poolData.type:ToString()
        cell.uiPrefabName = uiPrefabName
        cell.node = Utils.wrapLuaNode(obj)
    end
    local node = cell.node
    if node.nameMainImg then
        node.nameMainImg:LoadSprite(UIConst.UI_SPRITE_GACHA_POOL, poolData.nameImage)
    end
    node.gachaOnceBtn.gameObject:SetActive(poolTypeData.permitSinglePull)
    if poolTypeData.permitSinglePull then
        self:_UpdateGachaBtn(poolInfo.id, node.gachaOnceBtn, false)
    end
    self:_UpdateGachaBtn(poolInfo.id, node.gachaTenBtn, true)
    node.detailBtn.onClick:RemoveAllListeners()
    node.detailBtn.onClick:AddListener(function()
        self:_ShowDetailPanel()
    end)
    if node.hardGuaranteeNode then
        if poolTypeData.hardGuarantee > 0 then
            if poolInfo.csInfo.upGotCount > 0 then
                node.hardGuaranteeNode.gameObject:SetActive(false)
            else
                local leftCount = poolTypeData.hardGuarantee - poolInfo.csInfo.hardGuaranteeProgress
                node.hardGuaranteeTxt.text = leftCount
                node.hardGuaranteeNode.gameObject:SetActive(true)
            end
        else
            node.hardGuaranteeNode.gameObject:SetActive(false)
        end
    end
    if node.softGuaranteeTxt then
        node.softGuaranteeTxt.text = poolTypeData.softGuarantee - poolInfo.csInfo.softGuaranteeProgress
    end
    if node.softGuaranteeLeftTxt then
        node.softGuaranteeLeftTxt.text = poolTypeData.softGuarantee - poolInfo.csInfo.softGuaranteeProgress
    end
    if node.star5SoftGuaranteeTxt then
        node.star5SoftGuaranteeTxt.text = poolTypeData.star5SoftGuarantee - poolInfo.csInfo.star5SoftGuaranteeProgress
    end
    local endTime = poolInfo.csInfo.closeTime
    if node.endTimeTxt then
        node.endTimeTxt.text = Utils.appendUTC(os.date("!%m/%d %H:%M", endTime + Utils.getServerTimeZoneOffsetSeconds()))
    end
    self:_UpdateRemainingTime(node)
    local upCharIdsCS = poolData.upCharIds
    for k = 1, MAX_SHOW_CHAR_INFO_COUNT do
        local btnNode = node["showCharInfoBtn" .. k]
        if btnNode then
            if btnNode.config then
                self:_UpdateShowCharInfoBtn(btnNode, btnNode.config.CHAR_ID)
            else
                self:_UpdateShowCharInfoBtn(btnNode, upCharIdsCS[CSIndex(k)])
            end
        end
    end
end
GachaPoolCtrl._UpdatePoolNodeEffectView = HL.Method(HL.Table, HL.Number, HL.Number) << function(self, cell, index, value)
    cell.node.animationWrapper:SampleClip(cell.node.config.MOVE_ANI_NAME, 1 + value)
end
GachaPoolCtrl._UpdateRemainingTime = HL.Method(HL.Table) << function(self, node)
    if node.remainingTimeTxt then
        local poolInfo = self.m_pools[self.m_curIndex]
        local endTime = poolInfo.csInfo.closeTime
        local curServerTime = DateTimeUtils.GetCurrentTimestampBySeconds()
        local diffTime = math.max(0, endTime - curServerTime)
        node.remainingTimeTxt.text = string.format(Language.LUA_GACHA_REMAINING_TIME, math.ceil(diffTime / (3600 * 24)))
    end
end
GachaPoolCtrl._UpdateShowCharInfoBtn = HL.Method(HL.Table, HL.String) << function(self, node, charId)
    node.button.onClick:RemoveAllListeners()
    node.button.onClick:AddListener(function()
        self:_ShowUpCharInfo(charId)
    end)
    local charCfg = Tables.characterTable[charId]
    if node.nameTxt then
        node.nameTxt.text = charCfg.name
    end
    if node.professionIcon then
        node.professionIcon:LoadSprite(UIConst.UI_SPRITE_CHAR_PROFESSION, UIConst.UI_CHAR_PROFESSION_PREFIX .. charCfg.profession:ToInt())
    end
    if node.starGroup then
        node.starGroup:InitStarGroup(charCfg.rarity)
    end
    if node.headIcon then
        node.headIcon:LoadSprite(UIConst.UI_SPRITE_ROUND_CHAR_HEAD, UIConst.UI_ROUND_CHAR_HEAD_PREFIX .. charCfg.charId)
    end
end
GachaPoolCtrl._ShowUpCharInfo = HL.Method(HL.String) << function(self, charId)
    if PhaseManager:IsOpen(PhaseId.CharInfo) then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_GACHA_RESULT_OPEN_CHAR_INFO_FAIL)
        return
    end
    local poolData = Tables.gachaCharPoolTable[self.m_curPoolId]
    local idsCS = poolData.upCharIds
    local ids = {}
    if idsCS.Count == 0 then
        local contentData = Tables.gachaCharPoolContentTable[self.m_curPoolId]
        for _, v in pairs(contentData.list) do
            local id = v.charId
            local charData = Tables.characterTable[id]
            if charData.rarity == UIConst.CHAR_MAX_RARITY then
                table.insert(ids, id)
            end
        end
        table.sort(ids)
    else
        for _, v in pairs(idsCS) do
            table.insert(ids, v)
        end
    end
    local curCharInfo
    local charInstIdList = {}
    for _, id in ipairs(ids) do
        local info = GameInstance.player.charBag:CreateClientPerfectPoolCharInfo(id, ScopeUtil.GetCurrentScope())
        if id == charId then
            curCharInfo = info
        end
        table.insert(charInstIdList, info.instId)
    end
    if not curCharInfo then
        return
    end
    logger.info("charInstIdList", charInstIdList)
    PhaseManager:OpenPhase(PhaseId.CharInfo, { initCharInfo = { instId = curCharInfo.instId, templateId = charId, charInstIdList = charInstIdList, } })
end
GachaPoolCtrl._UpdateGachaBtn = HL.Method(HL.String, HL.Table, HL.Boolean) << function(self, poolId, btnCell, isTen)
    btnCell.button.onClick:RemoveAllListeners()
    btnCell.button.onClick:AddListener(function()
        if isTen then
            self:_GachaTen(poolId)
        else
            self:_GachaOnce(poolId)
        end
    end)
    self:_UpdateGachaBtnCost(poolId, btnCell, isTen)
end
GachaPoolCtrl._UpdateGachaBtnCost = HL.Method(HL.String, HL.Table, HL.Boolean) << function(self, poolId, btnCell, isTen)
    local poolData = Tables.gachaCharPoolTable[poolId]
    local poolTypeData = Tables.gachaCharPoolTypeTable[poolData.type]
    local rst
    if isTen then
        rst = self:_GetGachaCost(poolTypeData.tenPullCostItemIds, poolTypeData.tenPullCostItemCounts, 1)
        if not rst.isEnough then
            local hasDiscount = poolTypeData.tenPullCostCountAfterDiscount > 0
            local times = hasDiscount and poolTypeData.tenPullCostCountAfterDiscount or 10
            rst = self:_GetGachaCost(poolTypeData.singlePullCostItemIds, poolTypeData.singlePullCostItemCounts, times)
            if hasDiscount then
                rst.priceRate = times / 10
            end
        end
    else
        rst = self:_GetGachaCost(poolTypeData.singlePullCostItemIds, poolTypeData.singlePullCostItemCounts, 1)
    end
    if not btnCell.m_moneyCellCache then
        btnCell.m_moneyCellCache = UIUtils.genCellCache(btnCell.moneyPriceCell)
    end
    btnCell.m_moneyCellCache:Refresh(#rst.costItems, function(moneyCell, index)
        local info = rst.costItems[index]
        local itemData = Tables.itemTable:GetValue(info.id)
        moneyCell.icon:LoadSprite(UIConst.UI_SPRITE_GACHA_POOL, itemData.iconId)
        local isEnough = info.ownCount >= info.count
        moneyCell.countTxt.text = UIUtils.setCountColor(string.format("×%s", info.count), not isEnough)
        if rst.priceRate then
            moneyCell.oriCountTxt.gameObject:SetActive(true)
            moneyCell.oriCountTxt.text = string.format("×%d", info.count / rst.priceRate)
        end
    end)
end
GachaPoolCtrl._InitMoneyNode = HL.Method() << function(self)
    local moneyNode = self.view.moneyNode
    moneyNode.diamond:InitMoneyCell(Tables.globalConst.diamondItemId)
    moneyNode.originium:InitMoneyCell(Tables.globalConst.originiumItemId)
    local itemData = Tables.itemTable:GetValue(Tables.globalConst.diamondItemId)
    moneyNode.convertedDiamond.icon:LoadSprite(UIConst.UI_SPRITE_WALLET, itemData.iconId)
    moneyNode.convertedDiamond.button.onClick:AddListener(function()
        Notify(MessageConst.SHOW_ITEM_TIPS, { transform = moneyNode.convertedDiamond.transform, posType = UIConst.UI_TIPS_POS_TYPE.MidBottom, itemId = Tables.globalConst.diamondItemId, })
    end)
    self:OnWalletChanged()
end
GachaPoolCtrl.OnWalletChanged = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    local count = GameInstance.player.inventory:GetItemCountInWallet(Tables.globalConst.originiumItemId)
    self.view.moneyNode.convertedDiamond.text.text = count * Tables.CharGachaConst.exchangeCharGachaCostItemCount
    self:OnItemChanged()
end
GachaPoolCtrl.OnItemChanged = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    local cell = self.m_getCell(self.m_curIndex)
    if not cell or string.isEmpty(self.m_curPoolId) then
        return
    end
    local node = cell.node
    local poolData = Tables.gachaCharPoolTable[self.m_curPoolId]
    local poolTypeData = Tables.gachaCharPoolTypeTable[poolData.type]
    if poolTypeData.permitSinglePull then
        self:_UpdateGachaBtnCost(self.m_curPoolId, node.gachaOnceBtn, false)
    end
    self:_UpdateGachaBtnCost(self.m_curPoolId, node.gachaTenBtn, true)
end
GachaPoolCtrl.OnGachaPoolInfoChanged = HL.Method() << function(self)
end
GachaPoolCtrl.OnGachaPoolRoleDataChanged = HL.Method() << function(self)
end
GachaPoolCtrl._ShowDetailPanel = HL.Method() << function(self)
    UIManager:Open(PanelId.GachaPoolDetail, self.m_curPoolId)
end
GachaPoolCtrl._GachaOnce = HL.Method(HL.String) << function(self, poolId)
    if not self:_CheckCanGacha(poolId) then
        return
    end
    local poolData = Tables.gachaCharPoolTable[poolId]
    local poolTypeData = Tables.gachaCharPoolTypeTable[poolData.type]
    self:_TryGacha(poolId, poolTypeData.singlePullCostItemIds, poolTypeData.singlePullCostItemCounts, false, 1)
end
GachaPoolCtrl._GachaTen = HL.Method(HL.String) << function(self, poolId)
    if not self:_CheckCanGacha(poolId) then
        return
    end
    local poolData = Tables.gachaCharPoolTable[poolId]
    local poolTypeData = Tables.gachaCharPoolTypeTable[poolData.type]
    local succ = self:_TryGacha(poolId, poolTypeData.tenPullCostItemIds, poolTypeData.tenPullCostItemCounts, true, 1)
    if succ then
        return
    end
    local times = poolTypeData.tenPullCostCountAfterDiscount > 0 and poolTypeData.tenPullCostCountAfterDiscount or 10
    self:_TryGacha(poolId, poolTypeData.singlePullCostItemIds, poolTypeData.singlePullCostItemCounts, true, times)
end
GachaPoolCtrl._CheckCanGacha = HL.Method(HL.String).Return(HL.Boolean) << function(self, poolId)
    local succ, csInfo = GameInstance.player.gacha.poolInfos:TryGetValue(poolId)
    if succ and csInfo.isOpenValid then
        return true
    end
    GameInstance.player.guide:OnGachaPoolClosed()
    Notify(MessageConst.SHOW_POP_UP, {
        content = Language.LUA_GACHA_POOL_CLOSED,
        hideCancel = true,
        onConfirm = function()
            PhaseManager:PopPhase(PhaseId.GachaPool)
        end,
    })
    return false
end
GachaPoolCtrl._TryGacha = HL.Method(HL.String, HL.Userdata, HL.Userdata, HL.Boolean, HL.Number).Return(HL.Boolean) << function(self, poolId, costItemIdsCS, costItemCountsCS, isTen, times)
    local diamondId = Tables.globalConst.diamondItemId
    local rst = self:_GetGachaCost(costItemIdsCS, costItemCountsCS, times)
    local isEnough = rst.isEnough
    local costItems = rst.costItems
    local curDiamondCount = rst.curDiamondCount
    local diamondNeedCount = rst.diamondNeedCount
    logger.info("GachaPoolCtrl._TryGacha", poolId, costItems)
    if not isEnough and not diamondNeedCount then
        return false
    end
    local content
    if #costItems == 1 then
        local info = costItems[1]
        content = string.format(Language.LUA_GACHA_CONFIRM_USE_ONE_ITEM, Tables.itemTable[info.id].name, info.count)
    else
        local info1 = costItems[1]
        local info2 = costItems[2]
        content = string.format(Language.LUA_GACHA_CONFIRM_USE_TWO_ITEMS, Tables.itemTable[info1.id].name, info1.count, Tables.itemTable[info2.id].name, info2.count)
    end
    local finalCostDic = {}
    for _, v in ipairs(costItems) do
        finalCostDic[v.id] = v.count
    end
    local gachaFunc = function(cost)
        logger.info("GachaPoolCtrl._TryGacha Final", poolId, cost)
        if not self:_CheckCanGacha(poolId) then
            return
        end
        if isTen then
            GameInstance.player.gacha:GachaTen(poolId, cost)
        else
            GameInstance.player.gacha:GachaOnce(poolId, cost)
        end
    end
    if isEnough then
        Notify(MessageConst.SHOW_POP_UP, {
            content = content,
            costItems = costItems,
            onConfirm = function()
                gachaFunc(finalCostDic)
            end,
        })
        return true
    end
    Notify(MessageConst.SHOW_POP_UP, {
        content = content,
        costItems = costItems,
        onConfirm = function()
            local diffCount = diamondNeedCount - curDiamondCount
            local convertRate = Tables.charGachaConst.exchangeCharGachaCostItemCount
            local oriNeedCount = math.ceil(diffCount / convertRate)
            local originiumItemId = Tables.globalConst.originiumItemId
            local curOriCount = Utils.getItemCount(originiumItemId)
            Notify(MessageConst.SHOW_POP_UP, {
                content = string.format(Language.LUA_GACHA_CONFIRM_CONVERT_ORI, oriNeedCount, oriNeedCount * convertRate),
                costItems = { { id = originiumItemId, count = oriNeedCount, ownCount = curOriCount, }, { id = diamondId, count = oriNeedCount * convertRate, ownCount = curDiamondCount, }, },
                convertArrowIndex = 1,
                onConfirm = function()
                    if curOriCount >= oriNeedCount then
                        finalCostDic[diamondId] = curDiamondCount
                        finalCostDic[originiumItemId] = oriNeedCount
                        gachaFunc(finalCostDic)
                    else
                        Notify(MessageConst.SHOW_POP_UP, { content = Language.LUA_GACHA_CONFIRM_CONVERT_ORI_FAIL, hideCancel = true, })
                    end
                end,
            })
        end,
    })
    return true
end
GachaPoolCtrl._GetGachaCost = HL.Method(HL.Userdata, HL.Userdata, HL.Number).Return(HL.Table) << function(self, costItemIdsCS, costItemCountsCS, times)
    local diamondId = Tables.globalConst.diamondItemId
    local curDiamondCount, diamondNeedCount
    local costItems = {}
    local isEnough
    local leftTimes = times
    for k, itemId in pairs(costItemIdsCS) do
        local needCount = costItemCountsCS[k]
        local curCount = Utils.getItemCount(itemId)
        if itemId == diamondId then
            if k ~= costItemIdsCS.Count - 1 then
                logger.error("合成玉只能是最后一个消耗", costItemIdsCS)
            end
            table.insert(costItems, { id = itemId, count = needCount * leftTimes, ownCount = curCount, })
            curDiamondCount = curCount
            diamondNeedCount = needCount * leftTimes
            isEnough = curDiamondCount >= diamondNeedCount
            break
        end
        if curCount >= needCount then
            local consumedTimes = math.min(leftTimes, math.floor(curCount / needCount))
            table.insert(costItems, { id = itemId, count = needCount * consumedTimes, ownCount = curCount, })
            leftTimes = leftTimes - consumedTimes
        end
        if leftTimes == 0 then
            isEnough = true
            break
        end
    end
    return { isEnough = isEnough, costItems = costItems, curDiamondCount = curDiamondCount, diamondNeedCount = diamondNeedCount, }
end
GachaPoolCtrl.OnGachaSucc = HL.Method(HL.Table) << function(self, arg)
    local msg = unpack(arg)
    if msg.GachaPoolId ~= self.m_curPoolId then
        return
    end
    local chars = {}
    for k = 0, msg.FinalResults.Count - 1 do
        local v = msg.FinalResults[k]
        local charId = msg.OriResultIds[k]
        local isNew = not string.isEmpty(v.ItemId)
        local items = {}
        for kk = 0, v.RewardIds.Count - 1 do
            local rewardId = v.RewardIds[kk]
            UIUtils.getRewardItems(rewardId, items)
        end
        if not string.isEmpty(v.RewardItemId) then
            table.insert(items, 2, { id = v.RewardItemId, count = 1 })
        end
        table.insert(chars, { charId = charId, isNew = isNew, items = items, rarity = Tables.characterTable[charId].rarity, })
    end
    logger.info("OnGachaSucc", chars)
    LuaSystemManager.gachaSystem:UpdateGachaSettingState()
    PhaseManager:OpenPhaseFast(PhaseId.GachaDropBin, {
        chars = chars,
        onComplete = function()
            PhaseManager:OpenPhaseFast(PhaseId.GachaChar, {
                fromGacha = true,
                chars = chars,
                onComplete = function()
                    if self.m_pools[self.m_curIndex].csInfo.isClosed then
                        self:_InitData()
                    else
                        local cell = self.m_getCell(self.m_curIndex)
                        if cell then
                            self:_OnUpdateCell(cell, self.m_curIndex)
                        end
                    end
                end
            })
        end
    })
end
HL.Commit(GachaPoolCtrl)