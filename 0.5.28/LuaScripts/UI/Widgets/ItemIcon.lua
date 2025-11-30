local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
ItemIcon = HL.Class('ItemIcon', UIWidgetBase)
ItemIcon._OnFirstTimeInit = HL.Override() << function(self)
end
ItemIcon.m_itemId = HL.Field(HL.Any)
ItemIcon.m_instId = HL.Field(HL.Any)
ItemIcon.showRarity = HL.Field(HL.Boolean) << true
ItemIcon.InitItemIcon = HL.Method(HL.Opt(HL.String, HL.Boolean, HL.Number)) << function(self, itemId, isBig, instId)
    self:_FirstTimeInit()
    if self.m_itemId == itemId and self.m_instId == instId then
        return
    end
    self.m_itemId = itemId
    self.m_instId = instId
    local itemData = Tables.itemTable[itemId]
    self.view.icon.sprite = UIUtils.loadSprite(self.loader, isBig and UIConst.UI_SPRITE_ITEM_BIG or UIConst.UI_SPRITE_ITEM, itemData.iconId)
    local compositeId = itemData.iconCompositeId
    if string.isEmpty(compositeId) then
        self.showRarity = true
        self.view.bg.gameObject:SetActiveIfNecessary(false)
        self.view.mark.gameObject:SetActiveIfNecessary(false)
        self:_UpdateTrans()
    else
        local compositeData = Tables.itemIconCompositeTable[compositeId]
        self.showRarity = compositeData.showRarity
        local bg
        if compositeData.bgIcons.Count >= itemData.rarity then
            bg = compositeData.bgIcons[itemData.rarity - 1]
        end
        if string.isEmpty(bg) then
            self.view.bg.gameObject:SetActiveIfNecessary(false)
        else
            self.view.bg.gameObject:SetActiveIfNecessary(true)
            self.view.bg:LoadSprite(isBig and UIConst.UI_SPRITE_ITEM_COMPOSITE_DECO_BIG or UIConst.UI_SPRITE_ITEM_COMPOSITE_DECO, bg)
        end
        local mark = compositeData.markIcon
        if string.isEmpty(mark) then
            self.view.mark.gameObject:SetActiveIfNecessary(false)
        else
            self.view.mark.gameObject:SetActiveIfNecessary(true)
            self.view.mark:LoadSprite(isBig and UIConst.UI_SPRITE_ITEM_COMPOSITE_DECO_BIG or UIConst.UI_SPRITE_ITEM_COMPOSITE_DECO, mark)
        end
        self:_UpdateTrans(compositeData.iconTransType)
    end
    self:_RefreshGemAddOnNode(isBig == true, itemData, instId)
end
ItemIcon._UpdateTrans = HL.Method(HL.Opt(GEnums.ItemIconTransType)) << function(self, transType)
    local trans = self.view.icon.transform
    if transType == GEnums.ItemIconTransType.Formula then
        trans.localScale = Vector3.one * self.view.config.FORMULA_ICON_SCALE
        trans.pivot = self.view.config.FORMULA_ICON_PIVOT
    else
        trans.localScale = Vector3.one
        trans.pivot = Vector2.one / 2
    end
end
local DEFAULT_GEM_SPRITE = "icon_wpngem_00"
ItemIcon._RefreshGemAddOnNode = HL.Method(HL.Boolean, HL.Any, HL.Opt(HL.Number)) << function(self, isBig, itemData, instId)
    if not self.view.gemAddonNode then
        return
    end
    if not instId or instId < 0 then
        self.view.gemAddonNode.gameObject:SetActive(false)
        return
    end
    local itemType = itemData.type
    local isWeaponGem = itemType == GEnums.ItemType.WeaponGem
    self.view.gemAddonNode.gameObject:SetActive(isWeaponGem)
    if not isWeaponGem then
        return
    end
    local leadTermId = CharInfoUtils.getGemLeadSkillTermId(instId)
    local leadTermCfg
    local hasTermIcon = false
    if leadTermId then
        leadTermCfg = Tables.gemTable:GetValue(leadTermId)
    end
    hasTermIcon = leadTermCfg and not string.isEmpty(leadTermCfg.tagIcon)
    if hasTermIcon then
        self.view.attrAddonIcon.sprite = UIUtils.loadSprite(self.loader, isBig and UIConst.UI_SPRITE_ITEM_BIG or UIConst.UI_SPRITE_ITEM, leadTermCfg.tagIcon)
    else
        self.view.attrAddonIcon.sprite = UIUtils.loadSprite(self.loader, isBig and UIConst.UI_SPRITE_ITEM_BIG or UIConst.UI_SPRITE_ITEM, DEFAULT_GEM_SPRITE)
    end
end
ItemIcon.SetAlpha = HL.Method(HL.Number) << function(self, alpha)
    self.view.canvasGroup.alpha = alpha
end
HL.Commit(ItemIcon)
return ItemIcon