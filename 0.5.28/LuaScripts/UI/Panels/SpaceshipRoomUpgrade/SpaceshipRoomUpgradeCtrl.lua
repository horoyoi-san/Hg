local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SpaceshipRoomUpgrade
local PHASE_ID = PhaseId.SpaceshipRoomUpgrade
SpaceshipRoomUpgradeCtrl = HL.Class('SpaceshipRoomUpgradeCtrl', uiCtrl.UICtrl)
local States = { Upgrade = "Upgrade", Max = "Max", Build = "Build", }
SpaceshipRoomUpgradeCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.SPACESHIP_ON_ROOM_LEVEL_UP] = 'OnRoomLevelUp', [MessageConst.SPACESHIP_ON_ROOM_ADDED] = 'OnRoomAdded', }
SpaceshipRoomUpgradeCtrl.m_roomId = HL.Field(HL.String) << ''
SpaceshipRoomUpgradeCtrl.m_moveCam = HL.Field(HL.Boolean) << false
SpaceshipRoomUpgradeCtrl.m_roomInfo = HL.Field(CS.Beyond.Gameplay.SpaceshipSystem.Room)
SpaceshipRoomUpgradeCtrl.m_roomTypeData = HL.Field(Cfg.Types.SpaceshipRoomTypeData)
SpaceshipRoomUpgradeCtrl.m_roomLvTable = HL.Field(HL.Userdata)
SpaceshipRoomUpgradeCtrl.m_isEnough = HL.Field(HL.Boolean) << false
SpaceshipRoomUpgradeCtrl.m_curSelectedLv = HL.Field(HL.Number) << -1
SpaceshipRoomUpgradeCtrl.m_state = HL.Field(HL.String) << ''
SpaceshipRoomUpgradeCtrl.m_upgradeEffectCells = HL.Field(HL.Forward('UIListCache'))
SpaceshipRoomUpgradeCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeBtn.onClick:AddListener(function()
        self:_Exit()
    end)
    self.view.upgradeBtn.onClick:AddListener(function()
        self:_OnClickConfirm()
    end)
    self.view.buildBtn.onClick:AddListener(function()
        self:_OnClickConfirm()
    end)
    self.view.roomInfoTipNode.button.onClick:AddListener(function()
        self.view.roomInfoTipNode.tipNode.gameObject:SetActive(not self.view.roomInfoTipNode.tipNode.gameObject.activeSelf)
    end)
    self.view.changeLvNode.reduceBtn.onClick:AddListener(function()
        self:_ChangeCurSelectedLv(self.m_curSelectedLv - 1)
    end)
    self.view.changeLvNode.addBtn.onClick:AddListener(function()
        self:_ChangeCurSelectedLv(self.m_curSelectedLv + 1)
    end)
    self.m_upgradeEffectCells = UIUtils.genCellCache(self.view.upgradeEffectCell)
    local roomId, moveCam
    if type(arg) == "string" then
        roomId = arg
        moveCam = false
    else
        roomId = arg.roomId
        moveCam = arg.moveCam
    end
    self.m_roomId = roomId
    self.m_moveCam = moveCam == true
    local roomData = Tables.spaceshipRoomInsTable[roomId]
    self.view.name.text = roomData.name
    self.m_roomTypeData = Tables.spaceshipRoomTypeTable[roomData.roomType]
    self.view.icon:LoadSprite(UIConst.UI_SPRITE_SPACESHIP_ROOM, self.m_roomTypeData.icon)
    self.view.colorfulBg.color = UIUtils.getColorByString(self.m_roomTypeData.color)
    self.view.previewItemNode.text.text = self.m_roomTypeData.newFormulaTitle
    self.m_roomLvTable = SpaceshipUtils.getRoomLvTableByType(roomData.roomType)
    local unlocked, room = GameInstance.player.spaceship:TryGetRoom(roomId)
    if unlocked then
        self.m_roomInfo = room
        local lv = self.m_roomInfo.lv
        local maxLv = self.m_roomInfo.maxLv
        local isMax = lv >= maxLv
        self.m_state = isMax and States.Max or States.Upgrade
        self.view.content:SetState(self.m_state)
        if isMax then
            self.m_curSelectedLv = lv
            self:_RefreshMaxInfo()
        else
            self.m_curSelectedLv = lv + 1
            self:_RefreshUpgradeInfo()
        end
    else
        self.m_curSelectedLv = 1
        self.m_state = States.Build
        self.view.content:SetState(self.m_state)
        self:_RefreshBuildInfo()
    end
    if self.m_moveCam then
        Notify(MessageConst.MOVE_CAM_TO_SPACESHIP_ROOM, { roomId = self.m_roomId, isUpgrade = true })
    end
