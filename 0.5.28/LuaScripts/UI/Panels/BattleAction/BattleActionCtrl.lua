local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.BattleAction
local PlayerController = CS.Beyond.Gameplay.Core.PlayerController
BattleActionCtrl = HL.Class('BattleActionCtrl', uiCtrl.UICtrl)
BattleActionCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_TOGGLE_UI_ACTION] = 'OnToggleUiAction', [MessageConst.ON_BATTLE_SQUAD_CHANGED] = 'OnBattleTeamChanged', [MessageConst.ON_BATTLE_CENTER_CHANGE] = 'OnBattleCenterChange', [MessageConst.ON_CHARACTER_DEAD] = 'OnCharacterDead', [MessageConst.ON_RESET_LEVEL] = 'OnResetCharacters', [MessageConst.ON_SYSTEM_UNLOCK] = 'OnSystemUnlock', [MessageConst.ON_DEBUG_TOGGLE_SKILL_RECOVER_BUTTON] = 'OnDebugToggleSkillRecoverBtn', [MessageConst.ON_CLEAR_SKILLBTN_STATE] = 'OnClearSkillBtnState', [MessageConst.ON_SQUAD_USP_CHANGE] = '_OnUspChange', [MessageConst.CHAR_NORMAL_SKILL_CHANGE] = '_OnCharNormalSkillChange', [MessageConst.ON_SKILL_UPGRADE_SUCCESS] = '_OnSkillLevelUpgraded', [MessageConst.ON_CHAR_POTENTIAL_UNLOCK] = '_OnCharPotentialUnlock', [MessageConst.ON_CONTROLLER_INDICATOR_CHANGE] = 'OnToggleControllerSkillIndicator', [MessageConst.ON_FADE_HUD] = 'OnFadeHUD', }
do
    BattleActionCtrl.m_pressScreen = HL.Field(HL.Function)
    BattleActionCtrl.m_releaseScreen = HL.Field(HL.Function)
    BattleActionCtrl.m_onLongPress = HL.Field(HL.Function)
    BattleActionCtrl.m_toggleUIKey = HL.Field(HL.Number) << -1
    BattleActionCtrl.m_longPressScreen = HL.Field(HL.Boolean) << false
    BattleActionCtrl.m_pressTimerId = HL.Field(HL.Number) << -1
    BattleActionCtrl.m_selectedTarget = HL.Field(HL.Userdata)
    BattleActionCtrl.m_skillCellList = HL.Field(HL.Table)
    BattleActionCtrl.m_throwData = HL.Field(HL.Userdata)
    BattleActionCtrl.m_weakLockHint = HL.Field(HL.Table)
    BattleActionCtrl.m_enemyLockHint = HL.Field(HL.Table)
    BattleActionCtrl.m_characterFootBar = HL.Field(HL.Table)
    BattleActionCtrl.m_skillIndicatorShowing = HL.Field(HL.Boolean) << false
    BattleActionCtrl.m_teamSkillUnlocked = HL.Field(HL.Boolean) << false
    BattleActionCtrl.m_hudFadeTween = HL.Field(HL.Userdata)
