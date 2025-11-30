local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FriendShipPresent
FriendShipPresentCtrl = HL.Class('FriendShipPresentCtrl', uiCtrl.UICtrl)
FriendShipPresentCtrl.m_charId = HL.Field(HL.String) << ""
FriendShipPresentCtrl.m_gifts = HL.Field(HL.Table)
FriendShipPresentCtrl.m_selected = HL.Field(HL.Table)
FriendShipPresentCtrl.m_curSelectedNum = HL.Field(HL.Number) << 0
FriendShipPresentCtrl.m_getGiftItemCell = HL.Field(HL.Function)
FriendShipPresentCtrl.m_successCor = HL.Field(HL.Thread)
FriendShipPresentCtrl.s_sortInfo = HL.StaticField(HL.Table) << {}
FriendShipPresentCtrl.m_level = HL.Field(HL.Number) << 1
FriendShipPresentCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_VALUABLE_DEPOT_CHANGED] = '_OnItemRefresh', [MessageConst.ON_CHAR_FRIENDSHIP_CHANGED] = '_OnCharPresentRefresh', [MessageConst.ON_CHAR_FRIENDSHIP_SEND_CHAR_GIFT_SUCCESS] = '_OnCharSendPresentSuccess', }
FriendShipPresentCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_charId = arg.charId
    self.m_gifts = {}
    self.m_selected = {}
    self.view.bottomList.scrollList.onUpdateCell:AddListener(function(object, index)
        self:_RefreshGiftItemCell(object, LuaIndex(index))
    end)
    self.m_getGiftItemCell = UIUtils.genCachedCellFunction(self.view.bottomList.scrollList)
    self.view.closeBtn.onClick:AddListener(function()
        self:PlayAnimationOutWithCallback(function()
            self:Notify(MessageConst.DIALOG_SEND_PRESENT_END, { success = false, nextIndex = 1, })
        end)
    end)
    self.view.main.onClick:AddListener(function()
        self:_RefreshTips(false)
        self:_SelectOnlyOneCell(-1)
    end)
    self.view.bottomList.buttonSend.onClick:AddListener(function()
        self:_SendPresentToChar()
    end)
    local curCSOptionIndex
    local curIsIncremental
    if FriendShipPresentCtrl.s_sortInfo then
        curCSOptionIndex = FriendShipPresentCtrl.s_sortInfo.curCSOptionIndex
        curIsIncremental = FriendShipPresentCtrl.s_sortInfo.curIsIncremental
    end
    self.view.sortNode:InitSortNode(UIConst.FRIENDSHIP_PRESENT_GIFT_SORT_OPTION, function(optData, isIncremental)
        self:_OnSortChanged(optData, isIncremental)
    end, curCSOptionIndex, curIsIncremental)
    self.m_level = CSPlayerDataUtil.GetFriendshipLevelByChar(self.m_charId)
end
FriendShipPresentCtrl.OnShow = HL.Override() << function(self)
    self:RefreshReliabilityCell()
    self:RefreshGiftList()
    self:_RefreshRightInfo()
    self:_RefreshTips(false)
end
FriendShipPresentCtrl._RefreshGiftItemCell = HL.Method(HL.Userdata, HL.Number) << function(self, object, luaIndex)
    local itemId = self.m_gifts[luaIndex].itemId
    local count = Utils.getItemCount(itemId)
    local cell = self.m_getGiftItemCell(object)
    local isMax = self:_IsMax()
    local data = { id = itemId, }
    if not isMax then
        data.count = count
    end
    local itemCell = cell.listCellFriendshipUpgrade
    itemCell.item:InitItem(data, function()
        self:_OnItemSelectClicked(itemId, luaIndex)
    end)
    local like = self:_GetCharLike(itemId)
    itemCell.likeIcon.gameObject:SetActive(like)
    self:_RefreshSingleItemSelect(itemCell)
    itemCell.btnMinus.onClick:RemoveAllListeners()
    itemCell.btnMinus.onClick:AddListener(function()
        self:_OnItemMinusClicked(itemId, luaIndex)
    end)
