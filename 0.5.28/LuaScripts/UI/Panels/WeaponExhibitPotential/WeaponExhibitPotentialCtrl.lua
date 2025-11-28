local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.WeaponExhibitPotential
WeaponExhibitPotentialCtrl = HL.Class('WeaponExhibitPotentialCtrl', uiCtrl.UICtrl)
WeaponExhibitPotentialCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_WEAPON_REFINE] = 'OnWeaponRefine', [MessageConst.ON_GEM_DETACH] = 'OnGemDetach', [MessageConst.ON_ITEM_LOCKED_STATE_CHANGED] = 'OnItemLockedStateChanged', }
WeaponExhibitPotentialCtrl.m_weaponInfo = HL.Field(HL.Table)
WeaponExhibitPotentialCtrl.m_bottomWeaponCellCache = HL.Field(HL.Forward("UIListCache"))
WeaponExhibitPotentialCtrl.m_lastClickItemId = HL.Field(HL.Any)
WeaponExhibitPotentialCtrl.m_lastClickItemInfo = HL.Field(HL.Table)
WeaponExhibitPotentialCtrl.m_costItemInfoDict = HL.Field(HL.Table)
WeaponExhibitPotentialCtrl.m_isFocusJump = HL.Field(HL.Boolean) << false
WeaponExhibitPotentialCtrl.m_effectCor = HL.Field(HL.Thread)
WeaponExhibitPotentialCtrl.OnItemLockedStateChanged = HL.Method(HL.Table) << function(self, arg)
    local itemId, instId, isLock = unpack(arg)
    if not isLock then
        return
    end
    if not instId or instId <= 0 then
        return
    end
    local costItemInfoDict = self.m_costItemInfoDict
    if costItemInfoDict[instId] ~= nil then
        Notify(MessageConst.SHOW_TOAST, Language.LUA_WEAPON_EXHIBIT_ITEM_LOCK_TOAST)
        self:_RemoveFromCostItemDict(costItemInfoDict[instId])
    end
end
WeaponExhibitPotentialCtrl.OnGemDetach = HL.Method(HL.Table) << function(self, arg)
    self.view.commonWeaponList:RefreshAllCells()
end
WeaponExhibitPotentialCtrl.OnWeaponRefine = HL.Method(HL.Table) << function(self, arg)
    local weaponInfo = self.m_weaponInfo
    local weaponInst = CharInfoUtils.getWeaponByInstId(weaponInfo.weaponInstId)
    local maxRefineLv = CS.Beyond.Gameplay.WeaponUtil.GetWeaponMaxRefineLv(weaponInfo.weaponTemplateId)
    local weaponExhibitInfo = CharInfoUtils.getWeaponExhibitBasicInfo(weaponInfo.weaponTemplateId, weaponInfo.weaponInstId)
    self.m_costItemInfoDict = {}
    self:_ToggleExpandNode(false, true)
    if weaponInst.refineLv >= maxRefineLv then
        AudioAdapter.PostEvent("Au_UI_Event_WeaponPotentialLevelMax")
        self.m_effectCor = self:_ClearCoroutine(self.m_effectCor)
        self.m_effectCor = self:_StartCoroutine(function()
            self:_RefreshPotentialPanelBasic(weaponExhibitInfo)
            self.view.weaponSkillNodeBefore.gameObject:SetActive(false)
            self.view.potentialNode:Play("weaponpotential_fullfinsh_in")
            coroutine.wait(0.3)
            self:_RefreshWeaponPotentialStar(weaponExhibitInfo.weaponInst.templateId, weaponExhibitInfo.weaponInst.instId)
        end)
    else
        AudioAdapter.PostEvent("Au_UI_Event_WeaponPotentialLevelUp")
        self.m_effectCor = self:_StartCoroutine(function()
            self.view.potentialAfter.view.animation:Play("weaponexhibitpotential_finishglow_break")
            self:_RefreshPotentialPanelBasic(weaponExhibitInfo)
            self.view.potentialAfter:InitWeaponPotentialStar(weaponInst.refineLv, { showMaxPotentialHint = false, fromLv = weaponInst.refineLv })
            coroutine.wait(0.2)
            self.view.potentialBefore:InitWeaponPotentialStar(weaponInst.refineLv, { showCurLevelTransition = true, showMaxPotentialHint = false, fromLv = weaponInst.refineLv })
        end)
    end
