local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.WikiCraftingTree
WikiCraftingTreeCtrl = HL.Class('WikiCraftingTreeCtrl', uiCtrl.UICtrl)
local ITEM_CELL_HEIGHT = 160
local ITEM_CELL_WIDTH = 175
local ITEM_CELL_GAP_WIDTH = 175 + 100 * 2
local CREATE_LINE_THRESHOLD = 5
local LINE_WIDTH = 2
local CONTENT_PADDING = Vector2(100, 100)
WikiCraftingTreeCtrl.s_messages = HL.StaticField(HL.Table) << {}
WikiCraftingTreeCtrl.m_wikiEntryShowData = HL.Field(HL.Table)
WikiCraftingTreeCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local args = arg
    self.m_wikiEntryShowData = args.wikiEntryShowData
    self.view.wikiVideoBgWidget:InitWikiVideoBg()
    self:_ActivateBottom(false)
    self.view.scrollViewBtn.onClick:AddListener(function()
        self:_ActivateBottom(false)
    end)
    self.view.itemCell.gameObject:SetActive(false)
    self.view.buildingCell.gameObject:SetActive(false)
    self.view.lineCell.gameObject:SetActive(false)
    self.view.curveLeftCell.gameObject:SetActive(false)
    self.view.curveRightCell.gameObject:SetActive(false)
    self:_InitAllCellCache()
    self:_RefreshCraft(self.m_wikiEntryShowData.wikiEntryData.refItemId)
end
WikiCraftingTreeCtrl._OnPhaseItemBind = HL.Override() << function(self)
    self:_RefreshTop()
end
WikiCraftingTreeCtrl._RefreshTop = HL.Method() << function(self)
    local wikiTopArgs = { phase = self.m_phase, panelId = PANEL_ID, categoryType = self.m_wikiEntryShowData.wikiCategoryType, wikiEntryShowData = self.m_wikiEntryShowData, forceShowBackBtn = true, }
    self.view.top:InitWikiTop(wikiTopArgs)
end
WikiCraftingTreeCtrl.m_freeItemCellList = HL.Field(HL.Table)
WikiCraftingTreeCtrl.m_usedItemCellList = HL.Field(HL.Table)
WikiCraftingTreeCtrl._GetItemCell = HL.Method().Return(HL.Userdata) << function(self)
    return self:_GetCell(self.view.itemCell.gameObject, self.view.rootNode.transform, Utils.wrapLuaNode, self.m_freeItemCellList, self.m_usedItemCellList)
end
WikiCraftingTreeCtrl.m_freeBuildingCellList = HL.Field(HL.Table)
WikiCraftingTreeCtrl.m_usedBuildingCellList = HL.Field(HL.Table)
WikiCraftingTreeCtrl._GetBuildingCell = HL.Method().Return(HL.Userdata) << function(self)
    return self:_GetCell(self.view.buildingCell.gameObject, self.view.rootNode.transform, Utils.wrapLuaNode, self.m_freeBuildingCellList, self.m_usedBuildingCellList)
end
WikiCraftingTreeCtrl.m_freeLineCellList = HL.Field(HL.Table)
WikiCraftingTreeCtrl.m_usedLineCellList = HL.Field(HL.Table)
WikiCraftingTreeCtrl._GetLineCell = HL.Method().Return(HL.Table) << function(self)
    return self:_GetCell(self.view.lineCell.gameObject, self.view.lineRootNode.transform, Utils.bindLuaRef, self.m_freeLineCellList, self.m_usedLineCellList)
end
WikiCraftingTreeCtrl.m_freeCurveLeftCell = HL.Field(HL.Table)
WikiCraftingTreeCtrl.m_usedCurveLeftCell = HL.Field(HL.Table)
WikiCraftingTreeCtrl._GetCurveLeftCell = HL.Method().Return(HL.Table) << function(self)
    return self:_GetCell(self.view.curveLeftCell.gameObject, self.view.lineRootNode.transform, Utils.bindLuaRef, self.m_freeCurveLeftCell, self.m_usedCurveLeftCell)
