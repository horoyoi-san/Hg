local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacTechTree
local FAC_TECH_POINT_LACK_COLOR = "D25F69"
local SidebarType = { NodeDetails = 1, BlackboxList = 2, }
FacTechTreeCtrl = HL.Class('FacTechTreeCtrl', uiCtrl.UICtrl)
FacTechTreeCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.FAC_ON_REFRESH_TECH_TREE_UI] = 'OnRefreshUI', [MessageConst.FOCUS_TECH_TREE_NODE] = 'FocusTechTreeNode', [MessageConst.ZOOM_TO_FULL_TECH_TREE] = 'ZoomToFullTechTree', [MessageConst.FAC_ON_UNLOCK_TECH_TREE_UI] = 'OnUnlockNode', [MessageConst.FAC_ON_UNLOCK_TECH_TIER_UI] = 'OnUnlockTier', }
local facSTTGroupTable = Tables.facSTTGroupTable
local facSTTLayerTable = Tables.facSTTLayerTable
local facSTTNodeTable = Tables.facSTTNodeTable
local facSTTCategoryTable = Tables.facSTTCategoryTable
FacTechTreeCtrl.m_nodeCells = HL.Field(HL.Forward("UIListCache"))
FacTechTreeCtrl.m_lineCells = HL.Field(HL.Forward("UIListCache"))
FacTechTreeCtrl.m_layerCells = HL.Field(HL.Forward("UIListCache"))
FacTechTreeCtrl.m_categoryCells = HL.Field(HL.Forward("UIListCache"))
FacTechTreeCtrl.m_categoryLineCells = HL.Field(HL.Forward("UIListCache"))
FacTechTreeCtrl.m_targetCells = HL.Field(HL.Forward("UIListCache"))
FacTechTreeCtrl.m_getRewardCell = HL.Field(HL.Function)
FacTechTreeCtrl.m_curSelectNode = HL.Field(HL.Any)
FacTechTreeCtrl.m_nodeList = HL.Field(HL.Table)
FacTechTreeCtrl.m_lineList = HL.Field(HL.Table)
FacTechTreeCtrl.m_layerList = HL.Field(HL.Table)
FacTechTreeCtrl.m_categoryLineList = HL.Field(HL.Table)
FacTechTreeCtrl.m_rewardList = HL.Field(HL.Table)
FacTechTreeCtrl.m_recommendTechId = HL.Field(HL.String) << ""
FacTechTreeCtrl.m_popupArgs = HL.Field(HL.Table)
FacTechTreeCtrl.m_popupUIState = HL.Field(HL.Number) << 0
FacTechTreeCtrl.m_layerNode = HL.Field(HL.Table)
FacTechTreeCtrl.m_showSidebar = HL.Field(HL.Boolean) << false
FacTechTreeCtrl.m_isFocus = HL.Field(HL.Boolean) << false
FacTechTreeCtrl.m_packageName = HL.Field(HL.String) << ""
FacTechTreeCtrl.m_followTick = HL.Field(HL.Number) << -1
FacTechTreeCtrl.m_lastScale = HL.Field(HL.Number) << -1
FacTechTreeCtrl.m_getConsumeItemCell = HL.Field(HL.Function)
FacTechTreeCtrl.m_consumeItems = HL.Field(HL.Table)
FacTechTreeCtrl.m_blackboxCellCache = HL.Field(HL.Forward("UIListCache"))
FacTechTreeCtrl.m_getBlackboxCellFunc = HL.Field(HL.Function)
FacTechTreeCtrl.m_allBlackboxIds = HL.Field(HL.Table)
FacTechTreeCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:BindInputPlayerAction("fac_open_tech_tree", function()
        PhaseManager:PopPhase(PhaseId.FacTechTree)
    end)
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PhaseId.FacTechTree)
    end)
    local techId = arg.techId
    self.m_packageName = arg.packageId
    self.m_nodeCells = UIUtils.genCellCache(self.view.nodeCell)
    self.m_lineCells = UIUtils.genCellCache(self.view.lineCell)
    self.m_layerCells = UIUtils.genCellCache(self.view.layerCell)
    self.m_categoryCells = UIUtils.genCellCache(self.view.categoryCell)
    self.m_categoryLineCells = UIUtils.genCellCache(self.view.facTechTreeCategoryLineCell)
    self.m_curSelectNode = nil
    local unhiddenPackageCount = GameInstance.player.facTechTreeSystem:GetUnhiddenPackageCount()
    self.view.btnScene.gameObject:SetActiveIfNecessary(unhiddenPackageCount > 1)
    self.view.btnScene.onClick:AddListener(function()
        self:Notify(MessageConst.P_FAC_TECH_TREE_OPEN_PACKAGE_PANEL)
    end)
    self.view.btnBlackbox.onClick:AddListener(function()
        self:_OnBtnBlackboxClick()
    end)
    self.view.mask.gameObject:SetActiveIfNecessary(true)
    self.view.bigRectHelper.OnOpenTweenFinished:AddListener(function()
        self.view.mask.gameObject:SetActiveIfNecessary(false)
    end)
    self:_UpdateRecommendNode()
    self:_InitPanel()
    self:_StartCoroutine(function()
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.containerNode)
        coroutine.step()
        self.view.bigRectHelper:Init()
    end)
    self.view.touchPanelBtn.onClick:AddListener(function()
        self:_CloseSidebar()
    end)
    self.view.sidebar.gameObject:SetActiveIfNecessary(false)
    self.view.blackboxRedDot:InitRedDot("BlackboxEntry", self.m_packageName)
    local packageCfg = Tables.facSTTGroupTable[self.m_packageName]
    local detailNode = self.view.sidebar.facTechNodeDetail
    detailNode.nodeDetailReturnBtn.onClick:AddListener(function()
        self:_CloseSidebar()
    end)
    detailNode.relativeBtn.onClick:AddListener(function()
        self:_OnRelativeBtnClick()
    end)
    detailNode.packUpBtn.onClick:AddListener(function()
        self:_OnPackUpBtnClick()
    end)
    self.m_targetCells = UIUtils.genCellCache(detailNode.targetCell)
    self.m_getRewardCell = UIUtils.genCachedCellFunction(detailNode.rewardList)
    self.m_getConsumeItemCell = UIUtils.genCachedCellFunction(detailNode.consumeList)
    self.m_blackboxCellCache = UIUtils.genCellCache(detailNode.blackboxCell)
    detailNode.rewardList.onUpdateCell:AddListener(function(object, csIndex)
        local cell = self.m_getRewardCell(object)
        self:_OnUpdateRewardsCell(cell, LuaIndex(csIndex))
    end)
    detailNode.consumeList.onUpdateCell:AddListener(function(go, csIndex)
        local cell = self.m_getConsumeItemCell(go)
        self:_OnUpdateConsumeCell(cell, LuaIndex(csIndex))
    end)
    detailNode.techPointBtn.onClick:AddListener(function()
        self:_OnCostPointClick()
    end)
    detailNode.costPointBg.onClick:AddListener(function()
        self:_OnCostPointClick()
    end)
    FactoryUtils.updateFacTechTreeTechPointNode(detailNode.resourceNode, self.m_packageName)
    FactoryUtils.updateFacTechTreeTechPointNode(self.view.resourceNode, self.m_packageName)
    local blackboxOverview = self.view.sidebar.blackboxOverview
    self.m_allBlackboxIds = FactoryUtils.getBlackboxInfoTbl(packageCfg.blackboxIds)
    self.m_getBlackboxCellFunc = UIUtils.genCachedCellFunction(blackboxOverview.blackboxScrollList)
    blackboxOverview.blackboxOverviewReturnBtn.onClick:AddListener(function()
        self:_CloseSidebar()
    end)
    blackboxOverview.blackboxScrollList.onUpdateCell:AddListener(function(gameObject, csIndex)
        local cell = self.m_getBlackboxCellFunc(gameObject)
        local info = self.m_allBlackboxIds[LuaIndex(csIndex)]
        self:_OnUpdateBlackboxCell(cell, info)
    end)
    blackboxOverview.filterBtn.onClick:AddListener(function()
        local args = self:_GenFilterArgs()
        self:Notify(MessageConst.SHOW_COMMON_FILTER, args)
    end)
    FactoryUtils.updateFacTechTreeTechPointNode(blackboxOverview.resourceNode, self.m_packageName)
    self:AutoSelect(techId)
