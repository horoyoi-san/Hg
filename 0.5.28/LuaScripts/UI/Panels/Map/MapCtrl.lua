local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local MapSpaceshipNode = require_ex('UI/Widgets/MapSpaceshipNode')
local PANEL_ID = PanelId.Map
local PHASE_ID = PhaseId.Map
MapCtrl = HL.Class('MapCtrl', uiCtrl.UICtrl)
local COLLECTIONS_CONFIG = { ["chest"] = { viewName = "chest", mergeId = "item_cate_chest", hoverTextId = "ui_mappanel_collection_trchest", }, ["coin"] = { viewName = "coin", mergeId = "int_collection_coin", hoverTextId = "ui_mappanel_collection_coin", }, ["piece"] = { viewName = "piece", mergeId = "int_collection_piece", hoverTextId = "ui_mappanel_collection_puzzle", }, ["blackbox"] = { viewName = "blackbox", useCustomGetter = true, hoverTextId = "ui_mappanel_collection_blackbox", }, }
local COLLECTION_COUNT_TEXT_FORMAT = "%d/%d"
local BUILDING_INFOS_CONFIG = {
    ["bandwidth"] = {
        viewName = "bandwidth",
        getter = function(sceneInfo)
            return sceneInfo.bandwidth.current, sceneInfo.bandwidth.max
        end,
        hoverTextId = "ui_mappanel_collection_bandwidth",
    },
    ["travelPole"] = {
        viewName = "travelPole",
        getter = function(sceneInfo)
            return sceneInfo.bandwidth.travelPoleCurrent, sceneInfo.bandwidth.travelPoleMax
        end,
        hoverTextId = "ui_mappanel_collection_pole",
    },
    ["battleBuilding"] = {
        viewName = "battleBuilding",
        getter = function(sceneInfo)
            return sceneInfo.bandwidth.battleCurrent, sceneInfo.bandwidth.battleMax
        end,
        hoverTextId = "ui_mappanel_collection_battle",
    }
}
local BUILDING_INFO_NUM_TEXT_FORMAT = "%d/%d"
local TITLE_FORMAT_TEXT_ID = "LUA_MAP_TITLE"
local INITIAL_SELECT_OPTION_INDEX = 1
MapCtrl.m_initialLevelId = HL.Field(HL.String) << ""
MapCtrl.m_currLevelId = HL.Field(HL.String) << ""
MapCtrl.m_selectMarkRectTransform = HL.Field(Unity.RectTransform)
MapCtrl.m_isMarkDetailShowing = HL.Field(HL.Boolean) << false
MapCtrl.m_zoomTick = HL.Field(HL.Number) << -1
MapCtrl.m_zoomVisibleLayer = HL.Field(HL.Number) << -1
MapCtrl.m_controllerRect = HL.Field(Unity.RectTransform)
MapCtrl.m_selectOptionCells = HL.Field(HL.Forward('UIListCache'))
MapCtrl.m_selectNodeTick = HL.Field(HL.Number) << -1
MapCtrl.m_waitShowInitDetail = HL.Field(HL.Boolean) << false
MapCtrl.m_selectOptionMarkList = HL.Field(HL.Table)
MapCtrl.m_currHighlightOption = HL.Field(HL.Number) << -1
MapCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SCENE_GRADE_CHANGE_NOTIFY] = '_OnSceneGradeChangeNotify', [MessageConst.ON_LEVEL_MAP_MARK_CLICKED] = '_OnLevelMapMarkClicked', [MessageConst.ON_TRACKING_MAP_MARK] = '_OnTrackingMapMarkChanged', [MessageConst.ON_TELEPORT_FINISH] = '_OnTeleportFinish', [MessageConst.ON_MAP_FILTER_STATE_CHANGED] = '_RefreshFilterBtnState', [MessageConst.ON_SYSTEM_UNLOCK] = '_OnSystemUnlock', }
MapCtrl.OnCreate = HL.Override(HL.Any) << function(self, args)
    self.m_controllerRect = self.view.levelMapController.view.rectTransform
    self:_InitCloseButton()
    self:_InitFilterButton()
    self:_InitBuildingAndCollectionHoverButton()
    args = args or {}
    local markInstId, levelId = args.instId, args.levelId
    local needShowDetail = not string.isEmpty(markInstId)
    if needShowDetail then
        levelId = GameInstance.player.mapManager:GetMarkInstRuntimeDataLevelId(markInstId)
    end
    self.m_waitShowInitDetail = needShowDetail
    self.m_initialLevelId = not string.isEmpty(levelId) and levelId or GameInstance.world.curLevelId
    if not DataManager.uiLevelMapConfig.levelConfigInfos:ContainsKey(self.m_initialLevelId) then
        return
    end
    self:_InitLevelMapController()
    self:_InitBigRectHelper()
    self:_InitZoomNode(needShowDetail)
    self:_InitRegionMapButton()
    self:_InitSelectOptionList()
    self:_InitWalletBar()
    self:_RefreshLevelMapContent()
    self:_TryPlayMapMaskAnimation()
    self:_InitPlayerIcon(not needShowDetail)
    if needShowDetail then
        self:_ShowMarkDetail(markInstId, true)
        self.m_waitShowInitDetail = false
    end
    if args.needTransit == nil then
        args.needTransit = false
    end
    self.view.transitBlack.gameObject:SetActive(args.needTransit)
    if BEYOND_DEBUG_COMMAND then
        self:_InitDebugTeleport()
    end
