local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.MainHud
MainHudCtrl = HL.Class('MainHudCtrl', uiCtrl.UICtrl)
MainHudCtrl.s_messages = HL.StaticField(HL.Table) << { [MessageConst.ON_SQUAD_INFIGHT_CHANGED] = 'OnSquadInfightChanged', [MessageConst.ON_SET_IN_SAFE_ZONE] = 'OnSetInSafeZone', [MessageConst.ON_IN_FAC_MAIN_REGION_CHANGE] = 'OnInFacMainRegionChange', [MessageConst.ON_FAC_MODE_CHANGE] = 'OnFacModeChange', [MessageConst.ON_FAC_TOP_VIEW_HIDE_UI_MODE_CHANGE] = 'OnFacTopViewHideUIModeChange', [MessageConst.FAC_ON_PLAYER_POS_INFO_CHANGED] = 'OnFacPlayerPosInfoChanged', [MessageConst.FAC_SET_ENABLE_EXIT_FACTORY_MODE] = 'SetEnableExitFactoryMode', [MessageConst.ON_SYSTEM_UNLOCK] = 'OnSystemUnlock', [MessageConst.GAME_MODE_ENABLE] = 'OnGameModeChange', [MessageConst.ON_TOGGLE_FAC_TOP_VIEW] = 'OnToggleFacTopView', [MessageConst.ON_EXIT_FACTORY_MODE] = 'OnExitFactoryMode', [MessageConst.ON_FADE_HUD] = 'OnFadeHUD', [MessageConst.TOGGLE_FORBID_SPRINT] = 'ToggleForbidSprint', [MessageConst.ON_SNS_NORMAL_DIALOG_ADD] = 'OnSNSNormalDialogAdd', [MessageConst.ON_SNS_FORCE_DIALOG_ADD] = 'OnSNSForceDialogAdd', [MessageConst.TOGGLE_PLAYER_MOVE] = 'TogglePlayerMove', [MessageConst.ON_ENTER_TOWER_DEFENSE_DEFENDING_PHASE] = 'OnEnterTowerDefenseDefendingPhase', [MessageConst.ON_TOWER_DEFENSE_LEVEL_REWARDS_FINISHED] = 'OnTowerDefenseDefendingRewardsFinished', [MessageConst.ON_ENTER_RACING_DUNGEON] = 'OnEnterRacingDungeon', [MessageConst.ON_LEAVE_RACING_DUNGEON] = 'OnLeaveRacingDungeon', [MessageConst.SHOW_RACING_OBTAIN_BUFF] = 'OnShowRacingDungeonObtainBuff', [MessageConst.ON_BUILD_MODE_CHANGE] = 'OnBuildModeChange', [MessageConst.ON_FAC_DESTROY_MODE_CHANGE] = 'OnFacDestroyModeChange', [MessageConst.ON_GET_NEW_MAILS] = 'OnGetNewMails', [MessageConst.ON_GET_LOST_AND_FOUND] = 'OnLostAndFoundRefresh', [MessageConst.ON_ADD_LOST_AND_FOUND] = 'OnLostAndFoundRefresh', [MessageConst.OVERRIDE_JUMP_ACTION] = 'OverrideJump', [MessageConst.FAC_ON_FLUID_IN_BUILDING_REMOVED] = 'OnFluidInBuildingRemoved', [MessageConst.SET_MAIN_HUD_CAN_AUTO_STOP_EXPAND] = 'OnSetMainHudCanAutoStopExpand', [MessageConst.FORBID_SYSTEM_CHANGED] = 'TryUpdateAllTopBtnsVisible', [MessageConst.ON_TOGGLE_PHASE_FORBID] = 'TryUpdateAllTopBtnsVisible', }
MainHudCtrl.s_clearScreenId = HL.StaticField(HL.Number) << 0
MainHudCtrl.s_clearScreenIdExceptSomePanel = HL.StaticField(HL.Number) << 0
MainHudCtrl.m_indicatorControllerGroupId = HL.Field(HL.Number) << 1
MainHudCtrl.m_hudFadeTween = HL.Field(HL.Userdata)
MainHudCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.m_hideSprintKeys = {}
    self.m_disablePlayerMoveKeys = {}
    self.view.expandBtn.onClick:AddListener(function()
        self:_OnClickExpand()
    end)
    self.view.closeExpandBtn.onClick:AddListener(function()
        self:_SetExpanded(false)
    end)
    self.view.expandRedDot:InitRedDot("MainHudExpand")
    self:_InitTopBtns()
    self:_InitMainHudBinding()
    self:_UpdateInventoryState(true)
    self:_UpdateSwitchModeState()
    self:_InitDebugAction()
    self:_SetExpanded(false, true)
    self.view.racingEffectWidget:InitMainHudRacingEffectBtn()
    self.view.attackButton:InitAttackButton()
    if Utils.isSwitchModeDisabled() then
        self:BindInputPlayerAction("common_disable_switch_mode", function()
            if Utils.isInBlackbox() then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_BLACK_BOX_SWITCH_MODE_DISABLED)
            elseif Utils.isInSpaceShip() then
                Notify(MessageConst.SHOW_TOAST, Language.LUA_SPASCESHIP_SWITCH_MODE_DISABLED)
            end
        end)
    end
