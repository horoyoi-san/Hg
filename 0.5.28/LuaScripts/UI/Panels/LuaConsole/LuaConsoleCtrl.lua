local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.LuaConsole
LuaConsoleCtrl = HL.Class('LuaConsoleCtrl', uiCtrl.UICtrl)
LuaConsoleCtrl.s_messages = HL.StaticField(HL.Table) << {}
LuaConsoleCtrl.s_globalBindingGroupId = HL.StaticField(HL.Number) << -1
LuaConsoleCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeButton.onClick:AddListener(function()
        self:Hide()
    end)
    self.view.inputField.onValidateInput = function(input, charIndex, addedChar)
        return self:_ValidateInput(addedChar)
    end
    self.view.confirmButton.onClick:AddListener(function()
        self:_TryExecute()
    end)
    self:BindInputEvent(CS.Beyond.Input.KeyboardKeyCode.Return, function()
        self:_TryExecute()
    end)
    self:BindInputEvent(CS.Beyond.Input.KeyboardKeyCode.KeypadEnter, function()
        self:_TryExecute()
    end)
    self.view.confirmAndCloseButton.onClick:AddListener(function()
        self:_TryExecute()
        self:Hide()
    end)
    self.view.clearButton.onClick:AddListener(function()
        self:_ClearLog()
    end)
    self:_ClearLog()
end
LuaConsoleCtrl.Init = HL.StaticMethod() << function()
    if not (BEYOND_DEBUG_COMMAND or BEYOND_DEBUG) then
        return
    end
    logger.info("LuaConsoleCtrl.Init")
    LuaConsoleCtrl.s_globalBindingGroupId = InputManagerInst:CreateGroup(-1)
    UIUtils.bindInputEvent(CS.Beyond.Input.KeyboardKeyCode.BackQuote, function()
        LuaConsoleCtrl.ToggleSelf()
    end, "a", InputTimingType.OnClick, LuaConsoleCtrl.s_globalBindingGroupId)
    UIUtils.bindInputEvent(CS.Beyond.Input.KeyboardKeyCode.R, function()
        LuaConsoleCtrl.RefreshScripts()
    end, "a", InputTimingType.OnClick, LuaConsoleCtrl.s_globalBindingGroupId)
    UIUtils.bindInputEvent(CS.Beyond.Input.KeyboardKeyCode.I, function()
        CS.Beyond.UI.UIText.CopyUITextContent()
    end, "a", InputTimingType.OnClick, LuaConsoleCtrl.s_globalBindingGroupId)
    _G.UI = UIManager
    _G.UC = {}
    setmetatable(_G.UC, {
        __index = function(_, k)
            return UIManager.cfgs[k].ctrl
        end
    })
end
LuaConsoleCtrl.OnDisposeLuaEnv = HL.StaticMethod() << function()
    if not (BEYOND_DEBUG_COMMAND or BEYOND_DEBUG) then
        return
    end
    InputManagerInst:DeleteGroup(LuaConsoleCtrl.s_globalBindingGroupId)
end
LuaConsoleCtrl.ToggleSelf = HL.StaticMethod() << function()
    if UIManager:IsShow(PANEL_ID) then
        UIManager:Hide(PANEL_ID)
    else
        LuaConsoleCtrl.AutoOpen(PANEL_ID, nil, true)
        UIManager:SetTopOrder(PANEL_ID)
    end
end
LuaConsoleCtrl.RefreshScripts = HL.StaticMethod() << function()
    Notify(MessageConst.SHOW_TOAST, "刷新Lua脚本……")
    refreshScripts()
    logger.info("开始进行刷新Lua后处理……")
    RedDotManager:UpdateConfigs()
    logger.info("刷新Lua后处理结束")
end
LuaConsoleCtrl.DevOnlyTogglePanel = HL.StaticMethod(HL.Table) << function(args)
    local panelName, isShow = unpack(args)
    if isShow then
        UIManager:Show(PanelId[panelName])
    else
        UIManager:Hide(PanelId[panelName])
    end
end
LuaConsoleCtrl.OnShow = HL.Override() << function(self)
    self.view.inputField:ActivateInputField()
end
LuaConsoleCtrl._ClearLog = HL.Method() << function(self)
    self.view.logContent.text = ""
end
LuaConsoleCtrl._ValidateInput = HL.Method(HL.Number).Return(HL.Any) << function(self, addedChar)
    if addedChar == 10 then
        if not Input.GetKey(Unity.KeyCode.LeftShift) and not Input.GetKey(Unity.KeyCode.RightShift) then
            return ""
        end
    end
    return addedChar
end
LuaConsoleCtrl._TryExecute = HL.Method() << function(self)
    if not self:IsShow() or Input.GetKey(Unity.KeyCode.LeftShift) or Input.GetKey(Unity.KeyCode.RightShift) then
        return
    end
    local str = string.trim(self.view.inputField.text)
    if str == "" then
        return
    end
    CS.Beyond.Lua.LuaCypher.DisableDoStringCypher()
    local logs = Utils.printDoString(str)
    CS.Beyond.Lua.LuaCypher.EnableDoStringCypher()
    local newContent = table.concat(logs or {})
    newContent = string.gsub(newContent, "\r\n", "\n")
    newContent = string.gsub(newContent, "\r", "\n")
    self.view.logContent.text = newContent .. "---\n\n" .. self.view.logContent.text
    self.view.logScroll.verticalNormalizedPosition = 1
    self.view.inputField:ActivateInputField()
end
LuaConsoleCtrl.OnLuaDebugSocketMessage = HL.StaticMethod(HL.Table) << function(arg)
    local socketMgr, str = unpack(arg)
    CS.Beyond.Lua.LuaCypher.DisableDoStringCypher()
    local logs = Utils.printDoString(str)
    CS.Beyond.Lua.LuaCypher.EnableDoStringCypher()
    local newContent = table.concat(logs or {})
    newContent = string.gsub(newContent, "\n", "\r\n")
    socketMgr:SendString("---------------------------------------------------------------------------------------------------\r\n")
    socketMgr:SendString(newContent)
    socketMgr:SendString("---------------------------------------------------------------------------------------------------\r\n\r\n>")
end
HL.Commit(LuaConsoleCtrl)