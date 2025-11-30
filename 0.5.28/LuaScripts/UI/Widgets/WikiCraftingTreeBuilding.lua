local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
WikiCraftingTreeBuilding = HL.Class('WikiCraftingTreeBuilding', UIWidgetBase)
WikiCraftingTreeBuilding.m_args = HL.Field(HL.Table)
WikiCraftingTreeBuilding.m_nodeView = HL.Field(HL.Table)
WikiCraftingTreeBuilding._OnFirstTimeInit = HL.Override() << function(self)
    if self.m_args.onClicked then
        self.view.button.onClick:AddListener(function()
            self.m_args.onClicked(self.m_args.buildingId, self)
        end)
    end
end
WikiCraftingTreeBuilding.InitWikiCraftingTreeBuilding = HL.Method(HL.Table) << function(self, args)
    self.m_args = args
    self:_FirstTimeInit()
    local hasTime = args.time and args.time > 0
    self.view.timeNode.gameObject:SetActive(hasTime)
    if hasTime then
        self.view.timeTxt.text = string.format("%.1f s", args.time)
    end
    local name, iconFolder, iconId
    if not args.buildingId then
        name = Language.LUA_OBTAIN_WAYS_MANUAL_CRAFT_NAME
        iconFolder = UIConst.UI_SPRITE_ITEM_TIPS
        iconId = UIConst.UI_MANUALCRAFT_ICON_ID
    else
        local _, buildingData = Tables.factoryBuildingTable:TryGetValue(args.buildingId)
        if buildingData then
            name = buildingData.name
            iconFolder = UIConst.UI_SPRITE_FAC_BUILDING_PANEL_ICON
            iconId = buildingData.iconOnPanel
        end
    end
    local itemId = args.buildingId and FactoryUtils.getBuildingItemId(args.buildingId)
    local hasWiki = WikiUtils.getWikiEntryIdFromItemId(itemId) ~= nil
    self.view.buildingNode.gameObject:SetActive(hasWiki)
    self.view.manualNode.gameObject:SetActive(not hasWiki)
    self.m_nodeView = hasWiki and self.view.buildingNode or self.view.manualNode
    self.view.button.enabled = hasWiki
    if name then
        self.m_nodeView.iconImg.sprite = self:LoadSprite(iconFolder, iconId)
        self.m_nodeView.titleTxt.text = name
    end
    self.m_nodeView.extraItemNode.gameObject:SetActive(args.isShowExtraItemIcon)
    self:SetSelected(false)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.transform)
end
WikiCraftingTreeBuilding.SetSelected = HL.Method(HL.Boolean) << function(self, isSelected)
    self.view.selectNode.gameObject:SetActive(isSelected)
end
WikiCraftingTreeBuilding.GetLeftMountPoint = HL.Method(Transform).Return(Vector2) << function(self, relativeTo)
    local pos = relativeTo:InverseTransformPoint(self.m_nodeView.leftMountPoint.transform.position)
    return Vector2(pos.x, pos.y)
end
WikiCraftingTreeBuilding.GetRightMountPoint = HL.Method(Transform).Return(Vector2) << function(self, relativeTo)
    local pos = relativeTo:InverseTransformPoint(self.m_nodeView.rightMountPoint.transform.position)
    return Vector2(pos.x, pos.y)
end
HL.Commit(WikiCraftingTreeBuilding)
return WikiCraftingTreeBuilding