local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonMoneyExchange
local PHASE_ID = PhaseId.CommonMoneyExchange
CommonMoneyExchangeCtrl = HL.Class('CommonMoneyExchangeCtrl', uiCtrl.UICtrl)
CommonMoneyExchangeCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_WALLET_CHANGED] = 'Refresh', [MessageConst.ON_ITEM_COUNT_CHANGED] = 'Refresh', [MessageConst.ON_SHOP_MONEY_EXCHANGE_SUCC] = 'Success', }
CommonMoneyExchangeCtrl.m_arg = HL.Field(HL.Table)
CommonMoneyExchangeCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_arg = arg
    self.view.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PHASE_ID)
    end)
    self.view.mask.onClick:AddListener(function()
        PhaseManager:PopPhase(PHASE_ID)
    end)
    self.view.tipsBtn1.onClick:AddListener(function()
        local sourceId = self.m_arg.sourceId
        Notify(MessageConst.SHOW_ITEM_TIPS, { itemId = sourceId, transform = self.view.tipsBtn1.transform, })
    end)
    self.view.tipsBtn2.onClick:AddListener(function()
        local targetId = self.m_arg.targetId
        Notify(MessageConst.SHOW_ITEM_TIPS, { itemId = targetId, transform = self.view.tipsBtn2.transform, })
    end)
    local b, config = CS.Beyond.Gameplay.ShopSystem.GetExchangeData(arg.sourceId, arg.targetId)
    if not b then
        logger.error("can not find money exchange data")
        return
    end
    self.view.confirmButton.onClick:AddListener(function()
        local s, ss = CS.Beyond.Gameplay.ShopSystem.ExchangeMoney(self.m_arg.sourceId, self.m_arg.targetId, math.floor(tonumber(self.view.costNumTxt1.text)))
        local i = 1
    end)
    self:Refresh()
end
CommonMoneyExchangeCtrl.Success = HL.Method(HL.Any) << function(self, msg)
    local items = {}
    local reward = unpack(msg)
    local item = { id = reward.TargetMoneyId, count = reward.GetTargetMoneyNum, }
    table.insert(items, item)
    Notify(MessageConst.SHOW_SYSTEM_REWARDS, { title = Language.LUA_BUY_ITEM_SUCC_TITLE, icon = "icon_mail_obtain", items = items, })
    PhaseManager:PopPhase(PHASE_ID)
end
CommonMoneyExchangeCtrl.Refresh = HL.Method(HL.Opt(HL.Any)) << function(self, arg)
    local sourceId = self.m_arg.sourceId
    local targetId = self.m_arg.targetId
    local item1 = Tables.itemTable[sourceId]
    local item2 = Tables.itemTable[targetId]
    self.view.nameTxt1.text = item1.name
    self.view.nameTxt2.text = item2.name
    self.view.title.text = string.format(Language.LUA_SHOP_MONEY_EXCHANGE_TITLE, item2.name)
    self.view.icon1.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, item1.iconId)
    self.view.icon2.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, item2.iconId)
    local b, config = CS.Beyond.Gameplay.ShopSystem.GetExchangeData(sourceId, targetId)
    if not b then
        logger.error("can not find money exchange data")
        return
    end
    self.view.costNumTxt1.text = math.floor(config.sourceMoneyMinSwap)
    self.view.costNumTxt2.text = math.floor(config.targetMoneyGet * config.sourceMoneyMinSwap)
    self.view.totalNumTxt1.text = Utils.getItemCount(sourceId)
    self.view.totalNumTxt2.text = Utils.getItemCount(targetId)
    self.view.money1.text = string.format("*%s [%s]", config.sourceMoneyCost, item1.name)
    self.view.money2.text = string.format("*%s [%s]", config.targetMoneyGet, item2.name)
    local max = math.max(1, math.floor(Utils.getItemCount(sourceId) / config.sourceMoneyMinSwap))
    local canExchange = math.floor(Utils.getItemCount(sourceId) / config.sourceMoneyCost) > 0
    self.view.confirmButton.interactable = canExchange
    if not canExchange then
        self.view.confirmTxt.text = string.format(Language.LUA_SHOP_BUY_MONEY_NOT_ENOUGH, item1.name)
    end
    local curNum = self.view.numberSelector.curNumber
    self.view.numberSelector:InitNumberSelector(curNum, 1, max, function(newNum)
        self.view.costNumTxt1.text = math.floor(newNum * config.sourceMoneyMinSwap)
        self.view.costNumTxt2.text = math.floor((newNum * config.sourceMoneyMinSwap / config.sourceMoneyCost) * config.targetMoneyGet)
        self.view.numberSelector.view.numberText.text = math.floor(newNum)
        self.view.confirmTxt.text = string.format(Language.LUA_SHOP_MONEY_EXCHANGE_TIPS, item1.name .. "×" .. math.floor(newNum * config.sourceMoneyMinSwap), item2.name .. "×" .. math.floor((newNum * config.sourceMoneyMinSwap / config.sourceMoneyCost) * config.targetMoneyGet))
    end)
end
HL.Commit(CommonMoneyExchangeCtrl)