local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.QuickMenu
QuickMenuCtrl = HL.Class('QuickMenuCtrl', uiCtrl.UICtrl)
local QUICK_MENU_EMPTY_ITEM_ID = -1
local QUICK_MENU_INVALID_ITEM_ID = -1
QuickMenuCtrl.m_quickMenuSystemPhaseIdList = HL.Field(HL.Table)
QuickMenuCtrl.m_quickMenuFactoryRegionIdList = HL.Field(HL.Table)
QuickMenuCtrl.m_quickMenuNotDungeonIdList = HL.Field(HL.Table)
QuickMenuCtrl.m_quickMenuItemConfig = HL.Field(HL.Table)
QuickMenuCtrl.m_quickMenuItemGameObjectNameConfig = HL.Field(HL.Table)
QuickMenuCtrl.m_quickMenuItemData = HL.Field(HL.Table)
QuickMenuCtrl.m_quickMenuUpdateThread = HL.Field(HL.Thread)
QuickMenuCtrl.m_currentArrowAngle = HL.Field(HL.Number) << 0
QuickMenuCtrl.m_currentSelectedItemId = HL.Field(HL.Number) << -1
QuickMenuCtrl.m_currentStickPushed = HL.Field(HL.Boolean) << false
QuickMenuCtrl.m_enterSelectedSystemBindingId = HL.Field(HL.Number) << -1
QuickMenuCtrl.s_messages = HL.StaticField(HL.Table) << {}
QuickMenuCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:_InitQuickMenu()
    self:_BuildQuickMenuIdList()
    self:_BuildQuickMenuItemConfig()
    self:_BuildQuickMenuItemData()
end
QuickMenuCtrl.OnShow = HL.Override() << function(self)
    self:_ActivateQuickMenu()
    self:_RefreshQuickMenuValidItemDisplay()
    self:_RefreshQuickMenuFactoryItemDisplay()
    self:_RefreshQuickMenuLockedItemDisplay()
    self:_RefreshQuickMenuNormalItemDisplay()
    self:_RefreshQuickMenuExtraInfo()
    AudioManager.PostEvent("au_ui_menu_dial_open")
end
QuickMenuCtrl.OnHide = HL.Override() << function(self)
    self:_DeactivateQuickMenu()
end
QuickMenuCtrl.OnClose = HL.Override() << function(self)
    self:_DeactivateQuickMenu()
    self.m_quickMenuUpdateThread = self:_ClearCoroutine(self.m_quickMenuUpdateThread)
    AudioManager.PostEvent("au_ui_menu_dial_close")
end
QuickMenuCtrl._BuildQuickMenuIdList = HL.Method() << function(self)
    self.m_quickMenuSystemPhaseIdList = { EMPTY = QUICK_MENU_EMPTY_ITEM_ID, CHARACTER = PhaseId.CharInfo, INVENTORY = PhaseId.Inventory, MISSION = PhaseId.Mission, TECH_TREE = PhaseId.FacTechTree, WIKI = PhaseId.Wiki, CHAR_FORMATION = PhaseId.CharFormation, VALUABLE_DEPOT = PhaseId.ValuableDepot, MAIL = PhaseId.Mail, }
    self.m_quickMenuFactoryRegionIdList = { self.m_quickMenuSystemPhaseIdList.EMPLOYEE, }
    self.m_quickMenuNotDungeonIdList = { self.m_quickMenuSystemPhaseIdList.CHAR_FORMATION, self.m_quickMenuSystemPhaseIdList.HUB_DATA, self.m_quickMenuSystemPhaseIdList.TECH_TREE, self.m_quickMenuSystemPhaseIdList.EMPLOYEE, }
