local wikiDetailBaseCtrl = require_ex('UI/Panels/WikiDetailBase/WikiDetailBaseCtrl')
local PANEL_ID = PanelId.WikiBuilding
WikiBuildingCtrl = HL.Class('WikiBuildingCtrl', wikiDetailBaseCtrl.WikiDetailBaseCtrl)
local DETAIL_TITLE_TEXT = { ["wiki_group_building_source"] = Language.ui_wiki_building_mine, ["wiki_group_building_basic"] = Language.ui_wiki_building_usable_formula, ["wiki_group_building_assemble"] = Language.ui_wiki_building_usable_formula, ["wiki_group_building_logistic"] = Language.ui_wiki_building_extra, ["wiki_group_building_electric"] = Language.ui_wiki_building_extra, ["wiki_group_building_extra"] = Language.ui_wiki_building_extra, ["wiki_group_building_battle"] = Language.ui_wiki_building_battle, ["wiki_group_building_soil"] = Language.ui_wiki_building_soil, }
local HIDE_CRAFT_TREE_GROUP_TABLE = { wiki_group_building_logistic = true, }
WikiBuildingCtrl.GetPanelId = HL.Override().Return(HL.Number) << function(self)
    return PANEL_ID
end
WikiBuildingCtrl._OnPhaseItemBind = HL.Override() << function(self)
    WikiBuildingCtrl.Super._OnPhaseItemBind(self)
    self:_RefreshModel(true)
end
WikiBuildingCtrl._RefreshCenter = HL.Override() << function(self)
    WikiBuildingCtrl.Super._RefreshCenter(self)
    self:_RefreshModel()
end
WikiBuildingCtrl.m_isBtnInited = HL.Field(HL.Boolean) << false
WikiBuildingCtrl._RefreshRight = HL.Override() << function(self)
    local view = self.view.right
    local itemId = self.m_wikiEntryShowData.wikiEntryData.refItemId
    if not self.m_isBtnInited then
        self.m_isBtnInited = true
        view.viewBtn.onClick:AddListener(function()
            self.m_phase:CreatePhasePanelItem(PanelId.WikiCraftingTree, { wikiEntryShowData = self.m_wikiEntryShowData })
        end)
    end
    view.viewBtn.gameObject:SetActive(HIDE_CRAFT_TREE_GROUP_TABLE[self.m_wikiEntryShowData.wikiGroupData.groupId] ~= true)
    view.itemObtainWaysForWiki:InitItemObtainWays(itemId, nil, self.m_itemTipsPosInfo)
    self:_RefreshDetail(itemId)
end
WikiBuildingCtrl.m_craftCellCache = HL.Field(HL.Forward("UIListCache"))
WikiBuildingCtrl._RefreshDetail = HL.Method(HL.String) << function(self, itemId)
    local view = self.view.right.itemDetail
    local craftCount = 0
    local craftInfos
    local buildingData = FactoryUtils.getItemBuildingData(itemId)
    if buildingData then
        craftInfos = FactoryUtils.getBuildingCrafts(buildingData.id)
        craftCount = #craftInfos
    end
    if not self.m_craftCellCache then
        self.m_craftCellCache = UIUtils.genCellCache(view.craftCell)
    end
    self.m_craftCellCache:Refresh(craftCount, function(craftCell, index)
        local craftInfo = craftInfos[index]
        craftInfo.buildingId = nil
        craftInfo.time = nil
        craftCell:InitCraftCell(craftInfo, self.m_itemTipsPosInfo)
    end)
    view.obtainTitle.text = DETAIL_TITLE_TEXT[self.m_wikiEntryShowData.wikiGroupData.groupId]
    local desc = self.m_wikiEntryShowData.wikiEntryData.desc
    view.emptyText.gameObject:SetActive(craftCount == 0 and string.isEmpty(desc))
    view.descTxt.gameObject:SetActive(not string.isEmpty(desc))
    view.descTxt.text = UIUtils.resolveTextStyle(desc)
end
WikiBuildingCtrl._RefreshModel = HL.Method(HL.Opt(HL.Boolean)) << function(self, playInAnim)
    if self.m_phase then
        self.m_phase:ShowModel(self.m_wikiEntryShowData, { playInAnim = playInAnim })
        self.m_phase:ActiveEntryVirtualCamera(true)
        local isShowImg = lume.find(WikiConst.BUILDING_SHOW_IMG_GROUP_ID_LIST, self.m_wikiEntryShowData.wikiGroupData.groupId) ~= nil
        self.view.wikiItemImg.gameObject:SetActive(isShowImg)
        if isShowImg then
            self.m_phase:DestroyModel()
            local _, itemData = Tables.itemTable:TryGetValue(self.m_wikiEntryShowData.wikiEntryData.refItemId)
            if itemData then
                self.view.wikiItemImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, itemData.iconId)
            end
        end
    end
end
HL.Commit(WikiBuildingCtrl)