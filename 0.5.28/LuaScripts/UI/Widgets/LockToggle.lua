local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
LockToggle = HL.Class('LockToggle', UIWidgetBase)
LockToggle.itemId = HL.Field(HL.String) << ""
LockToggle.instId = HL.Field(HL.Number) << 0
LockToggle.canLock = HL.Field(HL.Boolean) << true
LockToggle._OnFirstTimeInit = HL.Override() << function(self)
    self.view.toggle.onValueChanged:AddListener(function(isOn)
        self:_LockItem(isOn)
    end)
    self.view.canLockBtn.onClick:AddListener(function()
        Notify(MessageConst.SHOW_TOAST, Language.LUA_FORBID_ITEM_LOCK_TOAST)
    end)
    self.view.toggle.clickOnHintTextId = "key_hint_item_lock_toggle"
    self.view.toggle.clickOffHintTextId = "key_hint_item_lock_toggle"
end
LockToggle.InitLockToggle = HL.Method(HL.String, HL.Number) << function(self, itemId, instId)
    self:_FirstTimeInit()
    self.itemId = ""
    if not instId or instId <= 0 or not (GameInstance.player.inventory:TryGetInstItem(Utils.getCurrentScope(), instId)) then
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
    local isItemInDepot = GameInstance.player.inventory:IsItemInDepot(Utils.getCurrentScope(), itemId, instId)
    self.view.toggle.interactable = isItemInDepot
    self.view.canLockBtn.gameObject:SetActive(not isItemInDepot)
    if not isItemInDepot then
        self.view.toggle:SetIsOnWithoutNotify(false)
        return
    end
    self.itemId, self.instId = itemId, instId
    self.view.toggle:SetIsOnWithoutNotify(GameInstance.player.inventory:IsItemLocked(Utils.getCurrentScope(), itemId, instId))
end
LockToggle._LockItem = HL.Method(HL.Boolean) << function(self, isOn)
    if string.isEmpty(self.itemId) then
        return
    end
    local isItemLock = GameInstance.player.inventory:IsItemLocked(Utils.getCurrentScope(), self.itemId, self.instId)
    if isItemLock ~= isOn then
        GameInstance.player.inventory:LockItem(Utils.getCurrentScope(), self.itemId, self.instId, isOn)
        if isOn then
            AudioAdapter.PostEvent("au_ui_btn_valuable_lock")
        else
            AudioAdapter.PostEvent("au_ui_btn_valuable_unlock")
        end
    end
end
HL.Commit(LockToggle)
return LockToggle