end
QuickMenuCtrl._BuildQuickMenuItemConfig = HL.Method() << function(self)
    self.m_quickMenuItemConfig = { self.m_quickMenuSystemPhaseIdList.CHARACTER, self.m_quickMenuSystemPhaseIdList.VALUABLE_DEPOT, self.m_quickMenuSystemPhaseIdList.INVENTORY, self.m_quickMenuSystemPhaseIdList.MAIL, self.m_quickMenuSystemPhaseIdList.TECH_TREE, self.m_quickMenuSystemPhaseIdList.WIKI, self.m_quickMenuSystemPhaseIdList.CHAR_FORMATION, self.m_quickMenuSystemPhaseIdList.MISSION, }
    self.m_quickMenuItemGameObjectNameConfig = { [self.m_quickMenuSystemPhaseIdList.CHARACTER] = "Character", [self.m_quickMenuSystemPhaseIdList.VALUABLE_DEPOT] = "ValuableDepot", [self.m_quickMenuSystemPhaseIdList.INVENTORY] = "Inventory", [self.m_quickMenuSystemPhaseIdList.MAIL] = "Mail", [self.m_quickMenuSystemPhaseIdList.TECH_TREE] = "TechTree", [self.m_quickMenuSystemPhaseIdList.WIKI] = "Wiki", [self.m_quickMenuSystemPhaseIdList.CHAR_FORMATION] = "CharFormation", [self.m_quickMenuSystemPhaseIdList.MISSION] = "Mission", }
end
QuickMenuCtrl._BuildQuickMenuItemData = HL.Method() << function(self)
    self.m_quickMenuItemData = {}
    local itemCount = #self.m_quickMenuItemConfig
    if itemCount == nil or itemCount <= 0 then
        return
    end
    local rotateAngle = 360 / itemCount
    for i, phaseId in ipairs(self.m_quickMenuItemConfig) do
        local isEmptyItem = phaseId == QUICK_MENU_EMPTY_ITEM_ID
        local itemCell = Utils.wrapLuaNode(UIUtils.addChild(self.view.quickMenuContent, self.view.quickMenuCell))
        local targetAngle = rotateAngle * (i - 1)
        local angleLeftBound, angleRightBound = targetAngle - rotateAngle / 2, targetAngle + rotateAngle / 2
        itemCell.transform.localEulerAngles = Vector3(0, 0, -targetAngle)
        itemCell.gameObject.name = string.format("QuickMenuCell_%s", self.m_quickMenuItemGameObjectNameConfig[phaseId])
        itemCell.gameObject:SetActiveIfNecessary(true)
        itemCell.systemIcon.transform.localEulerAngles = Vector3(0, 0, targetAngle)
        itemCell.systemIconShadow.transform.localEulerAngles = Vector3(0, 0, targetAngle)
        local systemViewConfig = PhaseManager:GetPhaseSystemViewConfig(phaseId)
        local spriteName = isEmptyItem and "btn_empty" or systemViewConfig.systemIcon
        local itemSprite = self:LoadSprite(UIConst.UI_SPRITE_MAIN_HUD, spriteName)
        if itemSprite ~= nil then
            itemCell.systemIcon.sprite = itemSprite
            itemCell.systemIconShadow.sprite = itemSprite
        end
        local redDot = isEmptyItem and "" or PhaseManager:GetPhaseRedDotName(phaseId)
        if not string.isEmpty(redDot) and not self:_GetQuickMenuItemIsLocked(phaseId) then
            itemCell.redDot.gameObject:SetActiveIfNecessary(true)
            itemCell.redDot:InitRedDot(redDot)
        end
        self.m_quickMenuItemData[phaseId] = { itemCell = itemCell, name = isEmptyItem and Language.LUA_LOCKED_SYSTEM_TITLE or systemViewConfig.systemName, desc = isEmptyItem and Language.LUA_LOCKED_SYSTEM_DESCRIPTION or systemViewConfig.systemDesc, angleLeftBound = angleLeftBound, angleRightBound = angleRightBound, isValid = not isEmptyItem, isLocked = false, }
    end
