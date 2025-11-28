local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.ShopYellowGreen
local PHASE_ID = PhaseId.ShopYellowGreen
ShopYellowGreenCtrl = HL.Class('ShopYellowGreenCtrl', uiCtrl.UICtrl)
ShopYellowGreenCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SHOP_REFRESH] = 'UpdateAll', [MessageConst.ON_SHOP_JUMP_EVENT] = 'OnClickGoods', [MessageConst.ON_BUY_ITEM_SUCC] = 'UpdateAll', [MessageConst.ON_SHOP_GOODS_CONDITION_REFRESH] = 'UpdateAll', }
ShopYellowGreenCtrl.m_getCellFunc = HL.Field(HL.Function)
ShopYellowGreenCtrl.m_datas = HL.Field(HL.Any)
ShopYellowGreenCtrl.OnCreate = HL.Override(HL.Any) << function(self, goodsData)
    self.m_getCellFunc = UIUtils.genCachedCellFunction(self.view.scrollList)
    self.view.scrollList.onUpdateCell:AddListener(function(obj, index)
        local cell = self.m_getCellFunc(LuaIndex(index))
        cell:InitShopWeaponCell(self.m_datas[(index)])
    end)
    self:Refresh(goodsData)
end
ShopYellowGreenCtrl.Refresh = HL.Method(HL.Any) << function(self, goodsData)
    self.m_datas = goodsData
    GameInstance.player.shopSystem:SortGoodsList(goodsData)
    self.view.scrollList:UpdateCount(self.m_datas.Count)
end
ShopYellowGreenCtrl.UpdateAll = HL.Method(HL.Opt(HL.Any)) << function(self, arg)
    self:Refresh(self.m_datas)
end
ShopYellowGreenCtrl.OnClickGoods = HL.Method(HL.Opt(HL.Table)) << function(self, arg)
    if not arg then
        return
    end
    local goodsId = arg.goods
    if goodsId == nil or string.isEmpty(goodsId) then
        return
    end
    local goods = Tables.shopGoodsTable[goodsId]
    local shopId = goods.shopId
    local goodsData = GameInstance.player.shopSystem:GetShopGoodsData(shopId, goodsId)
    if goodsData == nil then
        logger.error(ELogChannel.UI, "商店商品数据为空")
        return
    end
    local isBox = string.isEmpty(goods.rewardId)
    if isBox then
        PhaseManager:OpenPhase(PhaseId.GachaWeaponPool, { goodsData = goodsData })
    else
        UIManager:Open(PanelId.ShopDetail, goodsData)
    end
end
ShopYellowGreenCtrl.OnShow = HL.Override() << function(self)
    self:UpdateAll()
end
HL.Commit(ShopYellowGreenCtrl)