RoomStateEnum = { Idle = 1, Producing = 2, ShutDown = 3, }
function updateSSCharStamina(staminaNode, charId)
    local spaceship = GameInstance.player.spaceship
    local staminaPercent = spaceship:GetCharCurStamina(charId) / Tables.spaceshipConst.maxPhysicalStrength
    staminaNode.valueTxt.text = string.format(Language.LUA_SPACESHIP_CHAR_STAMINA_FORMAT, math.ceil(staminaPercent * 100))
    if staminaNode.fill then
        staminaNode.fill.fillAmount = staminaPercent
    end
    local sprite
    local lowFrameActive
    local fullFrameActive
    if staminaPercent >= 1 then
        sprite = "spaceship_stamina_full"
        lowFrameActive = false
        fullFrameActive = true
    elseif staminaPercent <= 0.2 then
        sprite = "spaceship_stamina_low"
        lowFrameActive = true
        fullFrameActive = false
    else
        sprite = "spaceship_stamina_normal"
        lowFrameActive = false
        fullFrameActive = false
    end
    if staminaNode.lowFrame then
        staminaNode.lowFrame.gameObject:SetActive(lowFrameActive)
    end
    if staminaNode.fullFrame then
        staminaNode.fullFrame.gameObject:SetActive(fullFrameActive)
    end
    if staminaNode.icon then
        staminaNode.icon:LoadSprite(UIConst.UI_SPRITE_SS_COMMON, sprite)
    end
end
function updateSSCharInfos(view, charId, targetRoomId)
    local charData = Tables.characterTable[charId]
    if view.nameTxt then
        view.nameTxt.text = charData.name
    end
    if view.config and view.config:HasValue("USE_ROUND_ICON_PATH") and view.config.USE_ROUND_ICON_PATH then
        view.charIcon:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD, UIConst.UI_CHAR_HEAD_PREFIX .. charId)
    else
        view.charIcon:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD_RECTANGLE, UIConst.UI_CHAR_HEAD_SQUARE_PREFIX .. charId)
    end
    if view.rarity then
        view.rarity.color = UIUtils.getCharRarityColor(charData.rarity)
    end
    local spaceship = GameInstance.player.spaceship
    local char = spaceship.characters:get_Item(charId)
    view.friendshipTxt.text = string.format(Language.LUA_SPACESHIP_CHAR_FRIENDSHIP_FORMAT, math.floor(CSPlayerDataUtil.GetFriendshipPercent(char.friendship) * 100))
    updateSSCharStamina(view.staminaNode, charId)
    local showRoom = true
    if view.roomNode then
        showRoom = view.config.USE_ROOM_NODE
        view.roomNode.gameObject:SetActive(showRoom)
    end
    if showRoom and view.roomBG then
        local roomId = char.stationedRoomId
        if string.isEmpty(roomId) then
            view.roomBG.color = UIUtils.getColorByString(SpaceshipConst.NO_ROOM_COLOR_STR[1])
            view.roomName.color = UIUtils.getColorByString(SpaceshipConst.NO_ROOM_COLOR_STR[2])
            view.roomName.text = Language.LUA_SPACESHIP_CHAR_NO_ROOM
        else
            local roomData = Tables.spaceshipRoomInsTable[roomId]
            view.roomBG.color = UIUtils.getColorByString(SpaceshipConst.ROOM_COLOR_STR[roomData.roomType][1])
            view.roomName.color = UIUtils.getColorByString(SpaceshipConst.ROOM_COLOR_STR[roomData.roomType][2])
            if roomId == targetRoomId then
                view.roomName.text = Language.LUA_SPACESHIP_IS_IN_TARGET_ROOM
            else
                view.roomName.text = roomData.name
            end
        end
    end
    if view.stateNode then
        view.stateNode.gameObject:SetActive(view.config.USE_STATE_NODE and spaceship:IsCharResting(charId))
    end
    if view.friendshipNode then
        if view.config and view.config:HasValue("USE_FRIENDSHIP_NODE") then
            view.friendshipNode.gameObject:SetActive(view.config.USE_FRIENDSHIP_NODE)
        end
    end
    if view.workStateNode then
        local isWorking = char.isWorking
        local isResting = char.isResting
        if isWorking or isResting then
            view.workStateNode.gameObject:SetActive(true)
            view.workStateNode.workingIcon.gameObject:SetActive(isWorking)
            view.workStateNode.restIcon.gameObject:SetActive(isResting)
            if view.workStateNode.stateTxt then
                view.workStateNode.stateTxt.text = isWorking and Language.LUA_SPACESHIP_CHAR_WORKING or Language.LUA_SPACESHIP_CHAR_RESTING
            end
            if view.workStateNode.timeTxt then
                view.workStateNode.timeTxt:InitCountDownText(spaceship:GetCharLeftTime(charId) + DateTimeUtils.GetCurrentTimestampBySeconds())
            end
        else
            view.workStateNode.gameObject:SetActive(false)
        end
    end
