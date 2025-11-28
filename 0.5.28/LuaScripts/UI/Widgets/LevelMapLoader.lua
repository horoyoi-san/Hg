local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
local LuaNodeCache = require_ex('Common/Utils/LuaNodeCache')
local UILevelMapUtils = CS.Beyond.UI.UILevelMapUtils
local ElementType = CS.Beyond.Gameplay.UILevelMapStaticElementType
local LineType = CS.Beyond.Gameplay.FacMarkLineType
LevelMapLoader = HL.Class('LevelMapLoader', UIWidgetBase)
local LOADER_DEFAULT_UPDATE_INTERVAL = 0.2
local MIN_MARK_ORDER = 1
local MAX_MARK_ORDER = 5
local MARK_ORDER_VIEW_NAME_FORMAT = "order%d"
local MARK_GAME_OBJECT_NAME_FORMAT = "MarkInst_%s"
LevelMapLoader.m_mapManager = HL.Field(CS.Beyond.Gameplay.MapManager)
LevelMapLoader.m_levelMapConfig = HL.Field(CS.Beyond.Gameplay.UILevelMapConfig)
LevelMapLoader.m_dataUpdateInterval = HL.Field(HL.Number) << LOADER_DEFAULT_UPDATE_INTERVAL
LevelMapLoader.m_dataUpdateTick = HL.Field(HL.Number) << -1
LevelMapLoader.m_rootUpdateTick = HL.Field(HL.Number) << -1
LevelMapLoader.m_mapId = HL.Field(HL.String) << ""
LevelMapLoader.m_levelId = HL.Field(HL.String) << ""
LevelMapLoader.m_gridCache = HL.Field(LuaNodeCache)
LevelMapLoader.m_gridSpriteCache = HL.Field(HL.Table)
LevelMapLoader.m_markCache = HL.Field(HL.Table)
LevelMapLoader.m_viewBound = HL.Field(HL.Table)
LevelMapLoader.m_posTween = HL.Field(HL.Userdata)
LevelMapLoader.m_sizeTween = HL.Field(HL.Userdata)
LevelMapLoader.m_buildLevels = HL.Field(HL.Table)
LevelMapLoader.m_onMarkInstDataChangedCallback = HL.Field(HL.Function)
LevelMapLoader.m_markStaticDataMap = HL.Field(HL.Table)
LevelMapLoader.m_viewSingleData = HL.Field(HL.Table)
LevelMapLoader.m_hideOtherLevels = HL.Field(HL.Boolean) << false
LevelMapLoader.m_hidePlayer = HL.Field(HL.Boolean) << false
LevelMapLoader.m_needUpdate = HL.Field(HL.Boolean) << true
LevelMapLoader.m_useSingleViewData = HL.Field(HL.Boolean) << false
LevelMapLoader.m_needDelayUpdateAll = HL.Field(HL.Boolean) << false
LevelMapLoader.m_levelBounds = HL.Field(HL.Table)
LevelMapLoader.m_levelGrids = HL.Field(HL.Table)
LevelMapLoader.m_gridGetter = HL.Field(HL.Table)
LevelMapLoader.m_hitLevels = HL.Field(HL.Table)
LevelMapLoader.m_hitGrids = HL.Field(HL.Table)
LevelMapLoader.m_loadedGrids = HL.Field(HL.Table)
LevelMapLoader.m_loadedPosition = HL.Field(HL.Table)
LevelMapLoader.m_duplicateGrids = HL.Field(HL.Table)
LevelMapLoader.m_needInverseCache = HL.Field(HL.Table)
LevelMapLoader.m_staticElementInitializer = HL.Field(HL.Table)
LevelMapLoader.m_lineCaches = HL.Field(HL.Table)
LevelMapLoader.m_lineRoots = HL.Field(HL.Table)
LevelMapLoader.m_loadedLines = HL.Field(HL.Table)
LevelMapLoader.m_buildElementsLevels = HL.Field(HL.Table)
LevelMapLoader.m_loadedStaticElements = HL.Field(HL.Table)
LevelMapLoader.m_loadedStaticElementInitializerMap = HL.Field(HL.Table)
LevelMapLoader.m_loadedMarks = HL.Field(HL.Table)
LevelMapLoader.m_loadedMarkViewDataMap = HL.Field(HL.Table)
LevelMapLoader.m_needRefreshPlayer = HL.Field(HL.Boolean) << true
LevelMapLoader.m_characterData = HL.Field(HL.Table)
LevelMapLoader.m_missionTrackingMarkCache = HL.Field(LuaNodeCache)
LevelMapLoader.m_missionTrackingAreaCache = HL.Field(LuaNodeCache)
LevelMapLoader.m_loadedMissionTrackingMarks = HL.Field(HL.Table)
LevelMapLoader.m_loadedMissionTrackingAreas = HL.Field(HL.Table)
LevelMapLoader.m_gameplayAreaCache = HL.Field(LuaNodeCache)
LevelMapLoader.m_loadedGameplayAreas = HL.Field(HL.Table)
LevelMapLoader.m_gridRectLength = HL.Field(HL.Number) << -1
LevelMapLoader.m_gridWorldLength = HL.Field(HL.Number) << -1
LevelMapLoader._OnFirstTimeInit = HL.Override() << function(self)
    self:RegisterMessage(MessageConst.ON_MAP_POWER_LINE_CHANGED, function()
        self:_RefreshPowerLines()
    end)
    self:RegisterMessage(MessageConst.ON_MAP_TRAVEL_LINE_CHANGED, function()
        self:_RefreshTravelLines()
    end)
    self:RegisterMessage(MessageConst.ON_MAP_MARK_RUNTIME_DATA_CHANGED, function(args)
        local instId, isAdd = unpack(args)
        self:_OnMarkInstDataChangedCallback(instId, isAdd)
    end)
    self:RegisterMessage(MessageConst.ON_MAP_GAMEPLAY_AREA_ADDED, function(args)
        local areaId = unpack(args)
        self:_RefreshGameplayArea(areaId, true)
    end)
    self:RegisterMessage(MessageConst.ON_MAP_GAMEPLAY_AREA_REMOVED, function(args)
        local areaId = unpack(args)
        self:_RefreshGameplayArea(areaId, false)
    end)
end
LevelMapLoader._OnDestroy = HL.Override() << function(self)
    self.m_dataUpdateTick = LuaUpdate:Remove(self.m_dataUpdateTick)
    self.m_rootUpdateTick = LuaUpdate:Remove(self.m_rootUpdateTick)