end
MainHudCtrl.OnShow = HL.Override() << function(self)
    self:UpdateAllTopBtnsVisible()
    RedDotManager:TriggerUpdate("Mail")
    self:_CheckShowMailBtnBubble()
    if Utils.isInFactoryMode() then
        self.view.topLeftBtns:SampleToInAnimationEnd()
    else
        self.view.topLeftBtns:SampleToOutAnimationEnd()
    end
    if InputManagerInst:GetKey(CS.Beyond.Input.GamepadKeyCode.RT) then
        self:_ToggleControllerIndicator(true)
    end
    self.view.racingEffectWidget:OnShow()
    self.view.attackButton:OnShow()
end
MainHudCtrl.OnHide = HL.Override() << function(self)
    self:_ToggleControllerIndicator(false)
    self:_SetExpanded(false, true)
    self.view.racingEffectWidget:OnHide()
    self.view.attackButton:OnHide()
    if self.m_mailBubbleShowingState ~= 0 then
        self.m_mailBubbleShowingState = 0
        self.m_mainBubbleCor = self:_ClearCoroutine(self.m_mainBubbleCor)
        self.view.mailBubbleImg.gameObject:SetActive(false)
    end
end
MainHudCtrl.OnClose = HL.Override() << function(self)
    if self.m_hudFadeTween then
        self.m_hudFadeTween:Kill()
    end
