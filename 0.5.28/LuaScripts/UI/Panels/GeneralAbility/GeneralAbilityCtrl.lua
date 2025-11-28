local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GeneralAbility
local GeneralAbilityType = GEnums.GeneralAbilityType
local GeneralAbilityState = CS.Beyond.Gameplay.GeneralAbilitySystem.AbilityState
local PlayerController = CS.Beyond.Gameplay.Core.PlayerController
local UnlockSystemType = GEnums.UnlockSystemType
local SelectorCellState = { None = "None", Normal = "Normal", Invalid = "Invalid", }
GeneralAbilityCtrl = HL.Class('GeneralAbilityCtrl', uiCtrl.UICtrl)
local SELECTED_ABILITY_TYPE_CLIENT_LOCAL_DATA_KEY = "selected_general_ability"
local INVALID_ABILITY_TYPE = -1
local HINT_ANIMATION_NAME = "generalability_hint"
local HINT_OUT_ANIMATION_NAME = "generalability_hint_out"
local PRESS_ANIMATION_NAME = "generalability_press"
local VALID_ANIMATION_NAME = "generalability_unlock"
local HIGHLIGHT_LOOP_ANIMATION_NAME = "generalability_highlight_loop"
local HIGHLIGHT_DEFAULT_ANIMATION_NAME = "generalability_highlight_default"
local SELECTOR_NORMAL_ANIMATION_NAME = "generalability_selector_cell_default"
local SELECTOR_HOVER_ANIMATION_NAME = "generalability_selector_cell_highlight"
local NEED_TIPS_ABILITY_TYPES = { [GeneralAbilityType.FluidInteract:GetHashCode()] = true }
local SELECTOR_CANCEL_ACTION_ID = "general_ability_selector_quit"
local SELECTOR_CLICK_ACTION_ID = "general_ability_selector_click"
GeneralAbilityCtrl.m_isValid = HL.Field(HL.Boolean) << false
GeneralAbilityCtrl.m_abilityRegisterConfig = HL.Field(HL.Table)
GeneralAbilityCtrl.m_abilityCells = HL.Field(HL.Forward("UIListCache"))
GeneralAbilityCtrl.m_abilityDataList = HL.Field(HL.Table)
GeneralAbilityCtrl.m_abilityDataMap = HL.Field(HL.Table)
GeneralAbilityCtrl.m_selectedAbilityType = HL.Field(HL.Number) << -1
GeneralAbilityCtrl.m_tipsAbilityType = HL.Field(HL.Number) << -1
GeneralAbilityCtrl.m_selectedAbilityPressTick = HL.Field(HL.Number) << -1
GeneralAbilityCtrl.m_selectedAbilityPressTime = HL.Field(HL.Number) << -1
GeneralAbilityCtrl.m_abilityUsePressDuration = HL.Field(HL.Number) << -1
GeneralAbilityCtrl.m_abilitySwitchPressDuration = HL.Field(HL.Number) << -1
GeneralAbilityCtrl.m_isSelectorShown = HL.Field(HL.Boolean) << false
GeneralAbilityCtrl.m_decoCells = HL.Field(HL.Forward("UIListCache"))
GeneralAbilityCtrl.m_clickEnabled = HL.Field(HL.Boolean) << true
GeneralAbilityCtrl.m_hoverSelectorType = HL.Field(HL.Number) << -1
GeneralAbilityCtrl.m_canReleaseCloseSelector = HL.Field(HL.Boolean) << true
GeneralAbilityCtrl.m_selectorCancelBinding = HL.Field(HL.Number) << -1
GeneralAbilityCtrl.m_selectorClickBinding = HL.Field(HL.Number) << -1
GeneralAbilityCtrl.m_isSwitchTipShown = HL.Field(HL.Boolean) << false
GeneralAbilityCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.GENERAL_ABILITY_SYSTEM_CHANGED] = '_OnSystemChanged', [MessageConst.GENERAL_ABILITY_SYSTEM_FORCE_SELECT] = '_OnForceSelectAbility', [MessageConst.ON_GENERAL_ABILITY_USE] = '_OnGeneralAbilityUse', [MessageConst.TOGGLE_GENERAL_ABILITY_CLICK] = '_ToggleGeneralAbilityClick', [MessageConst.SET_GENERAL_ABILITY_RELEASE_CLOSE] = '_ToggleGeneralAbilityClick', [MessageConst.FORBID_SYSTEM_CHANGED] = '_OnForbidSystemChanged', }
GeneralAbilityCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_selectorCancelBinding = self:BindInputPlayerAction(SELECTOR_CANCEL_ACTION_ID, function()
        self:_OnBackButtonClicked()
    end)
    self.m_selectorClickBinding = self:BindInputPlayerAction(SELECTOR_CLICK_ACTION_ID, function()
    end)
    InputManagerInst:ToggleBinding(self.m_selectorCancelBinding, false)
    InputManagerInst:ToggleBinding(self.m_selectorClickBinding, false)
    self.view.selectedAbilityButton.onPressStart:AddListener(function()
        self:_StartSelectedAbilityPress()
    end)
    self.view.selectedAbilityButton.onPressEnd:AddListener(function()
        self:_StopSelectedAbilityPress()
    end)
    self.m_abilityCells = UIUtils.genCellCache(self.view.abilityCell)
    self.m_decoCells = UIUtils.genCellCache(self.view.decoCell)
    self.m_abilityUsePressDuration = self.view.config.ABILITY_USE_PRESS_DURATION
    self.m_abilitySwitchPressDuration = self.view.config.ABILITY_SWITCH_PRESS_DURATION
    self:_BuildAbilityRegisterConfig()
    self:_InitAll()
    self.view.selectorAnim.gameObject:SetActive(false)