end
MapCtrl.OnClose = HL.Override() << function(self)
    self.m_selectNodeTick = LuaUpdate:Remove(self.m_selectNodeTick)
    self.m_zoomTick = LuaUpdate:Remove(self.m_zoomTick)
    self:_StopPlayerIconLimit()
end
MapCtrl._OnTeleportFinish = HL.Method() << function(self)
    MapSpaceshipNode.ClearStaticFromData()
    Notify(MessageConst.RECOVER_PHASE_LEVEL)
end
MapCtrl._RefreshTitle = HL.Method(HL.String) << function(self, levelId)
    local levelBasicSuccess, levelBasicInfo = DataManager.levelBasicInfoTable:TryGetValue(levelId)
    if not levelBasicSuccess then
        return
    end
    local success, levelDesc = Tables.levelDescTable:TryGetValue(levelId)
    if not success then
        return
    end
    local configSuccess, levelConfig = DataManager.uiLevelMapConfig.levelConfigInfos:TryGetValue(levelId)
    if not configSuccess then
        return
    end
    local domainId = levelBasicInfo.domainName
    local domainSuccess, domainData = Tables.domainDataTable:TryGetValue(domainId)
    if domainSuccess and not levelConfig.isSingleLevel then
        self.view.titleNode.titleText.text = string.format(Language[TITLE_FORMAT_TEXT_ID], domainData.domainName, levelDesc.showName)
    else
        self.view.titleNode.titleText.text = levelDesc.showName
    end
end
MapCtrl._InitLevelMapController = HL.Method() << function(self)
    self.view.levelMapController:InitLevelMapController(MapConst.LEVEL_MAP_CONTROLLER_MODE.LEVEL_SWITCH, {
        onLevelSwitch = function(targetInfo)
            self:_OnLevelSwitch(targetInfo)
        end,
        onLevelSwitchStart = function(targetInfo)
            self:_OnLevelSwitchStart(targetInfo)
        end,
        onLevelSwitchFinish = function()
            self:_OnLevelSwitchFinish()
        end,
        onTrackingMarkClicked = function(instId, trackingMark, relatedMark)
            self:_OnTrackingMarkClicked(instId, trackingMark, relatedMark)
        end,
        initialLevelId = self.m_initialLevelId,
        visibleRect = self.view.markVisibleRect
    })
end
MapCtrl._OnLevelSwitch = HL.Method(HL.Table) << function(self, switchTargetInfo)
    self:_SetMapRectByTargetLevelInfo(switchTargetInfo)
end
MapCtrl._OnLevelSwitchStart = HL.Method(HL.Table) << function(self, switchTargetInfo)
    self.view.fullScreenMask.gameObject:SetActive(true)
    self.view.bigRectHelper.enabled = false
    self.view.touchPanel.enabled = false
    self.m_controllerRect:SetParent(self.view.mapMask)
    self:_SetMapRectByTargetLevelInfo(switchTargetInfo)
    self:_StopPlayerIconLimit()
    self:_PlayBottomInfoNodeAnimation(false)
    self:_PlayRightZoomNodeAnimation(false)
    self:_PlayTopNodeAnimation(false)
    self:_PlayTrackingNodeAnimation(false)
    if self.m_isMarkDetailShowing then
        PhaseManager:PopPhase(PhaseId.MapMarkDetail)
    end
end
MapCtrl._OnLevelSwitchFinish = HL.Method() << function(self)
    self.view.fullScreenMask.gameObject:SetActive(false)
    self.view.touchPanel.enabled = true
    self.m_controllerRect:SetParent(self.view.mapRect)
    self:_RefreshLevelMapContent()
    self:_ResetBigRectHelper()
    self:_ResetZoomSliderValue(false)
    self:_RefreshPlayerIconNeedLimit()
    self:_PlayBottomInfoNodeAnimation(true)
    self:_PlayRightZoomNodeAnimation(true)
    self:_PlayTrackingNodeAnimation(true)
    self:_PlayTopNodeAnimation(true)
end
MapCtrl._SetMapRectByTargetLevelInfo = HL.Method(HL.Table) << function(self, targetInfo)
    self.view.mapRect.pivot = Vector2(0.5, 1.0)
    local resetPos = self:_GetTargetRelativeCenterPosition(self.view.mapRect, { scale = targetInfo.scale, width = targetInfo.size.x, height = targetInfo.size.y, })
    self.view.mapRect.sizeDelta = targetInfo.size
    self.view.mapRect.localScale = Vector3.one * targetInfo.scale
    self.view.mapRect.anchoredPosition = resetPos + targetInfo.initialOffset