end
SpaceshipRoomUpgradeCtrl.OnClose = HL.Override() << function(self)
    if self.m_moveCam then
        Notify(MessageConst.UNDO_MOVE_CAM_TO_SPACESHIP_ROOM, { roomId = self.m_roomId })
        self.m_moveCam = false
    end
end
SpaceshipRoomUpgradeCtrl.OnRoomAdded = HL.Method(HL.Table) << function(self, arg)
    local roomId = unpack(arg)
    if roomId ~= self.m_roomId then
        return
    end
    self:_Exit(true)
end
SpaceshipRoomUpgradeCtrl._RefreshBuildInfo = HL.Method() << function(self)
    self.view.buildNode.descTxt.text = self.m_roomTypeData.desc
    self:_UpdateCommonItemList(self.view.buildNode.previewItemNode, self.m_roomTypeData.previewProductItemIds)
    self:_UpdateCostItemList()
end
SpaceshipRoomUpgradeCtrl.OnRoomLevelUp = HL.Method(HL.Table) << function(self, arg)
    local roomId = unpack(arg)
    if roomId ~= self.m_roomId then
        return
    end
    if self.m_roomInfo.lv >= self.m_roomInfo.maxLv then
        local upgradeInteractOptArgs = { type = CS.Beyond.Gameplay.Core.InteractOptionType.Spaceship, sourceId = "SpaceshipRoom_" .. roomId, subIndex = 2, text = self.m_roomTypeData.maxLvOptName, icon = "btn_common_exchange_icon", }
        Notify(MessageConst.UPDATE_INTERACT_OPTION, upgradeInteractOptArgs)
    end
    self:_Exit(true)
end
SpaceshipRoomUpgradeCtrl._RefreshUpgradeInfo = HL.Method() << function(self)
    local roomInfo = self.m_roomInfo
    local isControlCenter = roomInfo.type == GEnums.SpaceshipRoomType.ControlCenter
    local typeLvData = self.m_roomLvTable[self.m_curSelectedLv]
    local commonLvData = Tables.spaceshipRoomLvTable[typeLvData.id]
    local roomTypeData = Tables.spaceshipRoomTypeTable[roomInfo.type]
    self.view.lvDotNode:InitLvDotNode(roomInfo.lv, roomInfo.maxLv, UIUtils.getColorByString(roomTypeData.color))
    self:_UpdateChangeLvNodeState()
    local effectInfos = SpaceshipUtils.getUpgradeEffectInfos(self.m_roomId, self.m_curSelectedLv)
    self.m_upgradeEffectCells:Refresh(#effectInfos, function(cell, index)
        local info = effectInfos[index]
        cell.nameTxt.text = info.name
        if info.subInfos then
            cell.subInfoNode.gameObject:SetActive(true)
            if not cell.m_subInfoCells then
                cell.m_subInfoCells = UIUtils.genCellCache(cell.subInfoCell)
            end
            cell.m_subInfoCells:Refresh(#info.subInfos, function(subCell, index)
                local subInfo = info.subInfos[index]
                subCell.text.text = subInfo.text
                subCell.image.color = subInfo.color
            end)
        else
            cell.subInfoNode.gameObject:SetActive(false)
        end
        cell.icon:LoadSprite(UIConst.UI_SPRITE_SPACESHIP_ROOM, info.icon)
        cell.beforeTxt.text = info.oldValue
        cell.afterTxt.text = info.newValue
        cell.addedTxt.text = string.format("+%d", info.newValue - info.oldValue)
    end)
    if isControlCenter then
        self.view.previewItemNode.gameObject:SetActive(false)
    else
        local newOutcomeItemIds = SpaceshipUtils.getRoomRecipeOutcomesByLv(self.m_roomId, self.m_curSelectedLv, true)
        self:_UpdateCommonItemList(self.view.previewItemNode, newOutcomeItemIds)
    end
    local rewardId
    if not isControlCenter then
        rewardId = typeLvData.rewardId
    end
    if string.isEmpty(rewardId) then
        self.view.rewardItemNode.gameObject:SetActive(false)
    else
        local rewardData = Tables.rewardTable:GetValue(typeLvData.rewardId)
        local itemBundles = rewardData.itemBundles
        self:_UpdateCommonItemList(self.view.rewardItemNode, itemBundles)
    end
    if self.m_curSelectedLv > roomInfo.lv then
        self:_UpdateCostItemList()
        self.view.bottomNode.gameObject:SetActive(true)
        if self.m_curSelectedLv == roomInfo.lv + 1 then
            if not self.m_roomInfo:CanLevelUp() then
                self.view.upgradeBtn.gameObject:SetActive(false)
                self.view.cantConfirmHintNode.gameObject:SetActive(true)
                self.view.cantConfirmHintNode.text.text = commonLvData.conditionDesc
            end
        else
            self.view.upgradeBtn.gameObject:SetActive(false)
            self.view.cantConfirmHintNode.gameObject:SetActive(true)
            self.view.cantConfirmHintNode.text.text = Language.LUA_SPACESHIP_ROOM_NEED_UNLOCK_PRE_LV
        end
    else
        self.view.costNode.gameObject:SetActive(false)
        self.view.bottomNode.gameObject:SetActive(false)
    end
    self.view.roomInfoTipNode.tipNode.gameObject:SetActive(false)
    self.view.roomInfoTipNode.tipTxt.text = self.m_roomTypeData.desc
