local MAX_REPORT_COUNT = 3
local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SpaceshipDailyReport
local PHASE_ID = PhaseId.SpaceshipDailyReport
SpaceshipDailyReportCtrl = HL.Class('SpaceshipDailyReportCtrl', uiCtrl.UICtrl)
SpaceshipDailyReportCtrl.s_messages = HL.StaticField(HL.Table) << {}
SpaceshipDailyReportCtrl.m_reportInfos = HL.Field(HL.Table)
SpaceshipDailyReportCtrl.m_curIndex = HL.Field(HL.Number) << -1
SpaceshipDailyReportCtrl.m_roomCellCache = HL.Field(HL.Forward('UIListCache'))
SpaceshipDailyReportCtrl.m_dayTabCache = HL.Field(HL.Forward('UIListCache'))
SpaceshipDailyReportCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeBtn.onClick:AddListener(function()
        PhaseManager:PopPhase(PHASE_ID)
    end)
    self.view.btnLeft.onClick:AddListener(function()
        self:_ChangeToDay(self.m_curIndex + 1)
    end)
    self.view.btnRight.onClick:AddListener(function()
        self:_ChangeToDay(self.m_curIndex - 1)
    end)
    self.m_roomCellCache = UIUtils.genCellCache(self.view.roomCell)
    self.m_dayTabCache = UIUtils.genCellCache(self.view.dayTabCell)
    self:_InitData()
end
SpaceshipDailyReportCtrl._InitData = HL.Method() << function(self)
    self.m_reportInfos = {}
    local curDayStartTimestamp = DateTimeUtils.GetServerCurBelongedDayStartTimestamp()
    local secondsPerDay = 24 * 3600
    local dayStartTimestamps = {}
    local roomReportInfoByTs = {}
    for k = 1, MAX_REPORT_COUNT do
        local ts = curDayStartTimestamp - (k - 1) * secondsPerDay
        table.insert(dayStartTimestamps, ts)
        roomReportInfoByTs[ts] = {}
    end
    local spaceship = GameInstance.player.spaceship
    for roomId, room in pairs(spaceship.rooms) do
        local data = Tables.spaceshipRoomInsTable[roomId]
        local haveTodayReport = false
        local isCC = data.roomType == GEnums.SpaceshipRoomType.ControlCenter
        for ts, report in pairs(room.reports) do
            if roomReportInfoByTs[ts] then
                if ts == curDayStartTimestamp then
                    haveTodayReport = true
                end
                table.insert(roomReportInfoByTs[ts], { id = roomId, isCC = isCC, sortId = data.sortId, room = room, data = data, report = report, })
            end
        end
        if not haveTodayReport then
            table.insert(roomReportInfoByTs[curDayStartTimestamp], { id = roomId, isCC = isCC, sortId = data.sortId, room = room, data = data, })
        end
    end
    for k, ts in ipairs(dayStartTimestamps) do
        local roomReports = roomReportInfoByTs[ts]
        if next(roomReports) then
            table.sort(roomReports, Utils.genSortFunction({ "sortId" }))
            table.insert(self.m_reportInfos, { ts = ts, roomReports = roomReports, })
        end
    end
    local dayCount = #self.m_reportInfos
    self.m_dayTabCache:Refresh(dayCount)
    self:_ChangeToDay(1)
end
SpaceshipDailyReportCtrl._ChangeToDay = HL.Method(HL.Number) << function(self, index)
    self.m_curIndex = index
    self.m_dayTabCache:Get(index).toggle.isOn = true
    self:_RefreshRoomCells()
    self:_RefreshBottom()
end
SpaceshipDailyReportCtrl._RefreshRoomCells = HL.Method() << function(self)
    local info = self.m_reportInfos[self.m_curIndex]
    self.m_roomCellCache:Refresh(#info.roomReports, function(cell, index)
        self:_OnUpdateRoomCell(cell, index)
    end)
end
SpaceshipDailyReportCtrl._RefreshBottom = HL.Method() << function(self)
    local info = self.m_reportInfos[self.m_curIndex]
    local isToday = self.m_curIndex == 1
    self.view.todayHint.gameObject:SetActive(isToday)
    self.view.btnLeft.interactable = self.m_curIndex < #self.m_reportInfos
    self.view.btnRight.interactable = self.m_curIndex > 1
    local dateNode = self.view.dateNode
    dateNode.animationWrapper:PlayInAnimation()
    dateNode.simpleStateController:SetState(isToday and "Today" or "NotToday")
    local offsetSeconds = Utils.getServerTimeZoneOffsetSeconds()
    dateNode.dateTxt.text = os.date("!%m.%d", info.ts + offsetSeconds)
    if isToday then
        dateNode.startTimeTxt.text = string.format("%02d:00", DateTimeUtils.GAME_DAY_DIVISION_HOUR)
        local curTs = DateTimeUtils.GetCurrentTimestampBySeconds()
        local cutTxt = os.date("!%H:%M", curTs + Utils.getServerTimeZoneOffsetSeconds())
        if curTs - info.ts >= (24 - DateTimeUtils.GAME_DAY_DIVISION_HOUR) * 3600 then
            cutTxt = cutTxt .. "(+1)"
        end
        dateNode.curTimeTxt.text = cutTxt
    end
