local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.TacticalItem
TacticalItemCtrl = HL.Class('TacticalItemCtrl', uiCtrl.UICtrl)
TacticalItemCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_USE_ITEM] = 'OnUseItem', [MessageConst.ON_ITEM_COUNT_CHANGED] = 'OnItemCountChanged', }
TacticalItemCtrl.m_charCellCache = HL.Field(HL.Forward("UIListCache"))
TacticalItemCtrl.m_selectCharInstIdDict = HL.Field(HL.Table)
TacticalItemCtrl.m_curItemId = HL.Field(HL.String) << ""
local USE_ITEM_CFG = { [GEnums.ItemUseUiType.SingleHeal] = { getMemberFunc = "_GetAllAliveMember", selectDefaultFunc = "_SelectLowestHpRate", refreshCellFunc = "_RefreshCharCellWithHp", onClick = "_OnClickSingleSelect", onConfirm = "UseItemOnTarget", afterUseCheckFunc = "_AfterUseCheckDefault", }, [GEnums.ItemUseUiType.Revive] = { getMemberFunc = "_GetAllDeadMember", selectDefaultFunc = "_SelectFirstOne", refreshCellFunc = "_RefreshCharCellDefault", onClick = "_OnClickSingleSelect", onConfirm = "UseItemOnTarget", afterUseCheckFunc = "_AfterUseCheckRevive", }, [GEnums.ItemUseUiType.AllHeal] = { getMemberFunc = "_GetAllAliveMember", selectDefaultFunc = "_SelectAll", refreshCellFunc = "_RefreshCharCellWithHp", onConfirm = "UseItem", afterUseCheckFunc = "_AfterUseCheckDefault", }, [GEnums.ItemUseUiType.Alive] = { getMemberFunc = "_GetAllAliveMember", selectDefaultFunc = "_SelectAliveDependOnTargetNumType", refreshCellFunc = "_RefreshCharCellDefault", isSingleSelect = true, onClick = "_OnClickSingleSelect", onConfirm = "UseItemOnTarget", afterUseCheckFunc = "_AfterUseCheckDefault", } }
TacticalItemCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    local itemId = arg.itemId
    self.m_curItemId = itemId
    self:_InitActionEvent()
    self:_RefreshTacticalPanel(itemId)
end
TacticalItemCtrl.OnUseItem = HL.Method(HL.Opt(HL.Any)) << function(self, arg)
    local itemId = self.m_curItemId
    local useItemCfg = Tables.useItemTable:GetValue(itemId)
    local cfg = USE_ITEM_CFG[useItemCfg.uiType]
    if cfg.afterUseCheckFunc then
        self[cfg.afterUseCheckFunc](self, itemId, true)
    end
end
TacticalItemCtrl.OnItemCountChanged = HL.Method(HL.Any) << function(self, args)
    local itemId2DiffCount = unpack(args)
    for itemId, v in pairs(itemId2DiffCount) do
        if itemId == self.m_curItemId then
            self:OnUseItem()
        end
    end
end
TacticalItemCtrl._AfterUseCheckDefault = HL.Method(HL.String, HL.Opt(HL.Boolean)) << function(self, itemId, inUseItemTransition)
    AudioAdapter.PostEvent("au_int_cure_one")
    local storageCount = Utils.getItemCount(itemId)
    if storageCount > 0 then
        self:_RefreshTacticalPanel(itemId, inUseItemTransition)
    else
        self.view.anim:PlayOutAnimation(function()
            self:Close()
        end)
    end
end
TacticalItemCtrl._AfterUseCheckRevive = HL.Method(HL.String, HL.Opt(HL.Boolean)) << function(self, itemId, inUseItemTransition)
    self.m_selectCharInstIdDict = nil
    self:_AfterUseCheckDefault(itemId)
    local deadMember = self:_GetAllDeadMember()
    if #deadMember <= 0 then
        self.view.anim:PlayOutAnimation(function()
            self:Close()
        end)
    end
end
TacticalItemCtrl.UseItem = HL.Method(HL.String, HL.Table) << function(self, itemId, selectCharInstIdDict)
    GameInstance.player.inventory:UseItem(Utils.getCurrentScope(), itemId)
