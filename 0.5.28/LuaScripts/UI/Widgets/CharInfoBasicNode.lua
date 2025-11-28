local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
CharInfoBasicNode = HL.Class('CharInfoBasicNode', UIWidgetBase)
do
    CharInfoBasicNode.m_starCellCache = HL.Field(HL.Forward("UIListCache"))
    CharInfoBasicNode.m_fcAttrCellCache = HL.Field(HL.Forward("UIListCache"))
    CharInfoBasicNode.m_scAttrCellCache = HL.Field(HL.Forward("UIListCache"))
    CharInfoBasicNode.m_imageSelectCache = HL.Field(HL.Table)
end
CharInfoBasicNode._OnFirstTimeInit = HL.Override() << function(self)
    self.m_starCellCache = UIUtils.genCellCache(self.view.starCell)
    self.m_fcAttrCellCache = UIUtils.genCellCache(self.view.firstClassAttributeCell)
    self.m_scAttrCellCache = UIUtils.genCellCache(self.view.secondClassAttributeCell)
    self.m_imageSelectCache = {}
    self:RegisterMessage(MessageConst.CHAR_INFO_SHOW_FC_ATTR_HINT, function(args)
        self:_RefreshImageSelect(args.cell)
    end)
    self:RegisterMessage(MessageConst.CHAR_INFO_SHOW_SC_ATTR_HINT, function(args)
        self:_RefreshImageSelect(args.cell)
    end)
    self:RegisterMessage(MessageConst.SHOW_CHAR_SKILL_TIP, function(args)
        self:_RefreshImageSelect(args.cell)
    end)
    self:RegisterMessage(MessageConst.CHAR_INFO_CLOSE_ATTR_TIP, function(args)
        self:_RefreshImageSelect()
    end)
    self:RegisterMessage(MessageConst.CHAR_INFO_CLOSE_SKILL_TIP, function(args)
        self:_RefreshImageSelect()
    end)
