local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacMain
FacMainCtrl = HL.Class('FacMainCtrl', uiCtrl.UICtrl)
local FORMULA_PIN_TOAST_TEXT_ID = "LUA_FORMULA_PIN_TOAST"
local FORMULA_CANCEL_PIN_TOAST_TEXT_ID = "LUA_FORMULA_CANCEL_PIN_TOAST"
FacMainCtrl.m_pinFormulaInCells = HL.Field(HL.Forward('UIListCache'))
FacMainCtrl.m_pinFormulaOutCells = HL.Field(HL.Forward('UIListCache'))
FacMainCtrl.m_pinFormulaData = HL.Field(HL.Table)
FacMainCtrl.m_isPinBuilding = HL.Field(HL.Boolean) << false
FacMainCtrl.m_isPinFormula = HL.Field(HL.Boolean) << false
FacMainCtrl.m_isPinFormulaNodeExpanded = HL.Field(HL.Boolean) << true
FacMainCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_PIN_STATE_CHANGED] = '_OnPinStateChanged', [MessageConst.ON_SYSTEM_UNLOCK] = '_OnPinSystemLockedStateChanged', [MessageConst.ON_ENTER_FAC_MAIN_REGION] = '_OnEnterFacMainRegion', [MessageConst.ON_EXIT_FAC_MAIN_REGION] = '_OnExitFacMainRegion', [MessageConst.ON_ENTITY_ALL_CPT_START_DONE] = '_OnFacBuildingNodeStateChanged', [MessageConst.ON_REMOTE_FACTORY_ENTITY_REMOVED] = '_OnFacBuildingNodeStateChanged', [MessageConst.ON_INPUT_DEVICE_TYPE_CHANGED] = '_OnInputDeviceTypeChanged', [MessageConst.ON_CONTROLLER_INDICATOR_CHANGE] = '_OnControllerIndicatorChange', [MessageConst.TOGGLE_FAC_MAIN_NAVIGATION_FROZEN_STATE] = '_OnToggleFacMainNavigationFrozenState', [MessageConst.ON_TOGGLE_FAC_TOP_VIEW] = 'OnToggleFacTopView', [MessageConst.ON_FAC_TOP_VIEW_HIDE_UI_MODE_CHANGE] = 'OnFacTopViewHideUIModeChange', }
FacMainCtrl.m_needUpdatePin = HL.Field(HL.Boolean) << false
FacMainCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.facQuickBarPlaceHolder:InitFacQuickBarPlaceHolder()
    self:_InitPinNode()
    self:_InitFacMainController()
end
FacMainCtrl.OnShow = HL.Override() << function(self)
    self:_UpdateAndRefreshPinFormula()
    self:_InitFacMainControllerDisplayMode()
end
FacMainCtrl.OnHide = HL.Override() << function(self)
    self:_ResetFacMainControllerDisplayMode()
end
FacMainCtrl._OnPanelInputBlocked = HL.Override(HL.Boolean) << function(self, isActive)
    if not isActive then
        if not self.m_navigationFrozen then
            self:_DeactivateNavigationController()
        end
    end
end
FacMainCtrl._OnEnterFacMainRegion = HL.Method(HL.Opt(HL.Any)) << function(self)
    self:_RefreshPinFormula()
end
FacMainCtrl._OnExitFacMainRegion = HL.Method() << function(self)
    self:_RefreshPinFormula()
