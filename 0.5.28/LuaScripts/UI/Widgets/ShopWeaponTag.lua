local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
ShopWeaponTag = HL.Class('ShopWeaponTag', UIWidgetBase)
ShopWeaponTag._OnFirstTimeInit = HL.Override() << function(self)
end
ShopWeaponTag.m_lateTickKey = HL.Field(HL.Number) << 0
ShopWeaponTag.m_data = HL.Field(HL.Any)
ShopWeaponTag.InitShopWeaponTag = HL.Method(HL.Any) << function(self, goodsData)
    self:_FirstTimeInit()
    self.m_data = goodsData
    local leftTime = GameInstance.player.shopSystem:GetWeaponGoodsTimeLimit(goodsData)
    if leftTime > -1 then
        self:UpdateTime()
        if self.m_lateTickKey == 0 then
            self.m_lateTickKey = LuaUpdate:Add("LateTick", function(deltaTime)
                self:UpdateTime()
            end)
        end
    else
        self.view.tagTime.gameObject:SetActive(false)
    end
    local limitBuy = GameInstance.player.shopSystem:GetRemainCountByGoodsId(goodsData.shopId, goodsData.goodsTemplateId)
    if limitBuy > 0 then
        self.view.tagRestriction.gameObject:SetActive(true)
        self.view.shopRestrictionText.text = limitBuy
    elseif limitBuy == -1 then
        self.view.tagRestriction.gameObject:SetActive(true)
        self.view.shopRestrictionText.text = "∞"
    else
        self.view.tagRestriction.gameObject:SetActive(false)
    end
    if goodsData.discount and goodsData.discount < 1 then
        self.view.tagDiscount.gameObject:SetActive(true)
        self.view.discountNumber.text = string.format("-%d<size=60%%>%%</size>", math.floor((1 - goodsData.discount) * 100 + 0.5))
    else
        self.view.tagDiscount.gameObject:SetActive(false)
    end
    self.view.tagRecommond.gameObject:SetActive(false)
end
ShopWeaponTag.UpdateTime = HL.Method() << function(self)
    local goodsData = self.m_data
    local leftTime = GameInstance.player.shopSystem:GetWeaponGoodsTimeLimit(goodsData)
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
end
ShopWeaponTag._OnDestroy = HL.Override() << function(self)
    if self.m_lateTickKey > 0 then
        LuaUpdate:Remove(self.m_lateTickKey)
    end
end
HL.Commit(ShopWeaponTag)
return ShopWeaponTag