end
MainHudCtrl.m_topBtnData = HL.Field(HL.Table)
MainHudCtrl._BuildTopBtnData = HL.Method() << function(self)
    self.m_topBtnData = {
        top = {
            viewNode = self.view.topNode,
            checkVisible = function()
                if FactoryUtils.isInBuildMode() then
                    return false
                end
                if LuaSystemManager.facSystem.inDestroyMode then
                    return false
                end
                return true
            end,
            canStayInTowerDefenseDefending = true,
        },
        bottomRight = {
            viewNode = self.view.bottomRightNode,
            checkVisible = function()
                if LuaSystemManager.facSystem.inTopView then
                    return false
                end
                return true
            end,
            canStayInTowerDefenseDefending = true,
        },
        exitRacing = {
            button = self.view.exitRacingBtn,
            checkVisible = function()
                return false
            end,
            onClick = function()
                UIManager:Open(PanelId.RacingDungeonExitPopUp)
            end,
        },
        answerRacing = {
            button = self.view.answerRacingBtn,
            checkVisible = function()
                return Utils.isInRacingDungeon()
            end,
            onClick = function()
                UIManager:Open(PanelId.RacingDungeonEntryPop)
            end,
        },
        exitDungeon = {
            button = self.view.exitDungeonBtn,
            checkVisible = function()
                return (Utils.isInRacingDungeon() or Utils.isInDungeon()) and not Utils.isInDungeonFactory()
            end,
            onClick = function()
                if Utils.isInRacingDungeon() then
                    UIManager:Open(PanelId.RacingDungeonExitPopUp)
                else
                    if LuaSystemManager.commonTaskTrackSystem:HasRequest() then
                        return
                    end
                    DungeonUtils.onClickExitDungeonBtn()
                end
            end
        },
        switchMode = {
            viewNode = self.view.switchModeNode,
            toggle = self.view.switchModeNode.toggle,
            checkVisible = function()
                if not Utils.isSystemUnlocked(GEnums.UnlockSystemType.FacMode) then
                    return false
                end
                if GameInstance.player.forbidSystem:IsForbidden(ForbidType.DisableSwitchMode) then
                    return false
                end
                if not Utils.isCurrentMapHasFactoryGrid() then
                    return false
                end
                return true
            end,
            checkIsValueValid = function(isOn)
                local valid, toast = self:_CheckSwitchModeValueValid(isOn)
                if not valid then
                    Notify(MessageConst.SHOW_TOAST, toast)
                    AudioAdapter.PostEvent("au_ui_fac_mode_fail")
                end
                return valid
            end,
            onValueChanged = function(isOn)
                self:_SwitchMode(isOn)
            end,
            getCurValue = function()
                return Utils.isInFactoryMode()
            end,
        },
        emptySwitch = {
            viewNode = self.view.emptySwitchNode,
            checkVisible = function()
                return GameInstance.player.forbidSystem:IsForbidden(ForbidType.ShowEmptySwitchModeBtn)
            end,
        },
        techTree = {
            button = self.view.techTreeBtn,
            redDotView = self.view.techTreeRedDot,
            phaseId = PhaseId.FacTechTree,
            checkVisible = function()
                return not Utils.isInDungeon()
            end,
        },
        dungeonInfo = {
            button = self.view.dungeonInfoBtn,
            checkVisible = function()
                if not Utils.isInDungeon() then
                    return false
                end
                if Utils.isInRacingDungeon() then
                    return false
                end
                return DungeonUtils.isDungeonHasFeatureInfo(GameInstance.dungeonManager.curDungeonId)
            end,
            onClick = function()
                local dungeonId = GameInstance.dungeonManager.curDungeonId
                UIManager:AutoOpen(PanelId.DungeonInfoPopup, { dungeonId = dungeonId, needBindAction = true })
            end,
        },
        report = {
            button = self.view.reportBtn,
            phaseId = PhaseId.FacHUBData,
            onlyInFacMode = true,
            checkVisible = function()
                return not Utils.isInDungeonFactory()
            end,
        },
        hub = {
            button = self.view.hubBtn,
            checkVisible = function()
                return Utils.isInDungeonFactory()
            end,
            onClick = function()
                Notify(MessageConst.FAC_OPEN_NEAREST_BUILDING_PANEL, { FacConst.HUB_DATA_ID, true })
            end
        },
        controlCenter = {
            button = self.view.controlCenterBtn,
            checkVisible = function()
                return Utils.isInSpaceShip()
            end,
            phaseId = PhaseId.SpaceshipControlCenter,
            phaseArgs = { fromMainHud = true },
        },
        sns = {
            button = self.view.snsBtn,
            redDotView = self.view.snsRedDot,
            phaseId = PhaseId.SNS,
            checkVisible = function()
                return GameInstance.player.sns:HasDialogOrMoment() and not Utils.isInDungeon() and not UIManager:IsOpen(PanelId.SNSNoticeHud)
            end,
            onClick = function()
                PhaseManager:OpenPhase(PhaseId.SNS)
            end,
        },
        watch = {
            button = self.view.watchBtn,
            redDotView = self.view.watchRedDot,
            phaseId = PhaseId.Watch,
            onClick = function()
                PhaseManager:OpenPhase(PhaseId.Watch)
            end,
        },
        simpleMenu = {
            button = self.view.simpleMenuBtn,
            phaseId = PhaseId.SimpleSystem,
            checkVisible = function()
                return not Utils.isSystemUnlocked(GEnums.UnlockSystemType.Watch)
            end,
        },
        inventory = { button = self.view.inventoryBtn, redDotView = self.view.inventoryRedDot, phaseId = PhaseId.Inventory, },
        valuableDepot = { button = self.view.valuableDepotBtn, phaseId = PhaseId.ValuableDepot, },
        character = { button = self.view.characterBtn, phaseId = PhaseId.CharInfo, canStayInTowerDefenseDefending = true, redDotView = self.view.charRedDot, },
        formation = { button = self.view.formationBtn, phaseId = PhaseId.CharFormation, },
        mail = {
            button = self.view.mailBtn,
            redDotView = self.view.mailRedDot,
            phaseId = PhaseId.Mail,
            checkVisible = function()
                return RedDotManager:GetRedDotState("Mail") and not Utils.isInDungeon()
            end,
        },
        adventureBook = {
            button = self.view.adventureBookBtn,
            phaseId = PhaseId.AdventureBook,
            redDotView = self.view.adventureBookRedDot,
            checkVisible = function()
                return not Utils.isInDungeon()
            end,
        },
        gacha = { button = self.view.gachaBtn, phaseId = PhaseId.GachaPool, redDotView = self.view.gachaRedDot, },
        racingEffect = {
            button = self.view.racingEffectBtn,
            phaseId = PhaseId.RacingDungeonEffect,
            checkVisible = function()
                return Utils.isInRacingDungeon()
            end,
        }
    }
end
MainHudCtrl._InitTopBtns = HL.Method() << function(self)
    self:_BuildTopBtnData()
    for _, info in pairs(self.m_topBtnData) do
        self:_InitSingleTopBtn(info)
    end
end
MainHudCtrl._InitSingleTopBtn = HL.Method(HL.Table) << function(self, info)
    if not info.viewNode then
        info.viewNode = info.button or info.toggle
    end
    if info.phaseId then
        if not info.redDotName then
            info.redDotName = PhaseManager:GetPhaseRedDotName(info.phaseId)
        end
    end
    if info.redDotView then
        info.redDotView:InitRedDot(info.redDotName)
    end
    if info.button then
        info.button.onClick:RemoveAllListeners()
        info.button.onClick:AddListener(function()
            if info.onClick then
                info.onClick()
            else
                PhaseManager:OpenPhase(info.phaseId, info.phaseArgs)
            end
        end)
    end
    if info.toggle then
        info.toggle.onValueChanged:RemoveAllListeners()
        info.toggle.isOn = info.getCurValue()
        info.toggle.onValueChanged:AddListener(function(isOn)
            info.onValueChanged(isOn)
        end)
        if info.checkIsValueValid then
            info.toggle.checkIsValueValid = function(isOn)
                return info.checkIsValueValid(isOn)
            end
        end
    end
