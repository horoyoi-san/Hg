local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local MapSpaceshipNode = require_ex('UI/Widgets/MapSpaceshipNode')
local PANEL_ID = PanelId.RegionMap
RegionMapCtrl = HL.Class('RegionMapCtrl', uiCtrl.UICtrl)
local MINI_POWER_HOVER_TEXT_ID = "ui_mappanel_collection_electricity"
RegionMapCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_CLICK_REGIONMAP_LOCK] = '_OnClickLevelBtn', [MessageConst.SWITCH_TO_LEVEL_MAP] = '_SwitchToLevelMap', [MessageConst.ON_SYSTEM_UNLOCK] = '_OnSystemUnlock', }
RegionMapCtrl.m_mapManager = HL.Field(HL.Userdata)
RegionMapCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local args = arg
    self.domainId = args.domainId
    self.m_mapManager = GameInstance.player.mapManager
    self.view.btnClose.onClick:AddListener(function()
        AudioAdapter.PostEvent("Au_UI_Menu_RegionMapPanel_Close")
        MapSpaceshipNode.ClearStaticFromData()
        self:Notify(MessageConst.P_ON_COMMON_BACK_CLICKED)
    end)
    self:_InitDomainDropdown()
end
RegionMapCtrl._OnClickLevelBtn = HL.Method() << function(self)
    self.view.luaPanel.animationWrapper:PlayOutAnimation()
end
RegionMapCtrl._SwitchToLevelMap = HL.Method(HL.Table) << function(self, args)
    local levelId, insId = unpack(args)
    MapUtils.switchFromRegionMapToLevelMap(insId, levelId)
end
RegionMapCtrl.domainId = HL.Field(HL.String) << ""
RegionMapCtrl.SwitchDomain = HL.Method(HL.String) << function(self, domainId)
    self.domainId = domainId
    self:_RefreshBasicInfo()
    Notify(MessageConst.SWITCH_DOMAIN_MAP, { domainId = domainId })
end
RegionMapCtrl.m_domainDataList = HL.Field(HL.Table)
RegionMapCtrl.m_trackIconCellCache = HL.Field(HL.Table)
RegionMapCtrl._InitDomainDropdown = HL.Method() << function(self)
    self.m_domainDataList = {}
    local secondDomainFirstLevelId = nil
    local i, selectedIndex = 0, 0
    for _, domainData in pairs(Tables.domainDataTable) do
        local isDomainUnlocked = false
        for _, levelId in pairs(domainData.levelGroup) do
            if self.m_mapManager:IsLevelUnlocked(levelId) then
                isDomainUnlocked = true
                break
            end
        end
        if isDomainUnlocked then
            i = i + 1
            table.insert(self.m_domainDataList, domainData)
            if domainData.domainId == self.domainId then
                selectedIndex = i
            end
            if i == 2 then
                secondDomainFirstLevelId = domainData.levelGroup[0]
            end
        end
    end
    local domainCount = #self.m_domainDataList
    self.view.dropDownListUp.gameObject:SetActive(domainCount > 1)
    if domainCount <= 1 then
        self:SwitchDomain(Utils.getCurDomainId())
        return
    end
    local curDomainId = Utils.getCurDomainId()
    self.m_trackIconCellCache = {}
    self.view.dropDownListUp:Init(function(index, option, isSelected)
        local domainData = self.m_domainDataList[LuaIndex(index)]
        option:SetText(domainData.domainName)
        local optionNode = Utils.wrapLuaNode(option)
        local isPlayerInDomain = curDomainId == domainData.domainId and not Utils.isInSpaceShip()
        optionNode.imgPlayer.gameObject:SetActive(isPlayerInDomain)
        local hasValue
        local trackingMarkDataList = {}
        for levelId, markDataDic in pairs(self.m_mapManager.markMissionDataDict) do
            for _, markData in pairs(markDataDic) do
                if markData.isMissionTracking then
                    local levelBasicInfo
                    hasValue, levelBasicInfo = DataManager.levelBasicInfoTable:TryGetValue(levelId)
                    local domainId
                    if hasValue then
                        domainId = levelBasicInfo.domainName
                    end
                    if domainId == domainData.domainId then
                        table.insert(trackingMarkDataList, markData)
                        break
                    end
                end
            end
            if #trackingMarkDataList > 0 then
                break
            end
        end
        local cellCache = self.m_trackIconCellCache[index]
        if cellCache == nil then
            cellCache = UIUtils.genCellCache(optionNode.imgTrack)
            self.m_trackIconCellCache[index] = cellCache
        end
        local count = #trackingMarkDataList
        cellCache:Refresh(count, function(cell, luaIndex)
            local markData = trackingMarkDataList[luaIndex]
            local _, markTempData = Tables.mapMarkTempTable:TryGetValue(markData.templateId)
            if markTempData then
                cell.imgTrack.sprite = self:LoadSprite(UIConst.UI_SPRITE_MAP_ICON, markTempData.activeIcon)
            end
            cell.imgTrack.color = markData.color
        end)
    end, function(index)
        local domainData = self.m_domainDataList[LuaIndex(index)]
        self:SwitchDomain(domainData.domainId)
    end)
    self.view.dropDownListUp:Refresh(domainCount, CSIndex(selectedIndex))
    if secondDomainFirstLevelId then
        self.view.domainSelectionRedDot:InitRedDot("MapUnreadLevel", secondDomainFirstLevelId)
    end
    self.view.dropDownListUp.onToggleOptList:AddListener(function(isOpen)
        if isOpen and secondDomainFirstLevelId then
            GameInstance.player.mapManager:SendLevelReadMessage(secondDomainFirstLevelId)
        end
    end)