end
QuickMenuCtrl._InitQuickMenu = HL.Method() << function(self)
    self.m_quickMenuUpdateThread = self:_StartCoroutine(function()
        while true do
            coroutine.step()
            if self:IsShow() then
                local lastSelectedId = self.m_currentSelectedItemId
                self:_UpdateSelectArrowState()
                self:_UpdateSelectItemState()
                if lastSelectedId ~= self.m_currentSelectedItemId then
                    if string.isEmpty(lastSelectedId) then
                        InputManagerInst:ToggleBinding(self.m_enterSelectedSystemBindingId, true)
                    end
                    self:_UpdateSystemInfo()
                end
                self:_UpdateQuickMenuState()
            end
        end
    end)
    self:BindInputPlayerAction("common_cancel", function()
        self:Close()
    end)
    self:BindInputPlayerAction("quickMenu_confirm_selected_system", function()
        self:_SelectQuickMenuItem()
    end)
    self.m_enterSelectedSystemBindingId = self:BindInputPlayerAction("quickMenu_enter_selected_system", function()
    end)
    InputManagerInst:ToggleBinding(self.m_enterSelectedSystemBindingId, false)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
QuickMenuCtrl._ActivateQuickMenu = HL.Method() << function(self)
    Notify(MessageConst.TOGGLE_LEVEL_CAMERA_MOVE, { "QuickMenuPanel", false })
    self.view.selectArrow.gameObject:SetActiveIfNecessary(false)
end
QuickMenuCtrl._DeactivateQuickMenu = HL.Method() << function(self)
    Notify(MessageConst.TOGGLE_LEVEL_CAMERA_MOVE, { "QuickMenuPanel", true })
end
QuickMenuCtrl._SelectQuickMenuItem = HL.Method() << function(self)
    if self.m_currentSelectedItemId == QUICK_MENU_INVALID_ITEM_ID then
        return
    end
    local itemData = self.m_quickMenuItemData[self.m_currentSelectedItemId]
    if itemData == nil then
        return
    end
    local isNormalItem = itemData.isValid and not itemData.isLocked
    if isNormalItem == false then
        return
    end
    if self:IsShow() then
        self:Close()
    end
    PhaseManager:OpenPhase(self.m_currentSelectedItemId)
end
QuickMenuCtrl._GetQuickMenuItemIsInConfig = HL.Method(HL.Table, HL.Number).Return(HL.Boolean) << function(self, configTable, phaseId)
    if configTable == nil then
        return
    end
    for _, id in ipairs(configTable) do
        if id == phaseId then
            return true
        end
    end
    return false
end
QuickMenuCtrl._GetQuickMenuItemIsLocked = HL.Method(HL.Number).Return(HL.Boolean) << function(self, phaseId)
    return not PhaseManager:IsPhaseUnlocked(phaseId)
end
QuickMenuCtrl._GetQuickMenuItemIsValid = HL.Method(HL.Number).Return(HL.Boolean) << function(self, phaseId)
    if phaseId == QUICK_MENU_EMPTY_ITEM_ID then
        return false
    end
    local isInFacMainRegion = Utils.isInFacMainRegion()
    local isInDungeon = UIUtils.inDungeon()
    if self:_GetQuickMenuItemIsInConfig(self.m_quickMenuFactoryRegionIdList, phaseId) and not isInFacMainRegion then
        return false
    end
    if self:_GetQuickMenuItemIsInConfig(self.m_quickMenuNotDungeonIdList, phaseId) and isInDungeon then
        return false
    end
    return true
end
QuickMenuCtrl._RefreshQuickMenuFactoryItemDisplay = HL.Method() << function(self)
    local iconAnimName = Utils.isInFacMainRegion() and "quickmenu_normal_icon" or "quickmenu_invalid_icon"
    self.view.iconAnimationWrapper:PlayWithTween(iconAnimName)
    if not UIUtils.inDungeon() then
        for _, regionItemId in ipairs(self.m_quickMenuFactoryRegionIdList) do
            local itemData = self.m_quickMenuItemData[regionItemId]
            if itemData and not itemData.isValid then
                itemData.desc = Language.LUA_INVALID_FACTORY_REGION_SYSTEM_DESCRIPTION
            end
        end
    end
