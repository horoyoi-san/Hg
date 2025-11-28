local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
WikiItemInfo = HL.Class('WikiItemInfo', UIWidgetBase)
local CATEGORY_TYPE_TO_REFRESH_FUNC = { [WikiConst.EWikiCategoryType.Weapon] = "_RefreshWeapon", [WikiConst.EWikiCategoryType.Equip] = "_RefreshEquip", [WikiConst.EWikiCategoryType.Item] = "_RefreshItem", [WikiConst.EWikiCategoryType.Monster] = "_RefreshMonster", [WikiConst.EWikiCategoryType.Building] = "_RefreshBuilding", [WikiConst.EWikiCategoryType.Tutorial] = "_RefreshTutorial", }
WikiItemInfo.m_tagListCache = HL.Field(HL.Forward("UIListCache"))
WikiItemInfo.m_starListCache = HL.Field(HL.Forward("UIListCache"))
WikiItemInfo.m_descListCache = HL.Field(HL.Forward("UIListCache"))
WikiItemInfo.m_itemData = HL.Field(HL.Userdata)
WikiItemInfo.m_onDetailBtnClicked = HL.Field(HL.Function)
WikiItemInfo._OnFirstTimeInit = HL.Override() << function(self)
    self.m_tagListCache = UIUtils.genCellCache(self.view.tagCell)
    self.m_starListCache = UIUtils.genCellCache(self.view.starCell)
    self.m_descListCache = UIUtils.genCellCache(self.view.descCell)
    self.view.detailBtn.onClick:AddListener(function()
        if self.m_onDetailBtnClicked then
            self.m_onDetailBtnClicked()
        end
    end)
end
WikiItemInfo.InitWikiItemInfo = HL.Method(HL.Table) << function(self, args)
    self:_FirstTimeInit()
    self.m_onDetailBtnClicked = args.onDetailBtnClick
    self.view.star.gameObject:SetActive(false)
    self.view.tagNode.gameObject:SetActive(false)
    self.view.tacticalItemDescNode.gameObject:SetActive(false)
    local hasValue
    hasValue, self.m_itemData = Tables.itemTable:TryGetValue(args.wikiEntryShowData.wikiEntryData.refItemId)
    if args.itemImg then
        args.itemImg.gameObject:SetActive(false)
    end
    if args.wikiGuideMediaCell then
        args.wikiGuideMediaCell.gameObject:SetActive(false)
    end
    self.view.circleLightImg.gameObject:SetActive(args.wikiEntryShowData.wikiCategoryType ~= WikiConst.EWikiCategoryType.Monster)
    self[CATEGORY_TYPE_TO_REFRESH_FUNC[args.wikiEntryShowData.wikiCategoryType]](self, args)
    if args.hideDetailBtn then
        self.view.detailBtn.gameObject:SetActive(false)
    end
end
WikiItemInfo._RefreshWeapon = HL.Method(HL.Table) << function(self, args)
    self:_InitItemInfo(args)
    self.view.star.gameObject:SetActive(true)
    self.m_starListCache:Refresh(self.m_itemData.rarity)
end
WikiItemInfo._RefreshEquip = HL.Method(HL.Table) << function(self, args)
    self.view.detailBtn.gameObject:SetActive(false)
    self:_InitItemInfo(args)
end
WikiItemInfo._RefreshItem = HL.Method(HL.Table) << function(self, args)
    self.view.detailBtn.gameObject:SetActive(false)
    self:_InitItemInfo(args)
    self:_InitTags(self:_GetItemTags())
end
WikiItemInfo._RefreshMonster = HL.Method(HL.Table) << function(self, args)
    self.view.star.gameObject:SetActive(false)
    local monsterTemplateId = args.wikiEntryShowData.wikiEntryData.refMonsterTemplateId
    local monsterDisplayData
    local hasValue
    hasValue, monsterDisplayData = Tables.enemyTemplateDisplayInfoTable:TryGetValue(monsterTemplateId)
    self.view.descNode.gameObject:SetActive(true)
    if monsterDisplayData then
        self.view.nameTxt.text = monsterDisplayData.name
        local desc = { monsterDisplayData.description }
        self.m_descListCache:Refresh(#desc, function(cell, index)
            cell.descTxt.text = UIUtils.resolveTextStyle(desc[index])
        end)
        local tags = {}
        for _, tagId in pairs(monsterDisplayData.tags) do
            if tagId then
                local _, monsterTagInfo = Tables.EnemyTagTable:TryGetValue(tagId)
                if monsterTagInfo then
                    table.insert(tags, monsterTagInfo.tagText)
                end
            end
        end
        self:_InitTags(tags)
    end
    local displayType = monsterDisplayData.displayType
    if not displayType then
        return
    end
    local _, displayTypeInfo = Tables.displayEnemyTypeTable:TryGetValue(displayType)
    if displayTypeInfo then
        self.view.typeTxt.text = displayTypeInfo.name
    end
    if args.itemImg then
        args.itemImg.gameObject:SetActive(true)
        args.itemImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_MONSTER_ICON_BIG, monsterDisplayData.templateId)
    end
end
WikiItemInfo._RefreshBuilding = HL.Method(HL.Table) << function(self, args)
    local isShowImg = lume.find(WikiConst.BUILDING_SHOW_IMG_GROUP_ID_LIST, args.wikiEntryShowData.wikiGroupData.groupId)
    self.view.detailBtn.gameObject:SetActive(not isShowImg)
    self:_InitItemInfo(args)
    self:_InitTags(self:_GetItemTags())
