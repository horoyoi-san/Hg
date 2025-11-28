local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
Item = HL.Class('Item', UIWidgetBase)
Item.canPlace = HL.Field(HL.Boolean) << false
Item.canSplit = HL.Field(HL.Boolean) << false
Item.canUse = HL.Field(HL.Boolean) << false
Item.canClear = HL.Field(HL.Boolean) << false
Item.canDestroy = HL.Field(HL.Boolean) << false
Item.canSetQuickBar = HL.Field(HL.Boolean) << false
Item.fromDepot = HL.Field(HL.Boolean) << false
Item.showingTips = HL.Field(HL.Boolean) << false
Item.hideItemObtainWays = HL.Field(HL.Boolean) << false
Item.hideBottomInfo = HL.Field(HL.Boolean) << false
Item.slotIndex = HL.Field(HL.Any)
Item.id = HL.Field(HL.String) << ''
Item.count = HL.Field(HL.Number) << 0
Item.instId = HL.Field(HL.Any)
Item.extraInfo = HL.Field(HL.Table)
Item.prefixDesc = HL.Field(HL.String) << ''
Item.equipInfo = HL.Field(HL.Any)
Item.redDot = HL.Field(HL.Forward("RedDot"))
Item.m_showCount = HL.Field(HL.Boolean) << true
Item.m_isSelected = HL.Field(HL.Boolean) << false
Item.m_isInfinite = HL.Field(HL.Boolean) << false
Item.m_showingHover = HL.Field(HL.Boolean) << false
Item.m_needShowDeco1 = HL.Field(HL.Boolean) << false
Item._OnFirstTimeInit = HL.Override() << function(self)
    self.redDot = self.view.redDot
    self:SetSelected(false, true)
end
Item._ResetOnInit = HL.Method() << function(self)
    self.canPlace = false
    self.canSplit = false
    self.canUse = false
    self.canDestroy = false
    self.canSetQuickBar = false
    self:ShowPickUpLogo(false)
    self.view.levelNode.gameObject:SetActive(false)
    self.view.button.onIsNaviTargetChanged = nil
    self.view.button.onClick:RemoveAllListeners()
    self.view.button.onHoverChange:RemoveAllListeners()
    self.view.button.onLongPress:RemoveAllListeners()
    if self.redDot then
        self.redDot:Stop()
    end
    self.view.button.clickHintTextId = nil
    self.view.button.longPressHintTextId = nil
    InputManagerInst:DeleteInGroup(self.view.button.hoverBindingGroupId)
    self.m_actionMenuBindingId = -1
    self.actionMenuArgs = nil
    self.customChangeActionMenuFunc = nil
    self.m_needShowDeco1 = self.view.deco1.gameObject.activeSelf
end
Item._CloseHoverTips = HL.Method() << function(self)
    if self.m_showingHover then
        Notify(MessageConst.HIDE_COMMON_HOVER_TIP)
        self.m_showingHover = false
    end
