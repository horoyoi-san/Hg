local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CharInfo
CharInfoCtrl = HL.Class('CharInfoCtrl', uiCtrl.UICtrl)
local CONTROL_TAB_FUNC_DICT = { [UIConst.CHAR_INFO_TAB_TYPE.OVERVIEW] = { pageType = UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW, name = "tab_char_overview", audioEvent = "au_ui_btn_menu_overview", isUnlocked = true, gyroscopeEffect = Types.EPanelGyroscopeEffect.Enable, }, [UIConst.CHAR_INFO_TAB_TYPE.WEAPON] = { pageType = UIConst.CHAR_INFO_PAGE_TYPE.WEAPON, name = "tab_char_weapon", audioEvent = "au_ui_btn_menu_weapon", systemUnlockType = GEnums.UnlockSystemType.Weapon, lockTip = Language.LUA_SYSTEM_WEAPON_LOCKED, gyroscopeEffect = Types.EPanelGyroscopeEffect.Enable, }, [UIConst.CHAR_INFO_TAB_TYPE.EQUIP] = { pageType = UIConst.CHAR_INFO_PAGE_TYPE.EQUIP, name = "tab_char_equip", audioEvent = "au_ui_btn_menu_equip", systemUnlockType = GEnums.UnlockSystemType.Equip, gyroscopeEffect = Types.EPanelGyroscopeEffect.Enable, lockTip = Language.LUA_SYSTEM_EQUIP_LOCKED, redDot = "EquipTab", }, [UIConst.CHAR_INFO_TAB_TYPE.POTENTIAL] = { pageType = UIConst.CHAR_INFO_PAGE_TYPE.POTENTIAL, name = "tab_char_potential", audioEvent = "au_ui_btn_menu_potential", gyroscopeEffect = Types.EPanelGyroscopeEffect.Enable, isUnlocked = true, lockTip = Language.LUA_SYSTEM_POTENTIAL_LOCKED, redDot = "CharInfoPotential", }, }
CharInfoCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.P_CHAR_INFO_SELECT_CHAR_CHANGE] = 'OnSelectCharChange', [MessageConst.P_CHAR_INFO_EMPTY_BUTTON_CLICK] = 'OnCommonEmptyButtonClick', [MessageConst.TOGGLE_CHAR_INFO_FOCUS_MODE] = "OnToggleFocusMode", [MessageConst.TOGGLE_CHAR_INFO_TOGGLE_MENU_AND_TOP_BTN] = "OnToggleMenuListAndTopBtn", }
do
    CharInfoCtrl.m_getCharHeadCell = HL.Field(HL.Function)
    CharInfoCtrl.m_charInfoList = HL.Field(HL.Table)
    CharInfoCtrl.m_charInfo = HL.Field(HL.Table)
    CharInfoCtrl.m_professionCache = HL.Field(HL.Forward("UIListCache"))
    CharInfoCtrl.m_elementalCache = HL.Field(HL.Forward("UIListCache"))
    CharInfoCtrl.m_equipIsOn = HL.Field(HL.Boolean) << false
    CharInfoCtrl.m_effectCor = HL.Field(HL.Thread)
    CharInfoCtrl.m_tabCellCache = HL.Field(HL.Forward("UIListCache"))
    CharInfoCtrl.m_equipSlotMap = HL.Field(HL.Table)
    CharInfoCtrl.m_curPageType = HL.Field(HL.Number) << UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW
    CharInfoCtrl.m_focusMode = HL.Field(HL.Boolean) << false
    CharInfoCtrl.m_isCharListInited = HL.Field(HL.Boolean) << false
end
CharInfoCtrl.OnCreate = HL.Override(HL.Opt(HL.Any)) << function(self, arg)
    local initCharInfo = arg.initCharInfo or CharInfoUtils.getLeaderCharInfo()
    local pageType = arg.pageType or UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW
    self.m_phase = arg.phase
    self.m_curPageType = pageType
    self.m_charInfo = initCharInfo
    self.m_charInfoList = arg.phase.m_charInfoList
    self:_InitActionEvent()
    self:OnPageChange(arg)