end
WeaponExhibitPotentialCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self:_InitActionEvent()
    self.view.expandNode.gameObject:SetActive(true)
    self.view.expandNode.gameObject:SetActive(false)
    self.m_weaponInfo = arg.weaponInfo
    self.m_isFocusJump = arg.isFocusJump == true
end
WeaponExhibitPotentialCtrl._InitActionEvent = HL.Method() << function(self)
    self.view.m_bottomWeaponCellCache = UIUtils.genCellCache(self.view.listCellWeaponUpgrade)
    self.view.btnBack.onClick:AddListener(function()
        if UIManager:IsShow(PanelId.ItemTips) then
            Notify(MessageConst.HIDE_ITEM_TIPS)
        end
        if self.m_isFocusJump then
            PhaseManager:SendMessageToOpenedPhase(PhaseId.WeaponInfo, MessageConst.P_WEAPON_EXHIBIT_BLEND_EXIT, {
                finishCallback = function()
                    PhaseManager:ExitPhaseFast(PhaseId.WeaponInfo)
                end
            })
            self:PlayAnimationOut()
            return
        end
        self:Notify(MessageConst.WEAPON_EXHIBIT_PAGE_CHANGE, { pageType = UIConst.WEAPON_EXHIBIT_PAGE_TYPE.OVERVIEW, })
    end)
    self.view.btnEmpty.onClick:AddListener(function()
        self:_ToggleExpandNode(false)
    end)
    self.view.btnLevelUp.onClick:AddListener(function()
        if not self.m_costItemInfoDict or lume.count(self.m_costItemInfoDict) == 0 then
            self:Notify(MessageConst.SHOW_TOAST, Language.LUA_WEAPON_EXHIBIT_POTENTIAL_EMPTY_INGREDIENT)
            return
        end
        local ingredients = {}
        for i, costItemInfo in pairs(self.m_costItemInfoDict) do
            table.insert(ingredients, costItemInfo.itemInst.instId)
        end
        local addRefineLv = self:_GetCurAddRefineLv()
        local weaponInst = CharInfoUtils.getWeaponByInstId(self.m_weaponInfo.weaponInstId)
        local maxRefineLv = CS.Beyond.Gameplay.WeaponUtil.GetWeaponMaxRefineLv(self.m_weaponInfo.weaponTemplateId)
        local newRefineLv = weaponInst.refineLv + addRefineLv
        if newRefineLv > maxRefineLv then
            self:Notify(MessageConst.SHOW_TOAST, Language.LUA_WEAPON_REFINE_OVERFLOW)
            return
        end
        GameInstance.player.charBag:WeaponRefine(self.m_weaponInfo.weaponInstId, math.min(weaponInst.refineLv + addRefineLv, maxRefineLv), ingredients)
    end)
end
WeaponExhibitPotentialCtrl.OnShow = HL.Override() << function(self)
    local weaponInfo = self.m_weaponInfo
    local weaponExhibitInfo = CharInfoUtils.getWeaponExhibitBasicInfo(weaponInfo.weaponTemplateId, weaponInfo.weaponInstId)
    self.m_costItemInfoDict = {}
    self:_RefreshPotentialPanelBasic(weaponExhibitInfo, true)
    self:_RefreshWeaponPotentialStar(weaponExhibitInfo.weaponInst.templateId, weaponExhibitInfo.weaponInst.instId)
end
WeaponExhibitPotentialCtrl._RefreshPotentialPanelBasic = HL.Method(HL.Table, HL.Opt(HL.Boolean)) << function(self, weaponExhibitInfo, isInit)
    self.view.title.text = string.format(Language.LUA_WEAPON_EXHIBIT_POTENTIAL_TITLE, weaponExhibitInfo.itemCfg.name)
    self.view.expandNode.gameObject:SetActive(false)
    self:_RefreshSkillNode(weaponExhibitInfo.weaponInst.templateId, weaponExhibitInfo.weaponInst.instId, isInit == true)
    self:_RefreshButtonNode(weaponExhibitInfo)
    self:_RefreshCommonItemList(weaponExhibitInfo)
