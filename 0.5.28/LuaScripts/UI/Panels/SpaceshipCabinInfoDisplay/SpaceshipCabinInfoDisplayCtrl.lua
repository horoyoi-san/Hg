local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SpaceshipCabinInfoDisplay
local SSStatusBarBase = require_ex('UI/Widgets/SSStatusBarBase')
SpaceshipCabinInfoDisplayCtrl = HL.Class('SpaceshipCabinInfoDisplayCtrl', uiCtrl.UICtrl)
SpaceshipCabinInfoDisplayCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.SS_UNREGISTER_STATUS_BAR] = 'UnregisterStatusBar', [MessageConst.SS_UNREGISTER_CHAR_INFO_PANEL] = 'UnregisterCharInfoPanel', [MessageConst.SPACESHIP_ON_SYNC_ROOM_STATION] = 'UpdateAllCharInfoPanelAndStatusBar', [MessageConst.SPACESHIP_ON_ROOM_LOCKED_CHANGED] = 'UpdateAllStatusBar', [MessageConst.SPACESHIP_ON_ROOM_ADDED] = 'OnRoomDataChanged', [MessageConst.SPACESHIP_ON_ROOM_DATA_CHANGE] = 'OnRoomDataChanged', [MessageConst.ON_SPACESHIP_MANUFACTURING_STATION_SYNC] = 'OnRoomStateChanged', [MessageConst.ON_SPACESHIP_MANUFACTURING_STATION_START] = 'OnRoomStateChanged', [MessageConst.ON_SPACESHIP_MANUFACTURING_STATION_CANCEL] = 'OnRoomStateChanged', [MessageConst.ON_SPACESHIP_MANUFACTURING_STATION_COLLECT] = 'OnRoomStateChanged', [MessageConst.ON_SPACESHIP_GROW_CABIN_MODIFY] = 'OnGcStateChanged', [MessageConst.ON_SPACESHIP_GROW_CABIN_SOW] = 'OnGcStateChanged', [MessageConst.ON_SPACESHIP_GROW_CABIN_HARVEST] = 'OnGcStateChanged', [MessageConst.ON_SPACESHIP_GROW_CABIN_CANCEL] = 'OnGcStateChanged', }
SpaceshipCabinInfoDisplayCtrl.m_statusBars = HL.Field(HL.Table)
SpaceshipCabinInfoDisplayCtrl.m_charInfoPanels = HL.Field(HL.Table)
SpaceshipCabinInfoDisplayCtrl.RegisterStatusBar = HL.StaticMethod(HL.Table) << function(args)
    local roomId = args.roomId
    local statusBar = args.statusBar
    local self = UIManager:AutoOpen(PANEL_ID)
    self.m_statusBars[roomId] = statusBar
    self:UpdateStatusBar(roomId)
end
SpaceshipCabinInfoDisplayCtrl.RegisterCharInfoPanel = HL.StaticMethod(HL.Table) << function(args)
    local roomId = args.roomId
    local charInfoPanel = args.charInfoPanel
    local self = UIManager:AutoOpen(PANEL_ID)
    self.m_charInfoPanels[roomId] = charInfoPanel
    self:UpdateCharInfoPanel(roomId)
end
SpaceshipCabinInfoDisplayCtrl.UnregisterStatusBar = HL.Method(HL.String) << function(self, roomId)
    self.m_statusBars[roomId] = nil
end
SpaceshipCabinInfoDisplayCtrl.UnregisterCharInfoPanel = HL.Method(HL.String) << function(self, roomId)
    self.m_charInfoPanels[roomId] = nil
end
SpaceshipCabinInfoDisplayCtrl.UpdateCharInfoPanel = HL.Method(HL.String) << function(self, roomId)
    local charInfoPanel = self.m_charInfoPanels[roomId]
    if not charInfoPanel then
        return
    end
    local spaceship = GameInstance.player.spaceship
    local maxCharCnt = spaceship:GetRoomCurMaxCharCount(roomId)
    local _, charList = spaceship:TryGetRoomCharList(roomId)
    charInfoPanel:UpdateCharInfo(maxCharCnt, charList)
end
SpaceshipCabinInfoDisplayCtrl.UpdateStatusBar = HL.Method(HL.String) << function(self, roomId)
    local statusBar = self.m_statusBars[roomId]
    if not statusBar then
        return
    end
    local spaceship = GameInstance.player.spaceship
    local roomStatus = spaceship:GetRoomState(roomId)
    statusBar:SwitchRoomState(roomStatus)
end
SpaceshipCabinInfoDisplayCtrl.OnRoomDataChanged = HL.Method(HL.Table) << function(self, args)
    local roomId = unpack(args)
    self:UpdateCharInfoPanel(roomId)
    self:UpdateStatusBar(roomId)
end
SpaceshipCabinInfoDisplayCtrl.OnRoomStateChanged = HL.Method(HL.Table) << function(self, args)
    local roomId = unpack(args)
    self:UpdateStatusBar(roomId)
end
SpaceshipCabinInfoDisplayCtrl.OnGcStateChanged = HL.Method(HL.Opt(HL.Table)) << function(self, args)
    local constGrowCabinId = "grow_cabin_1"
    self:UpdateStatusBar(constGrowCabinId)
end
SpaceshipCabinInfoDisplayCtrl.UpdateAllStatusBar = HL.Method() << function(self)
    local spaceship = GameInstance.player.spaceship
    for roomId, statusBar in pairs(self.m_statusBars) do
        if statusBar then
            local roomStatus = spaceship:GetRoomState(roomId)
            statusBar:SwitchRoomState(roomStatus)
        end
    end
end
SpaceshipCabinInfoDisplayCtrl.UpdateAllCharInfoPanelAndStatusBar = HL.Method() << function(self)
    local spaceship = GameInstance.player.spaceship
    for roomId, charInfoPanel in pairs(self.m_charInfoPanels) do
        if charInfoPanel then
            local maxCharCnt = spaceship:GetRoomCurMaxCharCount(roomId)
            local _, charList = spaceship:TryGetRoomCharList(roomId)
            charInfoPanel:UpdateCharInfo(maxCharCnt, charList)
        end
    end
    self:UpdateAllStatusBar()
end
SpaceshipCabinInfoDisplayCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_statusBars = {}
    self.m_charInfoPanels = {}
end
HL.Commit(SpaceshipCabinInfoDisplayCtrl)