end
CharInfoCtrl.PhaseCharInfoPanelShowFinal = HL.Method(HL.Table) << function(self, arg)
    local initCharInfo = arg.initCharInfo or CharInfoUtils.getLeaderCharInfo()
    local pageType = arg.pageType or UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW
    self.m_phase = arg.phase
    self.m_curPageType = pageType
    self.m_charInfo = initCharInfo
    self.m_charInfoList = arg.phase.m_charInfoList
    self:Show()
end
CharInfoCtrl.OnShow = HL.Override() << function(self)
    self:OnPageChange(self.m_curPageType)
end
CharInfoCtrl.OnSelectCharChange = HL.Method(HL.Table) << function(self, charInfo)
    self.m_charInfo = charInfo
    self:_RefreshCharInfo(charInfo, self.m_charInfoList)
    if self.view.charInfoBasicNodeRight.gameObject.activeSelf then
        self.view.charInfoBasicNodeRight.view.animationWrapper:PlayInAnimation()
    end
    self.view.textTitle.text = CharInfoUtils.getCharInfoTitle(self.m_charInfo.templateId, self.m_curPageType)
end
CharInfoCtrl.OnCommonEmptyButtonClick = HL.Method(HL.Opt(HL.Userdata)) << function(self, _)
    self:_ToggleExpandNode(false)
end
CharInfoCtrl.OnToggleFocusMode = HL.Method(HL.Boolean) << function(self, isOn)
    if self.m_focusMode == isOn then
        return
    end
    self.m_focusMode = isOn
    if isOn then
        self:PlayAnimationOut(UIConst.PANEL_PLAY_ANIMATION_OUT_COMPLETE_ACTION_TYPE.Hide)
    else
        self:Show()
    end
end
CharInfoCtrl.OnToggleMenuListAndTopBtn = HL.Method(HL.Boolean) << function(self, isOn)
    self.view.menuListNode.gameObject:SetActive(isOn)
    self.view.closeButton.gameObject:SetActive(isOn)
end
CharInfoCtrl._InitActionEvent = HL.Method() << function(self)
    self.m_getCharHeadCell = UIUtils.genCachedCellFunction(self.view.charListNode.charList)
    local charInst = CharInfoUtils.getPlayerCharInfoByInstId(self.m_charInfo.instId)
    self.view.bottomMenuNode.gameObject:SetActive(charInst and charInst.charType ~= GEnums.CharType.Trial)
    self.view.previewBtn.onClick:AddListener(function()
        self:Notify(MessageConst.P_CHAR_INFO_PAGE_CHANGE, { pageType = UIConst.CHAR_INFO_PAGE_TYPE.PROFILE_SHOW, extraArg = { onlyShow = true } })
    end)
    self.view.fashionBtn.onClick:AddListener(function()
        self:Notify(MessageConst.SHOW_TOAST, "切时装(还没做)")
    end)
    self.view.profileBtn.onClick:AddListener(function()
        self:Notify(MessageConst.P_CHAR_INFO_PAGE_CHANGE, { pageType = UIConst.CHAR_INFO_PAGE_TYPE.PROFILE })
    end)
    self.view.profileBtnRedDot:InitRedDot("CharInfoProfile", self.m_charInfo.templateId)
    self.view.closeButton.onClick:AddListener(function()
        self:Notify(MessageConst.P_ON_COMMON_BACK_CLICKED)
    end)
    self:BindInputPlayerAction("common_close_char_panel", function()
        PhaseManager:PopPhase(PhaseId.CharInfo)
    end)
    self.view.expandListButton.onClick:AddListener(function()
        self:_ToggleExpandNode(true)
    end)
    self.view.charListNode.charList.onUpdateCell:AddListener(function(object, csIndex)
        self:_RefreshSmallCharHeadCell(object, csIndex)
    end)
    self.m_tabCellCache = UIUtils.genCellCache(self.view.menuListCell)
    self.view.upgradeBtn.onClick:AddListener(function()
        local isTrail = CharInfoUtils.checkIsCardInTrail(self.m_charInfo.instId)
        if isTrail then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_CHAR_INFO_UPGRADE_FORBID)
            return
        end
        local isMaxLv = CharInfoUtils.checkIfCharMaxLv(self.m_charInfo.instId)
        if isMaxLv then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_CHAR_INFO_MAX_LV_TOAST)
            return
        end
        self:Notify(MessageConst.P_CHAR_INFO_PAGE_CHANGE, { pageType = UIConst.CHAR_INFO_PAGE_TYPE.UPGRADE })
    end)
    self.view.skillBtn.onClick:AddListener(function()
        self:Notify(MessageConst.P_CHAR_INFO_PAGE_CHANGE, { pageType = UIConst.CHAR_INFO_PAGE_TYPE.TALENT })
    end)
    self.m_equipSlotMap = {}
    for _, equipType in pairs(UIConst.CHAR_INFO_EQUIP_SLOT_MAP) do
        local cellConfig = UIConst.EQUIP_PART_TYPE_2_CELL_CONFIG[equipType]
        if cellConfig then
            local equipCellName = "equip_" .. cellConfig.equipPostfix
            local equipCell = self.view[equipCellName]
            if equipCell ~= nil then
                self.m_equipSlotMap[equipType] = equipCell
            else
                logger.error("equipCell is nil, equipType: " .. equipType)
            end
        end
    end