end
LevelMapLoader.InitLevelMapLoader = HL.Method(HL.String, HL.Opt(HL.Table)) << function(self, levelId, customInfo)
    if string.isEmpty(levelId) then
        return
    end
    local success, levelConfig = DataManager.levelConfigTable:TryGetData(levelId)
    if not success then
        return
    end
    self.m_mapManager = GameInstance.player.mapManager
    self.m_levelMapConfig = DataManager.uiLevelMapConfig
    self.m_mapId = levelConfig.mapIdStr
    self.m_levelId = levelId
    self:_InitTableFields()
    customInfo = customInfo or {}
    self.m_hideOtherLevels = customInfo.hideOtherLevels or false
    self.m_hidePlayer = customInfo.hidePlayer or false
    self.m_useSingleViewData = customInfo.useSingleViewData or false
    self.m_needDelayUpdateAll = customInfo.needDelayUpdateAll or false
    self.m_needUpdate = true
    if customInfo.needUpdate ~= nil then
        self.m_needUpdate = customInfo.needUpdate
    end
    if self.m_useSingleViewData then
        self.m_viewSingleData = {}
        self.m_viewSingleData.posX = 0
        self.m_viewSingleData.posY = 0
        self.m_viewSingleData.width = self.view.viewRect.rect.width
        self.m_viewSingleData.height = self.view.viewRect.rect.height
    end
    self:_InitMarkStaticDataMap()
    self:_InitLoaderCache()
    self:_InitStaticElementInitializer()
    self.m_gridRectLength = self.m_levelMapConfig.gridRectLength
    self.view.grid.rectTransform.sizeDelta = Vector2(self.m_gridRectLength, self.m_gridRectLength)
    self.m_gridWorldLength = self.m_levelMapConfig.gridWorldLength
    self:_InitLevelData()
    self:_InitLoaderUpdateThread()
    self:_InitLinesInCurrentMap()
    self:_InitPermanentElementsInCurrentMap()
    self:_FirstTimeInit()
end
LevelMapLoader._InitTableFields = HL.Method(HL.Opt(HL.Boolean)) << function(self, ignoreGlobal)
    self.m_viewBound = {}
    self.m_buildLevels = {}
    self.m_levelBounds = {}
    self.m_levelGrids = {}
    self.m_gridGetter = {}
    self.m_hitLevels = {}
    self.m_hitGrids = {}
    self.m_duplicateGrids = {}
    self.m_needInverseCache = {}
    self.m_buildElementsLevels = {}
    self.m_characterData = {}
    if not ignoreGlobal then
        self.m_loadedGrids = {}
        self.m_loadedPosition = {}
        self.m_loadedLines = {}
        self.m_loadedStaticElements = {}
        self.m_loadedStaticElementInitializerMap = {}
        self.m_loadedMarks = {}
        self.m_loadedMarkViewDataMap = {}
        self.m_loadedMissionTrackingMarks = {}
        self.m_loadedMissionTrackingAreas = {}
        self.m_loadedGameplayAreas = {}
        self.m_gridSpriteCache = {}
        self.m_markStaticDataMap = {}
    end
end
LevelMapLoader._InitMarkStaticDataMap = HL.Method() << function(self)
    self.m_markStaticDataMap = {}
    for templateId, templateData in pairs(Tables.mapMarkTempTable) do
        self.m_markStaticDataMap[templateId] = { templateId = templateId, visibleLayer = templateData.visibleLayer, sortOrder = templateData.sortOrder, filterType = templateData.markInfoType:GetHashCode(), }
    end
end
LevelMapLoader._InitLoaderCache = HL.Method() << function(self)
    self.m_gridCache = LuaNodeCache(self.view.grid, self.view.loadedGrids)
    self.m_markCache = {}
    local markRoot = self.view.markRoot
    for order = MIN_MARK_ORDER, MAX_MARK_ORDER do
        self.m_markCache[order] = LuaNodeCache(self.view.mark, markRoot[string.format(MARK_ORDER_VIEW_NAME_FORMAT, order)])
    end
    self.m_missionTrackingMarkCache = LuaNodeCache(self.view.mission.missionTrackingMark, self.view.trackingMarkRoot.mission)
    self.m_missionTrackingAreaCache = LuaNodeCache(self.view.mission.missionTrackingArea, self.view.missionArea)
    self.m_gameplayAreaCache = LuaNodeCache(self.view.gameplay.gameplayArea, self.view.gameplayArea)
    local lineRoot = self.view.lineRoot
    local lines = self.view.lines
    self.m_lineCaches = { [LineType.Power] = LuaNodeCache(lines.powerLine, lineRoot.powerLine), [LineType.Travel] = LuaNodeCache(lines.travelLine, lineRoot.travelLine), }
    self.m_lineRoots = { [LineType.Power] = lineRoot.powerLine, [LineType.Travel] = lineRoot.travelLine, }
end
LevelMapLoader._InitLevelData = HL.Method() << function(self)
    self:_TryBuildLevelAndConnectedLevelsData(self.m_levelId)
end
LevelMapLoader._InitStaticElementInitializer = HL.Method() << function(self)
    local frontRoot = self.view.staticElementFrontRoot
    local backRoot = self.view.staticElementBackRoot
    local bottomRoot = self.view.staticElementBottomRoot
    local gridRoot = self.view.staticElementGridRoot
    local staticElements = self.view.staticElements
    self.m_staticElementInitializer = {
        [ElementType.SwitchButton] = {
            cache = LuaNodeCache(staticElements.levelSwitchButton, frontRoot.switchButton),
            initializer = function(staticElement, settlementElementData)
                staticElement.levelMapSwitchBtn:InitSwitchButton(settlementElementData.targetLevelId, settlementElementData.directionAngle)
            end,
            componentGetter = function(staticElement)
                return staticElement.levelMapSwitchBtn
            end
        },
        [ElementType.NarrativeAreaText] = {
            cache = LuaNodeCache(staticElements.narrativeAreaText, backRoot.narrativeAreaText),
            initializer = function(staticElement, settlementElementData)
                staticElement.text.text = Language[settlementElementData.textId]
            end,
        },
        [ElementType.FacMainRegion] = {
            cache = LuaNodeCache(staticElements.facMainRegion, bottomRoot.facMainRegion),
            initializer = function(staticElement, settlementElementData)
                staticElement.facMainRegion:InitMainRegion(settlementElementData.regionLevelId, settlementElementData.regionPanelIndex)
            end,
            componentGetter = function(staticElement)
                return staticElement.facMainRegion
            end
        },
        [ElementType.SettlementRegion] = {
            cache = LuaNodeCache(staticElements.settlementRegion, bottomRoot.settlementRegion),
            initializer = function(staticElement, settlementElementData)
                local rectCenterPos = staticElement.rectTransform.anchoredPosition
                local worldCenterPos = UILevelMapUtils.ConvertUILevelMapRectPosToWorldPos(rectCenterPos, self.m_gridWorldLength, self.m_gridRectLength)
                staticElement.settlementRegion:InitSettlementRegion(settlementElementData.settlementId, worldCenterPos)
            end,
            componentGetter = function(staticElement)
                return staticElement.settlementRegion
            end
        },
        [ElementType.Crane] = {
            cache = LuaNodeCache(staticElements.crane, gridRoot.crane),
            initializer = function(staticElement, settlementElementData)
                staticElement.crane:InitCrane()
            end,
            componentGetter = function(staticElement)
                return staticElement.crane
            end
        },
        [ElementType.Misty] = {
            cache = LuaNodeCache(staticElements.misty, gridRoot.misty),
            initializer = function(staticElement, settlementElementData)
                staticElement.misty:InitMisty()
            end,
            componentGetter = function(staticElement)
                return staticElement.misty
            end
        },
    }