end
FriendShipPresentCtrl._OnItemSelectClicked = HL.Method(HL.String, HL.Number) << function(self, itemId, luaIndex)
    local count = Utils.getItemCount(itemId)
    local selectNum = self.m_selected[itemId] or 0
    local tmpSelectNum = selectNum + 1
    self:_RefreshTips(true, itemId)
    local isMax = self:_IsMax()
    if isMax then
        self:_SelectOnlyOneCell(luaIndex)
        return
    end
    if count == 0 then
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_SPACESHIP_GIFT_EMPTY)
        return
    end
    if count < tmpSelectNum then
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_SPACESHIP_GIFT_EMPTY)
        return
    end
    local curMaxNum = CSPlayerDataUtil.GetCharRecvGiftRemainToday(self.m_charId)
    if self.m_curSelectedNum >= curMaxNum then
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_SPACESHIP_GIFT_MAX_COUNT)
        return
    end
    self.m_selected[itemId] = tmpSelectNum
    local cell = self:_GetCellByIndex(luaIndex)
    if cell then
        self:_RefreshSingleItemSelect(cell.listCellFriendshipUpgrade)
    end
    self.m_curSelectedNum = self.m_curSelectedNum + 1
    self:_RefreshCurSelect()
end
FriendShipPresentCtrl._OnItemMinusClicked = HL.Method(HL.String, HL.Number) << function(self, itemId, luaIndex)
    local isMax = self:_IsMax()
    if isMax then
        return
    end
    local selectNum = self.m_selected[itemId]
    if selectNum and selectNum > 0 then
        self.m_selected[itemId] = self.m_selected[itemId] - 1
        self.m_curSelectedNum = self.m_curSelectedNum - 1
    end
    local cell = self:_GetCellByIndex(luaIndex)
    if cell then
        self:_RefreshSingleItemSelect(cell.listCellFriendshipUpgrade)
    end
    self:_RefreshCurSelect()
end
FriendShipPresentCtrl._GetCellByIndex = HL.Method(HL.Number).Return(HL.Any) << function(self, luaIndex)
    local cell
    if luaIndex > 0 then
        local object = self.view.bottomList.scrollList:Get(CSIndex(luaIndex))
        if object then
            cell = self.m_getGiftItemCell(object)
        end
    end
    return cell
end
FriendShipPresentCtrl._SelectOnlyOneCell = HL.Method(HL.Number) << function(self, luaIndex)
    local isMax = self:_IsMax()
    if isMax then
        for index = 1, self.view.bottomList.scrollList.count do
            local cell = self:_GetCellByIndex(index)
            if cell then
                cell.listCellFriendshipUpgrade.selectNode.gameObject:SetActive(index == luaIndex)
            end
        end
    end
end
FriendShipPresentCtrl._RefreshSingleItemSelect = HL.Method(HL.Table) << function(self, itemCell)
    local itemId = itemCell.item.id
    local selectNum = self.m_selected[itemId] or 0
    itemCell.multiSelectNode.gameObject:SetActive(selectNum > 0)
    itemCell.selectCount.text = tostring(selectNum)
    itemCell.btnMinus.gameObject:SetActive(selectNum > 0)
    itemCell.selectNode.gameObject:SetActive(selectNum > 0)
end
FriendShipPresentCtrl._GetCharLike = HL.Method(HL.String).Return(HL.Boolean) << function(self, itemId)
    local giftData = Tables.giftItemTable:GetValue(itemId)
    local tagList = giftData.tagList
    local charTagData = Tables.characterTagTable[self.m_charId]
    local hobbyTagIds = charTagData.hobbyTagIds
    local like = false
    for _, tag in pairs(tagList) do
        if lume.find(hobbyTagIds, tag) then
            like = true
            break
        end
    end
    return like
end
FriendShipPresentCtrl._RefreshTmpFriendship = HL.Method() << function(self)
    local totalFavorablePoint = 0
    for itemId, selectNum in pairs(self.m_selected) do
        local giftData = Tables.giftItemTable:GetValue(itemId)
        local isLike = self:_GetCharLike(itemId)
        local ratio = isLike and Tables.spaceshipConst.favoriteGiftRatio or 1
        totalFavorablePoint = totalFavorablePoint + lume.round(giftData.favorablePoint * selectNum * ratio)
    end
    self.view.reliabilityCell:RefreshTmpFriendship(totalFavorablePoint)