end
QuickMenuCtrl._RefreshQuickMenuLockedItemDisplay = HL.Method() << function(self)
    for phaseId, itemData in pairs(self.m_quickMenuItemData) do
        itemData.isLocked = self:_GetQuickMenuItemIsLocked(phaseId)
        if itemData.isLocked then
            local iconSprite = self:LoadSprite(UIConst.UI_SPRITE_MAIN_HUD, "btn_empty")
            local itemCell = itemData.itemCell
            if itemCell ~= nil then
                if iconSprite ~= nil then
                    itemCell.systemIcon.sprite = iconSprite
                    itemCell.systemIconShadow.sprite = iconSprite
                    itemCell.animationWrapper:PlayWithTween("quickmenu_normal_item")
                end
            end
            itemData.name = Language.LUA_LOCKED_SYSTEM_TITLE
            itemData.desc = Language.LUA_LOCKED_SYSTEM_DESCRIPTION
        end
    end
end
QuickMenuCtrl._RefreshQuickMenuValidItemDisplay = HL.Method() << function(self)
    for phaseId, itemData in pairs(self.m_quickMenuItemData) do
        itemData.isValid = self:_GetQuickMenuItemIsValid(phaseId)
        if not itemData.isValid and phaseId ~= QUICK_MENU_EMPTY_ITEM_ID then
            local itemCell = itemData.itemCell
            if itemCell ~= nil then
                itemCell.animationWrapper:PlayWithTween("quickmenu_invalid_item")
            end
            itemData.desc = Language.LUA_INVALID_SYSTEM_COMMON_DESCRIPTION
        end
    end
end
QuickMenuCtrl._RefreshQuickMenuNormalItemDisplay = HL.Method() << function(self)
    for phaseId, itemData in pairs(self.m_quickMenuItemData) do
        local success, systemConfigData = Tables.gameSystemConfigTable:TryGetValue(phaseId)
        local isNormalItem = not itemData.isLocked and itemData.isValid
        if success and isNormalItem then
            local itemCell = itemData.itemCell
            if itemCell ~= nil then
                itemCell.animationWrapper:PlayWithTween("quickmenu_normal_item")
            end
            itemData.name = systemConfigData.systemName
            itemData.desc = systemConfigData.systemDesc
        end
    end
end
QuickMenuCtrl._RefreshQuickMenuExtraInfo = HL.Method() << function(self)
    local isInFacMainRegion = Utils.isInFacMainRegion() and UIManager:IsShow(PanelId.FacMainLeft)
    local isInDungeon = UIUtils.inDungeon()
    self.view.extraInfoNode.gameObject:SetActiveIfNecessary(true)
    local extraInfoView = self.view.extraInfo
    if isInFacMainRegion then
        self:BindInputPlayerAction("fac_quick_menu_switch_device_icon_display", function()
            Notify(MessageConst.FAC_SWITCH_BUILDING_TARGET_DISPLAY_MODE)
            self:_RefreshQuickMenuExtraInfoHintText()
        end)
        extraInfoView.buildingNode.gameObject:SetActiveIfNecessary(true)
        extraInfoView.dungeonNode.gameObject:SetActiveIfNecessary(false)
        extraInfoView.keyHint:SetActionId("fac_quick_menu_switch_device_icon_display")
        self:_RefreshQuickMenuExtraInfoHintText()
        return
    end
    if isInDungeon then
        self:BindInputPlayerAction("mission_quick_menu_open_dungeon_detail", function()
            local dungeonId = GameInstance.dungeonManager.curDungeonId
            UIManager:AutoOpen(PanelId.DungeonInfoPopup, { dungeonId = dungeonId })
            self.m_currentSelectedItemId = QUICK_MENU_INVALID_ITEM_ID
            self:Close()
        end)
        extraInfoView.buildingNode.gameObject:SetActiveIfNecessary(false)
        extraInfoView.dungeonNode.gameObject:SetActiveIfNecessary(true)
        extraInfoView.keyHint:SetActionId("mission_quick_menu_open_dungeon_detail")
        return
    end
    self.view.extraInfoNode.gameObject:SetActiveIfNecessary(false)
