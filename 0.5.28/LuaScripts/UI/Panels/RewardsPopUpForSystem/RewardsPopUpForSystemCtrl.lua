local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RewardsPopUpForSystem
RewardsPopUpForSystemCtrl = HL.Class('RewardsPopUpForSystemCtrl', uiCtrl.UICtrl)
RewardsPopUpForSystemCtrl.s_messages = HL.StaticField(HL.Table) << {}
RewardsPopUpForSystemCtrl.m_args = HL.Field(HL.Table)
RewardsPopUpForSystemCtrl.m_items = HL.Field(HL.Table)
RewardsPopUpForSystemCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.closeBtn.onClick:AddListener(function()
        if UIManager:IsShow(PanelId.ItemTips) then
            return
        end
        self:_OnClickClose()
    end)
    self.view.fullMask.onClick:AddListener(function()
        if UIManager:IsShow(PanelId.ItemTips) then
            return
        end
        self:_OnClickClose()
    end)
    self.view.skipBtn.onClick:AddListener(function()
        self:_OnClickSkip()
    end)
    local getItemCells = UIUtils.genCachedCellFunction(self.view.rewardsScrollList)
    self.view.rewardsScrollList.onUpdateCell:AddListener(function(object, csIndex)
        local cell = getItemCells(object)
        self:_OnUpdateCell(cell, LuaIndex(csIndex))
    end)
    self.view.rewardsScrollList.onGraduallyShowFinish:AddListener(function()
        self.view.skipBtn.gameObject:SetActive(false)
    end)
    self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
end
RewardsPopUpForSystemCtrl.ShowSystemRewards = HL.StaticMethod(HL.Table) << function(args)
    if args.chars then
        local chars
        if type(args.chars) == "table" then
            chars = args.chars
        else
            chars = {}
            for _, v in pairs(args.chars) do
                local msg = v
                local info = { charId = msg.CharTemplateId, isNew = not msg.IsConverted, }
                info.rarity = Tables.characterTable[info.charId].rarity
                info.items = {}
                if not string.isEmpty(msg.ConvertedItemId) then
                    table.insert(info.items, { id = msg.ConvertedItemId, count = 1 })
                end
                if not string.isEmpty(msg.ConvertedRewardId) then
                    UIUtils.getRewardItems(msg.ConvertedRewardId, info.items)
                end
                table.insert(chars, info)
            end
        end
        PhaseManager:OpenPhaseFast(PhaseId.GachaChar, {
            chars = chars,
            onComplete = function()
                args.chars = nil
                RewardsPopUpForSystemCtrl.ShowSystemRewards(args)
            end
        })
        return
    end
    local self = UIManager:AutoOpen(PANEL_ID, nil, false)
    UIManager:SetTopOrder(PANEL_ID)
    self:_ShowRewards(args)
end
RewardsPopUpForSystemCtrl.CSShowSystemRewards = HL.StaticMethod(HL.Table) << function(args)
    local title, items, inputChars = unpack(args)
    if inputChars then
        local chars = {}
        for _, v in pairs(inputChars) do
            local msg = v
            local info = { charId = msg.CharTemplateId, isNew = not msg.IsConverted, }
            info.rarity = Tables.characterTable[info.charId].rarity
            info.items = {}
            if not string.isEmpty(msg.ConvertedItemId) then
                table.insert(info.items, { id = msg.ConvertedItemId, count = 1 })
            end
            if not string.isEmpty(msg.ConvertedRewardId) then
                UIUtils.getRewardItems(msg.ConvertedRewardId, info.items)
            end
            table.insert(chars, info)
        end
        PhaseManager:OpenPhaseFast(PhaseId.GachaChar, {
            chars = chars,
            onComplete = function()
                RewardsPopUpForSystemCtrl.CSShowSystemRewards({ title, items })
            end
        })
        return
    end
    local self = UIManager:AutoOpen(PANEL_ID, nil, false)
    UIManager:SetTopOrder(PANEL_ID)
    self:_ShowRewards({ title = title, items = items })