end
BattleActionCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.aimBtn.onPressStart:AddListener(function()
        self.view.aimBtnAnim:PlayWithTween("skillbutton_aim_press")
        GameInstance.world.battle:ToggleLockTargetStart()
    end)
    self.view.aimBtn.onPressEnd:AddListener(function()
        GameInstance.world.battle:ToggleLockTargetEnd()
    end)
    self.m_skillCellList = {}
    for k = 1, Const.BATTLE_SQUAD_MAX_CHAR_NUM do
        local skillCell = self.view["skillButton" .. k]
        skillCell:BindingButtonActions(CSIndex(k))
        self.m_skillCellList[k] = skillCell
    end
    self:_InitEnemyFootBar()
    self:_InitEnemyLockHint()
    self:_InitCharacterFootBar()
    self:RefreshSkills()
    self:OnToggleControllerSkillIndicator(false)
    self.view.atbNode:OnCreate()
    local isNormalSkillUnlock = Utils.isSystemUnlocked(GEnums.UnlockSystemType.NormalSkill)
    self.view.skillNode.gameObject:SetActiveIfNecessary(isNormalSkillUnlock)
    self.view.atbNode.gameObject:SetActiveIfNecessary(isNormalSkillUnlock)
    self.m_teamSkillUnlocked = Utils.isSystemUnlocked(GEnums.UnlockSystemType.TeamSkill)
    if self.isControllerPanel then
        self.view.cancelIndicator.onClick:AddListener(function()
        end)
        self.view.bombTipsNode:InitControllerHintPlaceholder({}, { "battle_throw_mode_rotate_show_only", "battle_throw_mode_throw_show_only" })
        self.view.bombTipsNode.gameObject:SetActive(false)
    end
    if BEYOND_DEBUG_COMMAND then
        self:BindInputPlayerAction("battle_debug_refresh_skill_usp", function()
            CS.Beyond.Gameplay.Core.PlayerController.DoRefreshSkill(true)
        end)
        self:BindInputPlayerAction("battle_debug_heal_all_char", function()
            CS.Beyond.Gameplay.Core.PlayerController.HealAllCharacters()
        end)
        self:BindInputPlayerAction("battle_debug_reload_all_skill", function()
            CS.Beyond.Gameplay.Core.PlayerController.ReloadBattleAssets()
        end)
        self:BindInputPlayerAction("battle_debug_kill_all_enemies", function()
            CS.Beyond.Gameplay.Core.PlayerController.KillAllEnemies(false)
        end)
        self:BindInputPlayerAction("battle_debug_kill_all_enemies_in_fight", function()
            CS.Beyond.Gameplay.Core.PlayerController.KillAllEnemies(true)
        end)
    end
end
BattleActionCtrl.OnShow = HL.Override() << function(self)
    self:RefreshSkills()
    self.view.atbNode:CheckAtbLoopAnim()
    self:OnBattleCenterChange()
    if InputManagerInst:GetKey(CS.Beyond.Input.GamepadKeyCode.RT) then
        self:OnToggleControllerSkillIndicator(true)
    end
end
BattleActionCtrl.OnHide = HL.Override() << function(self)
    self:_ClearRegisters()
    self:ClearAllSkillBtnClick()
    self:OnToggleControllerSkillIndicator(false)
end
BattleActionCtrl.OnClose = HL.Override() << function(self)
    self:_ClearRegisters()
    self.view.atbNode:OnClose()
    for k, skillCell in ipairs(self.m_skillCellList) do
        skillCell:Close()
    end
    if self.m_weakLockHint then
        GameObject.Destroy(self.m_weakLockHint.gameObject)
    end
    self.m_weakLockHint = nil
    if self.m_enemyLockHint then
        GameObject.Destroy(self.m_enemyLockHint.gameObject)
    end
    self.m_enemyLockHint = nil
    if self.m_characterFootBar then
        GameObject.Destroy(self.m_characterFootBar.gameObject)
    end
    self.m_characterFootBar = nil
    if self.m_hudFadeTween then
        self.m_hudFadeTween:Kill()
    end
end
BattleActionCtrl._ClearRegisters = HL.Method() << function(self)
    local touchPanel = UIManager.commonTouchPanel
    if self.m_pressScreen then
        touchPanel.onPress:RemoveListener(self.m_pressScreen)
    end
    if self.m_releaseScreen then
        touchPanel.onRelease:RemoveListener(self.m_releaseScreen)
    end
end
BattleActionCtrl.OnPressSkillButton = HL.Method(HL.Table) << function(self, args)
end
do
    BattleActionCtrl._InitEnemyFootBar = HL.Method() << function(self)
        self.m_weakLockHint = Utils.wrapLuaNode(CSUtils.CreateObject(self.view.config.WEAK_LOCK_HINT, UIManager.worldObjectRoot))
    end
    BattleActionCtrl._InitEnemyLockHint = HL.Method() << function(self)
        self.m_enemyLockHint = Utils.wrapLuaNode(CSUtils.CreateObject(self.view.config.ENEMY_LOCK_HINT, UIManager.worldObjectRoot))
    end
    BattleActionCtrl._InitCharacterFootBar = HL.Method() << function(self)
        self.m_characterFootBar = Utils.wrapLuaNode(CSUtils.CreateObject(self.view.config.CHARACTER_FOOT_BAR, UIManager.worldObjectRoot))
    end
