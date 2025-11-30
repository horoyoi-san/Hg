local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ItemTips
ItemTipsCtrl = HL.Class('ItemTipsCtrl', uiCtrl.UICtrl)
local LIQUID_EMPTY_CAPACITY_TEXT_ID = "LUA_ITEM_TIPS_LIQUID_INFO_EMPTY_CAPACITY"
local LIQUID_FULL_CAPACITY_TEXT_ID = "LUA_ITEM_TIPS_LIQUID_INFO_FULL_CAPACITY"
local LIQUID_EMPTY_NAME_TEXT_ID = "LUA_ITEM_TIPS_LIQUID_INFO_EMPTY_NAME"
local OBTAIN_WAYS_NORMAL_TITLE_TEXT_ID = "ui_common_obtain_method"
local OBTAIN_WAYS_LIQUID_TITLE_TEXT_ID = "ui_common_tips_liquid_obtain_ways"
local PRODUCT_NORMAL_TITLE_TEXT_ID = "ui_common_tips_main_product"
local PRODUCT_LIQUID_TITLE_TEXT_ID = "ui_common_tips_liquid_main_product"
ItemTipsCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.HIDE_ITEM_TIPS] = 'HideItemTips', [MessageConst.TOGGLE_ITEM_TIPS_AUTO_CLOSE] = 'ToggleItemTipsAutoClose', [MessageConst.ON_ITEM_COUNT_CHANGED] = 'OnItemCountChanged', }
ItemTipsCtrl.m_itemId = HL.Field(HL.String) << ""
ItemTipsCtrl.m_itemCount = HL.Field(HL.Number) << -1
ItemTipsCtrl.m_instId = HL.Field(HL.Number) << 0
ItemTipsCtrl.m_data = HL.Field(HL.Userdata)
ItemTipsCtrl.m_autoCloseTime = HL.Field(HL.Number) << -1
ItemTipsCtrl.m_stopCheckClose = HL.Field(HL.Boolean) << false
ItemTipsCtrl.m_args = HL.Field(HL.Table)
ItemTipsCtrl.m_slotIndex = HL.Field(HL.Number) << -1
ItemTipsCtrl.m_slotCount = HL.Field(HL.Number) << -1
ItemTipsCtrl.m_productCellCache = HL.Field(HL.Forward("UIListCache"))
ItemTipsCtrl.m_tagCellCache = HL.Field(HL.Forward("UIListCache"))
ItemTipsCtrl.m_isShowBlueprintProduct = HL.Field(HL.Boolean) << true
ItemTipsCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.maskBtn.onClick:AddListener(function()
        self:_CloseTips(false)
    end)
    self.view.placeButton.onClick:AddListener(function()
        self:_StartPlace()
    end)
    self.view.splitButton.onClick:AddListener(function()
        self:_ShowSplit()
    end)
    self.view.clearButton.onClick:AddListener(function()
        self:_ShowClearBottle()
    end)
    self.view.jumpButton.onClick:AddListener(function()
        self:_TryJump()
    end)
    self.view.useButton.onClick:AddListener(function()
        self:_UseItem()
    end)
    self.view.wikiBtn.onClick:AddListener(function()
        self:_ShowWiki()
    end)
    self.view.cantPenetrateBtn.onClick:AddListener(function()
        self:_CloseTips(false)
    end)
    self.view.detailScroll.onValueChanged:AddListener(function()
        self:_OnDetailScroll()
    end)
    self:BindInputPlayerAction("item_tips_close", function()
        self:_CloseTips(false)
    end)
    self.m_extraSafeAreas = {}
    self.m_detailContentTopPadding = self.view.detailContentVerticalLayoutGroup.padding.top
    self.m_productCellCache = UIUtils.genCellCache(self.view.productNode.itemCell)
    self.m_tagCellCache = UIUtils.genCellCache(self.view.tagInfoNode.tagCell)
    if BEYOND_DEBUG then
        self.view.debugIDButton.gameObject:SetActive(true)
        self.view.debugIDButton.onClick:AddListener(function()
            Unity.GUIUtility.systemCopyBuffer = self.m_itemId
            Notify(MessageConst.SHOW_TOAST, string.format("DEBUG: 已复制ID %s", self.m_itemId))
        end)
        self.view.countNode.debugAddButton.gameObject:SetActive(true)
        self.view.countNode.debugAddButton.onClick:AddListener(function()
            local itemData = Tables.itemTable[self.m_itemId]
            local isMoney = GameInstance.player.inventory:IsMoneyType(itemData.type)
            if isMoney then
                local msg = CS.Proto.CS_GM_COMMAND()
                msg.Command = "AddMoney " .. self.m_itemId .. " 1000000"
                CS.Beyond.Network.NetBus.instance.defaultSender:Send(msg)
                Notify(MessageConst.SHOW_TOAST, string.format("DEBUG: 支付宝到账 一百万%s", self.m_data.name))
            else
                local msg = CS.Proto.CS_GM_COMMAND()
                msg.Command = "AddItemToItemBagSystem " .. self.m_itemId .. " 50"
                CS.Beyond.Network.NetBus.instance.defaultSender:Send(msg)
                Notify(MessageConst.SHOW_TOAST, string.format("DEBUG: 已添加道具 %s 50个", self.m_data.name))
            end
        end)
        self.view.countNode.debugAddButton.onLongPress:AddListener(function()
            local itemData = Tables.itemTable[self.m_itemId]
            local isMoney = GameInstance.player.inventory:IsMoneyType(itemData.type)
            if isMoney then
                local msg = CS.Proto.CS_GM_COMMAND()
                msg.Command = "AddMoney " .. self.m_itemId .. " 1"
                CS.Beyond.Network.NetBus.instance.defaultSender:Send(msg)
                Notify(MessageConst.SHOW_TOAST, string.format("DEBUG: 支付宝到账 1 %s", self.m_data.name))
            else
                local msg = CS.Proto.CS_GM_COMMAND()
                msg.Command = "AddItemToItemBagSystem " .. self.m_itemId .. " 1"
                CS.Beyond.Network.NetBus.instance.defaultSender:Send(msg)
                Notify(MessageConst.SHOW_TOAST, string.format("DEBUG: 已添加道具 %s 1", self.m_data.name))
            end
        end)
    else
        self.view.debugIDButton.gameObject:SetActive(false)
        self.view.countNode.debugAddButton.gameObject:SetActive(false)
    end
