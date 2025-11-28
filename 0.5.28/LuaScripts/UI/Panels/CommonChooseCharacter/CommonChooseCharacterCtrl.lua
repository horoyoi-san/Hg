local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.CommonChooseCharacter
CommonChooseCharacterCtrl = HL.Class('CommonChooseCharacterCtrl', uiCtrl.UICtrl)
CommonChooseCharacterCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_USE_ITEM] = 'OnUseItem', }
CommonChooseCharacterCtrl.m_itemId = HL.Field(HL.String) << ""
CommonChooseCharacterCtrl.m_useItemTargets = HL.Field(HL.Forward('UIListCache'))
CommonChooseCharacterCtrl.m_curIndex = HL.Field(HL.Number) << 0
CommonChooseCharacterCtrl.m_playEffect = HL.Field(HL.Boolean) << false
CommonChooseCharacterCtrl.m_lateTickKey = HL.Field(HL.Number) << -1
CommonChooseCharacterCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_itemId = arg.itemId
    self.view.btnCancel.onClick:AddListener(function()
        AudioAdapter.PostEvent("au_ui_menu_item_use_close")
        self:PlayAnimationOut(UIConst.PANEL_PLAY_ANIMATION_OUT_COMPLETE_ACTION_TYPE.Close)
    end)
    self.view.btnConfirm.onClick:AddListener(function()
        self:_OnConfirm()
    end)
    self.view.btnConfirm.interactable = true
    self.m_useItemTargets = UIUtils.genCellCache(self.view.targetCell)
    local itemId = self.m_itemId
    local useItemData = Tables.useItemTable:GetValue(itemId)
    if useItemData.uiType == GEnums.ItemUseUiType.SingleHeal then
        self.m_curIndex = UIUtils.getMinHpDamagedCharIndex()
    elseif useItemData.uiType == GEnums.ItemUseUiType.AllHeal then
        self.m_curIndex = 0
    elseif useItemData.uiType == GEnums.ItemUseUiType.Revive then
        self.m_curIndex = UIUtils.getFirstNonAliveCharIndex()
        if self.m_curIndex == 0 and self.isControllerPanel then
            self.m_curIndex = 1
        end
    elseif useItemData.uiType == GEnums.ItemUseUiType.Alive then
        if useItemData.targetType == GEnums.ItemUseTargetType.Target then
            self.m_curIndex = UIUtils.getFirstAliveCharIndex()
            if self.m_curIndex == 0 and self.isControllerPanel then
                self.m_curIndex = 1
            end
        else
            self.m_curIndex = 0
        end
    end
    self.view.hintTips.text = string.format(Language.LUA_USE_ITEM_TO_TARGET, Tables.itemTable:GetValue(itemId).name)
    self:_RefreshTargetList(false)
    self:_CheckConfirmBtn()
    self:_StartCoroutine(function()
        while true do
            self:_RefreshTargetList(false)
            self:_CheckConfirmBtn()
            coroutine.wait(0.1)
        end
    end)
    if self.isControllerPanel then
        self:BindInputPlayerAction("common_navigation_left", function()
            self:_ChangeTarget(-1)
        end)
        self:BindInputPlayerAction("common_navigation_right", function()
            self:_ChangeTarget(1)
        end)
        self.view.controllerHintPlaceholder:InitControllerHintPlaceholder({ self.view.inputGroup.groupId })
    end
end
CommonChooseCharacterCtrl.OnShow = HL.Override() << function(self)
    AudioAdapter.PostEvent("au_ui_menu_item_use_open")
end
CommonChooseCharacterCtrl._RefreshTargetList = HL.Method(HL.Opt(HL.Boolean)) << function(self, playEffect)
    local squadSlots = GameInstance.player.squadManager.curSquad.slots
    self.m_playEffect = playEffect
    self.m_useItemTargets:Refresh(squadSlots.Count, function(cell, index)
        self:_RefreshCell(cell, index)
    end)
    self.m_playEffect = false
