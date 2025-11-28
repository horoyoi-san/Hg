local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
ShopWeaponCell = HL.Class('ShopWeaponCell', UIWidgetBase)
ShopWeaponCell.m_info = HL.Field(HL.Any)
ShopWeaponCell.m_isBox = HL.Field(HL.Boolean) << false
ShopWeaponCell._OnFirstTimeInit = HL.Override() << function(self)
    self.view.click.onClick:AddListener(function()
        if self.m_isBox then
            PhaseManager:OpenPhase(PhaseId.GachaWeaponPool, { goodsData = self.m_info })
        else
            UIManager:Open(PanelId.ShopDetail, self.m_info)
        end
    end)
    self:RegisterMessage(MessageConst.ON_WALLET_CHANGED, function(msgArg)
        self:UpdateMoney()
    end)
    self:RegisterMessage(MessageConst.ON_ITEM_COUNT_CHANGED, function(msgArg)
        self:UpdateMoney()
    end)
end
ShopWeaponCell.UpdateMoney = HL.Method(HL.Opt(HL.Any)) << function(self, arg)
    local goodsTableData = Tables.shopGoodsTable[self.m_info.goodsTemplateId]
    local moneyId = goodsTableData.moneyId
    local haveMoney = Utils.getItemCount(moneyId)
    local info = self.m_info
    local realPrice = 0
    if info.discount and info.discount < 1 then
        self.view.moneyDecPriceItem.gameObject:SetActive(true)
        self.view.numberMoneyGreyTxt.gameObject:SetActiveIfNecessary(true)
        self.view.numberMoneyTxt.text = math.floor(goodsTableData.price * info.discount)
        self.view.numberMoneyGreyTxt.text = goodsTableData.price
        realPrice = math.floor(goodsTableData.price * info.discount + 0.5)
        if self.view.deco then
            self.view.deco.gameObject:SetActive(false)
        end
    else
        self.view.moneyDecPriceItem.gameObject:SetActive(false)
        self.view.numberMoneyGreyTxt.gameObject:SetActiveIfNecessary(false)
        self.view.numberMoneyTxt.text = goodsTableData.price
        realPrice = goodsTableData.price
        if self.view.deco then
            self.view.deco.gameObject:SetActive(true)
        end
    end
    if realPrice > haveMoney then
        self.view.numberMoneyTxt.color = self.view.config.RED_COLOR
    else
        self.view.numberMoneyTxt.color = self.view.config.WHITE_COLOR
    end
    local shopSystem = GameInstance.player.shopSystem
    local remainCount = shopSystem:GetRemainCountByGoodsId(info.shopId, info.goodsId)
    if remainCount == 0 and self.view.soldOutNode then
        self.view.soldOutNode.gameObject:SetActive(true)
    end
end
ShopWeaponCell.InitShopWeaponCell = HL.Method(HL.Any) << function(self, info)
    self.m_info = info
    self:_FirstTimeInit()
    local shopSystem = GameInstance.player.shopSystem
    if self.view.shopWeaponTag then
        self.view.shopWeaponTag:InitShopWeaponTag(info)
    end
    local goodsId = info.goodsTemplateId
    local goodsTableData = Tables.shopGoodsTable[info.goodsTemplateId]
    local moneyId = goodsTableData.moneyId
    local haveMoney = Utils.getItemCount(moneyId)
    local realPrice = 0
    if info.discount and info.discount < 1 then
        self.view.moneyDecPriceItem.gameObject:SetActive(true)
        self.view.numberMoneyGreyTxt.gameObject:SetActiveIfNecessary(true)
        self.view.numberMoneyTxt.text = math.floor(goodsTableData.price * info.discount)
        self.view.numberMoneyGreyTxt.text = goodsTableData.price
        realPrice = math.floor(goodsTableData.price * info.discount + 0.5)
        if self.view.deco then
            self.view.deco.gameObject:SetActive(false)
        end
    else
        self.view.moneyDecPriceItem.gameObject:SetActive(false)
        self.view.numberMoneyGreyTxt.gameObject:SetActiveIfNecessary(false)
        self.view.numberMoneyTxt.text = goodsTableData.price
        realPrice = goodsTableData.price
        if self.view.deco then
            self.view.deco.gameObject:SetActive(true)
        end
    end
    if realPrice > haveMoney then
        self.view.numberMoneyTxt.color = self.view.config.RED_COLOR
    else
        self.view.numberMoneyTxt.color = self.view.config.WHITE_COLOR
    end
    local moneyItemData = Tables.itemTable:GetValue(moneyId)
    self.view.iconMoneyImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_WALLET, moneyItemData.iconId)
    local remainCount = shopSystem:GetRemainCountByGoodsId(info.shopId, goodsId)
    local itemId = nil
    local count = 0
    local itemData
    if string.isEmpty(goodsTableData.rewardId) then
        local weaponPool = Tables.gachaWeaponPoolTable[goodsTableData.weaponGachaPoolId]
        local weaponId = weaponPool.upWeaponIds[0]
        local _, weaponItemCfg = Tables.itemTable:TryGetValue(weaponId)
        itemId = weaponId
        if self.view.titleTxt then
            self.view.titleTxt.text = string.format(Language.LUA_SHOP_WEAPON_UP_TITLE, weaponItemCfg.name)
        end
        itemData = weaponItemCfg
        count = 1
        self.view.randomWeaponsTxt.text = weaponPool.name
        self.view.image.sprite = self:LoadSprite(UIConst.UI_SPRITE_SHOP_WEAPON_BOX, weaponPool.upWeaponIcon)
        self.m_isBox = true
    else
        local displayItem = UIUtils.getRewardFirstItem(goodsTableData.rewardId)
        itemId = displayItem.id
        count = displayItem.count
        local unlock = shopSystem:CheckGoodsUnlocked(goodsId)
        if self.view.lockNode then
            self.view.lockNode.gameObject:SetActive(not unlock)
        end
        if self.view.soldOutNode then
            self.view.soldOutNode.gameObject:SetActive(remainCount == 0)
        end
        itemData = Tables.itemTable[itemId]
        if self.view.rarityLineImg then
            UIUtils.setItemRarityImage(self.view.rarityLineImg, itemData.rarity)
            UIUtils.setItemRarityImage(self.view.rarityLineImg02, itemData.rarity)
        end
        self.view.image.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, itemData.iconId)
        self.view.randomWeaponsTxt.text = itemData.name
        if self.view.rarityLineImg then
            UIUtils.setItemRarityImage(self.view.rarityLineImg, itemData.rarity)
            UIUtils.setItemRarityImage(self.view.rarityLineImg02, itemData.rarity)
        end
    end
    if count ~= nil and count > 1 and self.view.numberTxt then
        self.view.numberTxt.text = "× " .. count
        self.view.number.gameObject:SetActiveIfNecessary(true)
    elseif self.view.numberTxt then
        self.view.number.gameObject:SetActiveIfNecessary(false)
    end
    if self.view.weaponDeco then
        self.view.weaponDeco.gameObject:SetActive(itemData.type == GEnums.ItemType.Weapon)
    end
end
HL.Commit(ShopWeaponCell)
return ShopWeaponCell