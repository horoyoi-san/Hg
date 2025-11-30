local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.EquipEnhance
local PHASE_ID = PhaseId.EquipEnhance
EquipEnhanceCtrl = HL.Class('EquipEnhanceCtrl', uiCtrl.UICtrl)
local STATE_NAME = { EQUIP_SELECTION = "equipSelection", MATERIAL_SELECTION = "materialSelection", EQUIP_SELECTION_EMPTY = "equipSelectionEmpty", MATERIAL_SELECTION_EMPTY = "materialSelectionEmpty", }
EquipEnhanceCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_EQUIP_ENHANCE] = '_OnEquipEnhance', }
EquipEnhanceCtrl.m_selectedEquipInstId = HL.Field(HL.Number) << 0
EquipEnhanceCtrl.m_equipTechSystem = HL.Field(CS.Beyond.Gameplay.EquipTechSystem)
EquipEnhanceCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_equipTechSystem = GameInstance.player.equipTechSystem
    self.view.topBar.btnClose.onClick:AddListener(function()
        PhaseManager:PopPhase(PHASE_ID)
    end)
    self.view.topBar.btnBack.onClick:AddListener(function()
        self:_ExistAttrEnhance()
    end)
    self.view.topBar.btnHelp.onClick:AddListener(function()
        UIManager:Open(PanelId.InstructionBook, "equip_enhance")
    end)
    self.view.middleBar.btnExplain.onClick:AddListener(function()
        if self.m_selectedEquipInstId == 0 then
            return
        end
        Notify(MessageConst.SHOW_TOAST, "等显示装备tips功能完成后接入")
    end)
    self.view.bottomNode.btnMake.onClick:AddListener(function()
        self:_OnEnhanceClicked()
    end)
    self.view.stateCtrl:SetState(STATE_NAME.EQUIP_SELECTION_EMPTY)
    self:_InitEquipPartTypeTabs()
    self:_RefreshEnhanceCount()
end
EquipEnhanceCtrl._OnEquipEnhance = HL.Method(HL.Table) << function(self, args)
    local equipInstId, enhancedAttrIndex = unpack(args)
    local attrShowInfo = self.m_selectedAttrShowInfoList[self.m_selectedAttrShowInfoIndex]
    if equipInstId ~= self.m_selectedItemInfo.instId or (enhancedAttrIndex >= 0 and attrShowInfo.enhancedAttrIndex ~= enhancedAttrIndex) then
        return
    end
    self:_RefreshEnhanceCount()
    self:_RefreshEnhancedEquip()
    self:_RefreshEquipEnhanceList()
    self:_RefreshEnhanceMaterialList()
    self:_RefreshEnhanceMaterial(nil)
    local equipInstData = EquipTechUtils.getEquipInstData(equipInstId)
    if enhancedAttrIndex >= 0 and equipInstData:IsAttrMaxEnhanced(enhancedAttrIndex) then
        self.view.stateCtrl:SetState(STATE_NAME.EQUIP_SELECTION)
    end
    local resultArgs = { isSuccessful = enhancedAttrIndex >= 0, equipInstId = equipInstId, attrShowInfo = attrShowInfo, nextLevelAttrShowValue = self.m_nextLevelAttrShowValue, }
    UIManager:Open(PanelId.EquipEnhanceResult, resultArgs)
end
local equipPartTypeTabConfig = { [1] = { partType = nil, }, [2] = { partType = GEnums.PartType.Body, }, [3] = { partType = GEnums.PartType.Hand, }, [4] = { partType = GEnums.PartType.EDC, }, }
EquipEnhanceCtrl._InitEquipPartTypeTabs = HL.Method() << function(self)
    local genCellCache = UIUtils.genCellCache(self.view.leftBar.typesNode.typeCell)
    genCellCache:Refresh(#equipPartTypeTabConfig, function(cell, index)
        local tabCfg = equipPartTypeTabConfig[index]
        if tabCfg.partType then
            local partTypeSprite = self:LoadSprite(UIConst.UI_SPRITE_EQUIP_PART_ICON, UIConst.EQUIP_TYPE_TO_ICON_NAME[tabCfg.partType])
            cell.lightIcon.sprite = partTypeSprite
            cell.dimIcon.sprite = partTypeSprite
        end
        cell.toggle.onValueChanged:AddListener(function(isOn)
            if isOn then
                self.m_partType = tabCfg.partType
                self:_RefreshEquipEnhanceList()
            end
        end)
    end)
    genCellCache:GetItem(1).toggle.isOn = true