end
FacMainCtrl._InitPinNode = HL.Method() << function(self)
    self.view.pinFormulaNode.detailButton.onClick:AddListener(function()
        self:_OnPinFormulaBtnClick()
    end)
    self.view.pinFormulaNode.singleButton.onClick:AddListener(function()
        self:_OnPinFormulaBtnClick()
    end)
    self.view.pinFormulaNode.closeButton.onClick:AddListener(function()
        self:_OnPinFormulaCloseBtnClick()
    end)
    self.view.pinFormulaNode.expandButton.onClick:AddListener(function()
        self:_OnPinFormulaExpandBtnClick()
    end)
    self.m_pinFormulaInCells = UIUtils.genCellCache(self.view.pinFormulaNode.incomeCell)
    self.m_pinFormulaOutCells = UIUtils.genCellCache(self.view.pinFormulaNode.outcomeCell)
    self.m_isPinFormulaNodeExpanded = true
    self:_UpdateAndRefreshPinFormula()
    self:_RefreshPinFormulaExpandedState()
end
FacMainCtrl._OnPinStateChanged = HL.Method(HL.Table) << function(self, pinStateInfo)
    local pinId, pinType, chapterId = unpack(pinStateInfo)
    if chapterId ~= Utils.getCurrentChapterId() then
        return
    end
    local lastPinFormulaId = self:_GetPinFormulaIdFromFormulaData()
    if pinType == GEnums.FCPinPosition.Formula:GetHashCode() then
        self:_UpdateAndRefreshPinFormula()
    end
    local currPinFormulaId = self:_GetPinFormulaIdFromFormulaData()
    self:_ShowPinFormulaChangedToast(lastPinFormulaId, currPinFormulaId)
    self.m_isPinFormulaNodeExpanded = true
    self:_RefreshPinFormulaExpandedState()
    if self.m_navigationActive then
        self:_RefreshNavigationData()
        self:_RefreshNavigationIndex()
        self:_RefreshNavigationKeyHint(true)
    end
end
FacMainCtrl._OnPinSystemLockedStateChanged = HL.Method(HL.Any) << function(self, arg)
    local systemIndex = unpack(arg)
    if systemIndex == GEnums.UnlockSystemType.FacCraftPin:GetHashCode() then
        self:_UpdateAndRefreshPinFormula()
    end
end
FacMainCtrl._OnFacBuildingNodeStateChanged = HL.Method(HL.Any) << function(self, arg)
    self.m_needUpdatePin = true
end
FacMainCtrl._ShowPinFormulaChangedToast = HL.Method(HL.String, HL.String) << function(self, lastId, currId)
    if lastId == currId then
        return
    end
    local isCurrEmpty = string.isEmpty(currId)
    local textId = isCurrEmpty and FORMULA_CANCEL_PIN_TOAST_TEXT_ID or FORMULA_PIN_TOAST_TEXT_ID
    local formulaDesc = ""
    if isCurrEmpty then
        local success, formulaTableData = Tables.factoryMachineCraftTable:TryGetValue(lastId)
        if success then
            formulaDesc = formulaTableData.formulaDesc
        end
    else
        local success, formulaTableData = Tables.factoryMachineCraftTable:TryGetValue(currId)
        if success then
            formulaDesc = formulaTableData.formulaDesc
        end
    end
    Notify(MessageConst.SHOW_TOAST, string.format(Language[textId], formulaDesc))
end
FacMainCtrl._GetPinFormulaIdFromFormulaData = HL.Method().Return(HL.String) << function(self)
    return self.m_pinFormulaData == nil and "" or self.m_pinFormulaData.craftId