end
Item.InitItem = HL.Method(HL.Opt(HL.Any, HL.Any, HL.String, HL.Boolean)) << function(self, itemBundle, onClick, limitId, clickableEvenEmpty)
    self:_FirstTimeInit()
    self:_ResetOnInit()
    self:SetIconTransparent(UIConst.ITEM_EXIST_TRANSPARENCY)
    if itemBundle then
        if Cfg.GetType(itemBundle) == Cfg.Types.ItemBundle then
            itemBundle = { id = itemBundle.id, count = itemBundle.count, }
        end
    end
    local isEmpty = itemBundle == nil or string.isEmpty(itemBundle.id)
    local isLimited = not string.isEmpty(limitId)
    self.view.content.gameObject:SetActive(not isEmpty or isLimited)
    if itemBundle == nil then
        self.m_isInfinite = false
    else
        self.m_isInfinite = itemBundle.isInfinite or false
    end
    self.extraInfo = {}
    local data
    if isEmpty then
        self:_CloseHoverTips()
        self.id = ""
        self:SetSelected(false)
        if clickableEvenEmpty then
            self.view.button.enabled = true
            self.view.button.onClick:AddListener(function()
                onClick(itemBundle)
            end)
        elseif DeviceInfo.usingController then
            self.view.button.enabled = true
        else
            self.view.button.enabled = false
        end
        if isLimited then
            data = Tables.itemTable[limitId]
            self.view.name.text = data.name
            if self.view.nameScrollText then
                self.view.nameScrollText:ForceUpdate()
            end
            self.view.count.gameObject:SetActive(false)
            self:SetIconTransparent(UIConst.ITEM_MISSING_TRANSPARENCY)
        end
        self:_UpdateIcon(data)
        self.view.content.gameObject:SetActive(isLimited)
        if self.config.USE_EMPTY_BG then
            self.view.emptyBG.gameObject:SetActive(true)
            self.view.normalBG.gameObject:SetActive(false)
        end
        self.m_showCount = false
        self.count = 0
        return
    end
    if self.view.config.SHOW_ITEM_TIPS_ON_R3 then
        self:AddHoverBinding("show_item_tips", function()
            self:ShowTips()
        end)
    end
    self.view.content.gameObject:SetActive(true)
    if self.config.USE_EMPTY_BG then
        self.view.emptyBG.gameObject:SetActive(false)
        self.view.normalBG.gameObject:SetActive(true)
    end
    if self.id ~= itemBundle.id then
        self.id = itemBundle.id
        self:SetSelected(false)
        self:_CloseHoverTips()
    end
    if itemBundle.instId and itemBundle.instId > 0 then
        if self.instId ~= itemBundle.instId then
            self.instId = itemBundle.instId
            self:SetSelected(false)
        end
    else
        if self.instId then
            self.instId = nil
            self:SetSelected(false)
        end
    end
    data = Tables.itemTable:GetValue(itemBundle.id)
    local typeData = Tables.itemTypeTable[data.type:ToInt()]
    self.m_showCount = typeData.showCount or self.view.config.FORCE_SHOW_COUNT
    self.view.name.text = data.name
    if self.view.nameScrollText then
        self.view.nameScrollText:ForceUpdate()
    end
    self:UpdateCount(itemBundle.count, itemBundle.needCount, nil, nil, nil, nil, itemBundle.isInfinite)
    self:_UpdateIcon(data, itemBundle.instId)
    self:_UpdateInstData(itemBundle)
    self:_UpdateWeaponAddon(itemBundle)
    self:_UpdateEquipAddon(itemBundle)
    if onClick then
        self.view.button.enabled = true
        if onClick == true then
            self.view.button.onClick:AddListener(function()
                self:ShowTips()
            end)
            self.view.button.clickHintTextId = "virtual_mouse_hint_item_tips"
        else
            self.view.button.onClick:AddListener(function()
                onClick(itemBundle)
            end)
        end
    else
        self.view.button.enabled = false
    end
    self.view.lockNode:InitItemLock(self.id, self.instId)
    self.view.button.onHoverChange:RemoveAllListeners()
    if self.view.config.SHOW_HOVER_TIP and not isEmpty then
        self.view.button.onHoverChange:AddListener(function(isHover)
            if isHover and not self.m_isSelected then
                Notify(MessageConst.SHOW_COMMON_HOVER_TIP, { itemId = itemBundle.id, delay = self.view.config.HOVER_TIP_DELAY, })
                self.m_showingHover = true
            else
                self:_CloseHoverTips()
            end
        end)
    end
end
Item._OnDestroy = HL.Override() << function(self)
    self:_CloseHoverTips()
end
Item._UpdateBg = HL.Method(HL.Opt(HL.Any)) << function(self, itemBundle)
    local bgColor
    if not itemBundle or string.isEmpty(itemBundle.id) then
        bgColor = Color.white
    else
        local data = Tables.itemTable[itemBundle.id]
        local typeData = Tables.itemTypeTable[data.type:ToInt()]
        if typeData.bgType == GEnums.ItemBgType.Normal then
            bgColor = Color.white
        elseif typeData.bgType == GEnums.ItemBgType.Black then
            bgColor = UIUtils.getColorByString(UIConst.ITEM_BG_TYPE_COLORS[typeData.bgType])
        end
    end
    bgColor.a = self.view.normalBG.color.a
    self.view.normalBG.color = bgColor
    bgColor.a = self.view.decoBG.color.a
    self.view.decoBG.color = bgColor
end
Item.AddHoverBinding = HL.Method(HL.String, HL.Function).Return(HL.Number) << function(self, actionId, action)
    return InputManagerInst:CreateBindingByActionId(actionId, action, self.view.button.hoverBindingGroupId)
