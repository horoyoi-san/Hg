local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FakeControllerSmallMenu
FakeControllerSmallMenuCtrl = HL.Class('FakeControllerSmallMenuCtrl', uiCtrl.UICtrl)
local DEFAULT_PANEL_OFFSET = 5
FakeControllerSmallMenuCtrl.m_currMenuData = HL.Field(HL.Table)
FakeControllerSmallMenuCtrl.m_menuDataStack = HL.Field(HL.Forward("Stack"))
FakeControllerSmallMenuCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.CLOSE_CONTROLLER_SMALL_MENU] = 'CloseControllerSmallMenu', [MessageConst.ON_INPUT_DEVICE_TYPE_CHANGED] = 'OnInputDeviceTypeChanged', }
FakeControllerSmallMenuCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.highlightCell.maskNode.onClick:AddListener(function()
        self:_OnClickClose()
    end)
    self.m_menuDataStack = require_ex("Common/Utils/DataStructure/Stack")()
end
FakeControllerSmallMenuCtrl.m_lateTickKey = HL.Field(HL.Number) << -1
FakeControllerSmallMenuCtrl.OnShow = HL.Override() << function(self)
    self.m_lateTickKey = LuaUpdate:Add("LateTick", function(deltaTime)
        self:_RefreshHighlight()
    end)
end
FakeControllerSmallMenuCtrl.OnHide = HL.Override() << function(self)
    self:_Clear()
end
FakeControllerSmallMenuCtrl.OnClose = HL.Override() << function(self)
    self:_Clear()
end
FakeControllerSmallMenuCtrl.ShowAsControllerSmallMenu = HL.StaticMethod(HL.Table) << function(args)
    local self = FakeControllerSmallMenuCtrl.AutoOpen(PANEL_ID, nil, true)
    self:_TryRefresh(args)
end
FakeControllerSmallMenuCtrl.OnInputDeviceTypeChanged = HL.Method(HL.Table) << function(self, arg)
    self:_ForceClose()
end
FakeControllerSmallMenuCtrl.CloseControllerSmallMenu = HL.Method(HL.Number) << function(self, panelId)
    if not self:IsShow() then
        return
    end
    self:_TryClose(panelId)
end
FakeControllerSmallMenuCtrl._OnPanelInputBlocked = HL.Override(HL.Boolean) << function(self, active)
    self.view.highlightCell.gameObject:SetActiveIfNecessary(active)
end
FakeControllerSmallMenuCtrl._Clear = HL.Method() << function(self)
    LuaUpdate:Remove(self.m_lateTickKey)
    self.m_lateTickKey = -1
    Notify(MessageConst.TOGGLE_LEVEL_CAMERA_MOVE, { "guide", true })
    CoroutineManager:ClearAllCoroutine(self)
end
FakeControllerSmallMenuCtrl._OnClickClose = HL.Method() << function(self)
    if self.m_currMenuData and not self.m_currMenuData.canClickClose then
        return
    end
    self:_ForceClose()
end
FakeControllerSmallMenuCtrl._TryRefresh = HL.Method(HL.Table) << function(self, args)
    local id = args.panelId
    if id == nil then
        return
    end
    if not self.m_menuDataStack:Empty() then
        local peekMenuData = self.m_menuDataStack:Peek()
        if peekMenuData ~= nil then
            if peekMenuData.id == id then
                self.m_menuDataStack:Pop()
            else
                self:_TransferParent(peekMenuData)
            end
        end
    end
    self.m_menuDataStack:Push(args)
    self:_Refresh(self.m_menuDataStack:Peek())
end
FakeControllerSmallMenuCtrl._Refresh = HL.Method(HL.Table) << function(self, menuData)
    if menuData == nil then
        return
    end
    local id = menuData.id
    local isGroup = menuData.isGroup
    local oldGroupId = InputManagerInst:GetGroupParentId(isGroup, id)
    InputManagerInst:ChangeParent(isGroup, id, self.view.inputGroup.groupId)
    local needShowType = menuData.useVirtualMouse and Types.EPanelMouseMode.NeedShow or Types.EPanelMouseMode.ForceHide
    self:ChangePanelCfg("virtualMouseMode", needShowType)
    menuData.oldGroupId = oldGroupId
    self:_ChangePanelOrder(menuData)
    if menuData.hintPlaceholder ~= nil then
        local hintArgs = menuData.hintPlaceholder:GetArgs()
        hintArgs.panelId = PANEL_ID
        hintArgs.groupIds = { self.view.inputGroup.groupId }
        hintArgs.optionalActionIds = nil
        hintArgs.offset = 1
        Notify(MessageConst.SHOW_CONTROLLER_HINT, hintArgs)
    end
    if menuData.walletPlaceholder ~= nil then
        local walletArgs = menuData.walletPlaceholder:GetArgs()
        walletArgs.panelId = PANEL_ID
        walletArgs.offset = 1
        Notify(MessageConst.SHOW_WALLET_BAR, walletArgs)
    end
    self.m_currMenuData = menuData
    self:_RefreshHighlight()
