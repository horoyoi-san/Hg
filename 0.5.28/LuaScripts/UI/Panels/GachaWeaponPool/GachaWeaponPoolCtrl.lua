local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GachaWeaponPool
GachaWeaponPoolCtrl = HL.Class('GachaWeaponPoolCtrl', uiCtrl.UICtrl)
GachaWeaponPoolCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_GACHA_SUCC] = 'OnGachaSucc', [MessageConst.ON_WALLET_CHANGED] = 'OnWalletChanged', [MessageConst.ON_ITEM_COUNT_CHANGED] = 'OnWalletChanged', [MessageConst.ON_GACHA_POOL_ROLE_DATA_CHANGED] = 'OnGachaPoolRoleDataChanged', [MessageConst.ON_SHOP_GOODS_CONDITION_REFRESH] = 'CloseSelf', }
GachaWeaponPoolCtrl.m_goodsData = HL.Field(CS.Beyond.Gameplay.ShopSystem.GoodsData)
GachaWeaponPoolCtrl.m_poolId = HL.Field(HL.String) << ""
GachaWeaponPoolCtrl.m_price = HL.Field(HL.Number) << 0
GachaWeaponPoolCtrl.m_itemNoUpCache = HL.Field(HL.Forward('UIListCache'))
GachaWeaponPoolCtrl.m_createdWeaponInsts = HL.Field(HL.Table)
GachaWeaponPoolCtrl.m_isRequesting = HL.Field(HL.Boolean) << false
GachaWeaponPoolCtrl.m_gachaFlowCoroutine = HL.Field(HL.Thread)
GachaWeaponPoolCtrl.CloseSelf = HL.Method() << function(self)
    if PhaseManager:GetTopPhaseId() ~= PhaseId.GachaWeaponPool then
        return
    end
    PhaseManager:PopPhase(PhaseId.GachaWeaponPool)
end
GachaWeaponPoolCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local goodsData = arg.goodsData
    self.m_goodsData = goodsData
    local goodsTemplate = goodsData.goodsTemplateId
    local shopGoodsData = Tables.shopGoodsTable:GetValue(goodsTemplate)
    self.m_poolId = shopGoodsData.weaponGachaPoolId
    self.m_price = shopGoodsData.price
    self.m_createdWeaponInsts = {}
    self.view.closeBtn.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.GachaWeaponPool)
    end)
    self.view.maskBgImage.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.GachaWeaponPool)
    end)
    self.view.gachaBtn.onClick:AddListener(function()
        self:_OnGachaBtnClick()
    end)
    self.view.detailTipsBtn.onClick:AddListener(function()
        UIManager:Open(PanelId.GachaWeaponPoolDetail, self.m_poolId)
    end)
    self.view.tipsDetailBtn.onClick:AddListener(function()
        UIManager:Open(PanelId.GachaWeaponPoolDetail, self.m_poolId)
    end)
    self.view.noMoneyBtn.onClick:AddListener(function()
        UIManager:Open(PanelId.GachaWeaponInsufficient)
    end)
    self.m_itemNoUpCache = UIUtils.genCellCache(self.view.itemNoUp)
    self:_InitData()
end
GachaWeaponPoolCtrl.OnShow = HL.Override() << function(self)
    local time = Time.unscaledTime
    self.loader:LoadGameObjectAsync("Assets/Beyond/DynamicAssets/Gameplay/Prefabs/Gacha/GachaWeaponPreheat.prefab", function()
        logger.info("GachaOutside 预载完成", Time.unscaledTime - time)
    end)
end
GachaWeaponPoolCtrl._InitData = HL.Method() << function(self)
    local poolInfo = GameInstance.player.gacha.poolInfos:get_Item(self.m_poolId)
    local poolData = poolInfo.data
    self.view.moneyCell:InitMoneyCell(Tables.globalConst.gachaWeaponItemId)
    local moneyItemData = Tables.itemTable:GetValue(Tables.globalConst.gachaWeaponItemId)
    self.view.priceIconImg:LoadSprite(UIConst.UI_SPRITE_WALLET, moneyItemData.iconId)
    self.view.priceNumTxt.text = self.m_price
    self.view.priceExpText.text = moneyItemData.name
    self:OnWalletChanged()
    local upWeaponId = poolData.upWeaponIds[0]
    local weaponItemData = Tables.itemTable:GetValue(upWeaponId)
    self.view.weaponIconImg:LoadSprite(UIConst.UI_SPRITE_ITEM, weaponItemData.iconId)
    self.view.weaponNameTxt.text = poolData.name
    self:_UpdateRemainingTime()
    self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.COMMON_UI_TIME_UPDATE_INTERVAL)
            self:_UpdateRemainingTime()
        end
    end)
    self.view.itemUp:InitItem({ id = upWeaponId, forceHidePotentialStar = true }, function()
        self:_ShowPerfectWeaponPreview(upWeaponId)
    end)
    local contentData = Tables.gachaWeaponPoolContentTable[self.m_poolId]
    local items = {}
    for _, v in pairs(contentData.list) do
        if v.starLevel == 6 and v.itemId ~= upWeaponId then
            table.insert(items, { id = v.itemId, forceHidePotentialStar = true })
        end
    end
    self.m_itemNoUpCache:Refresh(#items, function(cell, index)
        cell:InitItem(items[index], function()
            self:_ShowPerfectWeaponPreview(items[index].id)
        end)
    end)
    local typeData = Tables.gachaWeaponPoolTypeTable[poolData.type]
    local greyTxt5 = string.format(Language.LUA_GACHA_WEAPON_POOL_DESC_STAR_5, typeData.star5SoftGuarantee / 10)
    local greyTxt6 = string.format(typeData.softGuarantee - poolInfo.softGuaranteeProgress > 10 and Language.LUA_GACHA_WEAPON_POOL_DESC_STAR_6 or Language.LUA_GACHA_WEAPON_POOL_DESC_STAR_6_CURR, typeData.softGuarantee / 10)
    self.view.greyTxt.text = greyTxt5 .. '\n' .. greyTxt6
    if poolInfo.upGotCount > 0 or poolInfo.hardGuaranteeProgress > typeData.hardGuarantee then
        self.view.describeCon.gameObject:SetActive(false)
    else
        self.view.describeCon.gameObject:SetActive(true)
        self.view.describeConTxt.text = string.format(Language.LUA_GACHA_WEAPON_POOL_DESC_UP, math.ceil((typeData.hardGuarantee - poolInfo.hardGuaranteeProgress) / 10), weaponItemData.name)
    end