end
FacTechTreeCtrl.OnClose = HL.Override() << function(self)
    Notify(MessageConst.CLOSE_TECH_TREE_POP_UP)
    if self.m_followTick > 0 then
        LuaUpdate:Remove(self.m_followTick)
        self.m_followTick = -1
    end
end
FacTechTreeCtrl.OnRefreshUI = HL.Method() << function(self)
    if not self.m_showSidebar then
        return
    end
    self:_RefreshNodeDetail()
end
FacTechTreeCtrl.OnUnlockTier = HL.Method() << function(self)
    AudioAdapter.PostEvent("Au_UI_Event_FacTechTree_Unlock")
    for _, layer in ipairs(self.m_layerList) do
        layer.layerCell:Refresh()
    end
    for _, categoryLine in ipairs(self.m_categoryLineList) do
        categoryLine.categoryLineCell:Refresh()
    end
    self:_UpdateRecommendNode()
    for _, node in ipairs(self.m_nodeList) do
        node.nodeCell:Refresh(node.techId == self.m_recommendTechId)
    end
    self:_RefreshLine(false)
end
FacTechTreeCtrl.OnUnlockNode = HL.Method() << function(self)
    local techTreeSystem = GameInstance.player.facTechTreeSystem
    self:_UpdateRecommendNode()
    self:_RefreshLine(false)
    self:_CloseSidebar()
    FactoryUtils.updateFacTechTreeTechPointCount(self.view.resourceNode, self.m_packageName)
    FactoryUtils.updateFacTechTreeTechPointCount(self.view.sidebar.facTechNodeDetail.resourceNode, self.m_packageName)
    local unlockItems = {}
    local rewardsItems = {}
    local buildingInfo = {}
    local techId = self.m_curSelectNode.techId
    local techData = facSTTNodeTable:GetValue(techId)
    for _, rewardData in pairs(techData.unlockReward) do
        if rewardData.count <= 0 then
            table.insert(unlockItems, rewardData.itemId)
        else
            table.insert(rewardsItems, { id = rewardData.itemId, count = rewardData.count })
        end
    end
    buildingInfo.buildingId = techTreeSystem:GetBuildingName(techId)
    buildingInfo.level = techTreeSystem:GetBuildingLevel(techId)
    local args = {
        techId = techId,
        unlockItems = unlockItems,
        rewardsItems = rewardsItems,
        buildingInfo = buildingInfo,
        onHideCb = function()
            for _, node in ipairs(self.m_nodeList) do
                node.nodeCell:Refresh(node.techId == self.m_recommendTechId)
            end
        end,
    }
    self.m_popupArgs = args
    self.m_popupUIState = 0
    self.view.bigRectHelper:FocusNode(self.m_curSelectNode.transform.localPosition.x, self.m_curSelectNode.transform.localPosition.y, function()
        self:_ShowUnlock()
    end)
    CS.Beyond.Gameplay.Audio.AudioRemoteFactoryAnnouncement.Announcement("au_fac_announcement_techtree_unlock")