end
MapCtrl._RefreshLevelMapContent = HL.Method() << function(self)
    local currLevelId = self.view.levelMapController:GetControllerCurrentLevelId()
    self:_RefreshTitle(currLevelId)
    self:_RefreshBuildingInfos(currLevelId)
    self:_RefreshCollectionsInfo(currLevelId)
    self:_RefreshGradeNode(currLevelId)
    self:_RefreshTrackingInfo(currLevelId)
    self:_RefreshSpaceshipNode(currLevelId)
    self:_RefreshZoomNodeVisibleState(currLevelId)
    self:_RefreshBottomInfoVisibleState(currLevelId)
    self.m_currLevelId = currLevelId
    CS.Beyond.Gameplay.Conditions.OnUILevelMapEnterLevel.Trigger(currLevelId)
end
MapCtrl._GetTargetRelativeCenterPosition = HL.Method(Unity.RectTransform, HL.Table).Return(Vector2) << function(self, rectTransform, targetInfo)
    local parentRectTransform = rectTransform.parent:GetComponent("RectTransform")
    if parentRectTransform == nil then
        return
    end
    local anchorOffset = Vector2(parentRectTransform.rect.width * (0.5 - rectTransform.anchorMin.x), parentRectTransform.rect.height * (0.5 - rectTransform.anchorMin.y))
    local pivotOffset = Vector2(targetInfo.scale * targetInfo.width * (rectTransform.pivot.x - 0.5), targetInfo.scale * targetInfo.height * (rectTransform.pivot.y - 0.5));
    return anchorOffset + pivotOffset
end
MapCtrl._OnLevelMapMarkClicked = HL.Method(HL.Any) << function(self, args)
    local markInstId = unpack(args)
    local nearbyMarkList = self.view.levelMapController:GetControllerNearbyMarkList(markInstId, self.view.config.NEARBY_MARK_DISTANCE, self.view.zoomNode.zoomSlider.value)
    if #nearbyMarkList <= 1 then
        self:_ShowMarkDetail(markInstId)
    else
        self:_RefreshSelectOptionList(markInstId, nearbyMarkList)
    end
end
MapCtrl._ShowMarkDetail = HL.Method(HL.String, HL.Opt(HL.Boolean)) << function(self, markInstId, needFocus)
    local markRectTransform = self.view.levelMapController:GetControllerMarkRectTransform(markInstId)
    if markRectTransform == nil then
        return
    end
    if needFocus then
        self.view.bigRectHelper:FocusNode(markRectTransform, false)
    end
    if not self.m_isMarkDetailShowing then
        self.view.selectIcon.gameObject:SetActive(true)
        self.m_selectNodeTick = LuaUpdate:Add("Tick", function(deltaTime)
            self.view.selectIcon.position = self.m_selectMarkRectTransform.position
        end)
    end
    local markVisible = markRectTransform.gameObject.activeSelf
    if not markVisible then
        markRectTransform.gameObject:SetActive(true)
    end
    Notify(MessageConst.SHOW_LEVEL_MAP_MARK_DETAIL, {
        markInstId = markInstId,
        onClosedCallback = function()
            self.view.selectIcon.gameObject:SetActive(false)
            self.m_selectNodeTick = LuaUpdate:Remove(self.m_selectNodeTick)
            self.m_isMarkDetailShowing = false
            if not markVisible then
                markRectTransform.gameObject:SetActive(false)
            end
        end
    })
    self.m_selectMarkRectTransform = markRectTransform
    self.m_isMarkDetailShowing = true
end
MapCtrl._InitSelectOptionList = HL.Method() << function(self)
    self.m_selectOptionCells = UIUtils.genCellCache(self.view.selectOptionNode.selectOptionCell)
    self.view.selectOptionNode.button.onClick:AddListener(function()
        self:_RefreshSelectOptionListShownState(false)
    end)
    self.view.selectOptionNode.gameObject:SetActive(false)
end
MapCtrl._RefreshSelectOptionList = HL.Method(HL.String, HL.Table) << function(self, markInstId, nearbyMarkList)
    local markRectTransform = self.view.levelMapController:GetControllerMarkRectTransform(markInstId)
    if markRectTransform == nil then
        return
    end
    self.m_selectOptionMarkList = {}
    self.m_selectOptionCells:Refresh(#nearbyMarkList, function(cell, index)
        local nearbyInstId = nearbyMarkList[index]
        local runtimeSuccess, markRuntimeData = GameInstance.player.mapManager:GetMarkInstRuntimeData(nearbyInstId)
        if not runtimeSuccess then
            return
        end
        local templateId = markRuntimeData.templateId
        local templateSuccess, templateData = Tables.mapMarkTempTable:TryGetValue(templateId)
        if not templateSuccess then
            return
        end
        local icon = markRuntimeData.isActive and templateData.detailActiveIcon or templateData.detailInactiveIcon
        local iconSprite = self:LoadSprite(UIConst.UI_SPRITE_MAP_ICON, icon)
        if iconSprite ~= nil then
            cell.icon.sprite = iconSprite
        end
        if markRuntimeData.missionInfo ~= nil and markRuntimeData.isMissionTracking then
            cell.icon.color = GameInstance.player.mission:GetMissionColor(markRuntimeData.missionInfo.missionId)
        else
            cell.icon.color = Color.white
        end
        cell.name.text = templateData.name
        cell.button.onClick:RemoveAllListeners()
        cell.button.onClick:AddListener(function()
            self:_ShowMarkDetail(nearbyInstId)
            self:_RefreshSelectOptionListShownState(false)
        end)
        cell.button.onHoverChange:RemoveAllListeners()
        cell.button.onHoverChange:AddListener(function(isHover)
            if index == self.m_currHighlightOption then
                return
            end
            if isHover then
                local lastCell = self.m_selectOptionCells:GetItem(self.m_currHighlightOption)
                self:_RefreshSelectOptionHighlightState(lastCell, self.m_currHighlightOption, false)
                self:_RefreshSelectOptionHighlightState(cell, index, true)
                self.m_currHighlightOption = index
            end
        end)
        self.m_selectOptionMarkList[index] = self.view.levelMapController:GetControllerMarkByInstId(nearbyInstId)
        if index == INITIAL_SELECT_OPTION_INDEX then
            self:_RefreshSelectOptionHighlightState(cell, index, true)
            self.m_currHighlightOption = index
        else
            self:_RefreshSelectOptionHighlightState(cell, index, false)
        end
    end)
    self.view.bigSelectIcon.position = markRectTransform.position
    self:_RefreshSelectOptionListShownState(true)