end
FacMainCtrl._RefreshPinBuilding = HL.Method() << function(self)
    local chapterInfo = FactoryUtils.getCurChapterInfo()
    if chapterInfo == nil then
        return
    end
    local pinBuildingNode = self.view.pinBuildingNode
    if pinBuildingNode == nil then
        return
    end
    self.m_isPinBuilding = false
    local isBuildingPinUnlocked = Utils.isSystemUnlocked(GEnums.UnlockSystemType.FacBuildingPin)
    if not isBuildingPinUnlocked then
        pinBuildingNode.gameObject:SetActiveIfNecessary(false)
        return
    end
    local isInFacMainRegion = Utils.isInFacMainRegion()
    if not isInFacMainRegion then
        pinBuildingNode.gameObject:SetActiveIfNecessary(false)
        return
    end
    local pinId = CS.Beyond.Gameplay.RemoteFactory.RemoteFactoryUtil.GetPinBoardStrId(chapterInfo.pinBoard, GEnums.FCPinPosition.Building:GetHashCode())
    if string.isEmpty(pinId) then
        pinBuildingNode.gameObject:SetActiveIfNecessary(false)
        return
    end
    local buildingDataId = pinId
    local success = FactoryUtils.findNearestBuilding(buildingDataId)
    if not success then
        pinBuildingNode.gameObject:SetActiveIfNecessary(false)
        return
    end
    local buildingItemData = FactoryUtils.getBuildingItemData(buildingDataId)
    pinBuildingNode.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, buildingItemData.iconId)
    pinBuildingNode.text.text = buildingItemData.name
    pinBuildingNode.gameObject:SetActiveIfNecessary(true)
    self.m_isPinBuilding = true
end
FacMainCtrl._OnPinBuildingBtnClick = HL.Method() << function(self)
    local chapterInfo = FactoryUtils.getCurChapterInfo()
    if chapterInfo == nil then
        return
    end
    local buildingPinId = CS.Beyond.Gameplay.RemoteFactory.RemoteFactoryUtil.GetPinBoardStrId(chapterInfo.pinBoard, GEnums.FCPinPosition.Building:GetHashCode())
    if string.isEmpty(buildingPinId) then
        return
    end
    Notify(MessageConst.FAC_OPEN_NEAREST_BUILDING_PANEL, { buildingPinId })
end
FacMainCtrl._OnPinBuildingCloseBtnClick = HL.Method() << function(self)
    local curScopeIndex = ScopeUtil.GetCurrentScope():GetHashCode()
    if curScopeIndex ~= 0 then
        GameInstance.player.remoteFactory.core:Message_PinSet(curScopeIndex, GEnums.FCPinPosition.Building:GetHashCode(), "", 0, true)
    end
end
FacMainCtrl._UpdateAndRefreshPinFormula = HL.Method() << function(self)
    self:_UpdatePinFormulaData()
    self:_RefreshPinFormula()
end
FacMainCtrl._UpdatePinFormulaData = HL.Method() << function(self)
    self.m_pinFormulaData = nil
    local chapterInfo = FactoryUtils.getCurChapterInfo()
    if chapterInfo == nil then
        return
    end
    local isFormulaPinUnlocked = Utils.isSystemUnlocked(GEnums.UnlockSystemType.FacCraftPin)
    if not isFormulaPinUnlocked then
        return
    end
    local pinId = CS.Beyond.Gameplay.RemoteFactory.RemoteFactoryUtil.GetPinBoardStrId(chapterInfo.pinBoard, GEnums.FCPinPosition.Formula:GetHashCode())
    if string.isEmpty(pinId) then
        return
    end
    local formulaId = pinId
    if Tables.factoryMachineCraftTable:ContainsKey(formulaId) then
        self.m_pinFormulaData = FactoryUtils.parseMachineCraftData(formulaId)
    elseif Tables.factoryHubCraftTable:ContainsKey(formulaId) then
        self.m_pinFormulaData = FactoryUtils.parseHubCraftData(formulaId)
    elseif Tables.factoryManualCraftTable:ContainsKey(formulaId) then
        self.m_pinFormulaData = FactoryUtils.parseManualCraftData(formulaId)
    end
end
FacMainCtrl._RefreshPinFormula = HL.Method() << function(self)
    local pinFormulaNode = self.view.pinFormulaNode
    local isInFacMainRegion = Utils.isInFacMainRegion()
    if self.m_pinFormulaData ~= nil and pinFormulaNode ~= nil and isInFacMainRegion then
        UIUtils.PlayAnimationAndToggleActive(self.view.pinFormulaAnim, true)
        self:_RefreshPinFormulaNode()
        self.m_isPinFormula = true
    else
        UIUtils.PlayAnimationAndToggleActive(self.view.pinFormulaAnim, false)
        self.m_isPinFormula = false
    end