end
CommonChooseCharacterCtrl._RefreshCell = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local itemId = self.m_itemId
    local squadSlots = GameInstance.player.squadManager.curSquad.slots
    local slot = squadSlots[CSIndex(index)]
    local character = slot.character:Lock()
    local charId = slot.charId
    local spriteName = UIConst.UI_CHAR_HEAD_PREFIX .. charId
    cell.icon.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD, spriteName)
    cell.iconGray.sprite = self:LoadSprite(UIConst.UI_SPRITE_CHAR_HEAD, spriteName)
    local charData = Tables.characterTable:GetValue(charId)
    cell.name.text = charData.name
    cell.button.onClick:RemoveAllListeners()
    cell.button.interactable = true
    if character and character.abilityCom.alive then
        cell.iconGray.gameObject:SetActiveIfNecessary(false)
        local maxHp = character.abilityCom.maxHp
        local hp = character.abilityCom.hp
        cell.hp.fillAmount = hp / maxHp
    else
        cell.iconGray.gameObject:SetActiveIfNecessary(true)
        cell.hp.fillAmount = 0
    end
    local useItemData = Tables.useItemTable:GetValue(itemId)
    if useItemData.uiType == GEnums.ItemUseUiType.SingleHeal then
        cell.selected.gameObject:SetActiveIfNecessary(index == self.m_curIndex)
        if index == self.m_curIndex and character and character.abilityCom.alive then
            local maxHp = character.abilityCom.maxHp
            local hp = character.abilityCom.hp
            local value = GameInstance.player.inventory:GetHealValue(itemId, character.abilityCom) * character.abilityCom.healTakenScalar
            cell.hpHeal.fillAmount = (hp + value) / maxHp
        else
            cell.hpHeal.fillAmount = 0
        end
        cell.button.onClick:AddListener(function()
            self:_ClickCharForSingleHeal(cell, index)
        end)
        if index == self.m_curIndex and character and character.abilityCom.alive and self.m_playEffect then
            cell.hpEffectRecover.gameObject:SetActiveIfNecessary(true)
            cell.hpEffectRecover:PlayInAnimation(function()
                cell.hpEffectRecover.gameObject:SetActiveIfNecessary(false)
            end)
        end
    elseif useItemData.uiType == GEnums.ItemUseUiType.AllHeal then
        cell.selected.gameObject:SetActiveIfNecessary(true)
        if character and character.abilityCom.alive then
            local maxHp = character.abilityCom.maxHp
            local hp = character.abilityCom.hp
            local value = GameInstance.player.inventory:GetHealValue(itemId, character.abilityCom) * character.abilityCom.healTakenScalar
            cell.hpHeal.fillAmount = (hp + value) / maxHp
        else
            cell.hpHeal.fillAmount = 0
        end
        cell.button.interactable = false
        if character and character.abilityCom.alive and self.m_playEffect then
            cell.hpEffectRecover.gameObject:SetActiveIfNecessary(true)
            cell.hpEffectRecover:PlayInAnimation(function()
                cell.hpEffectRecover.gameObject:SetActiveIfNecessary(false)
            end)
        end
    elseif useItemData.uiType == GEnums.ItemUseUiType.Revive then
        cell.selected.gameObject:SetActiveIfNecessary(index == self.m_curIndex)
        cell.button.onClick:AddListener(function()
            self:_ClickCharForRevive(cell, index)
        end)
        if character and character.abilityCom.alive then
            local maxHp = character.abilityCom.maxHp
            local hp = character.abilityCom.hp
            cell.hpHeal.fillAmount = hp / maxHp
        else
            cell.hpHeal.fillAmount = 0
        end
        if index == self.m_curIndex and character and character.abilityCom.alive and self.m_playEffect then
            cell.hpEffectRecover.gameObject:SetActiveIfNecessary(true)
            cell.hpEffectRecover:PlayInAnimation(function()
                cell.hpEffectRecover.gameObject:SetActiveIfNecessary(false)
            end)
        end
    elseif useItemData.uiType == GEnums.ItemUseUiType.Alive then
        if useItemData.targetType == GEnums.ItemUseTargetType.Target then
            cell.selected.gameObject:SetActiveIfNecessary(index == self.m_curIndex)
            cell.button.onClick:AddListener(function()
                self:_ClickCharForAlive(cell, index)
            end)
            if character and character.abilityCom.alive then
                local maxHp = character.abilityCom.maxHp
                local hp = character.abilityCom.hp
                cell.hpHeal.fillAmount = hp / maxHp
            else
                cell.hpHeal.fillAmount = 0
            end
        else
            cell.button.interactable = false
            if character and character.abilityCom.alive then
                cell.selected.gameObject:SetActiveIfNecessary(true)
                local maxHp = character.abilityCom.maxHp
                local hp = character.abilityCom.hp
                cell.hpHeal.fillAmount = hp / maxHp
            else
                cell.selected.gameObject:SetActiveIfNecessary(false)
                cell.hpHeal.fillAmount = 0
            end
        end
    end