end
MapCtrl._RefreshSelectOptionListShownState = HL.Method(HL.Boolean) << function(self, isShown)
    self.view.bigSelectIcon.gameObject:SetActiveIfNecessary(isShown)
    self.view.selectOptionNode.gameObject:SetActiveIfNecessary(isShown)
    if not isShown and self.m_selectOptionMarkList ~= nil then
        for _, mark in pairs(self.m_selectOptionMarkList) do
            mark.levelMapMark:SwitchMarkHighlightState(false)
        end
    end
end
MapCtrl._RefreshSelectOptionHighlightState = HL.Method(HL.Any, HL.Number, HL.Boolean) << function(self, cell, index, isHighlight)
    local animName = isHighlight and "select_item_selected" or "select_item_normal"
    cell.contentAnimation:PlayWithTween(animName)
    local mark = self.m_selectOptionMarkList[index]
    if mark ~= nil then
        mark.levelMapMark:SwitchMarkHighlightState(isHighlight)
        self.view.bigSelectIcon.position = mark.rectTransform.position
    end
end
MapCtrl._InitBigRectHelper = HL.Method() << function(self)
    self.view.bigRectHelper:SetZoomRangeMax(self.view.levelMapController:GetControllerCurrentMaxScale())
    self.view.bigRectHelper:OverrideZoomRangeMin(self.view.levelMapController:GetControllerCurrentMinScale())
    self.view.bigRectHelper:Init()
    self.view.touchPanel.onZoom:AddListener(function(zoomVal)
        self:_RefreshZoomValue()
    end)
end
MapCtrl._ResetBigRectHelper = HL.Method() << function(self)
    self.view.bigRectHelper.enabled = true
    self.view.bigRectHelper:SetZoomRangeMax(self.view.levelMapController:GetControllerCurrentMaxScale())
    self.view.bigRectHelper:OverrideZoomRangeMin(self.view.levelMapController:GetControllerCurrentMinScale())
    self.view.bigRectHelper:Init()
end
MapCtrl._InitZoomNode = HL.Method(HL.Boolean) << function(self, useMaxValueInit)
    local zoomNode = self.view.zoomNode
    zoomNode.zoomSlider.onValueChanged:AddListener(function(value)
        self:_OnZoomValueChanged(value)
    end)
    zoomNode.addButton.onPressEnd:AddListener(function()
        self:_ChangeZoomValue(true, self.view.config.CLICK_DELTA)
    end)
    zoomNode.reduceButton.onPressEnd:AddListener(function()
        self:_ChangeZoomValue(false, self.view.config.CLICK_DELTA)
    end)
    self:_ResetZoomSliderValue(useMaxValueInit)
end
MapCtrl._RefreshZoomNodeVisibleState = HL.Method(HL.String) << function(self, levelId)
    local success, levelConfig = DataManager.uiLevelMapConfig.levelConfigInfos:TryGetValue(levelId)
    if not success then
        return
    end
    self.view.zoomNode.gameObject:SetActive(not levelConfig.isSingleLevel)
end
MapCtrl._ResetZoomSliderValue = HL.Method(HL.Boolean) << function(self, useMaxValue)
    local zoomSlider = self.view.zoomNode.zoomSlider
    zoomSlider.minValue = self.view.levelMapController:GetControllerCurrentMinScale()
    zoomSlider.maxValue = self.view.levelMapController:GetControllerCurrentMaxScale()
    local initValue = useMaxValue and zoomSlider.maxValue or zoomSlider.minValue
    zoomSlider.value = initValue
    self:_RefreshZoomVisibleLayer(initValue, true)
end
MapCtrl._RefreshZoomValue = HL.Method() << function(self)
    local current = self.view.bigRectHelper:GetCurrentZoomValue()
    self.view.zoomNode.zoomSlider:SetValueWithoutNotify(current)
    self:_RefreshZoomButtonInteractableState()
    self:_RefreshZoomVisibleLayer(current)