end
ItemTipsCtrl.ShowItemTips = HL.StaticMethod(HL.Table) << function(args)
    local isShowing = UIManager:IsShow(PANEL_ID)
    local self = UIManager:AutoOpen(PANEL_ID)
    if isShowing then
        self:_ClearArgs()
        if not self:IsPlayingAnimationOut() then
            self.m_cachedArgs = args
            self:PlayAnimationOutWithCallback(function()
                self:_ShowTips(self.m_cachedArgs)
            end)
        else
            if self.m_cachedArgs then
                if self.m_cachedArgs.onClose then
                    self.m_cachedArgs.onClose()
                end
            end
            self.m_cachedArgs = args
        end
    else
        self:_ShowTips(args)
    end
end
ItemTipsCtrl.m_cachedArgs = HL.Field(HL.Table)
ItemTipsCtrl.HideItemTips = HL.Method() << function(self)
    self:_CloseTips()
end
ItemTipsCtrl.m_autoClose = HL.Field(HL.Boolean) << true
ItemTipsCtrl.ToggleItemTipsAutoClose = HL.Method(HL.Any) << function(self, autoClose)
    logger.info("ToggleItemTipsAutoClose", inspect(autoClose))
    if type(autoClose) == "table" then
        self.m_autoClose = unpack(autoClose)
    else
        self.m_autoClose = autoClose
    end
end
ItemTipsCtrl.m_firstShow = HL.Field(HL.Boolean) << true
ItemTipsCtrl._ShowTips = HL.Method(HL.Table) << function(self, args)
    self:_ClearArgs()
    self.m_args = args
    self.m_cachedArgs = nil
    if args.safeArea then
        self:_AddItemTipsSafeArea(args.safeArea)
    end
    self.m_autoCloseTime = -1
    local itemId = args.itemId
    local instId = args.instId or 0
    self.m_itemCount = args.itemCount or -1
    if args.slotIndex then
        self.m_slotIndex = args.slotIndex
        local itemBundle = GameInstance.player.inventory.itemBag:GetOrFallback(Utils.getCurrentScope()).slots[args.slotIndex]
        itemId = itemBundle.id
        instId = itemBundle.instId
        self.m_slotCount = itemBundle.count
    else
        self.m_slotIndex = -1
        self.m_slotCount = -1
    end
    self:_RefreshContent(itemId, instId)
    if not string.isEmpty(args.prefixDesc) then
        self.view.prefixDescInfo.gameObject:SetActiveIfNecessary(true)
        self.view.prefixDescTxt.gameObject:SetActiveIfNecessary(true)
        self.view.prefixDescTxt.text = args.prefixDesc
    else
        self.view.prefixDescInfo.gameObject:SetActiveIfNecessary(false)
        self.view.prefixDescTxt.gameObject:SetActiveIfNecessary(false)
    end
    if args.autoClose ~= nil then
        self:ToggleItemTipsAutoClose(args.autoClose)
    else
        self:ToggleItemTipsAutoClose(true)
    end
    UIManager:SetTopOrder(PANEL_ID)
    local isFullScreen = self:_IsFullScreen()
    self.view.controllerHintPlaceholder.gameObject:SetActive(isFullScreen)
    self:ChangeCurPanelBlockSetting(isFullScreen)
    local State = CS.Beyond.UI.CustomUIStyle.OverrideValidState
    self.view.maskBtnCustomUIStyle.overrideValidState = self.m_args.isSideTips and State.ForceNotValid or State.None
    local curState = self.m_args.isSideTips and State.ForceValid or State.None
    self.view.bottomButtonsCustomUIStyle.overrideValidState = curState
    self.view.cantPenetrateBtn.gameObject:SetActive(args.notPenetrate == true)
    self:PlayAnimationIn()
    if args.moveVirtualMouse then
        InputManagerInst:MoveVirtualMouseTo(self.view.content.transform, self.uiCamera)
    end
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
ItemTipsCtrl._IsFullScreen = HL.Method().Return(HL.Boolean) << function(self)
    return InputManagerInst.usingController and not self.m_args.isSideTips
