local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
RpgDungeonEquipSlots = HL.Class('RpgDungeonEquipSlots', UIWidgetBase)
RpgDungeonEquipSlots.m_itemSlots = HL.Field(HL.Forward('UIListCache'))
RpgDungeonEquipSlots._OnFirstTimeInit = HL.Override() << function(self)
    self.m_itemSlots = UIUtils.genCellCache(self.view.itemSlot)
    self:RegisterMessage(MessageConst.ON_PUT_ON_RPG_DUNGEON_EQUIP_SUCC, function()
        self:Refresh()
    end)
    self:RegisterMessage(MessageConst.ON_PUT_OFF_RPG_DUNGEON_EQUIP_SUCC, function()
        self:Refresh()
    end)
end
RpgDungeonEquipSlots.InitRpgDungeonEquipSlots = HL.Method() << function(self)
    self:_FirstTimeInit()
    self:Refresh()
end
RpgDungeonEquipSlots.Refresh = HL.Method() << function(self)
    local equipList = GameInstance.player.rpgDungeonSystem.equippedInstList
    self.m_itemSlots:Refresh(equipList.Count, function(cell, luaIndex)
        self:_UpdateCell(cell, luaIndex)
    end)
end
RpgDungeonEquipSlots._UpdateCell = HL.Method(HL.Forward('ItemSlot'), HL.Number) << function(self, cell, luaIndex)
    local csIndex = CSIndex(luaIndex)
    local instId = GameInstance.player.rpgDungeonSystem.equippedInstList[csIndex]
    local isEmpty = instId <= 0
    if not isEmpty then
        local succ, itemBundle = GameInstance.player.inventory:TryGetInstItem(Utils.getCurrentScope(), instId)
        if not succ then
            logger.error("No Equipped Item", instId)
            return
        end
        cell:InitItemSlot(itemBundle, true)
        local itemId = itemBundle.id
        cell.gameObject.name = "Item__" .. itemId
        local data = Tables.itemTable:GetValue(itemId)
        local dragHelper = UIUtils.initUIDragHelper(cell.view.dragItem, {
            source = UIConst.UI_DRAG_DROP_SOURCE_TYPE.RpgEquipSlot,
            type = data.type,
            csIndex = csIndex,
            itemId = itemId,
            instId = instId,
            count = itemBundle.count,
            onEndDrag = function(enterObj, enterDrop)
                self:_OnEndDrag(csIndex, enterObj, enterDrop)
            end
        })
    else
        cell:InitItemSlot()
        cell.gameObject.name = "Item__" .. csIndex
    end
    UIUtils.initUIDropHelper(cell.view.dropItem, {
        acceptTypes = UIConst.RPG_EQUIP_SLOT_DROP_ACCEPT_INFO,
        onDropItem = function(eventData, dragHelper)
            self:_OnDropItem(csIndex, dragHelper)
        end,
    })
end
RpgDungeonEquipSlots._OnEndDrag = HL.Method(HL.Number, HL.Opt(HL.Userdata, HL.Forward('UIDropHelper'))) << function(self, csIndex, enterObj, enterDrop)
    if enterDrop then
        return
    end
    GameInstance.player.rpgDungeonSystem:PutOffEquip(csIndex)
end
RpgDungeonEquipSlots._OnDropItem = HL.Method(HL.Number, HL.Forward('UIDragHelper')) << function(self, csIndex, dragHelper)
    local source = dragHelper.source
    local sys = GameInstance.player.rpgDungeonSystem
    if source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.RpgEquipSlot then
        sys:PutOnEquip(csIndex, dragHelper.info.instId)
    elseif source == UIConst.UI_DRAG_DROP_SOURCE_TYPE.ItemBag then
        sys:PutOnEquip(csIndex, dragHelper.info.instId)
    end
end
HL.Commit(RpgDungeonEquipSlots)
return RpgDungeonEquipSlots