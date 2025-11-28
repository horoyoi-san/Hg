local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CharUpgrade
CharUpgradeCtrl = HL.Class('CharUpgradeCtrl', uiCtrl.UICtrl)
CharUpgradeCtrl.m_charInfo = HL.Field(HL.Table)
CharUpgradeCtrl.m_upgradeItemCostDict = HL.Field(HL.Table)
CharUpgradeCtrl.m_expCardInfoList = HL.Field(HL.Table)
CharUpgradeCtrl.m_curGenerateExp = HL.Field(HL.Number) << 0
CharUpgradeCtrl.m_upgradeItemCellCache = HL.Field(HL.Forward("UIListCache"))
CharUpgradeCtrl.m_level2RequireExpDict = HL.Field(HL.Table)
CharUpgradeCtrl.m_level2RequireGoldDict = HL.Field(HL.Table)
CharUpgradeCtrl.m_fromLevel = HL.Field(HL.Number) << 0
CharUpgradeCtrl.m_toLevel = HL.Field(HL.Number) << 0
CharUpgradeCtrl.m_controllerCurSelectedItemId = HL.Field(HL.String) << ""
CharUpgradeCtrl.m_upgradeItemList = HL.Field(HL.Table)
CharUpgradeCtrl.m_breakItemList = HL.Field(HL.Table)
CharUpgradeCtrl.m_itemIdToCellIndex = HL.Field(HL.Table)
CharUpgradeCtrl.m_levelUpCor = HL.Field(HL.Thread)
CharUpgradeCtrl.m_sliderTween = HL.Field(HL.Any)
CharUpgradeCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_CHAR_GAIN_EXP] = 'OnCharGainExp', [MessageConst.ON_CHAR_LEVEL_UP] = 'OnCharLevelUp', }
CharUpgradeCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local initCharInfo = arg.initCharInfo or CharInfoUtils.getLeaderCharInfo()
    self.m_charInfo = initCharInfo
    self.m_itemIdToCellIndex = {}
    self.m_upgradeItemList = {}
    self.m_breakItemList = {}
    self:_InitActionEvent()
    self:_InitCharUpgradePanel()
    local charInstId = initCharInfo.instId
    local curExp, levelUpExp, curLevel, stageLevel, expCards = CharInfoUtils.getCharExpInfo(charInstId)
    local isUpgrade = curLevel < stageLevel
    CS.Beyond.Lua.UtilsForLua.ToggleCharInfoInUpgradePanelOption(isUpgrade)
end
CharUpgradeCtrl._InitCharUpgradePanel = HL.Method() << function(self)
    self.view.upgradeNode.upgradeLevelNode.addExp.text = 0
    self.view.upgradeNode.upgradeLevelNode.addLevel.text = 0
    self.view.upgradeNode.upgradeLevelNode.addExpBar.fillAmount = 0
    self.view.breakNode.upgradeLevelNode.addExpBar.fillAmount = 0
end
CharUpgradeCtrl.OnHide = HL.Override() << function(self)
    Notify(MessageConst.HIDE_ITEM_TIPS)
end
CharUpgradeCtrl.OnClose = HL.Override() << function(self)
    if self.m_sliderTween then
        self.m_sliderTween:Kill()
    end
    CS.Beyond.Lua.UtilsForLua.ToggleCharInfoInUpgradePanelOption(false)
    Notify(MessageConst.HIDE_ITEM_TIPS)
end
CharUpgradeCtrl.OnShow = HL.Override() << function(self)
    local initCharInfo = self.m_charInfo
    self.view.walletBarPlaceholder:InitWalletBarPlaceholder(UIConst.INVENTORY_MONEY_IDS)
    self:_RefreshUpgradePanel(initCharInfo)
end
CharUpgradeCtrl.OnCharGainExp = HL.Method(HL.Table) << function(self, arg)
    self:_RefreshUpgradePanel(self.m_charInfo)