end
EquipEnhanceCtrl.m_partType = HL.Field(HL.Any)
EquipEnhanceCtrl.m_selectedItemInfo = HL.Field(HL.Table)
EquipEnhanceCtrl._RefreshEquipEnhanceList = HL.Method() << function(self)
    local itemListArgs = {
        listType = UIConst.COMMON_ITEM_LIST_TYPE.EQUIP_TECH_EQUIP_ENHANCE,
        onClickItem = function(args)
            self.m_selectedItemInfo = args.itemInfo
            self:_RefreshEnhancedEquip()
        end,
        onFilterNone = function()
            self.m_selectedItemInfo = nil
            self:_RefreshEnhancedEquip()
        end,
        setItemSelected = function(cell, isSelected)
            cell.imgBg.gameObject:SetActive(not isSelected)
            cell.imgSelectBg.gameObject:SetActive(isSelected)
            cell.txtName.color = isSelected and cell.config.COLOR_NAME_SELECTED or cell.config.COLOR_NAME_NORMAL
        end,
        getItemBtn = function(cell)
            return cell.btn
        end,
        refreshItemAddOn = function(cell, itemInfo)
            cell.txtName.text = itemInfo.data.name
            cell.equipEnhanceLevelNode:InitEquipEnhanceLevelNode({ equipInstId = itemInfo.instId, })
            cell.equipItem:InitEquipItem({ equipInstId = itemInfo.instId, noInitItem = true, itemInteractable = false, })
        end,
        filter_equipType = self.m_partType,
    }
end
EquipEnhanceCtrl.m_enhanceAttrCellCache = HL.Field(HL.Forward("UIListCache"))
EquipEnhanceCtrl.m_selectedAttrShowInfoList = HL.Field(HL.Table)
EquipEnhanceCtrl.m_selectedAttrShowInfoIndex = HL.Field(HL.Number) << 0
EquipEnhanceCtrl._RefreshEnhancedEquip = HL.Method() << function(self)
    local isEmpty = self.m_selectedItemInfo == nil
    self.m_selectedEquipInstId = isEmpty and 0 or self.m_selectedItemInfo.instId
    self.view.stateCtrl:SetState(isEmpty and STATE_NAME.EQUIP_SELECTION_EMPTY or STATE_NAME.EQUIP_SELECTION)
    self.view.middleBar.slider.value = isEmpty and 0 or 1
    if isEmpty then
        return
    end
    local equipInstData = EquipTechUtils.getEquipInstData(self.m_selectedEquipInstId)
    local itemData = Tables.itemTable[self.m_selectedItemInfo.id]
    if itemData then
        self.view.middleBar.imgEquip.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM_BIG, itemData.iconId)
        self.view.middleBar.txtEquip.text = itemData.name
    end
    local _, primaryAttrs, nonPrimaryAttrs = CharInfoUtils.getEquipShowAttributes(self.m_selectedEquipInstId)
    self.m_selectedAttrShowInfoList = lume.concat(primaryAttrs, nonPrimaryAttrs)
    local attrCount = self.m_selectedAttrShowInfoList and #self.m_selectedAttrShowInfoList or 0
    self.m_enhanceAttrCellCache = self.m_enhanceAttrCellCache or UIUtils.genCellCache(self.view.rightBar.enhanceAttrCell)
    self.m_enhanceAttrCellCache:Refresh(attrCount, function(cell, luaIndex)
        local attrShowInfo = self.m_selectedAttrShowInfoList[luaIndex]
        local isEnhanced = equipInstData:IsAttrEnhanced(attrShowInfo.enhancedAttrIndex)
        local isMaxEnhanced = equipInstData:IsAttrMaxEnhanced(attrShowInfo.enhancedAttrIndex)
        cell.stateCtrl:SetState(isMaxEnhanced and "complete" or "normal")
        cell.txtName.text = attrShowInfo.showName
        cell.txtValue.text = EquipTechUtils.getAttrShowValueText(attrShowInfo)
        local color = isEnhanced and self.view.config.COLOR_ENHANCED or self.view.config.COLOR_NORMAL
        cell.txtName.color = color
        cell.txtValue.color = color
        cell.equipEnhanceLevelNode:InitEquipEnhanceLevelNode({ equipInstId = self.m_selectedEquipInstId, attrIndex = attrShowInfo.enhancedAttrIndex, })
        cell.btnEnhance.onClick:RemoveAllListeners()
        if not isMaxEnhanced then
            cell.btnEnhance.onClick:AddListener(function()
                self.m_selectedAttrShowInfoIndex = luaIndex
                self:_EnterAttrEnhance()
            end)
        end
    end)
