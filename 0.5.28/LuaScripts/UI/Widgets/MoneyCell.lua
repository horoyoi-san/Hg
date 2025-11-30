local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
MoneyCell = HL.Class('MoneyCell', UIWidgetBase)
MoneyCell.m_itemId = HL.Field(HL.String) << ""
MoneyCell.m_isMoneyType = HL.Field(HL.Boolean) << false
MoneyCell.m_coroutine = HL.Field(HL.Thread)
MoneyCell.m_lastStamina = HL.Field(HL.Number) << 0
MoneyCell.m_controllerBindingId = HL.Field(HL.Number) << -1
MoneyCell.m_useItemIcon = HL.Field(HL.Boolean) << false
MoneyCell.m_needNumberLimit = HL.Field(HL.Boolean) << true
MoneyCell._OnFirstTimeInit = HL.Override() << function(self)
    self:_RegisterMessages()
    local autoCloseArea = self.view.autoCloseArea
    autoCloseArea.tmpSafeArea = self.view.tip.transform
    autoCloseArea.onTriggerAutoClose:RemoveAllListeners()
    autoCloseArea.onTriggerAutoClose:AddListener(function()
        local active = self.view.tip.gameObject.activeSelf
        if active then
            self.view.tip.gameObject:SetActive(false)
        end
    end)
end
MoneyCell._OnDestroy = HL.Override() << function(self)
    self:_StopTick()
end
MoneyCell._OnDisable = HL.Override() << function(self)
    self:_StopTick()
    if self:_IsStamina() then
        self.view.tip.gameObject:SetActive(false)
    end
end
MoneyCell.InitMoneyCell = HL.Method(HL.String, HL.Opt(HL.Boolean, HL.Boolean, HL.Boolean)) << function(self, itemId, useAction, useItemIcon, needNumberLimit)
    self:_FirstTimeInit()
    self.m_itemId = itemId
    local itemData = Tables.itemTable:GetValue(self.m_itemId)
    self.m_isMoneyType = GameInstance.player.inventory:IsMoneyType(itemData.type)
    self.m_useItemIcon = useItemIcon == true
    self.m_needNumberLimit = needNumberLimit == true
    self:_RefreshUI()
    if self:_IsStamina() then
        self:_StartTick()
    end
    self:_ClearControllerBinding()
    if useAction then
        self.m_controllerBindingId = InputManagerInst:CreateBindingByActionId("inv_money_add", function()
            self:_OnClickAddItem()
        end, self.view.addBtn.groupId)
        self.view.keyHint.gameObject:SetActiveIfNecessary(useAction)
    else
        self.view.keyHint.gameObject:SetActiveIfNecessary(false)
    end
end
MoneyCell._RegisterMessages = HL.Method() << function(self)
    self:RegisterMessage(MessageConst.ON_STAMINA_CHANGED, function()
        self:_OnStaminaChanged()
    end)
    self:RegisterMessage(MessageConst.ON_WALLET_CHANGED, function(evtData)
        self:_OnWalletChanged(evtData)
    end)
    self:RegisterMessage(MessageConst.ON_ITEM_COUNT_CHANGED, function(evtData)
        if not self.m_isMoneyType then
            self:_OnItemCountChanged(evtData)
        end
    end)
end
MoneyCell._RefreshUI = HL.Method() << function(self)
    local itemData = Tables.itemTable:GetValue(self.m_itemId)
    self.view.icon.sprite = self:LoadSprite(self.m_useItemIcon and UIConst.UI_SPRITE_ITEM or UIConst.UI_SPRITE_WALLET, itemData.iconId)
    self.view.button.onClick:RemoveAllListeners()
    self.view.button.onClick:AddListener(function()
        self:_OnClickItem()
    end)
    local showAddBtn = self:_ShouldShowAddButton()
    self.view.addBtn.gameObject:SetActive(showAddBtn)
    if showAddBtn then
        self.view.tip:InitStaminaTips()
        self.view.addBtn.onClick:RemoveAllListeners()
        self.view.addBtn.onClick:AddListener(function()
            self:_OnClickAddItem()
        end)
    end
    self:_UpdateCount()
end
MoneyCell._UpdateCount = HL.Method() << function(self)
    if self:_IsStamina() then
        local curStamina = GameInstance.player.inventory.curStamina
        local maxStamina = GameInstance.player.inventory.maxStamina
        self.view.text.text = string.format(Language.LUA_FORWARD_SLASH, curStamina, maxStamina)
    elseif self.m_needNumberLimit then
        self.view.text.text = string.format("%s/%s", GameInstance.player.inventory:GetItemCount(Utils.getCurrentScope(), Utils.getCurrentChapterId(), self.m_itemId), Tables.MoneyConfigTable:GetValue(self.m_itemId).MoneyClearLimit)
    else
        self.view.text.text = tonumber(GameInstance.player.inventory:GetItemCount(Utils.getCurrentScope(), Utils.getCurrentChapterId(), self.m_itemId))
    end