end
WikiCraftingTreeCtrl.m_freeCurveRightCell = HL.Field(HL.Table)
WikiCraftingTreeCtrl.m_usedCurveRightCell = HL.Field(HL.Table)
WikiCraftingTreeCtrl._GetCurveRightCell = HL.Method().Return(HL.Table) << function(self)
    return self:_GetCell(self.view.curveRightCell.gameObject, self.view.lineRootNode.transform, Utils.bindLuaRef, self.m_freeCurveRightCell, self.m_usedCurveRightCell)
end
WikiCraftingTreeCtrl._RecycleCell = HL.Method(HL.Table, HL.Table) << function(self, freeList, usedList)
    for i, cell in ipairs(usedList) do
        cell.gameObject:SetActive(false)
        table.insert(freeList, cell)
    end
    lume.clear(usedList)
end
WikiCraftingTreeCtrl._RecycleAllCell = HL.Method() << function(self)
    self:_RecycleCell(self.m_freeItemCellList, self.m_usedItemCellList)
    self:_RecycleCell(self.m_freeBuildingCellList, self.m_usedBuildingCellList)
    self:_RecycleCell(self.m_freeLineCellList, self.m_usedLineCellList)
    self:_RecycleCell(self.m_freeCurveLeftCell, self.m_usedCurveLeftCell)
    self:_RecycleCell(self.m_freeCurveRightCell, self.m_usedCurveRightCell)
end
WikiCraftingTreeCtrl._InitAllCellCache = HL.Method() << function(self)
    self.m_freeItemCellList = {}
    self.m_usedItemCellList = {}
    self.m_freeBuildingCellList = {}
    self.m_usedBuildingCellList = {}
    self.m_freeLineCellList = {}
    self.m_usedLineCellList = {}
    self.m_freeCurveLeftCell = {}
    self.m_usedCurveLeftCell = {}
    self.m_freeCurveRightCell = {}
    self.m_usedCurveRightCell = {}
end
WikiCraftingTreeCtrl._GetCell = HL.Method(CS.UnityEngine.GameObject, CS.UnityEngine.Transform, HL.Function, HL.Table, HL.Table).Return(HL.Any) << function(self, template, parent, wrapFunc, freeList, usedList)
    if #freeList > 0 then
        local cell = table.remove(freeList)
        cell.gameObject:SetActive(true)
        table.insert(usedList, cell)
        return cell
    end
    local go = GameObject.Instantiate(template, parent)
    go:SetActive(true)
    local cell = wrapFunc(go)
    table.insert(usedList, cell)
    return cell