end
FacMainCtrl._RefreshPinFormulaNode = HL.Method() << function(self)
    local pinFormulaNode = self.view.pinFormulaNode
    if pinFormulaNode == nil then
        return
    end
    local formulaData = self.m_pinFormulaData
    if formulaData == nil then
        return
    end
    local outcomeId = formulaData.outcomes[1].id
    local outcomeIcon = self:LoadSprite(UIConst.UI_SPRITE_ITEM, outcomeId)
    pinFormulaNode.outcomeIcon.sprite = outcomeIcon
    local incomes = formulaData.incomes
    self.m_pinFormulaInCells:Refresh(#incomes, function(cell, index)
        cell.incomeItem:InitItem(incomes[index])
    end)
    local outcomes = formulaData.outcomes
    self.m_pinFormulaOutCells:Refresh(#outcomes, function(cell, index)
        cell.outcomeItem:InitItem(outcomes[index])
    end)
    self:_RefreshPinFormulaNodeText()
end
FacMainCtrl._RefreshPinFormulaNodeText = HL.Method() << function(self)
    local formulaData = self.m_pinFormulaData
    if formulaData == nil then
        return
    end
    self.view.pinFormulaNode.formulaTime.text = string.format(Language["LUA_CRAFT_CELL_STANDARD_TIME"], FactoryUtils.getCraftTimeStr(formulaData.time))
end
FacMainCtrl._RefreshPinFormulaExpandedState = HL.Method() << function(self)
    self.view.pinFormulaNode.formulaDetailNode.gameObject:SetActive(self.m_isPinFormulaNodeExpanded)
    self.view.pinFormulaNode.singleOutcomeNode.gameObject:SetActive(not self.m_isPinFormulaNodeExpanded)
    self.view.pinFormulaNode.expandButtonRectTransform.localScale = Vector3(self.m_isPinFormulaNodeExpanded and -1 or 1, 1, 1)
end
FacMainCtrl._OnPinFormulaBtnClick = HL.Method() << function(self)
    if self.m_pinFormulaData == nil then
        return
    end
    local pinItemId = self.m_pinFormulaData.outcomes[1].id
    if string.isEmpty(pinItemId) then
        return
    end
    Notify(MessageConst.SHOW_WIKI_ENTRY, { itemId = pinItemId })
end
FacMainCtrl._OnPinFormulaCloseBtnClick = HL.Method() << function(self)
    local curScopeIndex = ScopeUtil.GetCurrentScope():GetHashCode()
    if curScopeIndex ~= 0 then
        GameInstance.player.remoteFactory.core:Message_PinSet(curScopeIndex, GEnums.FCPinPosition.Formula:GetHashCode(), "", 0, true)
    end
end
FacMainCtrl._OnPinFormulaExpandBtnClick = HL.Method() << function(self)
    self.m_isPinFormulaNodeExpanded = not self.m_isPinFormulaNodeExpanded
    self:_RefreshPinFormulaExpandedState()