end
FacTechTreeCtrl.OnRefreshNodeName = HL.Method(HL.Boolean) << function(self, show)
    local nodeList = self.m_nodeList
    for _, node in ipairs(nodeList) do
        node.nodeCell:OnShowNameStateChange(show)
    end
end
FacTechTreeCtrl.FocusTechTreeNode = HL.Method(HL.Table) << function(self, args)
    local techId = unpack(args)
    self:_FocusTechTreeNode(techId)
end
FacTechTreeCtrl.ZoomToFullTechTree = HL.Method() << function(self)
    self.view.bigRectHelper:ZoomToFullRect(function()
    end)
end
FacTechTreeCtrl.AutoSelect = HL.Method(HL.Opt(HL.String)) << function(self, techId)
    if string.isEmpty(techId) then
        return
    end
    local nodeData
    for _, node in ipairs(self.m_nodeList) do
        if node.techId == techId then
            nodeData = node
            break
        end
    end
    self:_StartCoroutine(function()
        coroutine.wait(0.5)
        self:_OnClickNode(nodeData.nodeCell)
    end)
end
FacTechTreeCtrl._InitPanel = HL.Method() << function(self)
    local cellWidth = self.view.nodeCell.rectTransform.rect.width
    local cellHeight = self.view.nodeCell.rectTransform.rect.height
    local X_DIS = cellWidth + self.view.config.HORIZ_SPACE
    local Y_DIS = cellHeight + self.view.config.VERT_SPACE
    local X_ORI = self.view.config.X_ORI
    local Y_ORI = self.view.config.Y_ORI
    local LINE_WEIGHT = self.view.config.LINE_WIDTH
    local packageCfg = facSTTGroupTable[self.m_packageName]
    local categoryPadding = packageCfg.categoryPadding
    local layerPadding = packageCfg.layerPadding
    local nodeList = {}
    local lineList = {}
    local layerList = {}
    local categoryList = {}
    local categoryLineList = {}
    local layerNode = {}
    self.m_nodeList = nodeList
    self.m_lineList = lineList
    self.m_layerList = layerList
    self.m_categoryLineList = categoryLineList
    self.m_layerNode = layerNode
    local maxX = 0
    for categoryId, categoryCfg in pairs(facSTTCategoryTable) do
        if categoryCfg.groupId == self.m_packageName then
            local categoryCfgSizeX = (categoryCfg.containsXCount - 1) * X_DIS + (categoryPadding * 2 + 1) * cellWidth
            table.insert(categoryList, { categoryId = categoryId, name = categoryCfg.name, order = categoryCfg.order, containsXCount = categoryCfg.containsXCount, sizeX = categoryCfgSizeX, })
            maxX = maxX + categoryCfgSizeX
        end
    end
    table.sort(categoryList, Utils.genSortFunction({ "order" }, true))
    for layerId, layerCfg in pairs(facSTTLayerTable) do
        if layerCfg.groupId == self.m_packageName then
            table.insert(layerList, { layerId = layerId, name = layerCfg.name, order = layerCfg.order, containsYCount = layerCfg.containsYCount, sizeY = (layerCfg.containsYCount - 1) * Y_DIS + (layerPadding * 2 + 1) * cellHeight, isTBD = layerCfg.isTBD, })
        end
    end
    table.sort(layerList, Utils.genSortFunction({ "order" }, true))
    local currentYOri = self.view.config.Y_ORI
    local currentXOri = self.view.config.X_ORI
    local accumulateHeight = 0
    local accumulateCellCountY = 0
    for _, layer in ipairs(layerList) do
        local calcPosY = currentYOri - layer.sizeY / 2
        local accumulateWidth = 0
        local accumulateCellCountX = 0
        for _, category in ipairs(categoryList) do
            local calcPosX = currentXOri + category.sizeX
            table.insert(categoryLineList, { layerId = layer.layerId, width = self.view.config.CATEGORY_LINE_WIDTH, height = layer.containsYCount * Y_DIS, posX = calcPosX, posY = calcPosY, })
            currentXOri = calcPosX
            category.accumulateWidth = accumulateWidth
            accumulateWidth = accumulateWidth + category.sizeX
            category.firstCellX = accumulateCellCountX
            accumulateCellCountX = accumulateCellCountX + category.containsXCount
        end
        currentXOri = self.view.config.X_ORI
        currentYOri = currentYOri - layer.sizeY
        layer.accumulateHeight = accumulateHeight
        accumulateHeight = accumulateHeight + layer.sizeY
        layer.firstCellY = accumulateCellCountY
        accumulateCellCountY = accumulateCellCountY + layer.containsYCount
    end
    self.m_categoryCells:Refresh(#categoryList, function(cell, index)
        local categoryVO = categoryList[index]
        categoryVO.categoryCell = cell
        cell.categoryTxt.text = categoryVO.name
        cell.rectTransform.sizeDelta = Vector2(categoryVO.sizeX, cell.rectTransform.sizeDelta.y)
    end)
    self.m_layerCells:Refresh(#layerList, function(cell, index)
        local layerVO = layerList[index]
        layerVO.layerCell = cell
        cell:InitFacTechTreeLayerCell(layerVO.layerId, maxX + X_ORI, layerVO.sizeY, function()
            self:_OnClickLayer(layerList[index].layerId)
        end)
        layerNode[layerVO.layerId] = {}
    end)
    self.m_categoryLineCells:Refresh(#categoryLineList, function(cell, index)
        local categoryLineVO = categoryLineList[index]
        categoryLineVO.categoryLineCell = cell
        cell:InitFacTechTreeCategoryLineCell(categoryLineVO)
    end)
    for techId, nodeData in pairs(facSTTNodeTable) do
        if nodeData.groupId == self.m_packageName then
            local calc = function(nodeData, isVertical)
                if isVertical then
                    local ownerLayer = facSTTLayerTable[nodeData.layer]
                    local layer = layerList[ownerLayer.order]
                    return Y_ORI - layer.accumulateHeight - (nodeData.uiPos[1] - layer.firstCellY) * Y_DIS - (layerPadding + 0.5) * cellHeight
                else
                    local ownerCategory = facSTTCategoryTable[nodeData.category]
                    local category = categoryList[ownerCategory.order]
                    return X_ORI + category.accumulateWidth + (nodeData.uiPos[0] - category.firstCellX) * X_DIS + (categoryPadding + 0.5) * cellWidth
                end
            end
            local x = calc(nodeData, false)
            local y = calc(nodeData, true)
            table.insert(nodeList, { techId = techId, layer = nodeData.layer, x = x, y = y, })
            for _, preNodeId in pairs(nodeData.preNode) do
                if not string.isEmpty(preNodeId) then
                    local preNodeData = facSTTNodeTable:GetValue(preNodeId)
                    local upX = calc(preNodeData, false)
                    local upY = calc(preNodeData, true)
                    table.insert(lineList, { techId = techId, preNodeLayer = preNodeData.layer, upX = upX, upY = upY, downX = x, downY = y, lineWeight = LINE_WEIGHT, yDis = Y_DIS, })
                end
            end
        end
    end
    self:_RefreshLine(true)
    self.m_nodeCells:Refresh(#nodeList, function(cell, index)
        local nodeVO = nodeList[index]
        nodeVO.nodeCell = cell
        cell:InitFacTechTreeNode(nodeVO.techId, nodeVO.x, nodeVO.y, nodeVO.techId == self.m_recommendTechId, function(node)
            self:_OnClickNode(node, true)
        end)
        cell:OnSelect(false)
        table.insert(layerNode[nodeVO.layer], cell)
    end)
    self.view.nameText.text = UIUtils.resolveTextStyle(packageCfg.groupName)
    self.view.bigRectHelper.zoomEvent:AddListener(function(csIndex, isLarger)
        if csIndex == 0 then
            self:OnRefreshNodeName(isLarger)
        end
    end)
    self.m_followTick = LuaUpdate:Add("TailTick", function()
        local targetPos = self.view.categoryPivot.position
        local followerPos = self.view.directory.position
        self.view.directory.position = Vector3(targetPos.x, followerPos.y, followerPos.z)
        local scale = self.view.containerNode.localScale.x
        if math.abs(self.m_lastScale - scale) > 0.001 then
            local newPaddingLeft = lume.round(self.view.config.X_ORI * scale)
            self.view.directoryHorizontalLayoutGroup.padding.left = newPaddingLeft
            for _, category in ipairs(categoryList) do
                local sizeDelta = category.categoryCell.rectTransform.sizeDelta
                category.categoryCell.rectTransform.sizeDelta = Vector2(category.sizeX * scale, sizeDelta.y)
            end
            LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.directory)
            self.m_lastScale = scale
        end
    end)
