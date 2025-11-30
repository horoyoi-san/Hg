function curPowerIsEnough()
    return not getCurRegionPowerInfo().isStopByPower
end
function getBuildingStateType(nodeId)
    local spBuilding = GameInstance.player.facSpMachineSystem:GetNode(nodeId)
    if spBuilding and spBuilding:IsIdle() then
        return GEnums.FacBuildingState.Idle
    end
    return GameInstance.remoteFactoryManager:QueryBuildingState(Utils.getCurrentChapterId(), nodeId, false)
end
function getCraftNeedTime(craftData)
    local formulaGroupId = craftData.formulaGroupId
    local machineCraftGroupData = Tables.factoryMachineCraftGroupTable:GetValue(formulaGroupId)
    return craftData.progressRound * machineCraftGroupData.msPerRound * 0.001
end
function getCurHubNodeId()
    local id = GameInstance.player.facSpMachineSystem:GetCurHubNodId()
    return id > 0 and id or nil
end
function getPowerText(power, isEnergy)
    local unit = isEnergy and Language.LUA_FAC_POWER_UNIT or Language.LUA_FAC_MACHINE_CONSUME_POWER_UNIT
    return UIUtils.getNumString(power) .. unit
end
function getBuildingStateIconName(nodeId, state)
    state = state or getBuildingStateType(nodeId)
    return UIConst.UI_SPRITE_FAC_BUILDING_COMMON, FacConst.FAC_BUILDING_STATE_TO_SPRITE[state]
end
function getItemProductivityPerMinus(itemId)
    return 0
end
function isBuilding(itemId)
    if string.isEmpty(itemId) then
        return false
    end
    local valid, data = Tables.factoryBuildingItemTable:TryGetValue(itemId)
    return valid, valid and data.buildingId or nil
end
function isInBuildMode()
    local opened, ctrl = UIManager:IsOpen(PanelId.FacBuildMode)
    if opened then
        return ctrl.m_mode ~= FacConst.FAC_BUILD_MODE.Normal
    else
        return false
    end
end
function isMovingBuilding()
    local opened, ctrl = UIManager:IsOpen(PanelId.FacBuildMode)
    if opened then
        return ctrl.m_buildingNodeId ~= nil
    else
        return false
    end
end
function getBuildingNodeHandler(nodeId)
    return CSFactoryUtil.GetNodeHandlerByNodeId(nodeId)
end
function getBuildingComponentHandler(componentId)
    return CSFactoryUtil.GetComponentHandlerByComponentId(componentId)
end
function getBuildingComponentHandlerAtPos(syncNode, cptPos)
    local cpt = syncNode:GetComponentInPosition(cptPos:GetHashCode())
    if cpt then
        return getBuildingComponentHandler(cpt.componentId)
    end
    return nil
end
function canMoveBuilding(nodeId, needToast)
    local node = getBuildingNodeHandler(nodeId)
    if not node then
        return false
    end
    local isMoveLocked = CSFactoryUtil.CheckIsBuildingMoveAndDelLocked(node.templateId, node.instKey, needToast == true)
    if isMoveLocked then
        return false
    end
    local pdp = node.predefinedParam
    if not pdp then
        return true
    end
    if not pdp.common then
        return true
    end
    if pdp.common.forbidMove then
        if needToast then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_FACTORY_BUILDING_MOVE_NOT_ALLOWED)
        end
        return false
    end
    return true
end
function canDelBuilding(nodeId, needToast)
    local node = getBuildingNodeHandler(nodeId)
    if not node then
        if needToast then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_FACTORY_BUILDING_DELETE_NOT_EXIST)
        end
        return false
    end
    local isDelLocked = CSFactoryUtil.CheckIsBuildingMoveAndDelLocked(node.templateId, node.instKey, needToast == true)
    if isDelLocked then
        return false
    end
    local pdp = node.predefinedParam
    if not pdp then
        return true
    end
    if not pdp.common then
        return true
    end
    if pdp.common.forbidDelete then
        if needToast then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_FACTORY_BUILDING_DELETE_NOT_ALLOWED)
        end
        return false
    end
    return true
end
function delBuilding(nodeId, onComplete, noConfirm, hintText)
    local clearAct
    local canDelete = canDelBuilding(nodeId, true)
    if not canDelete then
        return
    end
    local delBuildingAct = function()
        if clearAct then
            clearAct()
        end
        GameInstance.player.remoteFactory.core:Message_OpDismantle(Utils.getCurrentChapterId(), nodeId, function()
            if onComplete then
                onComplete()
            end
        end)
    end
    if noConfirm then
        delBuildingAct()
    else
        if hintText == nil or hintText == "" then
            hintText = Language.LUA_FAC_ASK_DELETE_BUILDING
        end
        Notify(MessageConst.SHOW_POP_UP, { content = hintText, hideBlur = true, onCancel = clearAct, onConfirm = delBuildingAct, })
    end
end
function getItemBuildingData(itemId)
    local succ, buildingItemData = Tables.factoryBuildingItemTable:TryGetValue(itemId)
    if not succ then
        return
    end
    local buildingData = Tables.factoryBuildingTable:GetValue(buildingItemData.buildingId)
    return buildingData
end
function getItemBuildingId(itemId)
    local succ, buildingItemData = Tables.factoryBuildingItemTable:TryGetValue(itemId)
    if not succ then
        return
    end
    return buildingItemData.buildingId
end
function getBuildingItemData(buildingId)
    local succ, buildingItemData = Tables.factoryBuildingItemReverseTable:TryGetValue(buildingId)
    if not succ then
        logger.error("策划配错了，建筑没有对应道具", buildingId)
    end
    local itemData = Tables.itemTable:GetValue(buildingItemData.itemId)
    return itemData
end
function getBuildingItemId(buildingId)
    if not buildingId then
        return nil
    end
    local buildingItemData = Tables.factoryBuildingItemReverseTable:GetValue(buildingId)
    return buildingItemData.itemId
