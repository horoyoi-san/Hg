local UIWidgetBase = require_ex('Common/Core/UIWidgetBase')
AttackButton = HL.Class('AttackButton', UIWidgetBase)
AttackButton.root = HL.Field(HL.Userdata)
AttackButton.m_isShowing = HL.Field(HL.Boolean) << false
AttackButton.m_hasBindInput = HL.Field(HL.Boolean) << false
AttackButton.m_pressScreen = HL.Field(HL.Function)
AttackButton.m_releaseScreen = HL.Field(HL.Function)
AttackButton.m_longPressScreen = HL.Field(HL.Boolean) << false
AttackButton.m_pressTimerId = HL.Field(HL.Number) << -1
AttackButton.m_lateTickKey = HL.Field(HL.Number) << -1
AttackButton.m_iconCache = HL.Field(HL.Table)
AttackButton.m_forbidAttackKeys = HL.Field(HL.Table)
AttackButton._OnFirstTimeInit = HL.Override() << function(self)
    self.root = self:GetUICtrl()
    self.m_isShowing = false
    self.m_forbidAttackKeys = {}
    self.m_iconCache = {}
    self:RegisterMessage(MessageConst.ON_CHANGE_THROW_MODE, function(args)
        self:_RefreshAttackIcon()
    end)
    self:RegisterMessage(MessageConst.TOGGLE_FORBID_ATTACK, function(args)
        self:ToggleForbidAttack(args)
    end)
    self:RegisterMessage(MessageConst.ON_APPLICATION_FOCUS, function(args)
        self:OnApplicationFocus(args)
    end)
    self:RegisterMessage(MessageConst.ON_SYSTEM_UNLOCK, function(args)
        self:OnSystemUnlock(args)
    end)
    self:RegisterMessage(MessageConst.ON_BATTLE_CENTER_CHANGE, function(args)
        self:_RefreshAttackIcon()
    end)
    self:RegisterMessage(MessageConst.ON_BREAKING_TARGET_CHANGED, function(args)
        self:_RefreshAttackIcon()
    end)
    if not DeviceInfo.isPCorConsole then
        self.view.button.onPressStart:AddListener(function()
            self:StartPressAttackBtn()
        end)
        self.view.button.onPressEnd:AddListener(function()
            if Utils.isInThrowMode() then
                self:_ThrowByForceAndDir()
            else
                self:ReleaseNormalAttackBtn()
            end
        end)
    end
    self.m_lateTickKey = LuaUpdate:Add("LateTick", function(deltaTime)
        self:_Update()
    end)
    self:ToggleForbidAttack({ "Unlock", not Utils.isSystemUnlocked(GEnums.UnlockSystemType.NormalAttack) })
    self:ToggleForbidAttack({ "GameMode", GameInstance.mode.forbidAttack })
end
AttackButton.InitAttackButton = HL.Method() << function(self)
    self:_FirstTimeInit()
end
AttackButton.OnShow = HL.Method() << function(self)
    self:_RefreshShowing()
    self:_RefreshAttackIcon()
end
AttackButton.OnHide = HL.Method() << function(self)
    self:_RefreshShowing()
    self:ReleaseNormalAttackBtn()
end
AttackButton._OnDestroy = HL.Override() << function(self)
    local touchPanel = UIManager.commonTouchPanel
    if self.m_pressScreen then
        touchPanel.onPress:RemoveListener(self.m_pressScreen)
    end
    if self.m_releaseScreen then
        touchPanel.onRelease:RemoveListener(self.m_releaseScreen)
    end
    LuaUpdate:Remove(self.m_lateTickKey)
    self.m_lateTickKey = -1
end
AttackButton._RefreshShowing = HL.Method() << function(self)
    local showing = self.view.gameObject.activeInHierarchy
    if self.m_isShowing == showing then
        return
    end
    self.m_isShowing = showing
    if showing then
        local touchPanel = UIManager.commonTouchPanel
        self.m_pressScreen = function()
            if DeviceInfo.isPCorConsole then
                if InputManagerInst.inHideCursorMode then
                    return
                end
                if not self.view.gameObject.activeSelf then
                    return
                end
                self:StartPressAttackBtn()
            end
        end
        self.m_releaseScreen = function()
            if DeviceInfo.isPCorConsole then
                if InputManagerInst.inHideCursorMode then
                    return
                end
                if Utils.isInThrowMode() then
                    self:_ThrowByForceAndDir()
                else
                    if InputManagerInst.inHideCursorMode then
                        return
                    end
                    self:ReleaseNormalAttackBtn()
                end
            end
        end
        touchPanel.onPress:AddListener(self.m_pressScreen)
        touchPanel.onRelease:AddListener(self.m_releaseScreen)
        self:BindNormalAttackInputEvent()
    else
        local touchPanel = UIManager.commonTouchPanel
        if self.m_pressScreen then
            touchPanel.onPress:RemoveListener(self.m_pressScreen)
        end
        if self.m_releaseScreen then
            touchPanel.onRelease:RemoveListener(self.m_releaseScreen)
        end
    end
