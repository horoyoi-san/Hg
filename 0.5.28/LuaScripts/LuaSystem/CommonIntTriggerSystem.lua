local LuaSystemBase = require_ex('LuaSystem/LuaSystemBase')
CommonIntTriggerSystem = HL.Class('CommonIntTriggerSystem', LuaSystemBase.LuaSystemBase)
CommonIntTriggerSystem.OnInit = HL.Override() << function(self)
    self:RegisterMessage(MessageConst.COMPONENT_CALL_LUA_UI_ON, function(args)
        self:CallLuaUI(args, true)
    end)
    self:RegisterMessage(MessageConst.COMPONENT_CALL_LUA_UI_OFF, function(args)
        self:CallLuaUI(args, false)
    end)
    self:_InitSpaceshipRoom()
end
CommonIntTriggerSystem.OnRelease = HL.Override() << function(self)
end
CommonIntTriggerSystem.CallLuaUI = HL.Method(HL.Table, HL.Boolean) << function(self, args, isOn)
    local argList, camConfigsCSCS = unpack(args)
    local name = argList[0]
    local funcName = name .. (isOn and "_ON" or "_OFF")
    local func = self[funcName]
    if not func then
        logger.error("No Func", funcName, name, args)
        return
    end
    local count = argList.Count - 1
    if count == 0 then
        func(self, camConfigsCSCS)
    elseif count == 1 then
        func(self, argList[1], camConfigsCSCS)
    elseif count == 2 then
        func(self, argList[1], argList[2], camConfigsCSCS)
    elseif count == 3 then
        func(self, argList[1], argList[2], argList[3], camConfigsCSCS)
    elseif count == 4 then
        func(self, argList[1], argList[2], argList[3], argList[4], camConfigsCSCS)
    elseif count == 5 then
        func(self, argList[1], argList[2], argList[3], argList[4], argList[5], camConfigsCSCS)
    elseif count == 6 then
        func(self, argList[1], argList[2], argList[3], argList[4], argList[5], argList[6], camConfigsCSCS)
    end
    AudioManager.PostEvent("au_int_template_slience")
end
CommonIntTriggerSystem.m_curSpaceshipRoomCamConfigs = HL.Field(HL.Table)
CommonIntTriggerSystem.m_curSpaceshipRoomCamStack = HL.Field(HL.Table)
CommonIntTriggerSystem._InitSpaceshipRoom = HL.Method() << function(self)
    self.m_curSpaceshipRoomCamStack = {}
    self:RegisterMessage(MessageConst.MOVE_CAM_TO_SPACESHIP_ROOM, function(args)
        local roomId = args.roomId
        if self.m_curSpaceshipRoomCamConfigs and self.m_curSpaceshipRoomCamConfigs.roomId then
            local isUpgrade = args.isUpgrade
            local cfg = self.m_curSpaceshipRoomCamConfigs.configs[isUpgrade and 1 or 0]
            local clearScreenKey
            if not isUpgrade then
                clearScreenKey = UIManager:ClearScreen()
            end
            table.insert(self.m_curSpaceshipRoomCamStack, { cfg, clearScreenKey })
            GameAction.BlendToRelativeCamera(cfg)
        end
    end)
    self:RegisterMessage(MessageConst.UNDO_MOVE_CAM_TO_SPACESHIP_ROOM, function(args)
        local roomId = args.roomId
        if self.m_curSpaceshipRoomCamConfigs and self.m_curSpaceshipRoomCamConfigs.roomId then
            local count = #self.m_curSpaceshipRoomCamStack
            local info = self.m_curSpaceshipRoomCamStack[count]
            self.m_curSpaceshipRoomCamStack[count] = nil
            local clearScreenKey = info[2]
            if clearScreenKey then
                UIManager:RecoverScreen(clearScreenKey)
            end
            if count > 1 then
                GameAction.BlendToRelativeCamera(self.m_curSpaceshipRoomCamStack[count - 1][1])
            else
                CS.Beyond.Gameplay.View.CameraUtils.DoCommonTempBlendOut(0.5)
            end
        end
    end)
    self:RegisterMessage(MessageConst.FORCE_CLEAR_SPACESHIP_ROOM_CAM, function(args)
        if self.m_curSpaceshipRoomCamConfigs then
            self.m_curSpaceshipRoomCamConfigs = nil
            self.m_curSpaceshipRoomCamStack = {}
            CS.Beyond.Gameplay.View.CameraUtils.DoCommonTempBlendOut(0)
        end
    end)
