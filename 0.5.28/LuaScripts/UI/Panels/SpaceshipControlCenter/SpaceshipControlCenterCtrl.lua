local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SpaceshipControlCenter
local PHASE_ID = PhaseId.SpaceshipControlCenter
SpaceshipControlCenterCtrl = HL.Class('SpaceshipControlCenterCtrl', uiCtrl.UICtrl)
SpaceshipControlCenterCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.SPACESHIP_ON_SYNC_ROOM_STATION] = 'OnSyncRoomStation', [MessageConst.SPACESHIP_ON_ROOM_LEVEL_UP] = '_RefreshRooms', }
SpaceshipControlCenterCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeBtn.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.SpaceshipControlCenter)
    end)
    self:BindInputPlayerAction("ss_open_control_center", function()
        PhaseManager:PopPhase(PhaseId.SpaceshipControlCenter)
    end)
    self.view.reportBtn.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.SpaceshipDailyReport)
    end)
    self:_RefreshRooms()
end
SpaceshipControlCenterCtrl.OnSyncRoomStation = HL.Method() << function(self)
    self:_RefreshRooms()
end
SpaceshipControlCenterCtrl._RefreshRooms = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    for k, _ in pairs(Tables.spaceshipRoomInsTable) do
        self:_UpdateRoomCell(self.view.roomNode[k], k)
    end
    local succ, roomInfo = GameInstance.player.spaceship:TryGetRoom(Tables.spaceshipConst.controlCenterRoomId)
    self.view.roomEffectInfoNode:InitSSRoomEffectInfoNode({ attrsMap = roomInfo.attrsMap, color = SpaceshipUtils.getRoomColor(roomInfo.id), })
end
SpaceshipControlCenterCtrl._UpdateRoomCell = HL.Method(HL.Table, HL.String) << function(self, cell, roomId)
    local succ, roomInfo = GameInstance.player.spaceship:TryGetRoom(roomId)
    local roomInsData = Tables.spaceshipRoomInsTable[roomId]
    local roomTypeData = Tables.spaceshipRoomTypeTable[roomInsData.roomType]
    if not succ then
        cell.button.enabled = false
        local locked = GameInstance.player.spaceship:IsRoomLocked(roomId)
        cell.simpleStateController:SetState(locked and "Locked" or "Unlocked")
        local node = cell.otherNode
        node.icon:LoadSprite(UIConst.UI_SPRITE_SPACESHIP_ROOM, roomTypeData.icon)
        node.nameTxt.text = roomInsData.name
        node.unlockTxt.text = string.format(Language.LUA_SPACESHIP_ROOM_UNLOCK_HINT, Tables.spaceshipRoomUnlockNeedCenterLvTable[roomId])
        local color = locked and Color.white or UIUtils.getColorByString(roomTypeData.color)
        color.a = node.icon.color.a
        node.icon.color = color
        return
    end
    cell.button.enabled = true
    cell.button.onClick:RemoveAllListeners()
    cell.button.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.SpaceshipStation, { roomId = roomId })
    end)
    local node = cell.contentNode
    node.icon:LoadSprite(UIConst.UI_SPRITE_SPACESHIP_ROOM, roomTypeData.icon)
    node.iconColorBG.color = UIUtils.getColorByString(roomTypeData.color)
    node.nameTxt.text = roomInsData.name
    node.lvDotNode:InitLvDotNode(roomInfo.lv, roomInfo.maxLv, node.iconColorBG.color)
    self:_UpdateRoomCellStation(cell, roomInfo)
    cell.simpleStateController:SetState("Normal")
end
SpaceshipControlCenterCtrl._UpdateRoomCellStation = HL.Method(HL.Table, CS.Beyond.Gameplay.SpaceshipSystem.Room) << function(self, cell, roomInfo)
    local node = cell.contentNode
    if not node.m_charCells then
        node.m_charCells = UIUtils.genCellCache(node.charCell)
    end
    local maxCount = roomInfo.maxLvStationCount
    local curMaxCount = roomInfo.maxStationCharNum
    local curCount = roomInfo.stationedCharList.Count
    node.m_charCells:Refresh(maxCount, function(charCell, index)
        if index <= curCount then
            charCell.view.simpleStateController:SetState("Normal")
            charCell:InitSSCharHeadCell({ charId = roomInfo.stationedCharList[CSIndex(index)], targetRoomId = roomInfo.id, })
        elseif index <= curMaxCount then
            charCell.view.simpleStateController:SetState("Empty")
        else
            charCell.view.simpleStateController:SetState("Locked")
        end
    end)
    node.countTxt.text = string.format("%d/%d", curCount, curMaxCount)
end
HL.Commit(SpaceshipControlCenterCtrl)