end
FriendShipPresentCtrl._RefreshCurSelect = HL.Method() << function(self)
    local visible = self.m_curSelectedNum > 0
    self.view.bottomList.textSelectedNum.gameObject:SetActive(visible)
    if visible then
        self.view.bottomList.textSelectedNum.text = string.format(Language.LUA_SPACESHIP_CHAR_FRIENDSHIP_PRESENT_SELECT_FORMAT, self.m_curSelectedNum)
    end
    self:_RefreshTmpFriendship()
end
FriendShipPresentCtrl._RefreshRightInfo = HL.Method() << function(self)
    local isEmpty = true
    for _, itemData in pairs(self.m_gifts) do
        local count = Utils.getItemCount(itemData.itemId)
        if count > 0 then
            isEmpty = false
            break
        end
    end
    local isMax = self:_IsMax()
    local curMaxNum = CSPlayerDataUtil.GetCharRecvGiftRemainToday(self.m_charId)
    local isLimitToday = curMaxNum <= 0
    local curMaxNum = CSPlayerDataUtil.GetCharRecvGiftRemainToday(self.m_charId)
    if isMax then
        self.view.bottomList.buttonSend.gameObject:SetActive(false)
        self.view.bottomList.textSelectedNum.gameObject:SetActive(false)
        self.view.bottomList.textRest.gameObject:SetActive(false)
        self.view.bottomList.hintNode.gameObject:SetActive(true)
        self.view.bottomList.textHint.text = UIUtils.resolveTextStyle(Language.LUA_SPACESHIP_CHAR_FRIENDSHIP_FULL)
    elseif isLimitToday then
        self.view.bottomList.buttonSend.gameObject:SetActive(false)
        self.view.bottomList.textSelectedNum.gameObject:SetActive(false)
        self.view.bottomList.textRest.gameObject:SetActive(false)
        local leftTime = self:_CalculateLeftTime()
        self.view.bottomList.textHint.text = UIUtils.resolveTextStyle(string.format(Language.LUA_SPACESHIP_CHAR_FRIENDSHIP_PRESENT_LEFT_TIME_FORMAT, UIUtils.getLeftTime(leftTime)))
    elseif isEmpty then
        self.view.bottomList.buttonSend.gameObject:SetActive(false)
        self.view.bottomList.textSelectedNum.gameObject:SetActive(false)
        self.view.bottomList.textRest.gameObject:SetActive(false)
        self.view.bottomList.hintNode.gameObject:SetActive(true)
        self.view.bottomList.textHint.text = UIUtils.resolveTextStyle(Language.LUA_SPACESHIP_CHAR_FRIENDSHIP_PRESENT_NO_ITEM)
    else
        self.view.bottomList.buttonSend.gameObject:SetActive(true)
        self.view.bottomList.textRest.gameObject:SetActive(true)
        self.view.bottomList.textRest.text = UIUtils.resolveTextStyle(string.format(Language.LUA_SPACESHIP_CHAR_FRIENDSHIP_PRESENT_REMAIN_FORMAT, curMaxNum))
    end
end
FriendShipPresentCtrl._CalculateLeftTime = HL.Method().Return(HL.Number) << function(self)
    local serverTime = DateTimeUtils.GetCurrentTimestampBySeconds()
    local nextTime = Utils.getNextCommonServerRefreshTime()
    return nextTime - serverTime
end
FriendShipPresentCtrl._RefreshTips = HL.Method(HL.Boolean, HL.Opt(HL.String)) << function(self, visible, itemId)
    local describeTips = self.view.bottomList.describeTips
    if visible then
        describeTips.gameObject:SetActive(visible)
    else
        describeTips.animationWrapper:PlayOutAnimation(function()
            describeTips.gameObject:SetActive(visible)
        end)
    end
    if visible then
        local itemData = Tables.itemTable:GetValue(itemId)
        local giftData = Tables.giftItemTable:GetValue(itemId)
        local favorablePoint = giftData.favorablePoint
        local isLike = self:_GetCharLike(itemId)
        if isLike then
            describeTips.loveIcon.gameObject:SetActive(true)
            local characterData = CharInfoUtils.getCharTableData(self.m_charId)
            describeTips.textChar.text = string.format(Language.LUA_SPACESHIP_CHAR_FRIENDSHIP_LIKE_NAME_FORMAT, characterData.name)
        else
            describeTips.loveIcon.gameObject:SetActive(false)
        end
        local iconId = itemData.iconId
        local sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, iconId)
        if sprite ~= nil then
            describeTips.itemIcon.sprite = sprite
        end
        describeTips.textName.text = itemData.name
        describeTips.textDesc.text = itemData.desc
        describeTips.buttonTips.onClick:RemoveAllListeners()
        describeTips.buttonTips.onClick:AddListener(function()
            self:Notify(MessageConst.SHOW_ITEM_TIPS, { transform = describeTips.buttonTips.transform, itemId = itemId, })
        end)
    end