end
WikiCraftingTreeCtrl.m_rowCountLeft = HL.Field(HL.Number) << 0
WikiCraftingTreeCtrl.m_rowCountRight = HL.Field(HL.Number) << 0
WikiCraftingTreeCtrl.m_columnCountLeft = HL.Field(HL.Number) << 0
WikiCraftingTreeCtrl.m_columnCountRight = HL.Field(HL.Number) << 0
WikiCraftingTreeCtrl.m_craftItemIds = HL.Field(HL.Table)
WikiCraftingTreeCtrl.m_sourceItemCell = HL.Field(HL.Userdata)
WikiCraftingTreeCtrl.m_debugCounter = HL.Field(HL.Number) << 0
WikiCraftingTreeCtrl.m_selectedCell = HL.Field(HL.Any)
WikiCraftingTreeCtrl._RefreshCraft = HL.Method(HL.String) << function(self, itemId)
    self.m_debugCounter = 0
    self.m_craftItemIds = {}
    self.m_rowCountLeft = 0
    self.m_rowCountRight = 0
    self.m_columnCountLeft = 0
    self.m_columnCountRight = 0
    self.m_sourceItemCell = nil
    if self.m_selectedCell then
        self.m_selectedCell:SetSelected(false)
    end
    self:_RecycleAllCell()
    self:_CreateLeftCraft(itemId, 0, Vector2.zero)
    self:_CreateRightCraft(itemId)
    local viewportSize = self.view.viewport.rect.size
    local contentSize = Vector2((ITEM_CELL_WIDTH + ITEM_CELL_GAP_WIDTH) * (self.m_columnCountLeft + self.m_columnCountRight) + ITEM_CELL_WIDTH, math.max(self.m_rowCountLeft, self.m_rowCountRight) * ITEM_CELL_HEIGHT)
    contentSize = contentSize + CONTENT_PADDING * 2
    local extraPadding = Vector2.zero
    if contentSize.x < viewportSize.x then
        extraPadding.x = (viewportSize.x - contentSize.x) / 2
    end
    if contentSize.y < viewportSize.y then
        extraPadding.y = (viewportSize.y - contentSize.y) / 2
    end
    contentSize = contentSize + extraPadding * 2
    self.view.content.sizeDelta = contentSize
    self.view.content.localPosition = Vector3.zero
    self.view.rootNode.localPosition = Vector3(-(self.m_columnCountRight * (ITEM_CELL_WIDTH + ITEM_CELL_GAP_WIDTH) + ITEM_CELL_WIDTH / 2 + CONTENT_PADDING.x + extraPadding.x), -(ITEM_CELL_HEIGHT / 2 + CONTENT_PADDING.y + extraPadding.y), 0)
    local viewMaskPadding = self.view.viewportMask.padding
    viewMaskPadding.z = viewportSize.x / 2
    viewMaskPadding.x = viewportSize.x / 2
    self.view.viewportMask.padding = viewMaskPadding
    DOTween.To(function()
        return self.view.viewportMask.padding
    end, function(value)
        self.view.viewportMask.padding = value
    end, Vector4.zero, self.view.config.EXPAND_ANIM_TIME):SetEase(self.view.config.EXPAND_ANIM_CURVE)
    self.view.center.alpha = 0
    DOTween.To(function()
        return self.view.center.alpha
    end, function(value)
        self.view.center.alpha = value
    end, 1, self.view.config.ALPHA_ANIM_TIME):SetEase(self.view.config.ALPHA_ANIM_CURVE)
end
WikiCraftingTreeCtrl._CreateLeftCraft = HL.Method(HL.String, HL.Number, Vector2) << function(self, itemId, columnCount, sourcePos)
    self.m_debugCounter = self.m_debugCounter + 1
    if self.m_debugCounter > 100 then
        logger.error('WikiCraftingTreeCtrl._CreateCraft: self.m_debugCounter > 100, ' .. itemId)
        return
    end
    if columnCount > self.m_columnCountLeft then
        self.m_columnCountLeft = columnCount
    end
    local itemCell = self:_GetItemCell()
    itemCell.transform.localPosition = Vector3(-(ITEM_CELL_WIDTH + ITEM_CELL_GAP_WIDTH) * columnCount, -ITEM_CELL_HEIGHT * self.m_rowCountLeft, 0)
    local itemArgs = {
        itemId = itemId,
        isShowMainIcon = self.m_sourceItemCell == nil,
        onClicked = function(id, cell)
            self:_OnCraftItemClicked(id, cell)
        end
    }
    itemCell:InitWikiCraftingTreeItem(itemArgs)
    if not self.m_sourceItemCell then
        self.m_sourceItemCell = itemCell
    end
    itemCell:SetRightMountPointCount(1)
    if sourcePos ~= Vector2.zero then
        local itemRightPoint = itemCell:GetRightMountPoint(self.view.rootNode.transform, 1)
        self:_CreateLeftLink(itemRightPoint, sourcePos)
    end
    local craftInfoList = FactoryUtils.getItemCrafts(itemId)
    if not next(craftInfoList) then
        itemCell:SetLeftMountPointCount(0)
        self.m_rowCountLeft = self.m_rowCountLeft + 1
        return
    end
    if self.m_craftItemIds[itemId] then
        itemCell:SetLeftMountPointCount(0)
        self.m_rowCountLeft = self.m_rowCountLeft + 1
        return
    else
        self.m_craftItemIds[itemId] = true
    end
    itemCell:SetLeftMountPointCount(1)
    for i, craftInfo in ipairs(craftInfoList) do
        local buildingCell = self:_GetBuildingCell()
        buildingCell.transform.localPosition = Vector3(-(ITEM_CELL_WIDTH + ITEM_CELL_GAP_WIDTH) * columnCount - (ITEM_CELL_WIDTH + ITEM_CELL_GAP_WIDTH) / 2, -ITEM_CELL_HEIGHT * self.m_rowCountLeft, 0)
        local buildingArgs = {
            buildingId = craftInfo.buildingId,
            time = craftInfo.time,
            onClicked = function(id, cell)
                self:_OnCraftBuildingClicked(id, cell)
            end
        }
        buildingCell:InitWikiCraftingTreeBuilding(buildingArgs)
        local linkRightPoint = itemCell:GetLeftMountPoint(self.view.rootNode, 1)
        local linkLeftPoint = buildingCell:GetRightMountPoint(self.view.rootNode)
        self:_CreateLeftLink(linkLeftPoint, linkRightPoint)
        local buildingLeftPoint = buildingCell:GetLeftMountPoint(self.view.rootNode)
        for j, itemBundle in ipairs(craftInfo.incomes) do
            self:_CreateLeftCraft(itemBundle.id, columnCount + 1, buildingLeftPoint)
        end
    end
    self.m_craftItemIds[itemId] = false
