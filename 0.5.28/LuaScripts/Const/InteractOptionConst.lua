local InteractOptionType = CS.Beyond.Gameplay.Core.InteractOptionType
INTERACT_OPTION_PARSE_OPTION_DATA_CONFIG = {
    [InteractOptionType.Npc] = function(optInfo, optData)
        optInfo.icon = "npc_int_icon"
    end,
    [InteractOptionType.Item] = function(optInfo, optData)
        optInfo.itemId = optData[2]
        optInfo.count = optData[3]
        optInfo.action = optData[4]
        optInfo.icon = optData[5]
        optInfo.iconFolder = optData[6]
        optInfo.isItem = true
    end,
    [InteractOptionType.Crop] = function(optInfo, optData)
        local srcData = optData[2]
        if srcData.isItem then
            optInfo.isItem = true
            optInfo.useOverrideName = true
            optInfo.itemId = srcData.itemId
            optInfo.count = srcData.itemCount
        else
            optInfo.isItem = false
            optInfo.icon = srcData.icon
            optInfo.viewGroupValue = srcData.buildingNodeId
            optInfo.viewGroupType = INTERACT_OPTION_VIEW_GROUP_TYPE.Soil
            if srcData.isMain then
                optInfo.sourceId = "MainBuilding"
                optInfo.sortId = 2
            else
                optInfo.sourceId = "SubBuilding"
                optInfo.sortId = 1
            end
        end
        optInfo.text = srcData.text
        optInfo.action = srcData.cb
    end,
    [InteractOptionType.AbandonPack] = function(optInfo, optData)
        optInfo.itemId = optData.itemId
        optInfo.count = optData.count
        optInfo.action = optData.onUseAction
        optInfo.iconFolder = UIConst.UI_SPRITE_ITEM
        optInfo.icon = optData.itemId
        optInfo.isItem = true
        optInfo.viewGroupValue = optData.packId
        optInfo.viewGroupType = INTERACT_OPTION_VIEW_GROUP_TYPE.Pack
    end,
    [InteractOptionType.Factory] = function(optInfo, optData)
        if optData.buildingNodeId then
            if optInfo.icon == nil and optInfo.isDel then
                optInfo.icon = "btn_del_building_icon"
            end
            optInfo.viewGroupValue = optData.buildingNodeId
            optInfo.viewGroupType = INTERACT_OPTION_VIEW_GROUP_TYPE.Building
            optInfo.gameObjectName = string.format("Fac-%s-%s", optData.sourceId, optData.templateId)
        else
            optInfo.text = optData[2]
            optInfo.action = optData[3]
            optInfo.icon = optData[4]
            optInfo.iconFolder = optData[5]
            optInfo.isItem = false
            local nodeId = CSFactoryUtil.GetNodeIdByLogicId(tonumber(optInfo.identifier.sourceId))
            if nodeId > 0 then
                optInfo.viewGroupValue = nodeId
                optInfo.viewGroupType = INTERACT_OPTION_VIEW_GROUP_TYPE.Building
                local node = FactoryUtils.getBuildingNodeHandler(nodeId)
                optInfo.gameObjectName = string.format("InteractiveFactory-%s", node.templateId)
            end
        end
    end,
    [InteractOptionType.Spaceship] = function(optInfo, optData)
        optInfo.viewGroupValue = optData.sourceId
        optInfo.viewGroupType = INTERACT_OPTION_VIEW_GROUP_TYPE.SpaceshipRoom
    end,
}
INTERACT_OPTION_VIEW_GROUP_TYPE = { Pack = 1, Building = 2, Soil = 3, SpaceshipRoom = 4, }
INTERACT_OPTION_VIEW_GROUP_CONFIG = {
    [INTERACT_OPTION_VIEW_GROUP_TYPE.Pack] = { groupTitle = Language.LUA_ABANDON_PACK_INTERACT_GROUP_TITLE, },
    [INTERACT_OPTION_VIEW_GROUP_TYPE.Building] = {
        mainOptionCheckFunction = function(optInfo)
            return optInfo.sourceId == "MainBuilding"
        end,
        groupTitle = function(mainOptInfo)
            local title = ""
            if mainOptInfo ~= nil then
                title = mainOptInfo.text
            end
            mainOptInfo.overrideText = Language.LUA_FAC_INTERACT_BUILDING_GROUP_MAIN_OPT_NAME
            return title
        end
    },
    [INTERACT_OPTION_VIEW_GROUP_TYPE.Soil] = {
        mainOptionCheckFunction = function(optInfo)
            return optInfo.sourceId == "MainBuilding"
        end,
        groupTitle = function(mainOptInfo)
            local title = ""
            if mainOptInfo ~= nil then
                title = mainOptInfo.text
            end
            mainOptInfo.overrideText = Language.LUA_FAC_INTERACT_SOIL_GROUP_MAIN_OPT_NAME
            return title
        end
    },
    [INTERACT_OPTION_VIEW_GROUP_TYPE.SpaceshipRoom] = {
        useMainOptionNameAsTitle = false,
        mainOptionCheckFunction = function(optInfo)
            return optInfo.subIndex == 1
        end,
        groupTitle = function(mainOptInfo)
            return mainOptInfo.data.roomName
        end
    }
}
INTERACT_OPTION_CLICK_AUDIO_CONFIG = { [InteractOptionType.Item] = "au_ui_btn_f_item", [InteractOptionType.Interactive] = "au_ui_btn_f_interactive", [InteractOptionType.InteractiveFunction] = "au_ui_btn_f_interactive_function", [InteractOptionType.Npc] = "au_ui_btn_f_npc", [InteractOptionType.Campfire] = "au_ui_btn_f_campfire", [InteractOptionType.Factory] = "au_ui_btn_f_factory", [InteractOptionType.Crop] = "au_ui_btn_f_interactive_function", }