local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacDestroyMode
FacDestroyModeCtrl = HL.Class('FacDestroyModeCtrl', uiCtrl.UICtrl)
FacDestroyModeCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.FAC_EXIT_DESTROY_MODE] = 'ExitMode', [MessageConst.FAC_ON_TOGGLE_BATH_MODE] = 'OnToggleBathMode', [MessageConst.FAC_ON_DRAG_BEGIN_IN_BATH_MODE] = 'OnDragBeginInBathMode', [MessageConst.FAC_ON_DRAG_END_IN_BATH_MODE] = 'OnDragEndInBathMode', }
FacDestroyModeCtrl.m_hideKey = HL.Field(HL.Number) << -1
FacDestroyModeCtrl.m_confirmBatchDelBindingId = HL.Field(HL.Number) << -1
FacDestroyModeCtrl.m_exitBindingId = HL.Field(HL.Number) << -1
FacDestroyModeCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.exitButton.onClick:AddListener(function()
        self:ExitMode()
    end)
    self.m_confirmBatchDelBindingId = self:BindInputPlayerAction("fac_dismantle_device", function()
        self:_ConfirmBatchDel()
    end)
    self.view.delButton.onClick:AddListener(function()
        self:_OnClickDel(false)
    end)
    self.view.delAllButton.onClick:AddListener(function()
        self:_OnClickDel(true)
    end)
    self.view.hidePipeToggle.toggle.onValueChanged:AddListener(function(isOn)
        self:_OnChangeHideToggle(isOn)
    end)
    self:BindInputPlayerAction("fac_disable_mouse1_sprint", function()
    end)
    self:_InitKeyHint()
end
FacDestroyModeCtrl._ToggleExitBinding = HL.Method(HL.Boolean) << function(self, active)
    if active then
        if self.m_exitBindingId == -1 then
            self.m_exitBindingId = self:BindInputPlayerAction("fac_exit_dismantle_device", function()
                self:ExitMode()
            end)
        end
    else
        self.m_exitBindingId = self:DeleteInputBinding(self.m_exitBindingId)
    end
end
FacDestroyModeCtrl.OnClose = HL.Override() << function(self)
    if LuaSystemManager.facSystem.inDestroyMode then
        self:_RealExitMode()
    else
        self:_ClearOnExit()
    end
end
FacDestroyModeCtrl.EnterMode = HL.StaticMethod() << function()
    local self = UIManager:AutoOpen(PANEL_ID)
    self:_OnEnterMode()
end
FacDestroyModeCtrl._OnEnterMode = HL.Method() << function(self)
    LuaSystemManager.facSystem.inDestroyMode = true
    self.m_hideKey = UIManager:ClearScreen({ PANEL_ID, PanelId.MainHud, PanelId.FacHudBottomMask, PanelId.LevelCamera, PanelId.FacBuildingInteract, PanelId.InteractOption, PanelId.Joystick, PanelId.FacPowerPoleLinkingLabel, PanelId.FacPowerPoleTravelHint, PanelId.HeadLabel, PanelId.FacTopView, PanelId.FacTopViewBuildingInfo, })
    Notify(MessageConst.TOGGLE_FORBID_ATTACK, { "FacDestroyModeCtrl", true })
    self.m_updateKey = LuaUpdate:Add("Tick", function()
        self:_Update()
    end, true)
    local inTopView = LuaSystemManager.facSystem.inTopView
    local showHidePipe = LuaSystemManager.facSystem.inTopView and FactoryUtils.canShowPipe()
    self.view.hidePipeToggle.gameObject:SetActive(showHidePipe)
    self.view.hidePipeToggle.toggle:SetIsOnWithoutNotify(false)
    self:_OnChangeHideToggle(false)
    self.view.delButton.gameObject:SetActive(inTopView)
    self.view.delAllButton.gameObject:SetActive(inTopView)
    Notify(MessageConst.ON_FAC_DESTROY_MODE_CHANGE, true)
    if LuaSystemManager.facSystem.inTopView then
        Notify(MessageConst.CHANGE_MOUSE_ICON_HINT, { name = "FacDestroyMode-DesMode", type = UIConst.MOUSE_ICON_HINT.Delete, })
    end
    self:_ToggleExitBinding(true)