end
CommonChooseCharacterCtrl._ChangeTarget = HL.Method(HL.Number) << function(self, delta)
    local itemId = self.m_itemId
    local useItemData = Tables.useItemTable:GetValue(itemId)
    if useItemData.uiType == GEnums.ItemUseUiType.AllHeal or useItemData.targetType ~= GEnums.ItemUseTargetType.Target then
        return
    end
    local squadSlots = GameInstance.player.squadManager.curSquad.slots
    local index = self.m_curIndex
    local count = squadSlots.Count
    if count <= 1 then
        return
    end
    local newIndex = index + delta
    if newIndex == 0 then
        newIndex = count
    elseif newIndex > count then
        newIndex = 1
    end
    local cell = self.m_useItemTargets:GetItem(newIndex)
    cell.button.onClick:Invoke()
    AudioAdapter.PostEvent("au_ui_hover_char")
end
CommonChooseCharacterCtrl._ClickCharForSingleHeal = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local squadSlots = GameInstance.player.squadManager.curSquad.slots
    local slot = squadSlots[CSIndex(index)]
    local character = slot.character:Lock()
    if not self.isControllerPanel then
        if not (character and character.abilityCom.alive) then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_USE_ITEM_ALIVE_TO_DEAD_CHARACTER)
            return
        end
        if character.abilityCom.hp >= character.abilityCom.maxHp then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_BAR_TOAST_MAX_HP)
            return
        end
    end
    local itemId = self.m_itemId
    if self.m_curIndex > 0 then
        local lastCell = self.m_useItemTargets:GetItem(self.m_curIndex)
        lastCell.selected.gameObject:SetActiveIfNecessary(false)
        lastCell.hpHeal.fillAmount = 0
    end
    self.m_curIndex = index
    cell.selected.gameObject:SetActiveIfNecessary(true)
    if character and character.abilityCom.alive then
        local maxHp = character.abilityCom.maxHp
        local hp = character.abilityCom.hp
        local value = GameInstance.player.inventory:GetHealValue(itemId, character.abilityCom) * character.abilityCom.healTakenScalar
        cell.hpHeal.fillAmount = (hp + value) / maxHp
    end
    self:_CheckConfirmBtn()
end
CommonChooseCharacterCtrl._ClickCharForRevive = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local squadSlots = GameInstance.player.squadManager.curSquad.slots
    local slot = squadSlots[CSIndex(index)]
    local character = slot.character:Lock()
    if not self.isControllerPanel then
        if character and character.abilityCom.alive then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_USE_ITEM_REVIVE_TO_ALIVE_CHARACTER)
            return
        end
    end
    if self.m_curIndex > 0 then
        local lastCell = self.m_useItemTargets:GetItem(self.m_curIndex)
        lastCell.selected.gameObject:SetActiveIfNecessary(false)
    end
    self.m_curIndex = index
    cell.selected.gameObject:SetActiveIfNecessary(true)
    self:_CheckConfirmBtn()
end
CommonChooseCharacterCtrl._ClickCharForAlive = HL.Method(HL.Table, HL.Number) << function(self, cell, index)
    local squadSlots = GameInstance.player.squadManager.curSquad.slots
    local slot = squadSlots[CSIndex(index)]
    local character = slot.character:Lock()
    if not self.isControllerPanel then
        if not (character and character.abilityCom.alive) then
            Notify(MessageConst.SHOW_TOAST, Language.LUA_USE_ITEM_ALIVE_TO_DEAD_CHARACTER)
            return
        end
    end
    if self.m_curIndex > 0 then
        local lastCell = self.m_useItemTargets:GetItem(self.m_curIndex)
        lastCell.selected.gameObject:SetActiveIfNecessary(false)
    end
    self.m_curIndex = index
    cell.selected.gameObject:SetActiveIfNecessary(true)
    self:_CheckConfirmBtn()
