local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ShopWeapon
local PHASE_ID = PhaseId.ShopWeapon
ShopWeaponCtrl = HL.Class('ShopWeaponCtrl', uiCtrl.UICtrl)
ShopWeaponCtrl.m_shopSystem = HL.Field(HL.Any)
ShopWeaponCtrl.m_boxGoodsCache = HL.Field(HL.Any)
ShopWeaponCtrl.m_weaponGoodsCache = HL.Field(HL.Any)
ShopWeaponCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SHOP_REFRESH] = 'UpdateAll', [MessageConst.ON_SHOP_JUMP_EVENT] = 'OnClickGoods', [MessageConst.ON_SHOP_GOODS_CONDITION_REFRESH] = 'UpdateAll', }
ShopWeaponCtrl.m_getNormalCellFunc = HL.Field(HL.Function)
ShopWeaponCtrl.m_normalGoods = HL.Field(HL.Any)
ShopWeaponCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_shopSystem = GameInstance.player.shopSystem
    self.m_getNormalCellFunc = UIUtils.genCachedCellFunction(self.view.commonWeapons.scrollList)
    self.view.commonWeapons.scrollList.onUpdateCell:AddListener(function(obj, index)
        local cell = self.m_getNormalCellFunc(LuaIndex(index))
        cell:InitShopWeaponCell(self.m_normalGoods[index])
    end)
    self.view.scroll.onValueChanged:AddListener(function(data)
        local show = (self.view.scroll.normalizedPosition.y) > 0.05
        if self.view.upWeaponNextPage.gameObject.activeSelf == show then
            return
        end
        if show then
            self.view.upWeaponNextPage:Play("shopweapon_upweaponnext_in", function()
                self.view.upWeaponNextPage.gameObject:SetActive(true)
            end)
        else
            self.view.upWeaponNextPage:Play("shopweapon_upweaponnext_out", function()
                self.view.upWeaponNextPage.gameObject:SetActive(false)
            end)
        end
    end)
    self:_StartCoroutine(function()
        self:UpdateUpWeapon()
        self:UpdateDailyWeapon()
        coroutine.wait(0.2)
        self:UpdatePermanentWeapon()
    end)
end
ShopWeaponCtrl.UpdateGoodsCell = HL.Method(HL.Any, HL.Table) << function(self, cell, info)
end
ShopWeaponCtrl.UpdateAll = HL.Method() << function(self)
    self:UpdateUpWeapon()
    self:UpdateDailyWeapon()
    self:UpdatePermanentWeapon()
end
ShopWeaponCtrl.OnClickGoods = HL.Method(HL.Opt(HL.Table)) << function(self, arg)
    local goodsId = arg.goods
    if goodsId then
        local goods = Tables.shopGoodsTable[goodsId]
        local shopId = goods.shopId
        local goodsData = self.m_shopSystem:GetShopGoodsData(shopId, goodsId)
        if goodsData == nil then
            logger.error(ELogChannel.UI, "商店商品数据为空")
            return
        end
        local isBox = string.isEmpty(goods.rewardId)
        if isBox then
            PhaseManager:OpenPhase(PhaseId.GachaWeaponPool, { goodsData = goodsData })
        else
            UIManager:Open(PanelId.ShopDetail, goodsData)
        end
        return
    end
    if arg.sourceId and arg.targetId then
        PhaseManager:OpenPhase(PhaseId.CommonMoneyExchange, { sourceId = arg.sourceId, targetId = arg.targetId })
    end