end
MainHudCtrl.m_updateTimerId = HL.Field(HL.Number) << -1
MainHudCtrl.TryUpdateAllTopBtnsVisible = HL.Method(HL.Opt(HL.Any)) << function(self, _)
    if self.m_updateTimerId > 0 then
        return
    end
    self.m_updateTimerId = self:_StartTimer(0, function()
        self.m_updateTimerId = -1
        self:UpdateAllTopBtnsVisible()
    end)
end
MainHudCtrl.UpdateAllTopBtnsVisible = HL.Method() << function(self)
    self.m_curExpandedBtnCount = 0
    for _, info in pairs(self.m_topBtnData) do
        self:_UpdateSingleTopBtnVisible(info)
    end
    if self.m_curExpandedBtnCount > 0 then
        self.view.expandBtn.gameObject:SetActive(not self.m_isExpanded)
        for k = 1, 4 do
            local img = self.view.expandDotNode["dot" .. k]
            if self.m_curExpandedBtnCount >= k then
                UIUtils.changeAlpha(img, 1)
            else
                UIUtils.changeAlpha(img, 0.3)
            end
        end
    else
        self:_SetExpanded(false, true)
    end
end
MainHudCtrl._UpdateSingleTopBtnVisible = HL.Method(HL.Table) << function(self, info)
    local visible = self:_GetSingleTopBtnVisible(info)
    if info.viewNode then
        info.viewNode.gameObject:SetActive(visible)
    else
        logger.error("No viewNode on", info)
    end
    if info.belongToExpand and visible then
        self.m_curExpandedBtnCount = self.m_curExpandedBtnCount + 1
    end
end
MainHudCtrl._GetSingleTopBtnVisible = HL.Method(HL.Table).Return(HL.Boolean) << function(self, info)
    if Utils.isInSettlementDefenseDefending() then
        if not info.canStayInTowerDefenseDefending then
            return false
        end
    end
    if LuaSystemManager.facSystem.isTopViewHideUIMode then
        if not info.canStayInTopViewHideUIMode then
            return false
        end
    end
    if info.onlyInFacMode then
        if not Utils.isInFactoryMode() then
            return false
        end
    end
    if info.hideInFacMode then
        if Utils.isInFactoryMode() then
            return false
        end
    end
    if info.phaseId then
        if not PhaseManager:IsPhaseUnlocked(info.phaseId) then
            return false
        end
        if PhaseManager:IsPhaseForbidden(info.phaseId) then
            return false
        end
    end
    if info.checkVisible then
        local rst = info.checkVisible()
        return rst == true
    end
    return true
end
MainHudCtrl._InitMainHudBinding = HL.Method() << function(self)
    self.view.sprintBtn.onPressStart:AddListener(function()
        self:_OnPressSprint()
    end)
    self.view.sprintBtn.onPressEnd:AddListener(function()
        self:_OnReleaseSprint()
    end)
    self.view.jumpBtn.onPressStart:AddListener(function()
        self:_OnPressJump()
    end)
    local groupId = self.view.topRightBtns.groupId
    self:BindInputPlayerAction("common_open_quick_menu_start", function()
        if self.m_battleActionType == Types.EBattleActionType.None and not InputManagerInst:GetKey(CS.Beyond.Input.GamepadKeyCode.RT) then
            UIManager:Open(PanelId.QuickMenu)
        end
    end)
    self.m_indicatorControllerGroupId = InputManagerInst:CreateGroup(self.view.inputGroup.groupId)
    UIUtils.bindInputPlayerAction("common_indicator_start", function()
        self:_ToggleControllerIndicator(true)
    end, self.m_indicatorControllerGroupId)
    UIUtils.bindInputPlayerAction("common_indicator_end", function()
        self:_ToggleControllerIndicator(false)
    end, self.m_indicatorControllerGroupId)
    self:ToggleForbidSprint({ "Unlock", not Utils.isSystemUnlocked(GEnums.UnlockSystemType.Dash) })
    self.view.jumpBtn.gameObject:SetActive(Utils.isSystemUnlocked(GEnums.UnlockSystemType.Jump))
end
MainHudCtrl._OnPanelInputBlocked = HL.Override(HL.Boolean) << function(self, active)
    self:_UpdateSprintInfo(active)
    if active then
        if DeviceInfo.isPCorConsole and InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.Mouse0) and not InputManagerInst:GetKeyUp(CS.Beyond.Input.KeyboardKeyCode.Mouse0) then
            self.view.attackButton:StartPressAttackBtn()
        end
    else
        self.view.attackButton:ReleaseNormalAttackBtn()
    end
end
MainHudCtrl._InitDebugAction = HL.Method() << function(self)
    if not BEYOND_DEBUG_COMMAND then
        return
    end
    self:BindInputPlayerAction("battle_debug_flying_mode", function()
        CS.Beyond.Gameplay.Core.PlayerController.ToggleFlyingMode()
    end)
    self:BindInputPlayerAction("battle_debug_get_debug_info", function()
        CS.Beyond.Gameplay.Core.PlayerController.GetDebugInfo()
    end)