end
EquipEnhanceCtrl._EnterAttrEnhance = HL.Method() << function(self)
    self.view.stateCtrl:SetState(STATE_NAME.MATERIAL_SELECTION_EMPTY)
    self:_RefreshEnhanceMaterialList()
    self:_RefreshEnhanceMaterial(nil)
end
EquipEnhanceCtrl._ExistAttrEnhance = HL.Method() << function(self)
    self.view.stateCtrl:SetState(STATE_NAME.EQUIP_SELECTION)
end
EquipEnhanceCtrl._RefreshEnhanceMaterialList = HL.Method() << function(self)
    local itemListArgs = {
        listType = UIConst.COMMON_ITEM_LIST_TYPE.EQUIP_TECH_EQUIP_ENHANCE_MATERIALS,
        onClickItem = function(args)
            self:_RefreshEnhanceMaterial(args.itemInfo)
        end,
        onFilterNone = function()
            self:_RefreshEnhanceMaterial(nil)
        end,
        setItemSelected = function(cell, isSelected)
            cell.selectedNode.gameObject:SetActive(isSelected)
        end,
        getItemBtn = function(cell)
            return cell.btn
        end,
        refreshItemAddOn = function(cell, itemInfo)
            cell.txtName.text = itemInfo.data.name
            cell.equipItem:InitEquipItem({ equipInstId = itemInfo.instId, noInitItem = true, itemInteractable = false, })
            cell.btnSymbol.onClick:RemoveAllListeners()
            cell.btnSymbol.onClick:AddListener(function()
                Notify(MessageConst.SHOW_TOAST, "等显示装备tips功能完成后接入")
            end)
            cell.txtNormal.gameObject:SetActive(itemInfo.equipEnhanceSuccessProb == EquipTechConst.EEquipEnhanceSuccessProb.Normal)
            cell.txtHigh.gameObject:SetActive(itemInfo.equipEnhanceSuccessProb == EquipTechConst.EEquipEnhanceSuccessProb.High)
        end,
        filter_equipType = self.m_selectedItemInfo.partType,
        attrShowInfo = self.m_selectedAttrShowInfoList[self.m_selectedAttrShowInfoIndex],
        equipInstId = self.m_selectedEquipInstId,
    }
end
EquipEnhanceCtrl.m_enhanceMaterialInstId = HL.Field(HL.Number) << 0
EquipEnhanceCtrl.m_nextLevelAttrShowValue = HL.Field(HL.String) << ""
EquipEnhanceCtrl.m_isCostItemCountEnough = HL.Field(HL.Boolean) << false
EquipEnhanceCtrl._RefreshEnhanceMaterial = HL.Method(HL.Table) << function(self, itemInfo)
    local isEmpty = itemInfo == nil
    self.m_enhanceMaterialInstId = isEmpty and 0 or itemInfo.instId
    local attrShowInfo = self.m_selectedAttrShowInfoList[self.m_selectedAttrShowInfoIndex]
    self.view.stateCtrl:SetState(isEmpty and STATE_NAME.MATERIAL_SELECTION_EMPTY or STATE_NAME.MATERIAL_SELECTION)
    self.view.selectMaterials.equipItem:InitEquipItem({ equipInstId = self.m_enhanceMaterialInstId, })
    self.view.middleBar.makeNode.txtName.text = attrShowInfo.showName
    self.view.middleBar.makeNode.equipEnhanceLevelNode:InitEquipEnhanceLevelNode({ equipInstId = self.m_selectedEquipInstId, attrIndex = attrShowInfo.enhancedAttrIndex, showNextLevel = not isEmpty, })
    self.view.makeNode.txtBefore.text = EquipTechUtils.getAttrShowValueText(attrShowInfo)
    self.view.makeNode.highSuccessRationNode.gameObject:SetActive(not isEmpty and itemInfo.equipEnhanceSuccessProb == EquipTechConst.EEquipEnhanceSuccessProb.High)
    self.view.makeNode.normalSuccessRationNode.gameObject:SetActive(not isEmpty and itemInfo.equipEnhanceSuccessProb == EquipTechConst.EEquipEnhanceSuccessProb.Normal)
    if isEmpty then
        return
    end
    self.m_nextLevelAttrShowValue = EquipTechUtils.getAttrShowValueText(attrShowInfo, true, self.m_selectedEquipInstId)
    self.view.makeNode.txtAfter.text = self.m_nextLevelAttrShowValue
    local costItemData = Tables.itemTable[Tables.equipConst.enhanceConsumeItemId]
    local itemCount = Utils.getItemCount(costItemData.id)
    local costItemCount = Tables.equipConst.enhanceConsumeItemCount
    self.m_isCostItemCountEnough = itemCount >= costItemCount
    self.view.bottomNode.imgIcon.sprite = self:LoadSprite(UIConst.UI_SPRITE_ITEM, costItemData.iconId)
    self.view.bottomNode.txtCost.color = self.m_isCostItemCountEnough and Color.white or self.view.config.COST_NOT_ENOUGH_COLOR
    self.view.bottomNode.txtCost.text = string.format("%d/%d", itemCount, costItemCount)
    self.view.bottomNode.btnIcon.onClick:RemoveAllListeners()
    self.view.bottomNode.btnIcon.onClick:AddListener(function()
        Notify(MessageConst.SHOW_ITEM_TIPS, { itemId = costItemData.id, transform = self.view.bottomNode.imgIcon.transform, posType = UIConst.UI_TIPS_POS_TYPE.LeftTop, })
    end)