end
CommonChooseCharacterCtrl._OnConfirm = HL.Method() << function(self)
    local itemId = self.m_itemId
    local useItemData = Tables.useItemTable:GetValue(itemId)
    if useItemData.uiType == GEnums.ItemUseUiType.SingleHeal then
        if self.m_curIndex == 0 then
            return
        end
        if self.isControllerPanel then
            local squadSlots = GameInstance.player.squadManager.curSquad.slots
            local slot = squadSlots[CSIndex(self.m_curIndex)]
            local character = slot.character:Lock()
            if not (character and character.abilityCom.alive) then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_USE_ITEM_ALIVE_TO_DEAD_CHARACTER)
                return
            end
            if character.abilityCom.hp >= character.abilityCom.maxHp then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_ITEM_BAR_TOAST_MAX_HP)
                return
            end
        end
        GameInstance.player.inventory:UseItem(Utils.getCurrentScope(), itemId, CSIndex(self.m_curIndex))
    elseif useItemData.uiType == GEnums.ItemUseUiType.Revive then
        if self.m_curIndex == 0 then
            return
        end
        if self.isControllerPanel then
            local squadSlots = GameInstance.player.squadManager.curSquad.slots
            local slot = squadSlots[CSIndex(self.m_curIndex)]
            local character = slot.character:Lock()
            if character and character.abilityCom.alive then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_USE_ITEM_REVIVE_TO_ALIVE_CHARACTER)
                return
            end
        end
        GameInstance.player.inventory:UseItem(Utils.getCurrentScope(), itemId, CSIndex(self.m_curIndex))
    elseif useItemData.uiType == GEnums.ItemUseUiType.AllHeal then
        GameInstance.player.inventory:UseItem(Utils.getCurrentScope(), itemId)
    elseif useItemData.uiType == GEnums.ItemUseUiType.Alive then
        if useItemData.targetType == GEnums.ItemUseTargetType.Target then
            if self.m_curIndex == 0 then
                return
            end
            if self.isControllerPanel then
                local squadSlots = GameInstance.player.squadManager.curSquad.slots
                local slot = squadSlots[CSIndex(self.m_curIndex)]
                local character = slot.character:Lock()
                if not (character and character.abilityCom.alive) then
                    Notify(MessageConst.SHOW_TOAST, Language.LUA_USE_ITEM_ALIVE_TO_DEAD_CHARACTER)
                    return
                end
            end
            GameInstance.player.inventory:UseItem(Utils.getCurrentScope(), itemId, CSIndex(self.m_curIndex))
        else
            GameInstance.player.inventory:UseItem(Utils.getCurrentScope(), itemId)
        end
    end
    self:_CheckConfirmBtn()
end
CommonChooseCharacterCtrl._CheckConfirmBtn = HL.Method() << function(self)
    self.view.btnConfirm.interactable = true
    if self.isControllerPanel then
        return
    end
    local itemId = self.m_itemId
    local useItemData = Tables.useItemTable:GetValue(itemId)
    if useItemData.uiType == GEnums.ItemUseUiType.SingleHeal then
        if self.m_curIndex == 0 then
            self.view.btnConfirm.interactable = false
            return
        end
        local squadSlots = GameInstance.player.squadManager.curSquad.slots
        local slot = squadSlots[CSIndex(self.m_curIndex)]
        local character = slot.character:Lock()
        if not (character and character.abilityCom.alive) then
            self.view.btnConfirm.interactable = false
            return
        end
        if character.abilityCom.hp >= character.abilityCom.maxHp then
            self.view.btnConfirm.interactable = false
            return
        end
    elseif useItemData.uiType == GEnums.ItemUseUiType.AllHeal then
        local _, minRatio = UIUtils.getMinHpDamagedCharIndex()
        if minRatio >= 1 then
            self.view.btnConfirm.interactable = false
            return
        end
    elseif useItemData.uiType == GEnums.ItemUseUiType.Revive then
        if self.m_curIndex == 0 then
            self.view.btnConfirm.interactable = false
            return
        end
        local squadSlots = GameInstance.player.squadManager.curSquad.slots
        local slot = squadSlots[CSIndex(self.m_curIndex)]
        local character = slot.character:Lock()
        if character and character.abilityCom.alive then
            self.view.btnConfirm.interactable = false
            return
        end
    elseif useItemData.uiType == GEnums.ItemUseUiType.Alive then
        if useItemData.targetType == GEnums.ItemUseTargetType.Target then
            if self.m_curIndex == 0 then
                self.view.btnConfirm.interactable = false
                return
            end
            local squadSlots = GameInstance.player.squadManager.curSquad.slots
            local slot = squadSlots[CSIndex(self.m_curIndex)]
            local character = slot.character:Lock()
            if not (character and character.abilityCom.alive) then
                self.view.btnConfirm.interactable = false
                return
            end
        else
            self.view.btnConfirm.interactable = true
        end
    end
end
CommonChooseCharacterCtrl.OnUseItem = HL.Method(HL.Any) << function(self)
    local itemId = self.m_itemId
    local useItemData = Tables.useItemTable:GetValue(itemId)
    if useItemData.uiType == GEnums.ItemUseUiType.SingleHeal or useItemData.uiType == GEnums.ItemUseUiType.AllHeal or useItemData.uiType == GEnums.ItemUseUiType.Revive then
        self:_RefreshTargetList(true)
    else
        self:_RefreshTargetList(false)
    end
    if GameInstance.player.inventory:GetItemCd(itemId) > 0 then
        self:Close()
        return
    end
    if useItemData.exitUiIfNoCd then
        self:Close()
        return
    end
    self:_CheckConfirmBtn()
end
HL.Commit(CommonChooseCharacterCtrl)