end
LevelMapLoader._InitLinesInCurrentMap = HL.Method() << function(self)
    self:_RefreshLinesInCurrentMap()
end
LevelMapLoader._InitPermanentElementsInCurrentMap = HL.Method() << function(self)
    self:_InitGameplayAreasInCurrentMap()
    self:_InitPermanentStaticElementsInCurrentMap()
end
LevelMapLoader._InitGameplayAreasInCurrentMap = HL.Method() << function(self)
    local success, areaDataDict = self.m_mapManager:GetGameplayAreaDataDictByMapId(self.m_mapId)
    if not success then
        return
    end
    for areaId, _ in cs_pairs(areaDataDict) do
        self:_RefreshGameplayArea(areaId, true)
    end
end
LevelMapLoader._InitPermanentStaticElementsInCurrentMap = HL.Method() << function(self)
    for levelId, uiLevelConfig in cs_pairs(self.m_levelMapConfig.levelConfigInfos) do
        local levelSuccess, levelConfig = DataManager.levelConfigTable:TryGetData(levelId)
        if levelSuccess and levelConfig.mapIdStr == self.m_mapId then
            for staticElementId, staticElementData in cs_pairs(uiLevelConfig.staticElements) do
                if self.m_loadedStaticElements[staticElementId] == nil then
                    local initializerInfo = self.m_staticElementInitializer[staticElementData.type]
                    if initializerInfo ~= nil then
                        local staticElement = initializerInfo.cache:Get()
                        staticElement.gameObject:SetActive(true)
                        staticElement.rectTransform.anchoredPosition = self:_GetRectPosByWorldPos(staticElementData.position)
                        initializerInfo.initializer(staticElement, staticElementData)
                        self.m_loadedStaticElements[staticElementId] = staticElement
                        self.m_loadedStaticElementInitializerMap[staticElementId] = initializerInfo
                    end
                end
            end
        end
    end
end
LevelMapLoader._InitLoaderUpdateThread = HL.Method() << function(self)
    if not self.m_needDelayUpdateAll then
        self:_UpdateAndRefreshAll()
    end
    local uiCtrl = self:GetUICtrl()
    local nextUpdateTime = 0
    self.m_dataUpdateTick = LuaUpdate:Add("Tick", function(deltaTime)
        if Time.unscaledTime < nextUpdateTime then
            return
        end
        nextUpdateTime = Time.unscaledTime + self.m_dataUpdateInterval
        if uiCtrl:IsShow() and self.m_needUpdate then
            self:_UpdateLoaderDataAndRefresh()
        end
    end, true)
    self.m_rootUpdateTick = LuaUpdate:Add("Tick", function(deltaTime)
        if uiCtrl:IsShow() then
            self:_UpdateCharacterData()
            self:_RefreshCharacter()
            self:_RefreshRootPosition()
        end
    end)
end
LevelMapLoader._TryBuildLevelAndConnectedLevelsData = HL.Method(HL.String).Return(HL.Boolean) << function(self, levelId)
    local isDirty = false
    local selfSuccess, selfLevelConfig = self.m_levelMapConfig.levelConfigInfos:TryGetValue(levelId)
    if selfSuccess then
        local selfDirty = self:_BuildLevelData(levelId, selfLevelConfig)
        if selfDirty then
            isDirty = true
        end
    end
    local connectedLevelList = MapConst.LEVEL_MAP_CONNECTED_LEVEL_CONFIG[self.m_levelId]
    if connectedLevelList ~= nil then
        for _, connectedLevelId in pairs(connectedLevelList) do
            local connectedSuccess, connectedLevelConfig = self.m_levelMapConfig.levelConfigInfos:TryGetValue(connectedLevelId)
            if connectedSuccess then
                local connectedDirty = self:_BuildLevelData(connectedLevelId, connectedLevelConfig)
                if connectedDirty then
                    isDirty = true
                end
            end
        end
    end
    return isDirty
end
LevelMapLoader._BuildLevelData = HL.Method(HL.String, HL.Userdata).Return(HL.Boolean) << function(self, levelId, levelConfig)
    if self.m_buildLevels[levelId] then
        return false
    end
    self.m_needInverseCache[levelId] = levelConfig.needInverseXZ
    local leftBottom = self:_GetRectPosByWorldPos(levelConfig.rectLeftBottom)
    local rightTop = self:_GetRectPosByWorldPos(levelConfig.rectRightTop)
    if levelConfig.needInverseXZ then
        leftBottom = Vector2(leftBottom.x, -leftBottom.y)
        rightTop = Vector2(rightTop.x, -rightTop.y)
    end
    self.m_levelBounds[levelId] = { left = leftBottom.x, right = rightTop.x, bottom = leftBottom.y, top = rightTop.y, }
    self:_BuildLevelGridData(levelId, levelConfig.rectLeftBottom, levelConfig.rectRightTop)
    self.m_buildLevels[levelId] = true
    return true
end
LevelMapLoader._BuildLevelGridData = HL.Method(HL.String, Vector2, Vector2) << function(self, levelId, leftBottom, rightTop)
    local grids = {}
    local xCount = (rightTop.x - leftBottom.x) / self.m_gridWorldLength
    local yCount = (rightTop.y - leftBottom.y) / self.m_gridWorldLength
    if self.m_needInverseCache[levelId] then
        local temp = xCount
        xCount = yCount
        yCount = temp
    end
    for i = 1, xCount do
        for j = 1, yCount do
            local gridId = UILevelMapUtils.GetUILevelMapGridId(levelId, i, j)
            local worldPos = Vector2(leftBottom.x + (i - 0.5) * self.m_gridWorldLength, leftBottom.y + (j - 0.5) * self.m_gridWorldLength)
            local rectPos = self:_GetRectPosByWorldPos(worldPos, true)
            local gridData = { levelId = levelId, id = gridId, pos = rectPos, posX = rectPos.x, posY = rectPos.y, staticElements = {}, marks = {}, }
            grids[gridId] = gridData
            self.m_gridGetter[gridId] = gridData
        end
    end
    self.m_levelGrids[levelId] = grids