end
QuickMenuCtrl._RefreshQuickMenuExtraInfoHintText = HL.Method() << function(self)
    local isMachineTargetShown = FactoryUtils.isMachineTargetShown()
    local switchIconDisplayTextId = isMachineTargetShown and "key_hint_fac_quick_menu_hide_device_icon" or "key_hint_fac_quick_menu_show_device_icon"
    self.view.extraInfo.buildingHintText.text = Language[switchIconDisplayTextId]
    self.view.extraInfo.buildingOffNode.gameObject:SetActiveIfNecessary(isMachineTargetShown)
    self.view.extraInfo.buildingOnNode.gameObject:SetActiveIfNecessary(not isMachineTargetShown)
end
QuickMenuCtrl._UpdateQuickMenuState = HL.Method() << function(self)
    local useLeftTrigger = InputManagerInst:GetKey(CS.Beyond.Input.GamepadKeyCode.LT)
    if not useLeftTrigger then
        self:Close()
        if DataManager.gameplayMiscSetting.controllerReleaseSkillWhenR2Released then
            self:_SelectQuickMenuItem()
        end
    end
end
QuickMenuCtrl._UpdateSelectArrowState = HL.Method() << function(self)
    local stickValue = InputManagerInst:GetGamepadStickValue(false)
    if stickValue.magnitude < self.view.config.RIGHT_STICK_DEAD_ZONE_VALUE then
        self.m_currentStickPushed = false
        return
    end
    local angle = 180 * (math.acos(Vector2.Dot(stickValue.normalized, Vector2(0, 1))) / math.pi)
    if stickValue.x < 0 then
        angle = 360 - angle
    end
    self.m_currentArrowAngle = angle
    self.view.selectArrow.eulerAngles = Vector3(0, 0, -angle)
    self.view.selectArrow.gameObject:SetActiveIfNecessary(true)
    self.m_currentStickPushed = true
end
QuickMenuCtrl._UpdateSelectItemState = HL.Method() << function(self)
    if self.m_currentArrowAngle == 0 and not self.m_currentStickPushed then
        if not self.m_currentSelectedItemId == QUICK_MENU_INVALID_ITEM_ID then
            local itemData = self.m_quickMenuItemData[self.m_currentSelectedItemId]
            if itemData ~= nil and itemData.itemCell ~= nil then
                itemData.itemCell.selectedMark.gameObject:SetActiveIfNecessary(false)
            end
            self.m_currentSelectedItemId = QUICK_MENU_INVALID_ITEM_ID
        end
        return
    end
    for itemId, itemData in pairs(self.m_quickMenuItemData) do
        local itemCell = itemData.itemCell
        local angleLeftBound, angleRightBound = itemData.angleLeftBound, itemData.angleRightBound
        local isSelected = false
        if angleLeftBound < 0 then
            angleLeftBound = 360 + angleLeftBound
            isSelected = (self.m_currentArrowAngle >= angleLeftBound and self.m_currentArrowAngle <= 360) or (self.m_currentArrowAngle >= 0 and self.m_currentArrowAngle < angleRightBound)
        else
            isSelected = self.m_currentArrowAngle >= angleLeftBound and self.m_currentArrowAngle < angleRightBound
        end
        itemCell.selectedMark.gameObject:SetActiveIfNecessary(isSelected)
        if isSelected then
            self.m_currentSelectedItemId = itemId
        end
    end
end
QuickMenuCtrl._UpdateSystemInfo = HL.Method() << function(self)
    local itemData = self.m_quickMenuItemData[self.m_currentSelectedItemId]
    if itemData == nil then
        self.view.tips.gameObject:SetActiveIfNecessary(true)
        self.view.systemInfo.gameObject:SetActiveIfNecessary(false)
        return
    end
    local name, desc = itemData.name, itemData.desc
    self.view.systemName.text = name
    self.view.systemDesc.text = desc
    local descAnimName = (itemData.isValid and not itemData.isLocked) and "quickmenu_normal_desc" or "quickmenu_invalid_desc"
    self.view.descAnimationWrapper:PlayWithTween(descAnimName)
    self.view.tips.gameObject:SetActiveIfNecessary(false)
    self.view.systemInfo.gameObject:SetActiveIfNecessary(true)
    AudioManager.PostEvent("au_ui_hover_dial")
end
HL.Commit(QuickMenuCtrl)