end
GeneralAbilityCtrl.OnShow = HL.Override() << function(self)
    self:_RefreshSwitchTipShownState(self.m_isSwitchTipShown)
end
GeneralAbilityCtrl._OnSystemChanged = HL.Method() << function(self)
    self:_InitAll()
end
GeneralAbilityCtrl._OnPanelInputBlocked = HL.Override(HL.Boolean) << function(self, active)
    if not active and self.m_isSelectorShown then
        self:_RefreshAbilitySelectorShownState(false)
    end
end
GeneralAbilityCtrl._OnForceSelectAbility = HL.Method(HL.Any) << function(self, args)
    local type, needHighlight = unpack(args)
    self:_SetSelectedAbility(type:GetHashCode(), true)
end
GeneralAbilityCtrl._OnTempAbilityActiveStateChanged = HL.Method(HL.Any) << function(self, args)
    local type, isActive = unpack(args)
    if not isActive and self.m_selectedAbilityType == type:GetHashCode() then
        self:_InitSelectedAbility()
    end
end
GeneralAbilityCtrl._OnGeneralAbilityUse = HL.Method(HL.Any) << function(self, args)
    local abilityType = unpack(args)
    local onUseCallback = self.m_abilityRegisterConfig[abilityType].onUseCallback
    local success, tableData = Tables.generalAbilityTable:TryGetValue(abilityType)
    if not success then
        return
    end
    if not string.isEmpty(tableData.useItem) then
        self:_UseAbilityItem(tableData.useItem)
    else
        if onUseCallback ~= nil then
            onUseCallback()
        end
    end
end
GeneralAbilityCtrl._OnSetGeneralAbilityReleaseClose = HL.Method(HL.Any) << function(self, args)
    self.m_canReleaseCloseSelector = unpack(args)
end
GeneralAbilityCtrl._ToggleGeneralAbilityClick = HL.Method(HL.Any) << function(self, args)
    self.m_clickEnabled = unpack(args)
end
GeneralAbilityCtrl._OnForbidSystemChanged = HL.Method(HL.Table) << function(self, args)
    local forbidType, isForbidden = unpack(args)
    if forbidType == ForbidType.HideGeneralAbility then
        self:_RefreshShownState()
    end