end
LevelMapLoader._BuildLevelElementsData = HL.Method(HL.String) << function(self, levelId)
    local markDataSuccess, markDataDict = self.m_mapManager:GetLevelMarkData(self.m_mapId, levelId)
    if markDataSuccess then
        for markInstId, markData in cs_pairs(markDataDict) do
            local gridId = self:_GetLevelGridByWorldPos(levelId, markData.position)
            local grid = self.m_gridGetter[gridId]
            if grid ~= nil then
                grid.marks[markInstId] = markData
            end
        end
    end
    local levelCfgSuccess, levelConfigInfo = self.m_levelMapConfig.levelConfigInfos:TryGetValue(levelId)
    if levelCfgSuccess then
        for staticElementId, staticElementData in cs_pairs(levelConfigInfo.staticElements) do
            if not staticElementData.isPermanent then
                local gridId = self:_GetLevelGridByWorldPos(levelId, staticElementData.position)
                local grid = self.m_gridGetter[gridId]
                if grid ~= nil then
                    grid.staticElements[staticElementId] = staticElementData
                end
            end
        end
    end
    self.m_buildElementsLevels[levelId] = true
end
LevelMapLoader._OnMarkInstDataChangedCallback = HL.Method(HL.String, HL.Boolean) << function(self, markInstId, isAdd)
    local success, markData = self.m_mapManager:GetMarkInstRuntimeData(markInstId)
    if not success then
        return
    end
    local gridId = self:_GetLevelGridByWorldPos(markData.levelId, markData.position)
    local grid = self.m_gridGetter[gridId]
    if not grid then
        return
    end
    if isAdd then
        grid.marks[markInstId] = markData
    else
        grid.marks[markInstId] = nil
    end
    if self.m_loadedGrids[gridId] ~= nil then
        self:_RefreshGridMark(markInstId, markData, isAdd)
    end
end
LevelMapLoader._UpdateAndRefreshAll = HL.Method() << function(self)
    self:_UpdateLoaderDataAndRefresh()
    self:_UpdateCharacterData()
    self:_RefreshCharacter()
    self:_RefreshRootPosition()
end
LevelMapLoader._UpdateLoaderDataAndRefresh = HL.Method() << function(self)
    self:_UpdateHitLevels()
    self:_UpdateHitGrids()
    self:_UpdateElementsData()
    self:_RefreshLoadedGridsAndElements()
end
LevelMapLoader._UpdateHitLevels = HL.Method() << function(self)
    local viewLeft, viewRight
    local viewBottom, viewTop
    if self.m_useSingleViewData then
        local halfWidth, halfHeight = self.m_viewSingleData.width / 2.0, self.m_viewSingleData.height / 2.0
        viewLeft, viewRight = self.m_viewSingleData.posX - halfWidth, self.m_viewSingleData.posX + halfWidth
        viewBottom, viewTop = self.m_viewSingleData.posY - halfHeight, self.m_viewSingleData.posY + halfHeight
    else
        local viewPos = self.view.viewRect.anchoredPosition
        local viewRect = self.view.viewRect.rect
        local halfWidth, halfHeight = viewRect.width / 2.0, viewRect.height / 2.0
        viewLeft, viewRight = viewPos.x - halfWidth, viewPos.x + halfWidth
        viewBottom, viewTop = viewPos.y - halfHeight, viewPos.y + halfHeight
    end
    local viewLeftBound = viewLeft - self.m_gridRectLength
    local viewRightBound = viewRight + self.m_gridRectLength
    local viewBottomBound = viewBottom - self.m_gridRectLength
    local viewTopBound = viewTop + self.m_gridRectLength
    self.m_viewBound = { left = viewLeftBound, right = viewRightBound, bottom = viewBottomBound, top = viewTopBound, }
    self.m_hitLevels = {}
    for levelId, bound in pairs(self.m_levelBounds) do
        local horizontalHit = viewLeftBound <= bound.right and viewRightBound >= bound.left
        local verticalHit = viewBottomBound <= bound.top and viewTopBound >= bound.bottom
        if horizontalHit or verticalHit then
            table.insert(self.m_hitLevels, levelId)
        end
    end
end
LevelMapLoader._UpdateHitGrids = HL.Method() << function(self)
    self.m_hitGrids = {}
    for _, levelId in pairs(self.m_hitLevels) do
        local grids = self.m_levelGrids[levelId]
        for gridId, grid in pairs(grids) do
            local x, y = grid.posX, grid.posY
            local hit = x >= self.m_viewBound.left and x <= self.m_viewBound.right and y >= self.m_viewBound.bottom and y <= self.m_viewBound.top
            if hit then
                self.m_hitGrids[gridId] = true
            end
        end
    end
end
LevelMapLoader._UpdateElementsData = HL.Method() << function(self)
    for _, levelId in pairs(self.m_hitLevels) do
        if not self.m_buildElementsLevels[levelId] then
            self:_BuildLevelElementsData(levelId)
        end
    end
end
LevelMapLoader._UpdateCharacterData = HL.Method() << function(self)
    local character = GameInstance.playerController.mainCharacter
    if not NotNull(character.rootCom.transform) then
        return
    end
    local charPos = Vector2(character.position.x, character.position.z)
    local charAngle = character.rootCom.transform.eulerAngles.y;
    local charViewAngle = CameraManager.mainCamera.transform.eulerAngles.y;
    if self.m_needInverseCache[self.m_levelId] then
        charAngle = (charAngle + 90) % 360
        charViewAngle = (charViewAngle + 90) % 360
    end
    self.m_characterData.pos = self:_GetRectPosByWorldPos(charPos)
    self.m_characterData.worldPos = character.position
    self.m_characterData.angle = charAngle
    self.m_characterData.viewAngle = charViewAngle
end
LevelMapLoader._RefreshLoadedGridsAndElements = HL.Method() << function(self)
    for gridId, gridCell in pairs(self.m_loadedGrids) do
        if not self.m_hitGrids[gridId] then
            self.m_gridCache:Cache(gridCell)
            self.m_loadedGrids[gridId] = nil
            self:_RefreshGridStaticElements(gridId, false)
            self:_RefreshGridMarks(gridId, false)
        end
    end
    for gridId, _ in pairs(self.m_hitGrids) do
        if self.m_loadedGrids[gridId] == nil then
            local gridCell = self.m_gridCache:Get()
            self:_RefreshGrid(gridCell, gridId)
            self.m_loadedGrids[gridId] = gridCell
            self:_RefreshGridStaticElements(gridId, true)
            self:_RefreshGridMarks(gridId, true)
        end
    end
    self:_RefreshDuplicateGrids()
    self:_RefreshHideElements()
