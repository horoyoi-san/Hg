local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.SquadIcon
SquadIconCtrl = HL.Class('SquadIconCtrl', uiCtrl.UICtrl)
SquadIconCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_BATTLE_SQUAD_CHANGED] = '_OnTeamChange', [MessageConst.ON_SQUAD_HP_CHANGE] = '_OnHpChange', [MessageConst.ON_BATTLE_CENTER_CHANGE] = '_OnBattleCenterChange', [MessageConst.ON_CHAR_LEVEL_UP] = '_OnLevelChange', [MessageConst.ON_CHARACTER_DEAD] = '_OnCharacterDead', [MessageConst.ON_CONTROLLER_INDICATOR_CHANGE] = 'OnToggleControllerIndicator', [MessageConst.ON_SQUAD_TACTICAL_ITEM_CHANGE] = '_OnSquadTacticalItemChange', [MessageConst.ON_MANUAL_CRAFT_ITEM_LEVEL_UP] = "_OnManualCraftItemLevelUp", [MessageConst.ON_FADE_HUD] = 'OnFadeHUD', [MessageConst.ON_SQUAD_INFIGHT_CHANGED] = 'OnInFightChanged', [MessageConst.ON_SYSTEM_UNLOCK] = 'OnSystemUnlock', }
SquadIconCtrl.m_listItems = HL.Field(HL.Table)
SquadIconCtrl.m_pressSlotIndex = HL.Field(HL.Number) << -1
SquadIconCtrl.m_indicatorShowing = HL.Field(HL.Boolean) << false
SquadIconCtrl.m_teamSwitchUnlocked = HL.Field(HL.Boolean) << false
SquadIconCtrl.m_hudFadeTween = HL.Field(HL.Userdata)
SquadIconCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_listItems = {}
    if self.isControllerPanel then
        for i = 1, Const.BATTLE_SQUAD_MAX_CHAR_NUM do
            self.m_listItems[i] = self.view["squadIcon" .. i]
        end
    else
        self.m_listItems[1] = self.view.squadIcon
        for i = 2, Const.BATTLE_SQUAD_MAX_CHAR_NUM do
            local obj = CSUtils.CreateObject(self.view.squadIcon.gameObject, self.view.squadIcon.gameObject.transform.parent)
            local cell = obj:GetComponent("SquadIcon")
            self.m_listItems[i] = cell
        end
    end
    self.view.nextBtn.onPressStart:AddListener(function(eventData)
        self:_OnNextBtnClick()
    end)
    self.m_teamSwitchUnlocked = Utils.isSystemUnlocked(GEnums.UnlockSystemType.TeamSwitch)
    self:OnToggleControllerIndicator(false)
    if self.isControllerPanel then
        self.view.activateHint.gameObject:SetActiveIfNecessary(true)
    else
        self.view.activateHint.gameObject:SetActiveIfNecessary(false)
    end
end
SquadIconCtrl.OnShow = HL.Override() << function(self)
    self:_OnTeamChange()
end
SquadIconCtrl.OnClose = HL.Override() << function(self)
    if self.m_hudFadeTween then
        self.m_hudFadeTween:Kill()
    end
end
SquadIconCtrl._GetCount = HL.Method().Return(HL.Number) << function(self)
    local count = 0
    for _, item in ipairs(self.m_listItems) do
        if not item.isEmpty then
            count = count + 1
        end
    end
    return count
end
SquadIconCtrl._GetItem = HL.Method(HL.Number).Return(HL.Any) << function(self, index)
    return self.m_listItems[index]
end
SquadIconCtrl._OnTeamChange = HL.Method(HL.Opt(HL.Any)) << function(self, arg)
    local squadSlots = GameInstance.player.squadManager.curSquad.slots
    local curDungeonId = GameInstance.dungeonManager.curDungeonId
    hasValue, subGameData = DataManager.subGameInstDataTable:TryGetValue(curDungeonId)
    formationData = nil
    if hasValue and not string.isEmpty(subGameData.teamConfigId) then
        formationData = CharInfoUtils.getLockedFormationData(subGameData.teamConfigId, false)
    end
    for i = 1, squadSlots.Count do
        local showFixed, showTrial = false, false
        if formationData ~= nil and formationData.chars ~= nil then
            local charInfo = CharInfoUtils.getPlayerCharInfoByInstId(squadSlots[CSIndex(i)].charInstId)
            if charInfo.charType == GEnums.CharType.Trial then
                for j = 1, #formationData.chars do
                    if formationData.chars[j].charId == charInfo.templateId then
                        showFixed, showTrial = CharInfoUtils.getLockedFormationCharTipsShow(formationData.chars[j])
                        break
                    end
                end
            end
        end
        local item = self.m_listItems[i]
        if item ~= nil then
            item:InitSquadIcon(CSIndex(i), showFixed, showTrial)
            item:SetEmpty(false)
        end
    end
    for i = squadSlots.Count + 1, Const.BATTLE_SQUAD_MAX_CHAR_NUM do
        local item = self.m_listItems[i]
        item:SetEmpty(true)
    end
    if squadSlots.Count > 1 and self.m_teamSwitchUnlocked then
        self.view.nextBtn.gameObject:SetActiveIfNecessary(true)
    else
        self.view.nextBtn.gameObject:SetActiveIfNecessary(false)
    end