end
MapCtrl._ChangeZoomValue = HL.Method(HL.Boolean, HL.Number) << function(self, isAdd, deltaPercent)
    local zoomSlider = self.view.zoomNode.zoomSlider
    local current = zoomSlider.value
    local min, max = zoomSlider.minValue, zoomSlider.maxValue
    local changeValue = (max - min) * deltaPercent / 100.0
    local targetValue = isAdd and current + changeValue or current - changeValue
    targetValue = lume.clamp(targetValue, min, max)
    if targetValue == current then
        return
    end
    zoomSlider.value = targetValue
end
MapCtrl._StartTickChangZoomValue = HL.Method(HL.Boolean) << function(self, isAdd)
    if self.m_zoomTick > 0 then
        self.m_zoomTick = LuaUpdate:Remove(self.m_zoomTick)
    end
    self.m_zoomTick = LuaUpdate:Add("Tick", function(deltaTime)
        self:_ChangeZoomValue(isAdd, self.view.config.PRESS_DELTA)
    end)
end
MapCtrl._StopTickChangZoomValue = HL.Method() << function(self)
    if self.m_zoomTick > 0 then
        self.m_zoomTick = LuaUpdate:Remove(self.m_zoomTick)
    end
end
MapCtrl._OnZoomValueChanged = HL.Method(HL.Number) << function(self, value)
    self.view.bigRectHelper:ResetPivotPositionToScreenCenter()
    self.view.bigRectHelper:SyncZoomValue(value, not self.m_waitShowInitDetail)
    self:_RefreshZoomButtonInteractableState()
    self:_RefreshZoomVisibleLayer(value)
end
MapCtrl._RefreshZoomButtonInteractableState = HL.Method() << function(self)
    local zoomNode = self.view.zoomNode
    local zoomSlider = zoomNode.zoomSlider
    local value = zoomSlider.value
    local min, max = zoomSlider.minValue, zoomSlider.maxValue
    if value <= min then
        if zoomNode.reduceButton.interactable then
            zoomNode.reduceButton.interactable = false
            self:_StopTickChangZoomValue()
        end
    else
        if not zoomNode.reduceButton.interactable then
            zoomNode.reduceButton.interactable = true
        end
    end
    if value >= max then
        if zoomNode.addButton.interactable then
            zoomNode.addButton.interactable = false
            self:_StopTickChangZoomValue()
        end
    else
        if not zoomNode.addButton.interactable then
            zoomNode.addButton.interactable = true
        end
    end
end
MapCtrl._RefreshZoomVisibleLayer = HL.Method(HL.Number, HL.Opt(HL.Boolean)) << function(self, scaleValue, forceRefresh)
    local layer = DataManager.uiLevelMapConfig:GetVisibleLayerByScale(scaleValue)
    if layer == self.m_zoomVisibleLayer and not forceRefresh then
        return
    end
    self.view.levelMapController:RefreshLoaderMarksVisibleStateByLayer(layer)
    self.m_zoomVisibleLayer = layer
end
MapCtrl._InitBuildingAndCollectionHoverButton = HL.Method() << function(self)
    for _, buildingInfo in pairs(BUILDING_INFOS_CONFIG) do
        local viewNode = self.view.infoNode[buildingInfo.viewName]
        if viewNode ~= nil then
            viewNode.button.onHoverChange:AddListener(function(isHover)
                if isHover then
                    Notify(MessageConst.SHOW_COMMON_HOVER_TIP, { mainText = Language[buildingInfo.hoverTextId], delay = self.view.config.BOTTOM_TIP_HOVER_DELAY, })
                else
                    Notify(MessageConst.HIDE_COMMON_HOVER_TIP)
                end
            end)
        end
    end
    for _, collectionInfo in pairs(COLLECTIONS_CONFIG) do
        local viewNode = self.view.infoNode[collectionInfo.viewName]
        if viewNode ~= nil then
            viewNode.button.onHoverChange:RemoveAllListeners()
            viewNode.button.onHoverChange:AddListener(function(isHover)
                if isHover then
                    Notify(MessageConst.SHOW_COMMON_HOVER_TIP, { mainText = Language[collectionInfo.hoverTextId], delay = self.view.config.BOTTOM_TIP_HOVER_DELAY, })
                else
                    Notify(MessageConst.HIDE_COMMON_HOVER_TIP)
                end
            end)
        end
    end
end
MapCtrl._RefreshBuildingInfos = HL.Method(HL.String) << function(self, levelId)
    local sceneInfo = GameInstance.remoteFactoryManager.system.core:GetSceneInfoByName(levelId);
    for _, buildingInfo in pairs(BUILDING_INFOS_CONFIG) do
        local viewNode = self.view.infoNode[buildingInfo.viewName]
        if viewNode ~= nil then
            viewNode.numText.text = string.format(BUILDING_INFO_NUM_TEXT_FORMAT, 0, 0)
            if sceneInfo ~= nil then
                local curr, max = buildingInfo.getter(sceneInfo)
                if max > 0 then
                    viewNode.numText.text = string.format(BUILDING_INFO_NUM_TEXT_FORMAT, curr, max)
                end
            end
        end
    end