end
CharInfoBasicNode.InitCharInfoBasicNode = HL.Method(HL.Number, HL.Opt(HL.Boolean)) << function(self, charInstId, hideWhenOpenDetail)
    self:_FirstTimeInit()
    if charInstId == nil then
        return
    end
    local charInfo = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
    local templateId = charInfo.templateId
    local charCfg = Tables.characterTable[templateId]
    self.view.charNameText.text = charCfg.name
    self.view.professionIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_PROFESSION, UIConst.CHAR_PROFESSION_ICON_DICT[charCfg.profession])
    self.view.charElementIcon:InitCharTypeIcon(charCfg.charTypeId)
    self.view.friendshipNode:InitFriendshipNode(charInstId)
    self.m_starCellCache:Refresh(UIConst.CHAR_MAX_RARITY, function(cell, index)
        cell.gameObject:SetActive(index <= charCfg.rarity)
    end)
    local fcAttrShowList, scAttrShowList = CharInfoUtils.generateCharInfoBasicAttrShowInfo(charInstId)
    self.m_fcAttrCellCache:Refresh(#fcAttrShowList, function(cell, index)
        local showInfo = fcAttrShowList[index]
        local isMainAttrType = showInfo.attributeType == charCfg.mainAttrType
        local isSubAttrType = showInfo.attributeType == charCfg.subAttrType
        cell.bgImage.gameObject:SetActive(isMainAttrType or isSubAttrType)
        if isMainAttrType or isSubAttrType then
            cell.bgImage.color = isMainAttrType and self.view.config.ATTR_BG_COLOR_MAIN or self.view.config.ATTR_BG_COLOR_SUB
        end
        cell.valueText.text = showInfo.showValue
        cell.nameText.text = showInfo.showName
        cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ATTRIBUTE_ICON, UIConst.UI_ATTRIBUTE_ICON_PREFIX .. showInfo.attributeKey)
        cell.icon.color = (isMainAttrType or isSubAttrType) and self.view.config.ATTR_ICON_COLOR_MAIN or self.view.config.ATTR_ICON_COLOR_OTHER
        cell.iconShadow.sprite = self:LoadSprite(UIConst.UI_SPRITE_ATTRIBUTE_ICON, UIConst.UI_ATTRIBUTE_ICON_PREFIX .. showInfo.attributeKey)
        cell.iconShadow.color = (isMainAttrType or isSubAttrType) and self.view.config.ATTR_SHADOW_COLOR_MAIN or self.view.config.ATTR_SHADOW_COLOR_SUB
        cell.button.onClick:RemoveAllListeners()
        cell.button.onClick:AddListener(function()
            Notify(MessageConst.CHAR_INFO_SHOW_FC_ATTR_HINT, { transform = self.view.hintTransform, attributeInfo = showInfo, charTemplateId = templateId, charInstId = charInstId, cell = cell, })
        end)
    end)
    self.m_scAttrCellCache:Refresh(#scAttrShowList, function(cell, index)
        local showInfo = scAttrShowList[index]
        cell.valueText.text = showInfo.showValue
        cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ATTRIBUTE_ICON, UIConst.UI_ATTRIBUTE_ICON_PREFIX .. showInfo.attributeKey)
        cell.button.onClick:RemoveAllListeners()
        cell.button.onClick:AddListener(function()
            Notify(MessageConst.CHAR_INFO_SHOW_SC_ATTR_HINT, { transform = self.view.hintTransform, attributeInfo = showInfo, charInfo = charInfo, cell = cell, })
        end)
    end)
    self.view.charSkillNodeNew:InitCharSkillNodeNew(charInstId, false, false, self.view.hintTransform)
    self.view.charPassiveSkillNode:InitCharPassiveSkillNode(charInstId, false, false, self.view.hintTransform)
    if self.view.professionIconButton then
        self.view.professionIconButton.onClick:RemoveAllListeners()
        self.view.professionIconButton.onClick:AddListener(function()
            UIManager:Open(PanelId.CharInfoProAndElement)
        end)
    end
    self.view.attributeTitle.detailButton.onClick:RemoveAllListeners()
    self.view.attributeTitle.detailButton.onClick:AddListener(function()
        if hideWhenOpenDetail then
            UIUtils.PlayAnimationAndToggleActive(self.view.animationWrapper, false, function()
                self:_OpenCharInfoFullAttribute(charInstId, templateId, function()
                    UIUtils.PlayAnimationAndToggleActive(self.view.animationWrapper, true)
                end)
            end)
        else
            self:_OpenCharInfoFullAttribute(charInstId, templateId)
        end
    end)
    self.view.charLevelNode:InitCharLevelNode(charInstId)
    self.m_imageSelectCache = {}
    local fcItemCells = self.m_fcAttrCellCache:GetItems()
    local scItemCells = self.m_scAttrCellCache:GetItems()
    local skillCells = self.view.charSkillNodeNew.m_skillCells:GetItems()
    local passiveSkillCells = self.view.charPassiveSkillNode.m_passiveSkillCellCache:GetItems()
    for i, cell in pairs(fcItemCells) do
        self.m_imageSelectCache[cell] = cell.imageSelect
    end
    for i, cell in pairs(scItemCells) do
        self.m_imageSelectCache[cell] = cell.imageSelect
    end
    for i, cell in pairs(skillCells) do
        self.m_imageSelectCache[cell] = cell.view.imageSelect
    end
    for i, cell in pairs(passiveSkillCells) do
        self.m_imageSelectCache[cell] = cell.imageSelect
    end
end
CharInfoBasicNode._RefreshImageSelect = HL.Method(HL.Opt(HL.Any)) << function(self, showCell)
    for parentCell, cell in pairs(self.m_imageSelectCache) do
        cell.gameObject:SetActive(parentCell == showCell)
    end
end
CharInfoBasicNode._OpenCharInfoFullAttribute = HL.Method(HL.Number, HL.String, HL.Opt(HL.Function)) << function(self, instId, templateId, onClose)
    UIManager:Open(PanelId.CharInfoFullAttribute, { charInfo = { instId = instId, templateId = templateId, }, onClose = onClose, })
end
HL.Commit(CharInfoBasicNode)
return CharInfoBasicNode