local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
WikiCraftingTreeItem = HL.Class('WikiCraftingTreeItem', UIWidgetBase)
WikiCraftingTreeItem.m_args = HL.Field(HL.Table)
WikiCraftingTreeItem._OnFirstTimeInit = HL.Override() << function(self)
end
WikiCraftingTreeItem.InitWikiCraftingTreeItem = HL.Method(HL.Table) << function(self, args)
    self.m_args = args
    self:_FirstTimeInit()
    self.view.gameObject.name = args.itemId
    self.view.itemBlack:InitItem({ id = args.itemId }, function()
        if args.onClicked then
            args.onClicked(args.itemId, self)
        end
    end)
    self:SetSelected(false)
    self:SetMain(false)
    self.view.mainNode.gameObject:SetActive(args.isShowMainIcon == true)
end
WikiCraftingTreeItem.SetMain = HL.Method(HL.Boolean) << function(self, isMain)
    self.view.mainNode.gameObject:SetActive(isMain)
end
WikiCraftingTreeItem.SetSelected = HL.Method(HL.Boolean) << function(self, isSelected)
    self.view.selectNode.gameObject:SetActive(isSelected)
end
WikiCraftingTreeItem.SetLeftMountPointCount = HL.Method(HL.Number) << function(self, count)
    CSUtils.UIContainerResize(self.view.leftNode, count)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.leftNode)
end
WikiCraftingTreeItem.SetRightMountPointCount = HL.Method(HL.Number) << function(self, count)
    CSUtils.UIContainerResize(self.view.rightNode, count)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.rightNode)
end
WikiCraftingTreeItem.GetLeftMountPoint = HL.Method(Transform, HL.Number).Return(Vector2) << function(self, relativeTo, index)
    local node = self.view.leftNode.transform:GetChild(CSIndex(index))
    if node then
        local pos = relativeTo:InverseTransformPoint(node.position)
        return Vector2(pos.x, pos.y)
    end
    return Vector2.zero
end
WikiCraftingTreeItem.GetRightMountPoint = HL.Method(Transform, HL.Number).Return(Vector2) << function(self, relativeTo, index)
    local node = self.view.rightNode.transform:GetChild(CSIndex(index))
    if node then
        local pos = relativeTo:InverseTransformPoint(node.position)
        return Vector2(pos.x, pos.y)
    end
    return Vector2.zero
end
HL.Commit(WikiCraftingTreeItem)
return WikiCraftingTreeItem