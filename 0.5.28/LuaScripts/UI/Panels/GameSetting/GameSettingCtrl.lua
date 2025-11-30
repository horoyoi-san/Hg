local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GameSetting
local GameSettingSetter = CS.Beyond.Scripts.Entry.GameSettingSetter
local GameSettingHelper = CS.Beyond.Gameplay.GameSettingHelper
local GameSetting = CS.Beyond.GameSetting
local QUALITY_SETTING_ID = GameSetting.ID_VIDEO_QUALITY
GameSettingCtrl = HL.Class('GameSettingCtrl', uiCtrl.UICtrl)
local SETTING_ICON_SPRITE_NAME_FORMAT = "icon_settings_%s"
local INITIAL_TAB_INDEX = 1
local CUSTOM_QUALITY_SETTING_INDEX = 1
local VOLUME_COEFFICIENT = 10.0
local LANGUAGE_TEXT_POP_UP_CONTENT_TEXT_ID = "ui_set_gamesetting_switch_lang_black"
local LANGUAGE_AUDIO_POP_UP_CONTENT_TEXT_ID = "ui_set_gamesetting_switch_voice_black"
local LANGUAGE_POP_UP_WARNING_TEXT_ID = "ui_set_gamesetting_switch_lang_red"
local LANGUAGE_RESOLUTION_POP_UP_CONTENT_TEXT_ID = "ui_set_gamesetting_switch_resolution"
local LANGUAGE_QUALITY_POP_UP_CONTENT_TEXT_ID = "ui_set_gamesetting_switch_graphic"
local DROPDOWN_FULL_SCREEN_RESOLUTION_TEXT_ID = "LUA_GAME_SETTING_FULL_SCREEN_RESOLUTION"
local DROPDOWN_WINDOWED_RESOLUTION_TEXT_ID = "LUA_GAME_SETTING_WINDOWED_RESOLUTION"
local DROPDOWN_MAIN_QUALITY_DEFAULT_TEXT_ID = "LUA_GAME_SETTING_DEFAULT_MAIN_QUALITY"
local KEY_HINT_TAB_ID = "gameSetting_key_hint"
local ITEM_TYPE_LIST = { GEnums.SettingItemType.Toggle, GEnums.SettingItemType.Dropdown, GEnums.SettingItemType.Slider, GEnums.SettingItemType.Button, }
GameSettingCtrl.m_tabCells = HL.Field(HL.Forward('UIListCache'))
GameSettingCtrl.m_tabDataList = HL.Field(HL.Table)
GameSettingCtrl.m_itemCells = HL.Field(HL.Forward('UIListCache'))
GameSettingCtrl.m_itemCacheMap = HL.Field(HL.Table)
GameSettingCtrl.m_itemDataList = HL.Field(HL.Table)
GameSettingCtrl.m_itemCellMap = HL.Field(HL.Table)
GameSettingCtrl.m_originalPadding = HL.Field(HL.Number) << -1
GameSettingCtrl.m_originalAudioSlide = HL.Field(HL.String) << ""
GameSettingCtrl.m_sliderValueDataMap = HL.Field(HL.Table)
GameSettingCtrl.m_qualitySubSettingDataMap = HL.Field(HL.Table)
GameSettingCtrl.s_messages = HL.StaticField(HL.Table) << {}
GameSettingCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.btnClose.onClick:AddListener(function()
        self:_OnCloseBtnClick()
    end)
    self.m_tabCells = UIUtils.genCellCache(self.view.tabs.tabCell)
    self.m_itemCells = UIUtils.genCellCache(self.view.settingItemCell)
    self.m_originalPadding = self.view.sourceItem.dropDownSetting.dropDownListMask.padding.w
    self.m_originalAudioSlide = self.view.sourceItem.sliderSetting.slider.audioSlide
    self.m_tabDataList = {}
    self.m_itemDataList = {}
    self.m_itemCellMap = {}
    self.m_sliderValueDataMap = {}
    self.m_qualitySubSettingDataMap = {}
    self.m_itemCacheMap = {}
    self:_BuildSettingDataList()
    self:_InitSettingTabList()
end
GameSettingCtrl._OnCloseBtnClick = HL.Method() << function(self)
    PhaseManager:PopPhase(PhaseId.GameSetting)
end
GameSettingCtrl._BuildSettingDataList = HL.Method() << function(self)
    local tabDataMap = Tables.settingTabTable
    if tabDataMap == nil then
        return
    end
    for _, tabData in pairs(tabDataMap) do
        if tabData.tabItems ~= nil then
            table.insert(self.m_tabDataList, tabData)
        end
    end
    table.sort(self.m_tabDataList, function(dataA, dataB)
        return dataA.tabSortOrder < dataB.tabSortOrder
    end)
    for tabIndex, tabData in ipairs(self.m_tabDataList) do
        local itemDataMap = tabData.tabItems
        self.m_itemDataList[tabIndex] = {}
        for _, itemData in pairs(itemDataMap) do
            table.insert(self.m_itemDataList[tabIndex], itemData)
        end
        table.sort(self.m_itemDataList[tabIndex], function(dataA, dataB)
            return dataA.settingSortOrder < dataB.settingSortOrder
        end)
    end
end
GameSettingCtrl._GetCachedItem = HL.Method(HL.Userdata, HL.Userdata).Return(HL.Table) << function(self, transform, itemType)
    if self.m_itemCacheMap[transform] == nil then
        self.m_itemCacheMap[transform] = {}
    end
    local cachedItem = self.m_itemCacheMap[transform]
    local sourceNode = self.view.sourceItem
    if cachedItem[itemType] == nil then
        local sourceItem
        if itemType == GEnums.SettingItemType.Dropdown then
            sourceItem = sourceNode.dropDownSetting
        elseif itemType == GEnums.SettingItemType.Slider then
            sourceItem = sourceNode.sliderSetting
        elseif itemType == GEnums.SettingItemType.Button then
            sourceItem = sourceNode.buttonSetting
        elseif itemType == GEnums.SettingItemType.Toggle then
            sourceItem = sourceNode.toggleSetting
        end
        local object = CSUtils.CreateObject(sourceItem.gameObject, transform)
        cachedItem[itemType] = Utils.wrapLuaNode(object)
    end
    local item = cachedItem[itemType]
    for _, type in pairs(ITEM_TYPE_LIST) do
        if type ~= itemType then
            if cachedItem[type] ~= nil then
                cachedItem[type].gameObject:SetActive(false)
            end
        end
    end
    item.gameObject:SetActive(true)
    item.rectTransform.anchoredPosition = Vector2.zero
    return item