end
WikiCraftingTreeCtrl._CreateRightCraft = HL.Method(HL.String) << function(self, itemId)
    local craftInfoList = FactoryUtils.getItemAsInputRecipeIds(itemId)
    local unlockedCraftInfoList = {}
    for _, craftInfo in pairs(craftInfoList) do
        if craftInfo.isUnlock then
            local buildingItemId = FactoryUtils.getBuildingItemId(craftInfo.buildingId)
            if not WikiUtils.getWikiEntryIdFromItemId(buildingItemId) or WikiUtils.canShowWikiEntry(buildingItemId) then
                table.insert(unlockedCraftInfoList, craftInfo)
            end
        end
    end
    if not unlockedCraftInfoList or #unlockedCraftInfoList == 0 then
        self.m_sourceItemCell:SetRightMountPointCount(0)
        return
    end
    local craftCount = #unlockedCraftInfoList
    self.m_sourceItemCell:SetRightMountPointCount(1)
    self.m_rowCountRight = 0
    self.m_columnCountRight = 1
    for i, craftInfo in pairs(unlockedCraftInfoList) do
        local buildingCell = self:_GetBuildingCell()
        buildingCell.transform.localPosition = Vector3((ITEM_CELL_WIDTH + ITEM_CELL_GAP_WIDTH) / 2, -ITEM_CELL_HEIGHT * self.m_rowCountRight, 0)
        local buildingArgs = {
            buildingId = craftInfo.buildingId,
            time = craftInfo.time,
            isShowExtraItemIcon = #craftInfo.incomes > 1,
            onClicked = function(id, cell)
                self:_OnCraftBuildingClicked(id, cell)
            end
        }
        buildingCell:InitWikiCraftingTreeBuilding(buildingArgs)
        local linkLeftPoint = self.m_sourceItemCell:GetRightMountPoint(self.view.rootNode, 1)
        local linkRightPoint = buildingCell:GetLeftMountPoint(self.view.rootNode)
        self:_CreateRightLink(linkLeftPoint, linkRightPoint)
        local buildingRightPoint = buildingCell:GetRightMountPoint(self.view.rootNode)
        for j, itemBundle in ipairs(craftInfo.outcomes) do
            local itemCell = self:_GetItemCell()
            itemCell.transform.localPosition = Vector3(ITEM_CELL_WIDTH + ITEM_CELL_GAP_WIDTH, -ITEM_CELL_HEIGHT * self.m_rowCountRight, 0)
            local itemArgs = {
                itemId = itemBundle.id,
                onClicked = function(id, cell)
                    self:_OnCraftItemClicked(id, cell)
                end
            }
            itemCell:InitWikiCraftingTreeItem(itemArgs)
            itemCell:SetLeftMountPointCount(1)
            itemCell:SetRightMountPointCount(0)
            local itemLeftPoint = itemCell:GetLeftMountPoint(self.view.rootNode.transform, 1)
            self:_CreateRightLink(buildingRightPoint, itemLeftPoint)
            self.m_rowCountRight = self.m_rowCountRight + 1
        end
    end
