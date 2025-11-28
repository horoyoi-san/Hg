local autoCalcOrderUICtrl = require_ex('UI/Panels/Base/AutoCalcOrderUICtrl')
local PANEL_ID = PanelId.ControllerHint
ControllerHintCtrl = HL.Class('ControllerHintCtrl', autoCalcOrderUICtrl.AutoCalcOrderUICtrl)
ControllerHintCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.HIDE_CONTROLLER_HINT] = 'HideControllerHint', [MessageConst.REFRESH_CONTROLLER_HINT] = 'RefreshControllerHint', [MessageConst.REFRESH_CONTROLLER_HINT_CONTENT_IMMEDIATELY] = 'RefreshContentImmediately', [MessageConst.PLAY_CONTROLLER_HINT_OUT_ANIM] = 'PlayOutAnim', }
ControllerHintCtrl.m_barCellCache = HL.Field(HL.Forward('CommonCache'))
ControllerHintCtrl.m_curBarCells = HL.Field(HL.Table)
ControllerHintCtrl.m_virtualMouseLongPressFakeBindingId = HL.Field(HL.Number) << -1
ControllerHintCtrl.m_virtualMouseHoverTarget = HL.Field(CS.UnityEngine.UI.Selectable)
ControllerHintCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_attachedPanels = {}
    self.m_curBarCells = {}
    self.view.barCell.gameObject:SetActive(false)
    self.m_barCellCache = require_ex("Common/Utils/CommonCache").CommonCache(function()
        local obj = CSUtils.CreateObject(self.view.barCell.gameObject, self.view.main.transform)
        local barCell = Utils.wrapLuaNode(obj)
        barCell.keyHintCells = UIUtils.genCellCache(barCell.keyHint)
        return barCell
    end, function(barCell)
        barCell.gameObject:SetActive(true)
    end, function(barCell)
        barCell.keyHintCells:Refresh(0, nil, nil, function(cell)
            self:_ClearRedDot(cell)
            cell.actionKeyHint:SetActionId(nil)
        end)
        barCell.gameObject:SetActive(false)
    end)
    self.m_lateTickFunc = function()
        self:_LateTick()
    end
end
ControllerHintCtrl.ShowControllerHint = HL.StaticMethod(HL.Table) << function(args)
    local self = ControllerHintCtrl.AutoOpen(PANEL_ID, nil, true)
    local newPanelArgs = self:_AddPanelArgs(args)
    self:_AttachToPanel(newPanelArgs)
end
ControllerHintCtrl._AddPanelArgs = HL.Method(HL.Table).Return(HL.Table) << function(self, args)
    local panelId = args.panelId
    local panelArgs = self.m_attachedPanels[panelId]
    if not panelArgs then
        panelArgs = { panelId = panelId, offset = args.offset, count = 0, subArgs = {}, }
    end
    if not panelArgs.subArgs[args.placeHolderObject] then
        panelArgs.count = panelArgs.count + 1
    end
    panelArgs.subArgs[args.placeHolderObject] = args
    return panelArgs
end
ControllerHintCtrl.HideControllerHint = HL.Method(HL.Table) << function(self, args)
    local panelId = args.panelId
    local panelArgs = self.m_attachedPanels[panelId]
    if not panelArgs then
        return
    end
    local placeHolderObject = args.placeHolderObject
    if placeHolderObject then
        panelArgs.subArgs[placeHolderObject] = nil
        if not next(panelArgs.subArgs) then
            self:_CustomHide(panelId)
        else
            panelArgs.count = panelArgs.count - 1
            self:_OnBarChanged(false)
        end
    else
        self:_CustomHide(panelId)
    end
end
ControllerHintCtrl.RefreshControllerHint = HL.Method() << function(self)
    for _, barCell in pairs(self.m_curBarCells) do
        barCell.keyHintCells:Update(function(cell)
            cell.actionKeyHint:UpdateKeyHint()
        end)
    end
end
ControllerHintCtrl.CustomSetPanelOrder = HL.Override(HL.Opt(HL.Number, HL.Table)) << function(self, maxOrder, args)
    self:SetSortingOrder(maxOrder, false)
    self.m_curArgs = args
    if self:IsHide() then
        self:Show()
    else
        self:PlayAnimationIn()
    end
    self:_OnBarChanged(true)
end
ControllerHintCtrl.RefreshContentImmediately = HL.Method() << function(self)
    self:_OnBarChanged(false)
end
ControllerHintCtrl._OnBarChanged = HL.Method(HL.Boolean) << function(self)
    if not DeviceInfo.usingController then
        return
    end
    if not self.m_curArgs then
        return
    end
    if self:IsPlayingAnimationOut() then
        return
    end
    local subArgs = self.m_curArgs.subArgs
    local newCells = {}
    for obj, cell in pairs(self.m_curBarCells) do
        local args = subArgs[obj]
        if not args then
            self.m_barCellCache:Cache(cell)
        else
            newCells[obj] = cell
        end
    end
    for obj, args in pairs(subArgs) do
        if not newCells[obj] then
            local cell = self.m_barCellCache:Get()
            newCells[obj] = cell
            self:_RefreshSingleBarContent(cell, args, true)
        end
    end
    self.m_curBarCells = newCells