end
SpaceshipRoomUpgradeCtrl._ChangeCurSelectedLv = HL.Method(HL.Number) << function(self, newLv)
    local roomInfo = self.m_roomInfo
    newLv = lume.clamp(newLv, 2, roomInfo.maxLv)
    self.m_curSelectedLv = newLv
    self:_RefreshUpgradeInfo()
end
SpaceshipRoomUpgradeCtrl._UpdateChangeLvNodeState = HL.Method() << function(self)
    local node = self.view.changeLvNode
    local roomInfo = self.m_roomInfo
    node.reduceBtn.gameObject:SetActive(self.m_curSelectedLv > (roomInfo.lv + 1) and self.m_curSelectedLv > 2)
    node.addBtn.gameObject:SetActive(self.m_curSelectedLv < roomInfo.maxLv)
    self:_UpdateChangeLvCell(node.leftLvCell, self.m_curSelectedLv - 1)
    self:_UpdateChangeLvCell(node.rightLvCell, self.m_curSelectedLv)
end
SpaceshipRoomUpgradeCtrl._UpdateChangeLvCell = HL.Method(HL.Table, HL.Number) << function(self, cell, lv)
    cell.text.text = lv
    cell.isCurHintNode.gameObject:SetActive(lv == self.m_roomInfo.lv)
    cell.image.enabled = lv > self.m_roomInfo.lv
end
SpaceshipRoomUpgradeCtrl._RefreshMaxInfo = HL.Method() << function(self)
    local node = self.view.maxNode
    local roomInfo = self.m_roomInfo
    local roomTypeData = Tables.spaceshipRoomTypeTable[roomInfo.type]
    node.lvDotNode:InitLvDotNode(roomInfo.lv, roomInfo.maxLv, UIUtils.getColorByString(roomTypeData.color))
    node.lvTxt.text = roomInfo.lv
    node.descTxt.text = self.m_roomTypeData.desc
    local effectInfos = SpaceshipUtils.getMaxUpgradeEffectInfos(self.m_roomId)
    if not node.m_finalEffectCells then
        node.m_finalEffectCells = UIUtils.genCellCache(node.finalEffectCell)
    end
    node.m_finalEffectCells:Refresh(#effectInfos, function(cell, index)
        local info = effectInfos[index]
        cell.nameTxt.text = info.name
        cell.icon:LoadSprite(UIConst.UI_SPRITE_SPACESHIP_ROOM, info.icon)
        cell.finalTxt.text = info.value
    end)
    local outcomeItemIds = SpaceshipUtils.getRoomRecipeOutcomesByLv(self.m_roomId, roomInfo.lv, false)
    self:_UpdateCommonItemList(node.formulaItemNode, outcomeItemIds)
    node.formulaItemNode.text.text = self.m_roomTypeData.newFormulaTitle
