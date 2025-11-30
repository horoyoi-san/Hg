function hasGemNotEquipped()
    local gemDepot = GameInstance.player.inventory.valuableDepots[GEnums.ItemValuableDepotType.WeaponGem]:GetOrFallback(Utils.getCurrentScope())
    if not gemDepot then
        return false
    end
    local gemInstDict = gemDepot.instItems
    for _, itemBundle in pairs(gemInstDict) do
        local gemInst = itemBundle.instData
        if gemInst and gemInst.weaponInstId <= 0 then
            return true
        end
    end
    return false
end
function hasBlocShopDiscountShopItem(blocId)
    local shopInfo = GameInstance.player.blocManager:GetBlocShopInfo(blocId)
    if not shopInfo then
        logger.error("RedDotUtils->hasBlocShopDiscountShopItem: shopInfo is nil, blocId", blocId)
        return false
    end
    local shopId = shopInfo.Shopid
    local discountInfoMaps = {}
    for k = 0, shopInfo.DiscountInfo.Count - 1 do
        local v = shopInfo.DiscountInfo[k]
        discountInfoMaps[v.Posid] = v.Discount
    end
    local shopItemMap = Tables.blocShopItemTable[shopId]
    if not shopItemMap then
        logger.error("RedDotUtils->hasBlocShopDiscountShopItem: shopItemMap is nil, shopId", shopId)
        return false
    end
    local blocInfo = GameInstance.player.blocManager:GetBlocInfo(blocId)
    if not blocInfo then
        logger.error("RedDotUtils->hasBlocShopDiscountShopItem: blocInfo is nil, blocId", blocId)
        return false
    end
    local blocLv = blocInfo.Level
    for lv, items in pairs(shopItemMap.map) do
        if lv <= blocLv then
            for _, v in pairs(items.list) do
                local _, soldCount = shopInfo.AlreadySellCount:TryGetValue(v.id)
                local count = v.availCount - soldCount
                local isDiscount = discountInfoMaps[v.id] ~= nil
                if isDiscount and count > 0 then
                    return true
                end
            end
        end
    end
    return false
end
function hasCheckInRewardsNotCollected()
    local activitySystem = GameInstance.player.activitySystem;
    local checkInSystem = activitySystem:GetActivity(UIConst.CHECK_IN_CONST.CBT2_CHECK_IN_ID)
    if checkInSystem.rewardDays >= checkInSystem.loginDays then
        return false
    end
    local maxRewardDays = #Tables.checkInRewardTable
    return checkInSystem.rewardDays < maxRewardDays
end
function hasCheckInRewardsNotCollectedInRange(args)
    if args.checkInActivity.loginDays == args.checkInActivity.rewardDays then
        return false
    end
    if args.checkInActivity.rewardDays >= args.lastDay then
        return false
    end
    if args.checkInActivity.loginDays < args.firstDay then
        return false
    end
    return true
end
function hasCraftRedDot(craftId)
    return false
end
function readRedDot(systemType, id)
    if isRead(systemType, id) then
        return
    end
    local msg = LegacyMockNet.ReadRedDot()
    msg.type = systemType
    msg.ids = { id }
    LegacyLuaNetBus.Send(msg)
end
function readRedDots(systemType, ids)
    local msg = LegacyMockNet.ReadRedDot()
    msg.type = systemType
    msg.ids = ids
    LegacyLuaNetBus.Send(msg)
end
function hasPrtsNoteRedDot(investCfg)
    for _, data in pairs(investCfg.categoryDataList) do
        for _, id in pairs(data.noteIdList) do
            if GameInstance.player.prts:IsNoteUnread(id) then
                return true
            end
        end
    end
    return false
end