end
Item._UpdateIcon = HL.Method(HL.Opt(HL.Any, HL.Number)) << function(self, data, instId)
    if not data then
        self.view.simpleStateController:SetState(self.view.config.FORCE_NO_RARITY and "NoRarity" or "Normal")
        return
    end
    self.view.icon:InitItemIcon(data.id, self.view.config.USE_BIG_ICON, instId)
    if self.view.compositeIconBG then
        self.view.compositeIconBG.gameObject:SetActive(not self.view.icon.showRarity)
    end
    local showRarity = self.view.icon.showRarity and not self.view.config.FORCE_NO_RARITY
    if showRarity then
        local isMaxRarity = data.rarity == UIConst.ITEM_MAX_RARITY
        self.view.simpleStateController:SetState(isMaxRarity and "6Star" or "Normal")
        if self.view.rarityLight then
            local rarityColor = UIUtils.getItemRarityColor(data.rarity)
            self.view.rarityLine.color = rarityColor
            if not isMaxRarity then
                self.view.rarityLight.color = rarityColor
            end
        end
    else
        self.view.simpleStateController:SetState("NoRarity")
    end
    local fullBottleSuccess, fullBottleData = Tables.fullBottleTable:TryGetValue(data.id)
    if fullBottleSuccess then
        local liquidSuccess, liquidData = Tables.itemTable:TryGetValue(fullBottleData.liquidId)
        if liquidSuccess then
            self.view.liquidIcon.gameObject:SetActive(true)
            self.view.liquidIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, liquidData.iconId)
        else
            self.view.liquidIcon.gameObject:SetActive(false)
        end
    else
        self.view.liquidIcon.gameObject:SetActive(false)
    end
end
Item._UpdateWeaponAddon = HL.Method(HL.Opt(HL.Any)) << function(self, data)
    local itemCfg = Tables.itemTable:GetValue(data.id)
    local itemType = itemCfg.type
    local isWeapon = itemType == GEnums.ItemType.Weapon
    if isWeapon then
        self.view.deco1.gameObject:SetActive(false)
    else
        if self.m_needShowDeco1 then
            self.view.deco1.gameObject:SetActive(true)
        end
    end
    self.view.potentialStar.gameObject:SetActive(not data.forceHidePotentialStar and isWeapon)
    self.view.gemEquipped.gameObject:SetActive(isWeapon)
    if not isWeapon then
        return
    end
    local weaponInstData = CharInfoUtils.getWeaponByInstId(data.instId)
    self.view.potentialStar:InitWeaponPotentialStar(weaponInstData and weaponInstData.refineLv or 0)
    self.view.gemEquipped.gameObject:SetActive(weaponInstData and weaponInstData.attachedGemInstId > 0)
end
Item._UpdateEquipAddon = HL.Method(HL.Opt(HL.Any)) << function(self, data)
    local itemCfg = Tables.itemTable:GetValue(data.id)
    local itemType = itemCfg.type
    local isEquip = itemType == GEnums.ItemType.Equip
    if not isEquip then
        return
    end
    self.view.levelNode.gameObject:SetActive(true)
    local equipCfg = Tables.equipTable:GetValue(data.id)
    self.view.lvNumTxt.text = equipCfg.minWearLv
end
Item.SetIconTransparent = HL.Method(HL.Number) << function(self, a)
    self.view.icon:SetAlpha(a)
end
Item.SetExtraInfo = HL.Method(HL.Table) << function(self, extraInfo)
    self.extraInfo = extraInfo
end
Item.ShowTips = HL.Method(HL.Opt(HL.Table, HL.Function)) << function(self, posInfo, onClose)
    if self.showingTips then
        Notify(MessageConst.HIDE_ITEM_TIPS)
        self:_OnTipsClosed(onClose)
        return
    end
    self:SetSelected(true)
    self.showingTips = true
    posInfo = posInfo or self.extraInfo
    Notify(MessageConst.SHOW_ITEM_TIPS, {
        transform = posInfo.tipsPosTransform or self.transform,
        posType = posInfo.tipsPosType,
        safeArea = posInfo.safeArea,
        padding = posInfo.padding,
        isSideTips = posInfo.isSideTips,
        moveVirtualMouse = posInfo.moveVirtualMouse,
        notPenetrate = self.config.NOT_PENETRATE_ITEM_TIPS_PANEL,
        hideItemObtainWays = self.hideItemObtainWays,
        hideBottomInfo = self.hideBottomInfo,
        prefixDesc = self.prefixDesc,
        itemId = self.id,
        itemCount = self.count,
        instId = self.instId,
        slotIndex = self.slotIndex,
        fromDepot = self.fromDepot,
        canPlace = self.canPlace,
        canSplit = self.canSplit,
        canUse = self.canUse,
        canClear = self.canClear,
        onClose = function()
            self:_OnTipsClosed(onClose)
        end
    })