end
GeneralAbilityCtrl._BuildAbilityRegisterConfig = HL.Method() << function(self)
    self.m_abilityRegisterConfig = {
        [GeneralAbilityType.Scan] = {
            onUseCallback = function()
                GameInstance.world.battle:ScanInteractive()
            end
        },
        [GeneralAbilityType.Bomb] = { useItem = true, stateRegisters = { [GeneralAbilityState.Idle] = MessageConst.HIDE_BOMB_AIM, [GeneralAbilityState.Forbidden] = MessageConst.SHOW_BOMB_AIM, }, },
        [GeneralAbilityType.FluidInteract] = {
            onUseCallback = function()
                GameInstance.world.waterSensorSystem:OnWaterInteract()
            end,
            stateRegisters = { [GeneralAbilityState.Idle] = MessageConst.ON_ENTER_LIQUID_POOL_NEARBY_AREA, [GeneralAbilityState.Forbidden] = MessageConst.ON_LEAVE_LIQUID_POOL_NEARBY_AREA, },
            initialStateGetter = function()
                return GameInstance.world.waterSensorSystem.isNearbyFactoryWater and GeneralAbilityState.Idle or GeneralAbilityState.Forbidden
            end
        }
    }
end
GeneralAbilityCtrl._InitAbilityRegisters = HL.Method() << function(self)
    local generalAbilitySystem = GameInstance.player.generalAbilitySystem
    for type, configInfo in pairs(self.m_abilityRegisterConfig) do
        local typeValue = type:GetHashCode()
        if self.m_abilityDataMap[typeValue] ~= nil then
            local stateRegisters = configInfo.stateRegisters
            if stateRegisters ~= nil then
                for toState, message in pairs(stateRegisters) do
                    local toStateValue = toState:GetHashCode()
                    MessageManager:Register(message, function(msgArg)
                        self:_OnStateSwitchMessageDispatched(typeValue, toStateValue)
                    end, self)
                end
            end
            local initialStateGetter = configInfo.initialStateGetter
            if initialStateGetter ~= nil then
                local initialState = initialStateGetter()
                if initialState ~= nil then
                    generalAbilitySystem:SwitchAbilityStateByType(type, initialState)
                end
            end
        end
    end
end
GeneralAbilityCtrl._InitAll = HL.Method() << function(self)
    self.m_selectedAbilityType = INVALID_ABILITY_TYPE
    GameInstance.player.generalAbilitySystem.selectGeneralAbility = INVALID_ABILITY_TYPE
    self:_InitAbilityData()
    if next(self.m_abilityDataList) then
        self:_InitAbilityRegisters()
        self:_InitAbilityCells()
        self:_InitDecoCells()
        self:_InitSelectedAbility()
        self.m_isValid = true
        self:_RefreshShownState()
    else
        self.m_isValid = false
        self:_RefreshShownState()
    end
end
GeneralAbilityCtrl._InitAbilityData = HL.Method() << function(self)
    local abilityDataList, tempAbilityDataList = {}, {}
    self.m_abilityDataList = {}
    self.m_abilityDataMap = {}
    for abilityType, abilityTableData in pairs(Tables.generalAbilityTable) do
        local abilityRuntimeData = GameInstance.player.generalAbilitySystem:GetAbilityRuntimeDataByType(abilityType)
        local abilityState = abilityRuntimeData.state
        if abilityState ~= GeneralAbilityState.None and abilityState ~= GeneralAbilityState.Locked then
            local data = { type = abilityType, sortId = abilityTableData.sortId, name = abilityTableData.name, }
            local isTemp = abilityTableData.unlockSystemType == UnlockSystemType.None
            local dataList = isTemp and tempAbilityDataList or abilityDataList
            table.insert(dataList, data)
            self.m_abilityDataMap[abilityType] = data
        end
    end
    table.sort(abilityDataList, Utils.genSortFunction({ "sortId" }, true))
    for index = 1, #abilityDataList do
        self.m_abilityDataList[index] = abilityDataList[index]
        self.m_abilityDataList[index].index = index
    end
    for index = 1, #tempAbilityDataList do
        local reverseIndex = self.view.config.CELL_MAX_COUNT - index + 1
        self.m_abilityDataList[reverseIndex] = tempAbilityDataList[index]
        self.m_abilityDataList[reverseIndex].index = reverseIndex
    end