end
ControllerHintCtrl._RefreshAllBars = HL.Method() << function(self)
    if not DeviceInfo.usingController then
        return
    end
    if not self.m_curArgs then
        return
    end
    if self:IsPlayingAnimationOut() then
        return
    end
    local subArgs = self.m_curArgs.subArgs
    for panelObj, barCell in pairs(self.m_curBarCells) do
        local args = subArgs[panelObj]
        self:_RefreshSingleBarContent(barCell, args, false)
    end
end
ControllerHintCtrl._RefreshSingleBarContent = HL.Method(HL.Table, HL.Table, HL.Boolean) << function(self, barCell, args, isInit)
    local needMouseHint = args.isMain and not self:IsPlayingAnimationIn()
    local infoList = self:_GetKeyHintInfos(args, needMouseHint)
    local count = #infoList
    barCell.keyHintCells:Refresh(count, function(cell, index)
        local info = infoList[index]
        self:_UpdateCell(cell, info)
    end, nil, function(cell)
        self:_ClearRedDot(cell)
        cell.actionKeyHint:SetActionId(nil)
    end)
    self:_SetContentTransformState(barCell, args, isInit, args.useBG)
end
ControllerHintCtrl._GetKeyHintInfos = HL.Method(HL.Table, HL.Boolean).Return(HL.Table) << function(self, args, needMouseHint)
    local infoList = {}
    local clickHintInfo, clickHintText
    if not needMouseHint then
        local mouseHoverTarget = InputManagerInst.virtualMouse:GetCurHoverSelectable()
        if self.m_virtualMouseHoverTarget ~= mouseHoverTarget then
            InputManagerInst:DeleteBinding(self.m_virtualMouseLongPressFakeBindingId)
            self.m_virtualMouseLongPressFakeBindingId = -1
        end
        if mouseHoverTarget then
            local succ, clickTextId, longPressTextId = mouseHoverTarget:GetMouseActionHints()
            if succ then
                if not string.isEmpty(clickTextId) then
                    clickHintInfo = { actionId = InputManager.s_virtualMouseClickHintActionId, textId = clickTextId, }
                    clickHintText = Language[clickTextId]
                    table.insert(infoList, clickHintInfo)
                end
                if not string.isEmpty(longPressTextId) then
                    local info = { actionId = InputManager.s_virtualMouseLongPressHintActionId, textId = longPressTextId, }
                    if self.m_virtualMouseHoverTarget ~= mouseHoverTarget then
                        self.m_virtualMouseLongPressFakeBindingId = self:BindInputPlayerAction(InputManager.s_virtualMouseLongPressHintActionId, function()
                        end)
                    end
                    info.bindingId = self.m_virtualMouseLongPressFakeBindingId
                    table.insert(infoList, info)
                end
            end
        end
        self.m_virtualMouseHoverTarget = mouseHoverTarget
    else
        if self.m_virtualMouseHoverTarget then
            InputManagerInst:DeleteBinding(self.m_virtualMouseLongPressFakeBindingId)
            self.m_virtualMouseLongPressFakeBindingId = -1
            self.m_virtualMouseHoverTarget = nil
        end
    end
    local infoCSList = InputManagerInst:GetEmptyControllerHintInfoList()
    infoCSList:Clear()
    for _, groupId in pairs(args.groupIds) do
        InputManagerInst:GetControllerHintInfos(groupId, infoCSList)
    end
    InputManagerInst:GetControllerHintInfos(args.optionalActionIds, infoCSList)
    for _, info in pairs(infoCSList) do
        table.insert(infoList, info)
    end
    if args.customGetKeyHintInfos then
        args.customGetKeyHintInfos(infoList)
    end
    return infoList
end
ControllerHintCtrl._UpdateCell = HL.Method(HL.Table, HL.Any) << function(self, cell, info)
    local actionId = info.actionId
    local hintView = info.hintView
    local textId = info.textId
    local bindingId = info.bind and info.bind.id or info.bindingId
    cell.gameObject.name = actionId
    if bindingId then
        cell.actionKeyHint:SetBindingId(bindingId, actionId, hintView, true)
    else
        cell.actionKeyHint:SetKeyHint(actionId, hintView, true)
    end
    if textId then
        cell.actionKeyHint:SetText(Language[textId])
    end
    if hintView and NotNull(hintView.redDotTrans) then
        if (not cell.redDotTarget) or (cell.redDotTarget.transform ~= hintView.redDotTrans) then
            self:_ClearRedDot(cell)
            local widget = hintView.redDotTrans:GetComponent("LuaUIWidget")
            if widget.table then
                cell.redDotTarget = widget.table[1]
                cell.redDotTarget:SetKeyHintTarget(cell.redDot)
            else
                logger.error("No LuaUIWidget Table", hintView.redDotTrans:PathFromRoot())
            end
        end
    else
        self:_ClearRedDot(cell)
        cell.redDot.gameObject:SetActive(false)
    end