end
FacTechTreeCtrl._UpdateRecommendNode = HL.Method() << function(self)
    local recommendTechId = ""
    local minSort = math.maxinteger
    local techTreeSystem = GameInstance.player.facTechTreeSystem
    for techId, nodeData in pairs(facSTTNodeTable) do
        if nodeData.groupId == self.m_packageName then
            local layerIsLocked = techTreeSystem:LayerIsLocked(nodeData.layer)
            local isPreNodeLocked = nodeData.preNode.Count > 0 and techTreeSystem:PreNodeIsLocked(techId)
            if not layerIsLocked and not isPreNodeLocked and techTreeSystem:NodeIsLocked(techId) then
                if nodeData.sortId < minSort then
                    minSort = nodeData.sortId
                    recommendTechId = techId
                end
            end
        end
    end
    self.m_recommendTechId = recommendTechId
end
FacTechTreeCtrl._RefreshLine = HL.Method(HL.Opt(HL.Boolean)) << function(self, isInit)
    local lineList = self.m_lineList
    local techTreeSystem = GameInstance.player.facTechTreeSystem
    for _, line in ipairs(lineList) do
        if techTreeSystem:NodeIsLocked(line.techId) then
            line.lineOrder = 0
        else
            line.lineOrder = 1
        end
    end
    table.sort(lineList, Utils.genSortFunction({ "lineOrder" }, true))
    self.m_lineCells:Refresh(#lineList, function(cell, index)
        cell:InitFacTechTreeLineCell(lineList[index])
        lineList[index].line = cell
        if isInit then
            cell.view.animationWrapper:SampleClipAtPercent("factechtreeline_in", 0)
            table.insert(self.m_layerNode[lineList[index].preNodeLayer], cell)
        end
    end)