end
CharInfoCtrl._RefreshCharInfo = HL.Method(HL.Table, HL.Table) << function(self, initCharInfo, charInfoList)
    self:_RefreshCharList(initCharInfo, charInfoList)
    self:_RefreshCharInfoBasic(initCharInfo.instId)
    if self.view.detailNode.gameObject.activeSelf then
        self:_RefreshDetailNode(initCharInfo)
    end
    self:_RefreshRedDot()
end
CharInfoCtrl._RefreshCharInfoBasic = HL.Method(HL.Number) << function(self, charInstId)
    self.view.charInfoBasicNodeLeft:InitCharInfoBasicNode(charInstId)
    self.view.charInfoBasicNodeRight:InitCharInfoBasicNode(charInstId, true)
end
CharInfoCtrl._RefreshCharList = HL.Method(HL.Table, HL.Table) << function(self, initCharInfo, charInfoList)
    if self.m_phase then
        self.m_phase:RefreshCharExpandList(initCharInfo, charInfoList)
    end
    self.view.charListNode.charList:UpdateCount(#charInfoList)
    self.m_isCharListInited = true
end
CharInfoCtrl._RefreshSmallCharHeadCell = HL.Method(HL.Userdata, HL.Number) << function(self, object, csIndex)
    local charInfo = self.m_charInfoList[LuaIndex(csIndex)]
    local templateId = charInfo.templateId
    local instId = charInfo.instId
    local charHeadCell = self.m_getCharHeadCell(object)
    local isSameInstId = charInfo.instId == self.m_charInfo.instId
    local isInSlot = CharInfoUtils.checkIsCardInSlot(instId)
    charHeadCell.tryoutTips.gameObject:SetActive(charInfo.isShowTrail)
    charHeadCell.fixedTips.gameObject:SetActive(charInfo.isShowFixed)
    charHeadCell.redDot:InitRedDot("CharInfo", instId)
    charHeadCell.charInfo = charInfo
    charHeadCell.bgSelected.gameObject:SetActive(isSameInstId)
    charHeadCell.charImage.sprite = self:LoadSprite(CharInfoUtils.getCharHeadSpriteName(templateId))
    charHeadCell.formationMark.gameObject:SetActive(isInSlot)
    charHeadCell.button.onClick:RemoveAllListeners()
    charHeadCell.button.onClick:AddListener(function()
        self:_OnClickCharHeadCell(charHeadCell.charInfo, true)
    end)
end
CharInfoCtrl._ToggleExpandNode = HL.Method(HL.Boolean) << function(self, isOn)
    if isOn then
        self.view.charListNode.animation:Play("charinfo_top_all_out")
    else
        self.view.charListNode.animation:Play("charinfo_top_all_in")
    end
    if self.m_curPageType ~= UIConst.CHAR_INFO_TAB_TYPE.OVERVIEW then
        if isOn then
            local args = {
                onClickCell = function(charInfo)
                    self:_OnClickCharHeadCell(charInfo, true)
                end,
                charInfo = self.m_charInfo,
                charInfoList = self.m_charInfoList,
                refreshAddon = function(cell, charInfo)
                    cell.view.selectedBG.gameObject:SetActive(charInfo.instId == self.m_charInfo.instId)
                end
            }
            self.m_phase:ShowCharExpandList(args)
        else
            self.m_phase:HideCharExpandList()
        end
        return
    end
    if isOn then
        self.view.topNode:Play("charinfo_top_all_out")
        self.view.gyroscopeRoot:ClearTween(false)
        self.view.gyroscopeRoot:PlayOutAnimation(function()
            self.view.menuListNode.gameObject:SetActive(false)
            UIUtils.PlayAnimationAndToggleActive(self.view.charInfoBasicNodeRight.view.animationWrapper, true)
            local args = {
                onClickCell = function(charInfo)
                    self:_OnClickCharHeadCell(charInfo, true)
                end,
                charInfo = self.m_charInfo,
                charInfoList = self.m_charInfoList,
                refreshAddon = function(cell, charInfo)
                    cell.view.selectedBG.gameObject:SetActive(charInfo.instId == self.m_charInfo.instId)
                end
            }
            self.m_phase:ShowCharExpandList(args)
        end)
    else
        self.view.topNode:Play("charinfo_top_all_in")
        self.m_phase:HideCharExpandList()
        UIUtils.PlayAnimationAndToggleActive(self.view.charInfoBasicNodeRight.view.animationWrapper, false, function()
            self.view.gyroscopeRoot:ClearTween(false)
            self.view.gyroscopeRoot:PlayInAnimation()
            self.view.menuListNode.gameObject:SetActive(true)
        end)
    end
    self.view.menuListNode.blocksRaycasts = not isOn
    self.view.charGradeNode.blocksRaycasts = not isOn
end
CharInfoCtrl._OnClickCharHeadCell = HL.Method(HL.Table, HL.Boolean) << function(self, charInfo, realClick)
    self:_ChangeSelectIndex(charInfo, realClick)
end
CharInfoCtrl._ChangeSelectIndex = HL.Method(HL.Table, HL.Boolean) << function(self, charInfo, realClick)
    local curTemplateId = self.m_charInfo.templateId
    local curInstId = self.m_charInfo.instId
    local templateId = charInfo.templateId
    if CharInfoUtils.getPlayerCharInfoByTemplateId(templateId, GEnums.CharType.Default) and RedDotManager:GetRedDotState("CharNew", templateId) then
        GameInstance.player.charBag:Send_RemoveCharNewTag(templateId)
    end
    if curTemplateId == charInfo.templateId and curInstId == charInfo.instId then
        return
    end
    self:Notify(MessageConst.P_CHAR_INFO_SELECT_CHAR_CHANGE, charInfo)
end
CharInfoCtrl._RefreshRedDot = HL.Method() << function(self)
    self.view.profileBtnRedDot:InitRedDot("CharInfoProfile", self.m_charInfo.templateId)
    self.view.skillBtnRedDot:InitRedDot("CharBreak", self.m_charInfo.instId)
    if self.m_tabCellCache then
        local count = self.m_tabCellCache:GetCount()
        for i = 1, count do
            local cell = self.m_tabCellCache:GetItem(i)
            local config = CONTROL_TAB_FUNC_DICT[i]
            local isUnlocked = self:_CheckIfTabUnlock(i)
            local redDot = config.redDot
            if isUnlocked and redDot then
                cell.redDot:InitRedDot(redDot, self.m_charInfo.instId)
            else
                cell.redDot:Stop()
            end
        end
    end
end
CharInfoCtrl._RefreshMenuNode = HL.Method(HL.Number) << function(self, curPageType)
    self.m_tabCellCache:Refresh(lume.count(CONTROL_TAB_FUNC_DICT), function(cell, index)
        local pageType = CONTROL_TAB_FUNC_DICT[index].pageType
        self:_RefreshTabCell(cell, index, pageType == curPageType)
        cell.gameObject.name = CONTROL_TAB_FUNC_DICT[index].name
    end)
end
CharInfoCtrl._RefreshDetailNode = HL.Method(HL.Table) << function(self, charInfo)
    self.view.charLevelNode:InitCharLevelNode(charInfo.instId)
    self.view.potentialRankNode:InitPotentialRankNode(charInfo.instId)
    self:_RefreshWeaponNode(charInfo)
    self:_RefreshEquipNode(charInfo)
end
CharInfoCtrl._RefreshWeaponNode = HL.Method(HL.Table) << function(self, charInfo)
    local weaponInfo = CharInfoUtils.getCharCurWeapon(charInfo.instId)
    local weaponExhibitInfo = CharInfoUtils.getWeaponExhibitBasicInfo(weaponInfo.weaponTemplateId, weaponInfo.weaponInstId)
    self.view.weaponIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, weaponExhibitInfo.itemCfg.iconId)
    UIUtils.setItemRarityImage(self.view.weaponRarityMarker.mainColor, weaponExhibitInfo.itemCfg.rarity)
    self.view.weaponLvText.text = weaponExhibitInfo.curLv