end
SpaceshipRoomUpgradeCtrl._UpdateCommonItemList = HL.Method(HL.Table, HL.Opt(HL.Any)) << function(self, listNode, itemInfos)
    local count = itemInfos and #itemInfos or 0
    if count == 0 then
        listNode.gameObject:SetActive(false)
        return
    end
    listNode.gameObject:SetActive(true)
    if not listNode.itemCells then
        listNode.itemCells = UIUtils.genCellCache(listNode.item)
    end
    local isTable = type(itemInfos) == "table"
    listNode.itemCells:Refresh(#itemInfos, function(cell, index)
        local info = itemInfos[isTable and index or CSIndex(index)]
        local itemId
        if type(info) == "string" then
            itemId = info
            cell:InitItem({ id = itemId }, true)
        else
            cell:InitItem(info, true)
        end
    end)
end
SpaceshipRoomUpgradeCtrl._UpdateCostItemList = HL.Method() << function(self)
    local typeLvData = self.m_roomLvTable[self.m_curSelectedLv]
    local commonLvData = Tables.spaceshipRoomLvTable[typeLvData.id]
    local costItemInfos = commonLvData.costItems
    local node = self.view.costNode
    local count = costItemInfos and #costItemInfos or 0
    self.m_isEnough = true
    if count == 0 then
        node.gameObject:SetActive(false)
    else
        node.gameObject:SetActive(true)
        if not node.itemCells then
            node.itemCells = UIUtils.genCellCache(node.item)
        end
        node.itemCells:Refresh(#costItemInfos, function(cell, index)
            local itemBundle = costItemInfos[CSIndex(index)]
            cell:InitItem(itemBundle, true)
            local ownCount = Utils.getItemCount(itemBundle.id, true, true)
            local isLack = ownCount < itemBundle.count
            local str = string.format("%s %s", Language.LUA_SAFE_AREA_ITEM_COUNT_LABEL, UIUtils.getNumString(ownCount))
            cell.view.ownCountTxt.text = UIUtils.setCountColor(str, isLack)
            cell:UpdateCountSimple(itemBundle.count, isLack)
            if isLack then
                self.m_isEnough = false
            end
        end)
    end
    if self.m_state == States.Build then
        self.view.buildBtn.gameObject:SetActive(self.m_isEnough)
    else
        self.view.upgradeBtn.gameObject:SetActive(self.m_isEnough)
    end
    self.view.cantConfirmHintNode.gameObject:SetActive(not self.m_isEnough)
    if not self.m_isEnough then
        self.view.cantConfirmHintNode.text.text = Language.LUA_ITEM_NOT_ENOUGH
    end
end
SpaceshipRoomUpgradeCtrl._OnClickConfirm = HL.Method() << function(self)
    if self:IsPlayingAnimationIn() then
        return
    end
    if self.m_state == States.Build then
        GameInstance.player.spaceship:BuildRoom(self.m_roomId)
    elseif self.m_state == States.Upgrade then
        GameInstance.player.spaceship:LevelUpRoom(self.m_roomId)
    end
end
SpaceshipRoomUpgradeCtrl._Exit = HL.Method(HL.Opt(HL.Boolean)) << function(self, needDialog)
    if not PhaseManager:CanPopPhase(PHASE_ID) then
        return
    end
    local dialogId
    local roomId = self.m_roomId
    if needDialog then
        local lv = self.m_state == States.Upgrade and self.m_roomInfo.lv or 1
        local roomData = Tables.spaceshipRoomInsTable[roomId]
        dialogId = roomData.upgradeDialogIds[CSIndex(lv)]
    end
    if string.isEmpty(dialogId) then
        if self.m_moveCam then
            Notify(MessageConst.UNDO_MOVE_CAM_TO_SPACESHIP_ROOM, { roomId = roomId })
            self.m_moveCam = false
        end
        PhaseManager:PopPhase(PHASE_ID)
        return
    end
    if self.m_moveCam then
        Notify(MessageConst.UNDO_MOVE_CAM_TO_SPACESHIP_ROOM, { roomId = roomId })
        self.m_moveCam = false
    end
    GameAction.StartDialog(dialogId)
    PhaseManager:ExitPhaseFast(PHASE_ID)
end
HL.Commit(SpaceshipRoomUpgradeCtrl)