end
FacDestroyModeCtrl.ExitMode = HL.Method(HL.Opt(HL.Boolean)) << function(self, skipAnim)
    if not LuaSystemManager.facSystem.inDestroyMode then
        return
    end
    if LuaSystemManager.facSystem.inTopView then
        Notify(MessageConst.CHANGE_MOUSE_ICON_HINT, { name = "FacDestroyMode-DesMode", type = UIConst.MOUSE_ICON_HINT.Default, })
    end
    FactoryUtils.stopLogisticFigureRenderer()
    if not skipAnim then
        self:PlayAnimationOutWithCallback(function()
            self:_RealExitMode()
        end)
    else
        self:_RealExitMode()
    end
end
FacDestroyModeCtrl._RealExitMode = HL.Method() << function(self)
    self:Hide()
    self:_ClearOnExit()
    LuaSystemManager.facSystem.inDestroyMode = false
    Notify(MessageConst.ON_FAC_DESTROY_MODE_CHANGE, false)
    Notify(MessageConst.TOGGLE_FORBID_ATTACK, { "FacDestroyModeCtrl", false })
end
FacDestroyModeCtrl._ClearOnExit = HL.Method() << function(self)
    self.m_hideKey = UIManager:RecoverScreen(self.m_hideKey)
    self.m_updateKey = LuaUpdate:Remove(self.m_updateKey)
end
FacDestroyModeCtrl._OnChangeHideToggle = HL.Method(HL.Boolean) << function(self, isOn)
    if isOn then
        FactoryUtils.startPipeFigureRenderer()
    else
        FactoryUtils.stopLogisticFigureRenderer()
    end
end
FacDestroyModeCtrl.OnDragBeginInBathMode = HL.Method() << function(self)
    self.view.keyHintNode.gameObject:SetActive(false)
    self:_ToggleExitBinding(false)
end
FacDestroyModeCtrl.OnDragEndInBathMode = HL.Method() << function(self)
    self:_ToggleExitBinding(true)
    self.view.keyHintNode.gameObject:SetActive(true)
end
FacDestroyModeCtrl.OnToggleBathMode = HL.Method(HL.Boolean) << function(self, active)
    InputManagerInst:ToggleBinding(self.m_confirmBatchDelBindingId, active)
end
FacDestroyModeCtrl._ConfirmBatchDel = HL.Method() << function(self)
    local targets = LuaSystemManager.facSystem.batchSelectTargets
    if not next(targets) then
        return
    end
    local nodeList = {}
    local Dictionary_UInt_ListInt = CS.System.Collections.Generic.Dictionary(CS.System.UInt32, CS.System.Collections.Generic["List`1[System.Int32]"])
    local beltInfos = Dictionary_UInt_ListInt()
    local count = 0
    for id, info in pairs(targets) do
        if info == true then
            table.insert(nodeList, id)
        else
            local list = {}
            for k, _ in pairs(info) do
                table.insert(list, k)
            end
            beltInfos[id] = list
        end
        count = count + 1
    end
    if count >= FacConst.BATCH_DEL_HINT_COUNT then
        Notify(MessageConst.SHOW_POP_UP, {
            content = Language.LUA_FAC_CONFIRM_BATCH_DEL_A_LOT,
            onConfirm = function()
                GameInstance.player.remoteFactory.core:Message_OpDismantleBatch(Utils.getCurrentChapterId(), nodeList, beltInfos)
            end
        })
    else
        GameInstance.player.remoteFactory.core:Message_OpDismantleBatch(Utils.getCurrentChapterId(), nodeList, beltInfos)
    end
