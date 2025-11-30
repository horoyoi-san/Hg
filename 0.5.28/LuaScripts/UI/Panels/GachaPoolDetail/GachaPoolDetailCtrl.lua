local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GachaPoolDetail
GachaPoolDetailCtrl = HL.Class('GachaPoolDetailCtrl', uiCtrl.UICtrl)
GachaPoolDetailCtrl.s_messages = HL.StaticField(HL.Table) << {}
GachaPoolDetailCtrl.m_upCharGroupCellCache = HL.Field(HL.Forward('UIListCache'))
GachaPoolDetailCtrl.m_allCharCellCache = HL.Field(HL.Forward('UIListCache'))
GachaPoolDetailCtrl.m_detailCellCache = HL.Field(HL.Forward('UIListCache'))
GachaPoolDetailCtrl.m_poolId = HL.Field(HL.String) << ''
GachaPoolDetailCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeButton.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.view.mask.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.m_upCharGroupCellCache = UIUtils.genCellCache(self.view.upCharGroupCell)
    self.m_allCharCellCache = UIUtils.genCellCache(self.view.allCharCell)
    self.m_detailCellCache = UIUtils.genCellCache(self.view.detailCell)
    self.m_poolId = arg
    self:_InitUpChars()
    self:_InitAllChars()
    self:_InitDetails()
end
GachaPoolDetailCtrl._InitUpChars = HL.Method() << function(self)
    local poolData = Tables.gachaCharPoolTable[self.m_poolId]
    local poolTypeData = Tables.gachaCharPoolTypeTable[poolData.type]
    local charIdsCS = poolData.upCharIds
    local count = charIdsCS.Count
    if count == 0 then
        self.view.upCharsNode.gameObject:SetActive(false)
        return
    end
    self.view.upCharsNode.gameObject:SetActive(true)
    local groupByRarity = {}
    for _, id in pairs(charIdsCS) do
        local charData = Tables.characterTable[id]
        local rarity = charData.rarity
        if not groupByRarity[rarity] then
            groupByRarity[rarity] = { rarity = rarity, chars = {} }
        end
        table.insert(groupByRarity[rarity].chars, { id = id, data = charData })
    end
    local groupList = {}
    for _, v in pairs(groupByRarity) do
        table.insert(groupList, v)
    end
    table.sort(groupList, Utils.genSortFunction({ "rarity" }))
    self.m_upCharGroupCellCache:Refresh(#groupList, function(cell, index)
        local groupInfo = groupList[index]
        local rarity = groupInfo.rarity
        cell.titleTxt.text = string.format(Language.LUA_GACHA_DETAIL_UP_CHAR_TITLE, rarity)
        local charCache = UIUtils.genCellCache(cell.charCell)
        charCache:Refresh(#groupInfo.chars, function(charCell, charIndex)
            local char = groupInfo.chars[charIndex]
            charCell.nameTxt.text = char.data.name
            charCell.starGroup:InitStarGroup(rarity)
            charCell.charImg:LoadSprite("CharHorHeadIcon", char.id)
            charCell.rarityImg:LoadSprite(UIConst.UI_SPRITE_GACHA_POOL, string.format("GachaPool_Quality_%d", rarity))
        end)
    end)
end
GachaPoolDetailCtrl._InitAllChars = HL.Method() << function(self)
    local poolData = Tables.gachaCharPoolTable[self.m_poolId]
    local poolTypeData = Tables.gachaCharPoolTypeTable[poolData.type]
    local contentData = Tables.gachaCharPoolContentTable[self.m_poolId]
    local groupByRarity = {}
    for _, v in pairs(contentData.list) do
        local charId = v.charId
        local charData = Tables.characterTable[charId]
        local rarity = charData.rarity
        if not groupByRarity[rarity] then
            groupByRarity[rarity] = { rarity = rarity, chars = {} }
        end
        table.insert(groupByRarity[rarity].chars, { id = charId, data = charData, upOrder = v.isHardGuaranteeItem and 1 or 0, })
    end
    local groupList = {}
    for _, v in pairs(groupByRarity) do
        table.insert(groupList, v)
        table.sort(v.chars, Utils.genSortFunction({ "upOrder", "id" }))
    end
    table.sort(groupList, Utils.genSortFunction({ "rarity" }))
    local rates = { [6] = poolTypeData.star6BaseRate / Const.GACHA_RATE_TOTAL_VALUE * 100, [5] = poolTypeData.star5BaseRate / Const.GACHA_RATE_TOTAL_VALUE * 100, [4] = poolTypeData.star4BaseRate / Const.GACHA_RATE_TOTAL_VALUE * 100, }
    self.m_allCharCellCache:Refresh(#groupList, function(cell, index)
        local groupInfo = groupList[index]
        cell.titleTxt.text = string.format(Language.LUA_GACHA_DETAIL_RARITY_BASE_RATE_TITLE, groupInfo.rarity, rates[groupInfo.rarity])
        local allCharNames
        for k, v in ipairs(groupInfo.chars) do
            if k == 1 then
                allCharNames = v.data.name
            else
                allCharNames = allCharNames .. "/" .. v.data.name
            end
        end
        cell.valueTxt.text = allCharNames
    end)