end
MainHudCtrl.OnExitFactoryMode = HL.Method() << function(self)
end
MainHudCtrl.OnFadeHUD = HL.Method(HL.Boolean) << function(self, inFade)
    if not DeviceInfo.isPCorConsole then
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
MainHudCtrl._OnClearScreenOn = HL.StaticMethod() << function()
    if MainHudCtrl.s_clearScreenId > 0 then
        print("MainHudCtrl._OnClearScreenOn : s_clearScreenId > 0")
        return
    end
    MainHudCtrl.s_clearScreenId = UIManager:ClearScreen()
    Notify(MessageConst.ON_CLEAR_SCREEN_STATE_CHANGED, true)
end
MainHudCtrl._OnClearScreenOff = HL.StaticMethod() << function()
    UIManager:RecoverScreen(MainHudCtrl.s_clearScreenId)
    MainHudCtrl.s_clearScreenId = 0
    Notify(MessageConst.ON_CLEAR_SCREEN_STATE_CHANGED, false)
end
MainHudCtrl._OnClearScreenOnExceptSomePanel = HL.StaticMethod(HL.Table) << function(arg)
    if MainHudCtrl.s_clearScreenIdExceptSomePanel > 0 then
        print("MainHudCtrl._OnClearScreenOnExceptSomePanel : s_clearScreenIdExceptSomePanel > 0")
        return
    end
    local panels = unpack(arg)
    local panelIds = {}
    for _, panelId in pairs(panels) do
        table.insert(panelIds, PanelId[panelId])
    end
    MainHudCtrl.s_clearScreenIdExceptSomePanel = UIManager:ClearScreen(panelIds)
    Notify(MessageConst.ON_CLEAR_SCREEN_STATE_CHANGED, true)
end
MainHudCtrl._OnClearScreenOffExceptSomePanel = HL.StaticMethod() << function()
    UIManager:RecoverScreen(MainHudCtrl.s_clearScreenIdExceptSomePanel)
    MainHudCtrl.s_clearScreenIdExceptSomePanel = 0
    Notify(MessageConst.ON_CLEAR_SCREEN_STATE_CHANGED, false)
end
MainHudCtrl.OnSquadInfightChanged = HL.Method(HL.Opt(HL.Any)) << function(self, args)
    self:_UpdateSwitchModeState()
    self:_UpdateInventoryState(false)
end
MainHudCtrl.OnSetInSafeZone = HL.Method(HL.Opt(HL.Any)) << function(self, args)
    self:_UpdateInventoryState(false)
end
MainHudCtrl.OnInFacMainRegionChange = HL.Method(HL.Boolean) << function(self, inFacMain)
    self:TryUpdateAllTopBtnsVisible()
    self:_UpdateInventoryState(false)
end
MainHudCtrl.OnFacPlayerPosInfoChanged = HL.Method() << function(self)
    self:_UpdateSwitchModeState()
end
MainHudCtrl.m_inFacModeTagHandle = HL.Field(HL.Userdata)
MainHudCtrl.OnFacModeChange = HL.Method(HL.Boolean) << function(self, inFacMode)
    self:TryUpdateAllTopBtnsVisible()
    self:_UpdateSwitchModeState()
    if inFacMode then
        if not self.m_inFacModeTagHandle then
            self.m_inFacModeTagHandle = GameInstance.instance:AddGlobalTag(CS.Beyond.Gameplay.Core.GameplayTag(CS.Beyond.GlobalTagConsts.TAG_FAC_MODE))
        end
        self.view.topLeftBtns:PlayInAnimation()
    else
        if self.m_inFacModeTagHandle then
            self.m_inFacModeTagHandle:RemoveTag()
            self.m_inFacModeTagHandle = nil
        end
        self.view.topLeftBtns:PlayOutAnimation()
    end
end
MainHudCtrl.OnFacTopViewHideUIModeChange = HL.Method(HL.Boolean) << function(self, isTopViewHideUIMode)
    self:TryUpdateAllTopBtnsVisible()
end
MainHudCtrl.OnToggleFacTopView = HL.Method(HL.Boolean) << function(self, active)
    self:TryUpdateAllTopBtnsVisible()
end
MainHudCtrl.OnSystemUnlock = HL.Method(HL.Table) << function(self, arg)
    self:TryUpdateAllTopBtnsVisible()
    local system = unpack(arg)
    system = GEnums.UnlockSystemType.__CastFrom(system)
    if system == GEnums.UnlockSystemType.FacMode then
        self:_UpdateSwitchModeState()
    elseif system == GEnums.UnlockSystemType.Dash then
        self:ToggleForbidSprint({ "Unlock", false })
    elseif system == GEnums.UnlockSystemType.Jump then
        self.view.jumpBtn.gameObject:SetActive(true)
    end
end
MainHudCtrl.OnGameModeChange = HL.Method(HL.Table) << function(self, mode)
    self:TryUpdateAllTopBtnsVisible()
    self:_UpdateSwitchModeState()