end
do
    BattleActionCtrl.OnBattleTeamChanged = HL.Method() << function(self)
        self:RefreshSkills()
        self:OnBattleCenterChange()
    end
    BattleActionCtrl.OnBattleCenterChange = HL.Method() << function(self)
        local curSquad = GameInstance.player.squadManager.curSquad
        self.view.buffNode:Init(curSquad.slots[curSquad.leaderIndex].character)
    end
    BattleActionCtrl.OnCharacterDead = HL.Method(HL.Table) << function(self, args)
        local csIndex = unpack(args)
        if csIndex == GameInstance.player.squadManager.curSquad.leaderIndex then
            self.view.buffNode:Clear()
        end
        local luaIndex = LuaIndex(csIndex)
        self.m_skillCellList[luaIndex]:OnCharacterDie()
    end
    BattleActionCtrl.OnResetCharacters = HL.Method() << function(self)
        self:RefreshSkills()
    end
end
do
    BattleActionCtrl._ChangeThrowMode = HL.Method(HL.Table) << function(self, args)
        local data = unpack(args)
        GameInstance.world.battle:ForceResetLockTarget()
        self.view.aimBtn.gameObject:SetActive(not data.valid)
        self.view.skillNode.gameObject:SetActive(not data.valid)
        self:RefreshSkills()
    end
    BattleActionCtrl.OnChangeThrowMode = HL.StaticMethod(HL.Table) << function(args)
        local isOpen, ctrl = UIManager:IsOpen(PanelId.BattleAction)
        if isOpen then
            ctrl:_ChangeThrowMode(args)
            return
        end
        local data = unpack(args)
        if data.valid then
            Notify(MessageConst.EXIT_FACTORY_MODE)
            isOpen, ctrl = UIManager:IsOpen(PanelId.BattleAction)
            if not isOpen then
                return
            end
            ctrl:_ChangeThrowMode(args)
        end
    end
    BattleActionCtrl._ThrowByForceAndDir = HL.Method() << function(self)
        if self.m_throwData ~= nil then
            GameInstance.playerController.mainCharacter.interactiveInstigatorCtrl:CastThrowSkill()
        end
    end