end
GachaPoolDetailCtrl._InitDetails = HL.Method() << function(self)
    local poolData = Tables.gachaCharPoolTable[self.m_poolId]
    local poolTypeData = Tables.gachaCharPoolTypeTable[poolData.type]
    local details = {}
    local rates = { [6] = poolTypeData.star6BaseRate / Const.GACHA_RATE_TOTAL_VALUE * 100, [5] = poolTypeData.star5BaseRate / Const.GACHA_RATE_TOTAL_VALUE * 100, [4] = poolTypeData.star4BaseRate / Const.GACHA_RATE_TOTAL_VALUE * 100, }
    table.insert(details, { title = Language.LUA_GACHA_DETAIL_DESC_TITLE, content = poolData.desc, })
    local rateContent = {}
    table.insert(rateContent, string.format(Language.LUA_GACHA_DETAIL_RARITY_RATE, 6, rates[6], poolTypeData.softGuarantee, 6))
    if poolTypeData.shareSoftGuarantee then
        table.insert(rateContent, string.format(Language.LUA_GACHA_DETAIL_SHARE_GUARANTEE, poolTypeData.name))
    else
        table.insert(rateContent, Language.LUA_GACHA_DETAIL_NOT_SHARE_GUARANTEE)
    end
    table.insert(rateContent, "\n")
    table.insert(rateContent, string.format(Language.LUA_GACHA_DETAIL_RARITY_RATE, 5, rates[5], poolTypeData.star5SoftGuarantee, 5))
    if poolTypeData.shareSoftGuarantee then
        table.insert(rateContent, string.format(Language.LUA_GACHA_DETAIL_SHARE_GUARANTEE, poolTypeData.name))
    else
        table.insert(rateContent, Language.LUA_GACHA_DETAIL_NOT_SHARE_GUARANTEE)
    end
    table.insert(rateContent, "\n")
    if poolTypeData.star6RatePromotePullCount.Count > 0 then
        local pullCount = poolTypeData.star6RatePromotePullCount[0] - 1
        local rate = poolTypeData.star6RatePromoteValue[0] / Const.GACHA_RATE_TOTAL_VALUE * 100
        table.insert(rateContent, string.format(Language.LUA_GACHA_DETAIL_RATE_UP, pullCount, rate))
        table.insert(rateContent, "\n")
    end
    if not string.isEmpty(poolData.upCharDesc) then
        table.insert(rateContent, poolData.upCharDesc)
        table.insert(rateContent, "\n")
    end
    if poolTypeData.hardGuarantee > 0 then
        table.insert(rateContent, string.format(Language.LUA_GACHA_DETAIL_HARD_GUARANTEE, poolTypeData.hardGuarantee))
    end
    table.insert(details, { title = Language.LUA_GACHA_DETAIL_RATE_TITLE, content = table.concat(rateContent), })
    local convertContent = {}
    table.insert(convertContent, string.format(Language.LUA_GACHA_DETAIL_RESULT_CONVERT_RULE_1, UIUtils.getRewardFirstItem(Tables.charGachaConst.weaponCoinRewardIdOfStar6).count, UIUtils.getRewardFirstItem(Tables.charGachaConst.weaponCoinRewardIdOfStar5).count, UIUtils.getRewardFirstItem(Tables.charGachaConst.weaponCoinRewardIdOfStar4).count))
    table.insert(convertContent, "\n")
    table.insert(convertContent, string.format(Language.LUA_GACHA_DETAIL_RESULT_CONVERT_RULE_2, UIUtils.getRewardFirstItem(Tables.charGachaConst.repeatStar6CharRewardIdBeforePotentialFull).count, UIUtils.getRewardFirstItem(Tables.charGachaConst.repeatStar6CharRewardIdAfterPotentialFull).count))
    table.insert(convertContent, "\n")
    table.insert(convertContent, string.format(Language.LUA_GACHA_DETAIL_RESULT_CONVERT_RULE_3, UIUtils.getRewardFirstItem(Tables.charGachaConst.repeatStar5CharRewardIdBeforePotentialFull).count, UIUtils.getRewardFirstItem(Tables.charGachaConst.repeatStar5CharRewardIdAfterPotentialFull).count))
    table.insert(convertContent, "\n")
    table.insert(convertContent, Language.LUA_GACHA_DETAIL_RESULT_CONVERT_RULE_4)
    table.insert(details, { title = Language.LUA_GACHA_DETAIL_CONVERT_TITLE, content = table.concat(convertContent), })
    self.m_detailCellCache:Refresh(#details, function(cell, index)
        local info = details[index]
        cell.titleTxt.text = info.title
        cell.contentTxt.text = info.content
    end)
end
HL.Commit(GachaPoolDetailCtrl)