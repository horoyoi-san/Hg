local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RpgDungeonMainHud
RpgDungeonMainHudCtrl = HL.Class('RpgDungeonMainHudCtrl', uiCtrl.UICtrl)
RpgDungeonMainHudCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_START_RPG_DUNGEON_COUNTDOWN] = 'OnStartRpgDungeonCountdown', [MessageConst.ON_RPG_EQUIP_COLUMN_CHANGE] = 'OnRpgDungeonEquipChange', [MessageConst.ON_TEAM_EXP_CHANGE] = 'OnTeamExpChange', [MessageConst.ON_FINISH_PICK_ABILITY] = 'OnFinishPickAbility' }
RpgDungeonMainHudCtrl.m_rpgDungeonUpdateTickKey = HL.Field(HL.Number) << -1
RpgDungeonMainHudCtrl.m_equipItemCellData = HL.Field(HL.Table)
RpgDungeonMainHudCtrl.m_equipItemCellCache = HL.Field(HL.Forward('UIListCache'))
RpgDungeonMainHudCtrl.m_pickBuffCellCache = HL.Field(HL.Forward('UIListCache'))
RpgDungeonMainHudCtrl.m_pickBuffCellDetailsCache = HL.Field(HL.Forward('UIListCache'))
RpgDungeonMainHudCtrl.m_pickedBuffLevel2CountdownId = HL.Field(HL.Table)
RpgDungeonMainHudCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_equipItemCellCache = UIUtils.genCellCache(self.view.equipItem)
    self.m_pickBuffCellCache = UIUtils.genCellCache(self.view.rpgDungeonBuffIcon)
    self.m_pickBuffCellDetailsCache = UIUtils.genCellCache(self.view.rpgDungeonBuffCell)
    self.view.expandBtn.onClick:AddListener(function()
        self.view.expandLayout.gameObject:SetActive(true)
        self.view.defaultLayout.gameObject:SetActive(false)
    end)
    self.view.rpgTpBtn.onClick:AddListener(function()
        local cfg = GameInstance.world.curLevel.config
        GameAction.TeleportTeam(cfg.playerInitPos, cfg.playerInitRot)
    end)
    self.view.itemBagBtn.onClick:AddListener(function()
        PhaseManager:OpenPhase(PhaseId.Inventory)
    end)
    self.view.walletBarPlaceholder:InitWalletBarPlaceholder({ UIConst.RPG_DUNGEON_GOLD_ID })
    self.m_pickedBuffLevel2CountdownId = {}
    self:_RefreshExp()
    self:_RefreshBuff()
    self:_RefreshEquipItems()
end
RpgDungeonMainHudCtrl.OnClose = HL.Override() << function(self)
    if self.m_rpgDungeonUpdateTickKey > 0 then
        LuaUpdate:Remove(self.m_rpgDungeonUpdateTickKey)
    end
end
RpgDungeonMainHudCtrl.OnStartRpgDungeonCountdown = HL.Method(HL.Any) << function(self, arg)
    local msg, countdownId = unpack(arg)
    local countdownMgr = GameInstance.player.countdownManager
    if self.m_rpgDungeonUpdateTickKey > 0 then
        LuaUpdate:Remove(self.m_rpgDungeonUpdateTickKey)
    end
    self.m_rpgDungeonUpdateTickKey = LuaUpdate:Add("Tick", function()
        local left = countdownMgr:GetCountdown(countdownId)
        self.view.countdownTxt.text = string.format(msg, math.ceil(left))
    end)
end
RpgDungeonMainHudCtrl.OnRpgDungeonEquipChange = HL.Method() << function(self)
    self:_RefreshEquipItems()
end
RpgDungeonMainHudCtrl._RefreshEquipItems = HL.Method() << function(self)
    local equipList = GameInstance.player.rpgDungeonSystem.equippedInstList
    local equipInstIds = {}
    for i = 0, equipList.Count - 1 do
        if equipList[i] > 0 then
            table.insert(equipInstIds, equipList[i])
        end
    end
    self.m_equipItemCellCache:Refresh(#equipInstIds, function(cell, luaIndex)
        local succ, itemBundle = GameInstance.player.inventory:TryGetInstItem(Utils.getCurrentScope(), equipInstIds[luaIndex])
        if not succ then
            logger.error("No Equipped Item", instId)
            return
        end
        cell:InitItem(itemBundle)
    end)
end
RpgDungeonMainHudCtrl._RefreshExp = HL.Method(HL.Opt(HL.Table)) << function(self, args)
    args = args or {}
    local curTeamLevel, curTeamExp, nextLevelExp = unpack(args)
    if nextLevelExp then
        if nextLevelExp == 0 then
            nextLevelExp = curTeamExp
        end
    else
        local rpgMgr = GameInstance.player.rpgDungeonSystem
        curTeamLevel = rpgMgr.curTeamLevel
        curTeamExp = rpgMgr.curExp
        local succ, expTbl = Tables.RpgDungeonTeamLevelTable:TryGetValue(curTeamLevel + 1)
        nextLevelExp = succ and expTbl.exp or 0
    end
    self.view.expProgressBarFill.fillAmount = curTeamExp / nextLevelExp
    self.view.expTxt.text = string.format(Language.LUA_RPG_DUNGEON_CURRENT_LEVEL_FORMAT, curTeamLevel, curTeamExp, nextLevelExp)
end
RpgDungeonMainHudCtrl.OnTeamExpChange = HL.Method(HL.Table) << function(self, args)
    self:_RefreshExp(args)
end
RpgDungeonMainHudCtrl.OnFinishPickAbility = HL.Method() << function(self)
    self:_RefreshBuff()
end
RpgDungeonMainHudCtrl._RefreshBuff = HL.Method() << function(self)
    local totalPickedAbility = GameInstance.player.rpgDungeonSystem.totalPickedAbility
    local pickBuffData = {}
    for level, abilityId in pairs(totalPickedAbility) do
        local succ, ability = Tables.rpgLevelUpAbilityInfoTable:TryGetValue(abilityId)
        if succ then
            table.insert(pickBuffData, { buffId = abilityId, buffOwnLevel = level, buffName = ability.levelUpAbilityName, buffDesc = ability.desc, buffCountdown = ability.showDuration })
        end
    end
    local partPickBuffData = {}
    for i = 1, math.min(#pickBuffData, 3) do
        table.insert(partPickBuffData, pickBuffData[i])
    end
    self.m_pickBuffCellCache:Refresh(#partPickBuffData, function(cell, index)
        cell:InitRpgDungeonBuffIcon(partPickBuffData[index], self)
    end)
    self.m_pickBuffCellDetailsCache:Refresh(#pickBuffData, function(cell, index)
        cell:InitRpgDungeonBuffCells(pickBuffData[index], self)
    end)
end
RpgDungeonMainHudCtrl.GetBuffCountdownIdByLevel = HL.Method(HL.Number).Return(HL.Opt(HL.Number)) << function(self, level)
    return self.m_pickedBuffLevel2CountdownId[level]
end
RpgDungeonMainHudCtrl.AddBuffCountdownId = HL.Method(HL.Number, HL.Number) << function(self, level, countdownId)
    self.m_pickedBuffLevel2CountdownId[level] = countdownId
end
HL.Commit(RpgDungeonMainHudCtrl)