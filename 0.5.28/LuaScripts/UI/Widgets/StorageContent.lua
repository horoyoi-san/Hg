local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
StorageContent = HL.Class('StorageContent', UIWidgetBase)
StorageContent.m_getCell = HL.Field(HL.Function)
StorageContent.m_storage = HL.Field(CS.Beyond.Gameplay.RemoteFactory.FBUtil.GridBox)
StorageContent.m_onClickItemAction = HL.Field(HL.Function)
StorageContent._OnFirstTimeInit = HL.Override() << function(self)
    self.m_getCell = UIUtils.genCachedCellFunction(self.view.itemList, function(object)
        return UIWidgetManager:Wrap(object)
    end)
    self.view.itemList.onUpdateCell:AddListener(function(object, csIndex)
        self:_OnUpdateCell(self.m_getCell(object), csIndex)
    end)
    self.view.dropHint.gameObject:SetActive(false)
    self.view.dropMask.gameObject:SetActive(false)
    self:RegisterMessage(MessageConst.ON_START_UI_DRAG, function(dragHelper)
        if UIUtils.isTypeDropValid(dragHelper, UIConst.FACTORY_STORAGER_DROP_ACCEPT_INFO) and dragHelper.info.storage ~= self.m_storage then
            self.view.quickDropButton.onClick:RemoveAllListeners()
            self.view.quickDropButton.onClick:AddListener(function()
                self:_OnDropItem(-1, dragHelper)
            end)
            self.view.dropHint.gameObject:SetActive(true)
            self.view.dropMask.gameObject:SetActive(true)
        end
    end)
    self:RegisterMessage(MessageConst.ON_END_UI_DRAG, function(dragHelper)
        if UIUtils.isTypeDropValid(dragHelper, UIConst.FACTORY_STORAGER_DROP_ACCEPT_INFO) and dragHelper.info.storage ~= self.m_storage then
            self.view.dropHint.gameObject:SetActive(false)
            self.view.dropMask.gameObject:SetActive(false)
        end
    end)
    UIUtils.initUIDropHelper(self.view.dropMask, {
        acceptTypes = UIConst.FACTORY_STORAGER_DROP_ACCEPT_INFO,
        onDropItem = function(eventData, dragHelper)
            self:_OnDropItem(-1, dragHelper)
        end,
        isDropArea = true,
        quickDropCheckGameObject = self.gameObject,
        dropPriority = 1,
    })
end
StorageContent.InitStorageContent = HL.Method(CS.Beyond.Gameplay.RemoteFactory.FBUtil.GridBox, HL.Opt(HL.Function, HL.Table)) << function(self, storage, onClickItemAction, otherArgs)
    otherArgs = otherArgs or {}
    self:_FirstTimeInit()
    self.m_storage = storage
    self.m_onClickItemAction = otherArgs.onClickItemAction
    self:Refresh()
    self:_StartCoroutine(function()
        while true do
            coroutine.step()
            self:_TryUpdateContent()
        end
    end)
end
StorageContent.Refresh = HL.Method() << function(self)
    self.view.itemList:UpdateCount(self.m_storage.items.Count)
end
StorageContent._TryUpdateContent = HL.Method() << function(self)
    for k, v in pairs(self.m_storage.items) do
        local cell = self.m_getCell(LuaIndex(k))
        if cell then
            local id, count = v.Item1, v.Item2
            if cell.item.id ~= id or cell.item.count ~= count then
                self:_OnUpdateCell(cell, k)
            end
        end
    end
end
StorageContent._OnUpdateCell = HL.Method(HL.Any, HL.Number) << function(self, cell, csIndex)
    local item = self.m_storage.items[csIndex]
    item = { id = item.Item1, count = item.Item2, }
    local isEmpty = string.isEmpty(item.id)
    if isEmpty then
        cell.gameObject.name = "Item__" .. csIndex
    else
        cell.gameObject.name = "Item_" .. item.id
    end
    cell:InitItemSlot(item, function()
        self:_OnClickItem(csIndex)
    end)
    cell.item.canClear = true
    if not isEmpty then
        local data = Tables.itemTable:GetValue(item.id)
        local dragHelper = UIUtils.initUIDragHelper(cell.view.dragItem, { source = UIConst.UI_DRAG_DROP_SOURCE_TYPE.Storage, type = data.type, storage = self.m_storage, csIndex = csIndex, itemId = item.id, count = item.count, })
        cell:InitPressDrag()
        cell.item.view.button.clickHintTextId = "virtual_mouse_hint_item_tips"
    end
    UIUtils.initUIDropHelper(cell.view.dropItem, {
        acceptTypes = UIConst.FACTORY_STORAGER_DROP_ACCEPT_INFO,
        onDropItem = function(eventData, dragHelper)
            self:_OnDropItem(csIndex, dragHelper)
        end,
    })
end
StorageContent._OnDropItem = HL.Method(HL.Number, HL.Forward('UIDragHelper')) << function(self, csIndex, dragHelper)
    local source = dragHelper.source
    local dragInfo = dragHelper.info
    local core = GameInstance.player.remoteFactory.core
    local componentId = self.m_storage.componentId
    if csIndex < 0 then
        for k, v in pairs(self.m_storage.items) do
            local cell = self.m_getCell(LuaIndex(k))
            if cell then
                if string.isEmpty(v.Item1) then
                    csIndex = k
                    break
                end
            end
        end
    end
    if csIndex < 0 then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_FAC_STORAGE_NO_EMPTY_SLOT)
        return
    end
    if source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.Storage then
        core:Message_OpGridBoxInnerMove(Utils.getCurrentChapterId(), componentId, dragInfo.csIndex, csIndex)
    elseif source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.FactoryDepot then
        core:Message_OpMoveItemDepotToGridBox(Utils.getCurrentChapterId(), dragInfo.itemId, componentId, csIndex)
    elseif source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.ItemBag then
        core:Message_OpMoveItemBagToGridBox(Utils.getCurrentChapterId(), dragInfo.csIndex, componentId, csIndex)
    end
    if dragInfo.itemId then
        local cptHandler = FactoryUtils.getBuildingComponentHandler(componentId)
        local buildingNode = cptHandler.belongNode
        local worldPos = GameInstance.remoteFactoryManager.visual:BuildingGridToWorld(Vector2(buildingNode.transform.position.x, buildingNode.transform.position.z))
        local curItems = {}
        for _, v in pairs(self.m_storage.items) do
            local id, count = v.Item1, v.Item2
            if not string.isEmpty(id) then
                if not curItems[id] then
                    curItems[id] = count
                else
                    curItems[id] = curItems[id] + count
                end
            end
        end
        EventLogManagerInst:GameEvent_FactoryItemPush(buildingNode.nodeId, buildingNode.templateId, GameInstance.remoteFactoryManager.currentSceneName, worldPos, dragInfo.itemId, dragInfo.count, curItems)
    end
end
StorageContent._OnClickItem = HL.Method(HL.Number) << function(self, csIndex)
    local item = self.m_storage.items[csIndex]
    local id, count = item.Item1, item.Item2
    local cell = self.m_getCell(LuaIndex(csIndex))
    if self.m_onClickItemAction then
        self.m_onClickItemAction(id)
    elseif not string.isEmpty(id) then
        cell.item:ShowTips()
    end
end
HL.Commit(StorageContent)
return StorageContent