end
MapCtrl._RefreshCollectionsInfo = HL.Method(HL.String) << function(self, levelId)
    local collectionManager = GameInstance.player.collectionManager
    for collectionCfgId, collectionInfo in pairs(COLLECTIONS_CONFIG) do
        local viewNode = self.view.infoNode[collectionInfo.viewName]
        if viewNode ~= nil then
            local curr, total = 0, 0
            if collectionInfo.useCustomGetter then
                if collectionCfgId == "blackbox" then
                    curr, total = self:_CustomGetBlackboxCurrAndTotalCount(levelId)
                end
            else
                total, curr = collectionManager:GetMergeItemCnt(collectionInfo.mergeId, levelId)
            end
            if total > 0 then
                viewNode.countText.text = string.format(COLLECTION_COUNT_TEXT_FORMAT, curr, total)
                viewNode.fillImage.fillAmount = curr / total
                viewNode.gameObject:SetActive(true)
            else
                viewNode.gameObject:SetActive(false)
            end
        end
    end
end
MapCtrl._CustomGetBlackboxCurrAndTotalCount = HL.Method(HL.String).Return(HL.Number, HL.Number) << function(self, levelId)
    local levelSuccess, levelBasicInfo = DataManager.levelBasicInfoTable:TryGetValue(levelId)
    if not levelSuccess then
        return 0, 0
    end
    local domainName = levelBasicInfo.domainName
    local domainSuccess, domainData = Tables.domainDataTable:TryGetValue(domainName)
    if not domainSuccess then
        return 0, 0
    end
    local facTechPackageId = domainData.facTechPackageId
    local facSTTSuccess, facSTTGroupData = Tables.facSTTGroupTable:TryGetValue(facTechPackageId)
    if not facSTTSuccess then
        return 0, 0
    end
    local blackboxIds = facSTTGroupData.blackboxIds
    local curr, total = 0, 0
    for _, blackboxId in pairs(blackboxIds) do
        local dungeonSuccess, dungeonData = Tables.dungeonTable:TryGetValue(blackboxId)
        if dungeonSuccess then
            local dungeonLevelId = dungeonData.levelId
            if dungeonLevelId == levelId then
                total = total + 1
                if GameInstance.dungeonManager:IsDungeonActive(blackboxId) then
                    curr = curr + 1
                end
            end
        end
    end
    return curr, total
end
MapCtrl._RefreshGradeNode = HL.Method(HL.String) << function(self, levelId)
    local isSpaceshipLevelId = levelId == Tables.spaceshipConst.baseSceneName
    self.view.gradeNode.gameObject:SetActive(not isSpaceshipLevelId)
    self.view.lvDotNode.gameObject:SetActive(isSpaceshipLevelId)
    if isSpaceshipLevelId then
        local _, roomInfo = GameInstance.player.spaceship:TryGetRoom(Tables.spaceshipConst.controlCenterRoomId)
        local roomTypeData = Tables.spaceshipRoomTypeTable[roomInfo.roomType]
        self.view.lvDotNode:InitLvDotNode(roomInfo.lv, roomInfo.maxLv, UIUtils.getColorByString(roomTypeData.color))
    else
        local isUnlocked = GameInstance.player.mapManager:IsSceneGradeChangeUnlocked(levelId)
        local isOnCD = GameInstance.player.mapManager:IsSceneGradeModifyOnCoolDown(levelId)
        self.view.gradeNode.timeIcon.gameObject:SetActive(isUnlocked and isOnCD)
        self.view.gradeNode.lockIcon.gameObject:SetActive(not isUnlocked)
        self.view.gradeNode.normalIcon.gameObject:SetActive(isUnlocked and not isOnCD)
        self.view.gradeNode.redDot:InitRedDot("SceneGrade", levelId)
        if isUnlocked and not GameInstance.player.mapManager:IsLevelRead(levelId) then
            self.view.topNodeAnimWrapper:PlayInAnimation()
            GameInstance.player.mapManager:SendLevelReadMessage(levelId)
        end
        self.view.gradeNode.txtGrade.text = UIConst.SCENE_GRADE_TEXT[GameInstance.player.mapManager:GetSceneGrade(levelId)]
        self.view.gradeNode.btnGrade.onClick:RemoveAllListeners()
        self.view.gradeNode.btnGrade.onClick:AddListener(function()
            if not isUnlocked then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_SCENE_GRADE_LOCKED_TIPS)
                return
            end
            local args = { levelId = levelId, }
            PhaseManager:OpenPhase(PhaseId.SceneGrade, args)
        end)
    end
end
MapCtrl._OnSceneGradeChangeNotify = HL.Method(HL.Table) << function(self, args)
    self:_RefreshGradeNode(self.m_currLevelId)
end
MapCtrl._InitRegionMapButton = HL.Method() << function(self)
    self.view.regionMapBtn.onClick:AddListener(function()
        MapUtils.switchFromLevelMapToRegionMap(self.m_currLevelId)
    end)
end
MapCtrl._RefreshTrackingInfo = HL.Method(HL.String) << function(self, levelId)
    self.view.mapTrackingInfo:InitMapTrackingInfo({ levelId = levelId })
