local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.FacTopViewBuildingInfo
local LuaNodeCache = require_ex("Common/Utils/LuaNodeCache")
FacTopViewBuildingInfoCtrl = HL.Class('FacTopViewBuildingInfoCtrl', uiCtrl.UICtrl)
FacTopViewBuildingInfoCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.FAC_TOGGLE_TOP_VIEW_BUILDING_INFO] = 'ToggleTopViewBuildingInfo', [MessageConst.FAC_ON_BUILDING_MOVED] = 'OnBuildingMoved', [MessageConst.FAC_ON_NODE_REMOVED] = 'OnNodeRemoved', [MessageConst.ON_FAC_TOP_VIEW_CAM_ZOOM] = 'OnFacTopViewCamZoom', }
FacTopViewBuildingInfoCtrl.m_isShowing = HL.Field(HL.Boolean) << false
FacTopViewBuildingInfoCtrl.m_updateCor = HL.Field(HL.Thread)
FacTopViewBuildingInfoCtrl.m_cellCache = HL.Field(LuaNodeCache)
FacTopViewBuildingInfoCtrl.m_cells = HL.Field(HL.Table)
FacTopViewBuildingInfoCtrl.m_onAddFunc = HL.Field(HL.Function)
FacTopViewBuildingInfoCtrl.m_onRemoveFunc = HL.Field(HL.Function)
FacTopViewBuildingInfoCtrl.m_onUpdateFunc = HL.Field(HL.Function)
FacTopViewBuildingInfoCtrl.m_padding = HL.Field(HL.Any)
FacTopViewBuildingInfoCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_cellCache = LuaNodeCache(self.view.buildingInfoCell, self.view.main)
    self.m_cells = {}
    self.m_onAddFunc = function(info)
        self:_OnAddInfo(info)
    end
    self.m_onRemoveFunc = function(nodeId)
        self:_OnRemoveInfo(nodeId)
    end
    self.m_onUpdateFunc = function(info)
        self:_OnUpdateInfo(info)
    end
    self.m_padding = CSFactoryUtil.Padding(self.view.config.PADDING_TOP, self.view.config.PADDING_LEFT, self.view.config.PADDING_RIGHT, self.view.config.PADDING_BOTTOM)
end
FacTopViewBuildingInfoCtrl.OnShow = HL.Override() << function(self)
    if self.m_isShowing then
        self:_UpdateInfos()
    end
    self.m_updateCor = self:_StartCoroutine(function()
        coroutine.step()
        self.view.main.gameObject:SetActive(true)
        while true do
            coroutine.step()
            if self.m_isShowing then
                self:_UpdateInfos()
            end
        end
    end)
    if LuaSystemManager.facSystem.m_topViewCamCtrl ~= nil then
        self:OnFacTopViewCamZoom(LuaSystemManager.facSystem.m_topViewCamCtrl.curZoomPercent)
    end
end
FacTopViewBuildingInfoCtrl.OnHide = HL.Override() << function(self)
    self.view.main.gameObject:SetActive(false)
    self.m_updateCor = self:_ClearCoroutine(self.m_updateCor)
end
FacTopViewBuildingInfoCtrl.OnClose = HL.Override() << function(self)
    self.m_updateCor = self:_ClearCoroutine(self.m_updateCor)
    self:_ClearCache()
end
FacTopViewBuildingInfoCtrl._ClearCache = HL.Method() << function(self)
    for _, cell in pairs(self.m_cells) do
        self.m_cellCache:Cache(cell)
    end
    self.m_cells = {}
end
FacTopViewBuildingInfoCtrl.ToggleTopViewBuildingInfo = HL.Method(HL.Boolean) << function(self, active)
    CSFactoryUtil.ClearTopViewBuildingInfos()
    if active then
        self:_ClearCache()
        self:Show()
        self.m_isShowing = true
        self:_UpdateAllInfos()
    else
        self.m_isShowing = false
        self:Hide()
        self:_ClearCache()
    end