end
FacTechTreeCtrl._OnClickLayer = HL.Method(HL.String) << function(self, layerId)
    local isLocked = GameInstance.player.facTechTreeSystem:LayerIsLocked(layerId)
    if not isLocked or string.isEmpty(Tables.facSTTLayerTable[layerId].preLayer) then
        return
    end
    UIManager:Open(PanelId.FacTechTreeUnlockTierPopup, { layerId })
end
FacTechTreeCtrl._OnClickNode = HL.Method(HL.Any, HL.Opt(HL.Boolean)) << function(self, node, playSound)
    local lastNode = self.m_curSelectNode
    if lastNode ~= nil and lastNode ~= node then
        lastNode:OnSelect(false)
    end
    self.m_curSelectNode = node
    node:OnSelect(true)
    self:_OpenNodeDetail()
    self:_RefreshNodeDetail()
    if playSound then
        AudioManager.PostEvent("au_ui_btn_techtree")
    end
end
FacTechTreeCtrl._RefreshNodeDetail = HL.Method() << function(self)
    local detailNode = self.view.sidebar.facTechNodeDetail
    local techId = self.m_curSelectNode.techId
    local nodeData = facSTTNodeTable:GetValue(techId)
    local posX = 0
    local posY = 0
    for _, node in ipairs(self.m_nodeList) do
        if node.techId == techId then
            posX = node.x
            posY = node.y
        end
    end
    self.view.bigRectHelper:Move(self.view.sidebar.rectTransform.sizeDelta.x, posX, posY)
    detailNode.techNameTxt.text = nodeData.name
    detailNode.techIcon:LoadSprite(UIConst.UI_SPRITE_FAC_TECH_ICON, nodeData.icon)
    detailNode.desc.text = UIUtils.resolveTextStyle(nodeData.desc)
    local techTreeSystem = GameInstance.player.facTechTreeSystem
    local isLocked = techTreeSystem:NodeIsLocked(techId)
    local conditions = nodeData.conditions
    if not isLocked or conditions.Count <= 0 then
        detailNode.conditionNode.gameObject:SetActiveIfNecessary(false)
    else
        detailNode.conditionNode.gameObject:SetActiveIfNecessary(true)
        self.m_targetCells:Refresh(nodeData.conditions.Count, function(item, index)
            self:_RefreshConditions(item, index)
        end)
    end
    local costItems = nodeData.costItems
    local hasCost = costItems.Count > 0
    local consumeList = {}
    detailNode.consumeNode.gameObject:SetActiveIfNecessary(hasCost)
    for _, itemBundle in pairs(costItems) do
        local consumeItem = {}
        consumeItem.id = itemBundle.id
        consumeItem.count = itemBundle.count
        consumeItem.ownCount = Utils.getItemCount(itemBundle.id)
        table.insert(consumeList, consumeItem)
    end
    self.m_consumeItems = consumeList
    detailNode.consumeList:UpdateCount(#consumeList)
    local rewardList = {}
    for i = 0, nodeData.unlockReward.Count - 1 do
        local rewardData = nodeData.unlockReward[i]
        local itemId = rewardData.itemId
        local count = rewardData.count
        if not string.isEmpty(itemId) then
            table.insert(rewardList, { itemId = itemId, count = count })
        end
    end
    self.m_rewardList = rewardList
    detailNode.rewardList:UpdateCount(#rewardList)
    detailNode.unlockInfoNode.gameObject:SetActiveIfNecessary(isLocked)
    if isLocked then
        local packageCfg = facSTTGroupTable[self.m_packageName]
        local costCount = nodeData.costPointCount
        local ownCount = Utils.getItemCount(packageCfg.costPointType)
        local techPointItemCfg = Tables.itemTable[packageCfg.costPointType]
        local countStr = string.format("%s/%s", ownCount, costCount)
        if costCount > ownCount then
            countStr = string.format(UIConst.COLOR_STRING_FORMAT, FAC_TECH_POINT_LACK_COLOR, countStr)
        end
        detailNode.unlockInfoTxt.text = countStr
        detailNode.techPointIcon:LoadSprite(UIConst.UI_SPRITE_ITEM, techPointItemCfg.iconId)
    end
    detailNode.animationWrapper:SampleToOutAnimationEnd()
    self:_RefreshUnlockButton()
end
FacTechTreeCtrl._RefreshUnlockButton = HL.Method() << function(self)
    local detailNode = self.view.sidebar.facTechNodeDetail
    local techId = self.m_curSelectNode.techId
    local techTreeSystem = GameInstance.player.facTechTreeSystem
    local nodeData = facSTTNodeTable:GetValue(techId)
    local groupData = facSTTGroupTable:GetValue(nodeData.groupId)
    local techPointItemCfg = Tables.itemTable[groupData.costPointType]
    local locked = techTreeSystem:NodeIsLocked(techId)
    detailNode.finishNode.gameObject:SetActiveIfNecessary(not locked)
    detailNode.unlockBtn.gameObject:SetActiveIfNecessary(locked)
    detailNode.relativeBtn.gameObject:SetActiveIfNecessary(nodeData.blackboxIds.Count > 0)
    if locked then
        local isMatchCondition = true
        if nodeData.conditions.Count > 0 then
            for i = 1, nodeData.conditions.Count do
                if not techTreeSystem:GetConditionIsCompleted(techId, nodeData.conditions[CSIndex(i)].conditionId) then
                    isMatchCondition = false
                    break
                end
            end
        end
        local costItemEnough = true
        if nodeData.conditions.Count > 0 then
            for i = 1, nodeData.costItems.Count do
                local costItemBundle = nodeData.costItems[CSIndex(i)]
                if Utils.getItemCount(costItemBundle.id) < costItemBundle.count then
                    costItemEnough = false
                    break
                end
            end
        end
        local pointEnough = Utils.getItemCount(groupData.costPointType) >= nodeData.costPointCount
        detailNode.unlockBtn.onClick:RemoveAllListeners()
        detailNode.unlockBtn.onClick:AddListener(function()
            AudioManager.PostEvent("au_ui_fac_techtree_node_unlock")
            local canUnlock = false
            local conditionText
            if techTreeSystem:LayerIsLocked(nodeData.layer) then
                local layerData = facSTTLayerTable:GetValue(nodeData.layer)
                conditionText = string.format(Language.LUA_FAC_TECHTREE_FAILED_TOAST_3, layerData.name)
            elseif techTreeSystem:PreNodeIsLocked(techId) then
                conditionText = Language.LUA_FAC_TECHTREE_FAILED_TOAST_4
            elseif not isMatchCondition then
                conditionText = Language.LUA_FAC_TECHTREE_FAILED_TOAST_1
            elseif not pointEnough then
                conditionText = string.format(Language.LUA_FAC_TECHTREE_FAILED_TOAST_5, techPointItemCfg.name)
            elseif not costItemEnough then
                conditionText = Language.LUA_FAC_TECHTREE_FAILED_TOAST_2
            else
                canUnlock = true
            end
            if not canUnlock then
                self:Notify(MessageConst.SHOW_TOAST, conditionText)
            else
                if self.m_isFocus then
                    return
                end
                local techId = self.m_curSelectNode.techId
                GameInstance.player.facTechTreeSystem:SendUnlockNodeMsg(techId)
            end
        end)
    end
end
FacTechTreeCtrl._OnUpdateRewardsCell = HL.Method(HL.Any, HL.Number) << function(self, cell, luaIndex)
    local techId = self.m_curSelectNode.techId
    local techTreeSystem = GameInstance.player.facTechTreeSystem
    local rewardData = self.m_rewardList[luaIndex]
    local count = rewardData.count
    local itemId = rewardData.itemId
    if count > 0 then
        cell:InitItem({ id = itemId, count = count }, function()
            self:_OnClickShowRewardItemTips(itemId)
        end)
    else
        cell:InitItem({ id = itemId }, function()
            self:_OnClickShowRewardItemTips(itemId)
        end)
    end
    cell.view.rewardedCover.gameObject:SetActiveIfNecessary(not techTreeSystem:NodeIsLocked(techId))
end
FacTechTreeCtrl._OnUpdateConsumeCell = HL.Method(HL.Any, HL.Number) << function(self, cell, luaIndex)
    local consumeItemData = self.m_consumeItems[luaIndex]
    cell.ownTxt.text = consumeItemData.ownCount
    cell.item:InitItem({ id = consumeItemData.id, count = consumeItemData.count }, function()
        self:_OnClickShowRewardItemTips(consumeItemData.id)
    end)
end
FacTechTreeCtrl._OnCostPointClick = HL.Method() << function(self)
    local packageCfg = Tables.facSTTGroupTable[self.m_packageName]
    self:Notify(MessageConst.SHOW_ITEM_TIPS, { itemId = packageCfg.costPointType, transform = self.view.sidebar.facTechNodeDetail.techPointBtn.transform, posType = UIConst.UI_TIPS_POS_TYPE.LeftMid, notPenetrate = true, })
end
FacTechTreeCtrl._OnClickShowRewardItemTips = HL.Method(HL.String) << function(self, itemId)
    self:Notify(MessageConst.SHOW_ITEM_TIPS, { itemId = itemId, transform = self.view.sidebar.transform, posType = UIConst.UI_TIPS_POS_TYPE.LeftMid, notPenetrate = true, })
end
FacTechTreeCtrl._RefreshConditions = HL.Method(HL.Table, HL.Number) << function(self, item, index)
    local techId = self.m_curSelectNode.techId
    local nodeData = facSTTNodeTable:GetValue(techId)
    local techTreeSystem = GameInstance.player.facTechTreeSystem
    local conditions = nodeData.conditions
    local condition = conditions[CSIndex(index)]
    local progress = techTreeSystem:GetConditionProgress(techId, condition.conditionId)
    local total = techTreeSystem:GetConditionTotalProgress(condition.conditionId)
    local progress = string.format("(%1$d/%2$d)", progress, total)
    item.desc.text = condition.desc .. " " .. progress
    item.descNormal.text = condition.desc .. " " .. progress
    item.normal.gameObject:SetActiveIfNecessary(not techTreeSystem:GetConditionIsCompleted(techId, condition.conditionId))
    item.complete.gameObject:SetActiveIfNecessary(techTreeSystem:GetConditionIsCompleted(techId, condition.conditionId))
end
FacTechTreeCtrl._OnRelativeBtnClick = HL.Method() << function(self)
    local techId = self.m_curSelectNode.techId
    local nodeData = facSTTNodeTable:GetValue(techId)
    local relativeBlackboxes = FactoryUtils.getBlackboxInfoTbl(nodeData.blackboxIds)
    if #relativeBlackboxes > 0 then
        self:_ToggleTechNodeRelativeBlackboxPanel(true)
        self.m_blackboxCellCache:Refresh(#relativeBlackboxes, function(cell, luaIndex)
            local info = relativeBlackboxes[luaIndex]
            self:_OnUpdateBlackboxCell(cell, info)
        end)
    else
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_TECH_TREE_NO_RELATIVE_BLACKBOX_TOAST_DESC)
    end
end
FacTechTreeCtrl._ToggleTechNodeRelativeBlackboxPanel = HL.Method(HL.Boolean) << function(self, isOn)
    local detailNode = self.view.sidebar.facTechNodeDetail
    if isOn then
        detailNode.animationWrapper:PlayInAnimation()
    else
        detailNode.animationWrapper:PlayOutAnimation()
    end
end
FacTechTreeCtrl._OnUpdateBlackboxCell = HL.Method(HL.Any, HL.Table) << function(self, cell, info)
    cell.name1.text = info.name
    cell.name2.text = info.name
    cell.node1.gameObject:SetActiveIfNecessary(not info.isComplete and info.isActive)
    cell.node2.gameObject:SetActiveIfNecessary(info.isComplete or not info.isActive)
    cell.completeIcon.gameObject:SetActiveIfNecessary(info.isComplete)
    cell.lockIcon.gameObject:SetActiveIfNecessary(info.isActive and not info.isUnlock)
    cell.locationIcon.gameObject:SetActiveIfNecessary(not info.isActive)
    cell.gotoIcon.gameObject:SetActiveIfNecessary(info.isActive)
    cell.button.onClick:RemoveAllListeners()
    cell.button.onClick:AddListener(function()
        if info.isActive then
            PhaseManager:OpenPhase(PhaseId.BlackboxEntry, { packageId = self.m_packageName, blackboxId = info.blackboxId })
        else
            MapUtils.openMap(info.markInstId)
        end
    end)
end
FacTechTreeCtrl._OnPackUpBtnClick = HL.Method() << function(self)
    self:_ToggleTechNodeRelativeBlackboxPanel(false)
end
FacTechTreeCtrl._OpenNodeDetail = HL.Method() << function(self)
    self:_ShowSideBar(SidebarType.NodeDetails)
    self:_ToggleTechNodeRelativeBlackboxPanel(false)
    self.view.sidebar.facTechNodeDetail.animationWrapper:SampleToOutAnimationEnd()
end
FacTechTreeCtrl._OpenBlackboxOverview = HL.Method() << function(self)
    self:_ShowSideBar(SidebarType.BlackboxList)
    local blackboxOverview = self.view.sidebar.blackboxOverview
    local count = #self.m_allBlackboxIds
    blackboxOverview.blackboxScrollList:UpdateCount(count)
    blackboxOverview.contentNode.gameObject:SetActiveIfNecessary(count > 0)
    blackboxOverview.emptyNode.gameObject:SetActiveIfNecessary(count == 0)
end
FacTechTreeCtrl._ShowSideBar = HL.Method(HL.Number) << function(self, sidebarType)
    self.m_showSidebar = true
    self.view.btnBlackbox.gameObject:SetActiveIfNecessary(false)
    self.view.sidebar.gameObject:SetActiveIfNecessary(true)
    self.view.sidebar.facTechNodeDetail.gameObject:SetActiveIfNecessary(sidebarType == SidebarType.NodeDetails)
    self.view.sidebar.blackboxOverview.gameObject:SetActiveIfNecessary(sidebarType == SidebarType.BlackboxList)
end
FacTechTreeCtrl._CloseSidebar = HL.Method(HL.Opt(HL.Function)) << function(self, onFinish)
    if self.m_showSidebar == false then
        return
    end
    self.m_showSidebar = false
    self.view.btnBlackbox.gameObject:SetActiveIfNecessary(true)
    if self.m_curSelectNode then
        self.m_curSelectNode:OnSelect(false)
    end
    self.view.bigRectHelper:Move(0, 0, 0, true)
    self.view.sidebar.animationWrapper:PlayOutAnimation(function()
        self.view.sidebar.gameObject:SetActiveIfNecessary(false)
        if onFinish then
            onFinish()
        end
    end)
end
FacTechTreeCtrl._GenFilterArgs = HL.Method().Return(HL.Table) << function(self)
    return FactoryUtils.genFilterBlackboxArgs(self.m_packageName, function(selectedTags)
        self:_OnFilterConfirm(selectedTags)
    end)
end
FacTechTreeCtrl._OnFilterConfirm = HL.Method(HL.Table) << function(self, selectedTags)
    selectedTags = selectedTags or {}
    local blackboxOverview = self.view.sidebar.blackboxOverview
    local ids = FactoryUtils.getFilterBlackboxIds(self.m_packageName, selectedTags)
    self.m_allBlackboxIds = FactoryUtils.getBlackboxInfoTbl(ids)
    local hasFilterResult = #ids > 0
    blackboxOverview.contentNode.gameObject:SetActiveIfNecessary(hasFilterResult)
    blackboxOverview.emptyNode.gameObject:SetActiveIfNecessary(not hasFilterResult)
    blackboxOverview.hasFilter.gameObject:SetActiveIfNecessary(#selectedTags > 0)
    if hasFilterResult then
        blackboxOverview.blackboxScrollList:UpdateCount(#ids)
    end
end
FacTechTreeCtrl._OnBtnBlackboxClick = HL.Method() << function(self)
    PhaseManager:OpenPhase(PhaseId.BlackboxEntry, { packageId = self.m_packageName })
end
FacTechTreeCtrl._ShowUnlock = HL.Method() << function(self)
    local args = self.m_popupArgs
    if #args.unlockItems > 0 then
        self.m_popupUIState = self.m_popupUIState + 1
        Notify(MessageConst.SHOW_TECH_TREE_POP_UP, {
            techId = args.techId,
            unlockItems = args.unlockItems,
            state = self.m_popupUIState,
            onStageFinishCb = function()
                self:_ShowLevelUp()
            end
        })
    else
        self:_ShowLevelUp()
    end
end
FacTechTreeCtrl._ShowLevelUp = HL.Method() << function(self)
    local args = self.m_popupArgs
    if not string.isEmpty(args.buildingInfo.buildingId) then
        self.m_popupUIState = self.m_popupUIState + 1
        Notify(MessageConst.SHOW_TECH_TREE_POP_UP, {
            techId = args.techId,
            buildingInfo = args.buildingInfo,
            state = self.m_popupUIState,
            onStageFinishCb = function()
                self:_ShowRewards()
            end
        })
    else
        self:_ShowRewards()
    end
end
FacTechTreeCtrl._ShowRewards = HL.Method() << function(self, args)
    local args = self.m_popupArgs
    if #args.rewardsItems > 0 then
        self.m_popupUIState = self.m_popupUIState + 1
        Notify(MessageConst.SHOW_TECH_TREE_POP_UP, {
            techId = args.techId,
            state = self.m_popupUIState,
            rewardsItems = args.rewardsItems,
            onStageFinishCb = function()
                self:_HidePopup()
            end
        })
    else
        self:_HidePopup()
    end
end
FacTechTreeCtrl._HidePopup = HL.Method() << function(self)
    if self.m_popupUIState > 0 then
        Notify(MessageConst.HIDE_TECH_TREE_POP_UP, {
            onHide = function()
                if self.m_popupArgs.onHideCb then
                    self.m_popupArgs.onHideCb()
                end
            end
        })
    end
    self.m_popupUIState = 0
end
FacTechTreeCtrl._FocusTechTreeNode = HL.Method(HL.String) << function(self, techId)
    for _, node in ipairs(self.m_nodeList) do
        if node.techId == techId then
            self:_OnClickNode(node.nodeCell, false)
            self.m_isFocus = true
            self.view.bigRectHelper:FocusNode(node.x, node.y, function()
                self.m_isFocus = false
            end)
            break
        end
    end
end
HL.Commit(FacTechTreeCtrl)