end
MainHudCtrl.OnSNSNormalDialogAdd = HL.Method(HL.Any) << function(self, args)
    if not PhaseManager:IsPhaseUnlocked(PhaseId.SNS) then
        return
    end
    local _, dialogId = unpack(args)
    local dialogContent = Tables.sNSDialogTable[dialogId].dialogSingData
    local firstContent = dialogContent[Tables.sNSConst.snsDialogStartId]
    if firstContent.noticeType ~= GEnums.SNSNewDialogNoticeType.None and self.view.topNode.gameObject.activeInHierarchy and not Utils.isInDungeon() then
        self.view.snsBtn.gameObject:SetActiveIfNecessary(false)
        local wrapArgs = {}
        wrapArgs.args = args
        wrapArgs.noticeFinishFunc = function()
            self:TryUpdateAllTopBtnsVisible()
        end
        UIManager:AutoOpen(PanelId.SNSNoticeHud, wrapArgs)
    end
    RedDotManager:TriggerUpdate("SNSHudEntry")
end
MainHudCtrl.OnSNSForceDialogAdd = HL.Method(HL.Any) << function(self, args)
    if not PhaseManager:IsPhaseUnlocked(PhaseId.SNS) then
        return
    end
    RedDotManager:TriggerUpdate("SNSHudEntry")
end
MainHudCtrl._UpdateSwitchModeState = HL.Method() << function(self)
    local node = self.view.switchModeNode
    if not node.gameObject.activeSelf then
        return
    end
    local inFacMode = Utils.isInFactoryMode()
    node.toggle:SetIsOnWithoutNotify(inFacMode)
    local inFight = Utils.isInFight()
    local isOutOfRangeManual = FactoryUtils.isPlayerOutOfRangeManual()
    node.invalidIcon.gameObject:SetActiveIfNecessary(inFight or isOutOfRangeManual)
end
MainHudCtrl._CheckSwitchModeValueValid = HL.Method(HL.Boolean).Return(HL.Boolean, HL.Opt(HL.String)) << function(self, toFactoryMode)
    if toFactoryMode and Utils.isInFight() then
        return false, Language.LUA_SWITCH_MODE_FAIL_WHEN_FIGHT
    end
    if toFactoryMode and FactoryUtils.isPlayerOutOfRangeManual() then
        return false, Language.LUA_SWITCH_MODE_FAIL_WHEN_OUT_OF_RANGE_MANUAL
    end
    if toFactoryMode and GameInstance.player.forbidSystem:IsForbidden(ForbidType.ForbidFactoryMode) then
        return false, Language.LUA_GAME_MODE_FORBID_FACTORY_BUILD
    end
    return true
end
MainHudCtrl._SwitchMode = HL.Method(HL.Boolean) << function(self, toFactory)
    if toFactory then
        Notify(MessageConst.ENTER_FACTORY_MODE)
    else
        if self.m_enableExitFactoryMode then
            Notify(MessageConst.EXIT_FACTORY_MODE)
        end
    end
end
MainHudCtrl.m_enableExitFactoryMode = HL.Field(HL.Boolean) << true
MainHudCtrl.SetEnableExitFactoryMode = HL.Method(HL.Table) << function(self, args)
    local enable = unpack(args)
    self.m_enableExitFactoryMode = enable
end
MainHudCtrl.m_lastIsInSafeZone = HL.Field(HL.Boolean) << false
MainHudCtrl._UpdateInventoryState = HL.Method(HL.Boolean) << function(self, skipAnim)
    local inSafeZone = Utils.isInSafeZone()
    local wrapper = self.view.inventoryBtnAnimationWrapper
    if skipAnim then
        if inSafeZone then
            wrapper:SampleToInAnimationEnd()
        else
            wrapper:SampleToOutAnimationEnd()
        end
    else
        if inSafeZone ~= self.m_lastIsInSafeZone then
            if inSafeZone then
                wrapper:PlayInAnimation()
            else
                wrapper:PlayOutAnimation()
            end
        end
    end
    self.m_lastIsInSafeZone = inSafeZone
end
MainHudCtrl.m_onPressJumpOverride = HL.Field(HL.Any)
MainHudCtrl.OverrideJump = HL.Method(HL.Any) << function(self, arg)
    if arg then
        self.m_onPressJumpOverride = arg[1]
    else
        self.m_onPressJumpOverride = nil
    end
end
MainHudCtrl.OnFluidInBuildingRemoved = HL.Method(HL.Any) << function(self, arg)
    local nodeList = unpack(arg)
    for i = 0, nodeList.Count - 1 do
        local node = nodeList[i]
        local buildingData = GameInstance.remoteFactoryManager.staticData:QueryBuildingData(node.templateId)
        if buildingData then
            local toastContent = string.format(Language.LUA_FACTORY_FLUID_IN_NODE_REMOVED, buildingData.name)
            Notify(MessageConst.SHOW_TOAST, toastContent)
        end
    end
end
MainHudCtrl._OnPressJump = HL.Method() << function(self)
    if self.m_onPressJumpOverride then
        self.m_onPressJumpOverride()
    else
        GameInstance.playerController:Jump()
    end