end
ItemTipsCtrl._ClearArgs = HL.Method() << function(self)
    if self.m_args then
        if self.m_args.onClose then
            self.m_args.onClose()
            self.m_args.onClose = nil
        end
        if self.m_args.safeArea then
            self:_RemoveItemTipsSafeArea(self.m_args.safeArea)
        end
    end
    self.m_args = nil
    self.m_itemId = ""
    self.m_instId = 0
    self.m_data = nil
    self.m_slotIndex = -1
    self.m_slotCount = -1
end
ItemTipsCtrl.OnShow = HL.Override() << function(self)
    self:_RegisterCallback()
end
ItemTipsCtrl.OnClose = HL.Override() << function(self)
    self:_ClearArgs()
    self:_ClearRegister()
end
ItemTipsCtrl.OnHide = HL.Override() << function(self)
    self:_ClearArgs()
    self:_ClearRegister()
end
ItemTipsCtrl._Update = HL.Method() << function(self)
    self:_CheckShouldAutoClose()
end
ItemTipsCtrl.m_craftCellCache = HL.Field(HL.Forward("UIListCache"))
ItemTipsCtrl._RefreshContent = HL.Method(HL.String, HL.Number) << function(self, itemId, instId)
    local data = Tables.itemTable:GetValue(itemId)
    local itemType = data.type
    local maxBackpackStackCount = data.maxBackpackStackCount
    self.m_itemId = itemId
    self.m_instId = instId
    self.m_data = data
    UIUtils.displayItemBasicInfos(self.view, self.loader, itemId, instId)
    self.view.icon:InitItemIcon(itemId, true, instId)
    self.view.iconImageBlur:OnChangeSprite()
    self.view.itemObtainWays.gameObject:SetActive(true)
    self.view.itemObtainWays:InitItemObtainWays(itemId, instId)
    self.view.stateCtrl:SetState("default")
    self.view.itemDescNode:InitItemDescNode(itemId)
    self:_RefreshWeaponNode(itemId, instId, itemType)
    self:_RefreshEquipNode(itemId, instId, itemType)
    self:_RefreshGemNode(itemId, instId, itemType)
    self:_RefreshCountNode(itemId, itemType, data.showAllDepotCount)
    self:_RefreshTagInfoNode(itemId, itemType)
    self:_RefreshProductNode(itemId, itemType)
    self:_RefreshEmptyNode(itemId, itemType)
    self:_RefreshPickUpNode(itemId)
    self:_RefreshLiquidInfoNode(itemId, self.m_itemCount)
    self.view.wikiBtn.gameObject:SetActive(self:_GetNeedShowWikiBtn())
    local isExp = itemType == GEnums.ItemType.CardExp
    local jumpText = ""
    if isExp then
        jumpText = Language.LUA_EXP_CARD_JUMP
    elseif isEquip then
        jumpText = Language.LUA_EQUIP_JUMP
    end
    if not string.isEmpty(jumpText) then
        self.view.jumpButton.text = jumpText
    end
    local hasBottomButton
    if DeviceInfo.usingController then
        hasBottomButton = false
    else
        local isUseItem, _ = Tables.useItemTable:TryGetValue(itemId)
        local count = Utils.getItemCount(itemId)
        local canUse = isUseItem and self.m_args.canUse and Utils.isSystemUnlocked(GEnums.UnlockSystemType.ItemUse) and count > 0 and not LuaSystemManager.facSystem.inTopView
        self.view.useButton.gameObject:SetActiveIfNecessary(canUse)
        local isBuilding, buildingId = FactoryUtils.isBuilding(itemId)
        local canPlace = self.m_args.canPlace and isBuilding and FactoryUtils.canPlaceBuildingOnCurRegion(buildingId)
        local canSplit = self.m_args.canSplit and maxBackpackStackCount > 1 and self.m_slotCount > 1
        local canJump = self:_CheckIfCanJump(itemId, itemType, instId)
        local canClear = self.m_args.canClear and Tables.fullBottleTable:ContainsKey(itemId) and self.m_itemCount > 0
        self.view.placeButton.gameObject:SetActive(canPlace)
        self.view.splitButton.gameObject:SetActive(canSplit)
        self.view.jumpButton.gameObject:SetActive(canJump)
        self.view.dropButton.gameObject:SetActive(false)
        self.view.clearButton.gameObject:SetActive(canClear)
        hasBottomButton = canPlace or canSplit or canUse or canJump or canClear
    end
    self.view.bottomButtons.gameObject:SetActive(hasBottomButton)
    self.view.detailScroll.normalizedPosition = Vector2(0, 1)
    self:_OnDetailScroll()
    local extraHeight = self.view.basicInfoNode.rect.size.y
    if hasBottomButton then
        extraHeight = extraHeight + self.view.bottomButtons.transform.rect.size.y
    end
    self.view.detailContentLayoutElement.enabled = false
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.detailContent)
    local detailContentHeight = self.view.detailContent.rect.size.y
    local detailShowHeight = lume.clamp(detailContentHeight, self.view.config.MIN_CONTENT_HEIGHT - extraHeight, self.view.config.MAX_CONTENT_HEIGHT - extraHeight)
    self.view.detailScrollLayoutElement.preferredHeight = detailShowHeight
    local canScroll = detailContentHeight > detailShowHeight
    if canScroll then
        self.view.detailContentLayoutElement.minHeight = detailShowHeight + self.m_detailContentTopPadding
        self.view.detailContentLayoutElement.enabled = true
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.detailContent)
    end
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.content)
    local padding = self.m_args.padding
    if not padding then
        padding = { bottom = 50 + (self:_IsFullScreen() and 50 or 0), }
    end
    local notchSize = CS.Beyond.DeviceInfoManager.NotchPaddingInCanvas(self.view.transform).x
    padding.left = (padding.left or 0) + notchSize
    padding.right = (padding.right or 0) + notchSize
    UIUtils.updateTipsPosition(self.view.content, self.m_args.transform, self.view.rectTransform, self.uiCamera, self.m_args.posType, padding)
    self.view.lockToggle:InitLockToggle(itemId, instId)
