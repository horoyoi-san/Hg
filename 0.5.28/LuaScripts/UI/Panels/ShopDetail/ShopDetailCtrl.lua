local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ShopDetail
ShopDetailCtrl = HL.Class('ShopDetailCtrl', uiCtrl.UICtrl)
ShopDetailCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_BUY_ITEM_SUCC] = 'OnBuyItemSucc', [MessageConst.ON_SHOP_GOODS_CONDITION_REFRESH] = 'PlayAnimationOutAndClose', }
ShopDetailCtrl.m_info = HL.Field(HL.Any)
ShopDetailCtrl.m_itemId = HL.Field(HL.String) << ""
ShopDetailCtrl.m_moneyId = HL.Field(HL.String) << ""
ShopDetailCtrl.m_createdWeaponInsts = HL.Field(HL.Table)
ShopDetailCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeButton.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.view.maskBg.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    local shopSystem = GameInstance.player.shopSystem
    self.m_info = arg
    self.m_createdWeaponInsts = {}
    self.view.numeberTxt.text = 1
    local goodsId = arg.goodsTemplateId
    local goodsTableData = Tables.shopGoodsTable:GetValue(goodsId)
    local remainCount = shopSystem:GetRemainCountByGoodsId(arg.shopId, arg.goodsId)
    local unlock = shopSystem:CheckGoodsUnlocked(arg.goodsId)
    local realPrice = 1
    if arg.discount and arg.discount < 1 then
        self.view.discountTag.gameObject:SetActive(true)
        self.view.originalCostTxt.gameObject:SetActive(true)
        self.view.discountTxt.text = string.format("-%d<size=60%%>%%</size>", math.floor((1 - arg.discount) * 100 + 0.5))
        self.view.originalCostTxt.text = goodsTableData.price
        realPrice = math.floor(goodsTableData.price * arg.discount + 0.5)
        self.view.costTxt.text = realPrice
    else
        self.view.discountTag.gameObject:SetActive(false)
        self.view.costTxt.gameObject:SetActiveIfNecessary(true)
        self.view.originalCostTxt.gameObject:SetActive(false)
        self.view.costTxt.text = goodsTableData.price
        realPrice = goodsTableData.price
    end
    local moneyId = goodsTableData.moneyId
    self.m_moneyId = moneyId
    local moneyItemData = Tables.itemTable:GetValue(moneyId)
    self.view.costIconImg1.sprite = self:LoadSprite(UIConst.UI_SPRITE_WALLET, moneyItemData.iconId)
    self.view.costIconImg2.sprite = self:LoadSprite(UIConst.UI_SPRITE_WALLET, moneyItemData.iconId)
    self.view.costIconImg3.sprite = self:LoadSprite(UIConst.UI_SPRITE_WALLET, moneyItemData.iconId)
    self.view.costMoneyTxt2.text = string.format(Language.LUA_SHOP_BUY_MONEY_NOT_ENOUGH, moneyItemData.name)
    self.view.costMoneyTxt1.text = moneyItemData.name
    local haveMoney = Utils.getItemCount(moneyId)
    local maxBuy = math.floor(haveMoney / realPrice)
    maxBuy = math.max(maxBuy, 1)
    maxBuy = math.min(maxBuy, 99)
    maxBuy = math.min(maxBuy, remainCount == -1 and 99 or remainCount)
    if haveMoney >= realPrice and (remainCount > 0 or remainCount == -1) then
        self.view.btnCommonYellow.onClick:AddListener(function()
            self:_OnClickConfirm()
        end)
        self.view.bottomNode:SetState("normal")
        self.view.amountNode:SetState("normal")
    else
        self.view.numberSelector.gameObject:SetActive(unlock)
        self.view.bottomNode:SetState("nomoney")
        self.view.amountNode:SetState("nomoney")
        if moneyId == Tables.globalConst.gachaWeaponItemId then
            self.view.btnCommon.onClick:AddListener(function()
                UIManager:Open(PanelId.GachaWeaponInsufficient)
            end)
            self.view.bottomNode:SetState("exchange")
        end
    end
    self.view.numberSelector:InitNumberSelector(1, 1, maxBuy, function(newNum)
        self.view.numeberTxt.text = math.floor(newNum)
        self.view.costTotalTxt.text = math.floor(newNum * realPrice)
    end)
    self.view.lock.gameObject:SetActive(not unlock)
    self.view.lockTxt.text = nil
    if remainCount == 1 then
        self.view.numberSelector.gameObject:SetActive(false)
    end
    if remainCount == 0 then
        self.view.numberSelector.gameObject:SetActive(false)
        local curTime = DateTimeUtils.GetCurrentTimestampBySeconds()
        local next = nil
        if goodsTableData.limitCountRefreshType == GEnums.ShopFrequencyLimitType.Daily then
            next = Utils.getNextCommonServerRefreshTime()
        end
        if goodsTableData.limitCountRefreshType == GEnums.ShopFrequencyLimitType.Weekly then
            next = Utils.getNextWeeklyServerRefreshTime()
        end
        if goodsTableData.limitCountRefreshType == GEnums.ShopFrequencyLimitType.Monthly then
            next = Utils.getNextMonthlyServerRefreshTime()
        end
        if next then
            local diff = next - curTime
            self.view.replenishTxt.text = string.format(Language.LUA_SHOP_GOODS_SOLD_OUT_WITH_TIME, UIUtils.getLeftTime(diff))
            self.view.amountNode:SetState("replensh")
        else
            self.view.emptyTxt.text = Language.LUA_SHOP_GOODS_SOLD_OUT
            self.view.amountNode:SetState("empty")
        end
        self.view.bottomNode:SetState("lock")
    end
    self.view.soldOut.gameObject:SetActive(remainCount == 0)
    self.view.common.gameObject:SetActive(unlock)
    if not unlock then
        self.view.lockTxt.text = goodsTableData.lockDesc
        self.view.amountNode:SetState("lock")
        self.view.bottomNode:SetState("lock")
        self.view.numberSelector.gameObject:SetActive(false)
    end
    local itemId = nil
    local itemData = nil
    local isBox = false
    if string.isEmpty(goodsTableData.rewardId) then
        local weaponPool = Tables.gachaWeaponPoolTable[goodsTableData.weaponGachaPoolId]
        local weaponId = weaponPool.upWeaponIds[0]
        itemId = weaponId
        local _, weaponItemCfg = Tables.itemTable:TryGetValue(weaponId)
        self.view.amountTxt.text = string.format("×%s", 1)
        self.view.nameTxt.text = weaponPool.name
        itemData = weaponItemCfg
        isBox = true
    else
        local displayItem = UIUtils.getRewardFirstItem(goodsTableData.rewardId)
        itemId = displayItem.id
        self.view.amountTxt.text = string.format("×%s", displayItem.count)
        itemData = Tables.itemTable[itemId]
        self.view.nameTxt.text = itemData.name
    end
    self.m_moneyId = moneyId
    self.m_itemId = itemId
    self.view.detailBtn.onClick:AddListener(function()
        if itemData.type == GEnums.ItemType.Weapon then
            local weaponInst = GameInstance.player.inventory:CreateClientPerfectPoolWeaponInst(self.m_itemId)
            self.m_createdWeaponInsts[self.m_itemId] = weaponInst
            GameInstance.player.charBag.clientItemInstDatas:Add(weaponInst.instId, weaponInst)
            local fadeTimeBoth = UIConst.CHAR_INFO_TRANSITION_BLACK_SCREEN_DURATION
            local dynamicFadeData = UIUtils.genDynamicBlackScreenMaskData("ShopDetail->WeaponInfo", fadeTimeBoth, fadeTimeBoth, function()
                PhaseManager:OpenPhase(PhaseId.WeaponInfo, { weaponTemplateId = self.m_itemId, weaponInstId = weaponInst.instId, isFocusJump = true, })
            end)
            GameAction.ShowBlackScreen(dynamicFadeData)
        elseif itemData.type == GEnums.ItemType.Char then
            local info = GameInstance.player.charBag:CreateClientPerfectPoolCharInfo(itemId, ScopeUtil.GetCurrentScope())
            local charInstIdList = {}
            table.insert(charInstIdList, info.instId)
            if not info then
                return
            end
            PhaseManager:OpenPhase(PhaseId.CharInfo, { initCharInfo = { instId = info.instId, templateId = itemId, charInstIdList = charInstIdList, } })
        else
            Notify(MessageConst.SHOW_ITEM_TIPS, { itemId = itemId, transform = self.view.detailBtn.transform, })
            self.view.starGroup.gameObject:SetActive(false)
        end
    end)
    UIUtils.setItemRarityImage(self.view.rarityLine, itemData.rarity)
    if itemData.type == GEnums.ItemType.Weapon then
        self.view.itemIconImg2.gameObject:SetActive(false)
        self.view.itemIconImg2Lock.gameObject:SetActive(false)
        if not self.view.lock.gameObject.activeSelf and remainCount ~= 0 then
            self.view.itemWeaponIcon.gameObject:SetActive(true)
            self.view.weaponIconImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_GACHA_WEAPON, itemData.iconId)
        else
            self.view.weaponIconImgLock.gameObject:SetActive(true)
            self.view.itemWeaponIconLock.gameObject:SetActive(true)
            self.view.weaponIconImgLock.sprite = self:LoadSprite(UIConst.UI_SPRITE_GACHA_WEAPON, itemData.iconId)
        end
        self.view.starGroup:InitStarGroup(itemData.rarity)
        self.view.ownNumber.gameObject:SetActive(false)
    else
        self.view.itemWeaponIcon.gameObject:SetActive(false)
        self.view.weaponIconImgLock.gameObject:SetActive(false)
        if not self.view.lock.gameObject.activeSelf and remainCount ~= 0 then
            self.view.itemIconImg2.gameObject:SetActive(true)
            self.view.itemIconImg2.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, itemData.iconId)
        else
            self.view.itemIconImg2Lock.gameObject:SetActive(true)
            self.view.itemIconImg2Lock.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, itemData.iconId)
        end
        if itemData.type == GEnums.ItemType.Char then
            self.view.starGroup:InitStarGroup(itemData.rarity)
            self.view.ownNumber.gameObject:SetActive(false)
        else
            self.view.starGroup.gameObject:SetActive(false)
            self.view.ownNumber.gameObject:SetActive(true)
            self.view.ownNumberTxt.text = Utils.getItemCount(itemId)
        end
    end
    self.view.ownNumberTxt.text = Utils.getItemCount(itemId)
    self.view.inventoryTagTxt01.text = remainCount == -1 and "∞" or remainCount
    local itemTypeName = UIUtils.getItemTypeName(itemId)
    self.view.subTitleTxt.text = itemTypeName
    self.view.descTxt.text = itemData.desc
    self.view.descTxt02.text = itemData.decoDesc
    local leftTime = GameInstance.player.shopSystem:GetWeaponGoodsTimeLimit(arg)
    if leftTime > -1 then
        self.view.tagTime.gameObject:SetActive(true)
        self.view.timeGreen.gameObject:SetActive(false)
        self.view.timeYellow.gameObject:SetActive(false)
        self.view.timeRed.gameObject:SetActive(false)
        if leftTime >= 3600 * 24 * 3 then
            self.view.timeGreen.gameObject:SetActive(true)
            self.view.timeGreenText.text = string.format(Language.LUA_SHOP_WEAPON_REFRESH_DAY, math.floor(leftTime / 3600 / 24 + 0.5))
        elseif leftTime < 3600 * 24 * 3 and leftTime > 3600 * 24 then
            self.view.timeYellow.gameObject:SetActive(true)
            self.view.timeYellowText.text = string.format(Language.LUA_SHOP_WEAPON_REFRESH_DAY, math.floor(leftTime / 3600 / 24 + 0.5))
        else
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
        self.view.tagTime.gameObject:SetActive(false)
    end
    self.view.moneyCell:InitMoneyCell(moneyId)
