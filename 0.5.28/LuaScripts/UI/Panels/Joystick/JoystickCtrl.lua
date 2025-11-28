local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.Joystick
JoystickCtrl = HL.Class('JoystickCtrl', uiCtrl.UICtrl)
JoystickCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_TOGGLE_SPRINT] = 'OnToggleSprint', [MessageConst.ON_TOGGLE_DEBUG_FLY] = "OnToggleDebugFly", [MessageConst.TOGGLE_PLAYER_MOVE] = 'TogglePlayerMove', [MessageConst.ON_TOGGLE_VIRTUAL_MOUSE] = 'OnToggleVirtualMouse', }
JoystickCtrl.m_updateKey = HL.Field(HL.Number) << -1
JoystickCtrl.m_inWalkMode = HL.Field(HL.Boolean) << false
JoystickCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_disablePlayerMoveKeys = {}
    if BEYOND_DEBUG then
        self:BindInputEvent(CS.Beyond.Input.KeyboardKeyCode.F5, function()
            self:_ToggleHideCursor()
        end)
        if CS.Beyond.DebugDefines.disableF5Mode then
            if InputManagerInst.inHideCursorMode then
                self:_ToggleHideCursor()
            end
        end
    end
    self:BindInputPlayerAction("common_toggle_walk", function()
        self:_ToggleWalk()
    end)
    self.view.joystick.onMoveStart:AddListener(function()
        GameInstance.playerController:ProduceMoveCommand()
    end)
    self.view.joystick.onTouchEnd:AddListener(function()
        GameInstance.playerController:ConsumeMoveCommand()
    end)
end
JoystickCtrl.OnShow = HL.Override() << function(self)
    self:_AddRegisters()
end
JoystickCtrl.OnHide = HL.Override() << function(self)
    self:_ClearRegisters()
end
JoystickCtrl.OnClose = HL.Override() << function(self)
    self:_ClearRegisters()
    if BEYOND_DEBUG and GameInstance.playerController.inFlyMode then
        CS.Beyond.Gameplay.Core.PlayerController.ToggleFlyingMode()
    end
end
JoystickCtrl._AddRegisters = HL.Method() << function(self)
    self.m_updateKey = LuaUpdate:Add("Tick", function()
        self:_Update()
    end)
end
JoystickCtrl._ClearRegisters = HL.Method() << function(self)
    GameInstance.playerController:UpdateMoveCommand(Vector2.zero)
    self.m_updateKey = LuaUpdate:Remove(self.m_updateKey)
end
JoystickCtrl._ToggleHideCursor = HL.Method() << function(self)
    InputManagerInst:ToggleHideCursor()
end
JoystickCtrl._Update = HL.Method() << function(self)
    self:_UpdateMove()
end
JoystickCtrl._UpdateMove = HL.Method() << function(self)
    if not self:CanPlayerMove() then
        return
    end
    local dir = self.view.joystick.jsValue
    if LuaSystemManager.facSystem.inTopView then
        local spd = InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.LeftShift) and 35 or 15
        LuaSystemManager.facSystem:MoveTopViewCamTarget(dir * spd * Time.deltaTime)
    else
        GameInstance.playerController:UpdateMoveCommand(dir)
    end
end
JoystickCtrl._ToggleWalk = HL.Method() << function(self)
    if FactoryUtils.isInTopView() then
        return
    end
    GameInstance.playerController:ToggleWalk()
end
JoystickCtrl.OnToggleSprint = HL.Method(HL.Table) << function(self, arg)
    local isSprint = unpack(arg)
    if isSprint and self.m_inWalkMode then
        self:_ToggleWalk()
    end
end
JoystickCtrl.m_disablePlayerMoveKeys = HL.Field(HL.Table)
JoystickCtrl.TogglePlayerMove = HL.Method(HL.Table) << function(self, args)
    logger.info("JoystickCtrl.TogglePlayerMove", inspect(args))
    local key, enable = unpack(args)
    if enable then
        self.m_disablePlayerMoveKeys[key] = nil
    else
        self.m_disablePlayerMoveKeys[key] = true
        GameInstance.playerController:UpdateMoveCommand(Vector2.zero)
    end
end
JoystickCtrl.OnToggleVirtualMouse = HL.Method(HL.Table) << function(self, args)
    local isActive = unpack(args)
    self:TogglePlayerMove({ "VirtualMouse", not isActive })
end
JoystickCtrl.CanPlayerMove = HL.Method().Return(HL.Boolean) << function(self)
    return next(self.m_disablePlayerMoveKeys) == nil
end
JoystickCtrl.m_flyModeUpPressKey = HL.Field(HL.Number) << -1
JoystickCtrl.m_flyModeUpReleaseKey = HL.Field(HL.Number) << -1
JoystickCtrl.m_flyModeDownPressKey = HL.Field(HL.Number) << -1
JoystickCtrl.m_flyModeDownReleaseKey = HL.Field(HL.Number) << -1
JoystickCtrl.OnToggleDebugFly = HL.Method() << function(self)
    if BEYOND_DEBUG_COMMAND then
        local inFlyMode = GameInstance.playerController.inFlyMode
        self:DeleteInputBinding(self.m_flyModeUpPressKey)
        self:DeleteInputBinding(self.m_flyModeUpReleaseKey)
        self:DeleteInputBinding(self.m_flyModeDownPressKey)
        self:DeleteInputBinding(self.m_flyModeDownReleaseKey)
        if inFlyMode then
            self.m_flyModeDownPressKey = self:BindInputPlayerAction("common_debug_fly_down_start", function()
                GameInstance.playerController:ToggleFly(-1.0, true)
            end)
            self.m_flyModeDownReleaseKey = self:BindInputPlayerAction("common_debug_fly_down_end", function()
                GameInstance.playerController:ToggleFly(-1.0, false)
            end)
            self.m_flyModeUpPressKey = self:BindInputPlayerAction("common_debug_fly_up_start", function()
                GameInstance.playerController:ToggleFly(1.0, true)
            end)
            self.m_flyModeUpReleaseKey = self:BindInputPlayerAction("common_debug_fly_up_end", function()
                GameInstance.playerController:ToggleFly(1.0, false)
            end)
        end
        Notify(MessageConst.SHOW_TOAST, inFlyMode and "角色飞行模式 开" or "角色飞行模式 关")
    end
end
HL.Commit(JoystickCtrl)