end
LevelMapLoader._RefreshGrid = HL.Method(HL.Any, HL.String) << function(self, grid, gridId)
    grid.image.sprite = self:_GetGridSprite(gridId)
    local gridData = self.m_gridGetter[gridId]
    if gridData then
        grid.rectTransform.anchoredPosition = gridData.pos or Vector2.zero
    end
end
LevelMapLoader._RefreshDuplicateGrids = HL.Method() << function(self)
    self.m_loadedPosition = {}
    self.m_duplicateGrids = {}
    for gridId, _ in pairs(self.m_loadedGrids) do
        local grid = self.m_gridGetter[gridId]
        local posX, posY = grid.posX, grid.posY
        if self.m_loadedPosition[posX] == nil then
            self.m_loadedPosition[posX] = {}
        end
        if self.m_loadedPosition[posX][posY] == nil then
            self.m_loadedPosition[posX][posY] = {}
        end
        table.insert(self.m_loadedPosition[posX][posY], gridId)
        if #self.m_loadedPosition[posX][posY] > 1 then
            table.insert(self.m_duplicateGrids, self.m_loadedPosition[posX][posY])
        end
    end
    for _, gridList in pairs(self.m_duplicateGrids) do
        for _, gridId in pairs(gridList) do
            local gridData = self.m_gridGetter[gridId]
            if gridData ~= nil then
                local gridCell = self.m_loadedGrids[gridId]
                if gridCell ~= nil then
                    gridCell.gameObject:SetActiveIfNecessary(gridData.levelId == self.m_levelId)
                end
            end
        end
    end
end
LevelMapLoader._RefreshRootPosition = HL.Method() << function(self)
    self.view.rectTransform.anchoredPosition = Vector2(-self.view.viewRect.anchoredPosition.x, -self.view.viewRect.anchoredPosition.y)
end
LevelMapLoader._RefreshGridMarks = HL.Method(HL.String, HL.Boolean) << function(self, gridId, needShow)
    local gridData = self.m_gridGetter[gridId]
    if gridData == nil then
        return
    end
    local marks = gridData.marks
    if marks == nil or not next(marks) then
        return
    end
    for markInstId, markData in pairs(marks) do
        self:_RefreshGridMark(markInstId, markData, needShow)
    end
end
LevelMapLoader._RefreshGridMark = HL.Method(HL.String, HL.Userdata, HL.Boolean) << function(self, markInstId, markData, needShow)
    local templateId = markData.templateId
    local templateData = self.m_markStaticDataMap[templateId]
    if templateData == nil then
        return
    end
    local order = templateData.sortOrder
    local cache = self.m_markCache[order]
    if cache ~= nil then
        if needShow then
            local mark = cache:Get()
            mark.rectTransform.anchoredPosition = self:_GetRectPosByWorldPos(markData.position)
            mark.content.gameObject:SetActive(true)
            mark.levelMapMark:Init(markData)
            mark.gameObject.name = string.format(MARK_GAME_OBJECT_NAME_FORMAT, markInstId)
            self.m_loadedMarks[markInstId] = mark
            self.m_loadedMarkViewDataMap[markInstId] = { instId = markInstId, mark = mark, sortOrder = order, visibleLayer = templateData.visibleLayer, filterType = templateData.filterType, isVisible = markData.isVisible, isPowerRelated = false, isTravelRelated = false, }
            if markData.isPowerRelated ~= nil then
                self.m_loadedMarkViewDataMap[markInstId].isPowerRelated = markData.isPowerRelated
            end
            if markData.isTravelRelated ~= nil then
                self.m_loadedMarkViewDataMap[markInstId].isTravelRelated = markData.isTravelRelated
            end
        else
            local mark = self.m_loadedMarks[markInstId]
            if mark ~= nil then
                mark.levelMapMark:ClearComponent()
                mark.gameObject.name = ""
                cache:Cache(mark)
                self.m_loadedMarks[markInstId] = nil
                self.m_loadedMarkViewDataMap[markInstId] = nil
            end
        end
    end
end
LevelMapLoader._RefreshGridStaticElements = HL.Method(HL.String, HL.Boolean) << function(self, gridId, needShow)
    local grid = self.m_gridGetter[gridId]
    if grid == nil then
        return
    end
    local staticElements = grid.staticElements
    if staticElements == nil or not next(staticElements) then
        return
    end
    for staticElementId, staticElementData in pairs(staticElements) do
        if staticElementData ~= nil then
            if needShow then
                if self.m_loadedStaticElements[staticElementId] == nil then
                    local initializerInfo = self.m_staticElementInitializer[staticElementData.type]
                    if initializerInfo ~= nil then
                        local staticElement = initializerInfo.cache:Get()
                        staticElement.gameObject:SetActive(true)
                        initializerInfo.initializer(staticElement, staticElementData)
                        staticElement.rectTransform.anchoredPosition = self:_GetRectPosByWorldPos(staticElementData.position)
                        self.m_loadedStaticElements[staticElementId] = staticElement
                        self.m_loadedStaticElementInitializerMap[staticElementId] = initializerInfo
                    end
                else
                    local staticElement = self.m_loadedStaticElements[staticElementId]
                    if not staticElement.gameObject.activeSelf then
                        staticElement.gameObject:SetActive(true)
                    end
                end
            else
                if self.m_loadedStaticElements[staticElementId] ~= nil then
                    local staticElement = self.m_loadedStaticElements[staticElementId]
                    if staticElement.gameObject.activeSelf then
                        staticElement.gameObject:SetActive(false)
                    end
                end
            end
        end
    end
end
LevelMapLoader._RefreshHideElements = HL.Method() << function(self)
    if not self.m_hideOtherLevels then
        return
    end
    for gridId, _ in pairs(self.m_loadedGrids) do
        local grid = self.m_gridGetter[gridId]
        local staticElements = grid.staticElements
        local marks = grid.marks
        if staticElements ~= nil and next(staticElements) then
            for staticElementId, _ in pairs(staticElements) do
                local staticElement = self.m_loadedStaticElements[staticElementId]
                if staticElement ~= nil then
                    staticElement.gameObject:SetActiveIfNecessary(grid.levelId == self.m_levelId)
                end
            end
        end
        if marks ~= nil and next(marks) then
            for markInstId, _ in pairs(marks) do
                local mark = self.m_loadedMarks[markInstId]
                local markViewData = self.m_loadedMarkViewDataMap[markInstId]
                if mark ~= nil and markViewData ~= nil then
                    markViewData.isHidden = not markViewData.isPowerRelated and not markViewData.isTravelRelated and grid.levelId ~= self.m_levelId
                    mark.gameObject:SetActiveIfNecessary(not markViewData.isHidden and markViewData.isVisible)
                end
            end
        end
    end