end
ItemTipsCtrl._RefreshPickUpNode = HL.Method(HL.String) << function(self, itemId)
    local isPickUp, _ = Tables.useItemTable:TryGetValue(itemId)
    self.view.pickUpNode.gameObject:SetActive(isPickUp)
end
ItemTipsCtrl._RefreshWeaponNode = HL.Method(HL.String, HL.Number, HL.Userdata) << function(self, itemId, instId, itemType)
    local isWeapon = itemType == GEnums.ItemType.Weapon
    if not isWeapon then
        return
    end
    self.view.stateCtrl:SetState("weapon")
    UIUtils.displayWeaponInfo(self.view, self.loader, itemId, instId)
end
ItemTipsCtrl._RefreshEquipNode = HL.Method(HL.String, HL.Number, HL.Userdata) << function(self, itemId, instId, itemType)
    local isEquip = itemType == GEnums.ItemType.Equip
    if not isEquip then
        return
    end
    self.view.stateCtrl:SetState("equip")
    UIUtils.displayEquipInfo(self.view, self.loader, itemId, instId)
end
ItemTipsCtrl._RefreshGemNode = HL.Method(HL.String, HL.Number, HL.Userdata) << function(self, itemId, instId, itemType)
    local isGem = itemType == GEnums.ItemType.WeaponGem
    if not isGem then
        return
    end
    self.view.stateCtrl:SetState("weaponGem")
    UIUtils.displayWeaponGemInfo(self.view, self.loader, itemId, instId)