end
GameSettingCtrl._InitSettingTabList = HL.Method() << function(self)
    self.m_tabCells:Refresh(#self.m_tabDataList, function(tabCell, tabIndex)
        self:_RefreshSettingTabCell(tabCell, tabIndex)
    end)
    self:_RefreshSettingTab(INITIAL_TAB_INDEX)
end
GameSettingCtrl._RefreshSettingTabCell = HL.Method(HL.Table, HL.Number) << function(self, tabCell, tabIndex)
    local tabData = self.m_tabDataList[tabIndex]
    if tabData == nil then
        return
    end
    tabCell.gameObject.name = string.format("GameSettingTab_%s", tabData.tabId)
    local spriteName = string.format(SETTING_ICON_SPRITE_NAME_FORMAT, tabData.tabIcon)
    local sprite = self:LoadSprite(UIConst.UI_SPRITE_GAME_SETTING, spriteName)
    if sprite ~= nil then
        tabCell.selectedIcon.sprite = sprite
        tabCell.defaultIcon.sprite = sprite
    end
    tabCell.toggle.isOn = tabIndex == INITIAL_TAB_INDEX
    tabCell.toggle.onValueChanged:RemoveAllListeners()
    tabCell.toggle.onValueChanged:AddListener(function(isOn)
        if isOn then
            self:_OnSettingTabClicked(tabIndex)
        end
    end)
end
GameSettingCtrl._OnSettingTabClicked = HL.Method(HL.Number) << function(self, tabIndex)
    self:_RefreshSettingTab(tabIndex)
    self.view.animationWrapper:PlayWithTween("gamesetting_change")
end
GameSettingCtrl._RefreshSettingTab = HL.Method(HL.Number) << function(self, tabIndex)
    local tabData = self.m_tabDataList[tabIndex]
    if tabData == nil then
        return
    end
    local itemDataList = self.m_itemDataList[tabIndex]
    if itemDataList == nil then
        return
    end
    self.view.tabTitleTxt.text = tabData.tabText
    if tabData.tabId ~= KEY_HINT_TAB_ID then
        self.m_itemCellMap = {}
        self.m_qualitySubSettingDataMap = {}
        self.m_itemCells:Refresh(#itemDataList, function(itemCell, itemIndex)
            self:_RefreshSettingItemCell(itemCell, itemIndex, tabIndex)
        end)
    end
    self.view.settingContent.gameObject:SetActive(tabData.tabId ~= KEY_HINT_TAB_ID)
    self.view.keyHintContent.gameObject:SetActive(tabData.tabId == KEY_HINT_TAB_ID)
end
GameSettingCtrl._RefreshSettingItemCell = HL.Method(HL.Table, HL.Number, HL.Number) << function(self, itemCell, itemIndex, tabIndex)
    local itemDataList = self.m_itemDataList[tabIndex]
    if itemDataList == nil then
        return
    end
    local itemData = itemDataList[itemIndex]
    if itemData == nil then
        return
    end
    itemCell.gameObject.name = string.format("GameSettingItem_%s", itemData.settingId)
    itemCell.settingItemText.text = itemData.settingText
    local itemType = itemData.settingItemType
    local item = self:_GetCachedItem(itemCell.cacheTransform, itemType)
    if itemType == GEnums.SettingItemType.Dropdown then
        self:_InitDropdownSettingItem(item, itemData, itemCell)
    elseif itemType == GEnums.SettingItemType.Slider then
        self:_InitSliderSettingItem(item, itemData)
    elseif itemType == GEnums.SettingItemType.Button then
        self:_InitButtonSettingItem(item, itemData)
    elseif itemType == GEnums.SettingItemType.Toggle then
        self:_InitToggleSettingItem(item, itemData)
    end
    local cellHeight = itemCell.rectTransform.rect.height
    local position = itemCell.rectTransform.anchoredPosition
    itemCell.rectTransform.anchoredPosition = Vector2(position.x, (itemIndex - 1) * (-cellHeight - self.view.config.SETTING_ITEM_VERTICAL_SPACE))
    if GameSettingHelper.IsQualitySubSetting(itemData.settingId) then
        self.m_qualitySubSettingDataMap[itemData.settingId] = { itemCell = item, itemType = itemData.settingItemType }
    end
    self.m_itemCellMap[itemData.settingId] = item