end
CharUpgradeCtrl.OnCharLevelUp = HL.Method(HL.Table) << function(self, arg)
    Utils.triggerVoice("chrup_level", self.m_charInfo.templateId)
    self.m_levelUpCor = self:_ClearCoroutine(self.m_levelUpCor)
    self.m_levelUpCor = self:_StartCoroutine(function()
        self:_RefreshUpgradePanel(self.m_charInfo, true)
    end)
end
CharUpgradeCtrl.AddUpgradeItem = HL.Method(HL.String, HL.Number) << function(self, itemId, count)
    local charInstId = self.m_charInfo.instId
    local curExp, levelUpExp, curLevel, maxLevel, expCards = CharInfoUtils.getCharExpInfo(charInstId)
    local curGenerateExp = self:_GetCurAddOnExp(curExp)
    local needExp = self.m_level2RequireExpDict[maxLevel] or 0
    local expRequire = needExp - curExp
    if count > 0 and curGenerateExp > expRequire then
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_WEAPON_EXHIBIT_UPGRADE_MAX_LEVEL)
        return
    end
    local addItemCount = self:_TryGetAddItemCount(curGenerateExp, expRequire, itemId, count)
    if addItemCount <= 0 then
        self.m_upgradeItemCostDict[itemId] = nil
    else
        self.m_upgradeItemCostDict[itemId] = addItemCount
    end
end
CharUpgradeCtrl._TryGetAddItemCount = HL.Method(HL.Number, HL.Number, HL.String, HL.Number).Return(HL.Number) << function(self, curGenerateExp, expRequire, itemId, count)
    local expItemDataMap = Tables.expItemDataMap
    local _, expItemData = expItemDataMap:TryGetValue(itemId)
    local exp = expItemData.expGain
    local curCount = self.m_upgradeItemCostDict[itemId] or 0
    local nextCount = curCount + count
    if count <= 0 then
        return nextCount
    end
    if (curGenerateExp + (exp * count)) > expRequire then
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_WEAPON_EXHIBIT_UPGRADE_MAX_LEVEL)
        local needExp = math.max(0, expRequire - curGenerateExp)
        nextCount = curCount + math.ceil(needExp / exp)
    end
    local inventoryCount = Utils.getItemCount(itemId, true)
    if nextCount > inventoryCount then
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_WEAPON_EXHIBIT_UPGRADE_MAX_ITEM_COUNT)
        return inventoryCount
    end
    return nextCount
end
CharUpgradeCtrl._RefreshUpgradePanel = HL.Method(HL.Table, HL.Opt(HL.Boolean)) << function(self, charInfo, isUpgradeTransition)
    local charInstId = charInfo.instId
    local curExp, levelUpExp, curLevel, stageLevel, expCards = CharInfoUtils.getCharExpInfo(charInstId)
    local isUpgrade = curLevel < stageLevel
    if isUpgradeTransition then
        if isUpgrade then
            AudioAdapter.PostEvent("Au_UI_Event_CharLevelUp")
            self.view.animation:Play("charupgrade_scroll_in")
            coroutine.wait(0.3)
        else
            AudioAdapter.PostEvent("Au_UI_Event_CharLevelUp")
            self.view.animation:Play("charupgrade_scroll_in")
            coroutine.wait(0.3)
            self:_InitUpgradeCache(charInfo)
            self:_RefreshUpgradeNode(charInfo, isUpgradeTransition)
            coroutine.wait(1.5)
            self.view.upgradeNode.animationWrapper:PlayOutAnimation()
            coroutine.wait(0.5)
            AudioAdapter.PostEvent("Au_UI_Event_CharLevelLimit")
        end
    end
    self.view.upgradeNode.gameObject:SetActive(isUpgrade)
    self.view.breakNode.gameObject:SetActive(not isUpgrade)
    CS.Beyond.Lua.UtilsForLua.ToggleCharInfoInUpgradePanelOption(isUpgrade)
    self.view.textTitle.text = CharInfoUtils.getCharInfoTitle(charInfo.templateId, UIConst.CHAR_INFO_PAGE_TYPE.UPGRADE)
    if isUpgrade then
        self:_InitUpgradeCache(charInfo)
        self:_RefreshUpgradeNode(charInfo, isUpgradeTransition)
    else
        self:_RefreshBreakNode(charInfo.instId)
    end