end
FakeControllerSmallMenuCtrl._RefreshHighlight = HL.Method() << function(self)
    if not self.view.highlightCell.gameObject.activeSelf then
        return
    end
    local cell = self.view.highlightCell
    cell.canvasGroup.alpha = 0
    if self.m_currMenuData == nil then
        return
    end
    local target = self.m_currMenuData.rectTransform
    if target == nil then
        return
    end
    local rectTrans = cell.rectTransform
    local targetRect = UIUtils.getUIRectOfRectTransform(target, self.uiCamera)
    rectTrans.anchoredPosition = Vector2(targetRect.center.x, -targetRect.center.y)
    rectTrans.sizeDelta = targetRect.size
    local width = UIManager.uiCanvasRect.rect.size.x
    local height = UIManager.uiCanvasRect.rect.size.y
    local xOffset = width / 2 - targetRect.center.x
    cell.up.anchoredPosition = Vector2(xOffset, 0)
    cell.down.anchoredPosition = Vector2(xOffset, 0)
    cell.up.sizeDelta = Vector2(width, targetRect.y)
    cell.down.sizeDelta = Vector2(width, height - targetRect.yMax)
    cell.left.sizeDelta = Vector2(targetRect.x, targetRect.height)
    cell.right.sizeDelta = Vector2(width - targetRect.xMax, targetRect.height)
    cell.canvasGroup.alpha = self.m_currMenuData.noHighlight and 0 or 1
end
FakeControllerSmallMenuCtrl._ChangePanelOrder = HL.Method(HL.Table) << function(self, menuData)
    if menuData == nil then
        return
    end
    local panelId = menuData.panelId
    if panelId == nil then
        return
    end
    local isOpen, panel = UIManager:IsOpen(panelId)
    if panel == nil then
        return
    end
    local offset = menuData.panelOffset or DEFAULT_PANEL_OFFSET
    local selfPanelOrder = panel:GetSortingOrder() + offset
    self:SetSortingOrder(selfPanelOrder, false)
    UIManager:CalcOtherSystemPropertyByPanelOrder()
end
FakeControllerSmallMenuCtrl._ForceClose = HL.Method() << function(self)
    if self.m_menuDataStack:Empty() then
        return
    end
    self:_Close(self.m_menuDataStack:Peek())
    self:Hide()
end
FakeControllerSmallMenuCtrl._TryClose = HL.Method(HL.Number) << function(self, panelId)
    if self.m_menuDataStack:Empty() then
        return
    end
    local index, closeMenuData
    for i = self.m_menuDataStack:Count(), 1, -1 do
        local menuData = self.m_menuDataStack:Get(i)
        if menuData ~= nil and menuData.panelId == panelId then
            index = i
            closeMenuData = menuData
            break
        end
    end
    if closeMenuData == nil then
        return
    end
    if index == self.m_menuDataStack:Count() then
        self:_Close(closeMenuData)
    end
    self.m_menuDataStack:Delete(closeMenuData)
    if self.m_menuDataStack:Empty() then
        self:Hide()
    else
        self:_Refresh(self.m_menuDataStack:Peek())
    end
end
FakeControllerSmallMenuCtrl._Close = HL.Method(HL.Table) << function(self, menuData)
    if menuData == nil then
        return
    end
    if menuData.hintPlaceholder ~= nil then
        Notify(MessageConst.HIDE_CONTROLLER_HINT, { panelId = PANEL_ID, })
        menuData.hintPlaceholder = nil
    end
    if menuData.walletPlaceholder ~= nil then
        Notify(MessageConst.HIDE_WALLET_BAR, PANEL_ID)
        menuData.walletPlaceholder = nil
    end
    local id = menuData.id
    local isGroup = menuData.isGroup
    local oldGroupId = menuData.oldGroupId
    InputManagerInst:ChangeParent(isGroup, id, oldGroupId)
    if menuData.onClose then
        menuData.onClose()
    end
    self.m_currMenuData = nil
end
FakeControllerSmallMenuCtrl._TransferParent = HL.Method(HL.Table) << function(self, menuData)
    if menuData == nil then
        return
    end
    local id = menuData.id
    local isGroup = menuData.isGroup
    local oldGroupId = menuData.oldGroupId
    InputManagerInst:ChangeParent(isGroup, id, oldGroupId)
    if menuData.hintPlaceholder ~= nil then
        Notify(MessageConst.HIDE_CONTROLLER_HINT, { panelId = PANEL_ID, })
    end
    if menuData.walletPlaceholder ~= nil then
        Notify(MessageConst.HIDE_WALLET_BAR, PANEL_ID)
    end
end
HL.Commit(FakeControllerSmallMenuCtrl)