end
CharInfoCtrl._RefreshEquipNode = HL.Method(HL.Table) << function(self, charInfo)
    local instId = self.m_charInfo.instId
    local charInst = CharInfoUtils.getPlayerCharInfoByInstId(instId)
    local equips = charInst.equipCol
    for slotIndex, config in pairs(UIConst.EQUIP_PART_TYPE_2_CELL_CONFIG) do
        local cell = self.m_equipSlotMap[slotIndex]
        local itemId
        if config.isTacticalItem then
            local equippedTacticalId = charInst.tacticalItemId
            if equippedTacticalId and not string.isEmpty(equippedTacticalId) then
                itemId = charInst.tacticalItemId
            end
        else
            local equipIndex = UIConst.EQUIP_PART_TYPE_2_CELL_CONFIG[slotIndex].equipIndex
            local hasValue, equipInstId = equips:TryGetValue(equipIndex)
            if hasValue then
                local equipInst = CharInfoUtils.getEquipByInstId(equipInstId)
                itemId = equipInst.templateId
            end
        end
        local hasValue, itemCfg = Tables.itemTable:TryGetValue(itemId or "")
        cell.iconNode.gameObject:SetActive(hasValue)
        cell.emptyNode.gameObject:SetActive(not hasValue)
        cell.equipmentColorCell.gameObject:SetActive(hasValue)
        if hasValue then
            cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, itemCfg.iconId)
            UIUtils.setItemRarityImage(cell.equipmentColorCell.mainColor, itemCfg.rarity)
        end
    end