end
CharUpgradeCtrl._VirtualNavigate = HL.Method(HL.Number, HL.Number) << function(self, tabType, offset)
    local isUpgrade = tabType == UIConst.CHAR_INFO_PAGE_TYPE.UPGRADE
    if isUpgrade then
        local itemId = self.m_controllerCurSelectedItemId
        local index = self.m_itemIdToCellIndex[itemId]
        local nextIndex = lume.clamp(index + offset, 1, #self.m_upgradeItemList)
        local nextCell = self.m_upgradeItemCellCache:GetItem(nextIndex)
        local nextItemId = self.m_upgradeItemList[nextIndex]
        self:_ClickUpgradeItemCell(nextCell, nextItemId)
    end
end
CharUpgradeCtrl.SwitchCharInfoVirtualMouseType = HL.Method(HL.Any) << function(self, panelMouseMode)
    self:ChangePanelCfg("virtualMouseMode", panelMouseMode)
    self:ChangePanelCfg("realMouseMode", panelMouseMode)
end
CharUpgradeCtrl._RefreshUpgradeNode = HL.Method(HL.Table, HL.Opt(HL.Boolean)) << function(self, charInfo, isUpgradeTransition)
    local charInstId = charInfo.instId
    local charInstInfo = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
    local curExp, levelUpExp, curLevel, stageLevel, expCards = CharInfoUtils.getCharExpInfo(charInstId)
    local upgradeLevelNode = self.view.upgradeNode.upgradeLevelNode
    upgradeLevelNode.stageLevel.text = stageLevel
    local curGenerateExp = self:_GetCurAddOnExp(curExp)
    local curAddExp = curGenerateExp + curExp
    local targetLevel, expLeft = self:_CalcLevelByExp(curAddExp, curLevel, stageLevel)
    local levelExpData = Tables.charLevelUpTable
    local targetLevelExp = levelExpData[targetLevel].exp
    local curLevelExp = levelExpData[curLevel].exp
    local addLevel = targetLevel - curLevel
    upgradeLevelNode.addExpIcon.gameObject:SetActive(true)
    upgradeLevelNode.addLevelIcon.gameObject:SetActive(true)
    upgradeLevelNode.nextLvExp.text = levelUpExp
    upgradeLevelNode.curExp.text = curExp
    if isUpgradeTransition then
        upgradeLevelNode.addLevel.text = addLevel
        upgradeLevelNode.addExp.text = curGenerateExp
        upgradeLevelNode.curLevel.tweenToText = curLevel
    else
        upgradeLevelNode.addLevel.tweenToText = addLevel
        upgradeLevelNode.addExp.text = curGenerateExp
        upgradeLevelNode.curLevel.text = curLevel
    end
    upgradeLevelNode.currentExpBar.fillAmount = targetLevel > curLevel and 0 or curExp / targetLevelExp
    local newValue = targetLevel > curLevel and 1 or expLeft / targetLevelExp
    if self.m_sliderTween then
        self.m_sliderTween:Kill()
    end
    self.m_sliderTween = DOTween.To(function()
        return upgradeLevelNode.addExpBar.fillAmount
    end, function(value)
        upgradeLevelNode.addExpBar.fillAmount = value
    end, newValue, 0.5)
    self.m_upgradeItemCellCache:Refresh(#expCards, function(cell, index)
        local itemId = expCards[CSIndex(index)]
        self:_RefreshUpgradeItemCell(cell, itemId)
    end)
    self.m_fromLevel = charInstInfo.level
    self.m_toLevel = targetLevel
    local breakStage = charInstInfo.breakStage
    self.view.upgradeNode.weaponAttributeNode:InitCharAttributeNode(charInstId, targetLevel, breakStage, { showAttrTransition = isUpgradeTransition })
    local curGold = Utils.getItemCount(UIConst.INVENTORY_MONEY_IDS[1], true)
    local needGold = self.m_level2RequireGoldDict[targetLevel] or 0
    self.view.upgradeNode.goldCostNumber.text = UIUtils.setCountColor(needGold, curGold < needGold)
end
CharUpgradeCtrl._GetCurAddOnExp = HL.Method(HL.Number).Return(HL.Number) << function(self)
    local expSum = 0
    local expItemDataMap = Tables.expItemDataMap
    for itemId, itemCount in pairs(self.m_upgradeItemCostDict) do
        local _, expItemData = expItemDataMap:TryGetValue(itemId)
        local exp = expItemData.expGain
        expSum = expSum + exp * itemCount
    end
    return expSum
end
CharUpgradeCtrl._CalcLevelByExp = HL.Method(HL.Number, HL.Number, HL.Number).Return(HL.Number, HL.Number) << function(self, addExp, curLevel, maxLevel)
    local level2RequireExpDict = self.m_level2RequireExpDict
    local maxExpRequire = level2RequireExpDict[maxLevel] or 0
    if addExp >= maxExpRequire then
        return maxLevel, addExp - maxExpRequire
    end
    for level = maxLevel, curLevel + 1, -1 do
        local requireExp = level2RequireExpDict[level]
        if addExp >= requireExp then
            return level, addExp - requireExp
        end
    end
    return curLevel, addExp
end
CharUpgradeCtrl._RefreshUpgradeItemCell = HL.Method(HL.Table, HL.String) << function(self, cell, itemId)
    local costCount = self.m_upgradeItemCostDict[itemId] or 0
    local inventoryCount = Utils.getItemCount(itemId, true)
    cell.itemBlack:InitItem({ id = itemId }, true, nil, true)
    cell.inventoryCount.text = UIUtils.setCountColor(inventoryCount, inventoryCount <= 0)
    cell.numberSelector:InitNumberSelector(costCount, 0, inventoryCount, function(curNumber)
        local curCount = self.m_upgradeItemCostDict[itemId] or 0
        local countDiff = curNumber - curCount
        if countDiff ~= 0 then
            self:AddUpgradeItem(itemId, countDiff)
            self:_RefreshUpgradeNode(self.m_charInfo)
        end
    end)
    UIUtils.PlayAnimationAndToggleActive(cell.selectedNode, costCount > 0)
end
CharUpgradeCtrl._ShowItemTips = HL.Method(HL.Any, HL.String) << function(self, cell, itemId)
    Notify(MessageConst.SHOW_ITEM_TIPS, {
        transform = cell.itemBigBlack.transform,
        itemId = itemId,
        safeArea = self.view.upgradeNode.itemList,
        moveVirtualMouse = true,
        onClose = function()
            if not DeviceInfo.usingController then
                cell.itemBigBlack:SetSelected(false)
            end
        end
    })
end
CharUpgradeCtrl._AutoFillUpgradeItem = HL.Method().Return(HL.Table) << function(self)
    local charInstId = self.m_charInfo.instId
    local costItemTable = {}
    local expCardInfoList = self.m_expCardInfoList
    local curExp, levelUpExp, curLevel, maxLevel, expCards = CharInfoUtils.getCharExpInfo(charInstId)
    local targetLevel = maxLevel
    local targetLevelExp = self.m_level2RequireExpDict[targetLevel] or 0
    local expRequire = targetLevelExp - curExp
    local expOverflow = 0
    local fillCount = 0
    if expRequire <= 0 then
        return costItemTable
    end
    for i = #expCardInfoList, 1, -1 do
        if expOverflow > 0 then
            local canGenerateExp = 0
            for j = i, 1, -1 do
                canGenerateExp = canGenerateExp + expCardInfoList[j].inventoryCount * expCardInfoList[j].expGain
            end
            if canGenerateExp > expOverflow + expCardInfoList[i + 1].expGain then
                costItemTable[expCardInfoList[i + 1].itemId] = costItemTable[expCardInfoList[i + 1].itemId] - 1
                fillCount, expRequire, expOverflow = self:_TryFillUpgradeItem(expCardInfoList[i].expGain, expCardInfoList[i].inventoryCount, expCardInfoList[i + 1].expGain - expOverflow)
                costItemTable[expCardInfoList[i].itemId] = fillCount
            else
                return costItemTable
            end
        else
            fillCount, expRequire, expOverflow = self:_TryFillUpgradeItem(expCardInfoList[i].expGain, expCardInfoList[i].inventoryCount, expRequire)
            costItemTable[expCardInfoList[i].itemId] = fillCount
        end
    end
    return costItemTable
end
CharUpgradeCtrl._GenerateExpCardInfoList = HL.Method(HL.Number).Return(HL.Table) << function(self, charInstId)
    local expItemDataMap = Tables.expItemDataMap
    local expCardInfoList = {}
    local curExp, levelUpExp, curLevel, maxLevel, expCards = CharInfoUtils.getCharExpInfo(charInstId)
    for _, cardItemId in pairs(expCards) do
        local _, expItemData = expItemDataMap:TryGetValue(cardItemId)
        local expGain = expItemData.expGain
        local inventoryCount = Utils.getItemCount(cardItemId, true)
        table.insert(expCardInfoList, { itemId = cardItemId, expGain = expGain, inventoryCount = inventoryCount, })
    end
    expCardInfoList = lume.sort(expCardInfoList, function(a, b)
        return a.expGain < b.expGain
    end)
    return expCardInfoList
end
CharUpgradeCtrl._TryFillUpgradeItem = HL.Method(HL.Number, HL.Number, HL.Number).Return(HL.Number, HL.Number, HL.Number) << function(self, expGain, inventoryCount, expRequire)
    local wishCount = math.ceil(expRequire / expGain)
    local costCount = math.min(wishCount, inventoryCount)
    local generateExp = costCount * expGain
    local expLeft = expRequire - generateExp
    local expOverflow = generateExp - expRequire
    return costCount, expLeft, expOverflow
end
CharUpgradeCtrl._RefreshBreakNode = HL.Method(HL.Number) << function(self, charInstId)
    local charInstInfo = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
    local breakNode = self.view.breakNode
    local curExp, levelUpExp, curLevel, stageLevel = CharInfoUtils.getCharExpInfo(charInstId)
    breakNode.charEliteMarker:InitCharEliteMarker(charInstId)
    breakNode.breakLevelTitle.text = string.format(Language.LUA_CHAR_INFO_BREAK_LEVEL_TITLE, charInstInfo.breakStage)
    breakNode.breakLevelDesc.text = string.format(Language.LUA_CHAR_INFO_BREAK_LEVEL_DESC, curLevel, curLevel)
    breakNode.upgradeLevelNode.addExp.gameObject:SetActive(false)
    breakNode.upgradeLevelNode.addLevel.gameObject:SetActive(false)
    breakNode.upgradeLevelNode.addExp.gameObject:SetActive(false)
    breakNode.upgradeLevelNode.addLevel.gameObject:SetActive(false)
    breakNode.upgradeLevelNode.addExpIcon.gameObject:SetActive(false)
    breakNode.upgradeLevelNode.addLevelIcon.gameObject:SetActive(false)
    breakNode.upgradeLevelNode.curLevel.text = curLevel
    breakNode.upgradeLevelNode.stageLevel.text = stageLevel
    breakNode.upgradeLevelNode.curExp.text = curExp
    breakNode.upgradeLevelNode.nextLvExp.text = curExp
    local isMaxLevel = curLevel >= stageLevel and charInstInfo.breakStage >= Tables.characterConst.maxBreak
    breakNode.breakInfoNode.gameObject:SetActive(not isMaxLevel)
    if not isMaxLevel then
        local breakCfg = Tables.charBreakTable[charInstInfo.breakStage + 1]
        if breakCfg then
            breakNode.breakDesc.text = string.format(Language.LUA_CHAR_INFO_UPGRADE_TO_BREAK_HINT, breakCfg.maxLevel)
        end
    end
    breakNode.weaponAttributeNode:InitCharAttributeNode(charInstId, curLevel, charInstInfo.breakStage)
    self.view.breakNode.btnBreak.gameObject:SetActive(charInstInfo.breakStage < Tables.characterConst.maxBreak)
end
CharUpgradeCtrl._InitUpgradeCache = HL.Method(HL.Table) << function(self, charInfo)
    local charInstId = charInfo.instId
    local curExp, levelUpExp, curLevel, maxLevel, expCards = CharInfoUtils.getCharExpInfo(charInstId)
    local levelUpData = Tables.charLevelUpTable
    local startExp = levelUpData[curLevel].exp
    local startGold = levelUpData[curLevel].gold
    local level2RequireExpDict = {}
    local level2RequireGoldDict = {}
    for levelIndex = curLevel + 1, maxLevel do
        level2RequireExpDict[levelIndex] = startExp
        level2RequireGoldDict[levelIndex] = startGold
        startExp = startExp + levelUpData[levelIndex].exp
        startGold = startGold + levelUpData[levelIndex].gold
    end
    self.m_upgradeItemCostDict = {}
    self.m_level2RequireGoldDict = level2RequireGoldDict
    self.m_level2RequireExpDict = level2RequireExpDict
    self.m_expCardInfoList = self:_GenerateExpCardInfoList(charInstId)
end
CharUpgradeCtrl._InitActionEvent = HL.Method() << function(self)
    self.m_upgradeItemCellCache = UIUtils.genCellCache(self.view.upgradeNode.upgradeItemCell)
    self.view.upgradeNode.btnReset.onClick:AddListener(function()
        self.m_upgradeItemCostDict = {}
        self:_RefreshUpgradeNode(self.m_charInfo)
    end)
    self.view.upgradeNode.btnAutoFill.onClick:AddListener(function()
        self.m_upgradeItemCostDict = self:_AutoFillUpgradeItem()
        self:_RefreshUpgradeNode(self.m_charInfo)
    end)
    self.view.btnBack.onClick:AddListener(function()
        self:Notify(MessageConst.P_CHAR_INFO_PAGE_CHANGE, { pageType = UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW })
    end)
    self.view.upgradeNode.btnLevelUp.onClick:AddListener(function()
        if not self:_CheckHasUpgradeItem() then
            self:Notify(MessageConst.SHOW_TOAST, Language.LUA_CHAR_UPGRADE_NONE_ITEM)
            return
        end
        if not self:_CheckGoldEnough() then
            self:Notify(MessageConst.SHOW_TOAST, Language.LUA_NOT_ENOUGH_GOLD)
            return
        end
        GameInstance.player.charBag:CharLevelUp(self.m_charInfo.instId, self.m_upgradeItemCostDict)
    end)
    self.view.breakNode.btnBreak.onClick:AddListener(function()
        self:Notify(MessageConst.P_CHAR_INFO_PAGE_CHANGE, { pageType = UIConst.CHAR_INFO_PAGE_TYPE.TALENT, isFast = true, showGlitch = true, extraArg = { showNextCharBreak = true, } })
    end)
end
CharUpgradeCtrl._CheckGoldEnough = HL.Method().Return(HL.Boolean) << function(self)
    local needGold = self.m_level2RequireGoldDict[self.m_toLevel] or 0
    local curGold = Utils.getItemCount(UIConst.INVENTORY_MONEY_IDS[1], true)
    return curGold >= needGold
end
CharUpgradeCtrl._CheckHasUpgradeItem = HL.Method().Return(HL.Boolean) << function(self)
    if not self.m_upgradeItemCostDict then
        return false
    end
    local hasItem = false
    for i, costCount in pairs(self.m_upgradeItemCostDict) do
        if costCount > 0 then
            hasItem = true
            break
        end
    end
    return hasItem
end
HL.Commit(CharUpgradeCtrl)