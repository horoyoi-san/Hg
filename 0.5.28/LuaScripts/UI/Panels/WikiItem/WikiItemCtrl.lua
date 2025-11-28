local wikiDetailBaseCtrl = require_ex('UI/Panels/WikiDetailBase/WikiDetailBaseCtrl')
local PANEL_ID = PanelId.WikiItem
WikiItemCtrl = HL.Class('WikiItemCtrl', wikiDetailBaseCtrl.WikiDetailBaseCtrl)
local SHOW_CRAFT_TREE_GROUP_TABLE = { wiki_group_item_nature = true, wiki_group_item_material = true, wiki_group_item_product = true, wiki_group_item_usable = true, }
WikiItemCtrl.GetPanelId = HL.Override().Return(HL.Number) << function(self)
    return PANEL_ID
end
WikiItemCtrl._RefreshCenter = HL.Override() << function(self)
    WikiItemCtrl.Super._RefreshCenter(self)
    local _, itemData = Tables.itemTable:TryGetValue(self.m_wikiEntryShowData.wikiEntryData.refItemId)
    self.view.wikiItemImg.gameObject:SetActive(itemData ~= nil)
    if itemData then
        self.view.wikiItemImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, itemData.iconId)
    end
end
WikiItemCtrl.m_isBtnInited = HL.Field(HL.Boolean) << false
WikiItemCtrl._RefreshRight = HL.Override() << function(self)
    local view = self.view.right
    if not self.m_isBtnInited then
        self.m_isBtnInited = true
        view.viewBtn.onClick:AddListener(function()
            self.m_phase:CreatePhasePanelItem(PanelId.WikiCraftingTree, { wikiEntryShowData = self.m_wikiEntryShowData })
        end)
    end
    view.viewBtn.gameObject:SetActive(SHOW_CRAFT_TREE_GROUP_TABLE[self.m_wikiEntryShowData.wikiGroupData.groupId] == true)
    local itemId = self.m_wikiEntryShowData.wikiEntryData.refItemId
    view.itemObtainWaysForWiki:InitItemObtainWays(itemId, nil, self.m_itemTipsPosInfo)
    view.itemAsInput:InitItemAsInput { itemId = itemId, itemTipsPosInfo = self.m_itemTipsPosInfo, }
end
HL.Commit(WikiItemCtrl)