end
WeaponExhibitPotentialCtrl._RefreshButtonNode = HL.Method(HL.Table) << function(self, weaponExhibitInfo)
    local isMaxPotential = weaponExhibitInfo.weaponInst.refineLv >= UIConst.CHAR_MAX_POTENTIAL
    if isMaxPotential then
        self.view.btnLevelUp.gameObject:SetActive(false)
        self.view.upgradeNode.gameObject:SetActive(false)
        return
    end
end
WeaponExhibitPotentialCtrl._RefreshCommonItemList = HL.Method(HL.Table) << function(self, weaponExhibitInfo)
    self.view.commonWeaponList:InitCommonItemList({
        listType = UIConst.COMMON_ITEM_LIST_TYPE.WEAPON_EXHIBIT_POTENTIAL,
        filter_templateId = weaponExhibitInfo.weaponInst.templateId,
        filter_not_instId = weaponExhibitInfo.weaponInst.instId,
        filter_not_equipped = true,
        filter_not_maxPotential = true,
        onClickItem = function(args)
            local itemInfo = args.itemInfo
            local curCell = args.curCell
            local nextCell = args.nextCell
            self:_OnClickExpandCostItemCell(itemInfo, args.realClick)
            if curCell then
            end
            if nextCell then
                self:_RefreshWeaponCellAddOn(nextCell, itemInfo)
            end
        end,
        refreshItemAddOn = function(cell, itemInfo)
            self:_RefreshWeaponCellAddOn(cell, itemInfo)
        end
    })
end
WeaponExhibitPotentialCtrl._RefreshWeaponCellAddOn = HL.Method(HL.Any, HL.Opt(HL.Table)) << function(self, cell, itemInfo)
    cell.emptyNode.onClick:RemoveAllListeners()
    cell.emptyNode.onClick:AddListener(function()
        self:_ToggleExpandNode(true)
    end)
    if itemInfo == nil then
        cell.selectNode.gameObject:SetActive(false)
        cell.multiSelectNode.gameObject:SetActive(false)
        cell.emptyNode.gameObject:SetActive(true)
        return
    end
    cell.btnMinus.onClick:RemoveAllListeners()
    cell.btnMinus.onClick:AddListener(function()
        self:_RefreshWeaponCellAddOn(cell, itemInfo)
        self:_RemoveFromCostItemDict(itemInfo, 1)
    end)
    cell.emptyNode.gameObject:SetActive(false)
    cell.selectNode.gameObject:SetActive(itemInfo.count ~= nil and itemInfo.count > 0)
    cell.multiSelectNode.gameObject:SetActive(false)
    cell.selectCount.text = itemInfo.count
end
WeaponExhibitPotentialCtrl._OnClickExpandCostItemCell = HL.Method(HL.Table, HL.Boolean) << function(self, costItemInfo, realClick)
    if not realClick then
        return
    end
    if self.m_lastClickItemId ~= costItemInfo.indexId then
        Notify(MessageConst.SHOW_ITEM_TIPS, { transform = self.view.expandNode.tipPos, itemId = costItemInfo.itemCfg.id, instId = costItemInfo.indexId, noJump = true, autoClose = false, isSideTips = true, })
    end
    self.m_lastClickItemId = costItemInfo.indexId
    self.m_lastClickItemInfo = costItemInfo
    self:_AddIntoCostItemDict(costItemInfo, 1)
end
WeaponExhibitPotentialCtrl._AddIntoCostItemDict = HL.Method(HL.Table, HL.Number) << function(self, itemInfo, count)
    local weaponInfo = self.m_weaponInfo
    self:_TryAddIntoCostItemDict(itemInfo, count)
    self:_RefreshBottomCostItem(true)
    self:_RefreshSkillNode(weaponInfo.weaponTemplateId, weaponInfo.weaponInstId)
    self:_RefreshWeaponPotentialStar(weaponInfo.weaponTemplateId, weaponInfo.weaponInstId)