end
EquipEnhanceCtrl._OnEnhanceClicked = HL.Method() << function(self)
    if self.m_selectedEquipInstId == 0 or self.m_enhanceMaterialInstId == 0 then
        return
    end
    if not self.m_hasEnhanceCount or not self.m_isCostItemCountEnough then
        Notify(MessageConst.SHOW_TOAST, not self.m_isCostItemCountEnough and Language.LUA_EQUIP_ENHANCE_MATERIAL_NOT_ENOUGH or Language.LUA_EQUIP_ENHANCE_COUNT_NOT_ENOUGH)
        return
    end
    local enhanceMaterialEquipInstData = CharInfoUtils.getEquipByInstId(self.m_enhanceMaterialInstId)
    local subContent = nil
    if enhanceMaterialEquipInstData:IsEnhanced() then
        subContent = Language.LUA_EQUIP_ENHANCE_MATERIAL_POPUP_SUB_TITLE
    end
    Notify(MessageConst.SHOW_POP_UP, {
        content = Language.LUA_EQUIP_ENHANCE_MATERIAL_POPUP_TITLE,
        subContent = subContent,
        equipInstId = self.m_enhanceMaterialInstId,
        onConfirm = function()
            local attrIndex = self.m_selectedAttrShowInfoList[self.m_selectedAttrShowInfoIndex].enhancedAttrIndex
            self.m_equipTechSystem:EnhanceEquip(self.m_selectedEquipInstId, self.m_enhanceMaterialInstId, attrIndex)
        end,
    })
end
EquipEnhanceCtrl.m_hasEnhanceCount = HL.Field(HL.Boolean) << false
EquipEnhanceCtrl._RefreshEnhanceCount = HL.Method() << function(self)
    local hasValue
    local lastReplenishTime
    hasValue, lastReplenishTime = GameInstance.player.globalVar:TryGetServerVar(GEnums.ServerGameVarEnum.ServerGameVarEnhanceBeanLastReplenishTime)
    local isOnCD = hasValue and DateTimeUtils.GetCurrentTimestampBySeconds() - lastReplenishTime < Tables.equipConst.enhanceBeanReplenishDuration * 60
    local enhanceBeanCount = 0
    hasValue, enhanceBeanCount = GameInstance.player.globalVar:TryGetServerVar(GEnums.ServerGameVarEnum.ServerGameVarEnhanceBean)
    local maxEnhanceBeanCount = Tables.equipConst.enhanceBeanStorageLimit
    local isShowCD = isOnCD and enhanceBeanCount < maxEnhanceBeanCount
    self.view.topNode.countDownText.gameObject:SetActive(isShowCD)
    if isShowCD then
        local targetTime = lastReplenishTime + Tables.equipConst.enhanceBeanReplenishDuration * 60
        self.view.topNode.countDownText:InitCountDownText(targetTime, function()
            self:_RefreshEnhanceCount()
        end, UIUtils.getLeftTimeToSecondFull)
    end
    self.m_hasEnhanceCount = enhanceBeanCount > 0
    self.view.topNode.txtCount.text = string.format("%d/%d", enhanceBeanCount, maxEnhanceBeanCount)
    self.view.topNode.txtCount.color = self.m_hasEnhanceCount and self.view.config.ENHANCE_COUNT_COLOR or self.view.config.NONE_ENHANCE_COUNT_COLOR
end
HL.Commit(EquipEnhanceCtrl)