end
function getRoomLvTableById(roomId)
    local roomData = Tables.spaceshipRoomInsTable[roomId]
    return getRoomLvTableByType(roomData.roomType)
end
function getRoomLvTableByType(roomType)
    if roomType == GEnums.SpaceshipRoomType.ControlCenter then
        return Tables.spaceshipControlCenterLvTable
    elseif roomType == GEnums.SpaceshipRoomType.ManufacturingStation then
        return Tables.spaceshipManufacturingStationLvTable
    elseif roomType == GEnums.SpaceshipRoomType.GrowCabin then
        return Tables.spaceshipGrowCabinLvTable
    end
end
function getRoomRecipeOutcomesByLv(roomId, lv, onlyNew)
    local roomData = Tables.spaceshipRoomInsTable[roomId]
    local roomType = roomData.roomType
    local outcomeItemIds = {}
    if roomType == GEnums.SpaceshipRoomType.ManufacturingStation then
        for _, v in pairs(Tables.spaceshipManufactureFormulaTable) do
            local isValid
            if onlyNew then
                isValid = v.level == lv
            else
                isValid = v.level <= lv
            end
            if isValid then
                local itemData = Tables.itemTable[v.outcomeItemId]
                table.insert(outcomeItemIds, { id = v.outcomeItemId, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2, })
            end
        end
    elseif roomType == GEnums.SpaceshipRoomType.GrowCabin then
        for _, v in pairs(Tables.spaceshipGrowCabinFormulaTable) do
            local isValid
            if onlyNew then
                isValid = v.level == lv
            else
                isValid = v.level <= lv
            end
            if isValid then
                local itemData = Tables.itemTable[v.outcomeItemId]
                table.insert(outcomeItemIds, { id = v.outcomeItemId, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2, })
            end
        end
        for _, v in pairs(Tables.spaceshipGrowCabinSeedFormulaTable) do
            local isValid
            if onlyNew then
                isValid = v.level == lv
            else
                isValid = v.level <= lv
            end
            if isValid then
                local itemData = Tables.itemTable[v.outcomeseedItemId]
                table.insert(outcomeItemIds, { id = v.outcomeseedItemId, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2, })
            end
        end
    end
    table.sort(outcomeItemIds, Utils.genSortFunction(UIConst.COMMON_ITEM_SORT_KEYS))
    return outcomeItemIds