end
do
    BattleActionCtrl.RefreshSkills = HL.Method() << function(self)
        local curSquad = GameInstance.player.squadManager.curSquad
        local squadSlots = curSquad.slots
        for k, skillCell in ipairs(self.m_skillCellList) do
            skillCell.gameObject:SetActive(true)
            if k > squadSlots.Count or (not self.m_teamSkillUnlocked and CSIndex(k) ~= curSquad.leaderIndex) then
                skillCell:SetEmpty(true)
            else
                skillCell:SetEmpty(false)
                skillCell:InitSkillButton(CSIndex(k))
            end
        end
        self:ClearAllSkillBtnClick()
    end
    BattleActionCtrl._OnCharNormalSkillChange = HL.Method(HL.Table) << function(self, args)
        local charInstId, normalSkillId = unpack(args)
        local squadSlots = GameInstance.player.squadManager.curSquad.slots
        for k, skillCell in ipairs(self.m_skillCellList) do
            if k <= squadSlots.Count and not skillCell.m_isEmpty then
                local slot = squadSlots[CSIndex(k)]
                if slot.charInstId == charInstId then
                    skillCell:InitSkillButton(CSIndex(k))
                end
            end
        end
    end
    BattleActionCtrl._OnUspChange = HL.Method(HL.Table) << function(self, args)
        local slotIndex = unpack(args)
        local squadSlots = GameInstance.player.squadManager.curSquad.slots
        for k, skillCell in ipairs(self.m_skillCellList) do
            if k <= squadSlots.Count and not skillCell.m_isEmpty then
                local slot = squadSlots[CSIndex(k)]
                if slot.index == slotIndex then
                    skillCell:OnUspChange()
                end
            end
        end
    end
    BattleActionCtrl._OnSkillLevelUpgraded = HL.Method(HL.Table) << function(self, args)
        local charInstId, skillId, newLevel = unpack(args)
        local squadSlots = GameInstance.player.squadManager.curSquad.slots
        for k, skillCell in ipairs(self.m_skillCellList) do
            if k <= squadSlots.Count and not skillCell.m_isEmpty then
                local slot = squadSlots[CSIndex(k)]
                if slot.charInstId == charInstId then
                    skillCell:InitSkillButton(CSIndex(k))
                end
            end
        end
    end
    BattleActionCtrl._OnCharPotentialUnlock = HL.Method(HL.Table) << function(self, args)
        local charInstId, level = unpack(args)
        local squadSlots = GameInstance.player.squadManager.curSquad.slots
        for k, skillCell in ipairs(self.m_skillCellList) do
            if k <= squadSlots.Count and not skillCell.m_isEmpty then
                local slot = squadSlots[CSIndex(k)]
                if slot.charInstId == charInstId then
                    skillCell:InitSkillButton(CSIndex(k))
                end
            end
        end
    end
    BattleActionCtrl._OnPanelInputBlocked = HL.Override(HL.Boolean) << function(self, active)
        if not active and self:IsShow() then
            self:ClearAllSkillBtnClick()
            self:OnToggleControllerSkillIndicator(false)
        end
        if active and self:IsShow() and InputManagerInst:GetKey(CS.Beyond.Input.GamepadKeyCode.RT) then
            self:OnToggleControllerSkillIndicator(true)
        end
    end
    BattleActionCtrl.OnClearSkillBtnState = HL.Method() << function(self)
        self:RefreshSkills()
    end
    BattleActionCtrl.ClearAllSkillBtnClick = HL.Method(HL.Opt(HL.Boolean)) << function(self)
        self:_ClearAllSkillBtnClick()
    end
    BattleActionCtrl._ClearAllSkillBtnClick = HL.Method() << function(self)
        local squadSlots = GameInstance.player.squadManager.curSquad.slots
        for k, skillCell in ipairs(self.m_skillCellList) do
            if k <= squadSlots.Count then
                skillCell:ClearBtnClick()
            end
        end
    end
    BattleActionCtrl.OnDebugToggleSkillRecoverBtn = HL.Method() << function(self)
    end
end
do
    BattleActionCtrl.OnToggleUiAction = HL.Method(HL.Table) << function(self, arg)
        local isShow = unpack(arg)
        if isShow then
            if self.m_toggleUIKey == -1 then
                return
            end
            UIManager:RecoverScreen(self.m_toggleUIKey)
            self.m_toggleUIKey = -1
            UIManager.worldObjectRoot.gameObject:SetActive(true)
        else
            if self.m_toggleUIKey ~= -1 then
                return
            end
            self.m_toggleUIKey = UIManager:ClearScreen(nil)
            UIManager.worldObjectRoot.gameObject:SetActive(false)
        end
    end
    BattleActionCtrl.OnToggleControllerSkillIndicator = HL.Method(HL.Boolean) << function(self, active)
        if self.isControllerPanel then
            if active and not self:IsShow() then
                return
            end
            self.m_skillIndicatorShowing = active
            self.view.animator:SetBool("IndicatorActive", active)
            if active then
                AudioManager.PostEvent("au_ui_menu_destroy_open")
            end
        end
    end
    BattleActionCtrl.OnFadeHUD = HL.Method(HL.Boolean) << function(self, inFade)
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
end
do
    BattleActionCtrl.OnSystemUnlock = HL.Method(HL.Any) << function(self, arg)
        local systemIndex = unpack(arg)
        if systemIndex == GEnums.UnlockSystemType.NormalSkill:GetHashCode() then
            self.view.skillNode.gameObject:SetActiveIfNecessary(true)
            self.view.atbNode.gameObject:SetActiveIfNecessary(true)
        end
        if systemIndex == GEnums.UnlockSystemType.UltimateSkill:GetHashCode() then
            self:RefreshSkills()
        end
        if systemIndex == GEnums.UnlockSystemType.TeamSkill:GetHashCode() then
            self.m_teamSkillUnlocked = true
            self:RefreshSkills()
        end
    end
end
HL.Commit(BattleActionCtrl)