end
WikiItemInfo._RefreshTutorial = HL.Method(HL.Table) << function(self, args)
    self.view.nameTxt.text = args.wikiEntryShowData.wikiEntryData.desc
    self.view.typeTxt.text = args.wikiEntryShowData.wikiGroupData.groupName
    UIUtils.setItemRarityImage(self.view.circleLightImg, 1)
    UIUtils.setItemRarityImage(self.view.circleImg, 1)
    local _, tutorialPages = Tables.wikiTutorialPageByEntryTable:TryGetValue(args.wikiEntryShowData.wikiEntryData.id)
    if args.wikiGuideMediaCell and tutorialPages and #tutorialPages.pageIds > 0 then
        self.view.descNode.gameObject:SetActive(true)
        local pageId = tutorialPages.pageIds[0]
        args.wikiGuideMediaCell:InitWikiGuideMediaCell(pageId)
        local _, pageData = Tables.wikiTutorialPageTable:TryGetValue(pageId)
        self.m_descListCache:Refresh(1, function(cell, index)
            cell.descTxt.text = InputManager.ParseTextActionId(UIUtils.resolveTextStyle(pageData.content))
        end)
    end
end
WikiItemInfo._InitItemInfo = HL.Method(HL.Table) << function(self, args)
    self.view.typeTxt.text = args.wikiEntryShowData.wikiGroupData.groupName
    if self.m_itemData then
        self.view.nameTxt.text = self.m_itemData.name
        if args.itemImg then
            args.itemImg.gameObject:SetActive(true)
            args.itemImg.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, self.m_itemData.iconId)
        end
        local isTacticalItem, tacticalItemCfg = Tables.useItemTable:TryGetValue(self.m_itemData.id)
        self.view.tacticalItemDescNode.gameObject:SetActive(isTacticalItem)
        self.view.descNode.gameObject:SetActive(not isTacticalItem)
        if isTacticalItem then
            local tacticalView = self.view.tacticalItemDescNode
            tacticalView.tacticalDescTxt.text = UIUtils.resolveTextStyle(UIUtils.getItemUseDesc(self.m_itemData.id))
            local isEquipUnlock = Utils.isSystemUnlocked(GEnums.UnlockSystemType.Equip)
            local isEquipItem, equipItemCfg = Tables.equipItemTable:TryGetValue(self.m_itemData.id)
            tacticalView.equipTitleTxt.gameObject:SetActive(isEquipUnlock and isEquipItem)
            tacticalView.equipDescNode.gameObject:SetActive(isEquipUnlock and isEquipItem)
            if isEquipUnlock and isEquipItem then
                tacticalView.equipDescTxt.text = UIUtils.resolveTextStyle(UIUtils.getItemEquippedDesc(self.m_itemData.id))
            end
            tacticalView.descTxt.text = self.m_itemData.decoDesc
        else
            local desc = {}
            if not string.isEmpty(self.m_itemData.desc) then
                table.insert(desc, self.m_itemData.desc)
            end
            if not string.isEmpty(self.m_itemData.decoDesc) then
                table.insert(desc, self.m_itemData.decoDesc)
            end
            if args.wikiEntryShowData.wikiCategoryType == WikiConst.EWikiCategoryType.Item and not FactoryUtils.isFactoryItemFluid(self.m_itemData.id) then
                local storageDesc
                local _, itemTypeData = Tables.itemTypeTable:TryGetValue(self.m_itemData.type)
                if itemTypeData then
                    if itemTypeData.storageSpace == GEnums.ItemStorageSpace.ValuableDepot then
                        storageDesc = Language.ui_wiki_item_in_valuable
                    elseif itemTypeData.storageSpace == GEnums.ItemStorageSpace.BagAndFactoryDepot then
                        storageDesc = Language.ui_wiki_item_in_bag
                    end
                end
                if storageDesc then
                    table.insert(desc, storageDesc)
                end
            end
            self.m_descListCache:Refresh(#desc, function(cell, index)
                cell.descTxt.text = desc[index]
            end)
        end
        UIUtils.setItemRarityImage(self.view.circleLightImg, self.m_itemData.rarity)
        UIUtils.setItemRarityImage(self.view.circleImg, self.m_itemData.rarity)
    end
end
WikiItemInfo._GetItemTags = HL.Method().Return(HL.Table) << function(self)
    local tags = {}
    if self.m_itemData then
        local hasTag, tagIdList = UIUtils.tryGetTagList(self.m_itemData.id, self.m_itemData.type)
        if hasTag then
            for i = 0, tagIdList.Count - 1 do
                local tagId = tagIdList[i]
                local _, tagData = Tables.factoryIngredientTagTable:TryGetValue(tagId)
                table.insert(tags, tagData.tagLabel)
            end
        end
    end
    return tags
end
WikiItemInfo._InitTags = HL.Method(HL.Table) << function(self, tags)
    if tags == nil or #tags == 0 then
        return
    end
    self.view.tagNode.gameObject:SetActive(true)
    self.m_tagListCache:Refresh(#tags, function(cell, index)
        local tag = tags[index]
        cell.nameTxt.text = tag
    end)
end
WikiItemInfo._InitBuilding = HL.Method(HL.Userdata) << function(self, itemData)
    local buildingId = FactoryUtils.getItemBuildingId(itemData.id)
    local hasValue
    local buildingData
    hasValue, buildingData = Tables.factoryBuildingTable:TryGetValue(buildingId)
    local subTitle = ""
    if hasValue and buildingData.powerConsume > 0 then
        subTitle = string.format(Language.LUA_WIKI_POWER_SUBTITLE_FORMAT, buildingData.powerConsume)
    end
    self.view.txtSubTitle.text = subTitle
end
HL.Commit(WikiItemInfo)
return WikiItemInfo