end
function getCurBuildingConsumePower(nodeId)
    local node = getBuildingNodeHandler(nodeId)
    local powerCost = getBuildingConsumePower(node.templateId)
    local powerObj = node.power
    if powerObj then
        if node.power.powerCost then
            powerCost = node.power.powerCost
        end
    end
    return powerCost
end
function getBuildingConsumePower(buildingId)
    local data = Tables.factoryBuildingTable:GetValue(buildingId)
    return data.powerConsume
end
function getItemOutputItemIds(itemId, ignoreUnlock)
    local outcomeIds = {}
    local facCore = GameInstance.player.remoteFactory.core
    do
        local hasCraft, craftIds = Tables.factoryItemAsMachineCrafterIncomeTable:TryGetValue(itemId)
        if hasCraft then
            for _, craftId in pairs(craftIds.list) do
                if ignoreUnlock or facCore:IsFormulaVisible(craftId) then
                    local craftData = Tables.factoryMachineCraftTable:GetValue(craftId)
                    local itemBundleGroupList = craftData.outcomes
                    for _, group in pairs(itemBundleGroupList) do
                        for _, bundle in pairs(group.group) do
                            outcomeIds[bundle.id] = true
                        end
                    end
                end
            end
        end
    end
    do
        local hasCraft, craftIds = Tables.FactoryItemAsHubCraftIncomeTable:TryGetValue(itemId)
        if hasCraft then
            local sys = GameInstance.player.facSpMachineSystem
            for _, craftId in pairs(craftIds.list) do
                if ignoreUnlock or sys:IsCraftUnlocked(craftId) then
                    local craftData = Tables.factoryHubCraftTable:GetValue(craftId)
                    for _, bundle in pairs(craftData.outcomes) do
                        outcomeIds[bundle.id] = true
                    end
                end
            end
        end
    end
    if not next(outcomeIds) then
        return
    end
    local outcomeIdList = {}
    for id, _ in pairs(outcomeIds) do
        table.insert(outcomeIdList, id)
    end
    return outcomeIdList
end
function getItemAsInputRecipeIds(itemId, ignoreUnlock)
    local recipeIds = {}
    local canCraft = false
    do
        local hasCraft, craftIds = Tables.factoryItemAsMachineCrafterIncomeTable:TryGetValue(itemId)
        if hasCraft then
            canCraft = true
            for _, craftId in pairs(craftIds.list) do
                table.insert(recipeIds, parseMachineCraftData(craftId))
            end
        end
    end
    do
        local hasCraft, craftIds = Tables.FactoryItemAsHubCraftIncomeTable:TryGetValue(itemId)
        if hasCraft then
            canCraft = true
            for _, craftId in pairs(craftIds.list) do
                if ignoreUnlock or FactoryUtils.isSpMachineFormulaUnlocked(craftId) then
                    table.insert(recipeIds, parseHubCraftData(craftId, true))
                end
            end
        end
    end
    do
        local manualCraftIdList = {}
        for craftId, v in pairs(Tables.factoryManualCraftTable) do
            for i = 0, v.ingredients.Count - 1 do
                local ingredientItemId = v.ingredients[i].id
                if v.ingredients[i].id == itemId then
                    table.insert(manualCraftIdList, craftId)
                    break
                end
            end
        end
        if #manualCraftIdList > 0 then
            local manualCraft = GameInstance.player.facManualCraft
            canCraft = true
            for _, craftId in pairs(manualCraftIdList) do
                if ignoreUnlock or manualCraft:IsCraftUnlocked(craftId) then
                    table.insert(recipeIds, parseManualCraftData(craftId, true))
                end
            end
        end
    end
    return recipeIds, canCraft