end
WeaponExhibitPotentialCtrl._RemoveFromCostItemDict = HL.Method(HL.Table, HL.Opt(HL.Number)) << function(self, itemInfo, count)
    local costItemInfoDict = self.m_costItemInfoDict
    local weaponInfo = self.m_weaponInfo
    local id = itemInfo.indexId
    itemInfo.count = 0
    if costItemInfoDict[id] and itemInfo.count <= 0 then
        costItemInfoDict[id] = nil
    end
    self:_RefreshBottomCostItem(true)
    self:_RefreshSkillNode(weaponInfo.weaponTemplateId, weaponInfo.weaponInstId)
    self:_RefreshWeaponPotentialStar(weaponInfo.weaponTemplateId, weaponInfo.weaponInstId)
    self.view.commonWeaponList:RefreshCellById(itemInfo.indexId)
end
WeaponExhibitPotentialCtrl._TryAddIntoCostItemDict = HL.Method(HL.Table, HL.Number) << function(self, itemInfo, count)
    local curCount = itemInfo.count or 0
    local nextCount = curCount + count
    local weaponInfo = self.m_weaponInfo
    local weaponInst = CharInfoUtils.getWeaponByInstId(weaponInfo.weaponInstId)
    if count <= 0 then
        return nextCount
    end
    local isLock = GameInstance.player.inventory:IsItemLocked(Utils.getCurrentScope(), itemInfo.itemInst.templateId, itemInfo.itemInst.instId)
    if isLock then
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_WEAPON_EXHIBIT_UPGRADE_WEAPON_LOCKED)
        return
    end
    local costItemInfoDict = self.m_costItemInfoDict
    local curAddRefineLv = self:_GetCurAddRefineLv()
    if curAddRefineLv >= (UIConst.CHAR_MAX_POTENTIAL - weaponInst.refineLv) then
        self:Notify(MessageConst.SHOW_TOAST, Language.LUA_WEAPON_EXHIBIT_POTENTIAL_MAX_TOAST)
        return
    end
    local hasGemAttached = itemInfo.isWeapon and itemInfo.itemInst.attachedGemInstId > 0
    if hasGemAttached then
        local gemInst = CharInfoUtils.getGemByInstId(itemInfo.itemInst.attachedGemInstId)
        local gemItemCfg = Tables.itemTable:GetValue(gemInst.templateId)
        Notify(MessageConst.SHOW_POP_UP, {
            content = string.format(Language.LUA_WEAPON_EXHIBIT_UPGRADE_GEM_EQUIPPED, gemItemCfg.name),
            onConfirm = function()
                GameInstance.player.charBag:DetachGem(itemInfo.itemInst.instId)
            end,
            onCancel = function()
            end
        })
        return
    end
    itemInfo.count = nextCount
    if itemInfo.count > 0 then
        local indexId = itemInfo.indexId
        costItemInfoDict[indexId] = itemInfo
    end
end
WeaponExhibitPotentialCtrl._GetCurAddRefineLv = HL.Method().Return(HL.Number) << function(self)
    local addRefineLv = 0
    for i, itemInfo in pairs(self.m_costItemInfoDict) do
        local weaponInst = CharInfoUtils.getWeaponByInstId(itemInfo.indexId)
        addRefineLv = addRefineLv + weaponInst.refineLv + 1
    end
    return lume.clamp(addRefineLv, 0, UIConst.CHAR_MAX_POTENTIAL)