end
ItemTipsCtrl._RefreshCountNode = HL.Method(HL.String, HL.Userdata, HL.Boolean) << function(self, itemId, itemType, showAllDepotCount)
    local typeData = Tables.itemTypeTable[itemType:ToInt()]
    local forceNoCount = typeData.showCountInTips == false
    self.view.countNode.gameObject:SetActive(not forceNoCount)
    self.view.countSpace.gameObject:SetActive(not forceNoCount)
    if forceNoCount then
        return
    end
    if Utils.isInBlackbox() and not UIManager:IsShow(PanelId.RewardsPopUpForBlackBox) then
        self.view.countNode.gameObject:SetActiveIfNecessary(false)
        self.view.countSpace.gameObject:SetActiveIfNecessary(false)
        return
    end
    local isPlaceInBag = GameInstance.player.inventory:IsPlaceInBag(itemType)
    local isMoney = not isPlaceInBag and GameInstance.player.inventory:IsMoneyType(itemType)
    local isAdventureExp = itemType == GEnums.ItemType.AdventureExp
    if not isMoney then
        if isPlaceInBag then
            local bagCount = Utils.getBagItemCount(itemId)
            self.view.countNode.bagCountText.text = bagCount
            if showAllDepotCount then
                self.view.countNode.allDepotCountText.text = Utils.getAllFacDepotItemCount(itemId)
            else
                self.view.countNode.depotCountText.text = Utils.getDepotItemCount(itemId)
            end
        else
            self.view.countNode.valuableCountText.text = Utils.getDepotItemCount(itemId)
        end
    else
        self.view.countNode.valuableCountText.text = Utils.getItemCount(itemId)
    end
    self.view.countNode.valuableInfoNode.gameObject:SetActiveIfNecessary(not isPlaceInBag and not isAdventureExp)
    self.view.countNode.depotInfoNode.gameObject:SetActiveIfNecessary(isPlaceInBag and not showAllDepotCount)
    self.view.countNode.allDepotInfoNode.gameObject:SetActiveIfNecessary(isPlaceInBag and showAllDepotCount)
    self.view.countNode.bagInfoNode.gameObject:SetActiveIfNecessary(isPlaceInBag)
    self.view.countNode.gameObject:SetActiveIfNecessary(true)
    self.view.countSpace.gameObject:SetActiveIfNecessary(true)
end
ItemTipsCtrl._RefreshProductNode = HL.Method(HL.String, HL.Userdata) << function(self, itemId, itemType)
    local productIds = self:_TryGetProductionItemList(itemId)
    if productIds then
        self.view.productNode.gameObject:SetActive(true)
        local count = #productIds
        local isShowMoreDeco = count > self.view.config.MAX_BLUEPRINT_PRODUCT_COUNT
        local showCount = lume.clamp(count, 0, self.view.config.MAX_BLUEPRINT_PRODUCT_COUNT)
        self.m_productCellCache:Refresh(showCount, function(cell, index)
            local productId = productIds[index]
            local itemData = Tables.itemTable:GetValue(productId)
            UIUtils.setItemSprite(cell.icon, productId, self)
            UIUtils.setItemRarityImage(cell.rarityLine, itemData.rarity)
            UIUtils.setItemRarityImage(cell.rarityLight, itemData.rarity)
        end)
        self.view.productNode.moreDeco.transform:SetAsLastSibling()
        self.view.productNode.moreDeco.gameObject:SetActive(isShowMoreDeco)
    else
        self.view.productNode.gameObject:SetActive(false)
    end
end
ItemTipsCtrl._RefreshEmptyNode = HL.Method(HL.String, HL.Userdata) << function(self, itemId, itemType)
    local isShowEmptyNode = self:_CheckIfShowEmptyNode(itemId, itemType)
    self.view.emptyNode.gameObject:SetActive(isShowEmptyNode)
end
ItemTipsCtrl._RefreshTagInfoNode = HL.Method(HL.String, HL.Userdata) << function(self, itemId, itemType)
    local isShowTagNode, tagList = self:_TryGetTagList(itemId, itemType)
    self.view.tagInfoNode.gameObject:SetActive(isShowTagNode)
    if isShowTagNode then
        local tagCount = tagList.Count
        self.m_tagCellCache:Refresh(math.min(tagCount, self.view.config.MAX_TAG_COUNT), function(cell, index)
            local tagId = tagList[CSIndex(index)]
            local tagData = Tables.factoryIngredientTagTable:GetValue(tagId)
            local isShowGreyBg = not itemType == GEnums.ItemType.NormalBuilding
            cell.whiteBG.gameObject:SetActive(not isShowGreyBg)
            cell.greyBG.gameObject:SetActive(isShowGreyBg)
            cell.text.text = tagData.tagLabel
            cell.gameObject.name = "Tag-" .. tagId
        end)
    end