end
local FAC_MAIN_NAVIGATION_QUICK_BAR_INDEX = 1
local FAC_MAIN_NAVIGATION_PIN_FORMULA_INDEX = 2
local FAC_MAIN_NAVIGATION_PIN_BUILDING_INDEX = 3
FacMainCtrl.m_navigationActive = HL.Field(HL.Boolean) << false
FacMainCtrl.m_navigationData = HL.Field(HL.Table)
FacMainCtrl.m_navigationFrozen = HL.Field(HL.Boolean) << false
FacMainCtrl.m_navigationGroupId = HL.Field(HL.Number) << 1
FacMainCtrl.m_navigationIndex = HL.Field(HL.Number) << 1
FacMainCtrl.m_pinFormulaGroupId = HL.Field(HL.Number) << 1
FacMainCtrl.m_pinBuildingGroupId = HL.Field(HL.Number) << 1
FacMainCtrl._BuildNavigationData = HL.Method() << function(self)
    self.m_navigationData = { [FAC_MAIN_NAVIGATION_QUICK_BAR_INDEX] = { isValid = true, isInMainCtrl = false, msg = MessageConst.FAC_MAIN_NAVIGATION_STATE_CHANGE_QUICK_BAR, activeAudioEventId = "au_ui_hover_item", }, [FAC_MAIN_NAVIGATION_PIN_FORMULA_INDEX] = { isValid = true, isInMainCtrl = true, func = "_SwitchPinFormulaNavigationState", activeAudioEventId = "au_ui_hover_item", }, [FAC_MAIN_NAVIGATION_PIN_BUILDING_INDEX] = { isValid = true, isInMainCtrl = true, func = "_SwitchPinBuildingNavigationState", activeAudioEventId = "au_ui_hover_item", }, }
end
FacMainCtrl._RefreshNavigationData = HL.Method() << function(self)
    if self.m_navigationData == nil then
        return
    end
    self.m_navigationData[FAC_MAIN_NAVIGATION_PIN_FORMULA_INDEX].isValid = self.m_isPinFormula
    self.m_navigationData[FAC_MAIN_NAVIGATION_PIN_BUILDING_INDEX].isValid = self.m_isPinBuilding
end
FacMainCtrl._OnInputDeviceTypeChanged = HL.Method(HL.Table) << function(self, arg)
    local type = unpack(arg)
    if not type then
        return
    end
    self:_RefreshFacMainControllerDisplayMode(type)
end
FacMainCtrl._OnControllerIndicatorChange = HL.Method(HL.Boolean) << function(self, active)
    if not self:IsShow() then
        return
    end
    if self.m_navigationFrozen then
        return
    end
    if active then
        self:_ActivateNavigationController()
    else
        self:_DeactivateNavigationController()
    end
end
FacMainCtrl._OnToggleFacMainNavigationFrozenState = HL.Method(HL.Any) << function(self, args)
    local frozen = unpack(args)
    self.m_navigationFrozen = frozen == nil and false or frozen
    if frozen == false then
        self:_DeactivateNavigationController()
    end
end
FacMainCtrl._InitFacMainController = HL.Method() << function(self)
    self.m_navigationGroupId = InputManagerInst:CreateGroup(self.view.inputGroup.groupId)
    UIUtils.bindInputPlayerAction("fac_quick_area_move_up", function()
        self:_MoveNavigationIndex(true)
    end, self.m_navigationGroupId)
    UIUtils.bindInputPlayerAction("fac_quick_area_move_down", function()
        self:_MoveNavigationIndex(false)
    end, self.m_navigationGroupId)
    self.m_pinFormulaGroupId = InputManagerInst:CreateGroup(self.view.inputGroup.groupId)
    UIUtils.bindInputPlayerAction("fac_enter_pin", function()
        self:_InvokePinFormulaEnter()
    end, self.m_pinFormulaGroupId)
    UIUtils.bindInputPlayerAction("fac_close_pin", function()
        self:_InvokePinFormulaClose()
    end, self.m_pinFormulaGroupId)
    self.m_pinBuildingGroupId = InputManagerInst:CreateGroup(self.view.inputGroup.groupId)
    UIUtils.bindInputPlayerAction("fac_enter_pin", function()
        self:_InvokePinBuildingEnter()
    end, self.m_pinBuildingGroupId)
    UIUtils.bindInputPlayerAction("fac_close_pin", function()
        self:_InvokePinBuildingClose()
    end, self.m_pinBuildingGroupId)
    InputManagerInst:ToggleGroup(self.m_navigationGroupId, false)
    InputManagerInst:ToggleGroup(self.m_pinBuildingGroupId, false)
    InputManagerInst:ToggleGroup(self.m_pinFormulaGroupId, false)
    self:_BuildNavigationData()
    self.view.pinAnimator:SetBool("IsInitialized", true)