end
MainHudCtrl.m_pressingSprint = HL.Field(HL.Boolean) << false
MainHudCtrl.m_pressedSprint = HL.Field(HL.Boolean) << false
MainHudCtrl.m_startPressSprintTime = HL.Field(HL.Number) << 0
MainHudCtrl.m_PressingSprintCor = HL.Field(HL.Thread)
MainHudCtrl._OnPressSprint = HL.Method() << function(self)
    if BEYOND_DEBUG and UNITY_EDITOR then
        if InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.Mouse1) then
            if CS.Beyond.DebugDefines.disableRightClickSprintEvenNoCursor then
                return
            end
            if CS.Beyond.DebugDefines.disableRightClickSprint and InputManager.cursorVisible then
                return
            end
        end
    end
    if next(self.m_disablePlayerMoveKeys) ~= nil then
        return
    end
    if DeviceInfo.usingController then
        if not GameInstance.playerController.hasMoveInput then
            return
        end
        self.m_pressingSprint = true
        self.m_pressedSprint = not self.m_pressedSprint
        if (self.m_pressedSprint) then
            GameInstance.playerController:OnSprintPressed()
        else
            GameInstance.playerController:OnSprintReleased()
        end
    else
        self.m_pressingSprint = true
        self.m_startPressSprintTime = Time.unscaledTime
        GameInstance.playerController:OnSprintPressed()
    end
end
MainHudCtrl._OnReleaseSprint = HL.Method() << function(self)
    GameInstance.playerController:OnSprintReleased()
end
MainHudCtrl._UpdateSprintInfo = HL.Method(HL.Boolean) << function(self, inputEnabled)
    if inputEnabled then
        if self.view.sprintBtn.groupEnabled then
            if InputManagerInst:GetKey(CS.Beyond.Input.KeyboardKeyCode.LeftShift) then
                self:_OnPressSprint()
            end
        end
    else
        self:_OnReleaseSprint()
    end
end
MainHudCtrl._ToggleControllerIndicator = HL.Method(HL.Boolean) << function(self, active)
    Notify(MessageConst.ON_CONTROLLER_INDICATOR_CHANGE, active)
    Notify(MessageConst.TOGGLE_HIDE_INTERACT_OPTION_LIST, { "CONTROLLER_INDICATOR", active })
end
MainHudCtrl.m_hideSprintKeys = HL.Field(HL.Table)
MainHudCtrl.m_disablePlayerMoveKeys = HL.Field(HL.Table)
MainHudCtrl.ToggleForbidSprint = HL.Method(HL.Table) << function(self, args)
    local reason, forbid = unpack(args)
    if forbid then
        self.m_hideSprintKeys[reason] = true
    else
        self.m_hideSprintKeys[reason] = nil
    end
    if next(self.m_hideSprintKeys) then
        self.view.sprintBtn.gameObject:SetActive(false)
    else
        self.view.sprintBtn.gameObject:SetActive(true)
    end
end
MainHudCtrl.TogglePlayerMove = HL.Method(HL.Table) << function(self, args)
    local key, enable = unpack(args)
    if enable then
        self.m_disablePlayerMoveKeys[key] = nil
    else
        self.m_disablePlayerMoveKeys[key] = true
        GameInstance.playerController:UpdateMoveCommand(Vector2.zero)
    end
end
MainHudCtrl.OnEnterTowerDefenseDefendingPhase = HL.Method() << function(self)
    self:TryUpdateAllTopBtnsVisible()
end
MainHudCtrl.OnTowerDefenseDefendingRewardsFinished = HL.Method() << function(self)
    self:_UpdateSwitchModeState()
end
MainHudCtrl.OnEnterRacingDungeon = HL.Method(HL.Any) << function(self, arg)
    self:TryUpdateAllTopBtnsVisible()
end
MainHudCtrl.OnLeaveRacingDungeon = HL.Method() << function(self)
    self:TryUpdateAllTopBtnsVisible()
    UIManager:Close(PanelId.RacingTimeToast)
    Notify(MessageConst.MIN_MAP_SHOW, { true })
end
MainHudCtrl.OnShowRacingDungeonObtainBuff = HL.Method(HL.Table) << function(self, args)
    self.view.racingEffectWidget:OnShowRacingDungeonObtainBuff(args)
    local id = args[1]
    if self.view.racingEffectWidget:CanPlayEffect(id) then
        self.view.racingEffectBtn.gameObject:GetComponent(typeof(CS.Beyond.UI.UIAnimationWrapper)):Play("racingeffect_btn_in")
    end
end
MainHudCtrl.m_curExpandedBtnCount = HL.Field(HL.Number) << 0
MainHudCtrl.m_isExpanded = HL.Field(HL.Boolean) << false
MainHudCtrl.m_expandTimerId = HL.Field(HL.Number) << -1
MainHudCtrl.m_canAutoStopExpand = HL.Field(HL.Boolean) << true
MainHudCtrl._OnClickExpand = HL.Method() << function(self)
    self:_SetExpanded(true)
    if self.m_canAutoStopExpand then
        self.m_expandTimerId = self:_StartTimer(self.view.config.EXPAND_TIME, function()
            self:_SetExpanded(false)
        end)
    end