end
MapCtrl._OnTrackingMapMarkChanged = HL.Method(HL.Any) << function(self)
    if not self.m_isMarkDetailShowing then
        return
    end
    Notify(MessageConst.HIDE_LEVEL_MAP_MARK_DETAIL)
end
MapCtrl._OnTrackingMarkClicked = HL.Method(HL.String, HL.Any, HL.Any) << function(self, instId, trackingMark, relatedMark)
    if trackingMark.levelMapLimitInRect.isLimitedInRect then
        local levelId = GameInstance.player.mapManager:GetMarkInstRuntimeDataLevelId(instId)
        if levelId == self.m_currLevelId then
            self.view.bigRectHelper:FocusNode(relatedMark.rectTransform, true, function()
                self:_ShowMarkDetail(instId)
            end)
        else
            self:ResetMapStateToTargetLevel({ instId = instId, levelId = levelId })
        end
    else
        self:_OnLevelMapMarkClicked({ instId })
    end
end
MapCtrl._InitPlayerIcon = HL.Method(HL.Boolean) << function(self, needFocus)
    local playerNode = self.view.levelMapController.view.levelMapLoader.view.player
    if self.m_initialLevelId == GameInstance.world.curLevelId then
        self:_StartPlayerIconLimit()
        if playerNode.gameObject.activeSelf and needFocus then
            self.view.bigRectHelper:FocusNode(playerNode.rectTransform, false)
        end
    end
    playerNode.playerBtn.onClick:AddListener(function()
        if playerNode.levelMapLimitInRect.isLimitedInRect then
            self.view.bigRectHelper:FocusNode(playerNode.rectTransform, true)
        end
    end)
end
MapCtrl._RefreshPlayerIconNeedLimit = HL.Method() << function(self)
    if self.m_currLevelId == GameInstance.world.curLevelId then
        self:_StartPlayerIconLimit()
    else
        self:_StopPlayerIconLimit()
    end
end
MapCtrl._StartPlayerIconLimit = HL.Method() << function(self)
    local playerNode = self.view.levelMapController.view.levelMapLoader.view.player
    playerNode.levelMapLimitInRect:StartLimitMarkInRect()
end
MapCtrl._StopPlayerIconLimit = HL.Method() << function(self)
    local playerNode = self.view.levelMapController.view.levelMapLoader.view.player
    playerNode.levelMapLimitInRect:StopLimitMarkInRect()
end
MapCtrl._RefreshSpaceshipNode = HL.Method(HL.String) << function(self, levelId)
    self.view.mapSpaceshipNode:InitMapSpaceshipNode({ levelId = levelId })
end
MapCtrl._InitCloseButton = HL.Method() << function(self)
    self.view.closeBtn.onClick:AddListener(function()
        self:_CloseMap()
    end)
    self:BindInputPlayerAction("map_close", function()
        self:_CloseMap()
    end)
end
MapCtrl._CloseMap = HL.Method() << function(self)
    MapSpaceshipNode.ClearStaticFromData()
    MapUtils.closeMapRelatedPhase()
end
MapCtrl._InitFilterButton = HL.Method() << function(self)
    self.view.filterBtn.button.onClick:AddListener(function()
        Notify(MessageConst.SHOW_LEVEL_MAP_FILTER)
    end)
    self:_RefreshFilterBtnState()
end
MapCtrl._RefreshFilterBtnState = HL.Method() << function(self)
    local isFilterValid = GameInstance.player.mapManager:IsFilterValid()
    self.view.filterBtn.existNode.gameObject:SetActive(isFilterValid)
    self.view.filterBtn.normalNode.gameObject:SetActive(not isFilterValid)
end
MapCtrl._InitWalletBar = HL.Method() << function(self)
    self.view.walletBarPlaceholder:InitWalletBarPlaceholder(UIConst.REGION_MAP_STAMINA_IDS)
    self:_RefreshWalletNodeVisibleState()
end
MapCtrl._OnSystemUnlock = HL.Method(HL.Table) << function(self, args)
    local systemIndex = unpack(args)
    if systemIndex == GEnums.UnlockSystemType.Dungeon:GetHashCode() then
        self:_RefreshWalletNodeVisibleState()
    end
end
MapCtrl._RefreshWalletNodeVisibleState = HL.Method() << function(self)
    self.view.walletBarPlaceholder.gameObject:SetActive(Utils.isSystemUnlocked(GEnums.UnlockSystemType.Dungeon))
end
MapCtrl._TryPlayMapMaskAnimation = HL.Method() << function(self)
    if self.m_waitShowInitDetail then
        return
    end
    self.view.mapMaskAnimWrapper:PlayWithTween("map_masklevelmapcontroller_in")
end
MapCtrl._PlayBottomInfoNodeAnimation = HL.Method(HL.Boolean) << function(self, isIn)
    local animName = isIn and "map_mainui_bottominfo_in" or "map_mainui_bottominfo_out"
    self.view.infoNode.animationWrapper:PlayWithTween(animName)
end
MapCtrl._PlayRightZoomNodeAnimation = HL.Method(HL.Boolean) << function(self, isIn)
    local animName = isIn and "map_mainui_rightzoom_in" or "map_mainui_rightzoom_out"
    self.view.rightAnim:PlayWithTween(animName)
