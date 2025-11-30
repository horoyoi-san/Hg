local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
ItemDescNode = HL.Class('ItemDescNode', UIWidgetBase)
ItemDescNode._OnFirstTimeInit = HL.Override() << function(self)
end
ItemDescNode.InitItemDescNode = HL.Method(HL.String, HL.Opt(HL.Table)) << function(self, itemId, args)
    self:_FirstTimeInit()
    local itemCfg = Tables.itemTable:GetValue(itemId)
    self.view.defaultDesc.text = UIUtils.resolveTextStyle(itemCfg.desc)
    local isTacticalItem, tacticalItemCfg = Tables.useItemTable:TryGetValue(itemId)
    self.view.tacticalItemTitle.gameObject:SetActive(isTacticalItem)
    self.view.tacticalItemDesc.gameObject:SetActive(isTacticalItem)
    self.view.defaultDesc.gameObject:SetActive(not isTacticalItem)
    if isTacticalItem then
        self.view.tacticalItemDesc.text = UIUtils.resolveTextStyle(UIUtils.getItemUseDesc(itemId))
    end
    local isEquipUnlock = Utils.isSystemUnlocked(GEnums.UnlockSystemType.Equip)
    local isEquipItem, equipItemCfg = Tables.equipItemTable:TryGetValue(itemId)
    self.view.equipItemTitle.gameObject:SetActive(isEquipUnlock and isEquipItem)
    self.view.equipItemDesc.gameObject:SetActive(isEquipUnlock and isEquipItem)
    if isEquipUnlock and isEquipItem then
        self.view.equipItemDesc.text = UIUtils.resolveTextStyle(UIUtils.getItemEquippedDesc(itemId))
    end
    self.view.decoDesc.text = itemCfg.decoDesc
end
HL.Commit(ItemDescNode)
return ItemDescNode