end
AttackButton._ThrowByForceAndDir = HL.Method() << function(self)
    if GameInstance.world.battle.inThrowMode then
        GameInstance.playerController.mainCharacter.interactiveInstigatorCtrl:CastThrowSkill()
    end
end
AttackButton.BindNormalAttackInputEvent = HL.Method() << function(self)
    if self.m_hasBindInput then
        return
    end
    self.m_hasBindInput = true
    self.root:BindInputPlayerAction("battle_attack_start", function()
        if UNITY_EDITOR and DeviceInfo.usingTouch then
            return
        end
        if not InputManager.cursorVisible then
            self:StartPressAttackBtn()
        end
    end)
    self.root:BindInputPlayerAction("battle_attack_end", function()
        if UNITY_EDITOR and DeviceInfo.usingTouch then
            return
        end
        if Utils.isInThrowMode() and not InputManager.cursorVisible then
            self:_ThrowByForceAndDir()
        end
        self:ReleaseNormalAttackBtn()
    end)
end
AttackButton._Update = HL.Method() << function(self)
    if not self.m_longPressScreen then
        return
    end
    GameInstance.playerController:CastNormalAttack()
end
AttackButton.StartPressAttackBtn = HL.Method() << function(self)
    if Utils.isInThrowMode() then
        return
    end
    if not GameInstance.playerController.canPressAttackButton then
        return
    end
    if not self.view.gameObject.activeSelf then
        return
    end
    self.m_pressTimerId = self:_StartTimer(0, function()
        self.m_longPressScreen = true
    end)
end
AttackButton.ReleaseNormalAttackBtn = HL.Method() << function(self)
    if self.m_longPressScreen == true then
        self.m_longPressScreen = false
    end
    self.m_pressTimerId = self:_ClearTimer(self.m_pressTimerId)
end
AttackButton.OnApplicationFocus = HL.Method(HL.Table) << function(self, args)
    local hasFocus = unpack(args)
    if not hasFocus then
        self:ReleaseNormalAttackBtn()
    end
end
local weaponNumToConfigIcon = { "ICON_ATTACK_SWORD", "ICON_ATTACK_WAND", "ICON_ATTACK_CLAYM", "", "ICON_ATTACK_LANCE", "ICON_ATTACK_PISTOL", }
AttackButton._RefreshAttackIcon = HL.Method() << function(self)
    if DeviceInfo.isPCorConsole then
        return
    end
    local iconName
    local inThrowMode = GameInstance.world.battle.inThrowMode
    local showBreakingNode = false
    if inThrowMode then
        iconName = self.config.ICON_THROW
    else
        if GameInstance.world.battle.lastCanBeBreakingAttackTarget ~= nil then
            iconName = "ICON_ATTACK_BREAKING"
            showBreakingNode = true
        else
            local mainChar = GameInstance.playerController.mainCharacter
            local templateId = mainChar.templateData.id
            local charWeaponTypeNum = Tables.characterTable:GetValue(templateId).weaponType:GetHashCode()
            iconName = weaponNumToConfigIcon[charWeaponTypeNum]
        end
    end
    local sprite = self.m_iconCache[iconName]
    if sprite == nil then
        sprite = self:LoadSprite(UIConst.UI_SPRITE_SKILL_ICON, self.config[iconName])
        self.m_iconCache[iconName] = sprite
    end
    self.view.icon.sprite = sprite
    self.view.finshKillAttackNode.gameObject:SetActive(showBreakingNode)
end
AttackButton.OnSystemUnlock = HL.Method(HL.Table) << function(self, args)
    local system = unpack(args)
    system = GEnums.UnlockSystemType.__CastFrom(system)
    if system == GEnums.UnlockSystemType.NormalAttack then
        self:ToggleForbidAttack({ "Unlock", false })
    end
end
AttackButton.ToggleForbidAttack = HL.Method(HL.Table) << function(self, args)
    local reason, forbid = unpack(args)
    if forbid then
        self.m_forbidAttackKeys[reason] = true
    else
        self.m_forbidAttackKeys[reason] = nil
    end
    if next(self.m_forbidAttackKeys) then
        self.view.gameObject:SetActive(false)
    else
        self.view.gameObject:SetActive(true)
    end
    self:_RefreshShowing()
end
HL.Commit(AttackButton)
return AttackButton