end
MapCtrl._PlayRightSpaceshipNodeAnimation = HL.Method(HL.Boolean) << function(self, isIn)
    local animName = isIn and "map_mainui_rightssnode_in" or "map_mainui_rightssnode_out"
    self.view.rightAnim:PlayWithTween(animName)
end
MapCtrl._PlayTopNodeAnimation = HL.Method(HL.Boolean) << function(self, isIn)
    local animName = isIn and "map_mainui_topnode_in" or "map_mainui_topnode_out"
    self.view.topAnim:PlayWithTween(animName)
end
MapCtrl._PlayMapResetAnimation = HL.Method(HL.Boolean, HL.Opt(HL.Function)) << function(self, isIn, callback)
    local animName = isIn and "map_mask_switch_in" or "map_mask_switch_out"
    self.view.mapMaskAnimWrapper:PlayWithTween(animName, callback)
end
MapCtrl._PlayTrackingNodeAnimation = HL.Method(HL.Boolean, HL.Opt(HL.Function)) << function(self, isIn, callback)
    local animName = isIn and "map_trackinginfo_in" or "map_trackinginfo_out"
    self.view.leftAnim:PlayWithTween(animName, callback)
end
MapCtrl._PlayFilterBtnAnimation = HL.Method(HL.Boolean, HL.Opt(HL.Function)) << function(self, isIn, callback)
    local animName = isIn and "map_mainui_filterbtn_in" or "map_mainui_filterbtn_out"
    self.view.leftAnim:PlayWithTween(animName, callback)
end
MapCtrl.ResetMapStateToTargetLevel = HL.Method(HL.Table) << function(self, args)
    local instId, levelId = args.instId, args.levelId
    local needShowDetail = not string.isEmpty(instId)
    if needShowDetail then
        levelId = GameInstance.player.mapManager:GetMarkInstRuntimeDataLevelId(instId)
    end
    self.m_waitShowInitDetail = needShowDetail
    if self.m_isMarkDetailShowing then
        Notify(MessageConst.HIDE_LEVEL_MAP_MARK_DETAIL)
    end
    self.view.bigRectHelper.enabled = false
    self.view.touchPanel.enabled = false
    self.view.fullScreenMask.gameObject:SetActive(true)
    self:_PlayBottomInfoNodeAnimation(false)
    self:_PlayRightZoomNodeAnimation(false)
    self:_PlayRightSpaceshipNodeAnimation(false)
    self:_PlayTopNodeAnimation(false)
    self:_PlayTrackingNodeAnimation(false)
    self:_PlayFilterBtnAnimation(false)
    self:_PlayMapResetAnimation(false, function()
        self.view.fullScreenMask.gameObject:SetActive(false)
        self.view.levelMapController:ResetSwitchModeToTargetLevelState(levelId)
        self:_ResetBigRectHelper()
        self.view.touchPanel.enabled = true
        self:_RefreshLevelMapContent()
        self:_ResetZoomSliderValue(needShowDetail)
        if needShowDetail then
            self:_ShowMarkDetail(instId, true)
            self.m_waitShowInitDetail = false
        end
        self:_PlayTopNodeAnimation(true)
        self:_PlayMapResetAnimation(true)
        self:_PlayBottomInfoNodeAnimation(true)
        self:_PlayRightZoomNodeAnimation(true)
        self:_PlayRightSpaceshipNodeAnimation(true)
        self:_PlayTrackingNodeAnimation(true)
        self:_PlayFilterBtnAnimation(true)
    end)
end
MapCtrl._RefreshBottomInfoVisibleState = HL.Method(HL.String) << function(self, levelId)
    local configSuccess, levelConfig = DataManager.uiLevelMapConfig.levelConfigInfos:TryGetValue(levelId)
    if not configSuccess then
        return
    end
    self.view.infoNode.gameObject:SetActive(not levelConfig.isSingleLevel)
    self.view.filterBtn.gameObject:SetActive(not levelConfig.isSingleLevel)
end
if BEYOND_DEBUG_COMMAND then
    MapCtrl._InitDebugTeleport = HL.Method() << function(self)
        self.view.touchPanel.onClick:AddListener(function(eventData)
            if not self.view.debugToggle.isOn then
                return
            end
            self:_DebugTeleport(eventData.position)
        end)
        self.view.touchPanel.onRightClick:AddListener(function(eventData)
            if not InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.LeftAlt) then
                return
            end
            self:_DebugTeleport(eventData.position)
        end)
        self.view.debugToggle.gameObject:SetActive(true)
    end
    MapCtrl._DebugTeleport = HL.Method(HL.Any) << function(self, position)
        local rectPos = UIUtils.screenPointToUI(position, self.uiCamera, self.view.levelMapController.view.levelMapLoader.view.rectTransform)
        local worldPos = self.view.levelMapController.view.levelMapLoader:GetWorldPositionByRectPosition(rectPos)
        worldPos.y = worldPos.y + 150.0
        Utils.teleportToPosition(self.m_currLevelId, worldPos, Quaternion.Euler(0, 0, 0))
    end
end
HL.Commit(MapCtrl)