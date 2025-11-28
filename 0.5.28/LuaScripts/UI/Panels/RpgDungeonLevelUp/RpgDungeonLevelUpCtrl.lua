local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.RpgDungeonLevelUp
RpgDungeonLevelUpCtrl = HL.Class('RpgDungeonLevelUpCtrl', uiCtrl.UICtrl)
RpgDungeonLevelUpCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_FINISH_PICK_ABILITY] = 'OnFinishPickAbility' }
RpgDungeonLevelUpCtrl.m_getAbilityCell = HL.Field(HL.Function)
RpgDungeonLevelUpCtrl.m_abilityData = HL.Field(HL.Table)
RpgDungeonLevelUpCtrl.m_lvUpLevel = HL.Field(HL.Number) << -1
RpgDungeonLevelUpCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_getAbilityCell = UIUtils.genCachedCellFunction(self.view.abilityList)
    self.view.abilityList.onUpdateCell:AddListener(function(obj, csIndex)
        self:_OnUpdateCell(self.m_getAbilityCell(obj), LuaIndex(csIndex))
    end)
    self.view.skipBtn.onClick:AddListener(function()
        self:Close()
    end)
    local lvUpLevel, fixedAbility, randomAbility = unpack(arg)
    self.m_lvUpLevel = lvUpLevel
    self:_ProcessLevelAbilityData(randomAbility)
    self:_RefreshAbilityList()
end
RpgDungeonLevelUpCtrl.OnTeamLevelUp = HL.StaticMethod(HL.Table) << function(args)
    UIManager:AutoOpen(PANEL_ID, args)
end
RpgDungeonLevelUpCtrl._RefreshAbilityList = HL.Method() << function(self)
    self.view.abilityList:UpdateCount(#self.m_abilityData)
    self.view.skipBtn.gameObject:SetActive(#self.m_abilityData == 0)
end
RpgDungeonLevelUpCtrl._ProcessLevelAbilityData = HL.Method(HL.Any) << function(self, randomAbility)
    self.m_abilityData = {}
    for i = 0, randomAbility.Count - 1 do
        local succ, ability = Tables.rpgLevelUpAbilityInfoTable:TryGetValue(randomAbility[i])
        if succ then
            local abilityData = {}
            abilityData.id = ability.levelUpAbilityId
            abilityData.name = ability.levelUpAbilityName
            abilityData.desc = ability.desc
            table.insert(self.m_abilityData, abilityData)
        end
    end
end
RpgDungeonLevelUpCtrl._OnUpdateCell = HL.Method(HL.Any, HL.Number) << function(self, cell, index)
    local ability = self.m_abilityData[index]
    cell.title.text = UIUtils.resolveTextStyle(ability.name)
    cell.description.text = UIUtils.resolveTextStyle(ability.desc)
    cell.btnSelect.onClick:RemoveAllListeners()
    cell.btnSelect.onClick:AddListener(function()
        GameInstance.player.rpgDungeonSystem:PickLvAbility(self.m_lvUpLevel, ability.id)
    end)
end
RpgDungeonLevelUpCtrl.OnFinishPickAbility = HL.Method() << function(self)
    self:Close()
end
HL.Commit(RpgDungeonLevelUpCtrl)