end
GeneralAbilityCtrl._InitAbilityCells = HL.Method() << function(self)
    self.m_hoverSelectorType = INVALID_ABILITY_TYPE
    self:_RefreshAllDecoUnSelectedState()
    self.m_abilityCells:Refresh(self.view.config.CELL_MAX_COUNT, function(cell, luaIndex)
        local angle = self.view.config.CELL_START_ANGLE - (luaIndex - 1) * self.view.config.CELL_INTERVAL_ANGLE
        cell.transform.localEulerAngles = Vector3(0, 0, angle)
        cell.ability.view.transform.localEulerAngles = Vector3(0, 0, -angle)
        cell.shadowAbility.view.transform.localEulerAngles = Vector3(0, 0, -angle)
        local abilityData = self.m_abilityDataList[luaIndex]
        if abilityData ~= nil then
            abilityData.cell = cell
            cell.controller:SetState(SelectorCellState.Normal)
            cell.ability:InitGeneralAbilityCell(abilityData.type, function(isValid)
                self:_OnAbilityValidStateChanged(abilityData.type, isValid)
            end)
            cell.ability:SetCustomCDFillImage(cell.fillImage)
            cell.shadowAbility:InitGeneralAbilityCell(abilityData.type)
            cell.shadowAbility.view.gameObject:SetActive(true)
            cell.gameObject.name = "Ability_" .. "Type" .. abilityData.type
        else
            cell.ability:InitGeneralAbilityCell()
            cell.controller:SetState(SelectorCellState.Invalid)
            cell.shadowAbility.view.gameObject:SetActive(false)
            cell.gameObject.name = "Ability_" .. "None" .. luaIndex
        end
        cell.button.enabled = abilityData ~= nil
        cell.animationWrapper:PlayWithTween(SELECTOR_NORMAL_ANIMATION_NAME)
        cell.button.onHoverChange:AddListener(function(isHover)
            self:_RefreshAbilityCellHoverState(cell, luaIndex, isHover)
        end)
        cell.button.onClick:AddListener(function()
            self:_OnSelectorAbilityCellClicked(luaIndex)
        end)
        cell.commonBg.alphaHitTestMinimumThreshold = 0.1
    end)
end
GeneralAbilityCtrl._InitSelectedAbility = HL.Method() << function(self)
    local selectedType = self:_GetSelectedAbility()
    if selectedType == INVALID_ABILITY_TYPE then
        self:_ResetSelectedAbility()
    else
        if self.m_abilityDataMap[selectedType] == nil then
            self:_ResetSelectedAbility()
        else
            self:_SetSelectedAbility(selectedType, false)
        end
    end
end
GeneralAbilityCtrl._InitDecoCells = HL.Method() << function(self)
    self.m_decoCells:Refresh(#self.m_abilityDataList, function(cell, luaIndex)
        local angle = self.view.config.DECO_START_ANGLE - (luaIndex - 1) * self.view.config.DECO_INTERVAL_ANGLE
        cell.transform.localEulerAngles = Vector3(0, 0, angle)
        cell.selected.gameObject:SetActive(false)
    end)
end
GeneralAbilityCtrl._OnStateSwitchMessageDispatched = HL.Method(HL.Number, HL.Number) << function(self, type, toState)
    if self.m_abilityDataMap[type] == nil then
        return
    end
    GameInstance.player.generalAbilitySystem:SwitchAbilityStateByType(type, toState)
end
GeneralAbilityCtrl._OnBackButtonClicked = HL.Method() << function(self)
    self:_RefreshAbilitySelectorShownState(false)