end
LevelMapLoader._RefreshCharacter = HL.Method() << function(self)
    local playerRect = self.view.player
    playerRect.rectTransform.anchoredPosition = self.m_characterData.pos
    playerRect.playerArrow.localEulerAngles = Vector3(0.0, 0.0, -self.m_characterData.angle)
    playerRect.playerView.localEulerAngles = Vector3(0.0, 0.0, -self.m_characterData.viewAngle)
    if self.m_hidePlayer then
        playerRect.gameObject:SetActive(false)
    else
        playerRect.gameObject:SetActive(self.m_needRefreshPlayer)
    end
end
LevelMapLoader._RefreshLinesInCurrentMap = HL.Method() << function(self)
    self:_RefreshPowerLines()
    self:_RefreshTravelLines()
end
LevelMapLoader._RefreshLineBasicTransform = HL.Method(HL.Any, HL.Userdata) << function(self, line, lineData)
    if line == nil or lineData == nil then
        return
    end
    local startRectPos = self:_GetRectPosByWorldPos(lineData.startPosition)
    local endRectPos = self:_GetRectPosByWorldPos(lineData.endPosition)
    local direction = endRectPos - startRectPos
    local length = direction.magnitude
    line.rectTransform.sizeDelta = Vector2(length, line.rectTransform.rect.height)
    line.rectTransform.anchoredPosition = (startRectPos + endRectPos) / 2
    local angle = math.acos(Vector2.Dot(direction.normalized, Vector2.right)) * (180 / math.pi)
    if direction.y < 0 then
        angle = 360 - angle
    end
    line.rectTransform.localRotation = Quaternion.Euler(0, 0, angle)
    if line.levelMapLine ~= nil then
        line.levelMapLine:Init(length)
    end
end
LevelMapLoader._RefreshPowerLines = HL.Method() << function(self)
    local powerLineSuccess, powerLineList = self.m_mapManager:GetFacPowerLineDataListByMapId(self.m_mapId)
    if not powerLineSuccess then
        return
    end
    local powerLineCache = self.m_lineCaches[LineType.Power]
    local loadedPowerLines = self.m_loadedLines[LineType.Power]
    if loadedPowerLines ~= nil then
        for _, loadedLine in pairs(loadedPowerLines) do
            loadedLine.gameObject:SetActive(false)
            if loadedLine.levelMapLine ~= nil then
                loadedLine.levelMapLine:ClearComponent()
            end
            powerLineCache:Cache(loadedLine)
        end
    end
    self.m_loadedLines[LineType.Power] = {}
    for lineData, _ in cs_pairs(powerLineList) do
        local line = powerLineCache:Get()
        line.gameObject:SetActive(true)
        line.image.color = lineData.hasPower and self.view.config.POWER_LINE_VALID_COLOR or self.view.config.POWER_LINE_INVALID_COLOR
        self:_RefreshLineBasicTransform(line, lineData)
        table.insert(self.m_loadedLines[LineType.Power], line)
    end
end
LevelMapLoader._RefreshTravelLines = HL.Method() << function(self)
    local travelLineSuccess, travelLineList = self.m_mapManager:GetFacTravelLineDataListByMapId(self.m_mapId)
    if not travelLineSuccess then
        return
    end
    local travelLineCache = self.m_lineCaches[LineType.Travel]
    local loadedTravelLines = self.m_loadedLines[LineType.Travel]
    if loadedTravelLines ~= nil then
        for _, loadedLine in pairs(loadedTravelLines) do
            loadedLine.gameObject:SetActive(false)
            if loadedLine.levelMapLine ~= nil then
                loadedLine.levelMapLine:ClearComponent()
            end
            travelLineCache:Cache(loadedLine)
        end
    end
    self.m_loadedLines[LineType.Travel] = {}
    for lineData, _ in cs_pairs(travelLineList) do
        local line = travelLineCache:Get()
        line.gameObject:SetActive(true)
        self:_RefreshLineBasicTransform(line, lineData)
        table.insert(self.m_loadedLines[LineType.Travel], line)
    end
end
LevelMapLoader._RefreshGameplayArea = HL.Method(HL.String, HL.Boolean) << function(self, areaId, needShow)
    if needShow then
        if self.m_loadedGameplayAreas[areaId] == nil then
            local success, areaData = self.m_mapManager:GetGameplayAreaInstRuntimeData(areaId)
            if success and areaData.mapId == self.m_mapId then
                local gameplayArea = self.m_gameplayAreaCache:Get()
                gameplayArea.rectTransform.anchoredPosition = self:_GetRectPosByWorldPos(areaData.position)
                gameplayArea.gameObject:SetActive(true)
                gameplayArea.levelMapGameplayArea:Init(areaData)
                self.m_loadedGameplayAreas[areaId] = gameplayArea
            end
        end
    else
        if self.m_loadedGameplayAreas[areaId] ~= nil then
            local gameplayArea = self.m_loadedGameplayAreas[areaId]
            gameplayArea.levelMapGameplayArea:ClearComponent()
            gameplayArea.gameObject:SetActive(false)
            self.m_gameplayAreaCache:Cache(gameplayArea)
            self.m_loadedGameplayAreas[areaId] = nil
        end
    end
end
LevelMapLoader._GetGridSprite = HL.Method(HL.String).Return(HL.Userdata) << function(self, gridId)
    local sprite = self.m_gridSpriteCache[gridId]
    if sprite == nil then
        local grid = self.m_gridGetter[gridId]
        if grid ~= nil then
            local folder = UILevelMapUtils.GetUILevelMapGridsFolderByLevelId(grid.levelId, false)
            sprite = self:LoadSprite(folder, gridId)
            self.m_gridSpriteCache[gridId] = sprite
        end
    end
    return sprite
end
LevelMapLoader._GetRectPosByWorldPos = HL.Method(HL.Any, HL.Opt(HL.Boolean)).Return(Vector2) << function(self, worldPos, ignoreInverse)
    local rectPos = UILevelMapUtils.ConvertUILevelMapWorldPosToRectPos(worldPos, self.m_gridWorldLength, self.m_gridRectLength)
    local needInverse = self.m_needInverseCache[self.m_levelId]
    if not ignoreInverse and needInverse then
        rectPos = Vector2(rectPos.y, -rectPos.x)
    end
    return rectPos