end
ItemTipsCtrl._RefreshLiquidInfoNode = HL.Method(HL.String, HL.Number) << function(self, itemId, itemCount)
    local liquidInfoNode = self.view.liquidInfoNode
    liquidInfoNode.gameObject:SetActive(false)
    self.view.itemObtainWays.view.obtainTitle.text = Language[OBTAIN_WAYS_NORMAL_TITLE_TEXT_ID]
    self.view.productNode.title.text = Language[PRODUCT_NORMAL_TITLE_TEXT_ID]
    local isSystemUnlocked = Utils.isSystemUnlocked(GEnums.UnlockSystemType.GeneralAbilityFluidInteract)
    if not isSystemUnlocked then
        return
    end
    local isEmptyBottle = Tables.emptyBottleTable:ContainsKey(itemId)
    local isFullBottle = Tables.fullBottleTable:ContainsKey(itemId)
    if not isEmptyBottle and not isFullBottle then
        return
    end
    liquidInfoNode.emptyIcon.gameObject:SetActive(isEmptyBottle)
    liquidInfoNode.icon.gameObject:SetActive(isFullBottle)
    liquidInfoNode.emptyLine.gameObject:SetActive(isEmptyBottle)
    liquidInfoNode.rarityLine.gameObject:SetActive(isFullBottle)
    if isEmptyBottle then
        local emptyBottleData = Tables.emptyBottleTable[itemId]
        local capacity = emptyBottleData.liquidCapacity
        liquidInfoNode.capacityTxt.text = string.format(Language[LIQUID_EMPTY_CAPACITY_TEXT_ID], capacity)
        liquidInfoNode.nameTxt.text = Language[LIQUID_EMPTY_NAME_TEXT_ID]
    end
    if isFullBottle then
        local fullBottleData = Tables.fullBottleTable[itemId]
        local liquidItemId = fullBottleData.liquidId
        local liquidSuccess, liquidItemData = Tables.itemTable:TryGetValue(liquidItemId)
        if liquidSuccess then
            local liquidSprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, liquidItemData.iconId)
            if liquidSprite ~= nil then
                liquidInfoNode.icon.sprite = liquidSprite
            end
            liquidInfoNode.nameTxt.text = liquidItemData.name
            local rarityColor = UIUtils.getItemRarityColor(liquidItemData.rarity)
            liquidInfoNode.rarityLine.color = rarityColor
            self.view.itemObtainWays:InitItemObtainWays(liquidItemId)
            self:_RefreshProductNode(liquidItemId, liquidItemData.type)
        end
        local liquidCount = fullBottleData.liquidCapacity
        liquidInfoNode.capacityTxt.text = string.format(Language[LIQUID_FULL_CAPACITY_TEXT_ID], liquidCount)
        self.view.itemObtainWays.view.obtainTitle.text = Language[OBTAIN_WAYS_LIQUID_TITLE_TEXT_ID]
        self.view.productNode.title.text = Language[PRODUCT_LIQUID_TITLE_TEXT_ID]
    end
    liquidInfoNode.gameObject:SetActive(true)
end
ItemTipsCtrl._OnDetailContentSizeChanged = HL.Method() << function(self)
    self.view.detailContentLayoutElement.enabled = false
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.detailContent)
    local detailContentHeight = self.view.detailContent.rect.size.y
    local detailShowHeight = self.view.detailScrollLayoutElement.preferredHeight
    local canScroll = detailContentHeight > detailShowHeight
    if canScroll then
        self.view.detailContentLayoutElement.minHeight = detailShowHeight + self.m_detailContentTopPadding
        self.view.detailContentLayoutElement.enabled = true
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.detailContent)
    end
end
ItemTipsCtrl._UpdateCount = HL.Method() << function(self)
    self.view.countNode.depotCountText.text = Utils.getDepotItemCount(self.m_itemId)
    self.view.countNode.bagCountText.text = Utils.getBagItemCount(self.m_itemId)
end
ItemTipsCtrl._OnClickObtainCell = HL.Method() << function(self)
end
ItemTipsCtrl._CheckShouldAutoClose = HL.Method() << function(self)
    if self:_IsFullScreen() then
        return
    end
    if self.m_autoCloseTime > 0 then
        if Time.unscaledTime >= self.m_autoCloseTime then
            self:_CloseTips()
            return
        end
    end
    if self.m_autoClose then
        local hasCloseAction, isClick = self:_HasActionOnOtherArea()
        if hasCloseAction then
            if not isClick then
                self:_CloseTips()
            else
                local isClickUp = InputManager.GetMouseButtonUp(0)
                if isClickUp then
                    self.m_autoCloseTime = Time.unscaledTime
                else
                    if self.m_autoCloseTime <= 0 then
                        self.m_autoCloseTime = Time.unscaledTime + self.view.config.AUTO_CLOSE_DELAY
                    end
                end
            end
        end
    end
end
ItemTipsCtrl._HasActionOnOtherArea = HL.Method().Return(HL.Boolean, HL.Opt(HL.Boolean)) << function(self)
    if self.m_stopCheckClose then
        return false
    end
    local scrolling = math.abs(InputManager.mouseScrollDelta.y) > 0
    if (InputManager.anyKeyDown and not InputManagerInst.usingController) or scrolling then
        local isInputValidInSafeArea = false
        if InputManager.IsLeftMouseDown() then
            isInputValidInSafeArea = true
        elseif InputManager.GetMouseButton(1) then
            isInputValidInSafeArea = true
        elseif scrolling then
            isInputValidInSafeArea = true
        end
        if not isInputValidInSafeArea then
            return true
        else
            local canvasSize = self.view.rectTransform.rect.size
            local mousePos = InputManager.mousePosition
            local isClickSelf = UIUtils.isScreenPosInRectTransform(mousePos, self.view.content, self.uiCamera)
            if not isClickSelf then
                for rect, _ in pairs(self.m_extraSafeAreas) do
                    local isSafe = UIUtils.isScreenPosInRectTransform(mousePos, rect, self.uiCamera)
                    if isSafe then
                        isClickSelf = true
                        break
                    end
                end
            end
            return not isClickSelf, true
        end
    end
    return false