end
GeneralAbilityCtrl._OnSelectedAbilityUseClicked = HL.Method() << function(self)
    if not self.m_clickEnabled then
        return
    end
    if self:_IsAllowedInPlayerController() then
        GameInstance.player.generalAbilitySystem:UseAbilityByType(Utils.intToEnum(typeof(CS.Beyond.GEnums.GeneralAbilityType), self:_GetSelectedAbility()))
    end
    self:_RefreshSelectedAbilityAnimState(PRESS_ANIMATION_NAME)
end
GeneralAbilityCtrl._OnSelectedAbilitySwitchLongPressed = HL.Method() << function(self)
    self:_RefreshAbilitySelectorShownState(self:_IsAllowedInPlayerController())
end
GeneralAbilityCtrl._OnSelectorAbilityCellClicked = HL.Method(HL.Number) << function(self, luaIndex)
    local abilityData = self.m_abilityDataList[luaIndex]
    if abilityData == nil then
        return
    end
    self:_RefreshAbilitySelectorShownState(false)
    self:_SetSelectedAbility(abilityData.type, true)
end
GeneralAbilityCtrl._RefreshAbilityCellHoverState = HL.Method(HL.Table, HL.Number, HL.Boolean) << function(self, cell, luaIndex, isHover)
    if cell == nil then
        return
    end
    cell.highlightNode.gameObject:SetActive(isHover)
    cell.highlightArrow.gameObject:SetActive(isHover)
    cell.animationWrapper:PlayWithTween(isHover and SELECTOR_HOVER_ANIMATION_NAME or SELECTOR_NORMAL_ANIMATION_NAME)
    if isHover then
        local abilityData = self.m_abilityDataList[luaIndex]
        self:_RefreshHoverAbility(abilityData.type)
        self.m_hoverSelectorType = abilityData.type
    else
        self:_RefreshHoverAbility(self.m_selectedAbilityType)
        self.m_hoverSelectorType = INVALID_ABILITY_TYPE
    end
    self.view.hoverAbilityNameTxt.gameObject:SetActive(isHover)
end
GeneralAbilityCtrl._RefreshHoverAbility = HL.Method(HL.Number) << function(self, type)
    local abilityData = self.m_abilityDataMap[type]
    if abilityData ~= nil then
        self.view.hoverAbility:InitGeneralAbilityCell(type)
        self.view.hoverAbilityNameTxt.text = abilityData.name
    end
end
GeneralAbilityCtrl._RefreshAbilitySelectorShownState = HL.Method(HL.Boolean) << function(self, isShown)
    if self.m_isSelectorShown == isShown then
        return
    end
    UIUtils.PlayAnimationAndToggleActive(self.view.middleAnim, isShown)
    UIUtils.PlayAnimationAndToggleActive(self.view.selectorAnim, isShown)
    if isShown then
        self:ChangePanelCfg("realMouseMode", Types.EPanelMouseMode.NeedShow)
        local abilityData = self.m_abilityDataMap[self:_GetSelectedAbility()]
        if abilityData ~= nil and abilityData.cell ~= nil then
            InputManagerInst:MoveMouseTo(abilityData.cell.rectTransform, self.uiCamera)
            self:_RefreshHoverAbility(abilityData.type)
        end
        UIManager:SetTopOrder(PANEL_ID)
    else
        self:ChangePanelCfg("realMouseMode", Types.EPanelMouseMode.NotNeedShow)
        self.m_hoverSelectorType = INVALID_ABILITY_TYPE
    end
    self.m_isSelectorShown = isShown
    self.view.selectedCanvasGroup.alpha = isShown and 0.1 or 1
    GameInstance.player.generalAbilitySystem.isInSelectMode = isShown
    InputManagerInst:ToggleBinding(self.m_selectorCancelBinding, isShown)
    InputManagerInst:ToggleBinding(self.m_selectorClickBinding, isShown)
end
GeneralAbilityCtrl._RefreshAbilityHighlightState = HL.Method(HL.Boolean) << function(self, needHighlight)
    if not self.view.highlight.gameObject.activeSelf and needHighlight then
        self:_RefreshSelectedAbilityAnimState(HIGHLIGHT_LOOP_ANIMATION_NAME)
        self.view.highlight.gameObject:SetActive(true)
    elseif self.view.highlight.gameObject.activeSelf and not needHighlight then
        self:_RefreshSelectedAbilityAnimState(HIGHLIGHT_DEFAULT_ANIMATION_NAME)
        self.view.highlight.gameObject:SetActive(false)
    end