end
MainHudCtrl._SetExpanded = HL.Method(HL.Boolean, HL.Opt(HL.Boolean)) << function(self, expand, skipAnimation)
    self.m_isExpanded = expand
    self.m_expandTimerId = self:_ClearTimer(self.m_expandTimerId)
    local act = function()
        self.view.expandNode.transform.localScale = expand and Vector3.one or Vector3.zero
        self.view.closeExpandBtn.gameObject:SetActive(expand)
        self.view.expandBtn.gameObject:SetActive(not expand and self.m_curExpandedBtnCount > 0)
    end
    if skipAnimation then
        act()
    else
        self.view.expandNode.transform.localScale = Vector3.one
        self.view.closeExpandBtn.gameObject:SetActive(true)
        self.view.expandBtn.gameObject:SetActive(false)
        if expand then
            self.view.expandNode:PlayInAnimation(act)
        else
            self.view.expandNode:PlayOutAnimation(act)
        end
    end
end
MainHudCtrl.OnSetMainHudCanAutoStopExpand = HL.Method(HL.Any) << function(self, args)
    self.m_canAutoStopExpand = unpack(args)
end
MainHudCtrl.OnBuildModeChange = HL.Method(HL.Number) << function(self, mode)
    self:_UpdateSingleTopBtnVisible(self.m_topBtnData.top)
end
MainHudCtrl.OnFacDestroyModeChange = HL.Method(HL.Boolean) << function(self, inDestroyMode)
    self:_UpdateSingleTopBtnVisible(self.m_topBtnData.top)
end
local MAIL_BUBBLE_STATE_NONE = 0
local MAIL_BUBBLE_STATE_LOST_AND_FOUND = 1
local MAIL_BUBBLE_STATE_QUESTIONNAIRE = 2
MainHudCtrl.m_mailBubbleCacheState = HL.Field(HL.Number) << 0
MainHudCtrl.m_mailBubbleShowingState = HL.Field(HL.Number) << 0
MainHudCtrl.m_mainBubbleCor = HL.Field(HL.Thread)
MainHudCtrl.OnGetNewMails = HL.Method() << function(self)
    self:_UpdateSingleTopBtnVisible(self.m_topBtnData.mail)
    self:_CheckShowMailBtnBubble()
end
MainHudCtrl.OnLostAndFoundRefresh = HL.Method(HL.Opt(HL.Table)) << function(self, args)
    self:_UpdateSingleTopBtnVisible(self.m_topBtnData.mail)
    self:_CheckShowMailBtnBubble()
end
MainHudCtrl._CheckShowMailBtnBubble = HL.Method() << function(self)
    self.m_mailBubbleCacheState = MAIL_BUBBLE_STATE_NONE
    if GameInstance.player.mail.needShowNewQuestionnaire then
        self.m_mailBubbleCacheState = MAIL_BUBBLE_STATE_QUESTIONNAIRE
    elseif GameInstance.player.inventory.lostAndFoundHasNew and not GameInstance.player.inventory.lostAndFound:IsEmpty() then
        self.m_mailBubbleCacheState = MAIL_BUBBLE_STATE_LOST_AND_FOUND
    end
    if self:IsShow() then
        self:_ShowMainBtnBubble()
    end
end
MainHudCtrl._ShowMainBtnBubble = HL.Method() << function(self)
    if self.m_mailBubbleShowingState >= self.m_mailBubbleCacheState then
        return
    end
    if self.m_mainBubbleCor then
        self.m_mainBubbleCor = self:_ClearCoroutine(self.m_mainBubbleCor)
    end
    self.m_mainBubbleCor = self:_StartCoroutine(function()
        self.view.mailBubbleImg.gameObject:SetActive(true)
        self.m_mailBubbleShowingState = self.m_mailBubbleCacheState
        self.m_mailBubbleCacheState = MAIL_BUBBLE_STATE_NONE
        if self.m_mailBubbleShowingState == MAIL_BUBBLE_STATE_QUESTIONNAIRE then
            GameInstance.player.mail.needShowNewQuestionnaire = false
            GameInstance.player.inventory.lostAndFoundHasNew = false
            self.view.mailBubbleTxt.text = Language.LUA_MAIL_HUD_BUBBLE_QUESTIONNAIRE
        elseif self.m_mailBubbleShowingState == MAIL_BUBBLE_STATE_LOST_AND_FOUND then
            GameInstance.player.inventory.lostAndFoundHasNew = false
            self.view.mailBubbleTxt.text = Language.LUA_MAIL_HUD_BUBBLE_LOST_AND_FOUND
        end
        coroutine.wait(self.view.config.MAIL_BUBBLE_STAY_TIME)
        self.view.mailBubbleImg.gameObject:SetActive(false)
        self.m_mailBubbleShowingState = MAIL_BUBBLE_STATE_NONE
    end)
end
HL.Commit(MainHudCtrl)