end
GachaWeaponPoolCtrl._UpdateRemainingTime = HL.Method() << function(self)
    local poolInfo = GameInstance.player.gacha.poolInfos:get_Item(self.m_poolId)
    local endTime = poolInfo.closeTime
    if endTime > 0 then
        local leftTime = endTime - DateTimeUtils.GetCurrentTimestampBySeconds()
        if leftTime > 3600 * 24 * 3 then
            self.view.timeGreen.gameObject:SetActive(true)
            self.view.timeYellow.gameObject:SetActive(false)
            self.view.timeRed.gameObject:SetActive(false)
            self.view.timeGreenText.text = string.format(Language.LUA_SHOP_WEAPON_REFRESH_DAY, math.floor(leftTime / 3600 / 24 + 0.5))
        elseif leftTime <= 3600 * 24 * 3 and leftTime > 3600 * 24 then
            self.view.timeGreen.gameObject:SetActive(false)
            self.view.timeYellow.gameObject:SetActive(true)
            self.view.timeRed.gameObject:SetActive(false)
            self.view.timeYellowText.text = string.format(Language.LUA_SHOP_WEAPON_REFRESH_DAY, math.floor(leftTime / 3600 / 24 + 0.5))
        else
            self.view.timeGreen.gameObject:SetActive(false)
            self.view.timeYellow.gameObject:SetActive(false)
            self.view.timeRed.gameObject:SetActive(true)
            if leftTime > 3600 then
                self.view.timeRedText.text = string.format(Language.LUA_SHOP_WEAPON_REFRESH_HOUR, math.floor(leftTime / 3600 + 0.5))
            else
                local min = math.floor(leftTime / 60 + 0.5)
                if min < 1 then
                    min = 1
                end
                self.view.timeRedText.text = string.format(Language.LUA_SHOP_WEAPON_REFRESH_MIN, min)
            end
        end
    else
        self.view.timeGreen.gameObject:SetActive(false)
        self.view.timeYellow.gameObject:SetActive(false)
        self.view.timeRed.gameObject:SetActive(false)
    end
end
GachaWeaponPoolCtrl._OnGachaBtnClick = HL.Method() << function(self)
    if self.m_isRequesting then
        return
    end
    GameInstance.player.shopSystem:BuyGoods(self.m_goodsData.shopId, self.m_goodsData.goodsId, 1)
    self.m_isRequesting = true
end
GachaWeaponPoolCtrl.OnWalletChanged = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    local count = GameInstance.player.inventory:GetItemCount(Utils.getCurrentScope(), Utils.getCurrentChapterId(), Tables.globalConst.gachaWeaponItemId)
    local iconId = Tables.itemTable:GetValue(Tables.globalConst.gachaWeaponItemId).iconId
    if count >= self.m_price then
        self.view.normalType.gameObject:SetActive(true)
        self.view.disableType.gameObject:SetActive(false)
        self.view.normalNumTxt.text = 1
        self.view.normalCostIconImg:LoadSprite(UIConst.UI_SPRITE_WALLET, iconId)
        self.view.normalCostTxt.text = self.m_price
        self.view.gachaBtn.gameObject:SetActive(true)
        self.view.noMoneyType.gameObject:SetActive(false)
    else
        self.view.normalType.gameObject:SetActive(false)
        self.view.disableType.gameObject:SetActive(true)
        self.view.disableNumTxt.text = 1
        self.view.disableCostIconImg:LoadSprite(UIConst.UI_SPRITE_WALLET, iconId)
        self.view.disableCostTxt.text = self.m_price
        self.view.gachaBtn.gameObject:SetActive(false)
        self.view.noMoneyType.gameObject:SetActive(true)
        self.view.noMoneyTxt.text = string.format(Language.LUA_GACHA_WEAPON_POOL_NO_MONEY, UIConst.UI_SPRITE_WALLET, iconId)
    end
