local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
local ShopGroupIdMap = { [1] = "shop_pay_gacha", [2] = "shop_pay_weapon", [3] = "shop_pay_yellow", [4] = "shop_pay_green", }
ShopTopNode = HL.Class('ShopTopNode', UIWidgetBase)
ShopTopNode._OnFirstTimeInit = HL.Override() << function(self)
end
ShopTopNode.m_tabIndex = HL.Field(HL.Number) << 0
ShopTopNode.m_curPanel = HL.Field(HL.Any)
ShopTopNode.m_tabClickFuncs = HL.Field(HL.Table)
ShopTopNode.m_entryPanel = HL.Field(HL.Any)
ShopTopNode.m_weaponPanel = HL.Field(HL.Any)
ShopTopNode.m_yellowPanel = HL.Field(HL.Any)
ShopTopNode.m_greenPanel = HL.Field(HL.Any)
ShopTopNode.m_whiteCache = HL.Field(HL.Any)
ShopTopNode.m_blackCache = HL.Field(HL.Any)
ShopTopNode.m_parent = HL.Field(HL.Any)
ShopTopNode.m_entry = HL.Field(HL.Any)
ShopTopNode.InitShopTopNode = HL.Method(HL.Any) << function(self, arg)
    self:_FirstTimeInit()
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.ShopEntry)
    end)
    self.m_tabIndex = 1
    self.m_entry = arg.ctrl
    self.m_entryPanel = arg
    self.m_curPanel = self.m_entryPanel
    self.m_parent = arg.parent
    self.m_parent.view.animationWrapper:Play("shoptopnode_in")
    self.view.tabWhite.gameObject:SetActive(false)
    self.view.tabBlack.gameObject:SetActive(true)
    self.m_tabClickFuncs = {
        function()
            self:PlayTabAnimation(1)
            self.m_tabIndex = 1
            self.m_curPanel.view.main.gameObject:SetActive(false)
            self.m_entryPanel.view.main.gameObject:SetActive(true)
            self.m_curPanel = self.m_entryPanel
            self.view.moneyCell01:InitMoneyCell(Tables.globalConst.originiumItemId)
            self.view.moneyCell02.gameObject:SetActive(true)
            self.view.moneyCell02:InitMoneyCell(Tables.globalConst.diamondItemId)
            self:SetSortingOrder()
            local cell = self.m_entry.m_getCellFunc(LuaIndex(self.m_entry.view.main.centerIndex))
            self.m_entry:PlayInAnimation(cell)
            self.m_entry:CheckTab()
        end,
        function()
            self:PlayTabAnimation(2)
            self.m_tabIndex = 2
            self.m_curPanel.view.main.gameObject:SetActive(false)
            if not self.m_weaponPanel then
                self.m_weaponPanel = UIManager:Open(PanelId.ShopWeapon)
            end
            self.m_weaponPanel.view.main.gameObject:SetActive(true)
            self.m_weaponPanel.view.animationWrapper:Play("shopweapon_in")
            self.m_curPanel = self.m_weaponPanel
            self.view.moneyCell01:InitMoneyCell(Tables.globalConst.diamondItemId)
            self.view.moneyCell02.gameObject:SetActive(true)
            self.view.moneyCell02:InitMoneyCell(Tables.globalConst.gachaWeaponItemId)
            self:SetSortingOrder()
        end,
        function()
            self:PlayTabAnimation(3)
            self.m_tabIndex = 3
            local shop = GameInstance.player.shopSystem:GetShopData("shop_pay_yellow_1")
            self:RefreshYellowOrGreen(shop.goodList)
            self.view.moneyCell01:InitMoneyCell(Tables.globalConst.yellowItemId)
            self.view.moneyCell02.gameObject:SetActive(false)
            self:SetSortingOrder()
        end,
        function()
            self:PlayTabAnimation(4)
            self.m_tabIndex = 4
            local shop = GameInstance.player.shopSystem:GetShopData("shop_pay_green_1")
            self:RefreshYellowOrGreen(shop.goodList)
            self.view.moneyCell01:InitMoneyCell(Tables.globalConst.greenItemId)
            self.view.moneyCell02.gameObject:SetActive(false)
            self:SetSortingOrder()
        end
    }
    self.view.moneyCell01:InitMoneyCell(Tables.globalConst.originiumItemId)
    self.view.moneyCell02:InitMoneyCell(Tables.globalConst.diamondItemId)
    self:RefreshTab()