end
CharInfoCtrl._RefreshTabCell = HL.Method(HL.Any, HL.Number, HL.Boolean) << function(self, cell, index, isCurTab)
    local tabIcon = UIConst.CHAR_INFO_TAB_ICON_PREFIX .. index
    local config = CONTROL_TAB_FUNC_DICT[index]
    if cell.isCurTabBefore == false and isCurTab == true then
        UIUtils.PlayAnimationAndToggleActive(cell.cellSelected, true)
    elseif cell.isCurTabBefore == true and isCurTab == false then
        UIUtils.PlayAnimationAndToggleActive(cell.cellSelected, false)
    else
        cell.cellSelected.gameObject:SetActive(isCurTab)
    end
    cell.defalutBg.gameObject:SetActive(not isCurTab)
    cell.hotAreaBig.gameObject:SetActive(not isCurTab)
    cell.hotAreaSmall.gameObject:SetActive(isCurTab)
    cell.isCurTabBefore = isCurTab
    local isUnlocked = self:_CheckIfTabUnlock(index)
    cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_INFO, tabIcon)
    cell.button.onClick:RemoveAllListeners()
    cell.button.onClick:AddListener(function()
        self:_OnClickTab(index)
    end)
end
CharInfoCtrl._OnClickTab = HL.Method(HL.Number) << function(self, index)
    local config = CONTROL_TAB_FUNC_DICT[index]
    local isUnlocked = self:_CheckIfTabUnlock(index)
    if not isUnlocked then
        local lockTip = config.lockTip and Language[config.lockTip] or Language.LUA_FEATURE_NOT_AVAILABLE
        self:Notify(MessageConst.SHOW_TOAST, lockTip)
        AudioAdapter.PostEvent("au_ui_btn_menu_inactive")
        return
    end
    if self.m_curPageType == config.pageType then
        return
    end
    AudioAdapter.PostEvent(config.audioEvent)
    self:ChangePanelCfg("gyroscopeEffect", config.gyroscopeEffect)
    self:Notify(MessageConst.P_CHAR_INFO_PAGE_CHANGE, { pageType = config.pageType })