end
RewardsPopUpForSystemCtrl._ShowRewards = HL.Method(HL.Table) << function(self, args)
    self.m_args = args
    if not string.isEmpty(args.title) then
        self.view.titleTxt.text = args.title
    else
        self.view.titleTxt.text = Language.LUA_DEFAULT_SYSTEM_REWARD_POP_UP_TITLE
    end
    if args.subTitle then
        self.view.subTitleTxt.text = args.subTitle
        self.view.subTitleTxt.gameObject:SetActive(true)
    else
        self.view.subTitleTxt.gameObject:SetActive(false)
    end
    if args.icon then
        self.view.rewardsTypeIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_REWARDS, args.icon)
    else
        self.view.rewardsTypeIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_REWARDS, "icon_common_rewards")
    end
    local items
    local count = 0
    if type(args.items) == "table" then
        items = args.items
        count = #items
    else
        items = {}
        for _, v in pairs(args.items) do
            table.insert(items, { id = v.id, count = v.count })
            count = count + 1
        end
    end
    for k = 1, count do
        local v = items[k]
        if type(v) ~= "table" then
            v = { id = v.id, count = v.count }
            items[k] = v
        end
        local iData = Tables.itemTable[v.id]
        v.sortId1 = iData.sortId1
        v.sortId2 = iData.sortId2
        v.rarity = iData.rarity
    end
    table.sort(items, Utils.genSortFunction(UIConst.COMMON_ITEM_SORT_KEYS))
    self.m_items = items
    self.view.rewardsScrollList.gameObject:SetActive(false)
    self.view.rewardsScrollList:UpdateCount(count, true)
    self.view.skipBtn.gameObject:SetActive(true)
end
RewardsPopUpForSystemCtrl._OnClickSkip = HL.Method() << function(self)
    self.view.luaPanel.animationWrapper:SkipInAnimation()
    self.view.rewardsScrollList:SkipGraduallyShow()
end
RewardsPopUpForSystemCtrl._OnClickClose = HL.Method() << function(self)
    self:PlayAnimationOutWithCallback(function()
        local onComplete = self.m_args.onComplete
        self.m_args = nil
        self.m_items = nil
        self:Hide()
        if onComplete then
            onComplete()
        end
    end)
end
RewardsPopUpForSystemCtrl._OnUpdateCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local itemBundle = self.m_items[index]
    cell:InitItem(itemBundle, true)
    UIUtils.setRewardItemRarityGlow(cell, UIUtils.getItemRarity(itemBundle.id))
    local isFullBottle, bottleData = Tables.fullBottleTable:TryGetValue(itemBundle.id)
    if isFullBottle then
        cell.view.name.text = string.format(Language.LUA_REWARD_FULL_BOTTLE_FORMAT, Tables.itemTable[bottleData.emptyBottleId].name, Tables.itemTable[bottleData.liquidId].name)
    end
end
RewardsPopUpForSystemCtrl.OnShow = HL.Override() << function(self)
    Notify(MessageConst.TOGGLE_COMMON_ITEM_TOAST, false)
    Notify(MessageConst.ON_ENTER_BLOCKED_REWARD_POP_UP_PANEL)
end
RewardsPopUpForSystemCtrl.OnHide = HL.Override() << function(self)
    Notify(MessageConst.TOGGLE_COMMON_ITEM_TOAST, true)
    Notify(MessageConst.ON_EXIT_BLOCKED_REWARD_POP_UP_PANEL)
end
RewardsPopUpForSystemCtrl.OnClose = HL.Override() << function(self)
    Notify(MessageConst.TOGGLE_COMMON_ITEM_TOAST, true)
    Notify(MessageConst.ON_EXIT_BLOCKED_REWARD_POP_UP_PANEL)
end
HL.Commit(RewardsPopUpForSystemCtrl)