end
ShopTopNode.PlayTabAnimation = HL.Method(HL.Number) << function(self, index)
    if self.m_tabIndex == index then
        return
    end
    if index == 1 then
        if self.m_tabIndex ~= 1 then
            self.m_parent.view.animationWrapper:Play("shoptopnode_out", function()
                self.m_parent.view.animationWrapper:Play("shoptopnode_in")
            end)
        else
            self.m_parent.view.animationWrapper:Play("shoptopnode_in")
        end
    else
        if self.m_tabIndex == 1 then
            self.m_parent.view.animationWrapper:Play("shoptopnode_out", function()
                self.m_parent.view.animationWrapper:Play("shoptopnode_in")
                self:SwitchTabBlackWhite(true)
            end)
        elseif self.m_tabIndex == 0 then
            self:SwitchTabBlackWhite(true)
            self.m_parent.view.animationWrapper:Play("shoptopnode_in")
        end
    end
end
ShopTopNode.SwitchTabBlackWhite = HL.Method(HL.Boolean) << function(self, isWhite)
    if self.m_tabIndex ~= 1 and not isWhite then
        return
    end
    if isWhite then
        self.view.tabWhite.gameObject:SetActive(true)
        self.view.tabBlack.gameObject:SetActive(false)
    else
        self.view.tabWhite.gameObject:SetActive(false)
        self.view.tabBlack.gameObject:SetActive(true)
    end
end
ShopTopNode.RefreshTab = HL.Method() << function(self)
    local tabCount = 4
    self.m_whiteCache = self.m_whiteCache or UIUtils.genCellCache(self.view.shopTabCellWhite)
    self.m_whiteCache:Refresh(tabCount, function(cell, index)
        self:RefreshTabCell(cell, index)
    end)
    self.m_blackCache = self.m_blackCache or UIUtils.genCellCache(self.view.shopTabCellBlack)
    self.m_blackCache:Refresh(tabCount, function(cell, index)
        self:RefreshTabCell(cell, index)
    end)
end
ShopTopNode.SetSortingOrder = HL.Method() << function(self)
    if self.m_curPanel then
        self.m_parent.view.canvas.sortingOrder = self.m_curPanel.view.gameObject:GetComponent("Canvas").sortingOrder + 10
    end
end
ShopTopNode.RefreshTabCell = HL.Method(HL.Any, HL.Number) << function(self, go, index)
    go.tabSlcText.text = Language["LUA_SHOP_ENTRY_" .. index]
    go.tabNormalText.text = Language["LUA_SHOP_ENTRY_" .. index]
    go.slc.gameObject:SetActive(index == self.m_tabIndex)
    go.normal.gameObject:SetActive(index ~= self.m_tabIndex)
    local shopGroupId = ShopGroupIdMap[index]
    local shopGroupCfg = Utils.tryGetTableCfg(Tables.shopGroupTable, shopGroupId)
    if shopGroupCfg then
        local icon = self:LoadSprite(UIConst.UI_SPRITE_SHOP_WEAPON_BOX, shopGroupCfg.icon)
        go.slcIcon.sprite = icon
        go.normalIcon.sprite = icon
    end
    go.normal.onClick:RemoveAllListeners()
    go.normal.onClick:AddListener(function()
        if self.m_tabIndex == index then
            return
        end
        local func = self.m_tabClickFuncs[index]
        if func then
            func()
        end
        self:RefreshTab()
    end)
end
ShopTopNode.RefreshYellowOrGreen = HL.Method(HL.Any) << function(self, goodsData)
    self.m_curPanel.view.main.gameObject:SetActive(false)
    if not self.m_yellowPanel then
        self.m_yellowPanel = UIManager:Open(PanelId.ShopYellowGreen, goodsData)
    end
    self.m_yellowPanel.view.main.gameObject:SetActive(true)
    self.m_yellowPanel:Refresh(goodsData)
    self.m_curPanel = self.m_yellowPanel
    self.view.moneyCell01:InitMoneyCell(Tables.globalConst.diamondItemId)
    self.view.moneyCell02:InitMoneyCell(Tables.globalConst.gachaWeaponItemId)
end
ShopTopNode._OnEnable = HL.Override() << function(self)
end
ShopTopNode._OnDestroy = HL.Override() << function(self)
    if self.m_weaponPanel then
        self.m_weaponPanel:PlayAnimationOutAndClose()
    end
    if self.m_yellowPanel then
        self.m_yellowPanel:PlayAnimationOutAndClose()
    end
    self.m_parent.view.animationWrapper:Play("shoptopnode_out")
end
HL.Commit(ShopTopNode)
return ShopTopNode