end
WikiCraftingTreeCtrl._OnCraftItemClicked = HL.Method(HL.String, HL.Forward("WikiCraftingTreeItem")) << function(self, itemId, itemCell)
    logger.info('itemId:', itemId)
    if self.m_selectedCell then
        self.m_selectedCell:SetSelected(false)
    end
    self.m_selectedCell = itemCell
    itemCell:SetSelected(true)
    self:_ActivateBottom(true)
    self:_RefreshBottom(itemId)
end
WikiCraftingTreeCtrl._OnCraftBuildingClicked = HL.Method(HL.String, HL.Forward("WikiCraftingTreeBuilding")) << function(self, buildingId, buildingCell)
    logger.info('buildingId:', buildingId)
    if self.m_selectedCell then
        self.m_selectedCell:SetSelected(false)
    end
    self.m_selectedCell = buildingCell
    buildingCell:SetSelected(true)
    local itemId = FactoryUtils.getBuildingItemId(buildingId)
    self:_ActivateBottom(true)
    self:_RefreshBottom(itemId)
end
WikiCraftingTreeCtrl._CreateLeftLink = HL.Method(Vector2, Vector2, HL.Opt(HL.Number)) << function(self, leftPoint, rightPoint, offset)
    if math.abs(leftPoint.y - rightPoint.y) < CREATE_LINE_THRESHOLD then
        self:_CreateLine(leftPoint, rightPoint)
    else
        self:_CreateLeftCurve(leftPoint, rightPoint, offset)
    end
end
WikiCraftingTreeCtrl._CreateRightLink = HL.Method(Vector2, Vector2, HL.Opt(HL.Number)) << function(self, leftPoint, rightPoint, offset)
    if math.abs(leftPoint.y - rightPoint.y) < CREATE_LINE_THRESHOLD then
        self:_CreateLine(leftPoint, rightPoint)
    else
        self:_CreateRightCurve(leftPoint, rightPoint, offset)
    end
end
WikiCraftingTreeCtrl._CreateLine = HL.Method(Vector2, Vector2) << function(self, pointStart, pointEnd)
    local lineCell = self:_GetLineCell()
    local pointMiddle = (pointStart + pointEnd) / 2
    lineCell.line.localPosition = Vector3(pointMiddle.x, pointMiddle.y, 0)
    lineCell.line.sizeDelta = Vector2(math.abs(pointEnd.x - pointStart.x), LINE_WIDTH)
end
local CURVE_WIDTH = 39
local CURVE_HEIGHT = 34
WikiCraftingTreeCtrl._CreateLeftCurve = HL.Method(Vector2, Vector2, HL.Opt(HL.Number)) << function(self, pointLeft, pointRight, offset)
    local curveCell = self:_GetCurveLeftCell()
    offset = offset or 0
    local lineHeight = math.abs(pointRight.y - pointLeft.y) - CURVE_HEIGHT * 2
    curveCell.verticalLine.sizeDelta = Vector2(lineHeight, LINE_WIDTH)
    local lineWidth = math.abs(pointRight.x - pointLeft.x) - CURVE_WIDTH * 2
    curveCell.topLine.sizeDelta = Vector2(offset, LINE_WIDTH)
    curveCell.bottomLine.sizeDelta = Vector2(lineWidth - offset, LINE_WIDTH)
    curveCell.transform.localPosition = Vector3(pointRight.x - offset - CURVE_WIDTH, (pointLeft.y + pointRight.y) / 2, 0)
