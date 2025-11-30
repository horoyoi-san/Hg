local LevelWorldUIBase = require_ex('UI/Widgets/LevelWorldUIBase')
SSStatusBarBase = HL.Class('SSStatusBarBase', LevelWorldUIBase)
SSStatusBarBase.m_stateHandleFuncLut = HL.Field(HL.Table)
SSStatusBarBase.m_roomId = HL.Field(HL.String) << ""
SSStatusBarBase.m_currentState = HL.Field(CS.Beyond.Gameplay.SpaceshipSystem.RoomState)
SSStatusBarBase._OnFirstTimeInit = HL.Override() << function(self)
    self:SetupSwitchStateHandleFunctions()
end
SSStatusBarBase.InitLevelWorldUi = HL.Override(HL.Any) << function(self, args)
    self:_FirstTimeInit()
    self.m_roomId = args[CSIndex(1)]
    self:SetupView()
    self.m_currentState = CS.Beyond.Gameplay.SpaceshipSystem.RoomState.Locked
    local args = {}
    args.roomId = self.m_roomId
    args.statusBar = self
    Notify(MessageConst.SS_REGISTER_STATUS_BAR, args)
end
SSStatusBarBase.SetupSwitchStateHandleFunctions = HL.Virtual() << function(self)
end
SSStatusBarBase.SetupView = HL.Virtual() << function(self)
end
SSStatusBarBase.OnLevelWorldUiReleased = HL.Override() << function(self)
    Notify(MessageConst.SS_UNREGISTER_STATUS_BAR, self.m_roomId)
end
SSStatusBarBase.SwitchRoomState = HL.Method(CS.Beyond.Gameplay.SpaceshipSystem.RoomState) << function(self, roomState)
    if self.m_stateHandleFuncLut and self.m_stateHandleFuncLut[roomState] then
        self.m_stateHandleFuncLut[roomState](self)
    end
    self.m_currentState = roomState
end
HL.Commit(SSStatusBarBase)
return SSStatusBarBase