end
RegionMapCtrl._RefreshBasicInfo = HL.Method() << function(self)
    local hasValue, _
    local domainData
    hasValue, domainData = Tables.domainDataTable:TryGetValue(self.domainId)
    local domainName = hasValue and domainData.domainName or ""
    self.view.txtTitle.text = domainName
    local prosperity = 0
    prosperity, _ = GameInstance.player.settlementSystem:GetProsperityByDomainId(self.domainId)
    self.view.txtGrade.text = tostring(prosperity)
    self.view.walletBarPlaceholder:InitWalletBarPlaceholder(UIConst.REGION_MAP_STAMINA_IDS)
    self:_RefreshWalletNodeVisibleState()
    local chapterId = ScopeUtil.ChapterIdStr2Int(self.domainId)
    self.view.facMiniPowerContent:InitFacMiniPowerContent(chapterId)
    self.view.facMiniPowerContent.view.hoverButton.onHoverChange:RemoveAllListeners()
    self.view.facMiniPowerContent.view.hoverButton.onHoverChange:AddListener(function(isHover)
        if isHover then
            Notify(MessageConst.SHOW_COMMON_HOVER_TIP, { mainText = Language[MINI_POWER_HOVER_TEXT_ID], delay = self.view.config.MINI_POWER_HOVER_DELAY, })
        else
            Notify(MessageConst.HIDE_COMMON_HOVER_TIP)
        end
    end)
    self.view.mapSpaceshipNode:InitMapSpaceshipNode({ domainId = self.domainId })
    self.view.mapTrackingInfo:InitMapTrackingInfo({ domainId = self.domainId })
end
RegionMapCtrl._OnClickRegionMapLevelBtn = HL.Method(HL.Userdata) << function(self, markData)
    if markData == nil then
        return
    end
    if markData.levelId == nil or markData.insId == nil then
        return
    end
    local data = {}
    data.levelId = markData.levelId
    data.insId = markData.insId
    Notify(MessageConst.ON_CLICK_REGIONMAP_LEVEL_BTN, data)
end
RegionMapCtrl._OnSystemUnlock = HL.Method(HL.Table) << function(self, args)
    local systemIndex = unpack(args)
    if systemIndex == GEnums.UnlockSystemType.Dungeon:GetHashCode() then
        self:_RefreshWalletNodeVisibleState()
    end
end
RegionMapCtrl._RefreshWalletNodeVisibleState = HL.Method() << function(self)
    self.view.walletBarPlaceholder.gameObject:SetActive(Utils.isSystemUnlocked(GEnums.UnlockSystemType.Dungeon))
end
HL.Commit(RegionMapCtrl)