end
CommonIntTriggerSystem.SpaceshipRoom_ON = HL.Method(HL.String, HL.Opt(HL.Any)) << function(self, roomId, camConfigsCS)
    local unlocked, room = GameInstance.player.spaceship:TryGetRoom(roomId)
    if not unlocked then
        return
    end
    self.m_curSpaceshipRoomCamConfigs = { roomId = roomId, configs = camConfigsCS, }
    local roomType = room.type
    local phaseId = PhaseId[SpaceshipConst.ROOM_PHASE_ID_NAME_MAP_BY_TYPE[roomType]]
    local roomTypeData = Tables.spaceshipRoomTypeTable[roomType]
    local sourceId = "SpaceshipRoom_" .. roomId
    local openInteractOptArgs = {
        type = CS.Beyond.Gameplay.Core.InteractOptionType.Spaceship,
        sourceId = sourceId,
        text = roomTypeData.viewOptName,
        action = function()
            Notify(MessageConst.MOVE_CAM_TO_SPACESHIP_ROOM, { roomId = roomId })
            TimerManager:StartTimer(0.5, function()
                PhaseManager:OpenPhase(phaseId, { roomId = roomId, moveCam = true, })
            end)
        end,
        icon = roomTypeData.icon,
        iconFolder = UIConst.UI_SPRITE_SPACESHIP_ROOM,
        subIndex = 1,
        sortId = 1,
        roomName = Tables.spaceshipRoomInsTable[roomId].name,
    }
    Notify(MessageConst.ADD_INTERACT_OPTION, openInteractOptArgs)
    local isMaxLv = room.lv >= room.maxLv
    local upgradeInteractOptArgs = {
        type = CS.Beyond.Gameplay.Core.InteractOptionType.Spaceship,
        sourceId = sourceId,
        text = isMaxLv and roomTypeData.maxLvOptName or roomTypeData.upgradeOptName,
        action = function()
            PhaseManager:OpenPhase(PhaseId.SpaceshipRoomUpgrade, { roomId = roomId, moveCam = true, })
        end,
        icon = "ss_room_upgrade_int_icon",
        subIndex = 2,
        sortId = 1,
    }
    Notify(MessageConst.ADD_INTERACT_OPTION, upgradeInteractOptArgs)
end
CommonIntTriggerSystem.SpaceshipRoom_OFF = HL.Method(HL.String, HL.Opt(HL.Any)) << function(self, roomId, camConfigsCS)
    local sourceId = "SpaceshipRoom_" .. roomId
    Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Spaceship, sourceId = sourceId, subIndex = 1, })
    Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.Spaceship, sourceId = sourceId, subIndex = 2, })
end
CommonIntTriggerSystem.RacingDungeon_ON = HL.Method(HL.String, HL.String, HL.String, HL.String, HL.Opt(HL.Any)) << function(self, roomId, position, rotation, sceneId, camConfigsCS)
    local positionList = string.split(position, ",")
    local rotationList = string.split(rotation, ",")
    local positionTable = { x = tonumber(positionList[1]), y = tonumber(positionList[2]), z = tonumber(positionList[3]) }
    local rotationTable = { x = tonumber(rotationList[1]), y = tonumber(rotationList[2]), z = tonumber(rotationList[3]) }
    local openInteractOptArgs = {
        type = CS.Beyond.Gameplay.Core.InteractOptionType.DungeonInteractive,
        sourceId = tonumber(roomId),
        text = Language.LUA_RACING_DUNGEON_START_OPTION,
        action = function()
            UIManager:Open(PanelId.RacingDungeonProtal, { roomId = roomId, position = positionTable, rotation = rotationTable, sceneId = sceneId })
        end,
        subIndex = 1,
        sortId = 1,
    }
    Notify(MessageConst.ADD_INTERACT_OPTION, openInteractOptArgs)
end
CommonIntTriggerSystem.RacingDungeon_OFF = HL.Method(HL.String, HL.String, HL.String, HL.String, HL.Opt(HL.Any)) << function(self, roomId, position, rotation, sceneId, camConfigsCS)
    Notify(MessageConst.REMOVE_INTERACT_OPTION, { type = CS.Beyond.Gameplay.Core.InteractOptionType.DungeonInteractive, sourceId = roomId, subIndex = 1, })
end
HL.Commit(CommonIntTriggerSystem)
return CommonIntTriggerSystem