end
ShopDetailCtrl._OnClickConfirm = HL.Method() << function(self)
    local buyCount = self.view.numberSelector.curNumber
    local info = self.m_info
    local inventorySystem = GameInstance.player.inventory
    if inventorySystem:IsPlaceInBag(self.m_itemId) then
        local itemTableData = Tables.itemTable[self.m_itemId]
        local stackCount = itemTableData.maxBackpackStackCount
        local oneCount = tonumber(string.sub(self.view.amountTxt.text, 2))
        local totalCount = oneCount * buyCount
        local itemBag = inventorySystem.itemBag:GetOrFallback(Utils.getCurrentScope())
        local emptySlotCount = itemBag.slotCount - itemBag:GetUsedSlotCount()
        local sameItemCount = itemBag:GetCount(info.itemId)
        local itemSlotCount = math.ceil(sameItemCount / stackCount)
        local capacity
        if itemSlotCount > 0 then
            capacity = (emptySlotCount + itemSlotCount) * stackCount - sameItemCount
        else
            capacity = stackCount * emptySlotCount
        end
        if capacity < totalCount then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_SHOP_BACKPACK_FULL)
            return
        end
    end
    GameInstance.player.shopSystem:BuyGoods(info.shopId, info.goodsId, buyCount)
end
ShopDetailCtrl.OnBuyItemSucc = HL.Method(HL.Any) << function(self, arg)
    local info = self.m_info
    local goodsTableData = Tables.shopGoodsTable:GetValue(info.goodsTemplateId)
    local displayItem = UIUtils.getRewardFirstItem(goodsTableData.rewardId)
    local itemId = displayItem.id
    local itemData = Tables.itemTable[itemId]
    local allDisplayItems = UIUtils.getRewardItems(goodsTableData.rewardId)
    local items = {}
    for i = 1, #allDisplayItems do
        local displayItem = allDisplayItems[i]
        local itemId = displayItem.id
        local itemData = Tables.itemTable[itemId]
        local totalCount = displayItem.count * self.view.numberSelector.curNumber
        if itemData.maxStackCount <= 1 and Utils.isItemInstType(itemId) then
            for i = 1, totalCount do
                local item = { id = displayItem.id, count = 1, type = itemData.type, }
                table.insert(items, item)
            end
        else
            local item = { id = displayItem.id, count = totalCount, }
            table.insert(items, item)
        end
    end
    if itemData.type == GEnums.ItemType.Char then
        local rewardPack = GameInstance.player.inventory:ConsumeLatestRewardPackOfType(CS.Beyond.GEnums.RewardSourceType.Shop)
        Notify(MessageConst.SHOW_SYSTEM_REWARDS, {
            title = Language.LUA_BUY_ITEM_SUCC_TITLE,
            icon = "icon_common_rewards",
            items = items,
            chars = rewardPack.chars,
            onComplete = function()
                Notify(MessageConst.AFTER_ON_BUY_ITEM_SUCC)
            end,
        })
    elseif itemData.type == GEnums.ItemType.Weapon then
        local weapons = {}
        local weapon = {}
        weapon.weaponId = itemId
        weapon.rarity = Tables.itemTable:GetValue(itemId).rarity
        weapon.items = {}
        for _, item in pairs(items) do
            if item.type ~= GEnums.ItemType.Weapon then
                table.insert(weapon.items, item)
            end
        end
        weapon.isNew = Utils.getItemCount(itemId) == 0
        table.insert(weapons, weapon)
        local onComplete = function()
            Notify(MessageConst.SHOW_SYSTEM_REWARDS, { title = Language.LUA_BUY_ITEM_SUCC_TITLE, icon = "icon_common_rewards", items = items, })
            Notify(MessageConst.AFTER_ON_BUY_ITEM_SUCC)
        end
        PhaseManager:OpenPhaseFast(PhaseId.GachaWeapon, { weapons = weapons, onComplete = onComplete, })
    else
        Notify(MessageConst.SHOW_SYSTEM_REWARDS, {
            title = Language.LUA_BUY_ITEM_SUCC_TITLE,
            icon = "icon_common_rewards",
            items = items,
            onComplete = function()
                Notify(MessageConst.AFTER_ON_BUY_ITEM_SUCC)
            end,
        })
    end
    self:PlayAnimationOutAndClose()
end
ShopDetailCtrl.OnClose = HL.Override() << function(self)
    for weaponId, weaponInst in pairs(self.m_createdWeaponInsts) do
        GameInstance.player.charBag.clientItemInstDatas:Remove(weaponInst.instId)
    end
    self.m_createdWeaponInsts = {}
    GameInstance.player.charBag:ClearAllClientCharInfo()
end
HL.Commit(ShopDetailCtrl)