end
function getUpgradeEffectInfos(roomId, newLv)
    local roomData = Tables.spaceshipRoomInsTable[roomId]
    local roomType = roomData.roomType
    local lvTable = getRoomLvTableByType(roomType)
    local oldLv = newLv - 1
    local oldLvData = lvTable[oldLv]
    local newLvData = lvTable[newLv]
    local effectInfos = {}
    if oldLvData.stationMaxCount ~= newLvData.stationMaxCount then
        table.insert(effectInfos, { icon = "icon_spaceship_room_effect_station", name = Language.LUA_SPACESHIP_UPGRADE_EFFECT_STATION_COUNT, oldValue = oldLvData.stationMaxCount, newValue = newLvData.stationMaxCount, })
    end
    if roomType == GEnums.SpaceshipRoomType.ControlCenter then
        if not string.isEmpty(newLvData.unlockRoom) then
            local oldRoomCount = 0
            for k = 1, newLv - 1 do
                local data = lvTable[k]
                oldRoomCount = oldRoomCount + (string.isEmpty(data.unlockRoom) and 0 or 1)
            end
            local roomInsData = Tables.spaceshipRoomInsTable[newLvData.unlockRoom]
            local roomName = roomInsData.name
            local roomTypeData = Tables.spaceshipRoomTypeTable[roomInsData.roomType]
            table.insert(effectInfos, { icon = "icon_spaceship_room_effect_new_room", name = Language.LUA_SPACESHIP_UPGRADE_EFFECT_NEW_ROOM, subInfos = { { color = UIUtils.getColorByString(roomTypeData.color), text = roomName, } }, oldValue = oldRoomCount, newValue = oldRoomCount + 1, })
        end
        local newRoomLvs = {}
        for k, v in pairs(Tables.spaceshipRoomLvTable) do
            if v.conditionType == GEnums.ConditionType.CheckSpaceshipRoomLevel and v.progressToCompare == newLv then
                table.insert(newRoomLvs, { id = k, helperData = Tables.spaceshipRoomLvHelperTable[k], })
            end
        end
        for _, info in ipairs(newRoomLvs) do
            local typeData = Tables.spaceshipRoomTypeTable[info.helperData.roomType]
            table.insert(effectInfos, { icon = typeData.icon, name = string.format(Language.LUA_SPACESHIP_UPGRADE_EFFECT_ROOM_MAX_LV, typeData.name), oldValue = info.helperData.level - 1, newValue = info.helperData.level, })
        end
    elseif roomType == GEnums.SpaceshipRoomType.ManufacturingStation then
        if oldLvData.machineCapacity ~= newLvData.machineCapacity then
            table.insert(effectInfos, { icon = "icon_spaceship_room_effect_capacity", name = Language.LUA_SPACESHIP_UPGRADE_EFFECT_MACHINE_CAPACITY, oldValue = oldLvData.machineCapacity, newValue = newLvData.machineCapacity, })
        end
    elseif roomType == GEnums.SpaceshipRoomType.GrowCabin then
        if newLvData.unlockPlantingField.Count > 0 then
            local oldFiledCount = 0
            for k = 1, newLv - 1 do
                local data = lvTable[k]
                oldFiledCount = oldFiledCount + data.unlockPlantingField.Count
            end
            table.insert(effectInfos, { icon = "icon_spaceship_room_effect_field", name = Language.LUA_SPACESHIP_UPGRADE_EFFECT_PLANTING_FIELD, oldValue = oldFiledCount, newValue = oldFiledCount + newLvData.unlockPlantingField.Count, })
        end
    end
    return effectInfos