end
WeaponExhibitPotentialCtrl._RefreshBottomCostItem = HL.Method(HL.Opt(HL.Boolean)) << function(self, skipGraduallyShow)
    local costItemInfoList = self:_CollectCostItemInfoList()
    local costCellCount = math.max(#costItemInfoList, UIConst.WEAPON_EXHIBIT_UPGRADE_MIN_SLOT_NUM)
    self.view.m_bottomWeaponCellCache:Refresh(costCellCount, function(cell, index)
        local costItemInfo = costItemInfoList[index]
        cell.emptyNode.gameObject:SetActive(costItemInfo == nil)
        cell.item.gameObject:SetActive(costItemInfo ~= nil)
        self:_RefreshWeaponCellAddOn(cell, costItemInfo)
        cell.btnMinus.onClick:AddListener(function()
            self:_RemoveFromCostItemDict(costItemInfo, 1)
        end)
        if costItemInfo then
            cell.item:InitItem({ id = costItemInfo.itemCfg.id, instId = costItemInfo.isWeapon and costItemInfo.indexId or 0, }, function()
                self:_ToggleExpandNode(true)
            end)
        end
    end)
end
WeaponExhibitPotentialCtrl._ToggleExpandNode = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, isOn, closeAll)
    self.m_lastClickItemId = nil
    self.m_lastClickItemInfo = nil
    if UIManager:IsShow(PanelId.ItemTips) then
        Notify(MessageConst.HIDE_ITEM_TIPS)
        if not closeAll then
            return
        end
    end
    if isOn then
        UIUtils.PlayAnimationAndToggleActive(self.view.commonWeaponList.view.animationWrapper, true)
        self.view.expandNode.gameObject:SetActive(true)
        self.view.commonWeaponList:PlayGraduallyShow()
    else
        UIUtils.PlayAnimationAndToggleActive(self.view.commonWeaponList.view.animationWrapper, false, function()
            self.view.expandNode.gameObject:SetActive(false)
        end)
    end
end
WeaponExhibitPotentialCtrl._RefreshWeaponPotentialStar = HL.Method(HL.String, HL.Number, HL.Opt(HL.Boolean)) << function(self, templateId, instId)
    local weaponInst = CharInfoUtils.getWeaponByInstId(instId)
    local addRefineLv = self:_GetCurAddRefineLv()
    local isMaxPotential = weaponInst.refineLv >= UIConst.CHAR_MAX_POTENTIAL
    if isMaxPotential then
        self.view.arrowNode.gameObject:SetActive(false)
        self.view.maxPotentialNode.gameObject:SetActive(true)
        self.view.potentialBefore.gameObject:SetActive(false)
        self.view.potentialAfter.gameObject:SetActive(false)
    else
        self.view.potentialBefore:InitWeaponPotentialStar(weaponInst.refineLv)
        self.view.potentialAfter:InitWeaponPotentialStar(weaponInst.refineLv + addRefineLv, { showMaxPotentialHint = false, fromLv = weaponInst.refineLv })
    end
end
WeaponExhibitPotentialCtrl._RefreshSkillNode = HL.Method(HL.String, HL.Number, HL.Opt(HL.Boolean)) << function(self, templateId, instId, isInit)
    local weaponInst = CharInfoUtils.getWeaponByInstId(instId)
    local addRefineLv = self:_GetCurAddRefineLv()
    local maxRefineLv = CS.Beyond.Gameplay.WeaponUtil.GetWeaponMaxRefineLv(templateId)
    local isMaxRefineLv = weaponInst.refineLv >= maxRefineLv
    self.view.weaponSkillNodeBefore.gameObject:SetActive(not isMaxRefineLv)
    self:_RefreshBottomCostItem()
    if not isMaxRefineLv then
        self.view.weaponSkillNodeBefore:InitWeaponSkillNode(instId, { tryGemInstId = weaponInst.attachedGemInstId, tryBreakthroughLv = weaponInst.breakthroughLv, tryRefineLv = weaponInst.refineLv, onlyPotentialSkill = true, })
    end
    self.view.weaponSkillNodeAfter:InitWeaponSkillNode(instId, { tryGemInstId = weaponInst.attachedGemInstId, tryBreakthroughLv = weaponInst.breakthroughLv, tryRefineLv = weaponInst.refineLv + addRefineLv, onlyPotentialSkill = true, })
    self.view.weaponIntroduction:InitWeaponIntroduction(templateId, instId)
end
WeaponExhibitPotentialCtrl._CollectCostItemInfoList = HL.Method().Return(HL.Table) << function(self)
    local costItemList = {}
    for i, itemInfo in pairs(self.m_costItemInfoDict) do
        table.insert(costItemList, itemInfo)
    end
    return costItemList
end
HL.Commit(WeaponExhibitPotentialCtrl)