end
FacTopViewBuildingInfoCtrl.OnBuildingMoved = HL.Method(HL.Table) << function(self, arg)
    self:OnNodeRemoved(arg)
end
FacTopViewBuildingInfoCtrl.OnNodeRemoved = HL.Method(HL.Table) << function(self, arg)
    local nodeId = unpack(arg)
    local cell = self.m_cells[nodeId]
    if cell then
        self:_OnRemoveInfo(nodeId)
    end
    if CSFactoryUtil.s_topViewBuildingInfos:ContainsKey(nodeId) then
        CSFactoryUtil.s_topViewBuildingInfos:Remove(nodeId)
    end
    self:_UpdateInfos()
end
FacTopViewBuildingInfoCtrl._UpdateAllInfos = HL.Method() << function(self)
    CSFactoryUtil.UpdateTopViewBuildingInfos(self.m_padding, nil, nil, nil)
    for _, info in pairs(CSFactoryUtil.s_topViewBuildingInfos) do
        self:_OnAddInfo(info)
    end
end
FacTopViewBuildingInfoCtrl._UpdateInfos = HL.Method() << function(self)
    CSFactoryUtil.UpdateTopViewBuildingInfos(self.m_padding, self.m_onAddFunc, self.m_onRemoveFunc, self.m_onUpdateFunc)
end
FacTopViewBuildingInfoCtrl._OnAddInfo = HL.Method(CS.Beyond.Gameplay.Factory.FactoryUtil.TopViewBuildingInfo) << function(self, info)
    local nodeId = info.nodeId
    local cell = self.m_cellCache:Get()
    local data = Tables.factoryBuildingTable[info.dataId]
    cell.name.text = data.name
    local sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_BUILDING_PANEL_ICON, data.iconOnPanel)
    cell.icon.sprite = sprite
    cell.iconShadow.sprite = sprite
    cell.elementFollower.followPosition = info.worldPos
    self:_OnUpdateInfo(info, cell)
    self.m_cells[nodeId] = cell
end
FacTopViewBuildingInfoCtrl._OnRemoveInfo = HL.Method(HL.Number) << function(self, nodeId)
    local cell = self.m_cells[nodeId]
    if cell then
        self.m_cellCache:Cache(cell)
        self.m_cells[nodeId] = nil
    end
end
FacTopViewBuildingInfoCtrl._OnUpdateInfo = HL.Method(CS.Beyond.Gameplay.Factory.FactoryUtil.TopViewBuildingInfo, HL.Opt(HL.Any)) << function(self, info, cell)
    local nodeId = info.nodeId
    if not cell then
        cell = self.m_cells[nodeId]
    end
    local state = GEnums.FacBuildingState.__CastFrom(info.lastState)
    local spriteName = FacConst.FAC_TOP_VIEW_BUILDING_STATE_TO_SPRITE[state]
    if spriteName then
        cell.stateNode.gameObject:SetActive(true)
        cell.stateIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_FAC_TOP_VIEW, spriteName)
    else
        cell.stateNode.gameObject:SetActive(false)
    end
    if info.itemCount > 0 then
        cell.productNode.gameObject:SetActive(true)
        if not cell.productCells then
            cell.productCells = UIUtils.genCellCache(cell.productCell)
        end
        cell.productCells:Refresh(info.itemCount, function(productCell, luaIndex)
            local itemId = info["item" .. CSIndex(luaIndex)]
            local itemData = Tables.itemTable[itemId]
            productCell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, itemData.iconId)
            UIUtils.setItemRarityImage(productCell.rarityLine, itemData.rarity)
        end)
    else
        cell.productNode.gameObject:SetActive(false)
    end
end
FacTopViewBuildingInfoCtrl.OnFacTopViewCamZoom = HL.Method(HL.Number) << function(self, zoomPercent)
    local scale = self.view.config.SIZE_ANIM_CURVE:Evaluate(zoomPercent)
    self.view.main.transform.localScale = Vector3(scale, scale, scale)
end
HL.Commit(FacTopViewBuildingInfoCtrl)