end
GachaWeaponPoolCtrl.OnGachaSucc = HL.Method(HL.Table) << function(self, arg)
    self:OnWalletChanged()
    local msg = unpack(arg)
    if msg.GachaPoolId ~= self.m_poolId then
        return
    end
    local weapons = {}
    for k = 0, msg.FinalResults.Count - 1 do
        local v = msg.FinalResults[k]
        local weaponId = msg.OriResultIds[k]
        local items = {}
        for kk = 0, v.RewardIds.Count - 1 do
            local rewardId = v.RewardIds[kk]
            UIUtils.getRewardItems(rewardId, items)
        end
        table.insert(weapons, { weaponId = weaponId, isNew = v.IsNew, items = items, rarity = Tables.itemTable:GetValue(weaponId).rarity, })
    end
    logger.info("OnGachaSucc", weapons)
    LuaSystemManager.gachaSystem:UpdateGachaWeaponSettingState()
    self.m_gachaFlowCoroutine = self:_ClearCoroutine(self.m_gachaFlowCoroutine)
    self.m_gachaFlowCoroutine = self:_StartCoroutine(function()
        coroutine.waitAsyncRequest(function(onComplete)
            PhaseManager:OpenPhaseFast(PhaseId.GachaWeaponPreheat, { weapons = weapons, onComplete = onComplete })
        end)
        coroutine.waitAsyncRequest(function(onComplete)
            PhaseManager:OpenPhaseFast(PhaseId.GachaWeapon, { weapons = weapons, onComplete = onComplete })
        end)
        table.sort(weapons, function(a, b)
            return a.rarity < b.rarity
        end)
        coroutine.waitAsyncRequest(function(onComplete)
            PhaseManager:OpenPhaseFast(PhaseId.GachaWeaponResult, { weapons = weapons, onComplete = onComplete })
        end)
        local getItems = {}
        local otherItemDict = {}
        for _, weapon in ipairs(weapons) do
            table.insert(getItems, { id = weapon.weaponId, count = 1 })
            for _, item in ipairs(weapon.items) do
                otherItemDict[item.id] = (otherItemDict[item.id] or 0) + item.count
            end
        end
        local otherItems = {}
        for k, v in pairs(otherItemDict) do
            local data = Tables.itemTable[k]
            table.insert(otherItems, { id = k, count = v, sortId1 = data.sortId1, sortId2 = data.sortId2, rarity = data.rarity, })
        end
        table.sort(otherItems, Utils.genSortFunction(UIConst.COMMON_ITEM_SORT_KEYS))
        for _, v in ipairs(otherItems) do
            table.insert(getItems, v)
        end
        Notify(MessageConst.SHOW_SYSTEM_REWARDS, { items = getItems, })
        self.m_isRequesting = false
    end)
end
GachaWeaponPoolCtrl.OnGachaPoolRoleDataChanged = HL.Method() << function(self)
    self:_InitData()
end
GachaWeaponPoolCtrl._ShowPerfectWeaponPreview = HL.Method(HL.String) << function(self, weaponId)
    local weaponInst
    if self.m_createdWeaponInsts[weaponId] ~= nil then
        weaponInst = self.m_createdWeaponInsts[weaponId]
    else
        weaponInst = GameInstance.player.inventory:CreateClientPerfectPoolWeaponInst(weaponId)
        self.m_createdWeaponInsts[weaponId] = weaponInst
        GameInstance.player.charBag.clientItemInstDatas:Add(weaponInst.instId, weaponInst)
    end
    if PhaseManager:CheckCanOpenPhase(PhaseId.WeaponInfo, nil, true) == false then
        return
    end
    if PhaseManager:CheckIsInTransition() then
        return
    end
    local fadeTimeBoth = UIConst.CHAR_INFO_TRANSITION_BLACK_SCREEN_DURATION
    local dynamicFadeData = UIUtils.genDynamicBlackScreenMaskData("GachaWeaponPool->WeaponInfo", fadeTimeBoth, fadeTimeBoth, function()
        PhaseManager:OpenPhase(PhaseId.WeaponInfo, { weaponTemplateId = weaponId, weaponInstId = weaponInst.instId, isFocusJump = true, })
    end)
    GameAction.ShowBlackScreen(dynamicFadeData)
end
GachaWeaponPoolCtrl.OnClose = HL.Override() << function(self)
    for weaponId, weaponInst in pairs(self.m_createdWeaponInsts) do
        GameInstance.player.charBag.clientItemInstDatas:Remove(weaponInst.instId)
    end
    self.m_createdWeaponInsts = {}
    self.m_gachaFlowCoroutine = self:_ClearCoroutine(self.m_gachaFlowCoroutine)
end
HL.Commit(GachaWeaponPoolCtrl)