end
MoneyCell._ShouldShowAddButton = HL.Method().Return(HL.Boolean) << function(self)
    return self:_IsStamina() or self:_IsDiamond() or self:_IsWeaponGacha()
end
MoneyCell._OnClickItem = HL.Method() << function(self)
    if self:_IsStamina() then
        if DeviceInfo.usingController then
            UIManager:Open(PanelId.StaminaPopUp)
        else
            local curStamina = GameInstance.player.inventory.curStamina
            local maxStamina = GameInstance.player.inventory.maxStamina
            if curStamina >= maxStamina then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_STAMINA_FULL_HINT)
            else
                local active = self.view.tip.gameObject.activeSelf
                self.view.tip.gameObject:SetActive(not active)
            end
        end
        AudioAdapter.PostEvent("au_ui_btn_ap_info")
    else
        Notify(MessageConst.SHOW_ITEM_TIPS, { transform = self.view.transform, posType = UIConst.UI_TIPS_POS_TYPE.MidBottom, itemId = self.m_itemId, })
    end
end
MoneyCell._OnClickAddItem = HL.Method() << function(self)
    if self:_IsStamina() then
        UIManager:Open(PanelId.StaminaPopUp)
    elseif self:_IsDiamond() then
        PhaseManager:OpenPhase(PhaseId.CommonMoneyExchange, { sourceId = Tables.globalConst.originiumItemId, targetId = Tables.globalConst.diamondItemId })
    elseif self:_IsWeaponGacha() then
        PhaseManager:OpenPhase(PhaseId.CommonMoneyExchange, { sourceId = Tables.globalConst.diamondItemId, targetId = Tables.globalConst.gachaWeaponItemId })
    end
end
MoneyCell._OnStaminaChanged = HL.Method() << function(self)
    if self:_IsStamina() then
        self:_UpdateCount()
        local curStamina = GameInstance.player.inventory.curStamina
        local maxStamina = GameInstance.player.inventory.maxStamina
        if curStamina >= maxStamina then
            self.view.tip.gameObject:SetActiveIfNecessary(false)
        end
    end
end
MoneyCell._OnWalletChanged = HL.Method(HL.Table) << function(self, args)
    if self:_IsStamina() then
        return
    end
    local id, amount, opAmount = unpack(args)
    if id == self.m_itemId then
        self:_UpdateCount()
    end
end
MoneyCell._OnItemCountChanged = HL.Method(HL.Table) << function(self, arg)
    if string.isEmpty(self.m_itemId) then
        return
    end
    local itemId2DiffCount = unpack(arg)
    if itemId2DiffCount:ContainsKey(self.m_itemId) then
        self:_UpdateCount()
    end
end
MoneyCell._IsStamina = HL.Method().Return(HL.Boolean) << function(self)
    return self.m_itemId == Tables.globalConst.apItemId
end
MoneyCell._IsDiamond = HL.Method().Return(HL.Boolean) << function(self)
    return self.m_itemId == Tables.globalConst.diamondItemId
end
MoneyCell._IsWeaponGacha = HL.Method().Return(HL.Boolean) << function(self)
    return self.m_itemId == Tables.globalConst.gachaWeaponItemId
end
MoneyCell._StartTick = HL.Method() << function(self)
    self.m_lastStamina = GameInstance.player.inventory.curStamina
    self.m_coroutine = self:_StartCoroutine(function()
        while true do
            coroutine.wait(UIConst.COMMON_UI_TIME_UPDATE_INTERVAL)
            self:_UpdateStamina()
        end
    end)
end
MoneyCell._StopTick = HL.Method() << function(self)
    if self.m_coroutine then
        self:_ClearCoroutine(self.m_coroutine)
    end
end
MoneyCell._UpdateStamina = HL.Method() << function(self)
    local curStamina = GameInstance.player.inventory.curStamina
    if curStamina ~= self.m_lastStamina then
        self:_UpdateCount()
        self.m_lastStamina = curStamina
    end
end
MoneyCell._ClearControllerBinding = HL.Method() << function(self)
    if self.m_controllerBindingId == -1 then
        return
    end
    InputManagerInst:DeleteBinding(self.m_controllerBindingId)
    self.m_controllerBindingId = -1
end
HL.Commit(MoneyCell)
return MoneyCell