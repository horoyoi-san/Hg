local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.GachaWeaponPoolDetail
GachaWeaponPoolDetailCtrl = HL.Class('GachaWeaponPoolDetailCtrl', uiCtrl.UICtrl)
GachaWeaponPoolDetailCtrl.s_messages = HL.StaticField(HL.Table) << {}
GachaWeaponPoolDetailCtrl.m_poolId = HL.Field(HL.String) << ""
GachaWeaponPoolDetailCtrl.m_allWeaponCellCache = HL.Field(HL.Forward('UIListCache'))
GachaWeaponPoolDetailCtrl.m_detailCellCache = HL.Field(HL.Forward('UIListCache'))
GachaWeaponPoolDetailCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeButton.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.view.mask.onClick:AddListener(function()
        self:PlayAnimationOutAndClose()
    end)
    self.m_allWeaponCellCache = UIUtils.genCellCache(self.view.allWeaponCell)
    self.m_detailCellCache = UIUtils.genCellCache(self.view.detailCell)
    self.m_poolId = arg
    self:_InitAllWeapons()
    self:_InitDetails()
end
GachaWeaponPoolDetailCtrl._InitAllWeapons = HL.Method() << function(self)
    local poolId = self.m_poolId
    local poolInfo = GameInstance.player.gacha.poolInfos:get_Item(poolId)
    local poolData = poolInfo.data
    local poolTypeData = Tables.gachaWeaponPoolTypeTable[poolData.type]
    local contentData = Tables.gachaWeaponPoolContentTable[poolId]
    local groupByRarity = {}
    local star6TotalWeight = 0
    local star6TotalNum = 0
    for _, v in pairs(contentData.list) do
        local weaponId = v.itemId
        local rarity = v.starLevel
        if not groupByRarity[rarity] then
            groupByRarity[rarity] = { rarity = rarity, weapons = {} }
        end
        if rarity == 6 then
            star6TotalWeight = star6TotalWeight + v.randomWeight
            star6TotalNum = star6TotalNum + 1
        end
        table.insert(groupByRarity[rarity].weapons, { id = weaponId, weight = v.randomWeight, data = Tables.itemTable:GetValue(weaponId), upOrder = v.isHardGuaranteeItem and 1 or 0, })
    end
    local averageWeight = star6TotalWeight / star6TotalNum
    local groupList = {}
    for _, v in pairs(groupByRarity) do
        table.insert(groupList, v)
        table.sort(v.weapons, Utils.genSortFunction({ "upOrder", "id" }))
    end
    table.sort(groupList, Utils.genSortFunction({ "rarity" }))
    local rates = { [6] = poolTypeData.star6BaseRate / Const.GACHA_RATE_TOTAL_VALUE * 100, [5] = poolTypeData.star5BaseRate / Const.GACHA_RATE_TOTAL_VALUE * 100, [4] = poolTypeData.star4BaseRate / Const.GACHA_RATE_TOTAL_VALUE * 100, }
    self.m_allWeaponCellCache:Refresh(#groupList, function(cell, index)
        local groupInfo = groupList[index]
        cell.titleTxt.text = string.format(Language.LUA_GACHA_WEAPON_DETAIL_RARITY_BASE_RATE_TITLE, groupInfo.rarity, rates[groupInfo.rarity])
        local allWeaponNames
        for k, v in ipairs(groupInfo.weapons) do
            local name = v.data.name
            if v.weight > averageWeight then
                name = name .. string.format(Language.LUA_GACHA_WEAPON_DETAIL_UP_POSTFIX, v.weight / star6TotalWeight * 100)
            end
            if k == 1 then
                allWeaponNames = name
            else
                allWeaponNames = allWeaponNames .. "/" .. name
            end
        end
        cell.valueTxt.text = allWeaponNames
    end)
end
GachaWeaponPoolDetailCtrl._InitDetails = HL.Method() << function(self)
    local poolId = self.m_poolId
    local poolInfo = GameInstance.player.gacha.poolInfos:get_Item(poolId)
    local poolData = poolInfo.data
    local poolTypeData = Tables.gachaWeaponPoolTypeTable[poolData.type]
    local contentData = Tables.gachaWeaponPoolContentTable[poolId]
    local details = {}
    local rates = { [6] = poolTypeData.star6BaseRate / Const.GACHA_RATE_TOTAL_VALUE * 100, [5] = poolTypeData.star5BaseRate / Const.GACHA_RATE_TOTAL_VALUE * 100, [4] = poolTypeData.star4BaseRate / Const.GACHA_RATE_TOTAL_VALUE * 100, }
    table.insert(details, { title = Language.LUA_GACHA_WEAPON_DETAIL_DESC_TITLE, content = poolData.desc, })
    local rateContent = {}
    table.insert(rateContent, string.format(Language.LUA_GACHA_WEAPON_DETAIL_RARITY_RATE_6, rates[6], poolTypeData.softGuarantee / 10))
    table.insert(rateContent, "\n")
    table.insert(rateContent, string.format(Language.LUA_GACHA_WEAPON_DETAIL_RARITY_RATE_5, rates[5], poolTypeData.star5SoftGuarantee / 10))
    table.insert(rateContent, "\n")
    if not string.isEmpty(poolData.upCharDesc) then
        table.insert(rateContent, poolData.upCharDesc)
        table.insert(rateContent, "\n")
    end
    local upWeaponId = poolData.upWeaponIds[0]
    local weaponItemData = Tables.itemTable:GetValue(upWeaponId)
    table.insert(rateContent, string.format(Language.LUA_GACHA_WEAPON_DETAIL_HARD_GUARANTEE, weaponItemData.name))
    table.insert(details, { title = Language.LUA_GACHA_DETAIL_RATE_TITLE, content = table.concat(rateContent), })
    local convertContent = {}
    table.insert(convertContent, Language.LUA_GACHA_WEAPON_RESULT_RULE_1)
    table.insert(convertContent, "\n")
    table.insert(convertContent, Language.LUA_GACHA_WEAPON_RESULT_RULE_2)
    table.insert(convertContent, "\n")
    table.insert(convertContent, Language.LUA_GACHA_WEAPON_RESULT_RULE_3)
    table.insert(details, { title = Language.LUA_GACHA_DETAIL_CONVERT_TITLE, content = table.concat(convertContent), })
    self.m_detailCellCache:Refresh(#details, function(cell, index)
        local info = details[index]
        cell.titleTxt.text = info.title
        cell.contentTxt.text = info.content
    end)
end
HL.Commit(GachaWeaponPoolDetailCtrl)