end
ControllerHintCtrl._SetContentTransformState = HL.Method(HL.Table, HL.Table, HL.Boolean, HL.Boolean) << function(self, barCell, args, isInit, showBg)
    local targetScreenRect = UIUtils.getTransformScreenRect(args.transform, self.uiCamera)
    local posType = args.posType
    if posType == UIConst.CONTROLLER_HINT_POS_TYPE.Center then
        if isInit then
            local point = Vector2.one / 2
            barCell.rectTransform.pivot = point
            barCell.rectTransform.anchorMin = point
            barCell.rectTransform.anchorMax = point
            barCell.contentHorizontalLayoutGroup.childAlignment = CS.UnityEngine.TextAnchor.MiddleCenter
            barCell.centerBG.gameObject:SetActiveIfNecessary(showBg)
            barCell.leftBG.gameObject:SetActiveIfNecessary(false)
            barCell.rightBG.gameObject:SetActiveIfNecessary(false)
        end
        local pos = UIUtils.screenPointToUI(targetScreenRect.center, self.uiCamera, self.view.transform)
        pos.y = -pos.y
        barCell.rectTransform.anchoredPosition = pos
    elseif posType == UIConst.CONTROLLER_HINT_POS_TYPE.Left then
        if isInit then
            local point = Vector2.zero
            barCell.rectTransform.pivot = point
            barCell.rectTransform.anchorMin = point
            barCell.rectTransform.anchorMax = point
            barCell.contentHorizontalLayoutGroup.childAlignment = CS.UnityEngine.TextAnchor.MiddleLeft
            barCell.centerBG.gameObject:SetActiveIfNecessary(false)
            barCell.leftBG.gameObject:SetActiveIfNecessary(showBg)
            barCell.rightBG.gameObject:SetActiveIfNecessary(false)
        end
        local pos = Vector2(targetScreenRect.xMin, targetScreenRect.yMax)
        pos = UIUtils.screenPointToUI(pos, self.uiCamera, self.view.transform)
        pos.y = self.view.transform.rect.size.y / 2 - pos.y
        pos.x = self.view.transform.rect.size.x / 2 + pos.x
        barCell.rectTransform.anchoredPosition = pos
    elseif posType == UIConst.CONTROLLER_HINT_POS_TYPE.Right then
        if isInit then
            local point = Vector2(1, 0)
            barCell.rectTransform.pivot = point
            barCell.rectTransform.anchorMin = point
            barCell.rectTransform.anchorMax = point
            barCell.contentHorizontalLayoutGroup.childAlignment = CS.UnityEngine.TextAnchor.MiddleRight
            barCell.centerBG.gameObject:SetActiveIfNecessary(false)
            barCell.leftBG.gameObject:SetActiveIfNecessary(false)
            barCell.rightBG.gameObject:SetActiveIfNecessary(showBg)
        end
        local pos = Vector2(targetScreenRect.xMax, targetScreenRect.yMax)
        pos = UIUtils.screenPointToUI(pos, self.uiCamera, self.view.transform)
        pos.y = self.view.transform.rect.size.y / 2 - pos.y
        pos.x = -(self.view.transform.rect.size.x / 2 - pos.x)
        barCell.rectTransform.anchoredPosition = pos
    end
end
ControllerHintCtrl._ClearRedDot = HL.Method(HL.Any) << function(self, cell)
    if cell.redDotTarget then
        if NotNull(cell.redDotTarget) then
            cell.redDotTarget:SetKeyHintTarget(nil)
        end
        cell.redDotTarget = nil
    end
end
ControllerHintCtrl.m_lateTickFunc = HL.Field(HL.Function)
ControllerHintCtrl.OnShow = HL.Override() << function(self)
    ControllerHintCtrl.Super.OnShow(self)
    InputManagerInst.onInputLateTick = InputManagerInst.onInputLateTick + self.m_lateTickFunc
end
ControllerHintCtrl.OnHide = HL.Override() << function(self)
    ControllerHintCtrl.Super.OnHide(self)
    InputManagerInst.onInputLateTick = InputManagerInst.onInputLateTick - self.m_lateTickFunc
    self:_ClearKeyHints()
end
ControllerHintCtrl.OnClose = HL.Override() << function(self)
    ControllerHintCtrl.Super.OnClose(self)
    InputManagerInst.onInputLateTick = InputManagerInst.onInputLateTick - self.m_lateTickFunc
    self:_ClearKeyHints()
end
ControllerHintCtrl._ClearKeyHints = HL.Method() << function(self)
    for _, barCell in pairs(self.m_curBarCells) do
        barCell.keyHintCells:Refresh(0, nil, nil, function(cell)
            self:_ClearRedDot(cell)
            cell.actionKeyHint:SetActionId(nil)
        end)
        self.m_barCellCache:Cache(barCell)
    end
    self.m_curBarCells = {}
end
ControllerHintCtrl._LateTick = HL.Method() << function(self)
    self:_RefreshAllBars()
end
HL.Commit(ControllerHintCtrl)