end
ShopWeaponCtrl.UpdateUpWeapon = HL.Method() << function(self)
    local _, box, goods = self.m_shopSystem:GetNowUpWeaponData()
    if box == nil or box.Count == 0 then
        self.view.randomWeaponsCase.gameObject:SetActive(false)
        self.view.upLimitWeapons.gameObject:SetActive(false)
        return
    end
    local goodsTableData = Tables.shopGoodsTable[box[0].goodsTemplateId]
    self.view.randomWeaponsCase.shopWeaponCaseCell:InitShopWeaponCell(box[0])
    local weaponPool = Tables.gachaWeaponPoolTable[goodsTableData.relatedWeaponGachPoolId]
    local weaponId = weaponPool.upWeaponIds[0]
    local _, weaponItemCfg = Tables.itemTable:TryGetValue(weaponId)
    self.view.randomWeaponsCase.shopWeaponCaseCell.view.titleTxt.gameObject:SetActive(true)
    self.view.upLimitWeapons.shopWeaponCell:InitShopWeaponCell(goods[0])
    if goods.Count > 1 then
        self.view.upLimitWeapons.shopWeaponCell02.gameObject:SetActive(true)
        self.view.upLimitWeapons.shopWeaponCell02:InitShopWeaponCell(goods[1])
    else
        self.view.upLimitWeapons.shopWeaponCell02.gameObject:SetActive(false)
    end
    local csGacha = GameInstance.player.gacha
    for id, csInfo in pairs(csGacha.poolInfos) do
        if csInfo.id == goodsTableData.relatedWeaponGachPoolId then
            local endTime = csInfo.closeTime
            local now = CS.Beyond.DateTimeUtils.GetCurrentTimestampBySeconds()
            local diff = endTime - now
            diff = math.max(diff, 0)
            self.view.upLimitWeapons.timeLimitTitleText.text = string.format(Language.LUA_SHOP_WEAPON_TIME_LIMIT, Utils.appendUTC(Utils.timestampToDateYMDHM(endTime)))
            self.view.randomWeaponsCase.upWeaponTitleText.text = string.format(Language.LUA_SHOP_WEAPON_TIME_LIMIT, Utils.appendUTC(Utils.timestampToDateYMDHM(endTime)))
        end
    end
end
ShopWeaponCtrl.UpdatePermanentWeapon = HL.Method() << function(self)
    local _, box, goods = self.m_shopSystem:GetPermanentWeaponShopData()
    self.m_shopSystem:SortGoodsList(box)
    self.m_shopSystem:SortGoodsList(goods)
    local permanentBoxCache = self.m_boxGoodsCache or UIUtils.genCellCache(self.view.commonWeapons.shopWeaponCaseCell)
    permanentBoxCache:Refresh(box.Count, function(cell, index)
        cell:InitShopWeaponCell(box[CSIndex(index)])
    end)
    self.m_normalGoods = goods
    local weaponCache = self.m_weaponGoodsCache or UIUtils.genCellCache(self.view.commonWeapons.shopWeaponCell)
    weaponCache:Refresh(goods.Count, function(cell, index)
        cell:InitShopWeaponCell(goods[CSIndex(index)])
    end)
    self.m_boxGoodsCache = permanentBoxCache
    self.m_weaponGoodsCache = weaponCache
end
ShopWeaponCtrl.UpdateDailyWeapon = HL.Method() << function(self)
    local _, box, goods = self.m_shopSystem:GetDailyWeaponData()
    GameInstance.player.shopSystem:SortGoodsList(goods)
    for i = 0, 2 do
        if goods.Count > i then
            self.view.permanentLimitWeapons["shopWeaponCell0" .. LuaIndex(i)].gameObject:SetActive(true)
            self.view.permanentLimitWeapons["shopWeaponCell0" .. LuaIndex(i)]:InitShopWeaponCell(goods[i])
        else
            self.view.permanentLimitWeapons["shopWeaponCell0" .. LuaIndex(i)].gameObject:SetActive(false)
        end
    end
    local endTime = GameInstance.player.shopSystem:GetWeaponGoodsTimeLimit(goods[0]) + 1
    local now = CS.Beyond.DateTimeUtils.GetCurrentTimestampBySeconds()
    self.view.permanentLimitWeapons.timeLimitTitleText.text = string.format(Language.LUA_SHOP_WEAPON_DAILY_TIME_LIMIT, Utils.appendUTC(Utils.timestampToDateYMDHM(endTime + now)))
end
HL.Commit(ShopWeaponCtrl)