end
CharInfoCtrl.OnPageChange = HL.Method(HL.Any) << function(self, arg)
    local pageType = arg
    local extraArg
    if type(arg) == "table" then
        pageType = arg.pageType
        extraArg = arg.extraArg
    end
    self:_TryToggleDetailNode(true, pageType)
    self:_RefreshMenuNode(pageType)
    local isBeforePageOverview = self.m_curPageType == UIConst.CHAR_INFO_TAB_TYPE.OVERVIEW
    self.m_curPageType = pageType
    UIUtils.PlayAnimationAndToggleActive(self.view.bottomMenuCover, pageType == UIConst.CHAR_INFO_TAB_TYPE.OVERVIEW)
    if pageType == UIConst.CHAR_INFO_TAB_TYPE.OVERVIEW then
        self:_RefreshCharInfo(self.m_charInfo, self.m_charInfoList)
        self:_RefreshDetailNode(self.m_charInfo)
        self.view.topNode:Play("charinfo_top_btn_in")
    elseif isBeforePageOverview then
        self.view.topNode:Play("charinfo_top_btn_out")
    end
    if not self.m_isCharListInited then
        self:_RefreshCharList(self.m_charInfo, self.m_charInfoList)
    end
    self.view.textTitle.text = CharInfoUtils.getCharInfoTitle(self.m_charInfo.templateId, pageType)
    local isShowDetailNode = pageType == UIConst.CHAR_INFO_PAGE_TYPE.OVERVIEW
    self.view.leftNode.gameObject:SetActive(isShowDetailNode)
    self.view.detailNode.gameObject:SetActive(isShowDetailNode)
end
CharInfoCtrl._TryToggleDetailNode = HL.Method(HL.Boolean, HL.Any) << function(self, isOn, pageType)
    local shouldActive = isOn and pageType == UIConst.CHAR_INFO_TAB_TYPE.OVERVIEW
    if shouldActive then
        self.view.gyroscopeRoot:ClearTween(false)
        self.view.gyroscopeRoot:PlayInAnimation()
    else
        self.view.gyroscopeRoot:ClearTween(false)
        self.view.gyroscopeRoot:PlayOutAnimation()
    end
end
CharInfoCtrl._CheckIfTabUnlock = HL.Method(HL.Number).Return(HL.Boolean) << function(self, tabIndex)
    local config = CONTROL_TAB_FUNC_DICT[tabIndex]
    if config.isUnlocked ~= nil then
        return config.isUnlocked
    end
    if config.systemUnlockType then
        return Utils.isSystemUnlocked(config.systemUnlockType)
    end
    return false
end
HL.Commit(CharInfoCtrl)