end
Item._OnTipsClosed = HL.Method(HL.Opt(HL.Function)) << function(self, onClose)
    if not self.showingTips then
        return
    end
    if NotNull(self.view.gameObject) then
        self:SetSelected(false)
        self.showingTips = false
    end
    if onClose then
        onClose()
    end
end
Item.UpdateCountSimple = HL.Method(HL.Opt(HL.Number, HL.Boolean)) << function(self, count, isLack)
    self:UpdateCount(count, nil, false, false, nil, isLack, self.m_isInfinite)
end
Item.UpdateCountWithColor = HL.Method(HL.Number, HL.String) << function(self, count, colorFormatter)
    if not self.m_showCount then
        self.view.count.gameObject:SetActive(false)
        return
    end
    self.count = count
    self.view.count.text = string.format(colorFormatter, UIUtils.getNumString(count))
    if count > 0 then
        self:SetIconTransparent(UIConst.ITEM_EXIST_TRANSPARENCY)
    else
        self:SetIconTransparent(UIConst.ITEM_MISSING_TRANSPARENCY)
    end
    self.view.count.gameObject:SetActive(true)
end
Item.UpdateCount = HL.Method(HL.Opt(HL.Number, HL.Number, HL.Boolean, HL.Boolean, HL.String, HL.Boolean, HL.Boolean)) << function(self, count, needCount, keepColor, needCountFirst, formatter, isLack, isInfinite)
    if not self.m_showCount then
        self.view.count.gameObject:SetActive(false)
        return
    end
    if count then
        self.count = count
        isInfinite = isInfinite or self.m_isInfinite
        local countText = isInfinite and Language.LUA_ITEM_INFINITE_COUNT or UIUtils.getNumString(count)
        if not needCount then
            self.view.count.text = UIUtils.setCountColor(countText, isLack)
            self.view.count.gameObject:SetActive(true)
            if count > 0 then
                self:SetIconTransparent(UIConst.ITEM_EXIST_TRANSPARENCY)
            else
                self:SetIconTransparent(UIConst.ITEM_MISSING_TRANSPARENCY)
            end
        else
            self.view.count.gameObject:SetActive(true)
            self:SetIconTransparent(UIConst.ITEM_EXIST_TRANSPARENCY)
            local text
            formatter = formatter or "%s/%s"
            if needCountFirst then
                text = string.format(formatter, UIUtils.getNumString(needCount), countText)
            else
                text = string.format(formatter, countText, UIUtils.getNumString(needCount))
            end
            if not keepColor then
                self.view.count.text = UIUtils.setCountColor(text, count < needCount)
            else
                self.view.count.text = text
            end
        end
    else
        self.count = 0
        self:SetIconTransparent(UIConst.ITEM_EXIST_TRANSPARENCY)
        self.view.count.gameObject:SetActive(false)
    end
end
Item.SetSelected = HL.Method(HL.Opt(HL.Boolean, HL.Boolean)) << function(self, isSelected, forceUpdate)
    isSelected = isSelected == true
    if not forceUpdate and self.m_isSelected == isSelected then
        return
    end
    self.m_isSelected = isSelected == true
    self:_CloseHoverTips()
    self.view.selectedBG.gameObject:SetActive(isSelected)
    self.view.selectedNode.gameObject:SetActive(isSelected)
end
Item.OpenLongPressTips = HL.Method() << function(self)
    self.view.button.onLongPress:AddListener(function()
        self:ShowTips()
    end)
    self.view.button.longPressHintTextId = "virtual_mouse_hint_item_tips"
end
Item.UpdateRedDot = HL.Method() << function(self)
    if string.isEmpty(self.id) then
        self.redDot:Stop()
    else
        if self.instId then
            self.redDot:InitRedDot("InstItem", self)
        else
            self.redDot:InitRedDot("NormalItem", self.id)
        end
    end
