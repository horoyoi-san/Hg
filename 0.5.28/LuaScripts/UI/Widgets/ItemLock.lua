local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
ItemLock = HL.Class('ItemLock', UIWidgetBase)
ItemLock.itemId = HL.Field(HL.String) << ""
ItemLock.instId = HL.Field(HL.Number) << 0
ItemLock._OnFirstTimeInit = HL.Override() << function(self)
    self:RegisterMessage(MessageConst.ON_ITEM_LOCKED_STATE_CHANGED, function(arg)
        self:_OnItemLockedStateChanged(arg)
    end)
end
ItemLock.InitItemLock = HL.Method(HL.Opt(HL.String, HL.Number)) << function(self, itemId, instId)
    self.itemId = ""
    if not instId or instId <= 0 then
        self.view.gameObject:SetActive(false)
        return
    end
    local itemData = Tables.itemTable[itemId]
    if itemData == nil then
        self.view.gameObject:SetActive(false)
        return
    end
    local itemType = itemData.type
    if itemType == GEnums.ItemType.Weapon or itemType == GEnums.ItemType.WeaponGem or itemType == GEnums.ItemType.Equip then
        self.view.gameObject:SetActive(true)
    else
        self.view.gameObject:SetActive(false)
        return
    end
    self:_FirstTimeInit()
    self.itemId, self.instId = itemId, instId
    self.gameObject:SetActive(GameInstance.player.inventory:IsItemLocked(Utils.getCurrentScope(), itemId, instId))
end
ItemLock._OnItemLockedStateChanged = HL.Method(HL.Table) << function(self, arg)
    if string.isEmpty(self.itemId) then
        return
    end
    local itemId, instId, isLock = unpack(arg)
    local isCurItem = self.itemId == itemId and self.instId == instId
    if not isCurItem then
        return
    end
    self.view.gameObject:SetActive(isLock)
end
HL.Commit(ItemLock)
return ItemLock