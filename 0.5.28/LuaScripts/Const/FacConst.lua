FACTORY_BUILDING_UI_MAP = { [GEnums.FacBuildingType.Hub] = { "FacHUB", false }, [GEnums.FacBuildingType.SubHub] = { "FacHUB", false }, [GEnums.FacBuildingType.PowerStation] = { "FacPowerStation", false }, [GEnums.FacBuildingType.PowerPole] = { "FacPowerPole", false }, [GEnums.FacBuildingType.MachineCrafter] = { "FacMachineCrafter", false }, [GEnums.FacBuildingType.Loader] = { "FacLoader", false }, [GEnums.FacBuildingType.Unloader] = { "FacUnloader", false }, [GEnums.FacBuildingType.Miner] = { "FacMiner", false }, [GEnums.FacBuildingType.Storager] = { "FacStorage", false }, [GEnums.FacBuildingType.Medic] = { "FacMedicalTowerNew", false }, [GEnums.FacBuildingType.Soil] = { "FacCultivate", false }, [GEnums.FacBuildingType.TravelPole] = { "FacTravelPole", false }, [GEnums.FacBuildingType.PowerTerminal] = { "FacPowerTerminal", false }, [GEnums.FacBuildingType.PowerPort] = { "FacPowerTerminal", false }, [GEnums.FacBuildingType.PowerGate] = { "FacPowerGate", false }, [GEnums.FacBuildingType.PowerDiffuser] = { "FacPowerDiffuser", false }, [GEnums.FacBuildingType.Battle] = { "FacBattle", false }, [GEnums.FacBuildingType.FluidPumpIn] = { "FacPump", false }, [GEnums.FacBuildingType.FluidContainer] = { "FacLiquidStorager", false }, [GEnums.FacBuildingType.FluidPumpOut] = { "FacDumper", false }, [GEnums.FacBuildingType.FluidReaction] = { "FacMixPool", false }, [GEnums.FacBuildingType.FluidSpray] = { "FacSquirter", false }, [GEnums.FacBuildingType.FluidConsume] = { "FacLiquidCleaner", false }, }
FACTORY_NON_BUILDING_UI_MAP = { ["grid_belt_01"] = "FacBelt", ["log_connector"] = "FacConnector", ["log_converger"] = "FacConverger", ["log_splitter"] = "FacSplitter", ["log_pipe_01"] = "FacPipe", ["log_pipe_connector"] = "FacPipeConnector", ["log_pipe_splitter"] = "FacPipeSplitter", ["log_pipe_converger"] = "FacPipeConverger", }
local RectFace = FacCoreNS.RectFace
LogisticNearCargoInfos = { { index = 1, gridOffset = FacCoreNS.Vector2IntData(0, -1), validInFace = RectFace.Down, validOutFace = RectFace.Top, }, { index = 2, gridOffset = FacCoreNS.Vector2IntData(-1, 0), validInFace = RectFace.Left, validOutFace = RectFace.Right, }, { index = 3, gridOffset = FacCoreNS.Vector2IntData(0, 1), validInFace = RectFace.Top, validOutFace = RectFace.Down, }, { index = 4, gridOffset = FacCoreNS.Vector2IntData(1, 0), validInFace = RectFace.Right, validOutFace = RectFace.Left, }, }
FactoryLogisticDeviceType = { Router = 1, Connector = 2, }
FAC_BUILD_MODE = { Normal = 1, Building = 2, Logistic = 3, Belt = 4, }
FAC_POWER_POLE_TOAST_TYPE = { Start = 1, Cancel = 2, Success = 3, Failed = 4, LinkFailed = 5, LinkAlready = 6, FailedSourceNoPower = 7, PowerNotEnough = 8, }
FAC_SAMPLE_TYPE = { Belt = 1, Pipe = 2, }
SP_BUILDING_TYPES = { GEnums.FacBuildingType.Hub, GEnums.FacBuildingType.Recycler, }
FAC_HUB_CRAFT_MAX_INCOME_NUM = 3
FAC_PROCESSOR_CRAFT_MAX_INCOME_NUM = 3
FAC_MANUAL_CRAFT_MAX_INCOME_NUM = 3
FAC_BUILDING_CHARACTER_MAX_NUM = 3
FAC_PROCESSOR_GEM_MAX_SOLT_NUM = 3
FAC_CHARACTER_MAX_SOLT_NUM = 3
BUILDING_SIZE_INDICATOR_PATH = "Assets/Beyond/DynamicAssets/Gameplay/Factory/Common/building_size_indicator.prefab"
BELT_START_PREVIEW_MARK_PREFAB_PATH = "Assets/Beyond/DynamicAssets/Gameplay/Factory/Common/belt_start_preview_mark.prefab"
PIPE_PREVIEW_MARK_PREFAB_PATH = "Assets/Beyond/DynamicAssets/Gameplay/Factory/Common/pipe_build_mark.prefab"
BUILDING_INTERACT_PIPE_INDICATOR_PATH = "Assets/Beyond/DynamicAssets/Gameplay/Factory/Common/fac_interact_indicator_pipe.prefab"
BUILDING_INTERACT_BOX_INDICATOR_PATH = "Assets/Beyond/DynamicAssets/Gameplay/Factory/Common/fac_interact_indicator_box.prefab"
BUILDING_INTERACT_NORMAL_INDICATOR_PATH = "Assets/Beyond/DynamicAssets/Gameplay/Factory/Common/fac_interact_indicator_normal.prefab"
BUILDING_INTERACT_HOVER_INDICATOR_PATH = "Assets/Beyond/DynamicAssets/Gameplay/Factory/Common/fac_interact_indicator_hover.prefab"
POWER_POLE_RANGE_EFFECT = "Assets/Beyond/DynamicAssets/Gameplay/Effects/Prefabs/P_interactive_electricpole_range.prefab"
FLUID_SPRAY_RANGE_EFFECT = "Assets/Beyond/DynamicAssets/Gameplay/Effects/Prefabs/P_interactive_sprinkler_01_range_5x4.prefab"
BATTLE_BUILDING_RANGE_EFFECT = "Assets/Beyond/DynamicAssets/Gameplay/Effects/Prefabs/P_interactive_boundary_weapontower_01.prefab"
AUTO_EXIT_FACTORY_DIST = 3
FAC_PROC_TYPE = { ExpCard = 1, Equip = 2, Gem = 3, GemRecast = 4, }
FAC_BUILDING_STATE_TO_SPRITE = { [GEnums.FacBuildingState.Closed] = "icon_ui_power_pole_machine_state_4", [GEnums.FacBuildingState.Unknown] = "icon_ui_power_pole_machine_state_4", [GEnums.FacBuildingState.Idle] = "icon_ui_power_pole_machine_state_5", [GEnums.FacBuildingState.Normal] = "icon_ui_power_pole_machine_state_6", [GEnums.FacBuildingState.Blocked] = "icon_ui_power_pole_machine_state_2", [GEnums.FacBuildingState.NoPower] = "icon_ui_power_pole_machine_state_3", [GEnums.FacBuildingState.NotInPowerNet] = "icon_ui_power_pole_machine_state_1", [GEnums.FacBuildingState.Fixable] = "icon_ui_power_pole_machine_state_7", }
FAC_TOP_VIEW_BUILDING_STATE_TO_SPRITE = { [GEnums.FacBuildingState.Closed] = "icon_building_state_4", [GEnums.FacBuildingState.Unknown] = "icon_building_state_4", [GEnums.FacBuildingState.Idle] = "icon_building_state_5", [GEnums.FacBuildingState.Blocked] = "icon_building_state_2", [GEnums.FacBuildingState.NoPower] = "icon_building_state_3", [GEnums.FacBuildingState.NotInPowerNet] = "icon_building_state_1", }
CRAFT_PROGRESS_MULTIPLIER = CS.Beyond.Gameplay.RemoteFactory.RemoteFactoryUtil.craftProgressMultiplier
HUB_DATA_ID = "sp_hub_1"
BELT_ITEM_ID = "item_log_belt_01"
BELT_ID = "grid_belt_01"
PIPE_ITEM_ID = "item_log_pipe_01"
PIPE_ID = "log_pipe_01"
CAN_BLOCK_CPTS = { [GEnums.FCComponentPos.Collector:GetHashCode()] = "collector", [GEnums.FCComponentPos.Producer:GetHashCode()] = "producer", }
HAVE_PORT_CPTS = { [GEnums.FCComponentPos.Cache:GetHashCode()] = "cache", [GEnums.FCComponentPos.CacheIn1:GetHashCode()] = "cache", [GEnums.FCComponentPos.CacheIn2:GetHashCode()] = "cache", [GEnums.FCComponentPos.CacheIn3:GetHashCode()] = "cache", [GEnums.FCComponentPos.CacheIn4:GetHashCode()] = "cache", [GEnums.FCComponentPos.CacheOut1:GetHashCode()] = "cache", [GEnums.FCComponentPos.CacheOut2:GetHashCode()] = "cache", [GEnums.FCComponentPos.CacheOut3:GetHashCode()] = "cache", [GEnums.FCComponentPos.CacheOut4:GetHashCode()] = "cache", [GEnums.FCComponentPos.BusLoader:GetHashCode()] = "busLoader", [GEnums.FCComponentPos.Selector:GetHashCode()] = "selector", [GEnums.FCComponentPos.Selector1:GetHashCode()] = "selector", [GEnums.FCComponentPos.Selector2:GetHashCode()] = "selector", [GEnums.FCComponentPos.Selector3:GetHashCode()] = "selector", [GEnums.FCComponentPos.Selector4:GetHashCode()] = "selector", [GEnums.FCComponentPos.Selector5:GetHashCode()] = "selector", [GEnums.FCComponentPos.Selector6:GetHashCode()] = "selector", [GEnums.FCComponentPos.Selector7:GetHashCode()] = "selector", [GEnums.FCComponentPos.Selector8:GetHashCode()] = "selector", [GEnums.FCComponentPos.Selector9:GetHashCode()] = "selector", }
BUILDING_PORT_IS_INPUT_INFOS = { [GEnums.FCComponentPos.BusLoader] = true, [GEnums.FCComponentPos.Selector1] = false, [GEnums.FCComponentPos.Selector2] = false, [GEnums.FCComponentPos.Selector3] = false, [GEnums.FCComponentPos.Selector4] = false, [GEnums.FCComponentPos.Selector5] = false, [GEnums.FCComponentPos.Selector6] = false, [GEnums.FCComponentPos.Cache] = true, [GEnums.FCComponentPos.CacheIn1] = true, [GEnums.FCComponentPos.CacheIn2] = true, [GEnums.FCComponentPos.CacheIn3] = true, [GEnums.FCComponentPos.CacheIn4] = true, [GEnums.FCComponentPos.CacheOut1] = false, [GEnums.FCComponentPos.CacheOut2] = false, [GEnums.FCComponentPos.CacheOut3] = false, [GEnums.FCComponentPos.CacheOut4] = false, }
SP_BUILDING_IDS = { [GEnums.FacBuildingType.Hub] = "sp_hub_1", }
LOGISTIC_UNLOCK_SYSTEM_MAP = { ["log_connector"] = GEnums.UnlockSystemType.FacBridge, ["log_converger"] = GEnums.UnlockSystemType.FacMerger, ["log_splitter"] = GEnums.UnlockSystemType.FacSplitter, ["log_pipe_connector"] = GEnums.UnlockSystemType.FacPipeConnector, ["log_pipe_converger"] = GEnums.UnlockSystemType.FacPipeConverger, ["log_pipe_splitter"] = GEnums.UnlockSystemType.FacPipeSplitter, }
FACTORY_DATA_TAB_INDEX = { DayData = 1, PowerData = 2, ProductData = 3, }
NOT_SHOW_IN_POWER_POLE_FC_NODE_TYPES = { [GEnums.FCNodeType.Invalid:GetHashCode()] = true, [GEnums.FCNodeType.Hub:GetHashCode()] = true, [GEnums.FCNodeType.SubHub:GetHashCode()] = true, [GEnums.FCNodeType.PowerPole:GetHashCode()] = true, [GEnums.FCNodeType.PowerDiffuser:GetHashCode()] = true, [GEnums.FCNodeType.PowerGate:GetHashCode()] = true, [GEnums.FCNodeType.PowerSave:GetHashCode()] = true, [GEnums.FCNodeType.Inventory:GetHashCode()] = true, [GEnums.FCNodeType.Bus:GetHashCode()] = true, [GEnums.FCNodeType.BusUnloader:GetHashCode()] = true, [GEnums.FCNodeType.BusLoader:GetHashCode()] = true, [GEnums.FCNodeType.BoxConveyor:GetHashCode()] = true, [GEnums.FCNodeType.BoxBridge:GetHashCode()] = true, [GEnums.FCNodeType.BoxRouterM1:GetHashCode()] = true, [GEnums.FCNodeType.BurnPower:GetHashCode()] = true, [GEnums.FCNodeType.PowerPort:GetHashCode()] = true, [GEnums.FCNodeType.PowerTerminal:GetHashCode()] = true, [GEnums.FCNodeType.FluidConveyor:GetHashCode()] = true, [GEnums.FCNodeType.FluidRepeater:GetHashCode()] = true, [GEnums.FCNodeType.FluidRouterM1:GetHashCode()] = true, [GEnums.FCNodeType.FluidBridge:GetHashCode()] = true, [GEnums.FCNodeType.Soil:GetHashCode()] = true, }
BUILDING_PANEL_AUTO_CLOSE_RANGE = 3
QuickBarItemType = { Building = 1, Belt = 2, Logistic = 3, }
FAC_FORMULA_MODE_MAP = { NORMAL = "normal", LIQUID = "liquid", }
FAC_TOP_VIEW_BASIC_ACTION_IDS = { "fac_top_view_move", "fac_top_view_zoom", }
FAC_TOP_VIEW_MOVE_PADDING = 3
FAC_LOGISTIC_SPEED_OVERRIDE = 0.001
FAC_PIPE_LOGISTIC_SPEED_OVERRIDE = 0.001
BattleBuildingChargingMode = { Battery = 1, PowerNet = 2, Overload = 3, Closed = 4, }
BATCH_DEL_HINT_COUNT = 5
HUB_ITEM_PRODUCTIVITY_SHOWING_TYPES = { GEnums.ItemShowingType.Ore, GEnums.ItemShowingType.Plant, GEnums.ItemShowingType.Product, GEnums.ItemShowingType.Usable, }
FLUID_LOGISTIC_ITEMS = { ["item_log_pipe_01"] = true, ["item_log_pipe_repeater"] = true, ["item_log_pipe_connector"] = true, ["item_log_pipe_splitter"] = true, ["item_log_pipe_converger"] = true, }
SEWAGE_LIQUID_ITEM_ID_LIST = { ["item_liquid_sewage"] = true, }
MAIN_REGION_CAM_STATE = "Factory/CCS_Fac_Region"