end
local RoomEffectIcon = { station = "icon_spaceship_room_effect_station", newRoom = "icon_spaceship_room_effect_new_room", roomLv = "icon_spaceship_room_effect_room_lv", capacity = "icon_spaceship_room_effect_capacity", field = "icon_spaceship_room_effect_field", }
function getMaxUpgradeEffectInfos(roomId)
    local roomData = Tables.spaceshipRoomInsTable[roomId]
    local roomType = roomData.roomType
    local lvTable = getRoomLvTableByType(roomType)
    local maxLv = #lvTable
    local maxLvData = lvTable[maxLv]
    local effectInfos = {}
    table.insert(effectInfos, { icon = RoomEffectIcon.station, name = Language.LUA_SPACESHIP_UPGRADE_EFFECT_STATION_COUNT, value = maxLvData.stationMaxCount, })
    if roomType == GEnums.SpaceshipRoomType.ControlCenter then
        local roomCount = 0
        for k = 1, maxLv do
            local data = lvTable[k]
            roomCount = roomCount + (string.isEmpty(data.unlockRoom) and 0 or 1)
        end
        table.insert(effectInfos, { icon = RoomEffectIcon.newRoom, name = Language.LUA_SPACESHIP_UPGRADE_EFFECT_NEW_ROOM, value = roomCount, })
        local newRoomLvs = {}
        for k, v in pairs(Tables.spaceshipRoomLvTable) do
            if v.conditionType == GEnums.ConditionType.CheckSpaceshipRoomLevel then
                local helperData = Tables.spaceshipRoomLvHelperTable[k]
                if helperData.level == GameInstance.player.spaceship:GetRoomMaxLvByType(helperData.roomType) then
                    table.insert(newRoomLvs, { id = k, helperData = helperData, })
                end
            end
        end
        for _, info in ipairs(newRoomLvs) do
            local typeData = Tables.spaceshipRoomTypeTable[info.helperData.roomType]
            table.insert(effectInfos, { icon = typeData.icon, name = string.format(Language.LUA_SPACESHIP_UPGRADE_EFFECT_ROOM_MAX_LV, typeData.name), value = info.helperData.level, })
        end
    elseif roomType == GEnums.SpaceshipRoomType.ManufacturingStation then
        table.insert(effectInfos, { icon = RoomEffectIcon.capacity, name = Language.LUA_SPACESHIP_UPGRADE_EFFECT_MACHINE_CAPACITY, value = maxLvData.machineCapacity, })
    elseif roomType == GEnums.SpaceshipRoomType.GrowCabin then
        table.insert(effectInfos, { icon = RoomEffectIcon.field, name = Language.LUA_SPACESHIP_UPGRADE_EFFECT_PLANTING_FIELD, value = SpaceshipConst.GROW_CABIN_MAX_FILED, })
    end
    return effectInfos
end
function getRoomColor(roomId)
    local roomInsData = Tables.spaceshipRoomInsTable[roomId]
    local roomTypeData = Tables.spaceshipRoomTypeTable[roomInsData.roomType]
    return UIUtils.getColorByString(roomTypeData.color)