end
FriendShipPresentCtrl.RefreshReliabilityCell = HL.Method() << function(self)
    self.view.reliabilityCell:InitReliabilityCell(self.m_charId)
    self.view.reliabilityCell:RefreshTmpFriendship(0)
end
FriendShipPresentCtrl._OnSortChanged = HL.Method(HL.Table, HL.Boolean) << function(self, optData, isIncremental)
    local keys = optData.keys
    self:_SortData(keys, isIncremental)
    FriendShipPresentCtrl.s_sortInfo.curIsIncremental = self.view.sortNode.isIncremental
    FriendShipPresentCtrl.s_sortInfo.curCSOptionIndex = CSIndex(self.view.sortNode:GetCurSelectedIndex())
end
FriendShipPresentCtrl._SortData = HL.Method(HL.Table, HL.Boolean) << function(self, keys, isIncremental)
    table.sort(self.m_gifts, Utils.genSortFunction(keys, isIncremental))
    self.view.bottomList.scrollList:UpdateCount(#self.m_gifts)
end
FriendShipPresentCtrl._IsMax = HL.Method().Return(HL.Boolean) << function(self)
    local level = CSPlayerDataUtil.GetFriendshipLevelByChar(self.m_charId)
    local maxLevel = CSPlayerDataUtil.maxFriendshipLevel
    local isMax = level == maxLevel
    return isMax
end
FriendShipPresentCtrl.RefreshGiftList = HL.Method() << function(self)
    self.m_gifts = {}
    local isMax = self:_IsMax()
    local list = Tables.itemListByTypeTable:GetValue(GEnums.ItemType.Gift).list
    for _, itemId in pairs(list) do
        local count = Utils.getItemCount(itemId)
        local giftData = Tables.giftItemTable:GetValue(itemId)
        local favorablePoint = giftData.favorablePoint
        local isLike = self:_GetCharLike(itemId)
        local itemData = Tables.itemTable:GetValue(itemId)
        if not isMax or isLike then
            local data = { itemId = itemId, count = count, countReverse = -count, isLike = isLike and 1 or 0, favorablePoint = favorablePoint, rarity = itemData.rarity, sortId1Reverse = -itemData.sortId1, }
            table.insert(self.m_gifts, data)
        end
    end
    self.view.sortNode:SortCurData()
end
FriendShipPresentCtrl._OnCharPresentRefresh = HL.Method() << function(self)
    self:_RefreshRightInfo()
    self:_RefreshCurSelect()
end
FriendShipPresentCtrl._OnCharSendPresentSuccess = HL.Method(HL.Table) << function(self, data)
    self:PlayAnimationOutWithCallback(function()
        local level = CSPlayerDataUtil.GetFriendshipLevelByChar(self.m_charId)
        local deltaFav = unpack(data)
        self:Notify(MessageConst.DIALOG_SEND_PRESENT_END, { success = true, nextIndex = 0, deltaFav = deltaFav, selectedItems = self.m_selected, levelChanged = level ~= self.m_level })
        self.m_level = level
    end)
end
FriendShipPresentCtrl._OnItemRefresh = HL.Method(HL.Table) << function(self, _)
    self:RefreshGiftList()
    self:_RefreshRightInfo()
end
FriendShipPresentCtrl._SendPresentToChar = HL.Method() << function(self)
    if self.m_curSelectedNum <= 0 then
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_SPACESHIP_GIFT_COUNT_NONE)
        return
    end
    local giftIds = {}
    local nums = {}
    for giftId, num in pairs(self.m_selected) do
        table.insert(giftIds, giftId)
        table.insert(nums, num)
    end
    GameInstance.player.spaceship:SendGiftToChar(self.m_charId, giftIds, nums);
end
HL.Commit(FriendShipPresentCtrl)