end
Item.Read = HL.Method() << function(self)
    if not self.redDot.curIsActive then
        return
    end
    if self.instId then
        GameInstance.player.inventory:ReadNewItem(self.id, self.instId)
    else
        GameInstance.player.inventory:ReadNewItem(self.id)
    end
end
Item._UpdateInstData = HL.Method(HL.Opt(HL.Any)) << function(self, itemBundle)
    local hasInstId = itemBundle and itemBundle.instId and itemBundle.instId > 0
    if not hasInstId then
        return
    end
    local instId = itemBundle.instId
    local weaponInst = CharInfoUtils.getWeaponByInstId(instId)
    if weaponInst then
        self.view.levelNode.gameObject:SetActive(true)
        self.view.lvNumTxt.text = weaponInst.weaponLv
        return
    end
    local equipInst = CharInfoUtils.getEquipByInstId(instId)
    if equipInst then
    end
end
Item.ShowPickUpLogo = HL.Method(HL.Boolean) << function(self, isShow)
    if self.view.pickUpNode ~= nil then
        if isShow then
            local isPickUp, _ = Tables.useItemTable:TryGetValue(self.id)
            self.view.pickUpNode.gameObject:SetActive(isPickUp)
        else
            self.view.pickUpNode.gameObject:SetActive(isShow)
        end
    end
end
Item.SetAsNaviTarget = HL.Method() << function(self)
    InputManagerInst.controllerNaviManager:SetTarget(self.view.button)
end
Item.m_actionMenuBindingId = HL.Field(HL.Number) << -1
Item.actionMenuArgs = HL.Field(HL.Table)
Item.customChangeActionMenuFunc = HL.Field(HL.Function)
Item.InitActionMenu = HL.Method() << function(self)
    if self.m_actionMenuBindingId > 0 then
        return
    end
    self.m_actionMenuBindingId = InputManagerInst:CreateBindingByActionId("item_open_action_menu", function()
        self:ShowActionMenu()
    end, self.view.button.hoverBindingGroupId)
end
Item.ToggleActionMenu = HL.Method(HL.Boolean) << function(self, active)
    if self.m_actionMenuBindingId <= 0 then
        return
    end
    InputManagerInst:ToggleBinding(self.m_actionMenuBindingId, active)
end
Item.ShowActionMenu = HL.Method() << function(self)
    self:SetSelected(true)
    Notify(MessageConst.SHOW_COMMON_ACTION_MENU, {
        transform = self.transform,
        actions = self:_GenActionMenuInfos(),
        onClose = function()
            self:SetSelected(false)
        end
    })