end
ItemTipsCtrl._CloseTips = HL.Method(HL.Opt(HL.Boolean)) << function(self, skipAnim)
    if UIManager:IsHide(PANEL_ID) then
        return
    end
    self:_ClearArgs()
    if skipAnim then
        self:Hide()
    else
        self:PlayAnimationOutWithCallback(function()
            if self.m_cachedArgs == nil then
                self:Hide()
            else
                self:_ShowTips(self.m_cachedArgs)
            end
        end)
    end
end
ItemTipsCtrl.m_extraSafeAreas = HL.Field(HL.Table)
ItemTipsCtrl._AddItemTipsSafeArea = HL.Method(RectTransform) << function(self, rect)
    self.m_extraSafeAreas[rect] = true
end
ItemTipsCtrl._RemoveItemTipsSafeArea = HL.Method(RectTransform) << function(self, rect)
    self.m_extraSafeAreas[rect] = nil
end
ItemTipsCtrl.m_updateCor = HL.Field(HL.Thread)
ItemTipsCtrl._RegisterCallback = HL.Method() << function(self)
    self.m_updateCor = self:_StartCoroutine(function()
        coroutine.step()
        while true do
            coroutine.step()
            if self:IsShow() and not self:IsPlayingAnimationOut() then
                self:_Update()
            end
        end
    end)
end
ItemTipsCtrl._ClearRegister = HL.Method() << function(self)
    self:_ClearCoroutine(self.m_updateCor)
    self.m_updateCor = nil
end
ItemTipsCtrl.OnItemCountChanged = HL.Method(HL.Any) << function(self, arg)
    if string.isEmpty(self.m_itemId) then
        return
    end
    local itemId2DiffCount = unpack(arg)
    if itemId2DiffCount:ContainsKey(self.m_itemId) then
        self:_UpdateCount()
    end
end
ItemTipsCtrl._StartPlace = HL.Method() << function(self)
    Notify(MessageConst.FAC_ENTER_BUILDING_MODE, { itemId = self.m_itemId, slotIndex = self.m_args.slotIndex, fromDepot = self.m_args.fromDepot, })
    self:_CloseTips(true)
end
ItemTipsCtrl._TryJump = HL.Method() << function(self)
    local canJump, jumpFunction = self:_CheckIfCanJump(self.m_itemId, self.m_data.type, self.m_instId)
    if not canJump then
        return
    end
    jumpFunction(self, self.m_itemId, self.m_instId)
    if canJump then
        self:_CloseTips(true)
    end
end
ItemTipsCtrl._UseItem = HL.Method() << function(self)
    if UIUtils.useItemOnTip(self.m_itemId) then
        self:_CloseTips(true)
    end
end
ItemTipsCtrl._ShowSplit = HL.Method() << function(self)
    UIUtils.splitItem(self.m_slotIndex)
    self:Hide()
end
ItemTipsCtrl._ShowClearBottle = HL.Method() << function(self)
    UIManager:Open(PanelId.ClearBottlePopUp, { slotIndex = self.m_slotIndex, fromDepot = self.m_args.fromDepot, itemId = self.m_itemId, itemCount = self.m_itemCount, })
    self:Hide()
end
ItemTipsCtrl._ShowWiki = HL.Method() << function(self)
    if UIManager:ShouldBlockObtainWaysJump() then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_OBTAIN_WAYS_JUMP_BLOCKED)
        return
    end
    Notify(MessageConst.SHOW_WIKI_ENTRY, { itemId = self:_GetShowWikiItemId() })
    self:_CloseTips(true)
end
ItemTipsCtrl._GetShowWikiItemId = HL.Method().Return(HL.String) << function(self)
    local isFullBottle, fullBottleData = Tables.fullBottleTable:TryGetValue(self.m_itemId)
    if isFullBottle then
        return fullBottleData.emptyBottleId
    end
    return self.m_itemId
end
ItemTipsCtrl._GetNeedShowWikiBtn = HL.Method().Return(HL.Boolean) << function(self)
    local wikiItemId = self:_GetShowWikiItemId()
    return WikiUtils.canShowWikiEntry(wikiItemId)
