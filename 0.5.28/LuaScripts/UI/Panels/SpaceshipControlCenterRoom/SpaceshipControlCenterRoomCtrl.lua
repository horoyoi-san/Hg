local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SpaceshipControlCenterRoom
SpaceshipControlCenterRoomCtrl = HL.Class('SpaceshipControlCenterRoomCtrl', uiCtrl.UICtrl)
SpaceshipControlCenterRoomCtrl.m_moveCam = HL.Field(HL.Boolean) << false
SpaceshipControlCenterRoomCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.SPACESHIP_ON_ROOM_LEVEL_UP] = 'OnRoomLevelUp', }
SpaceshipControlCenterRoomCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:RefreshAll()
    if arg.moveCam then
        self.m_moveCam = true
    end
end
SpaceshipControlCenterRoomCtrl.OnRoomLevelUp = HL.Method(HL.Any) << function(self, _)
    self:RefreshAll()
end
SpaceshipControlCenterRoomCtrl.RefreshAll = HL.Method() << function(self)
    self:_RefreshCCRoom()
    self:_RefreshOtherRooms()
end
SpaceshipControlCenterRoomCtrl._RefreshCCRoom = HL.Method() << function(self)
    local roomId = Tables.spaceshipConst.controlCenterRoomId
    local roomInsData = Tables.spaceshipRoomInsTable[roomId]
    local roomTypeData = Tables.spaceshipRoomTypeTable[roomInsData.roomType]
    local node = self.view.controlCenterNode
    local _, roomInfo = GameInstance.player.spaceship:TryGetRoom(roomId)
    node.button.onClick:RemoveAllListeners()
    node.button.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.SpaceshipStation, { roomId = roomId })
    end)
    node.upgradeBtn.onClick:RemoveAllListeners()
    node.upgradeBtn.onClick:AddListener(function()
        if self.m_phase.arg.fromMainHud then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_SPACESHIP_CC_ROOM_NO_UPGRADE)
            return
        end
        PhaseManager:OpenPhase(PhaseId.SpaceshipRoomUpgrade, { roomId = roomId, moveCam = self.m_moveCam })
    end)
    node.icon:LoadSprite(UIConst.UI_SPRITE_SPACESHIP_ROOM, roomTypeData.icon)
    node.iconColorBg.color = UIUtils.getColorByString(roomTypeData.color)
    node.titleTxt.text = roomInsData.name
    node.lvDotNode:InitLvDotNode(roomInfo.lv, roomInfo.maxLv)
    node.lvTxt.text = roomInfo.lv
    local notMaxLv = roomInfo.lv < roomInfo.maxLv
    self.view.lvHint.gameObject:SetActive(notMaxLv)
    node.upgradeBtn.gameObject:SetActive(notMaxLv)
end
SpaceshipControlCenterRoomCtrl._RefreshOtherRooms = HL.Method() << function(self)
    for k, _ in pairs(Tables.spaceshipRoomInsTable) do
        if k ~= Tables.spaceshipConst.controlCenterRoomId then
            self:_UpdateRoomCell(self.view[k], k)
        end
    end
end
SpaceshipControlCenterRoomCtrl._UpdateRoomCell = HL.Method(HL.Table, HL.String) << function(self, cell, roomId)
    local succ, roomInfo = GameInstance.player.spaceship:TryGetRoom(roomId)
    local roomInsData = Tables.spaceshipRoomInsTable[roomId]
    local roomTypeData = Tables.spaceshipRoomTypeTable[roomInsData.roomType]
    local locked = GameInstance.player.spaceship:IsRoomLocked(roomId)
    cell.icon:LoadSprite(UIConst.UI_SPRITE_SPACESHIP_ROOM, roomTypeData.icon)
    cell.iconColorBg.color = succ and UIUtils.getColorByString(roomTypeData.color) or self.view.config.LOCKED_COLOR
    cell.nameTxt.text = roomInsData.name
    cell.button.onClick:RemoveAllListeners()
    if locked then
        cell.simpleStateController:SetState("Locked")
        cell.button.onClick:AddListener(function()
            Notify(MessageConst.SHOW_TOAST, Language.LUA_SPACESHIP_ROOM_LOCKED)
        end)
    elseif succ then
        cell.simpleStateController:SetState("Normal")
        cell.button.onClick:AddListener(function()
            PhaseManager:OpenPhase(PhaseId.SpaceshipStation, { roomId = roomId })
        end)
    else
        cell.simpleStateController:SetState("NotBuild")
        cell.button.onClick:AddListener(function()
            Notify(MessageConst.SHOW_TOAST, Language.LUA_SPACESHIP_ROOM_NOT_BUILD)
        end)
    end
end
SpaceshipControlCenterRoomCtrl.OnClose = HL.Override() << function(self)
    if self.m_moveCam then
        Notify(MessageConst.UNDO_MOVE_CAM_TO_SPACESHIP_ROOM, { roomId = Tables.spaceshipConst.controlCenterRoomId })
    end
end
HL.Commit(SpaceshipControlCenterRoomCtrl)