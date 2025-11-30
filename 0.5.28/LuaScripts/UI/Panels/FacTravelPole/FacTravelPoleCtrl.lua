local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacTravelPole
FacTravelPoleCtrl = HL.Class('FacTravelPoleCtrl', uiCtrl.UICtrl)
FacTravelPoleCtrl.s_messages = HL.StaticField(HL.Table) << {}
FacTravelPoleCtrl.m_nodeId = HL.Field(HL.Any)
FacTravelPoleCtrl.m_isUpgraded = HL.Field(HL.Boolean) << false
FacTravelPoleCtrl.m_hasDefaultNext = HL.Field(HL.Boolean) << false
FacTravelPoleCtrl.m_currPoleMarkInstId = HL.Field(HL.String) << ""
FacTravelPoleCtrl.m_uiInfo = HL.Field(CS.Beyond.Gameplay.RemoteFactory.BuildingUIInfo_TravelPole)
FacTravelPoleCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_uiInfo = arg.uiInfo
    local nodeId = self.m_uiInfo.nodeId
    self.m_nodeId = nodeId
    self.view.buildingCommon:InitBuildingCommon(self.m_uiInfo)
    self:_InitMapNode()
    self:_RefreshBasicContent()
    self:_RefreshTravelPoleMapOrder()
end
FacTravelPoleCtrl._InitMapNode = HL.Method() << function(self)
    self.view.mapMask.gameObject:SetActive(false)
    self.view.emptyNode.gameObject:SetActive(true)
    if DataManager.uiLevelMapConfig.levelConfigInfos:ContainsKey(self.m_uiInfo.nodeHandler.belongScene.sceneIdStr) then
        local success, markInstId = GameInstance.player.mapManager:GetFacMarkInstIdByNodeId(self.m_uiInfo.chapterId, self.m_uiInfo.nodeId)
        if success then
            self.m_currPoleMarkInstId = markInstId
            self.view.levelMapController:InitLevelMapController(MapConst.LEVEL_MAP_CONTROLLER_MODE.FIXED, {
                fixedMarkInstId = markInstId,
                hidePlayer = true,
                customRefreshMark = function(markViewData)
                    self:_RefreshTravelPoleMapMark(markViewData)
                end
            })
            self.view.mapMask.gameObject:SetActive(true)
            self.view.emptyNode.gameObject:SetActive(false)
        end
    end
end
FacTravelPoleCtrl._GetAllRegionTravelPolesCount = HL.Method().Return(HL.Number) << function(self)
    local levelId = self.m_uiInfo.nodeHandler.belongScene.sceneIdStr
    local nodeType = self.m_uiInfo.nodeHandler.nodeType
    local travelPoleDataList = GameInstance.player.mapManager:GetFacMarkDataListByLevelIdAndType(levelId, nodeType)
    local count = 0
    for travelPoleData, _ in cs_pairs(travelPoleDataList) do
        if travelPoleData.isInFacRegion then
            count = count + 1
        end
    end
    return count
end
FacTravelPoleCtrl._RefreshBasicContent = HL.Method() << function(self)
    self.m_isUpgraded = GameInstance.world.gameMechManager.travelPoleBrain:CheckTravelPoleIsUpgraded(self.m_nodeId)
    self.m_hasDefaultNext = GameInstance.world.gameMechManager.travelPoleBrain:CheckTravelPoleHasDefaultNext(self.m_nodeId)
    self.view.defaultNextTipsNode.gameObject:SetActiveIfNecessary(self.m_isUpgraded and self.m_hasDefaultNext)
    local sceneMsg = FactoryUtils.getCurSceneHandler()
    if sceneMsg ~= nil then
        local isInFacRegion = CS.Beyond.Gameplay.RemoteFactory.RemoteFactoryUtil.IsNodeIncludedInMainRegion(self.m_uiInfo.nodeHandler)
        if isInFacRegion then
            self.view.regionNumberTxt.text = string.format("%d", self:_GetAllRegionTravelPolesCount())
        else
            local bandwidth = self.m_uiInfo.nodeHandler.belongBandwidth
            self.view.currentNumberTxt.text = string.format("%d", bandwidth.travelPoleCurrent)
            self.view.maxNumberTxt.text = string.format("%d", bandwidth.travelPoleMax)
            local textColor = bandwidth.travelPoleCurrent >= bandwidth.travelPoleMax and self.view.config.COLOR_MAX or self.view.config.COLOR_NORMAL
            self.view.currentNumberTxt.color = textColor
        end
        self.view.regionNumber.gameObject:SetActive(isInFacRegion)
        self.view.outRegionNumber.gameObject:SetActive(not isInFacRegion)
        self.view.regionTitle.gameObject:SetActive(isInFacRegion)
        self.view.outRegionTitle.gameObject:SetActive(not isInFacRegion)
    end
end
FacTravelPoleCtrl._RefreshTravelPoleMapOrder = HL.Method() << function(self)
    self.view.levelMapController.view.travelLine:SetParent(self.view.levelMapController.view.staticElementBackRoot)
end
FacTravelPoleCtrl._RefreshTravelPoleMapMark = HL.Method(HL.Table) << function(self, markViewData)
    if markViewData == nil then
        return
    end
    local isTypeVisible = markViewData.filterType == GEnums.MarkInfoType.TravelPole:GetHashCode() or markViewData.filterType == GEnums.MarkInfoType.HUB:GetHashCode()
    markViewData.mark.gameObject:SetActive(isTypeVisible)
    if markViewData.instId == self.m_currPoleMarkInstId then
        markViewData.mark.canvasGroup.color = self.view.config.CURRENT_MARK_COLOR
        self.view.currentHintNode.position = markViewData.mark.rectTransform.position
        markViewData.mark.rectTransform:SetParent(self.view.levelMapController.view.currentMarkRoot)
    end
end
HL.Commit(FacTravelPoleCtrl)