end
ItemTipsCtrl._TryGetTagList = HL.Method(HL.Any, HL.Any).Return(HL.Boolean, HL.Opt(HL.Any)) << function(self, itemId, itemType)
    return UIUtils.tryGetTagList(itemId, itemType)
end
ItemTipsCtrl._CheckIfCanJump = HL.Method(HL.String, HL.Userdata, HL.Opt(HL.Number)).Return(HL.Boolean, HL.Opt(HL.Function)) << function(self, itemId, itemType, instId)
    if self.m_args and self.m_args.noJump then
        return false
    end
    if not instId or instId <= 0 then
        return false
    end
    local isWeapon = itemType == GEnums.ItemType.Weapon
    if isWeapon then
        local weaponInst = CharInfoUtils.getWeaponByInstId(instId)
        if weaponInst ~= nil then
            return true, self._JumpToWeapon
        end
    end
    local isWeaponGem = itemType == GEnums.ItemType.WeaponGem
    if not isWeaponGem then
        return false
    end
    local gemInst = CharInfoUtils.getGemByInstId(instId)
    if not gemInst then
        return false
    end
    local weaponInstId = gemInst.weaponInstId
    if not weaponInstId or weaponInstId <= 0 then
        return false
    end
    return true, self._JumpToWeaponGem
end
ItemTipsCtrl._JumpToWeaponGem = HL.Method(HL.String, HL.Number) << function(self, gemTemplateId, gemInstId)
    local gemInst = CharInfoUtils.getGemByInstId(gemInstId)
    if not gemInst then
        return
    end
    local attachedWeaponInstId = gemInst.weaponInstId
    if not attachedWeaponInstId then
        return
    end
    local weaponInst = CharInfoUtils.getWeaponByInstId(attachedWeaponInstId)
    if not weaponInst then
        return
    end
    CharInfoUtils.openWeaponInfoBestWay({ weaponTemplateId = weaponInst.templateId, weaponInstId = weaponInst.instId, pageType = UIConst.WEAPON_EXHIBIT_PAGE_TYPE.GEM })
end
ItemTipsCtrl._JumpToWeapon = HL.Method(HL.String, HL.Number) << function(self, weaponTemplateId, weaponInstId)
    CharInfoUtils.openWeaponInfoBestWay({ weaponTemplateId = weaponTemplateId, weaponInstId = weaponInstId, })
end
ItemTipsCtrl._CheckIfShowEmptyNode = HL.Method(HL.Any, HL.Any).Return(HL.Boolean, HL.Opt(HL.Boolean, HL.Any, HL.Any)) << function(self, itemId, itemType)
    if itemType == GEnums.ItemType.Material or itemType == GEnums.ItemType.NormalBuilding then
        local isShowTagNode = self:_TryGetTagList(itemId, itemType)
        local isLiquidRelated = self:_CheckIsLiquidRelatedBottleItem(itemId)
        return not isShowTagNode and not isLiquidRelated
    end
    if itemType == GEnums.ItemType.Weapon then
        return false
    end
    if itemType == GEnums.ItemType.WeaponGem then
        return true
    end
    if itemType == GEnums.ItemType.Equip then
        return false
    end
    return true
end
ItemTipsCtrl._TryGetProductionItemList = HL.Method(HL.String).Return(HL.Opt(HL.Table)) << function(self, itemId)
    return FactoryUtils.getItemProductItemList(itemId)
end
ItemTipsCtrl._CheckIsLiquidRelatedBottleItem = HL.Method(HL.String).Return(HL.Boolean) << function(self, itemId)
    if not Utils.isSystemUnlocked(GEnums.UnlockSystemType.GeneralAbilityFluidInteract) then
        return false
    end
    return Tables.emptyBottleTable:ContainsKey(itemId) or Tables.fullBottleTable:ContainsKey(itemId)
end
ItemTipsCtrl.m_detailContentTopPadding = HL.Field(HL.Number) << 0
ItemTipsCtrl._OnDetailScroll = HL.Method() << function(self)
    local y = math.max(0, self.m_detailContentTopPadding - self.view.detailContent.anchoredPosition.y)
    local percent = 1 - (y / self.m_detailContentTopPadding)
    self.view.contentAnimationWrapper:SampleClipAtPercent("item_tips_scroll", percent)
end
ItemTipsCtrl._ToggleProductContent = HL.Method() << function(self)
    self.m_isShowBlueprintProduct = not self.m_isShowBlueprintProduct
    self.view.productNode.productContent.gameObject:SetActive(self.m_isShowBlueprintProduct)
    self.view.productNode.indicatorOn.gameObject:SetActive(not self.m_isShowBlueprintProduct)
    self.view.productNode.indicatorOff.gameObject:SetActive(self.m_isShowBlueprintProduct)
end
HL.Commit(ItemTipsCtrl)