end
FacMainCtrl._InitFacMainControllerDisplayMode = HL.Method() << function(self)
    self.view.pinAnimator:SetBool("IsInitialized", true)
    local deviceType = DeviceInfo.inputType
    self:_RefreshFacMainControllerDisplayMode(deviceType)
end
FacMainCtrl._ResetFacMainControllerDisplayMode = HL.Method() << function(self)
    self.view.pinAnimator:SetBool("IsInitialized", false)
end
FacMainCtrl._RefreshFacMainControllerDisplayMode = HL.Method(HL.Any) << function(self, type)
    self.view.pinAnimator:SetBool("IsController", type == DeviceInfo.InputType.Controller)
end
FacMainCtrl._ActivateNavigationController = HL.Method() << function(self)
    InputManagerInst:ToggleGroup(self.m_navigationGroupId, true)
    self.m_navigationIndex = 0
    self:_RefreshNavigationData()
    self:_RefreshNavigationKeyHint(true)
    self:_MoveNavigationIndex(true)
    self.view.pinAnimator:SetBool("IsControllerActive", true)
    Notify(MessageConst.TOGGLE_HIDE_INTERACT_OPTION_LIST, { "CONTROLLER_INDICATOR", true })
    Notify(MessageConst.FAC_MAIN_NAVIGATION_STATE_CHANGE, true)
    self.m_navigationActive = true
end
FacMainCtrl._DeactivateNavigationController = HL.Method() << function(self)
    InputManagerInst:ToggleGroup(self.m_navigationGroupId, false)
    self:_ResetNavigation()
    self:_RefreshNavigationKeyHint(false)
    self.view.pinAnimator:SetBool("IsControllerActive", false)
    Notify(MessageConst.TOGGLE_HIDE_INTERACT_OPTION_LIST, { "CONTROLLER_INDICATOR", false })
    Notify(MessageConst.FAC_MAIN_NAVIGATION_STATE_CHANGE, false)
    self.m_navigationActive = false
end
FacMainCtrl._RefreshNavigationKeyHint = HL.Method(HL.Boolean) << function(self, active)
    if not active then
        self.view.quickAreaHintNode.gameObject:SetActiveIfNecessary(false)
        return
    end
    local keyHintActive = self.m_navigationData[FAC_MAIN_NAVIGATION_PIN_FORMULA_INDEX].isValid or self.m_navigationData[FAC_MAIN_NAVIGATION_PIN_BUILDING_INDEX].isValid
    self.view.quickAreaHintNode.gameObject:SetActiveIfNecessary(keyHintActive)
end
FacMainCtrl._ResetNavigation = HL.Method() << function(self)
    if self.m_navigationData == nil then
        return
    end
    for index = 1, #self.m_navigationData, 1 do
        local navigationData = self.m_navigationData[index]
        if navigationData ~= nil then
            self:_SwitchNavigationState(index, false)
        end
    end
end
FacMainCtrl._RefreshNavigationIndex = HL.Method() << function(self)
    if self.m_navigationData == nil then
        return
    end
    local currentData = self.m_navigationData[self.m_navigationIndex]
    if currentData ~= nil and currentData.isValid then
        return
    end
    local lastIndex = self.m_navigationIndex
    self:_MoveNavigationIndex(true)
    if lastIndex ~= self.m_navigationIndex then
        return
    end
    self.m_navigationIndex = lastIndex
    self:_MoveNavigationIndex(false)