end
local Room2AttrMap = { [GEnums.SpaceshipRoomType.ControlCenter] = { GEnums.SpaceshipRoomAttrType.PSRecoveryRate, GEnums.SpaceshipRoomAttrType.RoomPSCostRate, }, [GEnums.SpaceshipRoomType.ManufacturingStation] = { GEnums.SpaceshipRoomAttrType.RoomPSCostRate, GEnums.SpaceshipRoomAttrType.RoomProduceRate, }, [GEnums.SpaceshipRoomType.GrowCabin] = { GEnums.SpaceshipRoomAttrType.RoomPSCostRate, GEnums.SpaceshipRoomAttrType.GrowCabinCharMaterialProduceRate, GEnums.SpaceshipRoomAttrType.GrowCabinSkillMaterialProduceRate, GEnums.SpaceshipRoomAttrType.GrowCabinWeaponMaterialProduceRate, }, }
local AttrBaseValue = { [GEnums.SpaceshipRoomAttrType.PSRecoveryRate] = Tables.spaceshipConst.basePhysicalStrengthRecoveryRate, [GEnums.SpaceshipRoomAttrType.RoomPSCostRate] = Tables.spaceshipConst.basePhysicalStrengthCostRate, [GEnums.SpaceshipRoomAttrType.RoomProduceRate] = Tables.spaceshipConst.defaultManufacturingStationProduceRate, [GEnums.SpaceshipRoomAttrType.GrowCabinCharMaterialProduceRate] = Tables.spaceshipConst.defaultGrowCabinProduceRate, [GEnums.SpaceshipRoomAttrType.GrowCabinSkillMaterialProduceRate] = Tables.spaceshipConst.defaultGrowCabinProduceRate, [GEnums.SpaceshipRoomAttrType.GrowCabinWeaponMaterialProduceRate] = Tables.spaceshipConst.defaultGrowCabinProduceRate, }
local AttrDefaultAddValue = { [GEnums.SpaceshipRoomAttrType.RoomProduceRate] = Tables.spaceshipConst.baseManufacturingStationProduceRate, [GEnums.SpaceshipRoomAttrType.GrowCabinCharMaterialProduceRate] = Tables.spaceshipConst.baseGrowCabinProduceRate, [GEnums.SpaceshipRoomAttrType.GrowCabinSkillMaterialProduceRate] = Tables.spaceshipConst.baseGrowCabinProduceRate, [GEnums.SpaceshipRoomAttrType.GrowCabinWeaponMaterialProduceRate] = Tables.spaceshipConst.baseGrowCabinProduceRate, }
function preCalcRoomAttrs(roomId, charIds)
    local roomAttrMap = {}
    local roomInsData = Tables.spaceshipRoomInsTable[roomId]
    local roomType = roomInsData.roomType
    local roomTypeData = Tables.spaceshipRoomTypeTable[roomType]
    local charCount = #charIds
    for _, t in ipairs(Room2AttrMap[roomType]) do
        local info = { type = t, typeData = Tables.spaceshipRoomAttrTypeTable:GetValue(t), }
        info.sortId = info.typeData.sortId
        info.attr = { baseValue = AttrBaseValue[t], addFromCharSkill = 0, }
        if AttrDefaultAddValue[t] then
            info.attr.addFromCharStation = AttrDefaultAddValue[t] * charCount
        else
            info.attr.addFromCharStation = 0
        end
        roomAttrMap[t] = info
    end
    local spaceship = GameInstance.player.spaceship
    for _, charId in ipairs(charIds) do
        local char = spaceship.characters:get_Item(charId)
        for _, skillId in pairs(char.skills) do
            local skillData = Tables.spaceshipSkillTable[skillId]
            if skillData.roomType == roomType then
                local attrType, rate
                if skillData.effectType == GEnums.SpaceshipStationEffectType.PSRecoveryRateAccByPercent then
                    attrType = GEnums.SpaceshipRoomAttrType.PSRecoveryRate
                    rate = skillData.parameters[0].valueFloatList[0]
                elseif skillData.effectType == GEnums.SpaceshipStationEffectType.RoomPSCostRateReduceByPercent then
                    attrType = GEnums.SpaceshipRoomAttrType.RoomPSCostRate
                    rate = -skillData.parameters[0].valueFloatList[0]
                elseif skillData.effectType == GEnums.SpaceshipStationEffectType.RoomProduceRateAccByPercent then
                    attrType = GEnums.SpaceshipRoomAttrType.RoomProduceRate
                    rate = skillData.parameters[0].valueFloatList[0]
                elseif skillData.effectType == GEnums.SpaceshipStationEffectType.RoomPlantTypeProduceRateAccByPercent then
                    local typeInt = skillData.parameters[1].valueIntList[0]
                    if typeInt == 1 then
                        attrType = GEnums.SpaceshipRoomAttrType.GrowCabinCharMaterialProduceRate
                    elseif typeInt == 2 then
                        attrType = GEnums.SpaceshipRoomAttrType.GrowCabinSkillMaterialProduceRate
                    elseif typeInt == 3 then
                        attrType = GEnums.SpaceshipRoomAttrType.GrowCabinWeaponMaterialProduceRate
                    end
                    rate = skillData.parameters[0].valueFloatList[0]
                end
                local attr = roomAttrMap[attrType].attr
                attr.addFromCharSkill = attr.addFromCharSkill + attr.baseValue * rate
            end
        end
    end
    local roomAttrs = {}
    for _, v in pairs(roomAttrMap) do
        v.attr.Value = v.attr.baseValue + v.attr.addFromCharStation + v.attr.addFromCharSkill
        table.insert(roomAttrs, v)
    end
    logger.info("preCalcRoomAttrs", roomAttrs)
    return roomAttrs
end