end
GameSettingCtrl._InitDropdownSettingItem = HL.Method(HL.Table, HL.Any, HL.Table) << function(self, itemCell, itemData, originalCell)
    local settingId = itemData.settingId
    local optionTextList = {}
    itemCell.dropdown:ClearComponent()
    itemCell.dropdown:Init(function(csIndex, option, isSelected)
        option:SetText(optionTextList[LuaIndex(csIndex)])
    end, function(csIndex)
        if GameSettingHelper.IsQualitySubSetting(settingId) then
            local index = self:_DropdownGetQualitySubSettingOptionIndex(settingId)
            if index ~= LuaIndex(csIndex) then
                self:_DropdownSetQualitySubSettingOptionIndex(settingId, LuaIndex(csIndex))
            end
        else
            local selectFunction = self:_GetSettingFunctionName(itemData.dropdownOptionSelectFunction)
            local getFunction = self:_GetSettingFunctionName(itemData.dropdownOptionGetFunction)
            if not string.isEmpty(selectFunction) then
                local index = -1
                if string.isEmpty(getFunction) then
                    index = self:_DropdownGetOptionIndex(settingId)
                else
                    index = self[getFunction](self, settingId)
                end
                if index ~= LuaIndex(csIndex) then
                    self[selectFunction](self, settingId, LuaIndex(csIndex))
                end
            end
        end
    end)
    itemCell.dropdown.onToggleOptList:AddListener(function(active)
        if active then
            self:_DropdownAdjustExpandDirection(itemCell, originalCell)
        end
    end)
    local initIndex = 1
    if GameSettingHelper.IsQualitySubSetting(settingId) then
        initIndex = self:_DropdownGetQualitySubSettingOptionIndex(settingId)
    else
        local getFunction = self:_GetSettingFunctionName(itemData.dropdownOptionGetFunction)
        initIndex = string.isEmpty(getFunction) and self:_DropdownGetOptionIndex(settingId) or self[getFunction](self, settingId)
    end
    self:_StartCoroutine(function()
        coroutine.step()
        if string.isEmpty(itemData.dropdownOptionTextListGetFunction) then
            local optionTextData = itemData.dropdownOptionTextList
            if optionTextData ~= nil then
                for i = 0, optionTextData.length - 1 do
                    if not string.isEmpty(optionTextData[i]) then
                        local text = UIUtils.resolveTextStyle(optionTextData[i])
                        table.insert(optionTextList, text)
                    end
                end
            end
        else
            local textListGetFunctionName = self:_GetSettingFunctionName(itemData.dropdownOptionTextListGetFunction)
            if not string.isEmpty(textListGetFunctionName) then
                optionTextList = self[textListGetFunctionName](self, itemData)
            end
        end
        itemCell.dropdown:Refresh(#optionTextList, CSIndex(initIndex), false)
    end)
end
GameSettingCtrl._InitSliderSettingItem = HL.Method(HL.Table, HL.Any) << function(self, itemCell, itemData)
    local settingId = itemData.settingId
    local getFunctionName = self:_GetSettingFunctionName(itemData.sliderValueGetFunction)
    local setFunctionName = self:_GetSettingFunctionName(itemData.sliderValueSetFunction)
    local iconOnClickFunction = self:_GetSettingFunctionName(itemData.sliderIconOnClickFunction)
    local iconListLength = #itemData.sliderIconList
    itemCell.sliderIconNode.gameObject:SetActive(iconListLength > 0)
    itemCell.sliderFillArea.gameObject:SetActive(itemData.sliderUseFill)
    itemCell.slider:ClearComponent()
    itemCell.sliderIconButton.onClick:RemoveAllListeners()
    itemCell.slider.audioSlide = ""
    itemCell.slider.wholeNumbers = itemData.sliderWholeNumbers
    itemCell.slider.minValue = itemData.sliderMinValue
    itemCell.slider.maxValue = itemData.sliderMaxValue
    self.m_sliderValueDataMap[settingId] = { minValue = itemData.sliderMinValue, maxValue = itemData.sliderMaxValue }
    itemCell.slider.onValueChanged:AddListener(function(value)
        if not string.isEmpty(setFunctionName) then
            self[setFunctionName](self, settingId, value)
            self:_SliderRecordValue(settingId, value)
        end
        if iconListLength > 0 then
            local icon = self:_SliderGetIcon(value, itemData.sliderIconList, itemData.sliderIconRangeList)
            if icon ~= nil then
                itemCell.sliderIcon.sprite = icon
                itemCell.sliderIcon.gameObject:SetActive(true)
            else
                itemCell.sliderIcon.gameObject:SetActive(false)
            end
        end
        self:_SliderRefreshText(itemCell, value)
    end)
    if not string.isEmpty(getFunctionName) then
        local initValue = self[getFunctionName](self, settingId)
        itemCell.slider:SetValueWithoutNotify(initValue, false)
        self:_SliderRefreshText(itemCell, initValue)
        self:_SliderRecordValue(settingId, initValue)
        if itemCell.slider.value == 0.0 then
            itemCell.slider.onValueChanged:Invoke(initValue)
        end
    end
    if not string.isEmpty(iconOnClickFunction) and iconListLength > 0 then
        itemCell.sliderIconButton.onClick:AddListener(function()
            self[iconOnClickFunction](self, settingId)
        end)
    end
    itemCell.slider.audioSlide = self.m_originalAudioSlide
    self:_InitSliderItemController(itemCell.controllerNode, itemCell.slider)
end
GameSettingCtrl._InitButtonSettingItem = HL.Method(HL.Table, HL.Any) << function(self, itemCell, itemData)
    itemCell.buttonText.text = UIUtils.resolveTextStyle(itemData.buttonText)
    local clickFunctionName = self:_GetSettingFunctionName(itemData.buttonOnClickFunction)
    if not string.isEmpty(clickFunctionName) then
        itemCell.button.onClick:RemoveAllListeners()
        itemCell.button.onClick:AddListener(function()
            self[clickFunctionName](self)
        end)
    end
    self:_InitButtonItemController(itemCell.controllerNode, function()
        self[clickFunctionName](self)
    end)
end
GameSettingCtrl._InitToggleSettingItem = HL.Method(HL.Table, HL.Any) << function(self, itemCell, itemData)
    local settingId = itemData.settingId
    local getFunctionName = self:_GetSettingFunctionName(itemData.toggleValueGetFunction)
    local setFunctionName = self:_GetSettingFunctionName(itemData.toggleValueSetFunction)
    local initialValue = false
    if GameSettingHelper.IsQualitySubSetting(settingId) then
        initialValue = self:_ToggleGetQualitySubSettingValue(settingId)
    else
        if not string.isEmpty(getFunctionName) then
            initialValue = self[getFunctionName](self, settingId)
        end
    end
    itemCell.toggle:InitCommonToggle(function(isOn)
        if GameSettingHelper.IsQualitySubSetting(settingId) then
            initialValue = self:_ToggleSetQualitySubSettingValue(settingId, isOn)
        else
            if not string.isEmpty(setFunctionName) then
                self[setFunctionName](self, settingId, isOn)
            end
        end
    end, initialValue, true)
end
GameSettingCtrl._GetSettingFunctionName = HL.Method(HL.String).Return(HL.String) << function(self, functionName)
    if not string.isEmpty(functionName) then
        functionName = "_" .. functionName
    end
    return functionName
end
GameSettingCtrl._DropdownAdjustExpandDirection = HL.Method(HL.Any, HL.Any) << function(self, cell, originalCell)
    originalCell.rectTransform:SetSiblingIndex(originalCell.rectTransform.parent.childCount - 1)
    local screenPosition = self.uiCamera:WorldToScreenPoint(cell.rectTransform.position)
    local isInUpperHalf = screenPosition.y > Screen.height / 2.0
    local listRect = cell.dropDownListRectTransform
    local listMask = cell.dropDownListMask
    local listLayout = cell.dropDownListContentLayout
    listRect.pivot = isInUpperHalf and Vector2(0.5, 1.0) or Vector2(0.5, 0)
    listRect.anchorMin = isInUpperHalf and Vector2(0, 1.0) or Vector2(0, 0)
    listRect.anchorMax = isInUpperHalf and Vector2(1.0, 1.0) or Vector2(1.0, 0)
    listRect.anchoredPosition = Vector2.zero
    local maskPadding = listMask.padding
    maskPadding.w = isInUpperHalf and self.m_originalPadding or 0
    maskPadding.y = isInUpperHalf and 0 or self.m_originalPadding
    listMask.padding = maskPadding
    cell.topMask.gameObject:SetActive(not isInUpperHalf)
    cell.bottomMask.gameObject:SetActive(isInUpperHalf)
    local needReverse = false
    if isInUpperHalf then
        if listLayout.padding.top < listLayout.padding.bottom then
            needReverse = true
        end
    else
        if listLayout.padding.top > listLayout.padding.bottom then
            needReverse = true
        end
    end
    if needReverse then
        local top = listLayout.padding.top
        listLayout.padding.top = listLayout.padding.bottom
        listLayout.padding.bottom = top
    end
end
GameSettingCtrl._DropdownGetOptionIndex = HL.Method(HL.String).Return(HL.Number) << function(self, settingId)
    local success, value = GameSetting.GameSettingGetInt(settingId)
    if success then
        return value
    end
    logger.error("GameSetting: 在打开界面时尝试获取一个尚未存在的设置项数值", settingId)
    return 1
end
GameSettingCtrl._DropdownGetIndexVideoResolution = HL.Method(HL.String).Return(HL.Number) << function(self, settingId)
    local resolutionList = GameSetting.GameSettingScreenResolution.availableGameSettingScreenResolutionList
    local currentResolution = GameSetting.videoResolution
    for i = 0, resolutionList.Count - 1 do
        local resolution = resolutionList[i]
        if resolution.height <= currentResolution.height and resolution.width <= currentResolution.width then
            return i + 1
        end
    end
    return 1
end
GameSettingCtrl._DropdownGetVideoMainQualityTextList = HL.Method(HL.Any).Return(HL.Table) << function(self, itemData)
    local qualityTextList = {}
    local optionTextData = itemData.dropdownOptionTextList
    if optionTextData ~= nil then
        local defaultQualityIndex = GameSettingHelper.GetDefaultVideoQualityIndex()
        for i = 0, optionTextData.length - 1 do
            if not string.isEmpty(optionTextData[i]) then
                local text = UIUtils.resolveTextStyle(optionTextData[i])
                if i == defaultQualityIndex then
                    table.insert(qualityTextList, string.format(Language[DROPDOWN_MAIN_QUALITY_DEFAULT_TEXT_ID], text))
                else
                    table.insert(qualityTextList, text)
                end
            end
        end
    end
    return qualityTextList
end
GameSettingCtrl._DropdownGetVideoResolutionTextList = HL.Method(HL.Any).Return(HL.Table) << function(self, itemData)
    local resolutionList = GameSetting.GameSettingScreenResolution.availableGameSettingScreenResolutionList
    local resolutionTextList = {}
    for i = 0, resolutionList.Count - 1 do
        local resolution = resolutionList[i]
        if resolution.isFullScreen then
            table.insert(resolutionTextList, string.format(Language[DROPDOWN_FULL_SCREEN_RESOLUTION_TEXT_ID], resolution.width, resolution.height))
        else
            table.insert(resolutionTextList, string.format(Language[DROPDOWN_WINDOWED_RESOLUTION_TEXT_ID], resolution.width, resolution.height))
        end
    end
    return resolutionTextList
end
GameSettingCtrl._DropdownOnSelectVideoFrameRate = HL.Method(HL.String, HL.Number) << function(self, settingId, index)
    GameSettingSetter.graphicsFrameRate:Set(index)
end
GameSettingCtrl._DropdownOnSelectVideoRenderScale = HL.Method(HL.String, HL.Number) << function(self, settingId, index)
    GameSettingSetter.graphicsRenderScale:Set(index)
end
GameSettingCtrl._DropdownOnSelectVideoResolution = HL.Method(HL.String, HL.Number) << function(self, settingId, index)
    local listIndex = index - 1
    local resolutionList = GameSetting.GameSettingScreenResolution.availableGameSettingScreenResolutionList
    if listIndex < 0 or listIndex >= resolutionList.Count then
        return
    end
    local resolution = resolutionList[listIndex]
    if resolution.width <= 0 or resolution.height <= 0 then
        return
    end
    GameSettingSetter.graphicsResolution:Set(resolution.width, resolution.height)
    self:_ResetVideoRenderScaleAfterQualityOrResolution(GameSettingHelper.GetQualityIndex(), resolution.width)
end
GameSettingCtrl._DropdownOnSelectLanguageText = HL.Method(HL.String, HL.Number) << function(self, settingId, index)
    local lastIndex = CSIndex(self:_DropdownGetOptionIndex(settingId))
    local dropdown = self.m_itemCellMap[settingId].dropdown
    Notify(MessageConst.SHOW_POP_UP, {
        content = Language[LANGUAGE_TEXT_POP_UP_CONTENT_TEXT_ID],
        warningContent = Language[LANGUAGE_POP_UP_WARNING_TEXT_ID],
        freezeWorld = true,
        hideBlur = true,
        onConfirm = function()
            GameSettingSetter.languageText:Set(index)
            CSUtils.QuitGame(0)
        end,
        onCancel = function()
            if dropdown ~= nil then
                dropdown:SetSelected(lastIndex, false, false)
            end
        end
    })
end
GameSettingCtrl._DropdownOnSelectLanguageAudio = HL.Method(HL.String, HL.Number) << function(self, settingId, index)
    local lastIndex = CSIndex(self:_DropdownGetOptionIndex(settingId))
    local dropdown = self.m_itemCellMap[settingId].dropdown
    Notify(MessageConst.SHOW_POP_UP, {
        content = Language[LANGUAGE_AUDIO_POP_UP_CONTENT_TEXT_ID],
        warningContent = Language[LANGUAGE_POP_UP_WARNING_TEXT_ID],
        freezeWorld = true,
        hideBlur = true,
        onConfirm = function()
            GameSettingSetter.languageAudio:Set(index)
            CSUtils.QuitGame(0)
        end,
        onCancel = function()
            if dropdown ~= nil then
                dropdown:SetSelected(lastIndex, false, false)
            end
        end
    })
end
GameSettingCtrl._DropdownOnSelectAudioSuiteMode = HL.Method(HL.String, HL.Number) << function(self, settingId, index)
    GameSettingSetter.audioSuiteMode:Set(index)
end
GameSettingCtrl._SliderRefreshText = HL.Method(HL.Any, HL.Number) << function(self, sliderItemCell, value)
    local valueText = ""
    if sliderItemCell.slider.wholeNumbers then
        valueText = string.format("%d", math.floor(value + 0.5))
    else
        valueText = string.format("%.1f", value)
    end
    sliderItemCell.sliderValueText.text = valueText
end
GameSettingCtrl._SliderGetValue = HL.Method(HL.String).Return(HL.Number) << function(self, settingId)
    local success, value = GameSetting.GameSettingGetFloat(settingId)
    if success then
        return value
    end
    logger.error("GameSetting: 在打开界面时尝试获取一个尚未存在的设置项数值", settingId)
    return 0
end
GameSettingCtrl._SliderGetIcon = HL.Method(HL.Number, HL.Any, HL.Any).Return(HL.Any) << function(self, value, iconList, rangeList)
    local listLength = math.min(#iconList, #rangeList)
    if listLength == 0 then
        return nil
    end
    for i = 0, listLength - 1 do
        if value <= rangeList[i] then
            return self:LoadSprite(UIConst.UI_SPRITE_GAME_SETTING, iconList[i])
        end
    end
    return self:LoadSprite(UIConst.UI_SPRITE_GAME_SETTING, iconList[listLength - 1])
end
GameSettingCtrl._SliderRecordValue = HL.Method(HL.String, HL.Number) << function(self, settingId, value)
    local sliderValueData = self.m_sliderValueDataMap[settingId]
    if sliderValueData == nil then
        return
    end
    sliderValueData.currValue = value
    if value > sliderValueData.minValue then
        sliderValueData.lastValidValue = value
    end
end
GameSettingCtrl._SliderOnAudioIconClicked = HL.Method(HL.String) << function(self, settingId)
    local valueData = self.m_sliderValueDataMap[settingId]
    if valueData == nil then
        return
    end
    local slider = self.m_itemCellMap[settingId].slider
    if valueData.currValue > valueData.minValue then
        slider.value = valueData.minValue
    else
        local nextValue = valueData.lastValidValue == nil and valueData.maxValue or valueData.lastValidValue
        slider.value = nextValue
    end
end
GameSettingCtrl._SliderGetGlobalVolume = HL.Method(HL.String).Return(HL.Number) << function(self, settingId)
    return VOLUME_COEFFICIENT * self:_SliderGetValue(settingId)
end
GameSettingCtrl._SliderGetVoiceVolume = HL.Method(HL.String).Return(HL.Number) << function(self, settingId)
    return VOLUME_COEFFICIENT * self:_SliderGetValue(settingId)
end
GameSettingCtrl._SliderGetMusicVolume = HL.Method(HL.String).Return(HL.Number) << function(self, settingId)
    return VOLUME_COEFFICIENT * self:_SliderGetValue(settingId)
end
GameSettingCtrl._SliderGetSfxVolume = HL.Method(HL.String).Return(HL.Number) << function(self, settingId)
    return VOLUME_COEFFICIENT * self:_SliderGetValue(settingId)
end
GameSettingCtrl._SliderGetCameraSpeedX = HL.Method(HL.String).Return(HL.Number) << function(self, settingId)
    return self:_SliderGetValue(settingId)
end
GameSettingCtrl._SliderGetCameraSpeedY = HL.Method(HL.String).Return(HL.Number) << function(self, settingId)
    return self:_SliderGetValue(settingId)
end
GameSettingCtrl._SliderGetCameraTopViewSpeed = HL.Method(HL.String).Return(HL.Number) << function(self, settingId)
    return self:_SliderGetValue(settingId)
end
GameSettingCtrl._SliderSetGlobalVolume = HL.Method(HL.String, HL.Number) << function(self, settingId, value)
    local systemValue = value / VOLUME_COEFFICIENT
    GameSettingSetter.audioGlobalVolume:Set(systemValue)
end
GameSettingCtrl._SliderSetVoiceVolume = HL.Method(HL.String, HL.Number) << function(self, settingId, value)
    local systemValue = value / VOLUME_COEFFICIENT
    GameSettingSetter.audioVoiceVolume:Set(systemValue)
end
GameSettingCtrl._SliderSetMusicVolume = HL.Method(HL.String, HL.Number) << function(self, settingId, value)
    local systemValue = value / VOLUME_COEFFICIENT
    GameSettingSetter.audioMusicVolume:Set(systemValue)
end
GameSettingCtrl._SliderSetSfxVolume = HL.Method(HL.String, HL.Number) << function(self, settingId, value)
    local systemValue = value / VOLUME_COEFFICIENT
    GameSettingSetter.audioSfxVolume:Set(systemValue)
end
GameSettingCtrl._SliderSetCameraSpeedX = HL.Method(HL.String, HL.Number) << function(self, settingId, value)
    GameSettingSetter.controllerCameraSpeedX:Set(value)
end
GameSettingCtrl._SliderSetCameraSpeedY = HL.Method(HL.String, HL.Number) << function(self, settingId, value)
    GameSettingSetter.controllerCameraSpeedY:Set(value)
end
GameSettingCtrl._SliderSetCameraTopViewSpeed = HL.Method(HL.String, HL.Number) << function(self, settingId, value)
    GameSettingSetter.controllerCameraTopViewSpeed:Set(value)
end
GameSettingCtrl._SliderOnGlobalVolumeIconClicked = HL.Method(HL.String) << function(self, settingId)
    self:_SliderOnAudioIconClicked(settingId)
end
GameSettingCtrl._SliderOnVoiceVolumeIconClicked = HL.Method(HL.String) << function(self, settingId)
    self:_SliderOnAudioIconClicked(settingId)
end
GameSettingCtrl._SliderOnMusicVolumeIconClicked = HL.Method(HL.String) << function(self, settingId)
    self:_SliderOnAudioIconClicked(settingId)
end
GameSettingCtrl._SliderOnSfxVolumeIconClicked = HL.Method(HL.String) << function(self, settingId)
    self:_SliderOnAudioIconClicked(settingId)
end
GameSettingCtrl._ButtonGetAccountCenterState = HL.Method().Return(HL.Table) << function(self)
end
GameSettingCtrl._ButtonOnAccountCenterClick = HL.Method() << function(self)
    CSUtils.OpenAccountCenter()
end
GameSettingCtrl._ButtonGetCustomerServiceCenterState = HL.Method().Return(HL.Table) << function(self)
end
GameSettingCtrl._ButtonOnCustomerServiceCenterClick = HL.Method() << function(self)
    CS.Beyond.Gameplay.AnnouncementSystem.OpenCustomService()
end
GameSettingCtrl._ToggleGetValue = HL.Method(HL.String).Return(HL.Boolean) << function(self, settingId)
    local success, value = GameSetting.GameSettingGetBool(settingId)
    if success then
        return value
    end
    logger.error("GameSetting: 在打开界面时尝试获取一个尚未存在的设置项数值", settingId)
    return false
end
GameSettingCtrl._ToggleGetSuspendUnfocused = HL.Method(HL.String).Return(HL.Boolean) << function(self, settingId)
    return self:_ToggleGetValue(settingId)
end
GameSettingCtrl._ToggleGetCameraReverseX = HL.Method(HL.String).Return(HL.Boolean) << function(self, settingId)
    return self:_ToggleGetValue(settingId)
end
GameSettingCtrl._ToggleGetCameraReverseY = HL.Method(HL.String).Return(HL.Boolean) << function(self, settingId)
    return self:_ToggleGetValue(settingId)
end
GameSettingCtrl._ToggleSetSuspendUnfocused = HL.Method(HL.String, HL.Boolean) << function(self, settingId, value)
    GameSettingSetter.audioSuspendUnfocused:Set(value)
end
GameSettingCtrl._ToggleSetCameraReverseX = HL.Method(HL.String, HL.Boolean) << function(self, settingId, value)
    GameSettingSetter.controllerCameraReverseX:Set(value)
end
GameSettingCtrl._ToggleSetCameraReverseY = HL.Method(HL.String, HL.Boolean) << function(self, settingId, value)
    GameSettingSetter.controllerCameraReverseY:Set(value)
end
GameSettingCtrl._DropdownOnSelectVideoQuality = HL.Method(HL.String, HL.Number) << function(self, settingId, index)
    local lastIndex = self:_DropdownGetIndexVideoQuality(settingId)
    local dropdown = self.m_itemCellMap[settingId].dropdown
    if index == CUSTOM_QUALITY_SETTING_INDEX then
        GameSettingHelper.SetQualityCustomState(true)
    else
        local qualityIndex = index - 1
        if GameSettingHelper.IsValidQualityIndex(qualityIndex) then
            GameSettingHelper.SetQualityCustomState(false)
            GameSettingSetter.graphicsQuality:Set(qualityIndex)
            self:_UpdateAndRefreshQualitySubSettingsState()
            local currentResolution = GameSetting.videoResolution
            self:_ResetVideoRenderScaleAfterQualityOrResolution(qualityIndex, currentResolution.width)
        else
            Notify(MessageConst.SHOW_POP_UP, {
                content = Language[LANGUAGE_QUALITY_POP_UP_CONTENT_TEXT_ID],
                freezeWorld = true,
                hideBlur = true,
                hideCancel = true,
                onConfirm = function()
                    if dropdown ~= nil then
                        dropdown:SetSelected(CSIndex(lastIndex), false, false)
                    end
                end
            })
        end
    end
end
GameSettingCtrl._ResetVideoRenderScaleAfterQualityOrResolution = HL.Method(HL.Number, HL.Number) << function(self, qualityIndex, currWidth)
    local resolutionWidth = GameSettingHelper.GetSettingResolutionWidthByQuality(qualityIndex)
    local renderScale = GameSettingHelper.GetRenderScaleByMaxWidthAndCurrentWidth(resolutionWidth, currWidth)
    local settingRenderScale = GameSettingHelper.GetGameSettingRenderScaleByRenderScale(renderScale)
    local renderScaleIndex = settingRenderScale:GetHashCode()
    local renderScaleId = GameSetting.ID_VIDEO_RENDER_SCALE
    local renderScaleCell = self.m_itemCellMap[renderScaleId]
    if renderScaleCell ~= nil and renderScaleCell.dropdown ~= nil then
        renderScaleCell.dropdown:SetSelected(CSIndex(renderScaleIndex), false, false)
    end
    GameSettingSetter.graphicsRenderScale:Set(renderScaleIndex)
end
GameSettingCtrl._DropdownGetIndexVideoQuality = HL.Method(HL.String).Return(HL.Number) << function(self, settingId)
    if GameSettingHelper.GetQualityCustomState() then
        return CUSTOM_QUALITY_SETTING_INDEX
    else
        return GameSettingHelper.GetQualityIndex() + 1
    end
end
GameSettingCtrl._UpdateAndRefreshQualitySubSettingsState = HL.Method() << function(self)
    for settingId, subSettingData in pairs(self.m_qualitySubSettingDataMap) do
        local success, subSettingTableData = Tables.qualitySubSettingTable:TryGetValue(settingId)
        if success and not subSettingTableData.ignoreMainChange then
            GameSetting.RemoveGameSettingSaveValue(settingId)
            local itemCell = subSettingData.itemCell
            local itemType = subSettingData.itemType
            if itemType == GEnums.SettingItemType.Dropdown then
                local index = self:_DropdownGetQualitySubSettingOptionIndex(settingId)
                itemCell.dropdown:SetSelected(CSIndex(index), false, false)
            elseif itemType == GEnums.SettingItemType.Toggle then
                local value = self:_ToggleGetQualitySubSettingValue(settingId)
                itemCell.toggle:SetValue(value, true)
            end
        end
    end
end
GameSettingCtrl._DropdownGetQualitySubSettingOptionIndex = HL.Method(HL.String).Return(HL.Number) << function(self, settingId)
    return GameSettingHelper.GetQualitySubSettingTierBySettingId(settingId)
end
GameSettingCtrl._DropdownSetQualitySubSettingOptionIndex = HL.Method(HL.String, HL.Number) << function(self, settingId, index)
    local qualityCell = self.m_itemCellMap[QUALITY_SETTING_ID]
    if qualityCell ~= nil and qualityCell.dropdown ~= nil then
        qualityCell.dropdown:SetSelected(0, false, false)
    end
    GameSettingHelper.SetQualityCustomState(true)
    GameSettingHelper.SetQualitySubSettingTierBySettingId(settingId, index)
end
GameSettingCtrl._ToggleGetQualitySubSettingValue = HL.Method(HL.String).Return(HL.Boolean) << function(self, settingId)
    return GameSettingHelper.GetQualitySubSettingTierBySettingId(settingId) > 0
end
GameSettingCtrl._ToggleSetQualitySubSettingValue = HL.Method(HL.String, HL.Boolean) << function(self, settingId, value)
    local qualityCell = self.m_itemCellMap[QUALITY_SETTING_ID]
    if qualityCell ~= nil and qualityCell.dropdown ~= nil then
        qualityCell.dropdown:SetSelected(0, false, false)
    end
    GameSettingHelper.SetQualityCustomState(true)
    GameSettingHelper.SetQualitySubSettingTierBySettingId(settingId, value and 1 or 0)
end
GameSettingCtrl.m_navigationSelectedTabIndex = HL.Field(HL.Number) << 1
GameSettingCtrl.m_navigationSelectedItemIndex = HL.Field(HL.Number) << 1
GameSettingCtrl.m_topTabCells = HL.Field(HL.Forward('UIListCache'))
GameSettingCtrl._InitGameSettingTopTabs = HL.Method() << function(self)
    local tabNode = self.view.tabs
    if tabNode == nil then
        return
    end
    self.m_topTabCells = UIUtils.genCellCache(tabNode.tabCell)
    local tabConfig = { { tabName = "setting", tabIcon = "setting_tab_setting", tabTitleTextId = "LUA_GAME_SETTING_BASIC_TITLE", activeNode = self.view.settingListNode, }, { tabName = "controllerHint", tabIcon = "setting_tab_controller_hint", tabTitleTextId = "LUA_GAME_SETTING_CONTROLLER_TITLE", activeNode = self.view.controllerHintNode, }, }
    self.m_topTabCells:Refresh(#tabConfig, function(cell, index)
        local configInfo = tabConfig[index]
        cell.gameObject.name = "Tab-" .. configInfo.tabName
        local tabIconSprite = self:LoadSprite(UIConst.UI_SPRITE_GAME_SETTING, configInfo.tabIcon)
        if tabIconSprite ~= nil then
            cell.defaultIcon.sprite = tabIconSprite
            cell.selectedIcon.sprite = tabIconSprite
        end
        cell.toggle.onValueChanged:RemoveAllListeners()
        cell.toggle.onValueChanged:AddListener(function(isOn)
            configInfo.activeNode.gameObject:SetActive(isOn)
            self.view.listTitleText.text = Language[configInfo.tabTitleTextId]
        end)
        cell.toggle.isOn = index == 1
    end)
end
GameSettingCtrl._InitGameSettingController = HL.Method() << function(self)
    if not DeviceInfo.usingController then
        return
    end
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
GameSettingCtrl._InitControllerHintBinding = HL.Method() << function(self)
    self.view.controllerHintNode.leftButton.onClick:AddListener(function()
        self:_RefreshControllerHintContent(false)
    end)
    self.view.controllerHintNode.rightButton.onClick:AddListener(function()
        self:_RefreshControllerHintContent(true)
    end)
    self:_RefreshControllerHintContent(false)
end
GameSettingCtrl._InitSettingItemControllerNavigation = HL.Method() << function(self)
    UIUtils.bindInputPlayerAction("common_navigation_up", function()
        self:_NavigateSettingItem(true)
    end, self.view.settingListBindingGroup.groupId)
    UIUtils.bindInputPlayerAction("common_navigation_down", function()
        self:_NavigateSettingItem(false)
    end, self.view.settingListBindingGroup.groupId)
    self.m_navigationSelectedTabIndex = 1
    self.m_navigationSelectedItemIndex = 0
end
GameSettingCtrl._InitDropDownItemController = HL.Method(HL.Table, HL.Userdata, HL.Userdata) << function(self, controllerNode, dropDownNode, dropDownRectTransform)
    if not DeviceInfo.usingController then
        return
    end
    if controllerNode == nil or dropDownNode == nil then
        return
    end
    controllerNode.dropDownSetting.gameObject:SetActive(true)
    controllerNode.dropDownOpenBtn.onClick:AddListener(function()
        dropDownNode:ToggleOptions(true)
    end)
    controllerNode.dropDownOpenBtn.clickHintTextId = "virtual_mouse_hint_select"
    dropDownNode.onToggleOptList:AddListener(function(active)
        if active then
            Notify(MessageConst.SHOW_AS_CONTROLLER_SMALL_MENU, { panelId = PANEL_ID, isGroup = true, id = dropDownNode.groupId, hintPlaceholder = self.view.controllerHintPlaceholder, rectTransform = dropDownRectTransform, })
        else
            Notify(MessageConst.CLOSE_CONTROLLER_SMALL_MENU, PANEL_ID)
        end
    end)
end
GameSettingCtrl._InitSliderItemController = HL.Method(HL.Table, HL.Userdata) << function(self, controllerNode, sliderNode)
    if not DeviceInfo.usingController then
        return
    end
    if controllerNode == nil or sliderNode == nil then
        return
    end
    controllerNode.sliderSetting.gameObject:SetActive(true)
    controllerNode.sliderAddBtn.onClick:AddListener(function()
        sliderNode.value = sliderNode.value + (sliderNode.maxValue - sliderNode.minValue) / 10
        sliderNode.value = math.min(sliderNode.value, sliderNode.maxValue)
    end)
    controllerNode.sliderReduceBtn.onClick:AddListener(function()
        sliderNode.value = sliderNode.value - (sliderNode.maxValue - sliderNode.minValue) / 10
        sliderNode.value = math.max(sliderNode.value, sliderNode.minValue)
    end)
end
GameSettingCtrl._InitButtonItemController = HL.Method(HL.Table, HL.Function) << function(self, controllerNode, buttonClickFunction)
    if not DeviceInfo.usingController then
        return
    end
    if controllerNode == nil or buttonClickFunction == nil then
        return
    end
    controllerNode.buttonSetting.gameObject:SetActive(true)
    controllerNode.buttonClickBtn.onClick:AddListener(function()
        buttonClickFunction()
    end)
    controllerNode.buttonClickBtn.clickHintTextId = "virtual_mouse_hint_view"
end
GameSettingCtrl._NavigateSettingItem = HL.Method(HL.Boolean) << function(self, isUp)
    if self.m_itemCellsList == nil then
        return
    end
    local lastTabIndex, lastItemIndex = self.m_navigationSelectedTabIndex, self.m_navigationSelectedItemIndex
    local tabCount = #self.m_itemCellsList
    local tabItemCount = self.m_itemCellsList[self.m_navigationSelectedTabIndex]:GetCount()
    local changeValue = isUp and -1 or 1
    local nextItemIndex = self.m_navigationSelectedItemIndex + changeValue
    if nextItemIndex == 0 then
        if self.m_navigationSelectedTabIndex > 1 then
            self.m_navigationSelectedTabIndex = self.m_navigationSelectedTabIndex - 1
            self.m_navigationSelectedItemIndex = self.m_itemCellsList[self.m_navigationSelectedTabIndex]:GetCount()
        end
    elseif nextItemIndex > tabItemCount then
        if self.m_navigationSelectedTabIndex < tabCount then
            self.m_navigationSelectedTabIndex = self.m_navigationSelectedTabIndex + 1
            self.m_navigationSelectedItemIndex = 1
        end
    else
        self.m_navigationSelectedItemIndex = nextItemIndex
    end
    if lastTabIndex == self.m_navigationSelectedTabIndex and lastItemIndex == self.m_navigationSelectedItemIndex then
        return
    end
    local cell = self.m_itemCellsList[self.m_navigationSelectedTabIndex]:Get(self.m_navigationSelectedItemIndex)
    if cell ~= nil then
        InputManagerInst:MoveVirtualMouseTo(cell.rectTransform, self.uiCamera)
        cell.controllerNode.controllerSelectedBg.gameObject:SetActive(true)
    end
    local lastCell = self.m_itemCellsList[lastTabIndex]:Get(lastItemIndex)
    if lastCell ~= nil then
        lastCell.controllerNode.controllerSelectedBg.gameObject:SetActive(false)
    end
    if not UIUtils.isPosInScreen(cell.transform.position, self.uiCamera, 0, 100) then
        local scrollX = self.view.scrollView.content.anchoredPosition.x
        local scrollY = self.view.scrollView.content.anchoredPosition.y
        self.view.scrollView:ScrollTo(Vector2(scrollX, scrollY + cell.rectTransform.rect.height * changeValue))
    end
end
GameSettingCtrl._RefreshControllerHintContent = HL.Method(HL.Boolean) << function(self, isInFactoryMode)
    local controllerHintNode = self.view.controllerHintNode
    if controllerHintNode == nil then
        return
    end
    controllerHintNode.explorationIndexToggle.isOn = not isInFactoryMode
    controllerHintNode.factoryIndexToggle.isOn = isInFactoryMode
    controllerHintNode.leftButton.interactable = isInFactoryMode
    controllerHintNode.rightButton.interactable = not isInFactoryMode
    local titleTextId = isInFactoryMode and "LUA_GAME_SETTING_CONTROLLER_FACTORY_HINT" or "LUA_GAME_SETTING_CONTROLLER_EXPLORATION_HINT"
    controllerHintNode.titleText.text = Language[titleTextId]
    local animationName = isInFactoryMode and "gamesetting_controller_nextpage_out" or "gamesetting_controller_nextpage_in"
    controllerHintNode.animationWrapper:PlayWithTween(animationName)
end
HL.Commit(GameSettingCtrl)