end
function getBuildingCrafts(buildingId, ignoreUnlock, justId, producerMode)
    local bData = Tables.factoryBuildingTable:GetValue(buildingId)
    local bType = bData.type
    local crafts = {}
    local facCore = GameInstance.player.remoteFactory.core
    local inventory = GameInstance.player.inventory
    if bType == GEnums.FacBuildingType.PowerStation then
        local powerStationData = Tables.factoryPowerStationTable:GetValue(buildingId)
        for fuelId, fuelData in pairs(Tables.factoryFuelItemTable) do
            if ignoreUnlock or inventory:IsItemFound(fuelId) then
                if justId then
                    table.insert(crafts, fuelId)
                else
                    local info = { incomes = { { id = fuelId, count = 1 } }, time = powerStationData.msPerRound * fuelData.progressRound * 0.001, outcomeText = string.format(Language.FUEL_OUTCOME_TEXT_FORMAT, powerStationData.powerProvide), buildingId = buildingId, craftId = fuelId, }
                    table.insert(crafts, info)
                end
            end
        end
    elseif bType == GEnums.FacBuildingType.Hub or bType == GEnums.FacBuildingType.SubHub then
        local sys = GameInstance.player.facSpMachineSystem
        for craftId, data in pairs(Tables.factoryHubCraftTable) do
            if ignoreUnlock or sys:IsCraftUnlocked(craftId) then
                if justId then
                    table.insert(crafts, craftId)
                else
                    local info = parseHubCraftData(craftId)
                    info.buildingId = buildingId
                    table.insert(crafts, info)
                end
            end
        end
    elseif bType == GEnums.FacBuildingType.Miner then
        if ignoreUnlock or inventory:IsItemFound(getBuildingItemId(buildingId)) then
            local minerData = Tables.factoryMinerTable:GetValue(buildingId)
            for _, mineable in pairs(minerData.mineable) do
                local mineId = mineable.miningItemId
                if justId then
                    table.insert(crafts, mineId)
                else
                    local incomesId = "item_minepoint" .. string.sub(mineId, string.find(mineId, "_"), -1)
                    local minerTime = minerData.msPerRound / mineable.produceRate * 0.001
                    local newIncomes = {}
                    local consumeItemId = mineable.consumeItem.id
                    local consumeItemCount = mineable.consumeItem.count
                    if not consumeItemId:isEmpty() and consumeItemCount > 0 then
                        table.insert(newIncomes, { id = consumeItemId, count = consumeItemCount })
                    end
                    table.insert(newIncomes, { id = incomesId, count = 1 })
                    local info = { time = minerTime, incomes = newIncomes, outcomes = { { id = mineId, count = 1 } }, buildingId = buildingId, craftId = mineId, }
                    table.insert(crafts, info)
                end
            end
        end
    elseif bType == GEnums.FacBuildingType.MachineCrafter or bType == GEnums.FacBuildingType.FluidReaction then
        local machineCrafterData = Tables.factoryMachineCrafterTable:GetValue(buildingId)
        for i = 0, machineCrafterData.modeMap.Count - 1 do
            local curModeItem = machineCrafterData.modeMap[i]
            if not producerMode or curModeItem.modeName == producerMode then
                local machineCrafterGroupData = Tables.factoryMachineCraftGroupTable:GetValue(curModeItem.groupName)
                for _, craftId in pairs(machineCrafterGroupData.craftList) do
                    if ignoreUnlock or facCore:IsFormulaVisible(craftId) then
                        if justId then
                            table.insert(crafts, craftId)
                        else
                            table.insert(crafts, parseMachineCraftData(craftId))
                        end
                    end
                end
                if producerMode then
                    break
                end
            end
        end
    elseif bType == GEnums.FacBuildingType.FluidPumpIn then
        local fluidPumpInDataSuccess, fluidPumpInData = Tables.factoryFluidPumpInTable:TryGetValue(buildingId)
        if fluidPumpInDataSuccess then
            local time = fluidPumpInData.msPerRound * 0.001
            for liquidItemId, _ in pairs(Tables.liquidTable) do
                local liquidPreFix = "liquid"
                local liquidItemSubString = string.sub(liquidItemId, string.find(liquidItemId, liquidPreFix) + #liquidPreFix)
                local liquidPointItemId = string.format("item_liquidpoint%s", liquidItemSubString)
                local liquidPointSuccess, liquidPointItemData = Tables.itemTable:TryGetValue(liquidPointItemId)
                if liquidPointSuccess then
                    if justId then
                        table.insert(crafts, liquidItemId)
                    else
                        local incomesId = liquidPointItemId
                        local info = { time = time, incomes = { { id = incomesId, count = 1 } }, outcomes = { { id = liquidItemId, count = 1 } }, buildingId = buildingId, craftId = liquidItemId, }
                        table.insert(crafts, info)
                    end
                end
            end
        end
    elseif bType == GEnums.FacBuildingType.FluidConsume then
        local consumeSuccess, consumeData = Tables.factoryFluidConsumeTable:TryGetValue(buildingId)
        if consumeSuccess then
            local time = consumeData.msPerRound * 0.001
            for index = 0, consumeData.liquidable.Count - 1 do
                local liquidItemId = consumeData.liquidable[index]
                if justId then
                    table.insert(crafts, liquidItemId)
                else
                    local incomesId = liquidItemId
                    local info = { time = time, incomes = { { id = incomesId, count = 1 } }, buildingId = buildingId, craftId = liquidItemId, useFinish = true, }
                    table.insert(crafts, info)
                end
            end
        end
    end
    return crafts, bType
end
function getBuildingCraftsWithNodeId(nodeId, ignoreUnlock, justId)
    local node = FactoryUtils.getBuildingNodeHandler(nodeId)
    local buildingId = node.templateId
    local formulaManComponentPosition = GEnums.FCComponentPos.FormulaMan:GetHashCode()
    local formulaManComponent = node:GetComponentInPosition(formulaManComponentPosition)
    local currentMode = formulaManComponent ~= nil and formulaManComponent.formulaMan.currentMode or nil
    local result
    local pdp = node.predefinedParam
    if pdp then
        local limitedResult = {}
        result = getBuildingCrafts(buildingId, true, justId, currentMode)
        local unlockIdList
        if pdp.producer and pdp.producer.limitedFormulaIds.Count > 0 then
            unlockIdList = pdp.producer.limitedFormulaIds
        elseif pdp.fluidReaction and pdp.fluidReaction.visibleFormulas.Count > 0 then
            unlockIdList = pdp.fluidReaction.visibleFormulas
        end
        if unlockIdList then
            for _, v in ipairs(result) do
                local curId = justId and v or v.craftId
                local found = false
                for i = 0, unlockIdList.Count - 1 do
                    if unlockIdList[i] == curId then
                        found = true
                        break
                    end
                end
                if found then
                    table.insert(limitedResult, v)
                end
            end
            result = limitedResult
        end
    end
    if not result then
        result = getBuildingCrafts(buildingId, ignoreUnlock, justId, currentMode)
    end
    return result
end
function checkBuildingHasMode(buildingId, mode)
    local crafterData = Tables.factoryMachineCrafterTable:GetValue(buildingId)
    for index = 0, crafterData.modeMap.Count - 1 do
        local mapData = crafterData.modeMap[index]
        if mapData ~= nil and mapData.modeName == mode then
            return true
        end
    end
    return false
end
function getMachineCraftGroupData(buildingId, modeName)
    local crafterData = Tables.factoryMachineCrafterTable:GetValue(buildingId)
    for i = 0, crafterData.modeMap.Count - 1 do
        local modeMapItem = crafterData.modeMap[i]
        if modeMapItem.modeName == modeName then
            return Tables.factoryMachineCraftGroupTable:GetValue(modeMapItem.groupName)
        end
    end
end
function getMachineCraftGroupDataFromNodeHandler(nodeHandler)
    local buildingId = nodeHandler.templateId
    local formulaManComponentPosition = GEnums.FCComponentPos.FormulaMan:GetHashCode()
    local formulaManComponent = nodeHandler:GetComponentInPosition(formulaManComponentPosition)
    local currentMode = formulaManComponent.formulaMan.currentMode
    return getMachineCraftGroupData(buildingId, currentMode)
end
function getItemCrafts(itemId, ignoreUnlock)
    local crafts = {}
    local canCraft = false
    local facCore = GameInstance.player.remoteFactory.core
    local inventory = GameInstance.player.inventory
    do
        local hasCraft, craftIds = Tables.factoryItemAsMachineCrafterOutcomeTable:TryGetValue(itemId)
        if hasCraft then
            canCraft = true
            for _, craftId in pairs(craftIds.list) do
                if ignoreUnlock or facCore:IsFormulaVisible(craftId) then
                    table.insert(crafts, parseMachineCraftData(craftId))
                end
            end
        end
    end
    do
        local hasCraft, craftIds = Tables.factoryItemAsHubCraftOutcomeTable:TryGetValue(itemId)
        if hasCraft then
            canCraft = true
            local sys = GameInstance.player.facSpMachineSystem
            for _, craftId in pairs(craftIds.list) do
                if ignoreUnlock or sys:IsCraftUnlocked(craftId) then
                    table.insert(crafts, parseHubCraftData(craftId, true))
                end
            end
        end
    end
    do
        local hasCraft, craftIds = Tables.factoryItemAsManualCraftOutcomeTable:TryGetValue(itemId)
        if hasCraft then
            canCraft = true
            local sys = GameInstance.player.facManualCraft
            for _, craftId in pairs(craftIds.list) do
                if ignoreUnlock or sys:IsCraftUnlocked(craftId) then
                    table.insert(crafts, parseManualCraftData(craftId, true))
                end
            end
        end
    end
    do
        for buildingId, minerData in pairs(Tables.factoryMinerTable) do
            local buildingItemId = getBuildingItemId(buildingId)
            local isUnlock = inventory:IsItemFound(buildingItemId)
            for idx = 0, minerData.mineable.Count - 1 do
                local v = minerData.mineable[idx]
                if v.miningItemId == itemId then
                    if ignoreUnlock or isUnlock then
                        canCraft = true
                        local minerTime = minerData.msPerRound / v.produceRate * 0.001
                        local info = { time = minerTime, outcomes = { { id = itemId, count = 1 } }, buildingId = buildingId, craftId = itemId, isUnlock = isUnlock, }
                    end
                end
            end
        end
    end
    return crafts, canCraft
end
function getItemProductItemList(itemId)
    local itemMap = {}
    local itemList = {}
    local itemData = Tables.itemTable[itemId]
    local itemType = itemData.type
    local inv = GameInstance.player.inventory
    local ignoreUnlock = itemType == GEnums.ItemType.Blueprint
    for _, id in pairs(itemData.outcomeItemIds) do
        if ignoreUnlock or inv:IsItemFound(id) then
            itemMap[id] = true
            table.insert(itemList, id)
        end
    end
    local extraItemIds, buildingId
    if itemType == GEnums.ItemType.Material then
        extraItemIds = getItemOutputItemIds(itemId, false)
    elseif itemType == GEnums.ItemType.NormalBuilding then
        buildingId = getItemBuildingId(itemId)
    elseif itemType == GEnums.ItemType.Blueprint then
        local succ, d = Tables.machineBlueprint2MachineItemTable:TryGetValue(itemId)
        if succ then
            buildingId = getItemBuildingId(d.itemId)
        end
    end
    if buildingId then
        local crafts, bType = getBuildingCrafts(buildingId, ignoreUnlock, true, nil)
        if bType == GEnums.FacBuildingType.Miner then
            extraItemIds = crafts
        elseif bType == GEnums.FacBuildingType.MachineCrafter then
            extraItemIds = {}
            for _, craftId in ipairs(crafts) do
                local craftData = Tables.factoryMachineCraftTable:GetValue(craftId)
                for _, itemBundleGroup in pairs(craftData.outcomes) do
                    for _, itemBundle in pairs(itemBundleGroup.group) do
                        table.insert(extraItemIds, itemBundle.id)
                    end
                end
            end
        end
    end
    if extraItemIds then
        for _, id in ipairs(extraItemIds) do
            if not itemMap[id] then
                itemMap[id] = true
                table.insert(itemList, id)
            end
        end
    end
    if next(itemList) then
        return itemList
    else
        return nil
    end
end
function parseMachineCraftData(craftId)
    local craftData = Tables.factoryMachineCraftTable:GetValue(craftId)
    local formulaGroupId = craftData.formulaGroupId
    local machineCraftGroupData = Tables.factoryMachineCraftGroupTable:GetValue(formulaGroupId)
    local info = { incomes = {}, time = craftData.progressRound * machineCraftGroupData.msPerRound * 0.001, outcomes = {}, buildingId = craftData.machineId, craftId = craftId, isUnlock = GameInstance.player.remoteFactory.core:IsFormulaVisible(craftId), }
    for _, itemBundleGroup in pairs(craftData.ingredients) do
        for _, itemBundle in pairs(itemBundleGroup.group) do
            table.insert(info.incomes, { id = itemBundle.id, count = itemBundle.count, buffer = craftData.buffers:GetValue(itemBundle.id) })
        end
    end
    for _, itemBundleGroup in pairs(craftData.outcomes) do
        for _, itemBundle in pairs(itemBundleGroup.group) do
            table.insert(info.outcomes, { id = itemBundle.id, count = itemBundle.count, buffer = craftData.buffers:GetValue(itemBundle.id) })
        end
    end
    return info
end
function parseHubCraftData(craftId, findBuilding)
    local craftData = Tables.factoryHubCraftTable:GetValue(craftId)
    local info = { incomes = {}, outcomes = {}, craftId = craftId, isUnlock = GameInstance.player.facSpMachineSystem:IsCraftUnlocked(craftId), }
    for _, itemBundle in pairs(craftData.ingredients) do
        table.insert(info.incomes, { id = itemBundle.id, count = itemBundle.count })
    end
    for _, itemBundle in pairs(craftData.outcomes) do
        table.insert(info.outcomes, { id = itemBundle.id, count = itemBundle.count })
    end
    if findBuilding then
        info.buildingId = FacConst.HUB_DATA_ID
    end
    return info
end
function parseManualCraftData(craftId, findBuilding)
    local craftData = Tables.factoryManualCraftTable:GetValue(craftId)
    local info = { incomes = {}, outcomes = {}, craftId = craftId, isUnlock = GameInstance.player.facManualCraft:IsCraftUnlocked(craftId) }
    for _, itemBundle in pairs(craftData.ingredients) do
        table.insert(info.incomes, { id = itemBundle.id, count = itemBundle.count })
    end
    for _, itemBundle in pairs(craftData.outcomes) do
        table.insert(info.outcomes, { id = itemBundle.id, count = itemBundle.count })
    end
    return info
end
function isSpecialBuilding(buildingId)
    local buildingData = Tables.factoryBuildingTable:GetValue(buildingId)
    local isSpBuilding = lume.find(FacConst.SP_BUILDING_TYPES, buildingData.type) ~= nil
    return isSpBuilding
end
function isInTopView()
    return LuaSystemManager.facSystem.inTopView
end
function isMachineTargetShown()
    local ctrl = UIManager.cfgs.FacMainLeft.ctrl
    return ctrl and ctrl.showMachineTarget or false
end
function canPlaceBuildingOnCurRegion(buildingId)
    if not Utils.isCurrentMapHasFactoryGrid() then
        return false
    end
    local isInMainRegion = GameInstance.remoteFactoryManager:IsPlayerPositionInMainRegion()
    if isInMainRegion then
        return true
    end
    local buildingData = Tables.factoryBuildingTable:GetValue(buildingId)
    if buildingData.type == GEnums.FacBuildingType.SubHub then
        return true
    end
    return not buildingData.onlyShowOnMain
end
function getCurRegionInfo()
    return GameInstance.remoteFactoryManager.system.core.currentScope
end
function getCurChapterInfo()
    return GameInstance.player.remoteFactory.core:GetChapterInfoById(Utils.getCurrentChapterId())
end
function getCurRegionPowerInfo()
    local chapterInfo = getCurChapterInfo()
    if chapterInfo then
        return chapterInfo.blackboard.power
    end
end
function getRegionPowerInfoByChapterId(chapterId)
    local chapterInfo = GameInstance.remoteFactoryManager.system.core:GetChapterInfoById(chapterId)
    if chapterInfo == nil then
        return nil
    end
    return chapterInfo.blackboard.power
end
function getMedicProgress(nodeId)
    return GameInstance.remoteFactoryManager.medicalTowerManager:GetCurrentProgress(nodeId)
end
function findNearestBuilding(buildingId, ignoreCull)
    local playerPos = GameInstance.playerController.mainCharacter.position
    return CS.Beyond.Gameplay.RemoteFactory.RemoteFactoryManager.FindNearestBuilding(buildingId, playerPos, ignoreCull == true)
end
function queryVoxelRangeHeightAdjust(posX, posY, posZ)
    return CS.Beyond.Gameplay.RemoteFactory.RemoteFactoryUtil.VoxelRangeHeightAdjust(CS.UnityEngine.RectInt(posX, posZ, 1, 1), posY)
end
function getCurSceneHandler()
    return CSFactoryUtil.GetSceneHandler()
end
function isPlayerOutOfRangeManual()
    local level = PhaseManager.m_openedPhaseSet[PhaseId.Level]
    if not level then
        return true
    end
    return level.isPlayerOutOfRangeManual
end
function canPlayerEnterFacMode()
    local level = PhaseManager.m_openedPhaseSet[PhaseId.Level]
    if not level then
        return false
    end
    return not (level.isPlayerOutOfRangeManual or GameInstance.world.battle.isSquadInFight)
end
function clampTopViewCamTargetPosition(worldPos, curWorldPos)
    local level = PhaseManager.m_openedPhaseSet[PhaseId.Level]
    if not level then
        return curWorldPos
    end
    local rect
    if level.customFacTopViewRangeInWorld then
        local mainCamera = CameraManager.mainCamera
        local dist = (mainCamera.transform.position - LuaSystemManager.facSystem.topViewCamTarget.position).y
        rect = level.customFacTopViewRangeInWorld
        local yPadding = math.min(dist * math.tan(mainCamera.fieldOfView / 2 * math.pi / 180), rect.height / 2)
        local xPadding = math.min(yPadding / Screen.height * Screen.width, rect.width / 2)
        rect = Unity.Rect(rect.x + xPadding, rect.y + yPadding, math.max(0, rect.width - xPadding * 2), math.max(0, rect.height - yPadding * 2))
    else
        rect = level.mainRegionLocalRectWithMovePadding
    end
    if not rect then
        return curWorldPos
    end
    local regionTransform, localPos, curLocalPos
    if not level.customFacTopViewRangeInWorld then
        regionTransform = GameInstance.remoteFactoryManager.gameWorldAgent:GetRegionRootTransform()
        localPos = regionTransform:InverseTransformPoint(worldPos)
        curLocalPos = regionTransform:InverseTransformPoint(curWorldPos)
    else
        localPos = worldPos
        curLocalPos = curWorldPos
    end
    if rect:Contains(localPos:XZ()) then
        return worldPos
    else
        local xMin, xMax, yMin, yMax
        if curWorldPos then
            xMin = math.min(rect.xMin, curLocalPos.x)
            xMax = math.max(rect.xMax, curLocalPos.x)
            yMin = math.min(rect.yMin, curLocalPos.z)
            yMax = math.max(rect.yMax, curLocalPos.z)
        else
            xMin = rect.xMin
            xMax = rect.xMax
            yMin = rect.yMin
            yMax = rect.yMax
        end
        localPos.x = lume.clamp(localPos.x, xMin, xMax)
        localPos.z = lume.clamp(localPos.z, yMin, yMax)
        if regionTransform then
            return regionTransform:TransformPoint(localPos)
        else
            return localPos
        end
    end
end
function gameEventFactoryItemPush(nodeId, itemId, count, curItems)
    local buildingNode = getBuildingNodeHandler(nodeId)
    local worldPos = GameInstance.remoteFactoryManager.visual:BuildingGridToWorld(Vector2(buildingNode.transform.position.x, buildingNode.transform.position.z))
    EventLogManagerInst:GameEvent_FactoryItemPush(buildingNode.nodeId, buildingNode.templateId, GameInstance.remoteFactoryManager.currentSceneName, worldPos, itemId, count, curItems)
end
function getBuildingPortState(nodeId, isPipePort)
    if nodeId <= 0 then
        return
    end
    local facManager = GameInstance.remoteFactoryManager
    local success, complexPortFragment = facManager:TrySamplePortInfo(Utils.getCurrentChapterId(), nodeId)
    if not success then
        return
    end
    local inPortInfoList, outPortInfoList = {}, {}
    for index = 0, complexPortFragment.ports.length - 1 do
        local portData = complexPortFragment.ports:GetValue(index)
        if portData.valid and portData.isPipe == isPipePort then
            local infoList = portData.isInput and inPortInfoList or outPortInfoList
            table.insert(infoList, { index = portData.idx, touchCompId = portData.touchComId, touchNodeId = portData.touchNodeId, isBinding = portData.touchNodeId > 0, isBlock = portData.isBlock, })
        end
    end
    local sortFunc = Utils.genSortFunction({ "index" }, true)
    table.sort(inPortInfoList, sortFunc)
    table.sort(outPortInfoList, sortFunc)
    return inPortInfoList, outPortInfoList
end
function getBuildingTypeByBuildingId(buildingId)
    local success, buildingData = Tables.factoryBuildingTable:TryGetValue(buildingId)
    if not success then
        return GEnums.FacBuildingType.Empty
    end
    return buildingData.type
end
function getBuildingProcessingCraft(buildingInfo)
    if buildingInfo == nil then
        return nil
    end
    local buildingType = getBuildingTypeByBuildingId(buildingInfo.buildingId)
    local crafts = getBuildingCraftsWithNodeId(buildingInfo.nodeId, true)
    if crafts == nil then
        return nil
    end
    if buildingType == GEnums.FacBuildingType.PowerStation then
        for _, craftInfo in pairs(crafts) do
            if craftInfo.incomes ~= nil and craftInfo.incomes[1].id == buildingInfo.burningItemId then
                return craftInfo
            end
        end
    elseif buildingType == GEnums.FacBuildingType.Miner then
        local collectItemId = buildingInfo.collectingItemId
        if string.isEmpty(collectItemId) and buildingInfo.mineData ~= nil then
            collectItemId = buildingInfo.mineData.itemId
        end
        for _, craftInfo in pairs(crafts) do
            if craftInfo.outcomes ~= nil and craftInfo.outcomes[1].id == collectItemId then
                return craftInfo
            end
        end
    elseif buildingType == GEnums.FacBuildingType.FluidPumpIn then
        for _, craftInfo in pairs(crafts) do
            if craftInfo.outcomes ~= nil and craftInfo.outcomes[1].id == buildingInfo.collectingItemId then
                return craftInfo
            end
        end
    elseif buildingType == GEnums.FacBuildingType.FluidConsume then
        local consumeId = buildingInfo.consumeItemId
        for _, craftInfo in pairs(crafts) do
            if craftInfo.incomes ~= nil and craftInfo.incomes[1].id == consumeId then
                return craftInfo
            end
        end
    else
        for _, craftInfo in pairs(crafts) do
            if craftInfo.craftId == buildingInfo.formulaId or craftInfo.craftId == buildingInfo.lastFormulaId then
                return craftInfo
            end
        end
    end
    return nil
end
function getMachineCraftLockFormulaId(nodeId)
    local node = FactoryUtils.getBuildingNodeHandler(nodeId)
    if node == nil then
        return ""
    end
    local pdp = node.predefinedParam
    if pdp == nil then
        return ""
    end
    local producer = pdp.producer
    if producer == nil then
        return ""
    end
    return producer.lockFormulaId
end
function isEquipFormulaUnlocked(formulaId)
    return GameInstance.player.equipTechSystem:IsFormulaUnlock(formulaId)
end
function isSpMachineFormulaUnlocked(formulaId)
    return GameInstance.player.facSpMachineSystem:IsCraftUnlocked(formulaId)
end
function isItemInfiniteInFactoryDepot(itemId)
    local factoryDepot = GameInstance.player.inventory.factoryDepot
    if factoryDepot == nil then
        return false
    end
    local depotInChapter = factoryDepot:GetOrFallback(Utils.getCurrentScope())
    if depotInChapter == nil then
        return false
    end
    local actualDepot = depotInChapter[Utils.getCurrentChapterId()]
    if actualDepot == nil then
        return false
    end
    local success, isInfinite = actualDepot.infiniteItemIds:TryGetValue(itemId)
    if success == false then
        return false
    end
    return isInfinite
end
function isBuildingInventoryLocked(nodeId)
    local node = FactoryUtils.getBuildingNodeHandler(nodeId)
    if node == nil then
        return false
    end
    local pdp = node.predefinedParam
    if pdp == nil then
        return false
    end
    local cache, gridBox = pdp.cache, pdp.gridBox
    if cache ~= nil then
        return cache.lockManualInOut
    end
    if gridBox ~= nil then
        return gridBox.lockManualInOut
    end
    return false
end
function getLogisticData(templateId)
    local _, data
    do
        _, data = Tables.factoryGridConnecterTable:TryGetValue(templateId)
        if not data then
            _, data = Tables.factoryGridRouterTable:TryGetValue(templateId)
        end
        if data then
            return data.gridUnitData, false
        end
    end
    do
        _, data = Tables.factoryLiquidRouterTable:TryGetValue(templateId)
        if not data then
            _, data = Tables.factoryLiquidConnectorTable:TryGetValue(templateId)
        end
        if not data then
            _, data = Tables.factoryLiquidRepeaterTable:TryGetValue(templateId)
        end
        if data then
            return data.liquidUnitData, true
        end
    end
    logger.error("No LogisticData", templateId)
end
function isFactoryItemFluid(itemId)
    local success, factoryItemData = Tables.factoryItemTable:TryGetValue(itemId)
    if success == false then
        return false
    end
    return factoryItemData.itemState
end
function getMachineCraftCacheLayoutData(nodeId)
    local nodeHandler = getBuildingNodeHandler(nodeId)
    if nodeHandler == nil then
        return nil
    end
    local groupData = getMachineCraftGroupDataFromNodeHandler(nodeHandler)
    local crafts = getBuildingCraftsWithNodeId(nodeId, true, false)
    if groupData == nil or crafts == nil or #crafts == 0 then
        return nil
    end
    local layoutData = {}
    layoutData.normalIncomeCaches = {}
    layoutData.fluidIncomeCaches = {}
    layoutData.normalOutcomeCaches = {}
    layoutData.fluidOutcomeCaches = {}
    local firstCraft = crafts[1]
    for _, income in ipairs(firstCraft.incomes) do
        local itemId = income.id
        local cacheData = isFactoryItemFluid(itemId) and layoutData.fluidIncomeCaches or layoutData.normalIncomeCaches
        local bufferId = LuaIndex(income.buffer)
        if cacheData[bufferId] == nil then
            local data = { slotCount = 1, }
            cacheData[bufferId] = data
        else
            local slotCount = cacheData[bufferId].slotCount
            cacheData[bufferId].slotCount = slotCount + 1
        end
    end
    for _, outcome in ipairs(firstCraft.outcomes) do
        local itemId = outcome.id
        local cacheData = isFactoryItemFluid(itemId) and layoutData.fluidOutcomeCaches or layoutData.normalOutcomeCaches
        local bufferId = LuaIndex(outcome.buffer)
        if cacheData[bufferId] == nil then
            local data = { slotCount = 1, }
            cacheData[bufferId] = data
        else
            local slotCount = cacheData[bufferId].slotCount
            cacheData[bufferId].slotCount = slotCount + 1
        end
    end
    local bindingCollector = function(bindingDataList, caches)
        if caches == nil or #caches == 0 then
            return
        end
        for index = 0, bindingDataList.Count - 1 do
            local cacheData = caches[LuaIndex(index)]
            if cacheData == nil then
                logger.error("配方道具数据与建筑数据不匹配")
                return
            end
            local bindingData = bindingDataList[index]
            cacheData.portCount = bindingData.bindingPortIndices.Count
            cacheData.ports = bindingData.bindingPortIndices
        end
    end
    bindingCollector(groupData.ingredientBufferBinding, layoutData.normalIncomeCaches)
    bindingCollector(groupData.outcomeBufferBinding, layoutData.normalOutcomeCaches)
    bindingCollector(groupData.pipeIngredientBufferBinding, layoutData.fluidIncomeCaches)
    bindingCollector(groupData.pipeOutcomeBufferBinding, layoutData.fluidOutcomeCaches)
    return layoutData
end
function getNodeWorldPos(nodeId)
    local buildingNode = getBuildingNodeHandler(nodeId)
    local worldPos = CSFactoryUtil.GetBuildingModelPosition(buildingNode)
    return worldPos
end
local EvtRendererClass = CS.Beyond.Gameplay.Factory.EvtLogisticFigureRenderer
function stopLogisticFigureRenderer()
    changeLogisticFigureRenderer(EvtRendererClass.S_NONE)
end
function startBeltFigureRenderer()
    changeLogisticFigureRenderer(EvtRendererClass.S_CONVEYOR)
end
function startPipeFigureRenderer()
    changeLogisticFigureRenderer(EvtRendererClass.S_PIPE)
end
function changeLogisticFigureRenderer(figureBit)
    GameInstance.remoteFactoryManager:ToggleLogisticFigure(figureBit)
end
function isBeltInSimpleFigure()
    return GameInstance.remoteFactoryManager:IsConveyorInSimpleFigure()
end
function isPipeInSimpleFigure()
    return GameInstance.remoteFactoryManager:IsPipeInSimpleFigure()
end
function updateFacTechTreeTechPointNode(view, facTechPackageId)
    local packageData = Tables.facSTTGroupTable[facTechPackageId]
    local costPointCfg = Tables.itemTable[packageData.costPointType]
    view.textResourceName.text = costPointCfg.name
    view.textResourceNumber.text = Utils.getItemCount(packageData.costPointType)
    local showTips = function()
        Notify(MessageConst.SHOW_ITEM_TIPS, { itemId = packageData.costPointType, transform = view.imgIcon.transform, posType = UIConst.UI_TIPS_POS_TYPE.LeftTop, })
    end
    view.imgIcon:LoadSprite(UIConst.UI_SPRITE_ITEM, packageData.costPointType)
    view.imgIconButton.onClick:AddListener(function()
        showTips()
    end)
    if view.imgBg then
        view.imgBg.onClick:AddListener(function()
            showTips()
        end)
    end
end
function updateFacTechTreeTechPointCount(view, facTechPackageId)
    local packageData = Tables.facSTTGroupTable[facTechPackageId]
    view.textResourceNumber.text = Utils.getItemCount(packageData.costPointType)
end
function getBlackboxInfoTbl(blackboxIds)
    local relativeBlackboxes = {}
    local mapManager = GameInstance.player.mapManager
    local dungeonManager = GameInstance.dungeonManager
    for _, blackboxId in pairs(blackboxIds) do
        local blackboxCfg = Tables.dungeonTable[blackboxId]
        local mapMgr = GameInstance.player.mapManager
        local _, instId = mapMgr:GetMapMarkInstId(GEnums.MarkType.BlackBox, blackboxCfg.dungeonSeriesId)
        local relativeBlackbox = {}
        local isComplete = dungeonManager:IsDungeonPassed(blackboxId)
        local isActive = dungeonManager:IsDungeonActive(blackboxId)
        local isUnlock = DungeonUtils.isDungeonUnlock(blackboxId)
        relativeBlackbox.blackboxId = blackboxId
        relativeBlackbox.isComplete = isComplete
        relativeBlackbox.isActive = isActive
        relativeBlackbox.isUnlock = isUnlock
        relativeBlackbox.name = isActive and blackboxCfg.dungeonName or Language.LUA_FAC_TECH_TREE_BLACK_BOX_TBD
        relativeBlackbox.markInstId = instId
        relativeBlackbox.dungeonSeriesId = blackboxCfg.dungeonSeriesId
        relativeBlackbox.completeSortId = isComplete and 1 or 0
        relativeBlackbox.activeSortId = isActive and 0 or 1
        relativeBlackbox.unlockSortId = isUnlock and 0 or 1
        local blackboxSeriesCfg = Tables.dungeonSeriesTable[blackboxCfg.dungeonSeriesId]
        relativeBlackbox.sortId = blackboxSeriesCfg.sortId
        table.insert(relativeBlackboxes, relativeBlackbox)
    end
    table.sort(relativeBlackboxes, Utils.genSortFunction({ "completeSortId", "activeSortId", "unlockSortId", "sortId" }, true))
    return relativeBlackboxes
end
function genFilterBlackboxArgs(packageName, onFilterConfirmFunc)
    local filter = {}
    filter.tagGroups = {}
    local layerFilter = {}
    layerFilter.title = Language.LUA_FAC_TECH_TREE_BLACKBOX_LIST_FILTER_LAYER_DESC
    layerFilter.tags = {}
    for layerId, layerCfg in pairs(Tables.facSTTLayerTable) do
        if layerCfg.groupId == packageName then
            table.insert(layerFilter.tags, { layerId = layerId, name = layerCfg.name, order = layerCfg.order, })
        end
    end
    table.sort(layerFilter.tags, Utils.genSortFunction({ "order" }, true))
    table.insert(filter.tagGroups, layerFilter)
    local categoryFilter = {}
    categoryFilter.title = Language.LUA_FAC_TECH_TREE_BLACKBOX_LIST_FILTER_CATEGORY_DESC
    categoryFilter.tags = {}
    for categoryId, categoryCfg in pairs(Tables.facSTTCategoryTable) do
        if categoryCfg.groupId == packageName then
            table.insert(categoryFilter.tags, { categoryId = categoryId, name = categoryCfg.name, order = categoryCfg.order, })
        end
    end
    table.sort(categoryFilter.tags, Utils.genSortFunction({ "order" }, true))
    table.insert(filter.tagGroups, categoryFilter)
    local completeFilter = {}
    completeFilter.title = Language.LUA_FAC_TECH_TREE_BLACKBOX_LIST_FILTER_IS_COMPLETE_DESC
    completeFilter.tags = { { name = Language.LUA_FAC_TECH_TREE_BLACKBOX_LIST_FILTER_STATE_UN_DESC, completeState = false }, { name = Language.LUA_FAC_TECH_TREE_BLACKBOX_LIST_FILTER_STATE_COMPLETE_DESC, completeState = true } }
    table.insert(filter.tagGroups, completeFilter)
    filter.onConfirm = function(selectedTags)
        onFilterConfirmFunc(selectedTags)
    end
    filter.getResultCount = function(selectedTags)
        local ids = FactoryUtils.getFilterBlackboxIds(packageName, selectedTags)
        return #ids
    end
    return filter
end
function getFilterBlackboxIds(packageName, selectedTags)
    local blackboxIds = {}
    for _, nodeData in pairs(Tables.facSTTNodeTable) do
        if nodeData.groupId == packageName and nodeData.blackboxIds.Count > 0 then
            for _, blackboxId in pairs(nodeData.blackboxIds) do
                local layerMatch = true
                local categoryMatch = true
                local completeMatch = true
                for _, tag in ipairs(selectedTags) do
                    if tag.layerId ~= nil then
                        layerMatch = false
                    end
                    if tag.categoryId ~= nil then
                        categoryMatch = false
                    end
                    if tag.completeState ~= nil then
                        completeMatch = false
                    end
                end
                for _, tag in ipairs(selectedTags) do
                    layerMatch = layerMatch or nodeData.layer == tag.layerId
                    categoryMatch = categoryMatch or nodeData.category == tag.categoryId
                    completeMatch = completeMatch or GameInstance.dungeonManager:IsDungeonPassed(blackboxId) == tag.completeState
                end
                if layerMatch and categoryMatch and completeMatch and not lume.find(blackboxIds, blackboxId) then
                    table.insert(blackboxIds, blackboxId)
                end
            end
        end
    end
    return blackboxIds
end
function enterFacCamera(stateName)
    return GameAction.AddCameraControlState(stateName)
end
function exitFacCamera(state)
    GameAction.RemoveCameraControlState(state)
end
function getCurOpenedBuildingId()
    local machine = PhaseManager.m_openedPhaseSet[PhaseId.PhaseFacMachine]
    if not machine then
        return true
    end
    return machine.m_panelBuildingDataId
end
function canShowPipe()
    return GameInstance.remoteFactoryManager.unlockSystem.systemUnlockedPipe and isDomainSupportPipe()
end
function isDomainSupportPipe()
    return CSFactoryUtil.IsCurDomainSupportPipe()
end
function getCraftTimeStr(time)
    if time == nil then
        return ""
    end
    local floorTime = math.floor(time)
    if floorTime == time then
        return tostring(floorTime)
    else
        return string.format("%.1f", time)
    end
end