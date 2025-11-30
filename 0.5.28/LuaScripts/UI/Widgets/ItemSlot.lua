local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
ItemSlot = HL.Class('ItemSlot', UIWidgetBase)
ItemSlot.item = HL.Field(HL.Forward('Item'))
ItemSlot._OnFirstTimeInit = HL.Override() << function(self)
    self.item = self.view.item
end
ItemSlot.InitItemSlot = HL.Method(HL.Opt(HL.Any, HL.Any, HL.String, HL.Boolean)) << function(self, itemBundle, onClick, limitId, clickableEvenEmpty)
    self:_FirstTimeInit()
    self.item.view.button.longPressImg = nil
    self.view.pressHintImg.gameObject:SetActive(false)
    self.view.lockNode.gameObject:SetActive(false)
    self.view.item.gameObject:SetActive(true)
    self.item:InitItem(itemBundle, onClick, limitId, clickableEvenEmpty)
    local isEmpty = itemBundle == nil or itemBundle.id == ""
    if self.view.emptyNode then
        self.view.emptyNode.gameObject:SetActive(isEmpty)
    end
    if isEmpty then
        self.view.dragItem.enabled = false
        self.view.dropItem:ClearEvents()
        self.view.dragItem:ClearEvents()
        return
    end
    self.view.dropItem:ClearEvents()
    self.view.dragItem:ClearEvents()
    self.view.dragItem.enabled = true
    self.view.dragItem.dragPivot = DeviceInfo.isMobile and self.config.DRAG_PIVOT_FOR_MOBILE or self.config.DRAG_PIVOT_FOR_PC
    self.item.view.button.longPressHintTextId = "virtual_mouse_hint_drag"
    self.view.dragItem.onUpdateDragObject:AddListener(function(dragObj)
        local dragItem = UIWidgetManager:Wrap(dragObj)
        dragItem:InitItem(itemBundle)
    end)
end
ItemSlot.InitLockSlot = HL.Method() << function(self)
    self:_FirstTimeInit()
    self.item.view.button.longPressImg = nil
    self.view.pressHintImg.gameObject:SetActive(false)
    self.view.item.gameObject:SetActive(false)
    self.view.lockNode.gameObject:SetActive(true)
    self.view.dragItem.enabled = false
    self.view.lockNode.onClick:RemoveAllListeners()
    self.view.lockNode.onClick:AddListener(function()
        Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_BAG_SLOT_LOCKED)
    end)
    self.view.dropItem.onDropEvent:RemoveAllListeners()
    self.view.dragItem.onBeginDragEvent:RemoveAllListeners()
    self.view.dragItem.onDragEvent:RemoveAllListeners()
    self.view.dragItem.onEndDragEvent:RemoveAllListeners()
    self.view.dragItem.onUpdateDragObject:RemoveAllListeners()
end
ItemSlot.InitPressDrag = HL.Method() << function(self)
    if DeviceInfo.usingTouch then
        self:InitPressDragForTouch()
    end
end
ItemSlot.InitPressDragForTouch = HL.Method() << function(self)
    self.item.view.button.longPressImg = self.view.pressHintImg
    if not self.view.dragItem.inDragging then
        self.view.dragItem.canStartDrag = false
    end
    self.item.view.button.onLongPress:AddListener(function(eventData)
        self.view.dragItem.canStartDrag = true
        self.view.dragItem:OnBeginDrag(eventData)
    end)
    self.view.dragItem.onEndDragEvent:AddListener(function(eventData)
        self.view.dragItem.canStartDrag = false
    end)
    self.item.view.button.onPressEnd:AddListener(function(eventData)
        if (not eventData.dragging) and self.view.dragItem.inDragging then
            self.view.dragItem:OnEndDrag(eventData)
        end
    end)
end
ItemSlot.QuickDrop = HL.Method() << function(self)
    local dragHelper = self.view.dragItem.luaTable[1]
    local UIDropHelper = require_ex("Common/Utils/UI/UIDropHelper")
    local maxPriority, targetDropHelper
    for dropHelper, _ in pairs(UIDropHelper.s_dropAreas) do
        if not maxPriority or dropHelper.dropPriority > maxPriority then
            local checkTarget = dropHelper.info.quickDropCheckGameObject or dropHelper.uiDropItem.gameObject
            if dropHelper.uiDropItem.enabled and checkTarget.activeInHierarchy and dropHelper:Accept(dragHelper) then
                maxPriority = dropHelper.dropPriority
                targetDropHelper = dropHelper
            end
        end
    end
    if targetDropHelper then
        targetDropHelper.info.onDropItem(nil, dragHelper)
    end
end
ItemSlot.SetAsNaviTarget = HL.Method() << function(self)
    self.item:SetAsNaviTarget()
end
HL.Commit(ItemSlot)
return ItemSlot