end
SpaceshipDailyReportCtrl._OnUpdateRoomCell = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local info = self.m_reportInfos[self.m_curIndex].roomReports[index]
    local roomInfo = info.room
    local roomTypeData = Tables.spaceshipRoomTypeTable[info.data.roomType]
    cell.icon:LoadSprite(UIConst.UI_SPRITE_SPACESHIP_ROOM, roomTypeData.icon)
    cell.nameTxt.text = info.data.name
    cell.iconBg.color = UIUtils.getColorByString(roomTypeData.color)
    local typeTxtStr = SpaceshipConst.TYPE_TXT_MAP[roomInfo.type]
    if typeTxtStr then
        cell.typeNode.gameObject:SetActive(true)
        cell.typeTxt.text = typeTxtStr
    else
        cell.typeNode.gameObject:SetActive(false)
    end
    local isToday = self.m_curIndex == 1
    if not cell.m_charCells then
        cell.m_charCells = UIUtils.genCellCache(cell.charCell)
    end
    local chars = {}
    local stationedChars = {}
    local charDivideLineIndex
    if isToday then
        local maxCount = roomInfo.maxLvStationCount
        local curMaxCount = roomInfo.maxStationCharNum
        local curCount = roomInfo.stationedCharList.Count
        for k = 1, maxCount do
            local cInfo = {}
            if k <= curCount then
                cInfo.charId = roomInfo.stationedCharList[CSIndex(k)]
                stationedChars[cInfo.charId] = true
            elseif k <= curMaxCount then
                cInfo.isEmpty = true
            else
                cInfo.isLocked = true
            end
            table.insert(chars, cInfo)
        end
        charDivideLineIndex = maxCount
    end
    if info.report then
        for _, charId in pairs(info.report.charWorkRecord) do
            if not stationedChars[charId] then
                table.insert(chars, { charId = charId })
            end
        end
    end
    cell.m_charCells:Refresh(#chars, function(charCell, charIndex)
        self:_OnUpdateCharCell(charCell, chars[charIndex], info)
        charCell.transform:SetSiblingIndex(CSIndex(charIndex))
    end)
    if charDivideLineIndex and #chars > charDivideLineIndex then
        cell.charDivideLine.gameObject:SetActive(true)
        cell.charDivideLine.transform:SetSiblingIndex(charDivideLineIndex)
    else
        cell.charDivideLine.gameObject:SetActive(false)
    end
    if info.isCC then
        cell.emptyHint.gameObject:SetActive(false)
        cell.itemNode.gameObject:SetActive(false)
    else
        local items = {}
        if info.report then
            for itemId, count in pairs(info.report.outputs) do
                local itemData = Tables.itemTable[itemId]
                table.insert(items, { id = itemId, count = count, sortId1 = itemData.sortId1, sortId2 = itemData.sortId2, rarity = itemData.rarity, })
            end
            table.sort(items, Utils.genSortFunction(UIConst.COMMON_ITEM_SORT_KEYS))
        end
        if not cell.m_itemCells then
            cell.m_itemCells = UIUtils.genCellCache(cell.item)
        end
        if next(items) then
            cell.emptyHint.gameObject:SetActive(false)
            cell.itemNode.gameObject:SetActive(true)
            cell.m_itemCells:Refresh(#items, function(itemCell, itemIndex)
                itemCell:InitItem(items[itemIndex], true)
            end)
        else
            cell.emptyHint.gameObject:SetActive(true)
            cell.itemNode.gameObject:SetActive(false)
        end
    end
end
SpaceshipDailyReportCtrl._OnUpdateCharCell = HL.Method(HL.Table, HL.Table, HL.Table) << function(self, charCell, info, roomReport)
    if info.isLocked then
        charCell.charHead.view.simpleStateController:SetState("Locked")
        return
    elseif info.isEmpty then
        charCell.charHead.view.simpleStateController:SetState("Empty")
        return
    end
    charCell.charHead.view.simpleStateController:SetState("Normal")
    local charId = info.charId
    charCell.charHead:InitSSCharHeadCell({
        charId = charId,
        targetRoomId = roomReport.id,
        onClick = function()
            Notify(MessageConst.SHOW_SPACESHIP_CHAR_TIPS, { key = charCell.transform, charId = charId, transform = charCell.transform, })
        end,
    })
    if not roomReport.isCC then
        charCell.friendshipChangeNode.gameObject:SetActive(false)
        return
    end
    charCell.friendshipChangeNode.gameObject:SetActive(true)
    local curFriendship = GameInstance.player.spaceship.characters:get_Item(charId).friendship
    for k = 1, self.m_curIndex - 1 do
        local otherDayTs = self.m_reportInfos[k].ts
        local succ, r = roomReport.room.reports:TryGetValue(otherDayTs)
        if succ then
            local succ2, addedValue = r.outputs:TryGetValue(charId)
            if succ2 then
                curFriendship = curFriendship - addedValue
            end
        end
    end
    local finalPercent = math.floor(CSPlayerDataUtil.GetFriendshipPercent(curFriendship) * 100)
    local addedValue
    if roomReport.report then
        _, addedValue = roomReport.report.outputs:TryGetValue(charId)
    end
    local startPercent = math.floor(CSPlayerDataUtil.GetFriendshipPercent(curFriendship - (addedValue or 0)) * 100)
    charCell.friendshipTxt.text = string.format(Language.LUA_SPACESHIP_CHAR_FRIENDSHIP_FORMAT, finalPercent)
    charCell.addedFriendshipTxt.text = string.format(Language.LUA_SPACESHIP_CHAR_FRIENDSHIP_FORMAT, startPercent)
end
HL.Commit(SpaceshipDailyReportCtrl)