end
LevelMapLoader._GetLevelGridByWorldPos = HL.Method(HL.String, HL.Any).Return(HL.String) << function(self, levelId, worldPos)
    local bounds = self.m_levelBounds[levelId]
    if bounds == nil then
        return ""
    end
    local rectPos = self:_GetRectPosByWorldPos(worldPos)
    local xOffset = rectPos.x - bounds.left
    local yOffset = rectPos.y - bounds.bottom
    local x = math.ceil(xOffset / self.m_gridRectLength)
    local y = math.ceil(yOffset / self.m_gridRectLength)
    return UILevelMapUtils.GetUILevelMapGridId(levelId, x, y)
end
LevelMapLoader._ClearLoaderCache = HL.Method(HL.Table, LuaNodeCache) << function(self, nodeTable, cache)
    if nodeTable == nil then
        return
    end
    for _, node in pairs(nodeTable) do
        cache:Cache(node)
    end
    nodeTable = {}
end
LevelMapLoader._ClearLoaderGridCache = HL.Method() << function(self)
    if self.m_loadedGrids == nil then
        return
    end
    for _, node in pairs(self.m_loadedGrids) do
        self.m_gridCache:Cache(node)
    end
    self.m_loadedGrids = {}
end
LevelMapLoader._ClearLoaderMarkCache = HL.Method() << function(self)
    for _, markViewData in pairs(self.m_loadedMarkViewDataMap) do
        local order = markViewData.sortOrder
        local cache = self.m_markCache[order]
        markViewData.mark.levelMapMark:ClearComponent()
        cache:Cache(markViewData.mark)
    end
    self.m_loadedMarks = {}
    self.m_loadedMarkViewDataMap = {}
end
LevelMapLoader._ClearLoaderStaticElementCache = HL.Method() << function(self)
    for staticElementId, staticElement in pairs(self.m_loadedStaticElements) do
        local initializer = self.m_loadedStaticElementInitializerMap[staticElementId]
        if initializer.componentGetter ~= nil then
            local component = initializer.componentGetter(staticElement)
            if component ~= nil then
                component:ClearComponent()
            end
        end
        initializer.cache:Cache(staticElement)
    end
    self.m_loadedStaticElements = {}
    self.m_loadedStaticElementInitializerMap = {}
end
LevelMapLoader._ClearLoaderGameplayAreaCache = HL.Method() << function(self)
    if self.m_loadedGameplayAreas == nil then
        return
    end
    for _, node in pairs(self.m_loadedGameplayAreas) do
        node.levelMapGameplayArea:ClearComponent()
        self.m_gameplayAreaCache:Cache(node)
    end
    self.m_loadedGameplayAreas = {}
end
LevelMapLoader._ClearLoaderCachesState = HL.Method() << function(self)
    self:_ClearLoaderGridCache()
    self:_ClearLoaderStaticElementCache()
    self:_ClearLoaderMarkCache()
    self:_ClearLoaderGameplayAreaCache()
end
LevelMapLoader.SetLoaderWithPlayerPosition = HL.Method() << function(self)
    self.view.viewRect.anchoredPosition = self.m_characterData.pos
    self.m_viewSingleData.posX = self.m_characterData.pos.x
    self.m_viewSingleData.posY = self.m_characterData.pos.y
end
LevelMapLoader.SetLoaderWithMarkPosition = HL.Method(HL.String) << function(self, markInstId)
    local success, markRuntimeData = GameInstance.player.mapManager:GetMarkInstRuntimeData(markInstId)
    if not success then
        return
    end
    self.view.viewRect.anchoredPosition = self:_GetRectPosByWorldPos(markRuntimeData.position)
end
LevelMapLoader.SetLoaderWithLevelCenterPosition = HL.Method(HL.String, Vector2, HL.Opt(HL.Table)).Return(HL.Userdata) << function(self, levelId, offset, tweenInfo)
    local levelBound = self.m_levelBounds[levelId]
    if levelBound == nil then
        return nil
    end
    local leftBottom = Vector2(levelBound.left, levelBound.bottom)
    local rightTop = Vector2(levelBound.right, levelBound.top)
    local center = (leftBottom + rightTop) / 2.0 + offset
    if tweenInfo then
        self.m_posTween = self.view.viewRect:DOAnchorPos(center, tweenInfo.duration):SetEase(tweenInfo.ease):OnUpdate(function()
            self:_RefreshRootPosition()
            self:_UpdateLoaderDataAndRefresh()
        end)
        return self.m_posTween
    else
        self.view.viewRect.anchoredPosition = center
        return nil
    end
end
LevelMapLoader.SetLoaderViewSizeByGridsCount = HL.Method(HL.Number, HL.Number, HL.Opt(HL.Table)).Return(HL.Userdata) << function(self, horizontalCount, verticalCount, tweenInfo)
    local size = Vector2(horizontalCount * self.m_gridRectLength, verticalCount * self.m_gridRectLength)
    if tweenInfo ~= nil then
        self.m_sizeTween = self.view.viewRect:DOSizeDelta(size, tweenInfo.duration):SetEase(tweenInfo.ease)
        return self.m_sizeTween
    else
        self.view.viewRect.sizeDelta = size
        return nil
    end
end
LevelMapLoader.SetLoaderDataUpdateInterval = HL.Method(HL.Number) << function(self, interval)
    self.m_dataUpdateInterval = interval
end
LevelMapLoader.SetLoaderElementsShownState = HL.Method(HL.Boolean) << function(self, isShown)
    self.view.staticElementBackRoot.gameObject:SetActive(isShown)
    self.view.staticElementFrontRoot.gameObject:SetActive(isShown)
    self.view.lineRoot.gameObject:SetActive(isShown)
    self.view.markRoot.gameObject:SetActive(isShown)
    self.view.trackingMarkRoot.gameObject:SetActive(isShown)
end
LevelMapLoader.SetLoaderLevel = HL.Method(HL.String) << function(self, levelId)
    self.m_levelId = levelId
    local needUpdate = self:_TryBuildLevelAndConnectedLevelsData(levelId)
    if needUpdate then
        self:_UpdateLoaderDataAndRefresh()
    end
end
LevelMapLoader.SetLoaderNeedUpdate = HL.Method(HL.Boolean) << function(self, needUpdate)
    self.m_needUpdate = needUpdate