end
SquadIconCtrl._OnHpChange = HL.Method(HL.Table) << function(self, args)
    local index, change = unpack(args)
    local luaIndex = LuaIndex(index)
    local item = self:_GetItem(luaIndex)
    if item ~= nil then
        item:OnHpChange(change)
    end
end
SquadIconCtrl._OnBattleCenterChange = HL.Method() << function(self)
    local count = self:_GetCount()
    if count > 0 then
        for i = 1, count do
            local item = self:_GetItem(i)
            item:OnBattleCenterChange()
        end
    end
end
SquadIconCtrl._OnLevelChange = HL.Method(HL.Table) << function(self, args)
    local instId, _ = unpack(args)
    local squadSlots = GameInstance.player.squadManager.curSquad.slots
    for i = 1, squadSlots.Count do
        local item = self.m_listItems[i]
        local csIndex = CSIndex(i)
        if squadSlots[csIndex].charInstId == instId then
            item:OnLevelChange()
        end
    end
end
SquadIconCtrl._OnCharacterDead = HL.Method(HL.Table) << function(self, args)
    local luaIndex = LuaIndex(unpack(args))
    local item = self:_GetItem(luaIndex)
    if item ~= nil then
        item:SetDeadState(true)
    end
end
SquadIconCtrl.SendGuideData = HL.Method(HL.Table) << function(self, args)
end
SquadIconCtrl._OnPanelInputBlocked = HL.Override(HL.Boolean) << function(self, active)
end
SquadIconCtrl.OnToggleControllerIndicator = HL.Method(HL.Boolean) << function(self, active)
    if self.isControllerPanel then
        if active and not self:IsShow() then
            return
        end
        self.m_indicatorShowing = active
        local count = self:_GetCount()
        if count > 0 then
            for i = 1, count do
                local item = self:_GetItem(i)
                item:ToggleIndicator(active)
            end
        end
    end
end
SquadIconCtrl._OnSquadTacticalItemChange = HL.Method(HL.Table) << function(self, args)
    local index, itemId = unpack(args)
    local luaIndex = LuaIndex(index)
    local item = self:_GetItem(luaIndex)
    if item ~= nil then
        item:OnTacticalItemChange()
    end
end
SquadIconCtrl._OnManualCraftItemLevelUp = HL.Method(HL.Table) << function(self, args)
    local items = unpack(args)
    for i = 0, items.Count - 1 do
        local itemId = items[i]
        local squadSlots = GameInstance.player.squadManager.curSquad.slots
        for j = 1, squadSlots.Count do
            local squadSlot = squadSlots[CSIndex(j)]
            local charInfo = CharInfoUtils.getPlayerCharInfoByInstId(squadSlot.charInstId)
            if charInfo.tacticalItemId == itemId then
                local squadIcon = self:_GetItem(j)
                if squadIcon ~= nil then
                    squadIcon:OnTacticalItemChange()
                end
            end
        end
    end
end
SquadIconCtrl.OnFadeHUD = HL.Method(HL.Boolean) << function(self, inFade)
    if not self.isPCPanel then
        return
    end
    if self.m_hudFadeTween then
        self.m_hudFadeTween:Kill()
    end
    if inFade then
        self.m_hudFadeTween = self.view.canvasGroup:DOFade(0, DataManager.gameplayMiscSetting.hudFadeDuration)
    else
        self.m_hudFadeTween = self.view.canvasGroup:DOFade(1, DataManager.gameplayMiscSetting.hudFadeDuration)
    end
end
SquadIconCtrl.OnInFightChanged = HL.Method(HL.Table) << function(self, args)
    local inFight = args[1]
    local count = self:_GetCount()
    if count > 0 then
        for i = 1, count do
            local item = self:_GetItem(i)
            item:OnInFightChanged(inFight)
        end
    end
end
SquadIconCtrl.OnSystemUnlock = HL.Method(HL.Any) << function(self, arg)
    local systemIndex = unpack(arg)
    if systemIndex == GEnums.UnlockSystemType.TeamSwitch:GetHashCode() then
        local count = self:_GetCount()
        if count > 0 then
            for i = 1, count do
                local item = self:_GetItem(i)
                item:OnTeamSwitchUnlocked()
            end
        end
        self.m_teamSwitchUnlocked = true
        if count > 1 and self.m_teamSwitchUnlocked then
            self.view.nextBtn.gameObject:SetActiveIfNecessary(true)
        else
            self.view.nextBtn.gameObject:SetActiveIfNecessary(false)
        end
    end
end
SquadIconCtrl._OnNextBtnClick = HL.Method() << function(self)
    local curIndex = LuaIndex(GameInstance.player.squadManager.leaderIndex)
    local count = self:_GetCount()
    for i = 1, count do
        local nextIndex = curIndex + i
        if nextIndex > count then
            nextIndex = nextIndex - count
        end
        local item = self:_GetItem(nextIndex)
        if item:CanSwitchToCenter(false) then
            item:OnPressCharIconStart(nil)
            break
        end
    end
end
HL.Commit(SquadIconCtrl)