end
WikiCraftingTreeCtrl._CreateRightCurve = HL.Method(Vector2, Vector2, HL.Opt(HL.Number)) << function(self, pointLeft, pointRight, offset)
    local curveCell = self:_GetCurveRightCell()
    offset = offset or 0
    local lineHeight = math.abs(pointRight.y - pointLeft.y) - CURVE_HEIGHT * 2
    curveCell.verticalLine.sizeDelta = Vector2(lineHeight, LINE_WIDTH)
    local lineWidth = math.abs(pointRight.x - pointLeft.x) - CURVE_WIDTH * 2
    curveCell.topLine.sizeDelta = Vector2(offset, LINE_WIDTH)
    curveCell.bottomLine.sizeDelta = Vector2(lineWidth - offset, LINE_WIDTH)
    curveCell.transform.localPosition = Vector3(pointLeft.x + offset + CURVE_WIDTH, (pointLeft.y + pointRight.y) / 2, 0)
end
WikiCraftingTreeCtrl._SetCurveCell = HL.Method(HL.Table, Vector2, Vector2, HL.Opt(HL.Number)) << function(self, curveCell, pointLeft, pointRight, offset)
    offset = offset or 0
    local lineHeight = math.abs(pointRight.y - pointLeft.y) - CURVE_HEIGHT * 2
    curveCell.verticalLine.sizeDelta = Vector2(lineHeight, 2)
    local lineWidth = (math.abs(pointRight.x - pointLeft.x) - CURVE_WIDTH * 2) / 2
    curveCell.topLine.sizeDelta = Vector2(offset, LINE_WIDTH)
    curveCell.bottomLine.sizeDelta = Vector2(lineWidth - offset, LINE_WIDTH)
    curveCell.transform.localPosition = Vector3((pointLeft.x + pointRight.x) / 2 + offset, (pointLeft.y + pointRight.y) / 2, 0)
end
WikiCraftingTreeCtrl._ActivateBottom = HL.Method(HL.Boolean) << function(self, active)
    local paddingBottom = 0
    if active then
        self.view.bottom.gameObject:SetActive(true)
        paddingBottom = self.view.bottom.rectTransform.rect.height
    else
        self.view.bottom.animWrapper:PlayOutAnimation(function()
            self.view.bottom.gameObject:SetActive(false)
            if self.m_selectedCell then
                self.m_selectedCell:SetSelected(false)
            end
        end)
    end
    local viewMaskPadding = self.view.viewportMask.padding
    viewMaskPadding.y = paddingBottom
    self.view.viewportMask.padding = viewMaskPadding
end
WikiCraftingTreeCtrl._RefreshBottom = HL.Method(HL.String) << function(self, itemId)
    local view = self.view.bottom
    local _, itemData = Tables.itemTable:TryGetValue(itemId)
    if not itemData then
        logger.error('WikiCraftingTreeCtrl._RefreshBottom: not itemData, ' .. itemId)
        return
    end
    view.nameTxt.text = itemData.name
    view.wikiItemImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, itemData.iconId)
    view.descTxt.text = itemData.desc
    view.itemTags:InitItemTags(itemId)
    local canShowWikiEntry = WikiUtils.canShowWikiEntry(itemId)
    view.detailBtn.gameObject:SetActive(canShowWikiEntry)
    view.detailBtn.onClick:RemoveAllListeners()
    view.detailBtn.onClick:AddListener(function()
        Notify(MessageConst.SHOW_WIKI_ENTRY, { itemId = itemId })
    end)
    view.cutBtn.gameObject:SetActive(canShowWikiEntry)
    view.cutBtn.onClick:RemoveAllListeners()
    view.cutBtn.onClick:AddListener(function()
        self:_ActivateBottom(false)
        self.m_wikiEntryShowData = WikiUtils.getWikiEntryShowDataFromItemId(itemId)
        self:_RefreshTop()
        self:_RefreshCraft(itemId)
    end)
end
HL.Commit(WikiCraftingTreeCtrl)