end
Item._GenActionMenuInfos = HL.Method().Return(HL.Table) << function(self)
    local id = self.id
    local count = self.count
    local args = self.actionMenuArgs
    local isItemBag = args.source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.ItemBag
    local isFacDepot = args.source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.FactoryDepot
    local isRepository = args.source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.Repository
    local inventory = GameInstance.player.inventory
    local core = GameInstance.player.remoteFactory.core
    local scope = Utils.getCurrentScope()
    local chapterId = Utils.getCurrentChapterId()
    local data = Tables.itemTable:GetValue(id)
    local isSafeArea = Utils.isInSafeZone()
    local isBuilding, buildingId = FactoryUtils.isBuilding(id)
    local actionMenuInfos = {}
    if args.machineCacheArea and (isItemBag or isFacDepot) then
        table.insert(actionMenuInfos, {
            text = Language.LUA_ITEM_ACTION_MOVE_TO_MACHINE,
            action = function()
                args.machineCacheArea:DropItemToArea({ source = args.source, itemId = id, csIndex = self.slotIndex, type = data.type, })
            end
        })
    end
    if (isFacDepot and isSafeArea) or isRepository then
        table.insert(actionMenuInfos, {
            text = Language.LUA_ITEM_ACTION_MOVE_TO_ITEM_BAG,
            action = function()
                local itemBag = inventory.itemBag[scope]
                local toIndex = itemBag:GetFirstValidSlotIndex(id)
                if toIndex < 0 then
                    Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_BAG_NO_EMPTY_SLOT)
                    return
                end
                if isFacDepot then
                    inventory:FactoryDepotMoveToItemBag(scope, chapterId, id, args.moveCount or count, toIndex)
                elseif isRepository then
                    core:Message_OpMoveItemCacheToBag(chapterId, args.componentId, toIndex, args.cacheGridIndex)
                end
            end
        })
        if isFacDepot then
            table.insert(actionMenuInfos, {
                text = Language.LUA_ITEM_ACTION_MOVE_SOME_TO_ITEM_BAG,
                action = function()
                    UIManager:Open(PanelId.CommonItemNumSelect, {
                        id = id,
                        count = count,
                        onComplete = function(moveCount)
                            if not moveCount then
                                return
                            end
                            local itemBag = inventory.itemBag[scope]
                            local toIndex = itemBag:GetFirstValidSlotIndex(id)
                            if toIndex < 0 then
                                Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_BAG_NO_EMPTY_SLOT)
                                return
                            end
                            inventory:FactoryDepotMoveToItemBag(scope, chapterId, id, moveCount or count, toIndex)
                        end
                    })
                end
            })
        end
    end
    if isSafeArea and (isItemBag or isRepository) then
        table.insert(actionMenuInfos, {
            text = Language.LUA_ITEM_ACTION_MOVE_TO_DEPOT,
            action = function()
                if isItemBag then
                    inventory:ItemBagMoveToFactoryDepot(scope, chapterId, self.slotIndex)
                elseif isRepository then
                    core:Message_OpMoveItemCacheToDepot(chapterId, args.componentId, args.cacheGridIndex)
                end
            end
        })
    end
    if self.canUse then
        local isUseItem, _ = Tables.useItemTable:TryGetValue(id)
        if isUseItem and Utils.isSystemUnlocked(GEnums.UnlockSystemType.ItemUse) then
            table.insert(actionMenuInfos, {
                text = Language.LUA_ITEM_ACTION_USE,
                action = function()
                    UIUtils.useItemOnTip(id)
                end
            })
        end
    end
    if isBuilding and self.canPlace then
        table.insert(actionMenuInfos, {
            text = Language.LUA_ITEM_ACTION_PLACE,
            action = function()
                Notify(MessageConst.FAC_ENTER_BUILDING_MODE, { itemId = id, slotIndex = self.slotIndex, fromDepot = isFacDepot, })
            end
        })
    end
    table.insert(actionMenuInfos, {
        text = Language.LUA_ITEM_ACTION_SHOW_TIPS,
        action = function()
            self:ShowTips()
        end
    })
    if isBuilding and self.canSetQuickBar then
        if UIManager:IsShow(PanelId.FacQuickBar) then
            table.insert(actionMenuInfos, {
                text = Language.LUA_ITEM_ACTION_MOVE_TO_FAC_QUICK_BAR,
                action = function()
                    Notify(MessageConst.START_SET_BUILDING_ON_FAC_QUICK_BAR, { itemId = id, })
                end
            })
        end
    end
    if self.canSplit and count > 1 then
        table.insert(actionMenuInfos, {
            text = Language.LUA_ITEM_ACTION_SPLIT,
            action = function()
                UIUtils.splitItem(self.slotIndex)
            end
        })
    end
    if self.canDestroy and inventory:CanDestroyItem(scope, id) then
        if isItemBag then
            table.insert(actionMenuInfos, {
                text = Language.LUA_ITEM_ACTION_DROP,
                action = function()
                    inventory:AbandonItemInItemBag(scope, { self.slotIndex })
                end
            })
        end
        if isFacDepot then
            table.insert(actionMenuInfos, {
                text = Language.LUA_ITEM_ACTION_DESTROY,
                action = function()
                    local items = { { id = id, count = count } }
                    Notify(MessageConst.SHOW_POP_UP, {
                        content = Language.LUA_DESTROY_ITEM_CONFIRM_TEXT,
                        warningContent = Language.LUA_DESTROY_ITEM_CONFIRM_WARNING_TEXT,
                        items = items,
                        onConfirm = function()
                            inventory:DestroyInFactoryDepot(scope, chapterId, { [id] = count })
                        end,
                    })
                end
            })
        end
    end
    if args.extraButtons then
        table.insert(actionMenuInfos, { text = Language.LUA_ITEM_ACTION_EXTRA_TITLE, })
        for _, btn in ipairs(args.extraButtons) do
            if btn.gameObject.activeInHierarchy then
                table.insert(actionMenuInfos, {
                    text = btn.hintText,
                    action = function()
                        btn.onClick:Invoke()
                    end
                })
            end
        end
    end
    if self.customChangeActionMenuFunc then
        self.customChangeActionMenuFunc(actionMenuInfos)
    end
    return actionMenuInfos
end
HL.Commit(Item)
return Item