config = {
    CharInfo = { panels = {}, fov = 15.3818, redDotName = "AllCharInfo", systemId = "system_character", disableEffectLodControl = true, },
    CharFormation = {
        panels = {},
        fov = 15.3818,
        systemId = "system_char_formation",
        disableEffectLodControl = true,
        checkCanOpen = function(arg)
            if Utils.isCurSquadAllDead() then
                return false, Language.LUA_GAME_MODE_FORBID_FACTORY_WATCH
            end
            return not Utils.isInFight(), Language.LUA_CHAR_FORMATION_IN_FIGHT
        end,
    },
    Level = { panels = {}, fov = 15.3818, },
    Dialog = { panels = { PanelId.Dialog, PanelId.HeadLabelInDialog, }, },
    Watch = {
        panels = { PanelId.Watch, },
        fov = 40,
        unlockSystemType = GEnums.UnlockSystemType.Watch,
        checkCanOpen = function(arg)
            return not Utils.isInThrowMode()
        end,
    },
    SimpleSystem = { panels = { PanelId.SimpleSystem }, isSimpleUIPhase = true, },
    ManualCraft = { panels = { PanelId.ManualCraft }, unlockSystemType = GEnums.UnlockSystemType.ManualCraft, isSimpleUIPhase = true, },
    Mission = { panels = { PanelId.Mission, }, systemId = "system_mission", isSimpleUIPhase = true, },
    Cinematic = { panels = { PanelId.Cinematic, PanelId.BigLogo, }, },
    WeaponInfo = { panels = {}, fov = 15.3818, unlockSystemType = GEnums.UnlockSystemType.Weapon, disableEffectLodControl = true, },
    Map = {
        panels = {},
        unlockSystemType = GEnums.UnlockSystemType.Map,
        redDotName = "Map",
        checkCanOpen = function(arg)
            if Utils.isCurSquadAllDead() then
                return false, Language.LUA_GAME_MODE_FORBID_FACTORY_WATCH
            end
            arg = arg or {}
            if UIUtils.inDungeon() then
                return false, Language.LUA_MAP_OPEN_FORBID_CONDITION
            end
            if not string.isEmpty(arg.levelId) and not MapUtils.checkIsValidLevelId(arg.levelId) then
                return false, Language.LUA_OPEN_MAP_LEVEL_LOCKED
            end
            if not string.isEmpty(arg.instId) and not MapUtils.checkIsValidMarkInstId(arg.instId) then
                return false
            end
            return true
        end,
    },
    RegionMap = {
        panels = {},
        fov = 40,
        unlockSystemType = GEnums.UnlockSystemType.Map,
        checkCanOpen = function(arg)
            if Utils.isCurSquadAllDead() then
                return false, Language.LUA_GAME_MODE_FORBID_FACTORY_WATCH
            end
            return true
        end,
    },
    ValuableDepot = { panels = { PanelId.ValuableDepot, }, systemId = "system_valuable_depot", isSimpleUIPhase = true, },
    Mail = { panels = { PanelId.Mail, }, systemId = "system_mail", isSimpleUIPhase = true, },
    RepairInteractive = { panels = { PanelId.RepairInteractive, }, isSimpleUIPhase = true, },
    Inventory = {
        panels = {},
        systemId = "system_inventory",
        checkCanOpen = function(arg)
            if Utils.isInFight() then
                return false, Language.LUA_CANT_OPEN_INVENTORY_IN_FIGHT
            end
            if Utils.isInThrowMode() then
                return false, Language.LUA_CANT_OPEN_INVENTORY_IN_THROW_MODE
            end
            return true
        end
    },
    Wiki = { panels = {}, systemId = "system_wiki", disableEffectLodControl = true, },
    Shop = { panels = { PanelId.Shop, }, isSimpleUIPhase = true, },
    PRTS = { panels = { PanelId.PRTSMain, }, redDotName = "PRTSWatch", unlockSystemType = GEnums.UnlockSystemType.PRTS, isSimpleUIPhase = true, },
    GameSetting = { panels = { PanelId.GameSetting, }, isSimpleUIPhase = true, },
    FacMachine = { panels = {}, },
    FacTechTree = { panels = {}, systemId = "system_tech_tree", isSimpleUIPhase = false, },
    FacHUBData = { panels = { PanelId.FacHUBData, }, systemId = "system_hub_data", isSimpleUIPhase = true, },
    RemoteComm = { panels = { PanelId.RemoteCommBG, PanelId.RemoteComm, PanelId.RemoteCommHud, }, fov = 15.3818, },
    LostAndFound = { panels = { PanelId.LostAndFound, }, isSimpleUIPhase = true, },
    RpgDungeonShop = { panels = { PanelId.RpgDungeonShop, }, isSimpleUIPhase = true, },
    Puzzle = { panels = { PanelId.Puzzle, }, isSimpleUIPhase = true, },
    SNS = { panels = {}, redDotName = "SNSHudEntry", isSimpleUIPhase = false, unlockSystemType = GEnums.UnlockSystemType.SNS, },
    SNSConstraint = { panels = { PanelId.SNSConstraint, }, isSimpleUIPhase = true, },
    CharJoinToast = { panels = { PanelId.CharJoinToast, }, isSimpleUIPhase = true, },
    SettlementMain = { panels = { PanelId.SettlementMain, }, systemId = "system_settlement", isSimpleUIPhase = true, },
    SettlementDetails = { panels = { PanelId.SettlementDetails, }, systemId = "system_settlement", isSimpleUIPhase = true, },
    SettlementChar = { panels = { PanelId.SettlementChar, }, systemId = "system_settlement", isSimpleUIPhase = true, },
    SettlementSwitchRegionPopup = { panels = { PanelId.SettlementSwitchRegionPopup, }, systemId = "system_settlement", isSimpleUIPhase = true, },
    SettlementStrategy = { panels = { PanelId.SettlementStrategy, }, systemId = "system_settlement", isSimpleUIPhase = true, },
    SettlementBrief = { panels = { PanelId.SettlementBrief, }, systemId = "system_settlement", isSimpleUIPhase = true, },
    SettlementDefenseTerminal = { panels = { PanelId.SettlementDefenseTerminal, }, isSimpleUIPhase = true, },
    SpaceshipStation = { panels = { PanelId.SpaceshipStation, }, isSimpleUIPhase = true, },
    FacHubCraft = {
        panels = { PanelId.FacHubCraft, },
        isSimpleUIPhase = true,
        checkCanOpen = function(arg)
            if Utils.isInBlackbox() then
                local curSceneInfo = GameInstance.remoteFactoryManager.currentSceneInfo
                return CS.Beyond.Gameplay.RemoteFactory.RemoteFactoryUtil.IsHubBuildingCraftEnabledInBlackbox(curSceneInfo)
            else
                return true
            end
        end,
        unlockSystemType = GEnums.UnlockSystemType.FacHub,
    },
    LiquidPool = { panels = { PanelId.LiquidPool, }, isSimpleUIPhase = true, },
    PowerPoleFastTravel = { panels = {}, isSimpleUIPhase = false, },
    SubmitItem = { panels = { PanelId.SubmitItem, }, isSimpleUIPhase = true, },
    FriendShipPresent = { panels = { PanelId.FriendShipPresent, }, isSimpleUIPhase = true, },
    RacingDungeonEntry = { panels = { PanelId.RacingDungeonEntry, }, isSimpleUIPhase = true, },
    SpaceshipManufacturingStation = { panels = { PanelId.SpaceshipManufacturingStation, }, isSimpleUIPhase = true, },
    SpaceshipRoomUpgrade = { panels = { PanelId.SpaceshipRoomUpgrade, }, isSimpleUIPhase = true, },
    SettlementDefenseShop = { panels = { PanelId.SettlementDefenseShop, }, isSimpleUIPhase = true, },
    EquipProducer = {
        panels = { PanelId.EquipProducer, },
        redDotName = "EquipProducer",
        isSimpleUIPhase = true,
        unlockSystemType = GEnums.UnlockSystemType.EquipProduce,
        checkCanOpen = function(arg)
            if Utils.isInBlackbox() then
                local curSceneInfo = GameInstance.remoteFactoryManager.currentSceneInfo
                return CS.Beyond.Gameplay.RemoteFactory.RemoteFactoryUtil.IsHubEquipCraftEnabledInBlackbox(curSceneInfo)
            else
                return true
            end
        end,
    },
    AdventureReward = { panels = { PanelId.AdventureReward, }, isSimpleUIPhase = true, },
    SettlementDefenseFinish = { panels = { PanelId.SettlementDefenseFinish, }, isSimpleUIPhase = true, },
    SettlementDefenseMainMap = { panels = { PanelId.SettlementDefenseMainMap, }, isSimpleUIPhase = true, },
    SpaceshipControlCenter = { panels = { PanelId.SpaceshipControlCenterRoom, PanelId.SpaceshipControlCenter, }, fov = 15.3818, isSimpleUIPhase = true, unlockSystemType = GEnums.UnlockSystemType.SpaceshipControlCenter, },
    SpaceshipCollectHintInfo = { panels = { PanelId.SpaceshipCollectHintInfo, }, isSimpleUIPhase = true, },
    SpaceshipGrowCabin = { panels = { PanelId.SpaceshipGrowCabin, }, isSimpleUIPhase = true, },
    SpaceshipShop = { panels = { PanelId.SpaceshipShop, }, isSimpleUIPhase = true, },
    AdventureBook = { panels = {}, redDotName = "AdventureBook", isSimpleUIPhase = false, unlockSystemType = GEnums.UnlockSystemType.AdventureBook, },
    RacingDungeonEffect = { panels = { PanelId.RacingDungeonEffect, }, isSimpleUIPhase = true, unlockSystemType = GEnums.UnlockSystemType.RacingDungeon, },
    PuzzleTrackPopup = { panels = { PanelId.PuzzleTrackPopup, }, isSimpleUIPhase = true, },
    Reading = { panels = { PanelId.Reading, }, isSimpleUIPhase = true, },
    ReadingPopUp = { panels = { PanelId.ReadingPopUp, }, isSimpleUIPhase = true, },
    FacDepotSwitching = { panels = { PanelId.FacDepotSwitching, }, isSimpleUIPhase = true, },
    DungeonDetails = { panels = { PanelId.DungeonDetails, }, isSimpleUIPhase = true, },
    BlackboxEntry = { panels = { PanelId.BlackboxEntry, }, isSimpleUIPhase = true, },
    EquipEnhance = { panels = { PanelId.EquipEnhance, }, isSimpleUIPhase = true, },
    GenderSelect = { isSimpleUIPhase = false, fov = 15.3818, },
    DungeonEntry = { panels = { PanelId.DungeonEntry, }, isSimpleUIPhase = true, },
    ManualCollect = { panels = { PanelId.ManualCollect, }, isSimpleUIPhase = true, unlockSystemType = GEnums.UnlockSystemType.ItemSubmitRecycle, },
    GachaChar = { panels = {}, isSimpleUIPhase = false, unlockSystemType = GEnums.UnlockSystemType.Gacha, disableEffectLodControl = true, fov = 15.3818, },
    DungeonTrainOverview = { panels = { PanelId.DungeonTrainOverview, }, isSimpleUIPhase = true, },
    SceneGrade = {
        panels = { PanelId.SceneGrade, },
        isSimpleUIPhase = true,
        checkCanOpen = function(args)
            return GameInstance.player.mapManager:IsSceneGradeChangeUnlocked(args.levelId), Language.LUA_SCENE_GRADE_LOCKED_TIPS
        end
    },
    GachaDropBin = { panels = {}, isSimpleUIPhase = false, unlockSystemType = GEnums.UnlockSystemType.Gacha, disableEffectLodControl = true, },
    GachaPool = { panels = { PanelId.GachaPool, }, isSimpleUIPhase = false, systemId = "system_gacha", },
    DeathInfo = { panels = { PanelId.DeathInfo, }, isSimpleUIPhase = true, },
    PlayerRename = { panels = { PanelId.PlayerRename, }, isSimpleUIPhase = true, },
    SettlementDefenseRewardsInfo = { panels = { PanelId.SettlementDefenseRewardsInfo, }, isSimpleUIPhase = true, },
    PRTSInvestigateGallery = { panels = { PanelId.PRTSInvestigateGallery, }, isSimpleUIPhase = true, },
    PRTSInvestigateDetail = {
        panels = { PanelId.PRTSInvestigateDetail, },
        isSimpleUIPhase = true,
        unlockSystemType = GEnums.UnlockSystemType.PRTS,
        checkCanOpen = function(arg)
            if not Utils.isSystemUnlocked(GEnums.UnlockSystemType.PRTS) then
                return false, "PRTS System Not Unlock"
            end
            return (arg ~= nil and not string.isEmpty(arg.id)), "[PRTSInvestigateDetailCtrl] arg or arg.id is nil!"
        end,
    },
    PRTSStoryCollGallery = {
        panels = { PanelId.PRTSStoryCollGallery, },
        isSimpleUIPhase = true,
        checkCanOpen = function(arg)
            return (arg ~= nil and not string.isEmpty(arg.pageType)), "[PRTSStoryCollGalleryCtrl] arg or arg.pageType is nil!"
        end,
    },
    SceneGradeDifferenceItemPopUp = { panels = { PanelId.SceneGradeDifferenceItemPopUp, }, isSimpleUIPhase = true, },
    SpaceshipDailyReport = { panels = { PanelId.SpaceshipDailyReport, }, isSimpleUIPhase = true, },
    UsableItemChest = { panels = { PanelId.UsableItemChest, }, isSimpleUIPhase = true, },
    GemRecast = { panels = { PanelId.GemRecast, }, isSimpleUIPhase = true, },
    PRTSStoryCollDetail = {
        panels = { PanelId.PRTSStoryCollDetail, },
        isSimpleUIPhase = true,
        unlockSystemType = GEnums.UnlockSystemType.PRTS,
        checkCanOpen = function(arg)
            if not Utils.isSystemUnlocked(GEnums.UnlockSystemType.PRTS) then
                return false, "PRTS System Not Unlock"
            end
            local canShow = arg ~= nil and (arg.id or arg.idList and #arg.idList > 0)
            return canShow, "[PRTSStoryCollDetailCtrl] arg is illegal!"
        end,
    },
    SubmitCollection = { panels = { PanelId.SubmitCollection, }, isSimpleUIPhase = true, },
    PRTSInvestigateReport = {
        panels = { PanelId.PRTSInvestigateReport, },
        isSimpleUIPhase = true,
        unlockSystemType = GEnums.UnlockSystemType.PRTS,
        checkCanOpen = function(arg)
            local canOpen = arg ~= nil and arg.storyCollId and Tables.prtsAllItem:ContainsKey(arg.storyCollId)
            return canOpen, "[PRTSInvestigateReportCtrl] arg or arg.storyCollId is missing!"
        end,
    },
    ShopEntry = { panels = { PanelId.ShopEntry, }, isSimpleUIPhase = true, },
    CommonMoneyExchange = { panels = { PanelId.CommonMoneyExchange, }, isSimpleUIPhase = true, },
    DomainItemTransfer = {
        panels = { PanelId.DomainItemTransfer, },
        isSimpleUIPhase = true,
        checkCanOpen = function(arg)
            return GameInstance.player.remoteFactory:IsFacTransExistUnlockedRoute()
        end,
    },
    GachaWeaponPreheat = { panels = {}, isSimpleUIPhase = false, disableEffectLodControl = true, },
    GachaWeapon = { panels = {}, isSimpleUIPhase = false, disableEffectLodControl = true, },
    GachaWeaponPool = { panels = { PanelId.GachaWeaponPool, }, isSimpleUIPhase = false, },
    CheckIn = { panels = { PanelId.CheckIn, }, isSimpleUIPhase = true, redDotName = 'CheckIn', unlockSystemType = GEnums.UnlockSystemType.CheckIn, },
    GachaWeaponResult = { panels = { PanelId.GachaWeaponResult, }, fov = 30, isSimpleUIPhase = false, },
    EndingToast = { panels = { PanelId.EndingToast, }, isSimpleUIPhase = true, },
    LeadingCharacter = { panels = { PanelId.LeadingCharacter, }, isSimpleUIPhase = true, },
    SettlementDefenseTransit = { panels = { PanelId.SettlementDefenseTransit, }, isSimpleUIPhase = true, },
}