end
LevelMapLoader.SetGeneralTrackingMarkState = HL.Method(HL.String) << function(self, markInstId)
    local generalTrackingMark = self.view.trackingMarkRoot.generalTrackingMark
    generalTrackingMark.gameObject:SetActive(false)
    generalTrackingMark.levelMapMark:RefreshTrackingState(false)
    if string.isEmpty(markInstId) then
        return
    end
    local success, markData = GameInstance.player.mapManager:GetMarkInstRuntimeData(markInstId)
    if not success or markData.mapId ~= self.m_mapId then
        return
    end
    generalTrackingMark.rectTransform.anchoredPosition = self:_GetRectPosByWorldPos(markData.position)
    generalTrackingMark.levelMapMark:Init(markData)
    generalTrackingMark.levelMapMark:RefreshTrackingState(true)
    generalTrackingMark.gameObject:SetActive(true)
end
LevelMapLoader.SetMissionTrackingMarkState = HL.Method(HL.Table) << function(self, markInstIdList)
    for _, missionTrackingMark in pairs(self.m_loadedMissionTrackingMarks) do
        missionTrackingMark.levelMapMark:ClearComponent()
        missionTrackingMark.gameObject:SetActive(false)
        self.m_missionTrackingMarkCache:Cache(missionTrackingMark)
    end
    self.m_loadedMissionTrackingMarks = {}
    for _, missionTrackingArea in pairs(self.m_loadedMissionTrackingAreas) do
        missionTrackingArea.levelMapMissionArea:ClearComponent()
        missionTrackingArea.gameObject:SetActive(false)
        self.m_missionTrackingAreaCache:Cache(missionTrackingArea)
    end
    self.m_loadedMissionTrackingAreas = {}
    if markInstIdList == nil then
        return
    end
    for _, markInstId in pairs(markInstIdList) do
        local success, markData = GameInstance.player.mapManager:GetMarkInstRuntimeData(markInstId)
        if success and markData.mapId == self.m_mapId then
            local missionTrackingMark = self.m_missionTrackingMarkCache:Get()
            local rectPos = self:_GetRectPosByWorldPos(markData.position)
            missionTrackingMark.rectTransform.anchoredPosition = rectPos
            missionTrackingMark.gameObject:SetActive(true)
            missionTrackingMark.levelMapMark:Init(markData)
            missionTrackingMark.levelMapMark:RefreshTrackingState(true)
            self.m_loadedMissionTrackingMarks[markInstId] = missionTrackingMark
            if markData.trackData ~= nil and markData.trackData.guidingArea > 0 then
                local missionTrackingArea = self.m_missionTrackingAreaCache:Get()
                missionTrackingArea.rectTransform.anchoredPosition = rectPos
                missionTrackingArea.gameObject:SetActive(true)
                missionTrackingArea.levelMapMissionArea:Init(markData, missionTrackingMark.gameObject)
                self.m_loadedMissionTrackingAreas[markInstId] = missionTrackingArea
                if missionTrackingArea.levelMapMissionArea.needUseCenterPosition then
                    local centerPos = self:_GetRectPosByWorldPos(markData.trackData.guidingAreaCenter)
                    missionTrackingArea.rectTransform.anchoredPosition = centerPos
                end
            end
        end
    end
end
LevelMapLoader.SetLoaderLineVisibleStateByType = HL.Method(HL.Userdata, HL.Boolean) << function(self, lineType, isVisible)
    local root = self.m_lineRoots[lineType]
    if root == nil then
        return
    end
    root.gameObject:SetActive(isVisible)
end
LevelMapLoader.SetLoaderLineVisibleState = HL.Method(HL.Boolean) << function(self, isVisible)
    for _, root in pairs(self.m_lineRoots) do
        root.gameObject:SetActive(isVisible)
    end
end
LevelMapLoader.SetLoaderPlayerVisibleState = HL.Method(HL.Boolean) << function(self, isVisible)
    self.m_needRefreshPlayer = isVisible
end
LevelMapLoader.GetLoaderViewRectWidthAndHeight = HL.Method(HL.Boolean).Return(HL.Number, HL.Number) << function(self, getTarget)
    if getTarget and self.m_sizeTween ~= nil and self.m_sizeTween:IsPlaying() then
        local size = self.m_sizeTween.endValue
        return size.x, size.y
    else
        local rect = self.view.viewRect.rect
        return rect.width, rect.height
    end
end
LevelMapLoader.GetWorldPositionByRectPosition = HL.Method(Vector2).Return(Vector3) << function(self, rectPos)
    return UILevelMapUtils.ConvertUILevelMapRectPosToWorldPos(rectPos, self.m_gridWorldLength, self.m_gridRectLength)
end
LevelMapLoader.GetMarkRectTransformByInstId = HL.Method(HL.String).Return(Unity.RectTransform) << function(self, instId)
    local mark = self.m_loadedMarks[instId]
    if mark == nil then
        return nil
    end
    return mark.rectTransform
end
LevelMapLoader.GetLoadedMarkViewDataMap = HL.Method().Return(HL.Table) << function(self)
    return self.m_loadedMarkViewDataMap
end
LevelMapLoader.GetLoadedMarkByInstId = HL.Method(HL.String).Return(HL.Any) << function(self, instId)
    return self.m_loadedMarks[instId]
end
LevelMapLoader.GetLoaderCharacterData = HL.Method().Return(HL.Table) << function(self)
    return self.m_characterData
end
LevelMapLoader.GetLoaderCharacterWorldPosition = HL.Method().Return(Vector3) << function(self)
    return (self.m_characterData == nil or self.m_characterData.worldPos == nil) and Vector3.zero or self.m_characterData.worldPos
end
LevelMapLoader.GetGeneralTrackingMark = HL.Method().Return(HL.Any) << function(self)
    return self.view.trackingMarkRoot.generalTrackingMark
end
LevelMapLoader.GetMissionTrackingMarks = HL.Method().Return(HL.Any) << function(self)
    return self.m_loadedMissionTrackingMarks
end
LevelMapLoader.UpdateAndRefreshAll = HL.Method() << function(self)
    self:_UpdateAndRefreshAll()
end
LevelMapLoader.ResetToTargetMapAndLevel = HL.Method(HL.String) << function(self, levelId)
    local success, levelConfig = DataManager.levelConfigTable:TryGetData(levelId)
    if not success then
        return
    end
    self.m_mapId = levelConfig.mapIdStr
    self.m_levelId = levelId
    self:_ClearLoaderCachesState()
    self:_InitTableFields(true)
    self:_InitLevelData()
    self:_UpdateAndRefreshAll()
    self:_InitLinesInCurrentMap()
    self:_InitPermanentElementsInCurrentMap()
end
HL.Commit(LevelMapLoader)
return LevelMapLoader