end
TacticalItemCtrl.UseItemOnTarget = HL.Method(HL.String, HL.Table) << function(self, itemId, selectCharInstIdDict)
    local charInstId
    for instId, v in pairs(selectCharInstIdDict) do
        charInstId = instId
    end
    GameInstance.player.inventory:UseItemOnTarget(Utils.getCurrentScope(), itemId, charInstId)
end
TacticalItemCtrl._InitActionEvent = HL.Method() << function(self)
    self.view.cancelBtn.onClick:AddListener(function()
        self.view.anim:PlayOutAnimation(function()
            self:Close()
        end)
    end)
    self.view.emptyButton.onClick:AddListener(function()
        self.view.anim:PlayOutAnimation(function()
            self:Close()
        end)
    end)
    self.view.confirmBtn.onClick:AddListener(function()
        if Utils.isCurSquadAllDead() then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_GAME_MODE_FORBID_FACTORY_WATCH)
            return
        end
        local useItemCfg = Tables.useItemTable:GetValue(self.m_curItemId)
        local cfg = USE_ITEM_CFG[useItemCfg.uiType]
        if cfg.onConfirm then
            self[cfg.onConfirm](self, self.m_curItemId, self.m_selectCharInstIdDict)
        end
    end)
    self.m_charCellCache = UIUtils.genCellCache(self.view.charCell)
end
TacticalItemCtrl._RefreshTacticalPanel = HL.Method(HL.String, HL.Opt(HL.Boolean)) << function(self, itemId, inUseItemTransition)
    local useItemCfg = Tables.useItemTable:GetValue(itemId)
    local cfg = USE_ITEM_CFG[useItemCfg.uiType]
    local squadMembers = self[cfg.getMemberFunc](self)
    self:_RefreshItemNode(itemId)
    self:_RefreshSquadNode(squadMembers, cfg, useItemCfg, inUseItemTransition)
end
TacticalItemCtrl._RefreshItemNode = HL.Method(HL.String) << function(self, itemId)
    local itemCfg = Tables.itemTable:GetValue(itemId)
    self.view.itemBlack:InitItem({ id = itemId })
    self.view.storageCount.text = Utils.getItemCount(itemId)
    self.view.desc.text = UIUtils.resolveTextStyle(UIUtils.getItemUseDesc(itemId))
    self.view.name.text = itemCfg.name
end
TacticalItemCtrl._RefreshSquadNode = HL.Method(HL.Table, HL.Table, HL.Userdata, HL.Opt(HL.Boolean)) << function(self, squadMembers, cfg, useItemCfg, inUseItemTransition)
    local squadMemberCount = #squadMembers
    self.view.scrollRect.gameObject:SetActive(squadMemberCount > 0)
    self.view.emptyNode.gameObject:SetActive(squadMemberCount <= 0)
    if squadMemberCount > 0 then
        if self.m_selectCharInstIdDict == nil then
            self.m_selectCharInstIdDict = self[cfg.selectDefaultFunc](self, squadMembers, useItemCfg)
        end
        self.m_charCellCache:Refresh(#squadMembers, function(cell, index)
            local memberInfo = squadMembers[index]
            self[cfg.refreshCellFunc](self, cell, memberInfo, useItemCfg, inUseItemTransition == true)
            cell.charHeadCellLongHpBar.view.button.onClick:RemoveAllListeners()
            cell.charHeadCellLongHpBar.view.button.onClick:AddListener(function()
                if cfg.onClick then
                    self[cfg.onClick](self, memberInfo, index, useItemCfg)
                end
            end)
        end)
    end
end
TacticalItemCtrl._GetAllAliveMember = HL.Method().Return(HL.Table) << function(self)
    local singleHealSquadMembers = {}
    local squadSlots = GameInstance.player.squadManager.curSquad.slots
    for i = 1, 4 do
        if i <= squadSlots.Count then
            local slot = squadSlots[CSIndex(i)]
            table.insert(singleHealSquadMembers, { isEmpty = false, slot = slot, })
        else
            table.insert(singleHealSquadMembers, { isEmpty = true, })
        end
    end
    return singleHealSquadMembers
