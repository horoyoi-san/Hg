local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
MapTrackingInfo = HL.Class('MapTrackingInfo', UIWidgetBase)
MapTrackingInfo.m_trackingListCache = HL.Field(HL.Forward("UIListCache"))
MapTrackingInfo.m_mapManager = HL.Field(HL.Userdata)
MapTrackingInfo.m_trackingInfoList = HL.Field(HL.Table)
MapTrackingInfo._OnFirstTimeInit = HL.Override() << function(self)
    self.m_trackingListCache = UIUtils.genCellCache(self.view.cellTracking)
end
MapTrackingInfo.InitMapTrackingInfo = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    self.m_mapManager = GameInstance.player.mapManager
    local hasValue
    self.m_trackingInfoList = {}
    local checkIsShowTrackingData = nil
    if not string.isEmpty(args.domainId) then
        checkIsShowTrackingData = function(levelId)
            local levelBasicInfo
            hasValue, levelBasicInfo = DataManager.levelBasicInfoTable:TryGetValue(levelId)
            local domainId
            if hasValue then
                domainId = levelBasicInfo.domainName
            end
            return domainId ~= args.domainId
        end
    elseif not string.isEmpty(args.levelId) then
        checkIsShowTrackingData = function(levelId)
            return levelId ~= args.levelId
        end
    end
    for levelId, markDataDic in cs_pairs(self.m_mapManager.markMissionDataDict) do
        if checkIsShowTrackingData and checkIsShowTrackingData(levelId) then
            for _, markData in cs_pairs(markDataDic) do
                if markData.isMissionTracking then
                    local _, markTempData = Tables.mapMarkTempTable:TryGetValue(markData.templateId)
                    if markTempData then
                        local trackingInfo = { name = markData.missionInfo.missionName:GetText(), instId = markData.instId, levelId = levelId, icon = markTempData.detailActiveIcon, color = markData.color, }
                        table.insert(self.m_trackingInfoList, trackingInfo)
                    end
                end
            end
        end
    end
    if not string.isEmpty(self.m_mapManager.trackingMarkInstId) then
        local markData
        hasValue, markData = self.m_mapManager:GetMarkInstRuntimeData(self.m_mapManager.trackingMarkInstId)
        if hasValue then
            local levelId = self.m_mapManager:GetMarkInstRuntimeDataLevelId(markData.instId)
            if checkIsShowTrackingData and checkIsShowTrackingData(levelId) then
                local markTempData
                hasValue, markTempData = Tables.mapMarkTempTable:TryGetValue(markData.templateId)
                if hasValue then
                    local trackingInfo = { name = markTempData.name, icon = markTempData.detailActiveIcon, instId = markData.instId, levelId = self.m_mapManager:GetMarkInstRuntimeDataLevelId(markData.instId), color = Color.white, }
                    table.insert(self.m_trackingInfoList, trackingInfo)
                end
            end
        end
    end
    local trackingCount = #self.m_trackingInfoList
    self.gameObject:SetActive(trackingCount > 0)
    if trackingCount == 0 then
        return
    end
    self.m_trackingListCache:Refresh(trackingCount, function(cell, index)
        local trackingInfo = self.m_trackingInfoList[index]
        cell.txtTitle.text = trackingInfo.name
        cell.imgTrackIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_MAP_ICON, trackingInfo.icon)
        cell.imgTrackIcon.color = trackingInfo.color
        cell.btn.onClick:RemoveAllListeners()
        cell.btn.onClick:AddListener(function()
            if PhaseManager:IsOpen(PhaseId.RegionMap) then
                PhaseManager:ExitPhaseFast(PhaseId.RegionMap)
            end
            MapUtils.openMap(trackingInfo.instId, trackingInfo.levelId)
        end)
    end)
end
HL.Commit(MapTrackingInfo)
return MapTrackingInfo