end
FacMainCtrl._MoveNavigationIndex = HL.Method(HL.Boolean) << function(self, toNext)
    local lastIndex = self.m_navigationIndex
    if toNext then
        for index = self.m_navigationIndex + 1, #self.m_navigationData, 1 do
            local navigationData = self.m_navigationData[index]
            if navigationData ~= nil and navigationData.isValid then
                self:_SwitchNavigationState(index, true)
                self.m_navigationIndex = index
                break
            end
        end
    else
        for index = self.m_navigationIndex - 1, 1, -1 do
            local navigationData = self.m_navigationData[index]
            if navigationData ~= nil and navigationData.isValid then
                self:_SwitchNavigationState(index, true)
                self.m_navigationIndex = index
                break
            end
        end
    end
    if lastIndex ~= self.m_navigationIndex then
        self:_SwitchNavigationState(lastIndex, false)
    end
end
FacMainCtrl._SwitchNavigationState = HL.Method(HL.Number, HL.Boolean) << function(self, index, isActive)
    local data = self.m_navigationData[index]
    if data == nil then
        return
    end
    if not data.isValid then
        return
    end
    if data.isInMainCtrl then
        if not string.isEmpty(data.func) then
            self[data.func](self, isActive)
        end
    else
        if not string.isEmpty(data.msg) then
            Notify(data.msg, isActive)
        end
    end
    if isActive and not string.isEmpty(data.activeAudioEventId) then
        AudioManager.PostEvent(data.activeAudioEventId)
    end
end
FacMainCtrl._SwitchPinFormulaNavigationState = HL.Method(HL.Boolean) << function(self, isActive)
    local formulaNode = self.view.pinFormulaNode
    if formulaNode == nil then
        return
    end
    InputManagerInst:ToggleGroup(self.m_pinFormulaGroupId, isActive)
end
FacMainCtrl._InvokePinFormulaEnter = HL.Method() << function(self)
    local formulaNode = self.view.pinFormulaNode
    if formulaNode == nil then
        return
    end
    local button = formulaNode.detailButton
    if button == nil then
        return
    end
    button.onClick:Invoke()
    self:_DeactivateNavigationController()
end
FacMainCtrl._InvokePinFormulaClose = HL.Method() << function(self)
    local formulaNode = self.view.pinFormulaNode
    if formulaNode == nil then
        return
    end
    local closeButton = formulaNode.closeButton
    if closeButton == nil then
        return
    end
    closeButton.onClick:Invoke()
    AudioManager.PostEvent("au_ui_menu_formula_close")
    self:_SwitchPinFormulaNavigationState(false)
end
FacMainCtrl._SwitchPinBuildingNavigationState = HL.Method(HL.Boolean) << function(self, isActive)
    local buildingNode = self.view.pinBuildingNode
    if buildingNode == nil then
        return
    end
    buildingNode.activeNode.gameObject:SetActiveIfNecessary(isActive)
    InputManagerInst:ToggleGroup(self.m_pinBuildingGroupId, isActive)
end
FacMainCtrl._InvokePinBuildingEnter = HL.Method() << function(self)
    local buildingNode = self.view.pinBuildingNode
    if buildingNode == nil then
        return
    end
    local button = buildingNode.button
    if button == nil then
        return
    end
    button.onClick:Invoke()
    self:_DeactivateNavigationController()
end
FacMainCtrl._InvokePinBuildingClose = HL.Method() << function(self)
    local buildingNode = self.view.pinBuildingNode
    if buildingNode == nil then
        return
    end
    local closeButton = buildingNode.closeButton
    if closeButton == nil then
        return
    end
    closeButton.onClick:Invoke()
    AudioManager.PostEvent("au_ui_menu_formula_close")
    self:_SwitchPinBuildingNavigationState(false)
end
FacMainCtrl.OnToggleFacTopView = HL.Method(HL.Boolean) << function(self, active)
    self.view.facQuickBarPlaceHolder.gameObject:SetActive(not active)
end
FacMainCtrl.OnFacTopViewHideUIModeChange = HL.Method(HL.Boolean) << function(self, isTopViewHideUIMode)
    self.view.rightNode.gameObject:SetActive(not isTopViewHideUIMode)
end
HL.Commit(FacMainCtrl)