end
GeneralAbilityCtrl._RefreshAllDecoUnSelectedState = HL.Method() << function(self)
    for index = 1, self.view.config.CELL_MAX_COUNT do
        local deco = self.m_decoCells:GetItem(index)
        if deco ~= nil then
            deco.selected.gameObject:SetActive(false)
        end
    end
end
GeneralAbilityCtrl._RefreshShownState = HL.Method() << function(self)
    if not self.m_isValid then
        self.view.main.gameObject:SetActive(false)
        return
    end
    local isForbidden = GameInstance.player.forbidSystem:IsForbidden(ForbidType.HideGeneralAbility)
    if isForbidden then
        self.view.main.gameObject:SetActive(false)
        return
    end
    self.view.main.gameObject:SetActive(true)
end
GeneralAbilityCtrl._RefreshSelectedAbilityAnimState = HL.Method(HL.String) << function(self, animName)
    if self.view.selectedAbilityAnim.curStateName == animName then
        return
    end
    if animName == HINT_ANIMATION_NAME or animName == HINT_OUT_ANIMATION_NAME then
        self.view.selectedAbilityAnim:PlayWithTween(animName)
    else
        self.view.selectedAbilityAnim:PlayWithTween(animName, function()
            if self.m_isSwitchTipShown and self.view.selectedAbilityAnim.curStateName ~= HINT_ANIMATION_NAME then
                self.view.selectedAbilityAnim:PlayWithTween(HINT_ANIMATION_NAME)
            end
        end)
    end
end
GeneralAbilityCtrl._RefreshSwitchTipShownState = HL.Method(HL.Boolean) << function(self, isShown)
    self.view.switchTipsIcon.gameObject:SetActiveIfNecessary(isShown)
    self.m_isSwitchTipShown = isShown
    local animName = isShown and HINT_ANIMATION_NAME or HINT_OUT_ANIMATION_NAME
    self:_RefreshSelectedAbilityAnimState(animName)
end
GeneralAbilityCtrl._ResetSelectedAbility = HL.Method() << function(self)
    local initialType
    for type, data in pairs(self.m_abilityDataMap) do
        if data ~= nil then
            if initialType == nil then
                initialType = type
            end
            if type == GeneralAbilityType.Scan:GetHashCode() then
                initialType = type
            end
        end
    end
    if initialType ~= nil then
        self:_SetSelectedAbility(initialType, true)
    end
end
GeneralAbilityCtrl._GetSelectedAbility = HL.Method().Return(HL.Number) << function(self, type)
    return self.m_selectedAbilityType == INVALID_ABILITY_TYPE and ClientDataManagerInst:GetInt(SELECTED_ABILITY_TYPE_CLIENT_LOCAL_DATA_KEY, false, INVALID_ABILITY_TYPE) or self.m_selectedAbilityType
end
GeneralAbilityCtrl._SetSelectedAbility = HL.Method(HL.Number, HL.Boolean) << function(self, type, needSave)
    self.view.selectedAbility:InitGeneralAbilityCell(type, function(isValid, fromState)
        if isValid and fromState ~= GeneralAbilityState.None then
            self:_RefreshSelectedAbilityAnimState(VALID_ANIMATION_NAME)
        end
    end)
    self.view.selectedAbility:SetCustomCDFillImage(self.view.selectedAbility.view.fillImage)
    local lastType = self.m_selectedAbilityType
    self.m_selectedAbilityType = type
    GameInstance.player.generalAbilitySystem.selectGeneralAbility = type
    local lastData = self.m_abilityDataMap[lastType]
    if lastData ~= nil then
        local lastDeco = self.m_decoCells:GetItem(lastData.index)
        lastDeco.selected.gameObject:SetActive(false)
    end
    local currData = self.m_abilityDataMap[type]
    if currData ~= nil then
        local currDeco = self.m_decoCells:GetItem(currData.index)
        currDeco.selected.gameObject:SetActive(true)
    end
    self:_RefreshSwitchTipShownState(type ~= self.m_tipsAbilityType and self.m_tipsAbilityType ~= INVALID_ABILITY_TYPE)
    if needSave and not GameInstance.player.generalAbilitySystem:IsTempAbility(type) then
        ClientDataManagerInst:SetInt(SELECTED_ABILITY_TYPE_CLIENT_LOCAL_DATA_KEY, type, false)
    end