end
TacticalItemCtrl._GetAllDeadMember = HL.Method().Return(HL.Table) << function(self)
    local squadSlots = GameInstance.player.squadManager.curSquad.slots
    local deadMember = {}
    for i, slot in pairs(squadSlots) do
        local isAlive = slot.character.isValid and slot.character:Lock().abilityCom.alive
        if not isAlive then
            table.insert(deadMember, { isEmpty = false, slot = slot, })
        end
    end
    return deadMember
end
TacticalItemCtrl._RefreshCharCellDefault = HL.Method(HL.Table, HL.Table, HL.Userdata, HL.Opt(HL.Boolean)) << function(self, cell, memberInfo, useItemCfg, inUseItemTransition)
    cell.emptyState.gameObject:SetActive(memberInfo.isEmpty)
    cell.charHeadCellLongHpBar.gameObject:SetActive(not memberInfo.isEmpty)
    if not memberInfo.isEmpty then
        local slot = memberInfo.slot
        self:_RefreshHeadCellBasic(cell.charHeadCellLongHpBar, slot, useItemCfg)
        if useItemCfg.effectType == GEnums.ItemUseEffectType.Buff then
            if inUseItemTransition and self.m_selectCharInstIdDict[slot.charInstId] ~= nil then
                cell.charHeadCellLongHpBar.view.buffAnim:PlayInAnimation()
            end
        end
    end
end
TacticalItemCtrl._RefreshCharCellWithHp = HL.Method(HL.Table, HL.Table, HL.Userdata, HL.Opt(HL.Boolean)) << function(self, cell, memberInfo, useItemCfg, inUseItemTransition)
    self:_RefreshCharCellDefault(cell, memberInfo, useItemCfg, inUseItemTransition)
    if not memberInfo.isEmpty then
        local slot = memberInfo.slot
        self:_RefreshHeadCellWithHp(cell.charHeadCellLongHpBar, slot, useItemCfg, inUseItemTransition)
    end
end
TacticalItemCtrl._RefreshHeadCellBasic = HL.Method(HL.Userdata, HL.Userdata, HL.Userdata) << function(self, cell, slot, useItemCfg)
    local charInstId = slot.charInstId
    local charInst = CharInfoUtils.getPlayerCharInfoByInstId(charInstId)
    local charCfg = Tables.characterTable:GetValue(charInst.templateId)
    cell:InitCharFormationHeadCell({ instId = charInst.instId, level = charInst.level, ownTime = charInst.ownTime, rarity = charCfg.rarity, templateId = charInst.templateId, })
    local isSelected = self.m_selectCharInstIdDict[slot.charInstId] ~= nil
    cell.view.selectedBG.gameObject:SetActive(isSelected)
    local isAlive = slot.character.isValid and slot.character:Lock().abilityCom.alive
    cell.view.disableMask.gameObject:SetActive(not isAlive)
    cell.view.charHeadBar.gameObject:SetActive(false)
end
TacticalItemCtrl._RefreshHeadCellWithHp = HL.Method(HL.Userdata, HL.Userdata, HL.Userdata, HL.Opt(HL.Boolean)) << function(self, cell, slot, useItemCfg, inUseItemTransition)
    local isAlive = slot.character.isValid and slot.character:Lock().abilityCom.alive
    if not isAlive then
        return
    end
    local abilityCom = slot.character:Lock().abilityCom
    cell.view.charHeadBar.gameObject:SetActive(abilityCom.alive)
    local isSelected = self.m_selectCharInstIdDict[slot.charInstId] ~= nil
    local currentHpPct = abilityCom.hp / abilityCom.maxHp
    if isSelected and inUseItemTransition and currentHpPct - cell.view.curHpFill.fillAmount > 0.01 then
        cell.view.hpRecoverAnim:PlayInAnimation()
    end
    cell.view.curHpFill.fillAmount = currentHpPct
    cell.view.disableMask.gameObject:SetActive(not abilityCom.alive)
    local showAddHp = isSelected and abilityCom.hp < abilityCom.maxHp
    cell.view.addHpFill.gameObject:SetActive(showAddHp)
    cell.view.totalAddHpFill.gameObject:SetActive(showAddHp)
    if showAddHp then
        local value = GameInstance.player.inventory:GetHealValue(useItemCfg.itemId, abilityCom) * (1 + abilityCom.healTakenIncrease)
        local addHpChildRect = cell.view.addHpFill.transform:GetChild(0)
        local addHpRect = cell.view.addHpFill.transform
        addHpChildRect.offsetMin = Vector2(addHpRect.rect.width * currentHpPct, addHpChildRect.offsetMin.y)
        addHpChildRect.offsetMax = Vector2(addHpRect.rect.width * math.min(1, (abilityCom.hp + value) / abilityCom.maxHp), addHpChildRect.offsetMax.y)
        local totalValue = GameInstance.player.inventory:GetTotalHealValue(useItemCfg.itemId, abilityCom) * (1 + abilityCom.healTakenIncrease)
        cell.view.totalAddHpFill.fillAmount = (totalValue + abilityCom.hp) / abilityCom.maxHp
    end
