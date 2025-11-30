local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RegionMap3D
RegionMap3DCtrl = HL.Class('RegionMap3DCtrl', uiCtrl.UICtrl)
RegionMap3DCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.SWITCH_DOMAIN_MAP] = '_OnSwitchDomainMap', }
RegionMap3DCtrl.m_domainId = HL.Field(HL.String) << ""
RegionMap3DCtrl.m_loadedRegionMapSetting = HL.Field(HL.Table)
RegionMap3DCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local args = arg
    self.m_loadedRegionMapSetting = {}
    self.m_domainId = args.domainId
    self:_RefreshAll()
end
RegionMap3DCtrl._OnSwitchDomainMap = HL.Method(HL.Table) << function(self, args)
    self.m_domainId = args.domainId
    self:_RefreshAll()
end
RegionMap3DCtrl._RefreshAll = HL.Method() << function(self)
    local regionMapSetting = self:_GetDomainRegionMapSetting(self.m_domainId)
    if not regionMapSetting then
        return
    end
    for domainId, loadedRegionMapSetting in pairs(self.m_loadedRegionMapSetting) do
        loadedRegionMapSetting.gameObject:SetActive(domainId == self.m_domainId)
    end
    self.view.regionMap3DPanel:InitData(regionMapSetting)
    regionMapSetting:InitData(CS.Beyond.UI.RegionMapShowType.Map)
    for levelId, cfg in cs_pairs(regionMapSetting.cfg) do
        if cfg.isLoaded then
            local sceneBasicInfo = Utils.wrapLuaNode(cfg.ui)
            if sceneBasicInfo then
                local sceneBasicInfoArgs = {
                    levelId = levelId,
                    onClick = function(levelId)
                        self.view.regionMap3DPanel:OnClickLevelBtn(levelId, "")
                    end,
                    onHoverChanged = function(levelId, isHover)
                        self.view.regionMap3DPanel:OnLevelHoverChanged(levelId, isHover)
                    end,
                }
                sceneBasicInfo:InitSceneBasicInfo(sceneBasicInfoArgs)
            end
        end
    end
end
RegionMap3DCtrl._GetDomainRegionMapSetting = HL.Method(HL.String).Return(CS.Beyond.UI.RegionMapSetting) << function(self, domainId)
    local regionMapSetting = self.m_loadedRegionMapSetting[domainId]
    if regionMapSetting then
        return regionMapSetting
    end
    local _, domainData = Tables.domainDataTable:TryGetValue(domainId)
    if domainData == nil then
        return nil
    end
    local domainPrefab = self:LoadGameObject(string.format(MapConst.UI_DOMAIN_MAP_PATH, domainData.domainMap))
    local domainGo = CSUtils.CreateObject(domainPrefab, self.view.domainRoot[string.lower(domainData.domainMap)])
    local _, regionMapSetting = domainGo:TryGetComponent(typeof(CS.Beyond.UI.RegionMapSetting))
    self.m_loadedRegionMapSetting[domainId] = regionMapSetting
    return regionMapSetting
end
HL.Commit(RegionMap3DCtrl)