local Config = {
    NormalItem = {
        msgs = { MessageConst.ON_READ_NEW_ITEM, },
        readLike = true,
        needArg = true,
        Check = function(id)
            return GameInstance.player.inventory:IsNewItem(id), UIConst.RED_DOT_TYPE.New
        end,
    },
    InstItem = {
        msgs = { MessageConst.ON_READ_NEW_INST_ITEM, },
        readLike = true,
        needArg = true,
        Check = function(info)
            return GameInstance.player.inventory:IsNewItem(info.id, info.instId), UIConst.RED_DOT_TYPE.New
        end,
    },
    BlocShopDiscountShopItem = {
        msgs = { MessageConst.ON_BUY_ITEM_SUCC, MessageConst.ON_SYNC_ALL_BLOC, },
        readLike = false,
        needArg = true,
        Check = function(blocId)
            return RedDotUtils.hasBlocShopDiscountShopItem(blocId)
        end
    },
    WeaponEmptyGem = {
        msgs = { MessageConst.ON_GEM_DETACH, MessageConst.ON_GEM_ATTACH, },
        readLike = true,
        needArg = true,
        Check = function(weaponInstId)
            local weaponInst = CharInfoUtils.getWeaponByInstId(weaponInstId)
            if weaponInst.attachedGemInstId > 0 then
                return false
            end
            return RedDotUtils.hasGemNotEquipped()
        end
    },
    WeaponCanUpgrade = {
        msgs = { MessageConst.ON_WEAPON_GAIN_EXP, MessageConst.ON_WEAPON_BREAKTHROUGH, },
        readLike = true,
        needArg = true,
        Check = function(weaponInstId)
            return WeaponUtils.canWeaponBreakthrough(weaponInstId) or WeaponUtils.canWeaponUpgrade(weaponInstId)
        end
    },
    Formula = {
        msgs = { MessageConst.ON_ADD_NEW_UNREAD_FORMULA, MessageConst.ON_READ_FORMULA, },
        readLike = true,
        needArg = true,
        Check = function(formulaId)
            return GameInstance.player.remoteFactory.core:IsFormulaUnread(formulaId), UIConst.RED_DOT_TYPE.New
        end,
    },
    BuildingFormula = {
        sons = { Formula = false, },
        readLike = false,
        needArg = true,
        Check = function(arg)
            local buildingId = arg.buildingId
            local modeName = arg.modeName
            local core = GameInstance.player.remoteFactory.core
            local bData = Tables.factoryBuildingTable:GetValue(buildingId)
            local bType = bData.type
            if bType == GEnums.FacBuildingType.MachineCrafter or bType == GEnums.FacBuildingType.FluidReaction then
                local machineCrafterData = FactoryUtils.getMachineCraftGroupData(buildingId, modeName)
                for _, craftId in pairs(machineCrafterData.craftList) do
                    if core:IsFormulaUnread(craftId) then
                        return true, UIConst.RED_DOT_TYPE.Normal
                    end
                end
            end
            return false
        end,
    },
    TechTree = {
        msgs = { MessageConst.ON_UNLOCK_FAC_TECH_PACKAGE, MessageConst.ON_UNHIDDEN_FAC_TECH_PACKAGE, MessageConst.ON_CHANGE_SPACESHIP_DOMAIN_ID, },
        readLike = false,
        needArg = false,
        Check = function()
            local levelId = GameInstance.world.curLevelId
            if string.isEmpty(levelId) then
                logger.warn("RedDotConfig->TechTree Check->levelId is None")
                return false
            end
            local _, levelBasicInfo = DataManager.levelBasicInfoTable:TryGetValue(levelId)
            local isInSpaceShip = Utils.isInSpaceShip()
            local domainId = isInSpaceShip and GameInstance.player.inventory.spaceshipDomainId or levelBasicInfo.domainName
            local hasDomain, domainCfg = Tables.domainDataTable:TryGetValue(domainId)
            if not hasDomain then
                return false
            end
            local facTechPackageId = domainCfg.facTechPackageId
            local techTreeSystem = GameInstance.player.facTechTreeSystem
            if techTreeSystem:PackageIsHidden(facTechPackageId) then
                return false
            end
            if techTreeSystem:PackageIsLocked(facTechPackageId) then
                return false
            end
            for techId, techNode in pairs(Tables.facSTTNodeTable) do
                if techNode.groupId == facTechPackageId then
                    local groupState = RedDotManager:GetRedDotState("TechTreeNode", techId)
                    if groupState then
                        return true, UIConst.RED_DOT_TYPE.Normal
                    end
                end
            end
            local blackboxEntryState = RedDotManager:GetRedDotState("BlackboxEntry", facTechPackageId)
            if blackboxEntryState then
                return true, UIConst.RED_DOT_TYPE.Normal
            end
            return false
        end,
        sons = { TechTreeNode = false, BlackboxEntry = false, }
    },
    TechTreeNode = {
        msgs = { MessageConst.FAC_ON_REFRESH_TECH_TREE_UI, MessageConst.ON_ITEM_COUNT_CHANGED, },
        readLike = false,
        needArg = true,
        Check = function(techId)
            local techTreeSystem = GameInstance.player.facTechTreeSystem
            local nodeData = Tables.facSTTNodeTable:GetValue(techId)
            if not techTreeSystem:NodeIsLocked(techId) then
                return false
            end
            if techTreeSystem:PreNodeIsLocked(techId) then
                return false
            end
            if techTreeSystem:LayerIsLocked(nodeData.layer) then
                return false
            end
            local isMatchCondition = true
            if nodeData.conditions.Count > 0 then
                for i = 1, nodeData.conditions.Count do
                    if not techTreeSystem:GetConditionIsCompleted(techId, nodeData.conditions[CSIndex(i)].conditionId) then
                        isMatchCondition = false
                        break
                    end
                end
            end
            if not isMatchCondition then
                return false
            end
            local isEnough = Utils.getItemCount(Tables.facSTTGroupTable[nodeData.groupId].costPointType) >= nodeData.costPointCount
            if not isEnough then
                return false
            end
            if not isEnough then
                return false
            end
            return true, UIConst.RED_DOT_TYPE.Normal
        end
    },
    BlackboxPreDependencies = {
        readLike = true,
        needArg = true,
        Check = function(blackboxIds)
            for _, blackboxId in pairs(blackboxIds) do
                if not GameInstance.dungeonManager:IsDungeonPassed(blackboxId) then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end,
        sons = { BlackboxSelectionCellPassed = false, }
    },
    BlackboxSelectionCellPassed = {
        msgs = {},
        readLike = true,
        needArg = true,
        Check = function(blackboxId)
            if not GameInstance.dungeonManager:IsDungeonPassed(blackboxId) then
                return true, UIConst.RED_DOT_TYPE.Normal
            end
            return false
        end
    },
    BlackboxEntry = {
        readLike = false,
        needArg = true,
        Check = function(packageId)
            local packageCfg = Tables.facSTTGroupTable[packageId]
            for _, blackboxId in pairs(packageCfg.blackboxIds) do
                local hasReadDotState = RedDotManager:GetRedDotState("BlackboxSelectionCellRead", blackboxId)
                if hasReadDotState then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end,
        sons = { BlackboxSelectionCellRead = false, },
    },
    BlackboxSelectionCellRead = {
        msgs = { MessageConst.ON_BLACKBOX_ACTIVE, MessageConst.ON_BLACKBOX_READ, },
        readLike = true,
        needArg = true,
        Check = function(blackboxId)
            local dungeonMgr = GameInstance.dungeonManager
            if not dungeonMgr:IsDungeonActive(blackboxId) then
                return false
            end
            if dungeonMgr:IsBlackboxRead(blackboxId) then
                return false
            end
            return true, UIConst.RED_DOT_TYPE.New
        end
    },
    MainHudExpand = { sons = {}, needArg = false, readLike = false, },
    SingleMail = {
        msgs = { MessageConst.ON_ALL_MAIL_INITED, MessageConst.ON_READ_MAIL, MessageConst.ON_GET_MAIL_ATTACHMENT, MessageConst.ON_GET_NEW_MAILS, },
        readLike = true,
        needArg = true,
        Check = function(mailId)
            local mailSys = GameInstance.player.mail
            if not mailSys:IsAllMailInited() then
                return false
            end
            local mail = mailSys.mails[mailId]
            if mail.isExpired then
                return false
            end
            if not mail.isRead then
                return true, UIConst.RED_DOT_TYPE.New
            end
            if not mail.collected then
                return true, UIConst.RED_DOT_TYPE.Normal
            end
            return false
        end,
    },
    MailTab = {
        sons = { SingleMail = false, },
        readLike = false,
        needArg = false,
        Check = function()
            local mailSys = GameInstance.player.mail
            if not mailSys:IsAllMailInited() then
                return false
            end
            for _, mail in pairs(mailSys.mails) do
                if (not mail.isExpired) and (not mail.collected or not mail.isRead) then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end,
    },
    MailTabGetAllBtn = {
        sons = { SingleMail = false, },
        readLike = false,
        needArg = false,
        Check = function()
            local mailSys = GameInstance.player.mail
            if not mailSys:IsAllMailInited() then
                return false
            end
            for _, mail in pairs(mailSys.mails) do
                if (not mail.isExpired) and (not mail.collected) then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end,
    },
    Mail = {
        sons = { SingleMail = false, LostAndFoundBtn = false, },
        readLike = false,
        needArg = false,
        Check = function()
            local hasRedDot = GameInstance.player.mail:HasNewMail() or not GameInstance.player.inventory.lostAndFound:IsEmpty()
            return hasRedDot, UIConst.RED_DOT_TYPE.Normal
        end,
    },
    LostAndFoundBtn = {
        msgs = { MessageConst.ON_GET_LOST_AND_FOUND, MessageConst.ON_ADD_LOST_AND_FOUND, },
        Check = function()
            return not GameInstance.player.inventory.lostAndFound:IsEmpty(), UIConst.RED_DOT_TYPE.Normal
        end,
        needArg = false,
        readLike = false,
    },
    Gacha = {
        msgs = {},
        Check = function()
            return false
        end,
        needArg = false,
        readLike = false,
    },
    PRTSReading = {
        msgs = { MessageConst.ON_PRTS_TERMINAL_READ, },
        readLike = true,
        needArg = true,
        Check = function(uniqId)
            return not GameInstance.player.prts.prtsTerminalContentSet:Contains(uniqId), UIConst.RED_DOT_TYPE.Normal
        end
    },
    PRTSWatch = {
        readLike = false,
        needArg = false,
        Check = function()
            local prtsSys = GameInstance.player.prts
            for id, _ in pairs(Tables.prtsInvestigate) do
                if not prtsSys:IsInvestigateFinished(id) and prtsSys:IsInvestigateCanFinish(id) then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end,
        sons = { PRTSDocument = false, PRTSText = false, PRTSMultimedia = false, PRTSInvestigateTab = false, },
    },
    PRTSDocument = {
        readLike = false,
        needArg = false,
        Check = function()
            local unlockSet = GameInstance.player.prts.prtsUnlockSet
            local unreadSet = GameInstance.player.prts.prtsUnReadSet
            for _, unreadId in pairs(unreadSet) do
                if unlockSet:Contains(unreadId) and Tables.prtsDocument:ContainsKey(unreadId) then
                    return true, UIConst.RED_DOT_TYPE.New
                end
            end
            return false
        end,
        sons = { PRTSItem = false },
    },
    PRTSText = {
        readLike = false,
        needArg = false,
        Check = function()
            local unlockSet = GameInstance.player.prts.prtsUnlockSet
            local unreadSet = GameInstance.player.prts.prtsUnReadSet
            for _, unreadId in pairs(unreadSet) do
                if unlockSet:Contains(unreadId) and Tables.prtsRecord:ContainsKey(unreadId) then
                    return true, UIConst.RED_DOT_TYPE.New
                end
            end
            return false
        end,
        sons = { PRTSItem = false },
    },
    PRTSStoryCollCategory = {
        readLike = false,
        needArg = true,
        Check = function(categoryId)
            local unreadSet = GameInstance.player.prts.prtsUnReadSet
            local prtsSystem = GameInstance.player.prts
            for _, unreadId in pairs(unreadSet) do
                local id = prtsSystem:GetCategoryIdByPrtsId(unreadId)
                if categoryId == id then
                    return true, UIConst.RED_DOT_TYPE.New
                end
            end
            return false
        end,
        sons = { PRTSItem = false },
    },
    PRTSMultimedia = {
        readLike = false,
        needArg = false,
        Check = function()
            local unlockSet = GameInstance.player.prts.prtsUnlockSet
            local unreadSet = GameInstance.player.prts.prtsUnReadSet
            for _, unreadId in pairs(unreadSet) do
                if unlockSet:Contains(unreadId) and Tables.prtsMultimedia:ContainsKey(unreadId) then
                    return true, UIConst.RED_DOT_TYPE.New
                end
            end
            return false
        end,
        sons = { PRTSItem = false },
    },
    PRTSFirstLv = {
        readLike = false,
        needArg = true,
        Check = function(firstLvId)
            local unreadSet = GameInstance.player.prts.prtsUnReadSet
            for _, unreadId in pairs(unreadSet) do
                local _, prtsData = Tables.prtsAllItem:TryGetValue(unreadId)
                if prtsData and prtsData.firstLvId == firstLvId then
                    return true, UIConst.RED_DOT_TYPE.New
                end
            end
            return false
        end,
        sons = { PRTSItem = false },
    },
    PRTSItem = {
        msgs = { MessageConst.ON_UNREAD_PRTS, MessageConst.ON_READ_PRTS, },
        readLike = false,
        needArg = true,
        Check = function(prtsId)
            local unlockSet = GameInstance.player.prts.prtsUnlockSet
            local unreadSet = GameInstance.player.prts.prtsUnReadSet
            if unlockSet:Contains(prtsId) and unreadSet:Contains(prtsId) then
                return true, UIConst.RED_DOT_TYPE.New
            end
            return false
        end,
    },
    PRTSInvestigateTab = {
        readLike = true,
        needArg = false,
        Check = function()
            local prtsSys = GameInstance.player.prts
            local hasUnread = false
            for investId, _ in pairs(Tables.prtsInvestigate) do
                local cfg = Utils.tryGetTableCfg(Tables.prtsInvestigate, investId)
                if cfg then
                    local isFinished = prtsSys:IsInvestigateFinished(investId)
                    if isFinished then
                        if not hasUnread then
                            for _, collId in pairs(cfg.collectionIdList) do
                                if prtsSys:IsPrtsUnread(collId) then
                                    hasUnread = true
                                    break;
                                end
                            end
                            if not hasUnread and RedDotUtils.hasPrtsNoteRedDot(cfg) then
                                hasUnread = true
                            end
                        end
                    else
                        local unlockCount = 0
                        for _, collId in pairs(cfg.collectionIdList) do
                            unlockCount = prtsSys:IsPrtsUnlocked(collId) and unlockCount + 1 or unlockCount
                            if prtsSys:IsPrtsUnread(collId) then
                                hasUnread = true
                            end
                        end
                        if unlockCount >= cfg.collectionIdList.Count then
                            return true, UIConst.RED_DOT_TYPE.Normal
                        end
                        if not hasUnread and RedDotUtils.hasPrtsNoteRedDot(cfg) then
                            hasUnread = true
                        end
                    end
                end
            end
            if hasUnread then
                return true, UIConst.RED_DOT_TYPE.New
            end
            return false
        end,
        sons = { PRTSInvestigate = false, },
    },
    PRTSInvestigate = {
        msgs = { MessageConst.ON_INVESTIGATE_FINISHED, MessageConst.ON_READ_PRTS_NOTE_BATCH, MessageConst.ON_READ_PRTS, },
        readLike = true,
        needArg = true,
        Check = function(investId)
            local cfg = Utils.tryGetTableCfg(Tables.prtsInvestigate, investId)
            if not cfg then
                return false
            end
            local prtsSys = GameInstance.player.prts
            local isFinished = prtsSys:IsInvestigateFinished(investId)
            if isFinished then
                for _, collId in pairs(cfg.collectionIdList) do
                    if prtsSys:IsPrtsUnread(collId) then
                        return true, UIConst.RED_DOT_TYPE.New
                    end
                end
                if RedDotUtils.hasPrtsNoteRedDot(cfg) then
                    return true, UIConst.RED_DOT_TYPE.New
                end
            else
                local unlockCount = 0
                local hasUnread = false
                for _, collId in pairs(cfg.collectionIdList) do
                    unlockCount = prtsSys:IsPrtsUnlocked(collId) and unlockCount + 1 or unlockCount
                    if prtsSys:IsPrtsUnread(collId) then
                        hasUnread = true
                    end
                end
                if unlockCount >= cfg.collectionIdList.Count then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
                if hasUnread then
                    return true, UIConst.RED_DOT_TYPE.New
                end
                if RedDotUtils.hasPrtsNoteRedDot(cfg) then
                    return true, UIConst.RED_DOT_TYPE.New
                end
            end
            return false
        end,
        sons = { PRTSItem = false, },
    },
    PRTSNote = {
        msgs = { MessageConst.ON_READ_PRTS_NOTE_BATCH, MessageConst.ON_UNREAD_PRTS_NOTE_BATCH, },
        readLike = true,
        needArg = true,
        Check = function(noteId)
            local prtsSys = GameInstance.player.prts
            if prtsSys:IsNoteUnread(noteId) then
                return true, UIConst.RED_DOT_TYPE.New
            end
            return false
        end,
    },
    AllCharInfo = {
        readLike = false,
        needArg = false,
        Check = function()
            local isFullLockedTeam = CharInfoUtils.IsFullLockedTeam()
            if isFullLockedTeam then
                return false
            end
            local charBag = GameInstance.player.charBag
            if charBag.newCharListSet.Count > 0 then
                return true, UIConst.RED_DOT_TYPE.Normal
            end
            for charInstId, charInfo in pairs(charBag.charInfos) do
                if charInfo.charType == GEnums.CharType.Default and RedDotManager:GetRedDotState("CharInfoPotential", charInstId) then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end,
        sons = { CharNew = false, CharInfoPotential = false, },
    },
    CharInfo = {
        msgs = { MessageConst.ON_SYSTEM_UNLOCK, },
        readLike = false,
        needArg = true,
        Check = function(charInstId)
            local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
            if charInst.charType == GEnums.CharType.Trial then
                return false
            end
            if RedDotManager:GetRedDotState("CharNew", charInst.templateId) then
                return true, UIConst.RED_DOT_TYPE.New
            end
            if RedDotManager:GetRedDotState("CharInfoPotential", charInstId) then
                return true, UIConst.RED_DOT_TYPE.Normal
            end
            return false
        end,
        sons = { CharNew = false, CharInfoPotential = false, },
    },
    CharNew = {
        msgs = { MessageConst.ON_CHAR_NEW_TAG_CHANGED, },
        readLike = true,
        needArg = true,
        Check = function(templateId)
            local res = GameInstance.player.charBag:CheckCharIsNew(templateId)
            return res, UIConst.RED_DOT_TYPE.New
        end,
    },
    CharBreak = {
        readLike = false,
        needArg = true,
        Check = function(charInstId)
            local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
            if charInst.charType == GEnums.CharType.Trial then
                return false
            end
            for nodeId, nodeData in pairs(Tables.charBreakNodeTable) do
                if nodeData.talentNodeType == GEnums.TalentNodeType.CharBreak then
                    if nodeData.breakStage == charInst.breakStage + 1 and nodeData.equipTierLimit <= charInst.equipTierLimit then
                        local _, breakStageData = Tables.charBreakStageTable:TryGetValue(nodeData.breakStage)
                        if breakStageData and breakStageData.minCharLevel <= charInst.level and CharInfoUtils.isCharBreakCostEnough(charInst.templateId, nodeId) then
                            return true, UIConst.RED_DOT_TYPE.Normal
                        end
                    end
                elseif nodeData.talentNodeType == GEnums.TalentNodeType.EquipBreak then
                    if nodeData.breakStage == charInst.breakStage and nodeId ~= charInst.talentInfo.latestBreakNode and CharInfoUtils.isCharBreakCostEnough(charInst.templateId, nodeId) then
                        return true, UIConst.RED_DOT_TYPE.Normal
                    end
                end
            end
            local _, charGrowthData = Tables.charGrowthTable:TryGetValue(charInst.templateId)
            if charGrowthData then
                local passiveSkillNodeTable = {}
                local shipSkillNodeIndexTable = {}
                for nodeId, nodeData in pairs(charGrowthData.talentNodeMap) do
                    if nodeData.nodeType == GEnums.TalentNodeType.Attr then
                        if not charInst.talentInfo.attributeNodes:Contains(nodeId) and CSPlayerDataUtil.GetCharFriendship(charInstId) >= nodeData.attributeNodeInfo.favorability and charInst.breakStage >= nodeData.attributeNodeInfo.breakStage and CharInfoUtils.isCharTalentCostEnough(charInst.templateId, nodeId) then
                            return true, UIConst.RED_DOT_TYPE.Normal
                        end
                    elseif nodeData.nodeType == GEnums.TalentNodeType.PassiveSkill then
                        local index = nodeData.passiveSkillNodeInfo.index
                        local data = passiveSkillNodeTable[index]
                        if not data then
                            data = {}
                            passiveSkillNodeTable[index] = data
                        end
                        data[nodeData.passiveSkillNodeInfo.level] = nodeData
                    elseif nodeData.nodeType == GEnums.TalentNodeType.FactorySkill then
                        local index = nodeData.factorySkillNodeInfo.index
                        local data = shipSkillNodeIndexTable[index]
                        if not data then
                            data = {}
                            shipSkillNodeIndexTable[index] = data
                        end
                        data[nodeData.factorySkillNodeInfo.level] = nodeData
                    end
                end
                for _, nodeDataTable in pairs(passiveSkillNodeTable) do
                    local maxLv = #nodeDataTable
                    for i = maxLv, 1, -1 do
                        local nodeData = nodeDataTable[i]
                        if charInst.talentInfo.latestPassiveSkillNodes:Contains(nodeData.nodeId) then
                            break
                        end
                        local preNodeData = nodeDataTable[i - 1]
                        if charInst.breakStage >= nodeData.passiveSkillNodeInfo.breakStage and (preNodeData == nil or charInst.talentInfo.latestPassiveSkillNodes:Contains(preNodeData.nodeId)) and CharInfoUtils.isCharTalentCostEnough(charInst.templateId, nodeData.nodeId) then
                            return true, UIConst.RED_DOT_TYPE.Normal
                        end
                    end
                end
                for _, nodeDataTable in pairs(shipSkillNodeIndexTable) do
                    local maxLv = #nodeDataTable
                    for i = maxLv, 1, -1 do
                        local nodeData = nodeDataTable[i]
                        if charInst.talentInfo.latestFactorySkillNodes:Contains(nodeData.nodeId) then
                            break
                        end
                        local preNodeData = nodeDataTable[i - 1]
                        if charInst.breakStage >= nodeData.factorySkillNodeInfo.breakStage and (preNodeData == nil or charInst.talentInfo.latestFactorySkillNodes:Contains(preNodeData.nodeId)) and CharInfoUtils.isCharTalentCostEnough(charInst.templateId, nodeData.nodeId) then
                            return true, UIConst.RED_DOT_TYPE.Normal
                        end
                    end
                end
            end
            for _, skillGroupLevelInfo in pairs(charInst.skillGroupLevelInfoList) do
                if skillGroupLevelInfo.level < skillGroupLevelInfo.maxLevel then
                    if CharInfoUtils.isSkillGroupLevelUpCostEnough(charInst.templateId, skillGroupLevelInfo.skillGroupId, skillGroupLevelInfo.level + 1) then
                        return true, UIConst.RED_DOT_TYPE.Normal
                    end
                end
            end
            return false
        end,
        sons = { CharBreakNode = false, EquipBreakNode = false, CharAttrNode = false, PassiveSkillNode = false, ShipSkillNode = false, },
    },
    CharBreakNode = {
        msgs = { MessageConst.ON_ITEM_COUNT_CHANGED, MessageConst.ON_WALLET_CHANGED, MessageConst.ON_CHAR_LEVEL_UP, MessageConst.ON_CHAR_TALENT_UPGRADE, },
        readLike = false,
        needArg = true,
        Check = function(args)
            local charInstId, nodeId = unpack(args)
            local isActive, isLock = CharInfoUtils.getCharBreakNodeStatus(charInstId, nodeId)
            if isActive or isLock then
                return false
            end
            local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
            if charInst.charType == GEnums.CharType.Trial then
                return false
            end
            if not CharInfoUtils.isCharBreakCostEnough(charInst.templateId, nodeId) then
                return false
            end
            return true, UIConst.RED_DOT_TYPE.Normal
        end
    },
    EquipBreakNode = {
        msgs = { MessageConst.ON_ITEM_COUNT_CHANGED, MessageConst.ON_WALLET_CHANGED, MessageConst.ON_CHAR_LEVEL_UP, MessageConst.ON_CHAR_TALENT_UPGRADE, },
        readLike = false,
        needArg = true,
        Check = function(args)
            local charInstId, nodeId = unpack(args)
            local isActive, isLock = CharInfoUtils.getEquipBreakNodeStatus(charInstId, nodeId)
            if isActive or isLock then
                return false
            end
            local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
            if charInst.charType == GEnums.CharType.Trial then
                return false
            end
            if not CharInfoUtils.isCharBreakCostEnough(charInst.templateId, nodeId) then
                return false
            end
            return true, UIConst.RED_DOT_TYPE.Normal
        end
    },
    CharAttrNode = {
        msgs = { MessageConst.ON_ITEM_COUNT_CHANGED, MessageConst.ON_WALLET_CHANGED, MessageConst.ON_CHAR_TALENT_UPGRADE, },
        readLike = false,
        needArg = true,
        Check = function(args)
            local charInstId, nodeId = unpack(args)
            local isActive, isLock = CharInfoUtils.getAttributeNodeStatus(charInstId, nodeId)
            if isActive or isLock then
                return false
            end
            local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
            if charInst.charType == GEnums.CharType.Trial then
                return false
            end
            if not CharInfoUtils.isCharTalentCostEnough(charInst.templateId, nodeId) then
                return false
            end
            return true, UIConst.RED_DOT_TYPE.Normal
        end
    },
    PassiveSkillNode = {
        msgs = { MessageConst.ON_ITEM_COUNT_CHANGED, MessageConst.ON_WALLET_CHANGED, MessageConst.ON_CHAR_TALENT_UPGRADE, },
        readLike = false,
        needArg = true,
        Check = function(args)
            local charInstId, nodeId = unpack(args)
            local isActive, isLock = CharInfoUtils.getPassiveSkillNodeStatus(charInstId, nodeId)
            if isActive or isLock then
                return false
            end
            local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
            if charInst.charType == GEnums.CharType.Trial then
                return false
            end
            if not CharInfoUtils.isCharTalentCostEnough(charInst.templateId, nodeId) then
                return false
            end
            return true, UIConst.RED_DOT_TYPE.Normal
        end
    },
    ShipSkillNode = {
        msgs = { MessageConst.ON_ITEM_COUNT_CHANGED, MessageConst.ON_WALLET_CHANGED, MessageConst.ON_CHAR_TALENT_UPGRADE, },
        readLike = false,
        needArg = true,
        Check = function(args)
            local charInstId, nodeId = unpack(args)
            local isActive, isLock = CharInfoUtils.getShipSkillNodeStatus(charInstId, nodeId)
            if isActive or isLock then
                return false
            end
            local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
            if charInst.charType == GEnums.CharType.Trial then
                return false
            end
            if not CharInfoUtils.isCharTalentCostEnough(charInst.templateId, nodeId) then
                return false
            end
            return true, UIConst.RED_DOT_TYPE.Normal
        end
    },
    CharSkillNode = {
        msgs = { MessageConst.ON_ITEM_COUNT_CHANGED, MessageConst.ON_WALLET_CHANGED, MessageConst.ON_SKILL_UPGRADE_SUCCESS, },
        readLike = false,
        needArg = true,
        Check = function(args)
            local charInstId, skillGroupId = unpack(args)
            local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
            if charInst.charType == GEnums.CharType.Trial then
                return false
            end
            local skillGroupLevelInfo = CharInfoUtils.getCharSkillLevelInfo(charInst, skillGroupId)
            if skillGroupLevelInfo.level < skillGroupLevelInfo.maxLevel then
                if CharInfoUtils.isSkillGroupLevelUpCostEnough(charInst.templateId, skillGroupId, skillGroupLevelInfo.level + 1) then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end
    },
    EquipTab = {
        readLike = false,
        needArg = true,
        Check = function(charInstId)
            for slotIndex, _ in pairs(UIConst.EQUIP_PART_TYPE_2_CELL_CONFIG) do
                local groupState = RedDotManager:GetRedDotState("Equip", { charInstId, slotIndex })
                if groupState then
                    return groupState, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end,
        sons = { Equip = false, },
    },
    Equip = {
        msgs = { MessageConst.ON_EQUIP_DEPOT_CHANGED, MessageConst.ON_PUT_ON_EQUIP, MessageConst.ON_PUT_OFF_EQUIP, MessageConst.ON_ITEM_COUNT_CHANGED, MessageConst.ON_TACTICAL_ITEM_CHANGE, },
        readLike = false,
        needArg = true,
        Check = function(args)
            local charInstId, equipSlotIndex = unpack(args)
            local equipCellCfg = UIConst.EQUIP_PART_TYPE_2_CELL_CONFIG[equipSlotIndex]
            if not equipCellCfg then
                return false
            end
            local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
            if charInst.charType == GEnums.CharType.Trial then
                return false
            end
            if equipCellCfg.isTacticalItem then
                if not string.isEmpty(charInst.tacticalItemId) then
                    return false
                end
                for _, itemEquipData in pairs(Tables.equipItemTable) do
                    if GameInstance.player.inventory:IsItemFound(itemEquipData.itemId) and Utils.getBagItemCount(itemEquipData.itemId) > 0 then
                        return true, UIConst.RED_DOT_TYPE.Normal
                    end
                end
            else
                local isEquipped, equipInstId = charInst.equipCol:TryGetValue(equipCellCfg.equipIndex)
                if isEquipped and equipInstId > 0 then
                    return false
                end
                local equipDepot = GameInstance.player.inventory.valuableDepots[GEnums.ItemValuableDepotType.Equip]:GetOrFallback(Utils.getCurrentScope())
                if not equipDepot then
                    return false
                end
                for _, itemBundle in pairs(equipDepot.instItems) do
                    if itemBundle.instData.equippedCharServerId == 0 then
                        local templateId = itemBundle.instData.templateId
                        local _, equipCfg = Tables.equipTable:TryGetValue(templateId)
                        if equipCfg and equipCfg.partType == equipCellCfg.slotPartType then
                            local _, itemData = Tables.itemTable:TryGetValue(templateId)
                            if itemData and itemData.rarity <= charInst.equipTierLimit then
                                return true, UIConst.RED_DOT_TYPE.Normal
                            end
                        end
                    end
                end
            end
            return false
        end,
    },
    WatchBtn = { readLike = false, needArg = false, sons = {}, },
    InventoryBtn = { readLike = false, needArg = false, sons = { ManualCraftBtn = true, }, },
    ManualCraftBtn = {
        readLike = false,
        needArg = false,
        Check = function()
            local blackboxData = GameInstance.world.curLevel.levelData.blackbox
            if blackboxData then
                return false, UIConst.RED_DOT_TYPE.Normal
            end
            local isUnlocked = Utils.isSystemUnlocked(GEnums.UnlockSystemType.ProductManual)
            if isUnlocked and GameInstance.player.facManualCraft.unreadFormulaIds.Count > 0 then
                return true, UIConst.RED_DOT_TYPE.Normal
            end
            return false
        end,
        sons = { ManualCraftType = false, ManualCraftRewardEntry = true, },
    },
    ManualCraftType = {
        readLike = false,
        needArg = true,
        Check = function(formulaType)
            if GameInstance.player.facManualCraft:ExistUnreadFormulaByType(formulaType) then
                return true, UIConst.RED_DOT_TYPE.Normal
            end
            return false
        end,
        sons = { ManualCraftItem = false, },
    },
    ManualCraftItem = {
        msgs = { MessageConst.ON_UNREAD_MANUAL_CRAFT, MessageConst.ON_READ_MANUAL_CRAFT, },
        readLike = false,
        needArg = true,
        Check = function(formulaId)
            if not GameInstance.player.facManualCraft:IsCraftRead(formulaId) then
                return true, UIConst.RED_DOT_TYPE.New
            end
            return false
        end,
    },
    ManualCraftRewardItem = {
        msgs = { MessageConst.ON_UNREAD_MANUAL_CRAFT_REWARD, MessageConst.ON_READ_MANUAL_CRAFT_REWARD, },
        readLike = false,
        needArg = true,
        Check = function(arg)
            if arg.rewardId then
                if GameInstance.player.facManualCraft:CheckHaveReadReward(arg.rewardId) then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
                return false
            else
                if GameInstance.player.facManualCraft:CheckHaveReadRewardByItem(arg.itemId) then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
                return false
            end
        end,
    },
    ManualCraftReward = {
        readLike = false,
        needArg = true,
        penetrateLevel = UIConst.RED_DOT_TYPE.Normal,
        Check = function(arg)
            if GameInstance.player.facManualCraft:CheckHaveRewardByItemNoGet(arg.itemId) > 0 then
                return true, UIConst.RED_DOT_TYPE.Normal
            end
            return false
        end,
        sons = { ManualCraftRewardItem = false, },
    },
    ManualCraftRewardEntry = {
        msgs = { MessageConst.ON_SYSTEM_UNLOCK, },
        readLike = false,
        needArg = false,
        penetrateLevel = UIConst.RED_DOT_TYPE.Normal,
        Check = function()
            if Utils.isSystemUnlocked(GEnums.UnlockSystemType.ProductManual) and GameInstance.player.facManualCraft:CheckRewardRedDot() then
                return true, UIConst.RED_DOT_TYPE.Normal
            end
            return false
        end,
        sons = { ManualCraftReward = false, },
    },
    Announcement = {
        msgs = { MessageConst.ON_ANNOUNCEMENT_RED_DOT_CHANGED, },
        readLike = false,
        needArg = false,
        Check = function()
            return GameInstance.player.announcement:HasNewAnnouncement()
        end,
    },
    FacBuildModeMenuItem = {
        readLike = true,
        needArg = true,
        Check = function(id)
            return Unity.PlayerPrefs.GetInt("FacBuildModeMenuItem" .. id, 0) == 0, UIConst.RED_DOT_TYPE.Normal
        end,
    },
    FacBuildModeMenuLogisticTab = {
        msgs = { MessageConst.ON_SYSTEM_UNLOCK, MessageConst.ON_IN_FAC_MAIN_REGION_CHANGE, },
        sons = { FacBuildModeMenuItem = false, },
        readLike = false,
        needArg = false,
        Check = function()
            if not Utils.isInFacMainRegion() then
                return false
            end
            for id, _ in pairs(Tables.factoryGridConnecterTable) do
                if Utils.isSystemUnlocked(FacConst.LOGISTIC_UNLOCK_SYSTEM_MAP[id]) then
                    if RedDotManager:GetRedDotState("FacBuildModeMenuItem", id) then
                        return true, UIConst.RED_DOT_TYPE.Normal
                    end
                end
            end
            for id, _ in pairs(Tables.factoryGridRouterTable) do
                if Utils.isSystemUnlocked(FacConst.LOGISTIC_UNLOCK_SYSTEM_MAP[id]) then
                    if RedDotManager:GetRedDotState("FacBuildModeMenuItem", id) then
                        return true, UIConst.RED_DOT_TYPE.Normal
                    end
                end
            end
            return false
        end,
    },
    SNSSubDialogCell = {
        msgs = { MessageConst.ON_READ_SNS_DIALOG, },
        needArg = true,
        readLike = true,
        Check = function(dialogId)
            local dialogHasRead = GameInstance.player.sns:DialogHasRead(dialogId)
            if not dialogHasRead then
                return true, UIConst.RED_DOT_TYPE.Normal
            end
            return false
        end,
    },
    SNSContactNpcCell = {
        sons = { SNSSubDialogCell = false, },
        needArg = true,
        readLike = true,
        Check = function(chatId)
            local dialogIds = GameInstance.player.sns.chatInfosDicForUI:get_Item(chatId)
            for _, dialogId in pairs(dialogIds) do
                local succ, _ = Tables.sNSDialogTable:TryGetValue(dialogId)
                if succ then
                    local redDotState = RedDotManager:GetRedDotState("SNSSubDialogCell", dialogId)
                    if redDotState then
                        return true, UIConst.RED_DOT_TYPE.Normal
                    end
                end
            end
            return false
        end,
    },
    SNSMainPanelChatTabCell = {
        sons = { SNSContactNpcCell = false, },
        needArg = false,
        readLike = true,
        Check = function()
            local chatInfo = GameInstance.player.sns.chatInfosDicForUI
            for chatId, _ in pairs(chatInfo) do
                local hasRedDot = RedDotManager:GetRedDotState("SNSContactNpcCell", chatId)
                if hasRedDot then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end
    },
    SNSMainPanelMomentTabCell = {
        needArg = false,
        readLike = false,
        msgs = { MessageConst.ON_SNS_MOMENT_ADD, MessageConst.ON_READ_SNS_MOMENT, },
        Check = function()
            local sns = GameInstance.player.sns
            for _, momentInfo in pairs(sns.momentInfoDic) do
                if not momentInfo.hasRead then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end
    },
    SNSHudEntry = {
        sons = { SNSMainPanelChatTabCell = false, SNSMainPanelMomentTabCell = false, },
        msg = { MessageConst.ON_SNS_NORMAL_DIALOG_ADD, MessageConst.ON_SNS_FORCE_DIALOG_ADD, },
        needArg = false,
        readLike = false,
        Check = function()
            local sns = GameInstance.player.sns
            for _, dialogInfo in pairs(sns.dialogInfoDic) do
                if not dialogInfo.isRead then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            for _, momentInfo in pairs(sns.momentInfoDic) do
                if not momentInfo.hasRead then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end
    },
    RacingEntry = {
        needArg = false,
        Check = function()
            return GameInstance.player.racingDungeonSystem:CheckCanGetWeeklyReward() or GameInstance.player.racingDungeonSystem:CheckCanGetAchieveReward(), UIConst.RED_DOT_TYPE.Normal
        end,
        sons = { RacingWeeklyEntry = false, RacingDungeonAchieveEntry = false },
        readLike = false
    },
    RacingWeeklyEntry = {
        needArg = false,
        Check = function()
            return GameInstance.player.racingDungeonSystem:CheckCanGetWeeklyReward(), UIConst.RED_DOT_TYPE.Normal
        end,
        sons = { RacingDungeonWeeklyReward = false },
        readLike = false
    },
    RacingDungeonWeeklyReward = {
        needArg = true,
        Check = function(dungeonId, nodeId)
            return GameInstance.player.racingDungeonSystem:CheckWeeklyRewardVCanGet(dungeonId, nodeId), UIConst.RED_DOT_TYPE.Normal
        end,
        readLike = false
    },
    RacingDungeonAchieveEntry = {
        needArg = false,
        Check = function()
            return GameInstance.player.racingDungeonSystem:CheckCanGetAchieveReward(), UIConst.RED_DOT_TYPE.Normal
        end,
        sons = { RacingDungeonAchieveReward = false },
        readLike = false
    },
    RacingDungeonAchieveReward = {
        needArg = true,
        Check = function(dungeonId, achieveId)
            return GameInstance.player.racingDungeonSystem:GetAchieveState(dungeonId, achieveId) == CS.Beyond.Gameplay.AchieveState.Complete, UIConst.RED_DOT_TYPE.Normal
        end,
        readLike = false
    },
    CharInfoPotential = {
        msgs = { MessageConst.ON_ITEM_COUNT_CHANGED, },
        readLike = false,
        needArg = true,
        Check = function(charInstId)
            local charInfo = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
            if charInfo.charType == GEnums.CharType.Trial then
                return false
            end
            local hasValue
            local characterPotentialList
            hasValue, characterPotentialList = Tables.characterPotentialTable:TryGetValue(charInfo.templateId)
            if not hasValue or charInfo.potentialLevel >= #characterPotentialList.potentialUnlockBundle then
                return false
            end
            local potentialData = characterPotentialList.potentialUnlockBundle[charInfo.potentialLevel]
            local itemId = potentialData.itemIds[0]
            local itemCount = Utils.getItemCount(itemId)
            local needCount = potentialData.itemCnts[0]
            if itemCount >= needCount then
                return true, UIConst.RED_DOT_TYPE.Normal
            end
            return false
        end
    },
    EquipProducer = {
        msg = { MessageConst.ON_SYSTEM_UNLOCK, },
        readLike = false,
        needArg = false,
        Check = function()
            if Utils.isInBlackbox() then
                return false
            end
            return Utils.isSystemUnlocked(GEnums.UnlockSystemType.EquipProduce) and GameInstance.player.equipTechSystem:GetUnreadFormulaCount() > 0, UIConst.RED_DOT_TYPE.Normal
        end,
        sons = { EquipFormula = false, }
    },
    EquipFormula = {
        msgs = { MessageConst.ON_EQUIP_FORMULA_UNREAD, MessageConst.ON_EQUIP_FORMULA_READ, },
        readLike = true,
        needArg = true,
        Check = function(formulaId)
            if Utils.isInBlackbox() then
                return false
            end
            return GameInstance.player.equipTechSystem:IsFormulaUnread(formulaId), UIConst.RED_DOT_TYPE.New
        end
    },
    CharInfoProfile = { readLike = false, needArg = true, sons = { CharVoice = true, CharDoc = true, } },
    CharVoice = {
        readLike = false,
        needArg = true,
        Check = function(charTemplateId)
            local hasValue
            local charData
            hasValue, charData = Tables.characterTable:TryGetValue(charTemplateId)
            if hasValue then
                for _, voiceData in pairs(charData.profileVoice) do
                    if GameInstance.player.charBag:IsCharVoiceUnread(voiceData.id) then
                        return true, UIConst.RED_DOT_TYPE.Normal
                    end
                end
            end
            return false
        end,
        sons = { CharVoiceEntry = false }
    },
    CharVoiceEntry = {
        msgs = { MessageConst.ON_CHAR_VOICE_READ, MessageConst.ON_CHAR_VOICE_UNREAD, MessageConst.ON_CHAR_VOICE_LOCKED, MessageConst.ON_CHAR_VOICE_UNLOCKED, },
        readLike = true,
        needArg = true,
        Check = function(charVoiceId)
            return GameInstance.player.charBag:IsCharVoiceUnread(charVoiceId), UIConst.RED_DOT_TYPE.New
        end
    },
    CharDoc = {
        readLike = false,
        needArg = true,
        Check = function(charTemplateId)
            local hasValue
            local charData
            hasValue, charData = Tables.characterTable:TryGetValue(charTemplateId)
            if hasValue then
                for _, recordData in pairs(charData.profileRecord) do
                    if GameInstance.player.charBag:IsCharDocUnread(recordData.id) then
                        return true, UIConst.RED_DOT_TYPE.Normal
                    end
                end
            end
            return false
        end,
        sons = { CharDocEntry = false }
    },
    CharDocEntry = {
        msgs = { MessageConst.ON_CHAR_DOC_READ, MessageConst.ON_CHAR_DOC_UNREAD, MessageConst.ON_CHAR_DOC_LOCKED, MessageConst.ON_CHAR_DOC_UNLOCKED, },
        readLike = true,
        needArg = true,
        Check = function(charDocId)
            return GameInstance.player.charBag:IsCharDocUnread(charDocId), UIConst.RED_DOT_TYPE.New
        end
    },
    AdventureBook = { readLike = false, needArg = false, sons = { AdventureBookTabDaily = true, AdventureBookTabStage = true, }, },
    AdventureBookTabStage = {
        msgs = { MessageConst.ON_ADVENTURE_TASK_MODIFY, MessageConst.ON_ADVENTURE_BOOK_STAGE_MODIFY, },
        readLike = false,
        needArg = false,
        Check = function()
            local adventureBookData = GameInstance.player.adventure.adventureBookData
            local isComplete = adventureBookData.isCurAdventureBookStateComplete
            local curStage = adventureBookData.adventureBookStage
            local isActualStage = curStage == adventureBookData.actualBookStage
            if isActualStage and isComplete then
                return true
            end
            local hasCfg, stageTaskCfg = Tables.adventureBookStageRewardTable:TryGetValue(curStage)
            if not hasCfg then
                logger.error("[Adventure Book Stage Reward Table] missing cfg, id = " .. curStage)
                return false
            end
            local taskIds = stageTaskCfg.taskIds
            for _, taskId in pairs(taskIds) do
                isComplete = GameInstance.player.adventure:IsTaskComplete(taskId)
                if isComplete then
                    return true
                end
            end
            return false
        end
    },
    AdventureBookTabDaily = {
        msgs = { MessageConst.ON_ADVENTURE_TASK_MODIFY, MessageConst.ON_DAILY_ACTIVATION_MODIFY, },
        readLike = false,
        needArg = false,
        Check = function()
            local curActivation = GameInstance.player.adventure.adventureBookData.dailyActivation
            local maxActivation = 0
            for _, cfg in pairs(Tables.dailyActivationRewardTable) do
                if cfg.activation > maxActivation then
                    maxActivation = cfg.activation
                end
            end
            if curActivation >= maxActivation then
                return false
            end
            local taskDic = GameInstance.player.adventure.adventureBookData.adventureTasks
            for k, v in pairs(Tables.adventureTaskTable) do
                local csTask = taskDic:get_Item(k)
                if v.taskType == GEnums.AdventureTaskType.Daily and csTask.isComplete then
                    return true
                end
            end
            return false
        end
    },
    AdventureBookTabDungeon = {
        msgs = { MessageConst.ON_SUB_GAME_READ, },
        readLike = false,
        needArg = false,
        Check = function()
            for seriesId, seriesCfg in pairs(Tables.dungeonSeriesTable) do
                local isUnlocked = seriesCfg.dungeonCategory ~= GEnums.DungeonCategoryType.None or seriesCfg.dungeonCategory ~= GEnums.DungeonCategoryType.Train or GameInstance.dungeonManager:IsDungeonSeriesUnlock(seriesId, seriesCfg.dungeonCategory)
                if isUnlocked then
                    for _, id in pairs(seriesCfg.includeDungeonIds) do
                        if GameInstance.player.subGameSys:IsGameUnread(id) then
                            return true
                        end
                    end
                end
            end
            for id, _ in pairs(Tables.worldGameMechanicsDisplayInfoTable) do
                local isMapUnlock = GameInstance.player.subGameSys:IsGameMapMarkUnlock(id, GEnums.MarkType.EnemySpawner)
                if isMapUnlock and GameInstance.player.subGameSys:IsGameUnread(id) then
                    return true
                end
            end
            return false
        end
    },
    AdventureDungeonTab = {
        msgs = { MessageConst.ON_SUB_GAME_READ, },
        readLike = false,
        needArg = true,
        Check = function(ids)
            for _, id in pairs(ids) do
                if GameInstance.player.subGameSys:IsGameUnread(id) then
                    return true
                end
            end
            return false
        end
    },
    AdventureDungeonCell = {
        msgs = { MessageConst.ON_SUB_GAME_READ, },
        readLike = false,
        needArg = true,
        Check = function(ids)
            for _, id in pairs(ids) do
                if GameInstance.player.subGameSys:IsGameUnread(id) then
                    return true, UIConst.RED_DOT_TYPE.New
                end
            end
            return false
        end
    },
    Map = {
        readLike = false,
        needArg = false,
        Check = function()
            local hasNewSceneGrade = RedDotManager:GetRedDotState("SceneGrade", GameInstance.world.curLevelId)
            if hasNewSceneGrade then
                return true, UIConst.RED_DOT_TYPE.Normal
            end
            return false
        end,
        sons = { SceneGrade = false, }
    },
    CheckIn = { readLike = false, needArg = false, Check = RedDotUtils.hasCheckInRewardsNotCollected, msgs = { MessageConst.ON_ACTIVITY_UPDATED } },
    CheckInTab = { readLike = false, needArg = true, Check = RedDotUtils.hasCheckInRewardsNotCollectedInRange, msgs = { MessageConst.ON_CHECK_IN_UPDATED }, },
    SceneGrade = {
        msgs = { MessageConst.ON_NEW_SCENE_GRADE_UNLOCK_CHANGED, },
        readLike = false,
        needArg = true,
        Check = function(sceneId)
            local mapManager = GameInstance.player.mapManager
            return mapManager:IsSceneGradeChangeUnlocked(sceneId) and mapManager:IsNewSceneGradeUnlocked(sceneId), UIConst.RED_DOT_TYPE.Normal
        end
    },
    MapUnreadLevel = {
        msgs = { MessageConst.ON_READ_LEVEL, },
        readLike = true,
        needArg = true,
        Check = function(levelId)
            return not GameInstance.player.mapManager:IsLevelRead(levelId), UIConst.RED_DOT_TYPE.Normal
        end
    },
    Wiki = {
        readLike = false,
        needArg = false,
        Check = function()
            if not Utils.isSystemUnlocked(GEnums.UnlockSystemType.Wiki) then
                return false
            end
            for _, categoryData in pairs(Tables.wikiCategoryTable) do
                local isUnread = RedDotManager:GetRedDotState("WikiCategory", categoryData.categoryId)
                if isUnread then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end,
        sons = { WikiCategory = false, }
    },
    WikiCategory = {
        readLike = false,
        needArg = true,
        Check = function(categoryId)
            if not Utils.isSystemUnlocked(GEnums.UnlockSystemType.Wiki) then
                return false
            end
            local _, wikiGroupData = Tables.wikiGroupTable:TryGetValue(categoryId)
            if not wikiGroupData then
                return false
            end
            for _, groupData in pairs(wikiGroupData.list) do
                local isUnread = RedDotManager:GetRedDotState("WikiGroup", groupData.groupId)
                if isUnread then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end,
        sons = { WikiGroup = false }
    },
    WikiGroup = {
        readLike = false,
        needArg = true,
        Check = function(groupId)
            if not Utils.isSystemUnlocked(GEnums.UnlockSystemType.Wiki) then
                return false
            end
            local _, wikiEntryList = Tables.wikiEntryTable:TryGetValue(groupId)
            if not wikiEntryList then
                return false
            end
            for _, wikiEntryId in pairs(wikiEntryList.list) do
                if WikiUtils.isWikiEntryUnread(wikiEntryId) then
                    return true, UIConst.RED_DOT_TYPE.Normal
                end
            end
            return false
        end,
        sons = { WikiEntry = false, },
    },
    WikiEntry = {
        msgs = { MessageConst.ON_WIKI_ENTRY_UNLOCKED, MessageConst.ON_WIKI_ENTRY_READ, },
        readLike = true,
        needArg = true,
        Check = function(entryId)
            if not Utils.isSystemUnlocked(GEnums.UnlockSystemType.Wiki) then
                return false
            end
            return WikiUtils.isWikiEntryUnread(entryId), UIConst.RED_DOT_TYPE.New
        end
    },
    WikiGuideEntry = {
        msgs = { MessageConst.ON_WIKI_ENTRY_UNLOCKED, MessageConst.ON_WIKI_ENTRY_READ, },
        readLike = true,
        needArg = true,
        Check = function(entryId)
            if not Utils.isSystemUnlocked(GEnums.UnlockSystemType.Wiki) then
                return false
            end
            return WikiUtils.isWikiEntryUnread(entryId), UIConst.RED_DOT_TYPE.Normal
        end
    },
}
return Config