end
TacticalItemCtrl._OnClickSingleSelect = HL.Method(HL.Table, HL.Number, HL.Any) << function(self, memberInfo, index, useItemCfg)
    if useItemCfg.targetNumType == GEnums.ItemUseTargetNumType.All then
        return
    end
    local slot = memberInfo.slot
    local charInstId = slot.charInstId
    self.m_selectCharInstIdDict = { [charInstId] = index }
    self:_RefreshTacticalPanel(self.m_curItemId)
end
TacticalItemCtrl._SelectLowestHpRate = HL.Method(HL.Table, HL.Opt(HL.Any)).Return(HL.Table) << function(self, squadMembers)
    local defaultSelectInstId = -1
    local defaultIndex = -1
    local minHpRate = 100
    for i = 1, #squadMembers do
        local squadMember = squadMembers[i]
        if squadMember.slot then
            if squadMember.slot.character.isValid and squadMember.slot.character:Lock().abilityCom.alive then
                local abilityCom = squadMember.slot.character:Lock().abilityCom
                if abilityCom.alive then
                    local hp = abilityCom.hp
                    local maxHp = abilityCom.maxHp
                    if not defaultSelectInstId then
                        defaultSelectInstId = squadMember.slot.charInstId
                        defaultIndex = i
                        minHpRate = hp / maxHp
                    else
                        local hpRate = hp / maxHp
                        if hpRate < minHpRate then
                            defaultSelectInstId = squadMember.slot.charInstId
                            defaultIndex = i
                            minHpRate = hpRate
                        end
                    end
                end
            end
        end
    end
    return { [defaultSelectInstId] = defaultIndex }
end
TacticalItemCtrl._SelectAll = HL.Method(HL.Table, HL.Opt(HL.Any)).Return(HL.Table) << function(self, squadMembers)
    local selectDict = {}
    for i = 1, #squadMembers do
        local squadMember = squadMembers[i]
        if squadMember.slot then
            if squadMember.slot.character.isValid then
                local abilityCom = squadMember.slot.character:Lock().abilityCom
                if abilityCom.alive then
                    selectDict[squadMember.slot.charInstId] = i
                end
            end
        end
    end
    return selectDict
end
TacticalItemCtrl._SelectFirstOne = HL.Method(HL.Table, HL.Opt(HL.Any)).Return(HL.Table) << function(self, squadMembers)
    for i = 1, #squadMembers do
        local squadMember = squadMembers[i]
        if squadMember.slot then
            return { [squadMember.slot.charInstId] = i }
        end
    end
end
TacticalItemCtrl._SelectFirstOneAlive = HL.Method(HL.Table, HL.Opt(HL.Any)).Return(HL.Table) << function(self, squadMembers)
    for i = 1, #squadMembers do
        local squadMember = squadMembers[i]
        if squadMember.slot then
            if squadMember.slot.character.isValid and squadMember.slot.character:Lock().abilityCom.alive then
                return { [squadMember.slot.charInstId] = i }
            end
        end
    end
end
TacticalItemCtrl._SelectAliveDependOnTargetNumType = HL.Method(HL.Table, HL.Opt(HL.Any)).Return(HL.Table) << function(self, squadMembers, useItemCfg)
    if useItemCfg.targetNumType == GEnums.ItemUseTargetNumType.Single then
        return self:_SelectFirstOneAlive(squadMembers)
    end
    return self:_SelectAll(squadMembers)
end
HL.Commit(TacticalItemCtrl)