end
FacDestroyModeCtrl.m_updateKey = HL.Field(HL.Number) << -1
FacDestroyModeCtrl._Update = HL.Method() << function(self)
    if DeviceInfo.usingTouch then
        if LuaSystemManager.facSystem.inBatchSelectMode then
            self.view.delButton.gameObject:SetActiveIfNecessary(next(LuaSystemManager.facSystem.batchSelectTargets) ~= nil)
            self.view.delAllButton.gameObject:SetActiveIfNecessary(false)
        else
            local _, interact = UIManager:IsOpen(PanelId.FacBuildingInteract)
            self.view.delButton.gameObject:SetActiveIfNecessary((interact.m_selectedInteractFacNodeId or interact.m_selectedInteractLogisticPos or interact.m_selectedInteractPipeNodeId) ~= nil)
            self.view.delAllButton.gameObject:SetActiveIfNecessary(interact.m_selectedInteractLogisticPos ~= nil)
        end
    else
        self:_UpdateKeyHintStates()
    end
end
local KeyHints = { normal = { "fac_exit_dismantle_device", }, top_view_building = { "fac_top_view_dismantle_confirm", "fac_exit_dismantle_device", }, top_view_belt = { "fac_top_view_dismantle_confirm", "fac_top_view_dismantle_whole_belt_confirm", "fac_exit_dismantle_device", }, batch_empty = { "fac_batch_select", "fac_batch_drag_select", "fac_batch_drag_unselect", "fac_exit_dismantle_device", }, batch_not_empty = { "fac_batch_select", "fac_batch_drag_select", "fac_batch_drag_unselect", "fac_exit_dismantle_device", }, }
FacDestroyModeCtrl.m_keyHintCells = HL.Field(HL.Forward('UIListCache'))
FacDestroyModeCtrl.m_keyHintName = HL.Field(HL.String) << ''
FacDestroyModeCtrl._InitKeyHint = HL.Method() << function(self)
    self.m_keyHintCells = UIUtils.genCellCache(self.view.keyHintCell)
end
FacDestroyModeCtrl._RefreshKeyHint = HL.Method(HL.Opt(HL.String)) << function(self, name)
    self.m_keyHintName = name
    local keyHint = KeyHints[name]
    if not keyHint then
        self.m_keyHintCells:Refresh(0)
        return
    end
    local count = #keyHint
    local preActionIds, preActionIdCount
    self.m_keyHintCells:Refresh(count, function(cell, index)
        local actionId
        if preActionIds then
            actionId = preActionIds[index] or keyHint[index - preActionIdCount]
        else
            actionId = keyHint[index]
        end
        cell.actionKeyHint:SetActionId(actionId)
        cell.gameObject.name = "KeyHint-" .. actionId
    end)
end
FacDestroyModeCtrl._UpdateKeyHintStates = HL.Method() << function(self)
    local name = "normal"
    local hasTarget = false
    if LuaSystemManager.facSystem.inTopView then
        if LuaSystemManager.facSystem.inBatchSelectMode then
            if next(LuaSystemManager.facSystem.batchSelectTargets) then
                hasTarget = true
                name = "batch_not_empty"
            else
                name = "batch_empty"
            end
        else
            local ctrl = LuaSystemManager.facSystem.interactPanelCtrl
            if ctrl.m_interactFacNodeId then
                hasTarget = true
                name = "top_view_building"
            elseif ctrl.m_interactLogisticPos then
                hasTarget = true
                name = "top_view_belt"
            end
        end
    end
    if name ~= self.m_keyHintName then
        self:_RefreshKeyHint(name)
    end
    self.view.confirmDesKeyHint.gameObject:SetActiveIfNecessary(hasTarget)
end
FacDestroyModeCtrl._OnClickDel = HL.Method(HL.Boolean) << function(self, isAll)
    if LuaSystemManager.facSystem.inBatchSelectMode then
        self:_ConfirmBatchDel()
    else
        local _, interactCtrl = UIManager:IsOpen(PanelId.FacBuildingInteract)
        interactCtrl:_OnClickFakeInteractOption(isAll)
    end
end
HL.Commit(FacDestroyModeCtrl)