end
GeneralAbilityCtrl._StartSelectedAbilityPress = HL.Method() << function(self)
    self:_ClearSelectedAbilityPress()
    self.m_selectedAbilityPressTime = 0
    if not self:_IsAllowedInPlayerController() then
        return
    end
    self.m_selectedAbilityPressTick = LuaUpdate:Add("Tick", function(deltaTime)
        self.m_selectedAbilityPressTime = self.m_selectedAbilityPressTime + deltaTime
        if self.m_selectedAbilityPressTime >= self.m_abilityUsePressDuration then
            local progress = self.view.pressProgress
            if not progress.gameObject.activeSelf then
                progress.gameObject:SetActive(true)
            end
            progress.fillAmount = (self.m_selectedAbilityPressTime - self.m_abilityUsePressDuration) / (self.m_abilitySwitchPressDuration - self.m_abilityUsePressDuration)
            if self.m_selectedAbilityPressTime >= self.m_abilitySwitchPressDuration then
                self:_OnSelectedAbilitySwitchLongPressed()
                self:_ClearSelectedAbilityPress()
            end
        end
    end)
end
GeneralAbilityCtrl._StopSelectedAbilityPress = HL.Method() << function(self)
    if self.m_selectedAbilityPressTime < self.m_abilityUsePressDuration then
        self:_OnSelectedAbilityUseClicked()
    end
    self:_ClearSelectedAbilityPress()
    if self.m_canReleaseCloseSelector and self.m_isSelectorShown then
        if self.m_hoverSelectorType ~= INVALID_ABILITY_TYPE then
            self:_SetSelectedAbility(self.m_hoverSelectorType, true)
        end
        self:_RefreshAbilitySelectorShownState(false)
    end
end
GeneralAbilityCtrl._ClearSelectedAbilityPress = HL.Method() << function(self)
    if self.m_selectedAbilityPressTick ~= -1 then
        self.m_selectedAbilityPressTick = LuaUpdate:Remove(self.m_selectedAbilityPressTick)
    end
    self.view.pressProgress.gameObject:SetActive(false)
end
GeneralAbilityCtrl._OnAbilityValidStateChanged = HL.Method(HL.Number, HL.Boolean) << function(self, type, isValid)
    if isValid then
        if NEED_TIPS_ABILITY_TYPES[type] then
            self.m_tipsAbilityType = type
            if type ~= self.m_selectedAbilityType then
                self:_RefreshSwitchTipShownState(true)
            end
        end
    else
        if type == self.m_tipsAbilityType then
            self.m_tipsAbilityType = INVALID_ABILITY_TYPE
            self:_RefreshSwitchTipShownState(false)
        end
    end
    local abilityData = self.m_abilityDataMap[type]
    if abilityData ~= nil and abilityData.cell ~= nil then
        abilityData.cell.controller:SetState(isValid and SelectorCellState.Normal or SelectorCellState.Invalid)
        abilityData.cell.ability.view.gameObject:SetActive(isValid)
    end
end
GeneralAbilityCtrl._UseAbilityItem = HL.Method(HL.String) << function(self, itemId)
    GameInstance.player.inventory:UseItem(Utils.getCurrentScope(), itemId)
end
GeneralAbilityCtrl._IsAllowedInPlayerController = HL.Method().Return(HL.Boolean) << function(self)
    return GameInstance.playerController:IsPlayerActionEnabled(PlayerController.InputActionType.GeneralAbility)
end
HL.Commit(GeneralAbilityCtrl)